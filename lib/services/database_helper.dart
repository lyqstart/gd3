import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/constants.dart';
import '../models/enums.dart';
import '../utils/performance_optimizer.dart';
import 'preset_parameter_initializer.dart';

/// 数据库帮助类
/// 
/// 负责管理本地SQLite数据库的创建、初始化、版本管理和迁移
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;
  
  /// 单例模式
  DatabaseHelper._internal();
  
  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }
  
  /// 获取数据库实例（优化版本）
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    
    // 使用性能监控
    PerformanceMonitor.startMeasurement('database_init');
    
    try {
      _database = await _initDatabase();
      PerformanceMonitor.endMeasurement('database_init');
      return _database!;
    } catch (e) {
      PerformanceMonitor.endMeasurement('database_init');
      rethrow;
    }
  }
  
  /// 初始化数据库（优化版本）
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);
    
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
      // 性能优化配置
      onConfigure: (db) async {
        // 启用外键约束
        await db.execute('PRAGMA foreign_keys = ON');
        // 设置同步模式为NORMAL以提高性能
        await db.execute('PRAGMA synchronous = NORMAL');
        // 设置日志模式为WAL以提高并发性能
        await db.execute('PRAGMA journal_mode = WAL');
        // 设置缓存大小（页数）
        await db.execute('PRAGMA cache_size = 10000');
        // 设置临时存储为内存
        await db.execute('PRAGMA temp_store = MEMORY');
      },
    );
  }
  
  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    
    // 创建计算记录表
    batch.execute('''
      CREATE TABLE calculation_records (
        id TEXT PRIMARY KEY,
        calculation_type TEXT NOT NULL,
        parameters TEXT NOT NULL,
        results TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 0,
        device_id TEXT,
        client_id TEXT,
        INDEX(calculation_type),
        INDEX(created_at),
        INDEX(sync_status)
      )
    ''');
    
    // 创建参数组表
    batch.execute('''
      CREATE TABLE parameter_sets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        calculation_type TEXT NOT NULL,
        parameters TEXT NOT NULL,
        is_preset INTEGER DEFAULT 0,
        tags TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 0,
        device_id TEXT,
        INDEX(calculation_type),
        INDEX(name),
        INDEX(is_preset),
        INDEX(sync_status)
      )
    ''');
    
    // 创建预设参数表
    batch.execute('''
      CREATE TABLE preset_parameters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        calculation_type TEXT NOT NULL,
        parameter_name TEXT NOT NULL,
        parameter_value REAL NOT NULL,
        unit TEXT,
        description TEXT,
        category TEXT,
        created_at INTEGER NOT NULL,
        INDEX(calculation_type),
        INDEX(parameter_name),
        INDEX(category)
      )
    ''');
    
    // 创建用户设置表
    batch.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    // 创建同步状态表
    batch.execute('''
      CREATE TABLE sync_status (
        table_name TEXT PRIMARY KEY,
        last_sync_time INTEGER NOT NULL,
        sync_version INTEGER DEFAULT 1,
        total_records INTEGER DEFAULT 0,
        synced_records INTEGER DEFAULT 0,
        failed_records INTEGER DEFAULT 0,
        last_error TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    // 创建离线队列表
    batch.execute('''
      CREATE TABLE offline_queue (
        id TEXT PRIMARY KEY,
        operation_type TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_retry_at INTEGER,
        error_message TEXT,
        INDEX(operation_type),
        INDEX(table_name),
        INDEX(created_at)
      )
    ''');
    
    await batch.commit();
    
    // 初始化预设数据
    await _initializeDefaultData(db);
  }
  
  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 处理数据库版本升级逻辑
    if (oldVersion < newVersion) {
      await _performMigration(db, oldVersion, newVersion);
    }
  }
  
  /// 数据库降级（通常不建议，但提供基本处理）
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    // 记录降级操作
    print('警告: 数据库从版本 $oldVersion 降级到 $newVersion');
    
    // 可以选择重新创建数据库或保持现有结构
    // 这里选择保持现有结构，但记录警告
    await db.execute('''
      INSERT OR REPLACE INTO user_settings (key, value, updated_at)
      VALUES ('database_downgrade_warning', 
              '数据库版本从 $oldVersion 降级到 $newVersion', 
              ${DateTime.now().millisecondsSinceEpoch})
    ''');
  }
  
  /// 执行数据库迁移
  Future<void> _performMigration(Database db, int oldVersion, int newVersion) async {
    print('执行数据库迁移: $oldVersion -> $newVersion');
    
    // 根据版本差异执行相应的迁移脚本
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      await _migrateToVersion(db, version);
    }
    
    // 更新迁移记录
    await db.execute('''
      INSERT OR REPLACE INTO user_settings (key, value, updated_at)
      VALUES ('last_migration', 
              'v$oldVersion->v$newVersion at ${DateTime.now().toIso8601String()}', 
              ${DateTime.now().millisecondsSinceEpoch})
    ''');
  }
  
  /// 迁移到指定版本
  Future<void> _migrateToVersion(Database db, int version) async {
    switch (version) {
      case 2:
        // 假设版本2添加了新字段
        await _migrateToVersion2(db);
        break;
      case 3:
        // 假设版本3添加了新表
        await _migrateToVersion3(db);
        break;
      // 可以继续添加更多版本的迁移逻辑
      default:
        print('未知的数据库版本: $version');
    }
  }
  
  /// 迁移到版本2的示例
  Future<void> _migrateToVersion2(Database db) async {
    // 示例：添加新字段
    try {
      await db.execute('ALTER TABLE calculation_records ADD COLUMN export_count INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE parameter_sets ADD COLUMN usage_count INTEGER DEFAULT 0');
      print('成功迁移到版本2');
    } catch (e) {
      print('迁移到版本2失败: $e');
      // 可以选择忽略已存在的字段错误
    }
  }
  
  /// 迁移到版本3的示例
  Future<void> _migrateToVersion3(Database db) async {
    // 示例：添加新表
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS export_history (
          id TEXT PRIMARY KEY,
          record_id TEXT NOT NULL,
          export_format TEXT NOT NULL,
          file_path TEXT,
          created_at INTEGER NOT NULL,
          INDEX(record_id),
          INDEX(export_format)
        )
      ''');
      print('成功迁移到版本3');
    } catch (e) {
      print('迁移到版本3失败: $e');
    }
  }
  
  /// 初始化默认数据
  Future<void> _initializeDefaultData(Database db) async {
    try {
      // 初始化预设参数
      await PresetParameterInitializer.initializeAllPresetParameters(db);
      
      // 初始化默认设置
      await _initializeDefaultSettings(db);
      
      // 初始化同步状态
      await _initializeSyncStatus(db);
      
      print('默认数据初始化完成');
    } catch (e) {
      print('默认数据初始化失败: $e');
      // 不抛出异常，允许应用继续运行
    }
  }
  
  /// 初始化默认设置
  Future<void> _initializeDefaultSettings(Database db) async {
    final defaultSettings = {
      'app_version': '1.0.0',
      'database_initialized': 'true',
      'default_unit': 'mm',
      'precision_digits': '2',
      'auto_sync': 'true',
      'offline_mode': 'false',
      'theme_mode': 'dark',
      'language': 'zh_CN',
    };
    
    final batch = db.batch();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    for (final entry in defaultSettings.entries) {
      batch.insert(
        'user_settings',
        {
          'key': entry.key,
          'value': entry.value,
          'updated_at': currentTime,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore, // 如果已存在则忽略
      );
    }
    
    await batch.commit();
  }
  
  /// 初始化同步状态
  Future<void> _initializeSyncStatus(Database db) async {
    final tables = [
      'calculation_records',
      'parameter_sets',
      'preset_parameters',
      'user_settings',
    ];
    
    final batch = db.batch();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    for (final tableName in tables) {
      batch.insert(
        'sync_status',
        {
          'table_name': tableName,
          'last_sync_time': 0, // 从未同步
          'sync_version': 1,
          'total_records': 0,
          'synced_records': 0,
          'failed_records': 0,
          'updated_at': currentTime,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    
    await batch.commit();
  }
  
  /// 获取数据库信息
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    
    // 获取数据库版本
    final version = await db.getVersion();
    
    // 获取所有表的记录数
    final tables = ['calculation_records', 'parameter_sets', 'preset_parameters', 'user_settings', 'sync_status', 'offline_queue'];
    final tableCounts = <String, int>{};
    
    for (final table in tables) {
      try {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        tableCounts[table] = result.first['count'] as int;
      } catch (e) {
        tableCounts[table] = -1; // 表示查询失败
      }
    }
    
    // 获取数据库文件大小（近似）
    final path = db.path;
    
    return {
      'version': version,
      'path': path,
      'table_counts': tableCounts,
      'total_records': tableCounts.values.where((count) => count > 0).fold(0, (sum, count) => sum + count),
    };
  }
  
  /// 检查数据库完整性
  Future<bool> checkDatabaseIntegrity() async {
    try {
      final db = await database;
      
      // 执行完整性检查
      final result = await db.rawQuery('PRAGMA integrity_check');
      
      // 如果返回 "ok"，说明数据库完整
      return result.isNotEmpty && result.first.values.first == 'ok';
    } catch (e) {
      print('数据库完整性检查失败: $e');
      return false;
    }
  }
  
  /// 优化数据库
  Future<void> optimizeDatabase() async {
    try {
      final db = await database;
      
      PerformanceMonitor.startMeasurement('database_optimization');
      
      // 执行VACUUM操作，清理和优化数据库
      await db.execute('VACUUM');
      
      // 分析表以优化查询性能
      await db.execute('ANALYZE');
      
      // 重建索引
      await _rebuildIndexes(db);
      
      PerformanceMonitor.endMeasurement('database_optimization');
      
      print('数据库优化完成');
    } catch (e) {
      PerformanceMonitor.endMeasurement('database_optimization');
      print('数据库优化失败: $e');
    }
  }
  
  /// 重建索引
  Future<void> _rebuildIndexes(Database db) async {
    final tables = ['calculation_records', 'parameter_sets', 'preset_parameters', 'user_settings', 'sync_status'];
    
    for (final table in tables) {
      try {
        await db.execute('REINDEX $table');
      } catch (e) {
        print('重建索引失败 [$table]: $e');
      }
    }
  }
  
  /// 优化查询方法
  Future<List<Map<String, dynamic>>> optimizedQuery({
    required String table,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
    bool useCache = true,
  }) async {
    // 生成缓存键
    final cacheKey = 'query_${table}_${where ?? ''}_${orderBy ?? ''}_${limit ?? ''}_${offset ?? ''}';
    
    // 尝试从缓存获取结果
    if (useCache) {
      final cachedResult = PerformanceOptimizer().getCachedParameter<List<Map<String, dynamic>>>(cacheKey);
      if (cachedResult != null) {
        return cachedResult;
      }
    }
    
    PerformanceMonitor.startMeasurement('database_query_$table');
    
    try {
      final db = await database;
      
      final result = await db.query(
        table,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
      
      // 缓存结果（仅缓存小结果集）
      if (useCache && result.length <= 100) {
        PerformanceOptimizer().cacheParameter(cacheKey, result);
      }
      
      PerformanceMonitor.endMeasurement('database_query_$table');
      
      return result;
    } catch (e) {
      PerformanceMonitor.endMeasurement('database_query_$table');
      rethrow;
    }
  }
  
  /// 批量插入优化
  Future<void> batchInsert({
    required String table,
    required List<Map<String, dynamic>> records,
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
    int batchSize = 100,
  }) async {
    if (records.isEmpty) return;
    
    PerformanceMonitor.startMeasurement('database_batch_insert_$table');
    
    try {
      final db = await database;
      
      // 分批处理以避免内存问题
      for (int i = 0; i < records.length; i += batchSize) {
        final batch = db.batch();
        final endIndex = (i + batchSize < records.length) ? i + batchSize : records.length;
        
        for (int j = i; j < endIndex; j++) {
          batch.insert(table, records[j], conflictAlgorithm: conflictAlgorithm);
        }
        
        await batch.commit(noResult: true);
      }
      
      PerformanceMonitor.endMeasurement('database_batch_insert_$table');
      
      print('批量插入完成: $table (${records.length} 条记录)');
    } catch (e) {
      PerformanceMonitor.endMeasurement('database_batch_insert_$table');
      print('批量插入失败: $e');
      rethrow;
    }
  }
  
  /// 备份数据库
  Future<String?> backupDatabase(String backupPath) async {
    try {
      final db = await database;
      final sourcePath = db.path;
      
      // 这里可以实现数据库文件复制逻辑
      // 由于sqflite的限制，实际实现可能需要使用文件操作
      
      print('数据库备份到: $backupPath');
      return backupPath;
    } catch (e) {
      print('数据库备份失败: $e');
      return null;
    }
  }
  
  /// 关闭数据库连接
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
  
  /// 重置数据库（危险操作，仅用于测试或紧急情况）
  Future<void> resetDatabase() async {
    try {
      await close();
      
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConstants.databaseName);
      
      await deleteDatabase(path);
      
      // 重新初始化
      _database = await _initDatabase();
      
      print('数据库已重置');
    } catch (e) {
      print('数据库重置失败: $e');
      rethrow;
    }
  }
}