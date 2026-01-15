import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';
import 'network_status_service.dart';
import 'calculation_repository.dart';
import '../models/calculation_result.dart';
import '../models/parameter_models.dart';
import '../models/enums.dart';
import '../utils/constants.dart';

/// 离线操作优先级
enum OfflinePriority {
  low,      // 低优先级
  normal,   // 普通优先级
  high,     // 高优先级
  critical, // 关键优先级
}

/// 离线存储状态
enum OfflineStorageStatus {
  healthy,    // 健康状态
  warning,    // 警告状态
  critical,   // 严重状态
  corrupted,  // 数据损坏
}

/// 离线队列项扩展
class EnhancedOfflineQueueItem extends OfflineQueueItem {
  final OfflinePriority priority;
  final Map<String, dynamic> metadata;
  final String? dependsOn; // 依赖的其他操作ID
  final DateTime? scheduledAt; // 计划执行时间
  
  EnhancedOfflineQueueItem({
    required String id,
    required OfflineOperationType operationType,
    required String tableName,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime createdAt,
    this.priority = OfflinePriority.normal,
    this.metadata = const {},
    this.dependsOn,
    this.scheduledAt,
    int retryCount = 0,
    DateTime? lastRetryAt,
    String? errorMessage,
  }) : super(
    id: id,
    operationType: operationType,
    tableName: tableName,
    recordId: recordId,
    data: data,
    createdAt: createdAt,
    retryCount: retryCount,
    lastRetryAt: lastRetryAt,
    errorMessage: errorMessage,
  );
  
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'priority': priority.toString(),
      'metadata': metadata,
      'depends_on': dependsOn,
      'scheduled_at': scheduledAt?.millisecondsSinceEpoch,
    });
    return json;
  }
  
  factory EnhancedOfflineQueueItem.fromJson(Map<String, dynamic> json) {
    return EnhancedOfflineQueueItem(
      id: json['id'],
      operationType: OfflineOperationType.values.firstWhere(
        (type) => type.toString() == json['operation_type'],
      ),
      tableName: json['table_name'],
      recordId: json['record_id'],
      data: Map<String, dynamic>.from(json['data']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      priority: OfflinePriority.values.firstWhere(
        (p) => p.toString() == json['priority'],
        orElse: () => OfflinePriority.normal,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      dependsOn: json['depends_on'],
      scheduledAt: json['scheduled_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['scheduled_at'])
          : null,
      retryCount: json['retry_count'] ?? 0,
      lastRetryAt: json['last_retry_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['last_retry_at'])
          : null,
      errorMessage: json['error_message'],
    );
  }
}

/// 离线存储统计信息
class OfflineStorageStatistics {
  final int totalQueueItems;
  final int pendingItems;
  final int failedItems;
  final int completedItems;
  final Map<OfflinePriority, int> itemsByPriority;
  final Map<OfflineOperationType, int> itemsByType;
  final double storageUsage; // MB
  final double availableStorage; // MB
  final OfflineStorageStatus status;
  final List<String> warnings;
  final DateTime generatedAt;
  
  OfflineStorageStatistics({
    required this.totalQueueItems,
    required this.pendingItems,
    required this.failedItems,
    required this.completedItems,
    required this.itemsByPriority,
    required this.itemsByType,
    required this.storageUsage,
    required this.availableStorage,
    required this.status,
    required this.warnings,
    required this.generatedAt,
  });
  
  double get storageUsagePercentage => 
      availableStorage > 0 ? (storageUsage / availableStorage) * 100 : 0.0;
  
  Map<String, dynamic> toJson() => {
    'total_queue_items': totalQueueItems,
    'pending_items': pendingItems,
    'failed_items': failedItems,
    'completed_items': completedItems,
    'items_by_priority': itemsByPriority.map((k, v) => MapEntry(k.toString(), v)),
    'items_by_type': itemsByType.map((k, v) => MapEntry(k.toString(), v)),
    'storage_usage_mb': storageUsage,
    'available_storage_mb': availableStorage,
    'storage_usage_percentage': storageUsagePercentage,
    'status': status.toString(),
    'warnings': warnings,
    'generated_at': generatedAt.toIso8601String(),
  };
}

/// 离线存储优化器
/// 
/// 负责优化离线存储、离线状态检测、本地数据管理和离线队列管理
class OfflineStorageOptimizer {
  static OfflineStorageOptimizer? _instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NetworkStatusService _networkService = NetworkStatusService();
  final CalculationRepository _calcRepository = CalculationRepository();
  
  bool _isInitialized = false;
  Timer? _optimizationTimer;
  Timer? _queueProcessingTimer;
  Timer? _storageMonitoringTimer;
  
  final StreamController<OfflineStorageStatistics> _statisticsController = 
      StreamController<OfflineStorageStatistics>.broadcast();
  final StreamController<OfflineStorageStatus> _statusController = 
      StreamController<OfflineStorageStatus>.broadcast();
  
  OfflineStorageStatus _currentStatus = OfflineStorageStatus.healthy;
  
  /// 单例模式
  OfflineStorageOptimizer._internal();
  
  factory OfflineStorageOptimizer() {
    _instance ??= OfflineStorageOptimizer._internal();
    return _instance!;
  }
  
  /// 统计信息流
  Stream<OfflineStorageStatistics> get statisticsStream => _statisticsController.stream;
  
  /// 状态流
  Stream<OfflineStorageStatus> get statusStream => _statusController.stream;
  
  /// 当前状态
  OfflineStorageStatus get currentStatus => _currentStatus;
  
  /// 初始化离线存储优化器
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 确保数据库已初始化
      await _dbHelper.database;
      
      // 初始化网络状态服务
      await _networkService.initialize();
      
      // 初始化计算存储库
      await _calcRepository.initialize();
      
      // 创建离线存储相关表
      await _createOfflineStorageTables();
      
      // 启动定期优化
      _startPeriodicOptimization();
      
      // 启动队列处理
      _startQueueProcessing();
      
      // 启动存储监控
      _startStorageMonitoring();
      
      // 执行初始优化
      await _performInitialOptimization();
      
      _isInitialized = true;
      print('离线存储优化器初始化完成');
      
    } catch (e) {
      print('离线存储优化器初始化失败: $e');
      rethrow;
    }
  }
  
  /// 创建离线存储相关表
  Future<void> _createOfflineStorageTables() async {
    final db = await _dbHelper.database;
    
    // 创建增强的离线队列表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS enhanced_offline_queue (
        id TEXT PRIMARY KEY,
        operation_type TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT NOT NULL,
        priority TEXT DEFAULT 'normal',
        metadata TEXT DEFAULT '{}',
        depends_on TEXT,
        scheduled_at INTEGER,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_retry_at INTEGER,
        error_message TEXT,
        status TEXT DEFAULT 'pending',
        INDEX(operation_type),
        INDEX(table_name),
        INDEX(priority),
        INDEX(status),
        INDEX(scheduled_at),
        INDEX(depends_on)
      )
    ''');
    
    // 创建离线存储统计表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_storage_stats (
        id TEXT PRIMARY KEY,
        stat_type TEXT NOT NULL,
        stat_value TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        INDEX(stat_type),
        INDEX(created_at)
      )
    ''');
    
    // 创建数据完整性检查表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS data_integrity_checks (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        check_type TEXT NOT NULL,
        check_result TEXT NOT NULL,
        issues_found INTEGER DEFAULT 0,
        issues_fixed INTEGER DEFAULT 0,
        check_time INTEGER NOT NULL,
        INDEX(table_name),
        INDEX(check_type),
        INDEX(check_time)
      )
    ''');
    
    print('离线存储表创建完成');
  }
  
  /// 执行初始优化
  Future<void> _performInitialOptimization() async {
    try {
      // 检查数据完整性
      await _checkDataIntegrity();
      
      // 清理过期数据
      await _cleanupExpiredData();
      
      // 优化数据库
      await _optimizeDatabase();
      
      // 迁移旧的离线队列数据
      await _migrateOldOfflineQueue();
      
      // 生成初始统计信息
      await _generateStatistics();
      
      print('初始优化完成');
      
    } catch (e) {
      print('初始优化失败: $e');
    }
  }
  
  /// 迁移旧的离线队列数据
  Future<void> _migrateOldOfflineQueue() async {
    try {
      final db = await _dbHelper.database;
      
      // 检查是否存在旧的离线队列表
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='offline_queue'"
      );
      
      if (tables.isNotEmpty) {
        // 获取旧队列数据
        final oldQueueItems = await db.query('offline_queue');
        
        // 迁移到新表
        final batch = db.batch();
        for (final item in oldQueueItems) {
          batch.insert(
            'enhanced_offline_queue',
            {
              'id': item['id'],
              'operation_type': item['operation_type'],
              'table_name': item['table_name'],
              'record_id': item['record_id'],
              'data': item['data'],
              'priority': 'normal', // 默认优先级
              'metadata': '{}',
              'created_at': item['created_at'],
              'retry_count': item['retry_count'] ?? 0,
              'last_retry_at': item['last_retry_at'],
              'error_message': item['error_message'],
              'status': 'pending',
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        
        await batch.commit();
        
        // 删除旧表（可选，为了安全可以保留）
        // await db.execute('DROP TABLE IF EXISTS offline_queue');
        
        print('迁移了 ${oldQueueItems.length} 个离线队列项');
      }
      
    } catch (e) {
      print('迁移离线队列数据失败: $e');
    }
  }
  
  /// 启动定期优化
  void _startPeriodicOptimization() {
    _optimizationTimer = Timer.periodic(const Duration(hours: 6), (timer) async {
      try {
        await _performPeriodicOptimization();
      } catch (e) {
        print('定期优化失败: $e');
      }
    });
  }
  
  /// 启动队列处理
  void _startQueueProcessing() {
    _queueProcessingTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      try {
        if (_networkService.isConnected) {
          await _processOfflineQueue();
        }
      } catch (e) {
        print('队列处理失败: $e');
      }
    });
  }
  
  /// 启动存储监控
  void _startStorageMonitoring() {
    _storageMonitoringTimer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      try {
        await _monitorStorageHealth();
      } catch (e) {
        print('存储监控失败: $e');
      }
    });
  }
  
  /// 执行定期优化
  Future<void> _performPeriodicOptimization() async {
    print('开始定期优化...');
    
    // 检查数据完整性
    await _checkDataIntegrity();
    
    // 清理过期数据
    await _cleanupExpiredData();
    
    // 压缩数据库
    await _compressDatabase();
    
    // 优化队列
    await _optimizeOfflineQueue();
    
    // 生成统计信息
    await _generateStatistics();
    
    print('定期优化完成');
  }
  
  /// 检查数据完整性
  Future<void> _checkDataIntegrity() async {
    final db = await _dbHelper.database;
    final checkId = const Uuid().v4();
    final checkTime = DateTime.now().millisecondsSinceEpoch;
    
    try {
      // 检查主要表的完整性
      final tables = ['calculation_records', 'parameter_sets', 'enhanced_offline_queue'];
      
      for (final tableName in tables) {
        int issuesFound = 0;
        int issuesFixed = 0;
        
        try {
          // 检查表结构
          await db.rawQuery('PRAGMA table_info($tableName)');
          
          // 检查数据一致性
          final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName WHERE id IS NULL OR id = ""');
          final nullIdCount = result.first['count'] as int;
          
          if (nullIdCount > 0) {
            issuesFound += nullIdCount;
            
            // 尝试修复空ID记录
            await db.delete(tableName, where: 'id IS NULL OR id = ""');
            issuesFixed += nullIdCount;
          }
          
          // 检查JSON字段格式
          if (tableName == 'calculation_records') {
            final jsonResult = await db.query(tableName, columns: ['id', 'parameters', 'results']);
            
            for (final record in jsonResult) {
              try {
                jsonDecode(record['parameters'] as String);
                jsonDecode(record['results'] as String);
              } catch (e) {
                issuesFound++;
                // 可以选择删除损坏的记录或尝试修复
                print('发现损坏的JSON数据: ${record['id']}');
              }
            }
          }
          
        } catch (e) {
          issuesFound++;
          print('表 $tableName 完整性检查失败: $e');
        }
        
        // 记录检查结果
        await db.insert(
          'data_integrity_checks',
          {
            'id': '${checkId}_$tableName',
            'table_name': tableName,
            'check_type': 'periodic_integrity_check',
            'check_result': issuesFound == 0 ? 'healthy' : 'issues_found',
            'issues_found': issuesFound,
            'issues_fixed': issuesFixed,
            'check_time': checkTime,
          },
        );
      }
      
      print('数据完整性检查完成');
      
    } catch (e) {
      print('数据完整性检查失败: $e');
      
      // 记录检查失败
      await db.insert(
        'data_integrity_checks',
        {
          'id': '${checkId}_failed',
          'table_name': 'all',
          'check_type': 'periodic_integrity_check',
          'check_result': 'check_failed',
          'issues_found': 1,
          'issues_fixed': 0,
          'check_time': checkTime,
        },
      );
    }
  }
  
  /// 清理过期数据
  Future<void> _cleanupExpiredData() async {
    final db = await _dbHelper.database;
    
    try {
      // 清理过期的完整性检查记录（保留最近30天）
      final cutoffTime = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      
      final deletedChecks = await db.delete(
        'data_integrity_checks',
        where: 'check_time < ?',
        whereArgs: [cutoffTime],
      );
      
      // 清理过期的统计记录（保留最近7天）
      final statsCutoffTime = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      
      final deletedStats = await db.delete(
        'offline_storage_stats',
        where: 'created_at < ?',
        whereArgs: [statsCutoffTime],
      );
      
      // 清理已完成的离线队列项（保留最近3天）
      final queueCutoffTime = DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch;
      
      final deletedQueueItems = await db.delete(
        'enhanced_offline_queue',
        where: 'status = ? AND created_at < ?',
        whereArgs: ['completed', queueCutoffTime],
      );
      
      print('清理过期数据完成: 检查记录 $deletedChecks, 统计记录 $deletedStats, 队列项 $deletedQueueItems');
      
    } catch (e) {
      print('清理过期数据失败: $e');
    }
  }
  
  /// 优化数据库
  Future<void> _optimizeDatabase() async {
    try {
      await _dbHelper.optimizeDatabase();
      print('数据库优化完成');
    } catch (e) {
      print('数据库优化失败: $e');
    }
  }
  
  /// 压缩数据库
  Future<void> _compressDatabase() async {
    try {
      final db = await _dbHelper.database;
      
      // 执行VACUUM操作
      await db.execute('VACUUM');
      
      // 重建索引
      await db.execute('REINDEX');
      
      print('数据库压缩完成');
      
    } catch (e) {
      print('数据库压缩失败: $e');
    }
  }
  
  /// 优化离线队列
  Future<void> _optimizeOfflineQueue() async {
    final db = await _dbHelper.database;
    
    try {
      // 清理重复的队列项
      await db.execute('''
        DELETE FROM enhanced_offline_queue 
        WHERE id NOT IN (
          SELECT MIN(id) 
          FROM enhanced_offline_queue 
          GROUP BY record_id, operation_type
        )
      ''');
      
      // 重新排序队列项（按优先级和创建时间）
      await db.execute('''
        UPDATE enhanced_offline_queue 
        SET priority = 'high' 
        WHERE operation_type = 'create' AND retry_count > 2
      ''');
      
      print('离线队列优化完成');
      
    } catch (e) {
      print('离线队列优化失败: $e');
    }
  }
  
  /// 处理离线队列
  Future<void> _processOfflineQueue() async {
    if (!_networkService.isConnected) {
      return;
    }
    
    final db = await _dbHelper.database;
    
    try {
      // 获取待处理的队列项（按优先级和依赖关系排序）
      final queueItems = await db.rawQuery('''
        SELECT * FROM enhanced_offline_queue 
        WHERE status = 'pending' 
        AND (scheduled_at IS NULL OR scheduled_at <= ?)
        AND (depends_on IS NULL OR depends_on IN (
          SELECT id FROM enhanced_offline_queue WHERE status = 'completed'
        ))
        ORDER BY 
          CASE priority 
            WHEN 'critical' THEN 1 
            WHEN 'high' THEN 2 
            WHEN 'normal' THEN 3 
            WHEN 'low' THEN 4 
          END,
          created_at ASC
        LIMIT 20
      ''', [DateTime.now().millisecondsSinceEpoch]);
      
      if (queueItems.isEmpty) {
        return;
      }
      
      print('处理 ${queueItems.length} 个离线队列项');
      
      for (final itemData in queueItems) {
        try {
          final item = EnhancedOfflineQueueItem.fromJson(itemData);
          
          // 检查重试次数
          if (item.retryCount >= AppConstants.maxRetryAttempts) {
            await _markQueueItemAsFailed(item.id, '超过最大重试次数');
            continue;
          }
          
          // 更新状态为处理中
          await _updateQueueItemStatus(item.id, 'processing');
          
          // 执行操作
          final success = await _executeQueueItem(item);
          
          if (success) {
            await _markQueueItemAsCompleted(item.id);
          } else {
            await _incrementRetryCount(item.id);
          }
          
        } catch (e) {
          print('处理队列项失败: $e');
          await _incrementRetryCount(itemData['id'], e.toString());
        }
      }
      
    } catch (e) {
      print('处理离线队列失败: $e');
    }
  }
  
  /// 执行队列项
  Future<bool> _executeQueueItem(EnhancedOfflineQueueItem item) async {
    try {
      switch (item.operationType) {
        case OfflineOperationType.create:
          return await _executeCreateOperation(item);
        case OfflineOperationType.update:
          return await _executeUpdateOperation(item);
        case OfflineOperationType.delete:
          return await _executeDeleteOperation(item);
        case OfflineOperationType.sync:
          return await _executeSyncOperation(item);
      }
    } catch (e) {
      print('执行队列项失败: ${item.id}, 错误: $e');
      return false;
    }
  }
  
  /// 执行创建操作
  Future<bool> _executeCreateOperation(EnhancedOfflineQueueItem item) async {
    // 这里应该调用相应的远程API创建记录
    // 暂时模拟成功
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }
  
  /// 执行更新操作
  Future<bool> _executeUpdateOperation(EnhancedOfflineQueueItem item) async {
    // 这里应该调用相应的远程API更新记录
    // 暂时模拟成功
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }
  
  /// 执行删除操作
  Future<bool> _executeDeleteOperation(EnhancedOfflineQueueItem item) async {
    // 这里应该调用相应的远程API删除记录
    // 暂时模拟成功
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }
  
  /// 执行同步操作
  Future<bool> _executeSyncOperation(EnhancedOfflineQueueItem item) async {
    // 这里应该执行数据同步
    // 暂时模拟成功
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }
  
  /// 更新队列项状态
  Future<void> _updateQueueItemStatus(String itemId, String status) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'enhanced_offline_queue',
      {
        'status': status,
        'last_retry_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }
  
  /// 标记队列项为已完成
  Future<void> _markQueueItemAsCompleted(String itemId) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'enhanced_offline_queue',
      {
        'status': 'completed',
        'last_retry_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }
  
  /// 标记队列项为失败
  Future<void> _markQueueItemAsFailed(String itemId, String errorMessage) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'enhanced_offline_queue',
      {
        'status': 'failed',
        'error_message': errorMessage,
        'last_retry_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }
  
  /// 增加重试次数
  Future<void> _incrementRetryCount(String itemId, [String? errorMessage]) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'enhanced_offline_queue',
      {
        'retry_count': 'retry_count + 1',
        'status': 'pending',
        'error_message': errorMessage,
        'last_retry_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }
  
  /// 监控存储健康状态
  Future<void> _monitorStorageHealth() async {
    try {
      final statistics = await _generateStatistics();
      
      // 根据统计信息判断健康状态
      OfflineStorageStatus newStatus = OfflineStorageStatus.healthy;
      
      if (statistics.storageUsagePercentage > 90) {
        newStatus = OfflineStorageStatus.critical;
      } else if (statistics.storageUsagePercentage > 75) {
        newStatus = OfflineStorageStatus.warning;
      } else if (statistics.failedItems > statistics.totalQueueItems * 0.5) {
        newStatus = OfflineStorageStatus.warning;
      }
      
      // 检查数据完整性问题
      final db = await _dbHelper.database;
      final recentChecks = await db.query(
        'data_integrity_checks',
        where: 'check_time > ?',
        whereArgs: [DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch],
        orderBy: 'check_time DESC',
        limit: 10,
      );
      
      final hasIntegrityIssues = recentChecks.any((check) => 
          (check['issues_found'] as int) > (check['issues_fixed'] as int));
      
      if (hasIntegrityIssues) {
        newStatus = OfflineStorageStatus.corrupted;
      }
      
      // 更新状态
      if (_currentStatus != newStatus) {
        _currentStatus = newStatus;
        _statusController.add(newStatus);
        print('存储健康状态更新: $newStatus');
      }
      
    } catch (e) {
      print('存储健康监控失败: $e');
      _currentStatus = OfflineStorageStatus.critical;
      _statusController.add(_currentStatus);
    }
  }
  
  /// 生成统计信息
  Future<OfflineStorageStatistics> _generateStatistics() async {
    final db = await _dbHelper.database;
    
    try {
      // 获取队列统计
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM enhanced_offline_queue');
      final totalQueueItems = totalResult.first['count'] as int;
      
      final pendingResult = await db.rawQuery('SELECT COUNT(*) as count FROM enhanced_offline_queue WHERE status = ?', ['pending']);
      final pendingItems = pendingResult.first['count'] as int;
      
      final failedResult = await db.rawQuery('SELECT COUNT(*) as count FROM enhanced_offline_queue WHERE status = ?', ['failed']);
      final failedItems = failedResult.first['count'] as int;
      
      final completedResult = await db.rawQuery('SELECT COUNT(*) as count FROM enhanced_offline_queue WHERE status = ?', ['completed']);
      final completedItems = completedResult.first['count'] as int;
      
      // 按优先级统计
      final itemsByPriority = <OfflinePriority, int>{};
      for (final priority in OfflinePriority.values) {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM enhanced_offline_queue WHERE priority = ?',
          [priority.toString()],
        );
        itemsByPriority[priority] = result.first['count'] as int;
      }
      
      // 按操作类型统计
      final itemsByType = <OfflineOperationType, int>{};
      for (final type in OfflineOperationType.values) {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM enhanced_offline_queue WHERE operation_type = ?',
          [type.toString()],
        );
        itemsByType[type] = result.first['count'] as int;
      }
      
      // 获取存储使用情况
      final storageInfo = await _getStorageInfo();
      
      // 收集警告信息
      final warnings = <String>[];
      if (storageInfo['usage_percentage'] > 75) {
        warnings.add('存储使用率过高: ${storageInfo['usage_percentage'].toStringAsFixed(1)}%');
      }
      if (failedItems > totalQueueItems * 0.3) {
        warnings.add('失败队列项过多: $failedItems/$totalQueueItems');
      }
      if (pendingItems > 100) {
        warnings.add('待处理队列项过多: $pendingItems');
      }
      
      final statistics = OfflineStorageStatistics(
        totalQueueItems: totalQueueItems,
        pendingItems: pendingItems,
        failedItems: failedItems,
        completedItems: completedItems,
        itemsByPriority: itemsByPriority,
        itemsByType: itemsByType,
        storageUsage: storageInfo['usage_mb'],
        availableStorage: storageInfo['available_mb'],
        status: _currentStatus,
        warnings: warnings,
        generatedAt: DateTime.now(),
      );
      
      // 保存统计信息
      await _saveStatistics(statistics);
      
      // 发送统计信息
      _statisticsController.add(statistics);
      
      return statistics;
      
    } catch (e) {
      print('生成统计信息失败: $e');
      rethrow;
    }
  }
  
  /// 获取存储信息
  Future<Map<String, double>> _getStorageInfo() async {
    try {
      // 获取数据库文件大小
      final db = await _dbHelper.database;
      final dbFile = File(db.path);
      final dbSize = await dbFile.length();
      
      // 获取可用存储空间（简化实现）
      final directory = Directory(dirname(db.path));
      final stat = await directory.stat();
      
      // 这里应该获取实际的可用空间，暂时使用估算值
      const estimatedAvailableSpace = 1024 * 1024 * 1024; // 1GB
      
      final usageMB = dbSize / (1024 * 1024);
      final availableMB = estimatedAvailableSpace / (1024 * 1024);
      
      return {
        'usage_mb': usageMB,
        'available_mb': availableMB,
        'usage_percentage': (usageMB / availableMB) * 100,
      };
      
    } catch (e) {
      print('获取存储信息失败: $e');
      return {
        'usage_mb': 0.0,
        'available_mb': 1024.0, // 默认1GB
        'usage_percentage': 0.0,
      };
    }
  }
  
  /// 保存统计信息
  Future<void> _saveStatistics(OfflineStorageStatistics statistics) async {
    final db = await _dbHelper.database;
    
    try {
      await db.insert(
        'offline_storage_stats',
        {
          'id': const Uuid().v4(),
          'stat_type': 'periodic_statistics',
          'stat_value': jsonEncode(statistics.toJson()),
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
    } catch (e) {
      print('保存统计信息失败: $e');
    }
  }
  
  /// 添加到离线队列
  Future<void> addToOfflineQueue(EnhancedOfflineQueueItem item) async {
    final db = await _dbHelper.database;
    
    try {
      await db.insert(
        'enhanced_offline_queue',
        item.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('操作已添加到离线队列: ${item.id}');
      
    } catch (e) {
      print('添加到离线队列失败: $e');
      rethrow;
    }
  }
  
  /// 获取队列统计
  Future<Map<String, int>> getQueueStatistics() async {
    final db = await _dbHelper.database;
    
    try {
      final stats = <String, int>{};
      
      // 按状态统计
      final statuses = ['pending', 'processing', 'completed', 'failed'];
      for (final status in statuses) {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM enhanced_offline_queue WHERE status = ?',
          [status],
        );
        stats[status] = result.first['count'] as int;
      }
      
      return stats;
      
    } catch (e) {
      print('获取队列统计失败: $e');
      return {};
    }
  }
  
  /// 清理队列
  Future<int> cleanupQueue({
    Duration? olderThan,
    List<String>? statuses,
  }) async {
    final db = await _dbHelper.database;
    
    try {
      String whereClause = '1=1';
      final whereArgs = <dynamic>[];
      
      if (olderThan != null) {
        final cutoffTime = DateTime.now().subtract(olderThan).millisecondsSinceEpoch;
        whereClause += ' AND created_at < ?';
        whereArgs.add(cutoffTime);
      }
      
      if (statuses != null && statuses.isNotEmpty) {
        final placeholders = statuses.map((_) => '?').join(',');
        whereClause += ' AND status IN ($placeholders)';
        whereArgs.addAll(statuses);
      }
      
      final deletedCount = await db.delete(
        'enhanced_offline_queue',
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      );
      
      print('清理了 $deletedCount 个队列项');
      return deletedCount;
      
    } catch (e) {
      print('清理队列失败: $e');
      return 0;
    }
  }
  
  /// 强制处理队列
  Future<void> forceProcessQueue() async {
    try {
      await _processOfflineQueue();
      print('强制队列处理完成');
    } catch (e) {
      print('强制队列处理失败: $e');
      rethrow;
    }
  }
  
  /// 获取当前统计信息
  Future<OfflineStorageStatistics> getCurrentStatistics() async {
    return await _generateStatistics();
  }
  
  /// 释放资源
  void dispose() {
    _optimizationTimer?.cancel();
    _queueProcessingTimer?.cancel();
    _storageMonitoringTimer?.cancel();
    _statisticsController.close();
    _statusController.close();
    _isInitialized = false;
    print('离线存储优化器已释放');
  }
}