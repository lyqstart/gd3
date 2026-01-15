import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';
import '../models/enums.dart';

/// 数据完整性检查类型
enum IntegrityCheckType {
  structure,    // 结构检查
  content,      // 内容检查
  consistency,  // 一致性检查
  corruption,   // 损坏检查
  foreign_key,  // 外键检查
}

/// 数据完整性问题级别
enum IntegrityIssueLevel {
  info,     // 信息
  warning,  // 警告
  error,    // 错误
  critical, // 严重
}

/// 数据完整性问题
class IntegrityIssue {
  final String id;
  final IntegrityCheckType checkType;
  final IntegrityIssueLevel level;
  final String tableName;
  final String? recordId;
  final String description;
  final String? suggestion;
  final Map<String, dynamic> metadata;
  final DateTime detectedAt;
  bool isFixed;
  DateTime? fixedAt;
  String? fixMethod;
  
  IntegrityIssue({
    required this.id,
    required this.checkType,
    required this.level,
    required this.tableName,
    this.recordId,
    required this.description,
    this.suggestion,
    this.metadata = const {},
    required this.detectedAt,
    this.isFixed = false,
    this.fixedAt,
    this.fixMethod,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'check_type': checkType.toString(),
    'level': level.toString(),
    'table_name': tableName,
    'record_id': recordId,
    'description': description,
    'suggestion': suggestion,
    'metadata': metadata,
    'detected_at': detectedAt.toIso8601String(),
    'is_fixed': isFixed,
    'fixed_at': fixedAt?.toIso8601String(),
    'fix_method': fixMethod,
  };
  
  factory IntegrityIssue.fromJson(Map<String, dynamic> json) => IntegrityIssue(
    id: json['id'],
    checkType: IntegrityCheckType.values.firstWhere(
      (type) => type.toString() == json['check_type'],
    ),
    level: IntegrityIssueLevel.values.firstWhere(
      (level) => level.toString() == json['level'],
    ),
    tableName: json['table_name'],
    recordId: json['record_id'],
    description: json['description'],
    suggestion: json['suggestion'],
    metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    detectedAt: DateTime.parse(json['detected_at']),
    isFixed: json['is_fixed'] ?? false,
    fixedAt: json['fixed_at'] != null ? DateTime.parse(json['fixed_at']) : null,
    fixMethod: json['fix_method'],
  );
}

/// 数据备份信息
class DataBackup {
  final String id;
  final String name;
  final String description;
  final String filePath;
  final int fileSize;
  final String checksum;
  final DateTime createdAt;
  final Map<String, int> tableCounts;
  final bool isAutomatic;
  final String? triggerReason;
  
  DataBackup({
    required this.id,
    required this.name,
    required this.description,
    required this.filePath,
    required this.fileSize,
    required this.checksum,
    required this.createdAt,
    required this.tableCounts,
    this.isAutomatic = false,
    this.triggerReason,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'file_path': filePath,
    'file_size': fileSize,
    'checksum': checksum,
    'created_at': createdAt.toIso8601String(),
    'table_counts': tableCounts,
    'is_automatic': isAutomatic,
    'trigger_reason': triggerReason,
  };
  
  factory DataBackup.fromJson(Map<String, dynamic> json) => DataBackup(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    filePath: json['file_path'],
    fileSize: json['file_size'],
    checksum: json['checksum'],
    createdAt: DateTime.parse(json['created_at']),
    tableCounts: Map<String, int>.from(json['table_counts']),
    isAutomatic: json['is_automatic'] ?? false,
    triggerReason: json['trigger_reason'],
  );
}

/// 数据完整性检查结果
class IntegrityCheckResult {
  final String checkId;
  final IntegrityCheckType checkType;
  final DateTime checkTime;
  final Duration checkDuration;
  final List<IntegrityIssue> issues;
  final Map<String, dynamic> statistics;
  final bool passed;
  
  IntegrityCheckResult({
    required this.checkId,
    required this.checkType,
    required this.checkTime,
    required this.checkDuration,
    required this.issues,
    required this.statistics,
    required this.passed,
  });
  
  int get criticalIssues => issues.where((i) => i.level == IntegrityIssueLevel.critical).length;
  int get errorIssues => issues.where((i) => i.level == IntegrityIssueLevel.error).length;
  int get warningIssues => issues.where((i) => i.level == IntegrityIssueLevel.warning).length;
  int get infoIssues => issues.where((i) => i.level == IntegrityIssueLevel.info).length;
  
  Map<String, dynamic> toJson() => {
    'check_id': checkId,
    'check_type': checkType.toString(),
    'check_time': checkTime.toIso8601String(),
    'check_duration': checkDuration.inMilliseconds,
    'issues': issues.map((i) => i.toJson()).toList(),
    'statistics': statistics,
    'passed': passed,
    'critical_issues': criticalIssues,
    'error_issues': errorIssues,
    'warning_issues': warningIssues,
    'info_issues': infoIssues,
  };
}

/// 数据完整性服务
/// 
/// 负责数据备份、恢复、完整性检查和数据损坏恢复
class DataIntegrityService {
  static DataIntegrityService? _instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  bool _isInitialized = false;
  Timer? _autoBackupTimer;
  Timer? _integrityCheckTimer;
  
  final StreamController<IntegrityCheckResult> _checkResultController = 
      StreamController<IntegrityCheckResult>.broadcast();
  final StreamController<DataBackup> _backupController = 
      StreamController<DataBackup>.broadcast();
  
  /// 单例模式
  DataIntegrityService._internal();
  
  factory DataIntegrityService() {
    _instance ??= DataIntegrityService._internal();
    return _instance!;
  }
  
  /// 完整性检查结果流
  Stream<IntegrityCheckResult> get checkResultStream => _checkResultController.stream;
  
  /// 备份完成流
  Stream<DataBackup> get backupStream => _backupController.stream;
  
  /// 初始化数据完整性服务
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 确保数据库已初始化
      await _dbHelper.database;
      
      // 创建完整性相关表
      await _createIntegrityTables();
      
      // 启动自动备份
      await _startAutoBackup();
      
      // 启动定期完整性检查
      await _startPeriodicIntegrityCheck();
      
      // 执行初始完整性检查
      await _performInitialIntegrityCheck();
      
      _isInitialized = true;
      print('数据完整性服务初始化完成');
      
    } catch (e) {
      print('数据完整性服务初始化失败: $e');
      rethrow;
    }
  }
  
  /// 创建完整性相关表
  Future<void> _createIntegrityTables() async {
    final db = await _dbHelper.database;
    
    // 创建完整性问题表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS integrity_issues (
        id TEXT PRIMARY KEY,
        check_type TEXT NOT NULL,
        level TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT,
        description TEXT NOT NULL,
        suggestion TEXT,
        metadata TEXT DEFAULT '{}',
        detected_at INTEGER NOT NULL,
        is_fixed INTEGER DEFAULT 0,
        fixed_at INTEGER,
        fix_method TEXT,
        INDEX(check_type),
        INDEX(level),
        INDEX(table_name),
        INDEX(is_fixed),
        INDEX(detected_at)
      )
    ''');
    
    // 创建数据备份表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS data_backups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        file_path TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        checksum TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        table_counts TEXT NOT NULL,
        is_automatic INTEGER DEFAULT 0,
        trigger_reason TEXT,
        INDEX(created_at),
        INDEX(is_automatic)
      )
    ''');
    
    // 创建完整性检查历史表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS integrity_check_history (
        id TEXT PRIMARY KEY,
        check_type TEXT NOT NULL,
        check_time INTEGER NOT NULL,
        check_duration INTEGER NOT NULL,
        issues_found INTEGER NOT NULL,
        critical_issues INTEGER DEFAULT 0,
        error_issues INTEGER DEFAULT 0,
        warning_issues INTEGER DEFAULT 0,
        info_issues INTEGER DEFAULT 0,
        passed INTEGER NOT NULL,
        statistics TEXT DEFAULT '{}',
        INDEX(check_type),
        INDEX(check_time),
        INDEX(passed)
      )
    ''');
    
    print('完整性相关表创建完成');
  }
  
  /// 启动自动备份
  Future<void> _startAutoBackup() async {
    // 每天自动备份一次
    _autoBackupTimer = Timer.periodic(const Duration(hours: 24), (timer) async {
      try {
        await createBackup(
          name: '自动备份_${DateTime.now().toIso8601String().split('T')[0]}',
          description: '系统自动创建的每日备份',
          isAutomatic: true,
          triggerReason: 'daily_auto_backup',
        );
      } catch (e) {
        print('自动备份失败: $e');
      }
    });
    
    print('自动备份已启动');
  }
  
  /// 启动定期完整性检查
  Future<void> _startPeriodicIntegrityCheck() async {
    // 每6小时检查一次
    _integrityCheckTimer = Timer.periodic(const Duration(hours: 6), (timer) async {
      try {
        await performIntegrityCheck(IntegrityCheckType.consistency);
      } catch (e) {
        print('定期完整性检查失败: $e');
      }
    });
    
    print('定期完整性检查已启动');
  }
  
  /// 执行初始完整性检查
  Future<void> _performInitialIntegrityCheck() async {
    try {
      // 执行结构检查
      await performIntegrityCheck(IntegrityCheckType.structure);
      
      // 执行内容检查
      await performIntegrityCheck(IntegrityCheckType.content);
      
      print('初始完整性检查完成');
      
    } catch (e) {
      print('初始完整性检查失败: $e');
    }
  }
  
  /// 创建数据备份
  Future<DataBackup> createBackup({
    required String name,
    String? description,
    bool isAutomatic = false,
    String? triggerReason,
  }) async {
    final backupId = const Uuid().v4();
    final timestamp = DateTime.now();
    
    try {
      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(join(appDir.path, 'backups'));
      
      // 确保备份目录存在
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      // 生成备份文件路径
      final backupFileName = 'backup_${timestamp.millisecondsSinceEpoch}.db';
      final backupFilePath = join(backupDir.path, backupFileName);
      
      // 获取数据库文件路径
      final db = await _dbHelper.database;
      final dbPath = db.path;
      
      // 复制数据库文件
      final dbFile = File(dbPath);
      final backupFile = File(backupFilePath);
      await dbFile.copy(backupFilePath);
      
      // 计算文件大小和校验和
      final fileSize = await backupFile.length();
      final fileBytes = await backupFile.readAsBytes();
      final checksum = sha256.convert(fileBytes).toString();
      
      // 获取表记录数统计
      final tableCounts = await _getTableCounts();
      
      // 创建备份信息
      final backup = DataBackup(
        id: backupId,
        name: name,
        description: description ?? '数据备份',
        filePath: backupFilePath,
        fileSize: fileSize,
        checksum: checksum,
        createdAt: timestamp,
        tableCounts: tableCounts,
        isAutomatic: isAutomatic,
        triggerReason: triggerReason,
      );
      
      // 保存备份信息到数据库
      await db.insert(
        'data_backups',
        {
          'id': backup.id,
          'name': backup.name,
          'description': backup.description,
          'file_path': backup.filePath,
          'file_size': backup.fileSize,
          'checksum': backup.checksum,
          'created_at': backup.createdAt.millisecondsSinceEpoch,
          'table_counts': jsonEncode(backup.tableCounts),
          'is_automatic': backup.isAutomatic ? 1 : 0,
          'trigger_reason': backup.triggerReason,
        },
      );
      
      // 发送备份完成事件
      _backupController.add(backup);
      
      print('数据备份创建成功: ${backup.name}');
      return backup;
      
    } catch (e) {
      print('创建数据备份失败: $e');
      rethrow;
    }
  }
  
  /// 恢复数据备份
  Future<void> restoreBackup(String backupId) async {
    try {
      final db = await _dbHelper.database;
      
      // 获取备份信息
      final backupResult = await db.query(
        'data_backups',
        where: 'id = ?',
        whereArgs: [backupId],
      );
      
      if (backupResult.isEmpty) {
        throw ArgumentError('备份不存在: $backupId');
      }
      
      final backupData = backupResult.first;
      final backupFilePath = backupData['file_path'] as String;
      final backupFile = File(backupFilePath);
      
      if (!await backupFile.exists()) {
        throw FileSystemException('备份文件不存在: $backupFilePath');
      }
      
      // 验证备份文件完整性
      final fileBytes = await backupFile.readAsBytes();
      final actualChecksum = sha256.convert(fileBytes).toString();
      final expectedChecksum = backupData['checksum'] as String;
      
      if (actualChecksum != expectedChecksum) {
        throw StateError('备份文件校验和不匹配，文件可能已损坏');
      }
      
      // 关闭当前数据库连接
      await _dbHelper.close();
      
      // 获取当前数据库路径
      final currentDbPath = db.path;
      
      // 创建当前数据库的临时备份
      final tempBackupPath = '$currentDbPath.temp_backup';
      final currentDbFile = File(currentDbPath);
      if (await currentDbFile.exists()) {
        await currentDbFile.copy(tempBackupPath);
      }
      
      try {
        // 恢复备份文件
        await backupFile.copy(currentDbPath);
        
        // 重新初始化数据库连接
        await _dbHelper.database;
        
        // 验证恢复后的数据库
        final isValid = await _validateRestoredDatabase();
        if (!isValid) {
          throw StateError('恢复后的数据库验证失败');
        }
        
        // 删除临时备份
        final tempBackupFile = File(tempBackupPath);
        if (await tempBackupFile.exists()) {
          await tempBackupFile.delete();
        }
        
        print('数据备份恢复成功: $backupId');
        
      } catch (e) {
        // 恢复失败，回滚到原始数据库
        final tempBackupFile = File(tempBackupPath);
        if (await tempBackupFile.exists()) {
          await tempBackupFile.copy(currentDbPath);
          await tempBackupFile.delete();
        }
        
        // 重新初始化数据库连接
        await _dbHelper.database;
        
        rethrow;
      }
      
    } catch (e) {
      print('恢复数据备份失败: $e');
      rethrow;
    }
  }
  
  /// 验证恢复后的数据库
  Future<bool> _validateRestoredDatabase() async {
    try {
      final db = await _dbHelper.database;
      
      // 检查数据库完整性
      final integrityResult = await db.rawQuery('PRAGMA integrity_check');
      if (integrityResult.isEmpty || integrityResult.first.values.first != 'ok') {
        return false;
      }
      
      // 检查关键表是否存在
      final tables = ['calculation_records', 'parameter_sets', 'user_settings'];
      for (final table in tables) {
        try {
          await db.rawQuery('SELECT COUNT(*) FROM $table LIMIT 1');
        } catch (e) {
          print('表 $table 验证失败: $e');
          return false;
        }
      }
      
      return true;
      
    } catch (e) {
      print('数据库验证失败: $e');
      return false;
    }
  }
  
  /// 执行完整性检查
  Future<IntegrityCheckResult> performIntegrityCheck(IntegrityCheckType checkType) async {
    final checkId = const Uuid().v4();
    final startTime = DateTime.now();
    final issues = <IntegrityIssue>[];
    final statistics = <String, dynamic>{};
    
    try {
      switch (checkType) {
        case IntegrityCheckType.structure:
          await _checkDatabaseStructure(issues, statistics);
          break;
        case IntegrityCheckType.content:
          await _checkDataContent(issues, statistics);
          break;
        case IntegrityCheckType.consistency:
          await _checkDataConsistency(issues, statistics);
          break;
        case IntegrityCheckType.corruption:
          await _checkDataCorruption(issues, statistics);
          break;
        case IntegrityCheckType.foreign_key:
          await _checkForeignKeys(issues, statistics);
          break;
      }
      
      final endTime = DateTime.now();
      final checkDuration = endTime.difference(startTime);
      
      // 保存问题到数据库
      await _saveIntegrityIssues(issues);
      
      // 创建检查结果
      final result = IntegrityCheckResult(
        checkId: checkId,
        checkType: checkType,
        checkTime: startTime,
        checkDuration: checkDuration,
        issues: issues,
        statistics: statistics,
        passed: issues.where((i) => i.level == IntegrityIssueLevel.critical || 
                                   i.level == IntegrityIssueLevel.error).isEmpty,
      );
      
      // 保存检查历史
      await _saveCheckHistory(result);
      
      // 发送检查结果事件
      _checkResultController.add(result);
      
      print('完整性检查完成: ${checkType.toString()}, 发现 ${issues.length} 个问题');
      return result;
      
    } catch (e) {
      print('完整性检查失败: $e');
      rethrow;
    }
  }
  
  /// 检查数据库结构
  Future<void> _checkDatabaseStructure(List<IntegrityIssue> issues, Map<String, dynamic> statistics) async {
    final db = await _dbHelper.database;
    
    try {
      // 检查表结构
      final expectedTables = [
        'calculation_records',
        'parameter_sets',
        'preset_parameters',
        'user_settings',
        'sync_status',
        'enhanced_offline_queue',
        'integrity_issues',
        'data_backups',
        'integrity_check_history',
      ];
      
      final existingTables = <String>[];
      final tableResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      for (final row in tableResult) {
        existingTables.add(row['name'] as String);
      }
      
      // 检查缺失的表
      for (final expectedTable in expectedTables) {
        if (!existingTables.contains(expectedTable)) {
          issues.add(IntegrityIssue(
            id: const Uuid().v4(),
            checkType: IntegrityCheckType.structure,
            level: IntegrityIssueLevel.critical,
            tableName: expectedTable,
            description: '缺少必需的表: $expectedTable',
            suggestion: '重新初始化数据库或运行数据库迁移',
            detectedAt: DateTime.now(),
          ));
        }
      }
      
      // 检查表字段
      for (final tableName in existingTables) {
        if (expectedTables.contains(tableName)) {
          await _checkTableColumns(tableName, issues);
        }
      }
      
      statistics['expected_tables'] = expectedTables.length;
      statistics['existing_tables'] = existingTables.length;
      statistics['missing_tables'] = expectedTables.length - existingTables.length;
      
    } catch (e) {
      issues.add(IntegrityIssue(
        id: const Uuid().v4(),
        checkType: IntegrityCheckType.structure,
        level: IntegrityIssueLevel.error,
        tableName: 'database',
        description: '数据库结构检查失败: $e',
        suggestion: '检查数据库连接和权限',
        detectedAt: DateTime.now(),
      ));
    }
  }
  
  /// 检查表字段
  Future<void> _checkTableColumns(String tableName, List<IntegrityIssue> issues) async {
    final db = await _dbHelper.database;
    
    try {
      final columnResult = await db.rawQuery('PRAGMA table_info($tableName)');
      
      // 检查关键字段
      final requiredColumns = _getRequiredColumns(tableName);
      final existingColumns = columnResult.map((row) => row['name'] as String).toList();
      
      for (final requiredColumn in requiredColumns) {
        if (!existingColumns.contains(requiredColumn)) {
          issues.add(IntegrityIssue(
            id: const Uuid().v4(),
            checkType: IntegrityCheckType.structure,
            level: IntegrityIssueLevel.error,
            tableName: tableName,
            description: '表 $tableName 缺少必需字段: $requiredColumn',
            suggestion: '运行数据库迁移或重新创建表',
            detectedAt: DateTime.now(),
          ));
        }
      }
      
    } catch (e) {
      issues.add(IntegrityIssue(
        id: const Uuid().v4(),
        checkType: IntegrityCheckType.structure,
        level: IntegrityIssueLevel.warning,
        tableName: tableName,
        description: '无法检查表 $tableName 的字段: $e',
        suggestion: '检查表是否存在和可访问',
        detectedAt: DateTime.now(),
      ));
    }
  }
  
  /// 获取表的必需字段
  List<String> _getRequiredColumns(String tableName) {
    switch (tableName) {
      case 'calculation_records':
        return ['id', 'calculation_type', 'parameters', 'results', 'created_at'];
      case 'parameter_sets':
        return ['id', 'name', 'calculation_type', 'parameters', 'created_at'];
      case 'user_settings':
        return ['key', 'value', 'updated_at'];
      default:
        return ['id'];
    }
  }
  
  /// 检查数据内容
  Future<void> _checkDataContent(List<IntegrityIssue> issues, Map<String, dynamic> statistics) async {
    final db = await _dbHelper.database;
    
    try {
      // 检查计算记录
      await _checkCalculationRecords(db, issues, statistics);
      
      // 检查参数组
      await _checkParameterSets(db, issues, statistics);
      
      // 检查用户设置
      await _checkUserSettings(db, issues, statistics);
      
    } catch (e) {
      issues.add(IntegrityIssue(
        id: const Uuid().v4(),
        checkType: IntegrityCheckType.content,
        level: IntegrityIssueLevel.error,
        tableName: 'database',
        description: '数据内容检查失败: $e',
        suggestion: '检查数据库连接和数据格式',
        detectedAt: DateTime.now(),
      ));
    }
  }
  
  /// 检查计算记录
  Future<void> _checkCalculationRecords(Database db, List<IntegrityIssue> issues, Map<String, dynamic> statistics) async {
    try {
      final records = await db.query('calculation_records');
      int validRecords = 0;
      int invalidRecords = 0;
      
      for (final record in records) {
        final recordId = record['id'] as String?;
        
        // 检查ID是否为空
        if (recordId == null || recordId.isEmpty) {
          issues.add(IntegrityIssue(
            id: const Uuid().v4(),
            checkType: IntegrityCheckType.content,
            level: IntegrityIssueLevel.error,
            tableName: 'calculation_records',
            recordId: recordId,
            description: '计算记录ID为空',
            suggestion: '删除无效记录或生成新ID',
            detectedAt: DateTime.now(),
          ));
          invalidRecords++;
          continue;
        }
        
        // 检查JSON字段格式
        try {
          final parameters = record['parameters'] as String?;
          final results = record['results'] as String?;
          
          if (parameters != null) {
            jsonDecode(parameters);
          }
          
          if (results != null) {
            jsonDecode(results);
          }
          
          validRecords++;
          
        } catch (e) {
          issues.add(IntegrityIssue(
            id: const Uuid().v4(),
            checkType: IntegrityCheckType.content,
            level: IntegrityIssueLevel.error,
            tableName: 'calculation_records',
            recordId: recordId,
            description: '计算记录JSON格式无效: $e',
            suggestion: '修复JSON格式或删除损坏记录',
            detectedAt: DateTime.now(),
          ));
          invalidRecords++;
        }
      }
      
      statistics['calculation_records_total'] = records.length;
      statistics['calculation_records_valid'] = validRecords;
      statistics['calculation_records_invalid'] = invalidRecords;
      
    } catch (e) {
      issues.add(IntegrityIssue(
        id: const Uuid().v4(),
        checkType: IntegrityCheckType.content,
        level: IntegrityIssueLevel.warning,
        tableName: 'calculation_records',
        description: '无法检查计算记录: $e',
        suggestion: '检查表是否存在和可访问',
        detectedAt: DateTime.now(),
      ));
    }
  }
  
  /// 检查参数组
  Future<void> _checkParameterSets(Database db, List<IntegrityIssue> issues, Map<String, dynamic> statistics) async {
    try {
      final paramSets = await db.query('parameter_sets');
      int validSets = 0;
      int invalidSets = 0;
      
      for (final paramSet in paramSets) {
        final setId = paramSet['id'] as String?;
        
        // 检查ID和名称
        if (setId == null || setId.isEmpty) {
          issues.add(IntegrityIssue(
            id: const Uuid().v4(),
            checkType: IntegrityCheckType.content,
            level: IntegrityIssueLevel.error,
            tableName: 'parameter_sets',
            recordId: setId,
            description: '参数组ID为空',
            suggestion: '删除无效记录或生成新ID',
            detectedAt: DateTime.now(),
          ));
          invalidSets++;
          continue;
        }
        
        final name = paramSet['name'] as String?;
        if (name == null || name.isEmpty) {
          issues.add(IntegrityIssue(
            id: const Uuid().v4(),
            checkType: IntegrityCheckType.content,
            level: IntegrityIssueLevel.warning,
            tableName: 'parameter_sets',
            recordId: setId,
            description: '参数组名称为空',
            suggestion: '为参数组设置有效名称',
            detectedAt: DateTime.now(),
          ));
        }
        
        // 检查参数JSON格式
        try {
          final parameters = paramSet['parameters'] as String?;
          if (parameters != null) {
            jsonDecode(parameters);
          }
          
          validSets++;
          
        } catch (e) {
          issues.add(IntegrityIssue(
            id: const Uuid().v4(),
            checkType: IntegrityCheckType.content,
            level: IntegrityIssueLevel.error,
            tableName: 'parameter_sets',
            recordId: setId,
            description: '参数组JSON格式无效: $e',
            suggestion: '修复JSON格式或删除损坏记录',
            detectedAt: DateTime.now(),
          ));
          invalidSets++;
        }
      }
      
      statistics['parameter_sets_total'] = paramSets.length;
      statistics['parameter_sets_valid'] = validSets;
      statistics['parameter_sets_invalid'] = invalidSets;
      
    } catch (e) {
      issues.add(IntegrityIssue(
        id: const Uuid().v4(),
        checkType: IntegrityCheckType.content,
        level: IntegrityIssueLevel.warning,
        tableName: 'parameter_sets',
        description: '无法检查参数组: $e',
        suggestion: '检查表是否存在和可访问',
        detectedAt: DateTime.now(),
      ));
    }
  }
  
  /// 检查用户设置
  Future<void> _checkUserSettings(Database db, List<IntegrityIssue> issues, Map<String, dynamic> statistics) async {
    try {
      final settings = await db.query('user_settings');
      int validSettings = 0;
      int invalidSettings = 0;
      
      for (final setting in settings) {
        final key = setting['key'] as String?;
        final value = setting['value'] as String?;
        
        if (key == null || key.isEmpty) {
          issues.add(IntegrityIssue(
            id: const Uuid().v4(),
            checkType: IntegrityCheckType.content,
            level: IntegrityIssueLevel.error,
            tableName: 'user_settings',
            recordId: key,
            description: '用户设置键为空',
            suggestion: '删除无效设置记录',
            detectedAt: DateTime.now(),
          ));
          invalidSettings++;
          continue;
        }
        
        if (value == null) {
          issues.add(IntegrityIssue(
            id: const Uuid().v4(),
            checkType: IntegrityCheckType.content,
            level: IntegrityIssueLevel.warning,
            tableName: 'user_settings',
            recordId: key,
            description: '用户设置值为空: $key',
            suggestion: '为设置项设置默认值',
            detectedAt: DateTime.now(),
          ));
        }
        
        validSettings++;
      }
      
      statistics['user_settings_total'] = settings.length;
      statistics['user_settings_valid'] = validSettings;
      statistics['user_settings_invalid'] = invalidSettings;
      
    } catch (e) {
      issues.add(IntegrityIssue(
        id: const Uuid().v4(),
        checkType: IntegrityCheckType.content,
        level: IntegrityIssueLevel.warning,
        tableName: 'user_settings',
        description: '无法检查用户设置: $e',
        suggestion: '检查表是否存在和可访问',
        detectedAt: DateTime.now(),
      ));
    }
  }
  
  /// 检查数据一致性
  Future<void> _checkDataConsistency(List<IntegrityIssue> issues, Map<String, dynamic> statistics) async {
    final db = await _dbHelper.database;
    
    try {
      // 检查重复ID
      await _checkDuplicateIds(db, issues, statistics);
      
      // 检查时间戳一致性
      await _checkTimestampConsistency(db, issues, statistics);
      
      // 检查枚举值有效性
      await _checkEnumValues(db, issues, statistics);
      
    } catch (e) {
      issues.add(IntegrityIssue(
        id: const Uuid().v4(),
        checkType: IntegrityCheckType.consistency,
        level: IntegrityIssueLevel.error,
        tableName: 'database',
        description: '数据一致性检查失败: $e',
        suggestion: '检查数据库连接和数据完整性',
        detectedAt: DateTime.now(),
      ));
    }
  }
  
  /// 检查重复ID
  Future<void> _checkDuplicateIds(Database db, List<IntegrityIssue> issues, Map<String, dynamic> statistics) async {
    final tables = ['calculation_records', 'parameter_sets'];
    
    for (final tableName in tables) {
      try {
        final duplicateResult = await db.rawQuery('''
          SELECT id, COUNT(*) as count 
          FROM $tableName 
          GROUP BY id 
          HAVING COUNT(*) > 1
        ''');
        
        for (final row in duplicateResult) {
          final id = row['id'] as String;
          final count = row['count'] as int;
          
          issues.add(IntegrityIssue(
            id: const Uuid().v4(),
            checkType: IntegrityCheckType.consistency,
            level: IntegrityIssueLevel.error,
            tableName: tableName,
            recordId: id,
            description: '发现重复ID: $id (出现 $count 次)',
            suggestion: '删除重复记录或重新生成唯一ID',
            detectedAt: DateTime.now(),
          ));
        }
        
        statistics['${tableName}_duplicates'] = duplicateResult.length;
        
      } catch (e) {
        print('检查表 $tableName 重复ID失败: $e');
      }
    }
  }
  
  /// 检查时间戳一致性
  Future<void> _checkTimestampConsistency(Database db, List<IntegrityIssue> issues, Map<String, dynamic> statistics) async {
    try {
      // 检查创建时间晚于更新时间的记录
      final inconsistentRecords = await db.rawQuery('''
        SELECT id, created_at, updated_at 
        FROM calculation_records 
        WHERE created_at > updated_at
      ''');
      
      for (final record in inconsistentRecords) {
        issues.add(IntegrityIssue(
          id: const Uuid().v4(),
          checkType: IntegrityCheckType.consistency,
          level: IntegrityIssueLevel.warning,
          tableName: 'calculation_records',
          recordId: record['id'] as String,
          description: '创建时间晚于更新时间',
          suggestion: '修正时间戳或重新设置更新时间',
          detectedAt: DateTime.now(),
        ));
      }
      
      statistics['timestamp_inconsistencies'] = inconsistentRecords.length;
      
    } catch (e) {
      print('检查时间戳一致性失败: $e');
    }
  }
  
  /// 检查枚举值有效性
  Future<void> _checkEnumValues(Database db, List<IntegrityIssue> issues, Map<String, dynamic> statistics) async {
    try {
      // 检查计算类型枚举值
      final validCalculationTypes = CalculationType.values.map((e) => e.toString()).toList();
      
      final invalidTypeRecords = await db.rawQuery('''
        SELECT id, calculation_type 
        FROM calculation_records 
        WHERE calculation_type NOT IN (${validCalculationTypes.map((_) => '?').join(',')})
      ''', validCalculationTypes);
      
      for (final record in invalidTypeRecords) {
        issues.add(IntegrityIssue(
          id: const Uuid().v4(),
          checkType: IntegrityCheckType.consistency,
          level: IntegrityIssueLevel.error,
          tableName: 'calculation_records',
          recordId: record['id'] as String,
          description: '无效的计算类型: ${record['calculation_type']}',
          suggestion: '修正为有效的计算类型或删除记录',
          detectedAt: DateTime.now(),
        ));
      }
      
      statistics['invalid_enum_values'] = invalidTypeRecords.length;
      
    } catch (e) {
      print('检查枚举值有效性失败: $e');
    }
  }
  
  /// 检查数据损坏
  Future<void> _checkDataCorruption(List<IntegrityIssue> issues, Map<String, dynamic> statistics) async {
    final db = await _dbHelper.database;
    
    try {
      // 执行SQLite完整性检查
      final integrityResult = await db.rawQuery('PRAGMA integrity_check');
      
      if (integrityResult.isEmpty || integrityResult.first.values.first != 'ok') {
        for (final row in integrityResult) {
          final message = row.values.first as String;
          if (message != 'ok') {
            issues.add(IntegrityIssue(
              id: const Uuid().v4(),
              checkType: IntegrityCheckType.corruption,
              level: IntegrityIssueLevel.critical,
              tableName: 'database',
              description: 'SQLite完整性检查失败: $message',
              suggestion: '考虑从备份恢复数据库',
              detectedAt: DateTime.now(),
            ));
          }
        }
      }
      
      // 执行快速检查
      final quickCheckResult = await db.rawQuery('PRAGMA quick_check');
      
      if (quickCheckResult.isEmpty || quickCheckResult.first.values.first != 'ok') {
        for (final row in quickCheckResult) {
          final message = row.values.first as String;
          if (message != 'ok') {
            issues.add(IntegrityIssue(
              id: const Uuid().v4(),
              checkType: IntegrityCheckType.corruption,
              level: IntegrityIssueLevel.error,
              tableName: 'database',
              description: 'SQLite快速检查失败: $message',
              suggestion: '运行完整的数据库修复或从备份恢复',
              detectedAt: DateTime.now(),
            ));
          }
        }
      }
      
      statistics['integrity_check_passed'] = issues.isEmpty;
      
    } catch (e) {
      issues.add(IntegrityIssue(
        id: const Uuid().v4(),
        checkType: IntegrityCheckType.corruption,
        level: IntegrityIssueLevel.error,
        tableName: 'database',
        description: '数据损坏检查失败: $e',
        suggestion: '检查数据库文件和权限',
        detectedAt: DateTime.now(),
      ));
    }
  }
  
  /// 检查外键约束
  Future<void> _checkForeignKeys(List<IntegrityIssue> issues, Map<String, dynamic> statistics) async {
    final db = await _dbHelper.database;
    
    try {
      // 启用外键检查
      await db.execute('PRAGMA foreign_keys = ON');
      
      // 检查外键约束
      final foreignKeyResult = await db.rawQuery('PRAGMA foreign_key_check');
      
      for (final row in foreignKeyResult) {
        issues.add(IntegrityIssue(
          id: const Uuid().v4(),
          checkType: IntegrityCheckType.foreign_key,
          level: IntegrityIssueLevel.error,
          tableName: row['table'] as String,
          recordId: row['rowid']?.toString(),
          description: '外键约束违反: ${row['parent']} -> ${row['fkid']}',
          suggestion: '修复引用关系或删除孤立记录',
          detectedAt: DateTime.now(),
        ));
      }
      
      statistics['foreign_key_violations'] = foreignKeyResult.length;
      
    } catch (e) {
      issues.add(IntegrityIssue(
        id: const Uuid().v4(),
        checkType: IntegrityCheckType.foreign_key,
        level: IntegrityIssueLevel.warning,
        tableName: 'database',
        description: '外键检查失败: $e',
        suggestion: '检查数据库是否支持外键约束',
        detectedAt: DateTime.now(),
      ));
    }
  }
  
  /// 保存完整性问题
  Future<void> _saveIntegrityIssues(List<IntegrityIssue> issues) async {
    if (issues.isEmpty) return;
    
    final db = await _dbHelper.database;
    
    try {
      final batch = db.batch();
      
      for (final issue in issues) {
        batch.insert(
          'integrity_issues',
          {
            'id': issue.id,
            'check_type': issue.checkType.toString(),
            'level': issue.level.toString(),
            'table_name': issue.tableName,
            'record_id': issue.recordId,
            'description': issue.description,
            'suggestion': issue.suggestion,
            'metadata': jsonEncode(issue.metadata),
            'detected_at': issue.detectedAt.millisecondsSinceEpoch,
            'is_fixed': issue.isFixed ? 1 : 0,
            'fixed_at': issue.fixedAt?.millisecondsSinceEpoch,
            'fix_method': issue.fixMethod,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit();
      
    } catch (e) {
      print('保存完整性问题失败: $e');
    }
  }
  
  /// 保存检查历史
  Future<void> _saveCheckHistory(IntegrityCheckResult result) async {
    final db = await _dbHelper.database;
    
    try {
      await db.insert(
        'integrity_check_history',
        {
          'id': result.checkId,
          'check_type': result.checkType.toString(),
          'check_time': result.checkTime.millisecondsSinceEpoch,
          'check_duration': result.checkDuration.inMilliseconds,
          'issues_found': result.issues.length,
          'critical_issues': result.criticalIssues,
          'error_issues': result.errorIssues,
          'warning_issues': result.warningIssues,
          'info_issues': result.infoIssues,
          'passed': result.passed ? 1 : 0,
          'statistics': jsonEncode(result.statistics),
        },
      );
      
    } catch (e) {
      print('保存检查历史失败: $e');
    }
  }
  
  /// 获取表记录数统计
  Future<Map<String, int>> _getTableCounts() async {
    final db = await _dbHelper.database;
    final counts = <String, int>{};
    
    final tables = [
      'calculation_records',
      'parameter_sets',
      'preset_parameters',
      'user_settings',
      'sync_status',
      'enhanced_offline_queue',
    ];
    
    for (final table in tables) {
      try {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        counts[table] = result.first['count'] as int;
      } catch (e) {
        counts[table] = 0;
      }
    }
    
    return counts;
  }
  
  /// 获取备份列表
  Future<List<DataBackup>> getBackupList() async {
    final db = await _dbHelper.database;
    
    try {
      final backupResults = await db.query(
        'data_backups',
        orderBy: 'created_at DESC',
      );
      
      return backupResults.map((row) {
        return DataBackup(
          id: row['id'] as String,
          name: row['name'] as String,
          description: row['description'] as String? ?? '',
          filePath: row['file_path'] as String,
          fileSize: row['file_size'] as int,
          checksum: row['checksum'] as String,
          createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
          tableCounts: Map<String, int>.from(jsonDecode(row['table_counts'] as String)),
          isAutomatic: (row['is_automatic'] as int) == 1,
          triggerReason: row['trigger_reason'] as String?,
        );
      }).toList();
      
    } catch (e) {
      print('获取备份列表失败: $e');
      return [];
    }
  }
  
  /// 删除备份
  Future<void> deleteBackup(String backupId) async {
    final db = await _dbHelper.database;
    
    try {
      // 获取备份信息
      final backupResult = await db.query(
        'data_backups',
        where: 'id = ?',
        whereArgs: [backupId],
      );
      
      if (backupResult.isNotEmpty) {
        final backupData = backupResult.first;
        final backupFilePath = backupData['file_path'] as String;
        
        // 删除备份文件
        final backupFile = File(backupFilePath);
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
        
        // 删除数据库记录
        await db.delete(
          'data_backups',
          where: 'id = ?',
          whereArgs: [backupId],
        );
        
        print('备份删除成功: $backupId');
      }
      
    } catch (e) {
      print('删除备份失败: $e');
      rethrow;
    }
  }
  
  /// 获取完整性问题列表
  Future<List<IntegrityIssue>> getIntegrityIssues({
    IntegrityCheckType? checkType,
    IntegrityIssueLevel? level,
    bool? isFixed,
  }) async {
    final db = await _dbHelper.database;
    
    try {
      String whereClause = '1=1';
      final whereArgs = <dynamic>[];
      
      if (checkType != null) {
        whereClause += ' AND check_type = ?';
        whereArgs.add(checkType.toString());
      }
      
      if (level != null) {
        whereClause += ' AND level = ?';
        whereArgs.add(level.toString());
      }
      
      if (isFixed != null) {
        whereClause += ' AND is_fixed = ?';
        whereArgs.add(isFixed ? 1 : 0);
      }
      
      final issueResults = await db.query(
        'integrity_issues',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'detected_at DESC',
      );
      
      return issueResults.map((row) {
        return IntegrityIssue(
          id: row['id'] as String,
          checkType: IntegrityCheckType.values.firstWhere(
            (type) => type.toString() == row['check_type'],
          ),
          level: IntegrityIssueLevel.values.firstWhere(
            (level) => level.toString() == row['level'],
          ),
          tableName: row['table_name'] as String,
          recordId: row['record_id'] as String?,
          description: row['description'] as String,
          suggestion: row['suggestion'] as String?,
          metadata: Map<String, dynamic>.from(jsonDecode(row['metadata'] as String? ?? '{}')),
          detectedAt: DateTime.fromMillisecondsSinceEpoch(row['detected_at'] as int),
          isFixed: (row['is_fixed'] as int) == 1,
          fixedAt: row['fixed_at'] != null ? DateTime.fromMillisecondsSinceEpoch(row['fixed_at'] as int) : null,
          fixMethod: row['fix_method'] as String?,
        );
      }).toList();
      
    } catch (e) {
      print('获取完整性问题列表失败: $e');
      return [];
    }
  }
  
  /// 标记问题已修复
  Future<void> markIssueFixed(String issueId, String fixMethod) async {
    final db = await _dbHelper.database;
    
    try {
      await db.update(
        'integrity_issues',
        {
          'is_fixed': 1,
          'fixed_at': DateTime.now().millisecondsSinceEpoch,
          'fix_method': fixMethod,
        },
        where: 'id = ?',
        whereArgs: [issueId],
      );
      
      print('问题标记为已修复: $issueId');
      
    } catch (e) {
      print('标记问题修复失败: $e');
      rethrow;
    }
  }
  
  /// 自动修复数据问题
  Future<List<String>> autoFixIssues({
    IntegrityCheckType? checkType,
    IntegrityIssueLevel? maxLevel,
  }) async {
    final fixedIssues = <String>[];
    
    try {
      // 获取可自动修复的问题
      final issues = await getIntegrityIssues(
        checkType: checkType,
        isFixed: false,
      );
      
      for (final issue in issues) {
        // 跳过严重级别的问题，需要手动处理
        if (maxLevel != null && _getIssueLevelPriority(issue.level) > _getIssueLevelPriority(maxLevel)) {
          continue;
        }
        
        try {
          final fixed = await _autoFixSingleIssue(issue);
          if (fixed) {
            await markIssueFixed(issue.id, 'auto_fix');
            fixedIssues.add(issue.id);
          }
        } catch (e) {
          print('自动修复问题失败 ${issue.id}: $e');
        }
      }
      
      print('自动修复完成，共修复 ${fixedIssues.length} 个问题');
      return fixedIssues;
      
    } catch (e) {
      print('自动修复过程失败: $e');
      return fixedIssues;
    }
  }
  
  /// 获取问题级别优先级
  int _getIssueLevelPriority(IntegrityIssueLevel level) {
    switch (level) {
      case IntegrityIssueLevel.info:
        return 1;
      case IntegrityIssueLevel.warning:
        return 2;
      case IntegrityIssueLevel.error:
        return 3;
      case IntegrityIssueLevel.critical:
        return 4;
    }
  }
  
  /// 自动修复单个问题
  Future<bool> _autoFixSingleIssue(IntegrityIssue issue) async {
    final db = await _dbHelper.database;
    
    try {
      switch (issue.checkType) {
        case IntegrityCheckType.content:
          return await _autoFixContentIssue(db, issue);
        case IntegrityCheckType.consistency:
          return await _autoFixConsistencyIssue(db, issue);
        case IntegrityCheckType.structure:
          return await _autoFixStructureIssue(db, issue);
        default:
          return false; // 其他类型问题需要手动处理
      }
    } catch (e) {
      print('修复问题失败 ${issue.id}: $e');
      return false;
    }
  }
  
  /// 自动修复内容问题
  Future<bool> _autoFixContentIssue(Database db, IntegrityIssue issue) async {
    if (issue.description.contains('ID为空')) {
      // 为空ID记录生成新ID
      if (issue.recordId == null) {
        final newId = const Uuid().v4();
        await db.update(
          issue.tableName,
          {'id': newId},
          where: 'id IS NULL OR id = ""',
        );
        return true;
      }
    } else if (issue.description.contains('JSON格式无效')) {
      // 删除JSON格式无效的记录
      if (issue.recordId != null) {
        await db.delete(
          issue.tableName,
          where: 'id = ?',
          whereArgs: [issue.recordId],
        );
        return true;
      }
    }
    
    return false;
  }
  
  /// 自动修复一致性问题
  Future<bool> _autoFixConsistencyIssue(Database db, IntegrityIssue issue) async {
    if (issue.description.contains('重复ID')) {
      // 删除重复记录，保留最新的
      if (issue.recordId != null) {
        await db.execute('''
          DELETE FROM ${issue.tableName} 
          WHERE id = ? AND rowid NOT IN (
            SELECT MAX(rowid) FROM ${issue.tableName} WHERE id = ?
          )
        ''', [issue.recordId, issue.recordId]);
        return true;
      }
    } else if (issue.description.contains('创建时间晚于更新时间')) {
      // 修正更新时间
      if (issue.recordId != null) {
        await db.execute('''
          UPDATE ${issue.tableName} 
          SET updated_at = created_at 
          WHERE id = ? AND created_at > updated_at
        ''', [issue.recordId]);
        return true;
      }
    }
    
    return false;
  }
  
  /// 自动修复结构问题
  Future<bool> _autoFixStructureIssue(Database db, IntegrityIssue issue) async {
    // 结构问题通常需要手动处理，这里只处理简单情况
    if (issue.description.contains('缺少必需的表')) {
      // 重新创建缺失的表
      await _createIntegrityTables();
      return true;
    }
    
    return false;
  }
  
  /// 清理旧备份
  Future<void> cleanupOldBackups({int maxBackups = 10, int maxDays = 30}) async {
    try {
      final backups = await getBackupList();
      
      // 按时间排序，保留最新的备份
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: maxDays));
      
      final backupsToDelete = <DataBackup>[];
      
      // 删除超过数量限制的备份
      if (backups.length > maxBackups) {
        backupsToDelete.addAll(backups.skip(maxBackups));
      }
      
      // 删除超过时间限制的备份（但保留至少一个备份）
      for (final backup in backups) {
        if (backup.createdAt.isBefore(cutoffDate) && backups.length > 1) {
          if (!backupsToDelete.contains(backup)) {
            backupsToDelete.add(backup);
          }
        }
      }
      
      // 执行删除
      for (final backup in backupsToDelete) {
        await deleteBackup(backup.id);
      }
      
      print('清理完成，删除了 ${backupsToDelete.length} 个旧备份');
      
    } catch (e) {
      print('清理旧备份失败: $e');
    }
  }
  
  /// 验证备份文件完整性
  Future<bool> verifyBackupIntegrity(String backupId) async {
    try {
      final db = await _dbHelper.database;
      
      // 获取备份信息
      final backupResult = await db.query(
        'data_backups',
        where: 'id = ?',
        whereArgs: [backupId],
      );
      
      if (backupResult.isEmpty) {
        return false;
      }
      
      final backupData = backupResult.first;
      final backupFilePath = backupData['file_path'] as String;
      final expectedChecksum = backupData['checksum'] as String;
      
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        return false;
      }
      
      // 计算当前文件校验和
      final fileBytes = await backupFile.readAsBytes();
      final actualChecksum = sha256.convert(fileBytes).toString();
      
      return actualChecksum == expectedChecksum;
      
    } catch (e) {
      print('验证备份完整性失败: $e');
      return false;
    }
  }
  
  /// 获取数据库健康状态
  Future<Map<String, dynamic>> getDatabaseHealthStatus() async {
    try {
      final db = await _dbHelper.database;
      
      // 执行基本健康检查
      final integrityResult = await db.rawQuery('PRAGMA integrity_check(1)');
      final quickCheckResult = await db.rawQuery('PRAGMA quick_check(1)');
      
      // 获取数据库统计信息
      final tableCounts = await _getTableCounts();
      
      // 获取未修复的问题数量
      final unFixedIssues = await getIntegrityIssues(isFixed: false);
      final criticalIssues = unFixedIssues.where((i) => i.level == IntegrityIssueLevel.critical).length;
      final errorIssues = unFixedIssues.where((i) => i.level == IntegrityIssueLevel.error).length;
      
      // 获取最近的备份信息
      final backups = await getBackupList();
      final latestBackup = backups.isNotEmpty ? backups.first : null;
      
      return {
        'database_integrity': integrityResult.first.values.first == 'ok',
        'quick_check_passed': quickCheckResult.first.values.first == 'ok',
        'table_counts': tableCounts,
        'total_records': tableCounts.values.fold(0, (sum, count) => sum + count),
        'unfixed_issues': unFixedIssues.length,
        'critical_issues': criticalIssues,
        'error_issues': errorIssues,
        'latest_backup': latestBackup?.toJson(),
        'backup_count': backups.length,
        'health_score': _calculateHealthScore(
          integrityResult.first.values.first == 'ok',
          quickCheckResult.first.values.first == 'ok',
          criticalIssues,
          errorIssues,
          latestBackup != null,
        ),
        'last_check_time': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('获取数据库健康状态失败: $e');
      return {
        'database_integrity': false,
        'quick_check_passed': false,
        'health_score': 0,
        'error': e.toString(),
      };
    }
  }
  
  /// 计算健康评分
  double _calculateHealthScore(
    bool integrityPassed,
    bool quickCheckPassed,
    int criticalIssues,
    int errorIssues,
    bool hasRecentBackup,
  ) {
    double score = 100.0;
    
    if (!integrityPassed) score -= 50.0;
    if (!quickCheckPassed) score -= 30.0;
    if (!hasRecentBackup) score -= 10.0;
    
    score -= criticalIssues * 10.0;
    score -= errorIssues * 5.0;
    
    return score.clamp(0.0, 100.0);
  }
  
  /// 执行数据库修复
  Future<bool> repairDatabase() async {
    try {
      print('开始数据库修复...');
      
      // 1. 创建紧急备份
      await createBackup(
        name: '紧急修复备份_${DateTime.now().millisecondsSinceEpoch}',
        description: '数据库修复前的紧急备份',
        isAutomatic: true,
        triggerReason: 'emergency_repair',
      );
      
      // 2. 尝试自动修复问题
      final fixedIssues = await autoFixIssues(
        maxLevel: IntegrityIssueLevel.error,
      );
      
      // 3. 重建索引
      await _rebuildIndexes();
      
      // 4. 清理无效数据
      await _cleanupInvalidData();
      
      // 5. 重新检查完整性
      final finalCheck = await performIntegrityCheck(IntegrityCheckType.corruption);
      
      print('数据库修复完成，修复了 ${fixedIssues.length} 个问题');
      return finalCheck.passed;
      
    } catch (e) {
      print('数据库修复失败: $e');
      return false;
    }
  }
  
  /// 重建数据库索引
  Future<void> _rebuildIndexes() async {
    final db = await _dbHelper.database;
    
    try {
      // 重建所有索引
      await db.execute('REINDEX');
      print('数据库索引重建完成');
      
    } catch (e) {
      print('重建索引失败: $e');
    }
  }
  
  /// 清理无效数据
  Future<void> _cleanupInvalidData() async {
    final db = await _dbHelper.database;
    
    try {
      // 删除空ID记录
      await db.delete('calculation_records', where: 'id IS NULL OR id = ""');
      await db.delete('parameter_sets', where: 'id IS NULL OR id = ""');
      
      // 删除JSON格式无效的记录
      final records = await db.query('calculation_records');
      for (final record in records) {
        try {
          jsonDecode(record['parameters'] as String? ?? '{}');
          jsonDecode(record['results'] as String? ?? '{}');
        } catch (e) {
          await db.delete('calculation_records', where: 'id = ?', whereArgs: [record['id']]);
        }
      }
      
      print('无效数据清理完成');
      
    } catch (e) {
      print('清理无效数据失败: $e');
    }
  }
  
  /// 释放资源
  void dispose() {
    _autoBackupTimer?.cancel();
    _integrityCheckTimer?.cancel();
    _checkResultController.close();
    _backupController.close();
    _isInitialized = false;
  }
}