import 'dart:async';
import 'dart:convert';
import 'package:mysql1/mysql1.dart';
import '../utils/constants.dart';
import '../models/calculation_result.dart';
import '../models/parameter_models.dart';
import '../models/enums.dart';

/// 远程数据库服务
/// 
/// 负责管理MySQL远程数据库连接、初始化、数据同步和连接池管理
class RemoteDatabaseService {
  static RemoteDatabaseService? _instance;
  MySqlConnection? _connection;
  bool _isInitialized = false;
  Timer? _heartbeatTimer;
  
  /// 连接配置
  static const String _host = AppConstants.remoteDbHost;
  static const int _port = AppConstants.remoteDbPort;
  static const String _database = AppConstants.remoteDbName;
  static const String _username = AppConstants.remoteDbUsername;
  static const String _password = AppConstants.remoteDbPassword;
  
  /// 连接配置
  static const Duration _connectionTimeout = Duration(seconds: 30);
  static const Duration _heartbeatInterval = Duration(minutes: 5);
  
  /// 单例模式
  RemoteDatabaseService._internal();
  
  factory RemoteDatabaseService() {
    _instance ??= RemoteDatabaseService._internal();
    return _instance!;
  }
  
  /// 获取数据库连接
  Future<MySqlConnection> get connection async {
    if (_connection == null) {
      await _createConnection();
    }
    return _connection!;
  }
  
  /// 创建数据库连接
  Future<void> _createConnection() async {
    try {
      final settings = ConnectionSettings(
        host: _host,
        port: _port,
        user: _username,
        password: _password,
        db: _database,
        timeout: _connectionTimeout,
        useCompression: true,
        useSSL: false, // 本地开发环境，生产环境应启用SSL
        maxPacketSize: 16 * 1024 * 1024, // 16MB
      );
      
      _connection = await MySqlConnection.connect(settings);
      print('远程数据库连接成功: $_host:$_port/$_database');
      
      // 启动心跳检测
      _startHeartbeat();
      
    } catch (e) {
      print('远程数据库连接失败: $e');
      rethrow;
    }
  }
  
  /// 启动心跳检测
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) async {
      try {
        if (_connection != null) {
          await _connection!.query('SELECT 1');
        }
      } catch (e) {
        print('心跳检测失败，尝试重连: $e');
        await _reconnect();
      }
    });
  }
  
  /// 重新连接
  Future<void> _reconnect() async {
    try {
      await _connection?.close();
      _connection = null;
      await _createConnection();
      print('数据库重连成功');
    } catch (e) {
      print('数据库重连失败: $e');
    }
  }
  
  /// 初始化远程数据库
  Future<void> initializeDatabase() async {
    if (_isInitialized) {
      return;
    }
    
    try {
      // 首先连接到MySQL服务器（不指定数据库）
      final adminSettings = ConnectionSettings(
        host: _host,
        port: _port,
        user: _username,
        password: _password,
        timeout: _connectionTimeout,
      );
      
      final adminConnection = await MySqlConnection.connect(adminSettings);
      
      // 创建数据库（如果不存在）
      await adminConnection.query('''
        CREATE DATABASE IF NOT EXISTS $_database 
        CHARACTER SET utf8mb4 
        COLLATE utf8mb4_unicode_ci
      ''');
      
      await adminConnection.close();
      
      // 连接到新创建的数据库
      await _createConnection();
      final conn = await connection;
      
      // 创建所有表
      await _createTables(conn);
      
      // 创建索引
      await _createIndexes(conn);
      
      // 初始化默认数据
      await _initializeDefaultData(conn);
      
      _isInitialized = true;
      print('远程数据库初始化完成');
      
    } catch (e) {
      print('远程数据库初始化失败: $e');
      rethrow;
    }
  }
  
  /// 创建数据库表
  Future<void> _createTables(MySqlConnection conn) async {
    // 创建计算记录表
    await conn.query('''
      CREATE TABLE IF NOT EXISTS calculation_records (
        id VARCHAR(255) PRIMARY KEY,
        calculation_type VARCHAR(100) NOT NULL,
        parameters JSON NOT NULL,
        results JSON NOT NULL,
        created_at BIGINT NOT NULL,
        updated_at BIGINT NOT NULL,
        device_id VARCHAR(255),
        sync_version INT DEFAULT 1,
        is_deleted BOOLEAN DEFAULT FALSE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ''');
    
    // 创建参数组表
    await conn.query('''
      CREATE TABLE IF NOT EXISTS parameter_sets (
        id VARCHAR(255) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        calculation_type VARCHAR(100) NOT NULL,
        parameters JSON NOT NULL,
        is_preset BOOLEAN DEFAULT FALSE,
        tags JSON,
        created_at BIGINT NOT NULL,
        updated_at BIGINT NOT NULL,
        device_id VARCHAR(255),
        sync_version INT DEFAULT 1,
        is_deleted BOOLEAN DEFAULT FALSE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ''');
    
    // 创建预设参数表
    await conn.query('''
      CREATE TABLE IF NOT EXISTS preset_parameters (
        id VARCHAR(255) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        calculation_type VARCHAR(100) NOT NULL,
        parameter_name VARCHAR(255) NOT NULL,
        parameter_value DECIMAL(10,3) NOT NULL,
        unit VARCHAR(50),
        description TEXT,
        category VARCHAR(100),
        created_at BIGINT NOT NULL,
        sync_version INT DEFAULT 1,
        is_deleted BOOLEAN DEFAULT FALSE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ''');
    
    // 创建用户设置表
    await conn.query('''
      CREATE TABLE IF NOT EXISTS user_settings (
        setting_key VARCHAR(255) PRIMARY KEY,
        setting_value TEXT NOT NULL,
        updated_at BIGINT NOT NULL,
        device_id VARCHAR(255),
        sync_version INT DEFAULT 1
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ''');
    
    // 创建同步状态表
    await conn.query('''
      CREATE TABLE IF NOT EXISTS sync_status (
        device_id VARCHAR(255) PRIMARY KEY,
        last_sync_time BIGINT NOT NULL,
        sync_version INT DEFAULT 1,
        total_records INT DEFAULT 0,
        synced_records INT DEFAULT 0,
        failed_records INT DEFAULT 0,
        last_error TEXT,
        created_at BIGINT NOT NULL,
        updated_at BIGINT NOT NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ''');
    
    // 创建设备信息表
    await conn.query('''
      CREATE TABLE IF NOT EXISTS device_info (
        device_id VARCHAR(255) PRIMARY KEY,
        device_name VARCHAR(255),
        platform VARCHAR(100),
        app_version VARCHAR(50),
        first_seen BIGINT NOT NULL,
        last_seen BIGINT NOT NULL,
        is_active BOOLEAN DEFAULT TRUE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ''');
  }
  
  /// 创建索引
  Future<void> _createIndexes(MySqlConnection conn) async {
    final indexes = [
      // calculation_records表索引
      'CREATE INDEX IF NOT EXISTS idx_calc_type ON calculation_records (calculation_type)',
      'CREATE INDEX IF NOT EXISTS idx_calc_created ON calculation_records (created_at)',
      'CREATE INDEX IF NOT EXISTS idx_calc_device ON calculation_records (device_id)',
      'CREATE INDEX IF NOT EXISTS idx_calc_sync ON calculation_records (sync_version)',
      
      // parameter_sets表索引
      'CREATE INDEX IF NOT EXISTS idx_param_type ON parameter_sets (calculation_type)',
      'CREATE INDEX IF NOT EXISTS idx_param_name ON parameter_sets (name)',
      'CREATE INDEX IF NOT EXISTS idx_param_preset ON parameter_sets (is_preset)',
      'CREATE INDEX IF NOT EXISTS idx_param_device ON parameter_sets (device_id)',
      
      // preset_parameters表索引
      'CREATE INDEX IF NOT EXISTS idx_preset_type ON preset_parameters (calculation_type)',
      'CREATE INDEX IF NOT EXISTS idx_preset_name ON preset_parameters (parameter_name)',
      'CREATE INDEX IF NOT EXISTS idx_preset_category ON preset_parameters (category)',
      
      // sync_status表索引
      'CREATE INDEX IF NOT EXISTS idx_sync_time ON sync_status (last_sync_time)',
      'CREATE INDEX IF NOT EXISTS idx_sync_version ON sync_status (sync_version)',
      
      // device_info表索引
      'CREATE INDEX IF NOT EXISTS idx_device_active ON device_info (is_active)',
      'CREATE INDEX IF NOT EXISTS idx_device_last_seen ON device_info (last_seen)',
    ];
    
    for (final indexSql in indexes) {
      try {
        await conn.query(indexSql);
      } catch (e) {
        // 索引可能已存在，忽略错误
        print('创建索引时出现警告: $e');
      }
    }
  }
  
  /// 初始化默认数据
  Future<void> _initializeDefaultData(MySqlConnection conn) async {
    // 这里可以插入一些默认的预设参数或配置
    // 暂时留空，后续可以根据需要添加
  }
  
  /// 同步计算记录
  Future<void> syncCalculationRecord(CalculationResult result, String deviceId) async {
    try {
      final conn = await connection;
      
      await conn.query('''
        INSERT INTO calculation_records 
        (id, calculation_type, parameters, results, created_at, updated_at, device_id, sync_version)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        parameters = VALUES(parameters),
        results = VALUES(results),
        updated_at = VALUES(updated_at),
        sync_version = sync_version + 1
      ''', [
        result.id,
        result.calculationType.toString(),
        jsonEncode(result.parameters.toJson()),
        jsonEncode(result.toJson()),
        result.calculationTime.millisecondsSinceEpoch,
        DateTime.now().millisecondsSinceEpoch,
        deviceId,
        1,
      ]);
      
    } catch (e) {
      print('同步计算记录失败: $e');
      rethrow;
    }
  }
  
  /// 同步参数组
  Future<void> syncParameterSet(ParameterSet parameterSet, String deviceId) async {
    try {
      final conn = await connection;
      
      await conn.query('''
        INSERT INTO parameter_sets 
        (id, name, description, calculation_type, parameters, is_preset, tags, created_at, updated_at, device_id, sync_version)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        name = VALUES(name),
        description = VALUES(description),
        parameters = VALUES(parameters),
        tags = VALUES(tags),
        updated_at = VALUES(updated_at),
        sync_version = sync_version + 1
      ''', [
        parameterSet.id,
        parameterSet.name,
        parameterSet.description,
        parameterSet.calculationType.toString(),
        jsonEncode(parameterSet.parameters),
        parameterSet.isPreset ? 1 : 0,
        jsonEncode(parameterSet.tags),
        parameterSet.createdAt.millisecondsSinceEpoch,
        parameterSet.updatedAt.millisecondsSinceEpoch,
        deviceId,
        1,
      ]);
      
    } catch (e) {
      print('同步参数组失败: $e');
      rethrow;
    }
  }
  
  /// 批量同步计算记录
  Future<void> batchSyncCalculationRecords(List<CalculationResult> results, String deviceId) async {
    if (results.isEmpty) return;
    
    try {
      final conn = await connection;
      
      // 使用单个连接进行批量操作
      for (final result in results) {
        await conn.query('''
          INSERT INTO calculation_records 
          (id, calculation_type, parameters, results, created_at, updated_at, device_id, sync_version)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE
          parameters = VALUES(parameters),
          results = VALUES(results),
          updated_at = VALUES(updated_at),
          sync_version = sync_version + 1
        ''', [
          result.id,
          result.calculationType.toString(),
          jsonEncode(result.parameters.toJson()),
          jsonEncode(result.toJson()),
          result.calculationTime.millisecondsSinceEpoch,
          DateTime.now().millisecondsSinceEpoch,
          deviceId,
          1,
        ]);
      }
      
      print('批量同步 ${results.length} 条计算记录成功');
      
    } catch (e) {
      print('批量同步计算记录失败: $e');
      rethrow;
    }
  }
  
  /// 获取远程计算记录
  Future<List<Map<String, dynamic>>> getRemoteCalculationRecords({
    String? deviceId,
    DateTime? since,
    int? limit,
  }) async {
    try {
      final conn = await connection;
      
      String whereClause = 'WHERE is_deleted = FALSE';
      final params = <dynamic>[];
      
      if (deviceId != null) {
        whereClause += ' AND device_id = ?';
        params.add(deviceId);
      }
      
      if (since != null) {
        whereClause += ' AND updated_at > ?';
        params.add(since.millisecondsSinceEpoch);
      }
      
      String limitClause = '';
      if (limit != null) {
        limitClause = ' LIMIT ?';
        params.add(limit);
      }
      
      final results = await conn.query('''
        SELECT * FROM calculation_records 
        $whereClause 
        ORDER BY updated_at DESC
        $limitClause
      ''', params);
      
      return results.map((row) => row.fields).toList();
      
    } catch (e) {
      print('获取远程计算记录失败: $e');
      rethrow;
    }
  }
  
  /// 更新同步状态
  Future<void> updateSyncStatus(String deviceId, {
    int? totalRecords,
    int? syncedRecords,
    int? failedRecords,
    String? lastError,
  }) async {
    try {
      final conn = await connection;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      await conn.query('''
        INSERT INTO sync_status 
        (device_id, last_sync_time, total_records, synced_records, failed_records, last_error, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        last_sync_time = VALUES(last_sync_time),
        total_records = COALESCE(VALUES(total_records), total_records),
        synced_records = COALESCE(VALUES(synced_records), synced_records),
        failed_records = COALESCE(VALUES(failed_records), failed_records),
        last_error = VALUES(last_error),
        updated_at = VALUES(updated_at),
        sync_version = sync_version + 1
      ''', [
        deviceId,
        currentTime,
        totalRecords,
        syncedRecords,
        failedRecords,
        lastError,
        currentTime,
        currentTime,
      ]);
      
    } catch (e) {
      print('更新同步状态失败: $e');
      rethrow;
    }
  }
  
  /// 注册设备信息
  Future<void> registerDevice(String deviceId, String deviceName, String platform, String appVersion) async {
    try {
      final conn = await connection;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      await conn.query('''
        INSERT INTO device_info 
        (device_id, device_name, platform, app_version, first_seen, last_seen, is_active)
        VALUES (?, ?, ?, ?, ?, ?, TRUE)
        ON DUPLICATE KEY UPDATE
        device_name = VALUES(device_name),
        platform = VALUES(platform),
        app_version = VALUES(app_version),
        last_seen = VALUES(last_seen),
        is_active = TRUE
      ''', [
        deviceId,
        deviceName,
        platform,
        appVersion,
        currentTime,
        currentTime,
      ]);
      
    } catch (e) {
      print('注册设备信息失败: $e');
      rethrow;
    }
  }
  
  /// 检查连接状态
  Future<bool> isConnected() async {
    try {
      if (_connection == null) {
        return false;
      }
      
      await _connection!.query('SELECT 1');
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 获取数据库统计信息
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final conn = await connection;
      
      // 获取各表的记录数
      final tables = ['calculation_records', 'parameter_sets', 'preset_parameters', 'device_info'];
      final stats = <String, int>{};
      
      for (final table in tables) {
        final result = await conn.query('SELECT COUNT(*) as count FROM $table WHERE is_deleted = FALSE OR is_deleted IS NULL');
        stats[table] = result.first['count'] as int;
      }
      
      // 获取活跃设备数
      final activeDevicesResult = await conn.query('SELECT COUNT(*) as count FROM device_info WHERE is_active = TRUE');
      stats['active_devices'] = activeDevicesResult.first['count'] as int;
      
      return {
        'table_counts': stats,
        'total_records': stats.values.fold(0, (sum, count) => sum + count),
        'last_updated': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('获取数据库统计信息失败: $e');
      rethrow;
    }
  }
  
  /// 清理过期数据
  Future<int> cleanupExpiredData(Duration retentionPeriod) async {
    try {
      final conn = await connection;
      final cutoffTime = DateTime.now().subtract(retentionPeriod).millisecondsSinceEpoch;
      
      // 软删除过期的计算记录
      final result = await conn.query('''
        UPDATE calculation_records 
        SET is_deleted = TRUE 
        WHERE created_at < ? AND is_deleted = FALSE
      ''', [cutoffTime]);
      
      final deletedCount = result.affectedRows ?? 0;
      print('清理了 $deletedCount 条过期记录');
      
      return deletedCount;
      
    } catch (e) {
      print('清理过期数据失败: $e');
      rethrow;
    }
  }
  
  /// 关闭连接
  Future<void> close() async {
    try {
      _heartbeatTimer?.cancel();
      
      if (_connection != null) {
        await _connection!.close();
        _connection = null;
      }
      
      _isInitialized = false;
      print('远程数据库连接已关闭');
      
    } catch (e) {
      print('关闭远程数据库连接失败: $e');
    }
  }
}