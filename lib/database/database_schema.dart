// 油气管道开孔封堵计算系统 - SQLite数据库Schema定义
// 版本: 1.0.0
// 用途: 定义本地SQLite数据库结构

/// 数据库版本
const int kDatabaseVersion = 1;

/// 数据库名称
const String kDatabaseName = 'pipeline_calculation.db';

/// 表名常量
class TableNames {
  static const String calculationRecords = 'calculation_records';
  static const String parameterSets = 'parameter_sets';
  static const String userSettings = 'user_settings';
  static const String syncStatus = 'sync_status';
}

/// 计算记录表Schema
class CalculationRecordsSchema {
  static const String tableName = TableNames.calculationRecords;
  
  // 列名
  static const String columnId = 'id';
  static const String columnCalculationType = 'calculation_type';
  static const String columnParameters = 'parameters';
  static const String columnResults = 'results';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnDeviceId = 'device_id';
  static const String columnSyncStatus = 'sync_status';
  static const String columnServerId = 'server_id';
  static const String columnClientId = 'client_id';
  
  /// 创建表SQL
  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnCalculationType TEXT NOT NULL,
      $columnParameters TEXT NOT NULL,
      $columnResults TEXT NOT NULL,
      $columnCreatedAt INTEGER NOT NULL,
      $columnUpdatedAt INTEGER NOT NULL,
      $columnDeviceId TEXT,
      $columnSyncStatus TEXT NOT NULL DEFAULT 'pending',
      $columnServerId TEXT,
      $columnClientId TEXT
    )
  ''';
  
  /// 创建索引SQL
  static const List<String> createIndexSql = [
    'CREATE INDEX idx_calc_type ON $tableName($columnCalculationType)',
    'CREATE INDEX idx_calc_created ON $tableName($columnCreatedAt DESC)',
    'CREATE INDEX idx_calc_sync ON $tableName($columnSyncStatus)',
    'CREATE INDEX idx_calc_server ON $tableName($columnServerId)',
  ];
}

/// 参数组表Schema
class ParameterSetsSchema {
  static const String tableName = TableNames.parameterSets;
  
  // 列名
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnCalculationType = 'calculation_type';
  static const String columnParameters = 'parameters';
  static const String columnIsPreset = 'is_preset';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnSyncStatus = 'sync_status';
  static const String columnServerId = 'server_id';
  
  /// 创建表SQL
  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnName TEXT NOT NULL,
      $columnCalculationType TEXT NOT NULL,
      $columnParameters TEXT NOT NULL,
      $columnIsPreset INTEGER NOT NULL DEFAULT 0,
      $columnCreatedAt INTEGER NOT NULL,
      $columnUpdatedAt INTEGER NOT NULL,
      $columnSyncStatus TEXT NOT NULL DEFAULT 'pending',
      $columnServerId TEXT
    )
  ''';
  
  /// 创建索引SQL
  static const List<String> createIndexSql = [
    'CREATE INDEX idx_param_type ON $tableName($columnCalculationType)',
    'CREATE INDEX idx_param_name ON $tableName($columnName)',
    'CREATE INDEX idx_param_preset ON $tableName($columnIsPreset)',
    'CREATE INDEX idx_param_sync ON $tableName($columnSyncStatus)',
  ];
}

/// 用户设置表Schema
class UserSettingsSchema {
  static const String tableName = TableNames.userSettings;
  
  // 列名
  static const String columnKey = 'key';
  static const String columnValue = 'value';
  static const String columnUpdatedAt = 'updated_at';
  
  /// 创建表SQL
  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnKey TEXT PRIMARY KEY,
      $columnValue TEXT NOT NULL,
      $columnUpdatedAt INTEGER NOT NULL
    )
  ''';
}

/// 同步状态表Schema
class SyncStatusSchema {
  static const String tableName = TableNames.syncStatus;
  
  // 列名
  static const String columnId = 'id';
  static const String columnEntityType = 'entity_type';
  static const String columnEntityId = 'entity_id';
  static const String columnSyncAction = 'sync_action';
  static const String columnSyncTime = 'sync_time';
  static const String columnStatus = 'status';
  static const String columnErrorMessage = 'error_message';
  static const String columnRetryCount = 'retry_count';
  
  /// 创建表SQL
  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnEntityType TEXT NOT NULL,
      $columnEntityId TEXT NOT NULL,
      $columnSyncAction TEXT NOT NULL,
      $columnSyncTime INTEGER NOT NULL,
      $columnStatus TEXT NOT NULL,
      $columnErrorMessage TEXT,
      $columnRetryCount INTEGER NOT NULL DEFAULT 0
    )
  ''';
  
  /// 创建索引SQL
  static const List<String> createIndexSql = [
    'CREATE INDEX idx_sync_entity ON $tableName($columnEntityType, $columnEntityId)',
    'CREATE INDEX idx_sync_status ON $tableName($columnStatus)',
    'CREATE INDEX idx_sync_time ON $tableName($columnSyncTime DESC)',
  ];
}

/// 同步状态枚举
enum SyncStatus {
  pending('pending'),      // 待同步
  syncing('syncing'),      // 同步中
  synced('synced'),        // 已同步
  conflict('conflict'),    // 冲突
  error('error');          // 错误
  
  final String value;
  const SyncStatus(this.value);
  
  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SyncStatus.pending,
    );
  }
}

/// 同步操作枚举
enum SyncAction {
  upload('upload'),        // 上传
  download('download'),    // 下载
  delete('delete');        // 删除
  
  final String value;
  const SyncAction(this.value);
  
  static SyncAction fromString(String value) {
    return SyncAction.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SyncAction.upload,
    );
  }
}

/// 实体类型枚举
enum EntityType {
  calculationRecord('calculation_record'),
  parameterSet('parameter_set');
  
  final String value;
  const EntityType(this.value);
  
  static EntityType fromString(String value) {
    return EntityType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EntityType.calculationRecord,
    );
  }
}

/// 数据库迁移脚本
class DatabaseMigrations {
  /// 获取所有创建表的SQL语句
  static List<String> getCreateTableStatements() {
    return [
      CalculationRecordsSchema.createTableSql,
      ParameterSetsSchema.createTableSql,
      UserSettingsSchema.createTableSql,
      SyncStatusSchema.createTableSql,
    ];
  }
  
  /// 获取所有创建索引的SQL语句
  static List<String> getCreateIndexStatements() {
    return [
      ...CalculationRecordsSchema.createIndexSql,
      ...ParameterSetsSchema.createIndexSql,
      ...SyncStatusSchema.createIndexSql,
    ];
  }
  
  /// 获取版本1的迁移脚本
  static List<String> getMigrationV1() {
    return [
      ...getCreateTableStatements(),
      ...getCreateIndexStatements(),
    ];
  }
  
  /// 获取版本2的迁移脚本（示例）
  static List<String> getMigrationV2() {
    return [
      // 示例：添加新字段
      // 'ALTER TABLE ${TableNames.calculationRecords} ADD COLUMN new_field TEXT',
    ];
  }
}

/// 数据库配置
class DatabaseConfig {
  /// 数据库版本
  static const int version = kDatabaseVersion;
  
  /// 数据库名称
  static const String name = kDatabaseName;
  
  /// 是否启用外键约束
  static const bool enableForeignKeys = true;
  
  /// 是否启用WAL模式（Write-Ahead Logging）
  /// WAL模式提供更好的并发性能
  static const bool enableWAL = true;
  
  /// 缓存大小（页数）
  /// 默认2000页，每页约1KB，总计约2MB
  static const int cacheSize = 2000;
  
  /// 同步模式
  /// NORMAL: 平衡性能和安全性
  /// FULL: 最安全但最慢
  /// OFF: 最快但不安全
  static const String synchronousMode = 'NORMAL';
  
  /// 日志模式
  /// WAL: Write-Ahead Logging（推荐）
  /// DELETE: 传统模式
  /// TRUNCATE: 截断模式
  /// PERSIST: 持久化模式
  static const String journalMode = 'WAL';
  
  /// 临时存储位置
  /// MEMORY: 内存（更快）
  /// FILE: 文件（更安全）
  static const String tempStore = 'MEMORY';
}
