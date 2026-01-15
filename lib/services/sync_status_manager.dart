import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'database_helper.dart';
import 'remote_database_service.dart';
import '../models/enums.dart';

/// 同步状态枚举
enum SyncStatus {
  idle,        // 空闲状态
  syncing,     // 同步中
  success,     // 同步成功
  failed,      // 同步失败
  conflict,    // 同步冲突
}

/// 同步冲突类型
enum ConflictType {
  dataModified,    // 数据被修改
  versionMismatch, // 版本不匹配
  deviceMismatch,  // 设备不匹配
}

/// 同步冲突信息
class SyncConflict {
  final String recordId;
  final String tableName;
  final ConflictType type;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime conflictTime;
  final String description;
  
  SyncConflict({
    required this.recordId,
    required this.tableName,
    required this.type,
    required this.localData,
    required this.remoteData,
    required this.conflictTime,
    required this.description,
  });
  
  Map<String, dynamic> toJson() => {
    'recordId': recordId,
    'tableName': tableName,
    'type': type.toString(),
    'localData': localData,
    'remoteData': remoteData,
    'conflictTime': conflictTime.toIso8601String(),
    'description': description,
  };
  
  factory SyncConflict.fromJson(Map<String, dynamic> json) => SyncConflict(
    recordId: json['recordId'],
    tableName: json['tableName'],
    type: ConflictType.values.firstWhere((e) => e.toString() == json['type']),
    localData: json['localData'],
    remoteData: json['remoteData'],
    conflictTime: DateTime.parse(json['conflictTime']),
    description: json['description'],
  );
}

/// 同步统计信息
class SyncStatistics {
  final int totalRecords;
  final int syncedRecords;
  final int failedRecords;
  final int conflictRecords;
  final DateTime lastSyncTime;
  final Duration syncDuration;
  final List<String> errors;
  
  SyncStatistics({
    required this.totalRecords,
    required this.syncedRecords,
    required this.failedRecords,
    required this.conflictRecords,
    required this.lastSyncTime,
    required this.syncDuration,
    required this.errors,
  });
  
  double get successRate => totalRecords > 0 ? syncedRecords / totalRecords : 0.0;
  
  Map<String, dynamic> toJson() => {
    'totalRecords': totalRecords,
    'syncedRecords': syncedRecords,
    'failedRecords': failedRecords,
    'conflictRecords': conflictRecords,
    'lastSyncTime': lastSyncTime.toIso8601String(),
    'syncDuration': syncDuration.inMilliseconds,
    'successRate': successRate,
    'errors': errors,
  };
}

/// 同步状态管理器
/// 
/// 负责设备ID生成、同步版本控制、冲突检测和解决
class SyncStatusManager {
  static SyncStatusManager? _instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final RemoteDatabaseService _remoteDb = RemoteDatabaseService();
  
  String? _deviceId;
  String? _deviceName;
  String? _platform;
  String? _appVersion;
  
  SyncStatus _currentStatus = SyncStatus.idle;
  final List<SyncConflict> _conflicts = [];
  final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();
  final StreamController<SyncStatistics> _statisticsController = StreamController<SyncStatistics>.broadcast();
  final StreamController<List<SyncConflict>> _conflictsController = StreamController<List<SyncConflict>>.broadcast();
  
  /// 单例模式
  SyncStatusManager._internal();
  
  factory SyncStatusManager() {
    _instance ??= SyncStatusManager._internal();
    return _instance!;
  }
  
  /// 同步状态流
  Stream<SyncStatus> get statusStream => _statusController.stream;
  
  /// 同步统计流
  Stream<SyncStatistics> get statisticsStream => _statisticsController.stream;
  
  /// 冲突列表流
  Stream<List<SyncConflict>> get conflictsStream => _conflictsController.stream;
  
  /// 当前同步状态
  SyncStatus get currentStatus => _currentStatus;
  
  /// 当前冲突列表
  List<SyncConflict> get conflicts => List.unmodifiable(_conflicts);
  
  /// 初始化同步管理器
  Future<void> initialize() async {
    await _generateOrLoadDeviceId();
    await _loadDeviceInfo();
    await _initializeSyncTables();
    print('同步状态管理器初始化完成');
  }
  
  /// 生成或加载设备ID
  Future<void> _generateOrLoadDeviceId() async {
    try {
      final db = await _dbHelper.database;
      
      // 尝试从数据库加载现有设备ID
      final result = await db.query(
        'user_settings',
        where: 'key = ?',
        whereArgs: ['device_id'],
      );
      
      if (result.isNotEmpty) {
        _deviceId = result.first['value'] as String;
      } else {
        // 生成新的设备ID
        _deviceId = const Uuid().v4();
        
        // 保存到数据库
        await db.insert(
          'user_settings',
          {
            'key': 'device_id',
            'value': _deviceId!,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      print('设备ID: $_deviceId');
      
    } catch (e) {
      print('生成设备ID失败: $e');
      // 使用临时ID
      _deviceId = const Uuid().v4();
    }
  }
  
  /// 加载设备信息
  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      _appVersion = packageInfo.version;
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceName = '${androidInfo.brand} ${androidInfo.model}';
        _platform = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceName = '${iosInfo.name}';
        _platform = 'iOS ${iosInfo.systemVersion}';
      } else {
        _deviceName = 'Unknown Device';
        _platform = Platform.operatingSystem;
      }
      
      print('设备信息: $_deviceName ($_platform), 应用版本: $_appVersion');
      
    } catch (e) {
      print('加载设备信息失败: $e');
      _deviceName = 'Unknown Device';
      _platform = 'Unknown Platform';
      _appVersion = '1.0.0';
    }
  }
  
  /// 初始化同步相关表
  Future<void> _initializeSyncTables() async {
    try {
      final db = await _dbHelper.database;
      
      // 确保同步状态表存在
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_conflicts (
          id TEXT PRIMARY KEY,
          record_id TEXT NOT NULL,
          table_name TEXT NOT NULL,
          conflict_type TEXT NOT NULL,
          local_data TEXT NOT NULL,
          remote_data TEXT NOT NULL,
          conflict_time INTEGER NOT NULL,
          description TEXT,
          resolved INTEGER DEFAULT 0,
          resolution_strategy TEXT,
          resolved_at INTEGER,
          INDEX(record_id),
          INDEX(table_name),
          INDEX(resolved)
        )
      ''');
      
      print('同步表初始化完成');
      
    } catch (e) {
      print('初始化同步表失败: $e');
    }
  }
  
  /// 获取设备ID
  String get deviceId => _deviceId ?? 'unknown';
  
  /// 获取设备信息
  Map<String, String> get deviceInfo => {
    'deviceId': deviceId,
    'deviceName': _deviceName ?? 'Unknown',
    'platform': _platform ?? 'Unknown',
    'appVersion': _appVersion ?? '1.0.0',
  };
  
  /// 更新同步状态
  void _updateStatus(SyncStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
      print('同步状态更新: $status');
    }
  }
  
  /// 开始同步
  Future<SyncStatistics> startSync({bool forceFullSync = false}) async {
    if (_currentStatus == SyncStatus.syncing) {
      throw StateError('同步正在进行中');
    }
    
    _updateStatus(SyncStatus.syncing);
    final startTime = DateTime.now();
    final errors = <String>[];
    
    int totalRecords = 0;
    int syncedRecords = 0;
    int failedRecords = 0;
    int conflictRecords = 0;
    
    try {
      // 注册设备信息到远程数据库
      await _registerDevice();
      
      // 获取本地待同步数据
      final localData = await _getLocalUnsyncedData();
      totalRecords = localData.length;
      
      // 执行同步
      for (final record in localData) {
        try {
          final syncResult = await _syncRecord(record);
          
          if (syncResult['success'] == true) {
            syncedRecords++;
          } else if (syncResult['conflict'] == true) {
            conflictRecords++;
            _conflicts.add(syncResult['conflictInfo']);
          } else {
            failedRecords++;
            errors.add(syncResult['error'] ?? '未知错误');
          }
          
        } catch (e) {
          failedRecords++;
          errors.add('同步记录失败: $e');
        }
      }
      
      // 从远程拉取更新
      if (!forceFullSync) {
        await _pullRemoteUpdates();
      }
      
      // 更新同步状态
      final finalStatus = conflictRecords > 0 ? SyncStatus.conflict : 
                         failedRecords > 0 ? SyncStatus.failed : SyncStatus.success;
      _updateStatus(finalStatus);
      
    } catch (e) {
      _updateStatus(SyncStatus.failed);
      errors.add('同步过程失败: $e');
      failedRecords = totalRecords - syncedRecords;
    }
    
    final endTime = DateTime.now();
    final statistics = SyncStatistics(
      totalRecords: totalRecords,
      syncedRecords: syncedRecords,
      failedRecords: failedRecords,
      conflictRecords: conflictRecords,
      lastSyncTime: endTime,
      syncDuration: endTime.difference(startTime),
      errors: errors,
    );
    
    // 发送统计信息
    _statisticsController.add(statistics);
    _conflictsController.add(List.from(_conflicts));
    
    // 保存同步统计到本地
    await _saveSyncStatistics(statistics);
    
    return statistics;
  }
  
  /// 注册设备到远程数据库
  Future<void> _registerDevice() async {
    try {
      await _remoteDb.registerDevice(
        deviceId,
        _deviceName ?? 'Unknown',
        _platform ?? 'Unknown',
        _appVersion ?? '1.0.0',
      );
    } catch (e) {
      print('注册设备失败: $e');
      // 不抛出异常，允许同步继续
    }
  }
  
  /// 获取本地未同步数据
  Future<List<Map<String, dynamic>>> _getLocalUnsyncedData() async {
    final db = await _dbHelper.database;
    final unsyncedData = <Map<String, dynamic>>[];
    
    // 获取未同步的计算记录
    final calcRecords = await db.query(
      'calculation_records',
      where: 'sync_status = ?',
      whereArgs: [0], // 0表示未同步
    );
    
    for (final record in calcRecords) {
      unsyncedData.add({
        'table': 'calculation_records',
        'data': record,
      });
    }
    
    // 获取未同步的参数组
    final paramSets = await db.query(
      'parameter_sets',
      where: 'sync_status = ?',
      whereArgs: [0],
    );
    
    for (final record in paramSets) {
      unsyncedData.add({
        'table': 'parameter_sets',
        'data': record,
      });
    }
    
    return unsyncedData;
  }
  
  /// 同步单条记录
  Future<Map<String, dynamic>> _syncRecord(Map<String, dynamic> record) async {
    final tableName = record['table'] as String;
    final data = record['data'] as Map<String, dynamic>;
    
    try {
      // 检查远程是否存在相同记录
      final remoteRecord = await _getRemoteRecord(tableName, data['id']);
      
      if (remoteRecord != null) {
        // 检查是否有冲突
        final conflict = _detectConflict(data, remoteRecord);
        if (conflict != null) {
          return {
            'success': false,
            'conflict': true,
            'conflictInfo': conflict,
          };
        }
      }
      
      // 执行同步
      await _uploadRecord(tableName, data);
      
      // 更新本地同步状态
      await _updateLocalSyncStatus(tableName, data['id'], 1); // 1表示已同步
      
      return {'success': true};
      
    } catch (e) {
      return {
        'success': false,
        'conflict': false,
        'error': e.toString(),
      };
    }
  }
  
  /// 获取远程记录
  Future<Map<String, dynamic>?> _getRemoteRecord(String tableName, String recordId) async {
    // 这里应该调用远程数据库服务获取记录
    // 暂时返回null，表示没有找到远程记录
    return null;
  }
  
  /// 检测冲突
  SyncConflict? _detectConflict(Map<String, dynamic> localData, Map<String, dynamic> remoteData) {
    // 检查更新时间
    final localUpdatedAt = localData['updated_at'] as int;
    final remoteUpdatedAt = remoteData['updated_at'] as int;
    
    // 如果远程数据更新时间更晚，且内容不同，则存在冲突
    if (remoteUpdatedAt > localUpdatedAt) {
      // 比较关键字段是否不同
      final keyFields = ['parameters', 'results', 'name', 'description'];
      
      for (final field in keyFields) {
        if (localData.containsKey(field) && remoteData.containsKey(field)) {
          if (localData[field] != remoteData[field]) {
            return SyncConflict(
              recordId: localData['id'],
              tableName: 'calculation_records', // 这里应该动态获取
              type: ConflictType.dataModified,
              localData: localData,
              remoteData: remoteData,
              conflictTime: DateTime.now(),
              description: '本地和远程数据在字段 $field 上存在差异',
            );
          }
        }
      }
    }
    
    return null;
  }
  
  /// 上传记录到远程
  Future<void> _uploadRecord(String tableName, Map<String, dynamic> data) async {
    // 根据表名调用相应的远程同步方法
    switch (tableName) {
      case 'calculation_records':
        // 这里需要将Map转换为CalculationResult对象
        // 暂时跳过实际上传
        break;
      case 'parameter_sets':
        // 这里需要将Map转换为ParameterSet对象
        // 暂时跳过实际上传
        break;
    }
  }
  
  /// 更新本地同步状态
  Future<void> _updateLocalSyncStatus(String tableName, String recordId, int syncStatus) async {
    final db = await _dbHelper.database;
    
    await db.update(
      tableName,
      {
        'sync_status': syncStatus,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }
  
  /// 从远程拉取更新
  Future<void> _pullRemoteUpdates() async {
    try {
      // 获取上次同步时间
      final lastSyncTime = await _getLastSyncTime();
      
      // 从远程获取更新的记录
      final remoteUpdates = await _remoteDb.getRemoteCalculationRecords(
        deviceId: deviceId,
        since: lastSyncTime,
      );
      
      // 应用远程更新到本地
      for (final update in remoteUpdates) {
        await _applyRemoteUpdate(update);
      }
      
      // 更新最后同步时间
      await _updateLastSyncTime(DateTime.now());
      
    } catch (e) {
      print('拉取远程更新失败: $e');
    }
  }
  
  /// 获取上次同步时间
  Future<DateTime?> _getLastSyncTime() async {
    try {
      final db = await _dbHelper.database;
      
      final result = await db.query(
        'user_settings',
        where: 'key = ?',
        whereArgs: ['last_sync_time'],
      );
      
      if (result.isNotEmpty) {
        final timestamp = int.parse(result.first['value'] as String);
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      
    } catch (e) {
      print('获取上次同步时间失败: $e');
    }
    
    return null;
  }
  
  /// 更新最后同步时间
  Future<void> _updateLastSyncTime(DateTime time) async {
    try {
      final db = await _dbHelper.database;
      
      await db.insert(
        'user_settings',
        {
          'key': 'last_sync_time',
          'value': time.millisecondsSinceEpoch.toString(),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
    } catch (e) {
      print('更新同步时间失败: $e');
    }
  }
  
  /// 应用远程更新
  Future<void> _applyRemoteUpdate(Map<String, dynamic> remoteData) async {
    // 这里应该根据远程数据更新本地数据库
    // 需要处理冲突检测和解决
    print('应用远程更新: ${remoteData['id']}');
  }
  
  /// 解决冲突
  Future<void> resolveConflict(String conflictId, String strategy, {Map<String, dynamic>? customData}) async {
    try {
      final db = await _dbHelper.database;
      
      // 获取冲突信息
      final conflictResult = await db.query(
        'sync_conflicts',
        where: 'id = ?',
        whereArgs: [conflictId],
      );
      
      if (conflictResult.isEmpty) {
        throw ArgumentError('冲突记录不存在: $conflictId');
      }
      
      final conflictData = conflictResult.first;
      final localData = jsonDecode(conflictData['local_data'] as String);
      final remoteData = jsonDecode(conflictData['remote_data'] as String);
      
      Map<String, dynamic> resolvedData;
      
      // 根据策略解决冲突
      switch (strategy) {
        case 'use_local':
          resolvedData = localData;
          break;
        case 'use_remote':
          resolvedData = remoteData;
          break;
        case 'merge':
          resolvedData = _mergeData(localData, remoteData);
          break;
        case 'custom':
          if (customData == null) {
            throw ArgumentError('自定义策略需要提供数据');
          }
          resolvedData = customData;
          break;
        default:
          throw ArgumentError('未知的冲突解决策略: $strategy');
      }
      
      // 更新目标表的数据
      final tableName = conflictData['table_name'] as String;
      final recordId = conflictData['record_id'] as String;
      
      await db.update(
        tableName,
        resolvedData,
        where: 'id = ?',
        whereArgs: [recordId],
      );
      
      // 标记冲突为已解决
      await db.update(
        'sync_conflicts',
        {
          'resolved': 1,
          'resolution_strategy': strategy,
          'resolved_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [conflictId],
      );
      
      // 从内存中移除冲突
      _conflicts.removeWhere((conflict) => conflict.recordId == recordId);
      _conflictsController.add(List.from(_conflicts));
      
      print('冲突解决成功: $conflictId, 策略: $strategy');
      
    } catch (e) {
      print('解决冲突失败: $e');
      rethrow;
    }
  }
  
  /// 合并数据
  Map<String, dynamic> _mergeData(Map<String, dynamic> localData, Map<String, dynamic> remoteData) {
    final merged = Map<String, dynamic>.from(localData);
    
    // 使用更新时间较晚的数据
    final localUpdatedAt = localData['updated_at'] as int? ?? 0;
    final remoteUpdatedAt = remoteData['updated_at'] as int? ?? 0;
    
    if (remoteUpdatedAt > localUpdatedAt) {
      // 远程数据更新，但保留本地的某些字段
      merged.addAll(remoteData);
      
      // 保留本地的设备ID
      if (localData.containsKey('device_id')) {
        merged['device_id'] = localData['device_id'];
      }
    }
    
    return merged;
  }
  
  /// 保存同步统计
  Future<void> _saveSyncStatistics(SyncStatistics statistics) async {
    try {
      final db = await _dbHelper.database;
      
      await db.insert(
        'user_settings',
        {
          'key': 'last_sync_statistics',
          'value': jsonEncode(statistics.toJson()),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
    } catch (e) {
      print('保存同步统计失败: $e');
    }
  }
  
  /// 获取同步统计
  Future<SyncStatistics?> getLastSyncStatistics() async {
    try {
      final db = await _dbHelper.database;
      
      final result = await db.query(
        'user_settings',
        where: 'key = ?',
        whereArgs: ['last_sync_statistics'],
      );
      
      if (result.isNotEmpty) {
        final data = jsonDecode(result.first['value'] as String);
        return SyncStatistics(
          totalRecords: data['totalRecords'],
          syncedRecords: data['syncedRecords'],
          failedRecords: data['failedRecords'],
          conflictRecords: data['conflictRecords'],
          lastSyncTime: DateTime.parse(data['lastSyncTime']),
          syncDuration: Duration(milliseconds: data['syncDuration']),
          errors: List<String>.from(data['errors']),
        );
      }
      
    } catch (e) {
      print('获取同步统计失败: $e');
    }
    
    return null;
  }
  
  /// 清理已解决的冲突
  Future<int> cleanupResolvedConflicts({Duration? olderThan}) async {
    try {
      final db = await _dbHelper.database;
      
      String whereClause = 'resolved = 1';
      final whereArgs = <dynamic>[];
      
      if (olderThan != null) {
        final cutoffTime = DateTime.now().subtract(olderThan).millisecondsSinceEpoch;
        whereClause += ' AND resolved_at < ?';
        whereArgs.add(cutoffTime);
      }
      
      final deletedCount = await db.delete(
        'sync_conflicts',
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      );
      
      print('清理了 $deletedCount 个已解决的冲突');
      return deletedCount;
      
    } catch (e) {
      print('清理冲突失败: $e');
      return 0;
    }
  }
  
  /// 重置同步状态
  Future<void> resetSyncStatus() async {
    try {
      final db = await _dbHelper.database;
      
      // 重置所有记录的同步状态
      await db.update(
        'calculation_records',
        {'sync_status': 0},
        where: 'sync_status != 0',
      );
      
      await db.update(
        'parameter_sets',
        {'sync_status': 0},
        where: 'sync_status != 0',
      );
      
      // 清空冲突记录
      await db.delete('sync_conflicts');
      _conflicts.clear();
      
      // 重置同步状态
      _updateStatus(SyncStatus.idle);
      _conflictsController.add([]);
      
      print('同步状态已重置');
      
    } catch (e) {
      print('重置同步状态失败: $e');
      rethrow;
    }
  }
  
  /// 获取同步版本
  Future<int> getSyncVersion(String tableName) async {
    try {
      final db = await _dbHelper.database;
      
      final result = await db.query(
        'sync_status',
        columns: ['sync_version'],
        where: 'table_name = ?',
        whereArgs: [tableName],
      );
      
      if (result.isNotEmpty) {
        return result.first['sync_version'] as int;
      }
      
      return 1; // 默认版本
      
    } catch (e) {
      print('获取同步版本失败: $e');
      return 1;
    }
  }
  
  /// 更新同步版本
  Future<void> updateSyncVersion(String tableName, int version) async {
    try {
      final db = await _dbHelper.database;
      
      await db.insert(
        'sync_status',
        {
          'table_name': tableName,
          'sync_version': version,
          'last_sync_time': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
    } catch (e) {
      print('更新同步版本失败: $e');
    }
  }
  
  /// 检查是否需要同步
  Future<bool> needsSync() async {
    try {
      final db = await _dbHelper.database;
      
      // 检查是否有未同步的记录
      final unsyncedCalcRecords = await db.query(
        'calculation_records',
        where: 'sync_status = 0',
        limit: 1,
      );
      
      final unsyncedParamSets = await db.query(
        'parameter_sets',
        where: 'sync_status = 0',
        limit: 1,
      );
      
      return unsyncedCalcRecords.isNotEmpty || unsyncedParamSets.isNotEmpty;
      
    } catch (e) {
      print('检查同步需求失败: $e');
      return false;
    }
  }
  
  /// 获取未同步记录数量
  Future<Map<String, int>> getUnsyncedCounts() async {
    try {
      final db = await _dbHelper.database;
      
      final calcResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM calculation_records WHERE sync_status = 0'
      );
      
      final paramResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM parameter_sets WHERE sync_status = 0'
      );
      
      return {
        'calculation_records': calcResult.first['count'] as int,
        'parameter_sets': paramResult.first['count'] as int,
      };
      
    } catch (e) {
      print('获取未同步记录数量失败: $e');
      return {
        'calculation_records': 0,
        'parameter_sets': 0,
      };
    }
  }
  
  /// 释放资源
  void dispose() {
    _statusController.close();
    _statisticsController.close();
    _conflictsController.close();
  }
}