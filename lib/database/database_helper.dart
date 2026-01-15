// 油气管道开孔封堵计算系统 - SQLite数据库助手
// 版本: 1.0.0
// 用途: 管理SQLite数据库连接和操作

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_schema.dart';

/// 数据库助手类
/// 
/// 单例模式，管理SQLite数据库的创建、升级和访问
class DatabaseHelper {
  // 单例实例
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  
  /// 获取单例实例
  factory DatabaseHelper() => _instance;
  
  /// 私有构造函数
  DatabaseHelper._internal();
  
  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  /// 初始化数据库
  Future<Database> _initDatabase() async {
    // 获取数据库路径
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConfig.name);
    
    // 打开数据库
    return await openDatabase(
      path,
      version: DatabaseConfig.version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
      onOpen: _onOpen,
    );
  }
  
  /// 配置数据库
  Future<void> _onConfigure(Database db) async {
    // 启用外键约束
    if (DatabaseConfig.enableForeignKeys) {
      await db.execute('PRAGMA foreign_keys = ON');
    }
    
    // 设置缓存大小
    await db.execute('PRAGMA cache_size = ${DatabaseConfig.cacheSize}');
    
    // 设置同步模式
    await db.execute('PRAGMA synchronous = ${DatabaseConfig.synchronousMode}');
    
    // 设置临时存储位置
    await db.execute('PRAGMA temp_store = ${DatabaseConfig.tempStore}');
  }
  
  /// 打开数据库时的回调
  Future<void> _onOpen(Database db) async {
    // 启用WAL模式
    if (DatabaseConfig.enableWAL) {
      await db.execute('PRAGMA journal_mode = ${DatabaseConfig.journalMode}');
    }
    
    print('数据库已打开: ${DatabaseConfig.name} v${DatabaseConfig.version}');
  }
  
  /// 创建数据库
  Future<void> _onCreate(Database db, int version) async {
    print('创建数据库: v$version');
    
    // 执行所有创建表的SQL语句
    for (final sql in DatabaseMigrations.getCreateTableStatements()) {
      await db.execute(sql);
    }
    
    // 执行所有创建索引的SQL语句
    for (final sql in DatabaseMigrations.getCreateIndexStatements()) {
      await db.execute(sql);
    }
    
    // 插入默认设置
    await _insertDefaultSettings(db);
    
    print('数据库创建完成');
  }
  
  /// 升级数据库
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('升级数据库: v$oldVersion -> v$newVersion');
    
    // 根据版本执行相应的迁移脚本
    if (oldVersion < 2 && newVersion >= 2) {
      for (final sql in DatabaseMigrations.getMigrationV2()) {
        await db.execute(sql);
      }
    }
    
    // 可以添加更多版本的迁移逻辑
    
    print('数据库升级完成');
  }
  
  /// 插入默认设置
  Future<void> _insertDefaultSettings(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final defaultSettings = [
      {
        UserSettingsSchema.columnKey: 'theme_mode',
        UserSettingsSchema.columnValue: 'system',
        UserSettingsSchema.columnUpdatedAt: now,
      },
      {
        UserSettingsSchema.columnKey: 'language',
        UserSettingsSchema.columnValue: 'zh_CN',
        UserSettingsSchema.columnUpdatedAt: now,
      },
      {
        UserSettingsSchema.columnKey: 'sync_enabled',
        UserSettingsSchema.columnValue: 'false',
        UserSettingsSchema.columnUpdatedAt: now,
      },
      {
        UserSettingsSchema.columnKey: 'auto_backup',
        UserSettingsSchema.columnValue: 'true',
        UserSettingsSchema.columnUpdatedAt: now,
      },
      {
        UserSettingsSchema.columnKey: 'device_id',
        UserSettingsSchema.columnValue: _generateDeviceId(),
        UserSettingsSchema.columnUpdatedAt: now,
      },
    ];
    
    for (final setting in defaultSettings) {
      await db.insert(
        UserSettingsSchema.tableName,
        setting,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
  
  /// 生成设备ID
  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'device_${timestamp}_$random';
  }
  
  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('数据库已关闭');
  }
  
  /// 删除数据库
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConfig.name);
    
    await close();
    await databaseFactory.deleteDatabase(path);
    print('数据库已删除: $path');
  }
  
  /// 获取数据库路径
  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, DatabaseConfig.name);
  }
  
  /// 获取数据库大小（字节）
  Future<int> getDatabaseSize() async {
    final path = await getDatabasePath();
    final file = await databaseFactory.databaseExists(path);
    if (!file) return 0;
    
    // 注意：sqflite不直接提供文件大小API
    // 需要使用dart:io的File类
    // 这里返回0作为占位符
    return 0;
  }
  
  /// 检查数据库是否存在
  Future<bool> databaseExists() async {
    final path = await getDatabasePath();
    return await databaseFactory.databaseExists(path);
  }
  
  /// 执行原始SQL查询
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }
  
  /// 执行原始SQL语句
  Future<int> rawExecute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }
  
  /// 开始事务
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }
  
  /// 批量操作
  Future<List<dynamic>> batch(void Function(Batch batch) operations) async {
    final db = await database;
    final batch = db.batch();
    operations(batch);
    return await batch.commit();
  }
  
  /// 清空所有表数据（保留表结构）
  Future<void> clearAllData() async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete(TableNames.calculationRecords);
      await txn.delete(TableNames.parameterSets);
      await txn.delete(TableNames.syncStatus);
      // 不清空用户设置
      print('所有数据已清空');
    });
  }
  
  /// 获取数据库统计信息
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    
    final calcCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${TableNames.calculationRecords}'),
    ) ?? 0;
    
    final paramCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${TableNames.parameterSets}'),
    ) ?? 0;
    
    final syncCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${TableNames.syncStatus}'),
    ) ?? 0;
    
    final pendingSyncCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${TableNames.calculationRecords} WHERE ${CalculationRecordsSchema.columnSyncStatus} = ?',
        [SyncStatus.pending.value],
      ),
    ) ?? 0;
    
    return {
      'calculation_records': calcCount,
      'parameter_sets': paramCount,
      'sync_status': syncCount,
      'pending_sync': pendingSyncCount,
      'database_version': DatabaseConfig.version,
      'database_name': DatabaseConfig.name,
    };
  }
  
  /// 导出数据库为JSON
  Future<Map<String, dynamic>> exportToJson() async {
    final db = await database;
    
    final calculations = await db.query(TableNames.calculationRecords);
    final parameters = await db.query(TableNames.parameterSets);
    final settings = await db.query(TableNames.userSettings);
    
    return {
      'version': DatabaseConfig.version,
      'exported_at': DateTime.now().toIso8601String(),
      'data': {
        'calculation_records': calculations,
        'parameter_sets': parameters,
        'user_settings': settings,
      },
    };
  }
  
  /// 从JSON导入数据
  Future<void> importFromJson(Map<String, dynamic> json) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // 清空现有数据
      await txn.delete(TableNames.calculationRecords);
      await txn.delete(TableNames.parameterSets);
      
      // 导入计算记录
      final calculations = json['data']['calculation_records'] as List<dynamic>;
      for (final calc in calculations) {
        await txn.insert(
          TableNames.calculationRecords,
          calc as Map<String, dynamic>,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      // 导入参数组
      final parameters = json['data']['parameter_sets'] as List<dynamic>;
      for (final param in parameters) {
        await txn.insert(
          TableNames.parameterSets,
          param as Map<String, dynamic>,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      // 导入设置（可选）
      if (json['data'].containsKey('user_settings')) {
        final settings = json['data']['user_settings'] as List<dynamic>;
        for (final setting in settings) {
          await txn.insert(
            UserSettingsSchema.tableName,
            setting as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      
      print('数据导入完成');
    });
  }
  
  /// 优化数据库
  Future<void> optimize() async {
    final db = await database;
    
    // 执行VACUUM命令，重建数据库文件
    await db.execute('VACUUM');
    
    // 分析数据库，更新统计信息
    await db.execute('ANALYZE');
    
    print('数据库优化完成');
  }
  
  /// 检查数据库完整性
  Future<bool> checkIntegrity() async {
    final db = await database;
    
    final result = await db.rawQuery('PRAGMA integrity_check');
    final isOk = result.isNotEmpty && result.first.values.first == 'ok';
    
    if (isOk) {
      print('数据库完整性检查通过');
    } else {
      print('数据库完整性检查失败: $result');
    }
    
    return isOk;
  }
}


/// DatabaseHelper扩展 - 用于测试
extension DatabaseHelperTestExtensions on DatabaseHelper {
  /// 获取单例实例（用于测试）
  static DatabaseHelper get instance => DatabaseHelper._instance;
  
  /// 删除所有计算记录（用于测试）
  Future<void> deleteAllRecords() async {
    final db = await database;
    await db.delete(TableNames.calculationRecords);
  }
  
  /// 删除所有参数组（用于测试）
  Future<void> deleteAllParameterSets() async {
    final db = await database;
    await db.delete(TableNames.parameterSets);
  }
}
