import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'remote_database_service.dart';
import 'sync_status_manager.dart' as sync_status_manager;
import 'cloud_sync_manager.dart';
import '../models/calculation_result.dart';
import '../models/parameter_models.dart';
import '../models/enums.dart';
import '../utils/constants.dart';

/// 计算记录存储库
/// 
/// 负责计算记录的本地和远程双重存储、历史记录管理、同步功能
class CalculationRepository {
  static CalculationRepository? _instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final RemoteDatabaseService _remoteDb = RemoteDatabaseService();
  final sync_status_manager.SyncStatusManager _syncManager = sync_status_manager.SyncStatusManager();
  CloudSyncManager? _cloudSync;
  
  bool _isInitialized = false;
  Timer? _autoSyncTimer;
  
  /// 单例模式
  CalculationRepository._internal();
  
  factory CalculationRepository() {
    _instance ??= CalculationRepository._internal();
    return _instance!;
  }
  
  /// 初始化存储库
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 初始化数据库连接
      await _dbHelper.database;
      
      // 初始化同步管理器
      await _syncManager.initialize();
      
      // 初始化云端同步管理器（延迟初始化）
      await _ensureCloudSyncInitialized();
      
      // 尝试初始化远程数据库（可选）
      try {
        await _remoteDb.initializeDatabase();
        print('远程数据库初始化成功');
      } catch (e) {
        print('远程数据库初始化失败，将仅使用本地存储: $e');
      }
      
      // 启动自动同步（如果启用）
      await _startAutoSyncIfEnabled();
      
      _isInitialized = true;
      print('计算记录存储库初始化完成');
      
    } catch (e) {
      print('计算记录存储库初始化失败: $e');
      rethrow;
    }
  }
  
  /// 保存计算记录
  Future<void> saveCalculationRecord(CalculationResult result) async {
    await _ensureInitialized();
    
    try {
      // 保存到本地SQLite
      await _saveToLocal(result);
      
      // 尝试同步到远程MySQL（如果网络可用）
      await _trySyncToRemote(result);
      
      // 尝试同步到云端Firebase（如果用户已登录）
      await _trySyncToCloud(result);
      
      print('计算记录保存成功: ${result.id}');
      
    } catch (e) {
      print('保存计算记录失败: $e');
      rethrow;
    }
  }
  
  /// 保存到本地数据库
  Future<void> _saveToLocal(CalculationResult result) async {
    final db = await _dbHelper.database;
    
    await db.insert(
      'calculation_records',
      {
        'id': result.id,
        'calculation_type': result.calculationType.toString(),
        'parameters': jsonEncode(result.parameters.toJson()),
        'results': jsonEncode(result.toJson()),
        'created_at': result.calculationTime.millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0, // 0表示未同步
        'device_id': _syncManager.deviceId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// 尝试同步到远程
  Future<void> _trySyncToRemote(CalculationResult result) async {
    try {
      if (await _remoteDb.isConnected()) {
        await _remoteDb.syncCalculationRecord(result, _syncManager.deviceId);
        
        // 更新本地同步状态
        await _updateLocalSyncStatus(result.id, 1); // 1表示已同步
      }
    } catch (e) {
      print('远程同步失败，记录将在下次同步时重试: $e');
      // 不抛出异常，允许本地保存成功
    }
  }

  /// 尝试同步到云端
  Future<void> _trySyncToCloud(CalculationResult result) async {
    try {
      await _ensureCloudSyncInitialized();
      if (_cloudSync?.canSync == true) {
        await _cloudSync!.syncCalculationRecord(result);
        print('云端同步成功: ${result.id}');
      }
    } catch (e) {
      print('云端同步失败，记录将在下次同步时重试: $e');
      // 不抛出异常，允许本地保存成功
    }
  }
  
  /// 更新本地同步状态
  Future<void> _updateLocalSyncStatus(String recordId, int syncStatus) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'calculation_records',
      {
        'sync_status': syncStatus,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }
  
  /// 获取计算记录
  Future<CalculationResult?> getCalculationRecord(String id) async {
    await _ensureInitialized();
    
    try {
      final db = await _dbHelper.database;
      
      final result = await db.query(
        'calculation_records',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result.isNotEmpty) {
        return _mapToCalculationResult(result.first);
      }
      
      return null;
      
    } catch (e) {
      print('获取计算记录失败: $e');
      rethrow;
    }
  }
  
  /// 获取计算历史记录
  Future<List<CalculationResult>> getCalculationHistory({
    CalculationType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
    String? searchKeyword,
  }) async {
    await _ensureInitialized();
    
    try {
      final db = await _dbHelper.database;
      
      // 构建查询条件
      String whereClause = '1=1';
      final whereArgs = <dynamic>[];
      
      if (type != null) {
        whereClause += ' AND calculation_type = ?';
        whereArgs.add(type.toString());
      }
      
      if (startDate != null) {
        whereClause += ' AND created_at >= ?';
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }
      
      if (endDate != null) {
        whereClause += ' AND created_at <= ?';
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }
      
      if (searchKeyword != null && searchKeyword.isNotEmpty) {
        whereClause += ' AND (parameters LIKE ? OR results LIKE ?)';
        final keyword = '%$searchKeyword%';
        whereArgs.add(keyword);
        whereArgs.add(keyword);
      }
      
      // 构建查询
      String query = '''
        SELECT * FROM calculation_records 
        WHERE $whereClause 
        ORDER BY created_at DESC
      ''';
      
      if (limit != null) {
        query += ' LIMIT $limit';
        if (offset != null) {
          query += ' OFFSET $offset';
        }
      }
      
      final results = await db.rawQuery(query, whereArgs);
      
      return results.map((row) => _mapToCalculationResult(row)).toList();
      
    } catch (e) {
      print('获取计算历史失败: $e');
      rethrow;
    }
  }
  
  /// 获取计算统计信息
  Future<Map<String, dynamic>> getCalculationStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _ensureInitialized();
    
    try {
      final db = await _dbHelper.database;
      
      String whereClause = '1=1';
      final whereArgs = <dynamic>[];
      
      if (startDate != null) {
        whereClause += ' AND created_at >= ?';
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }
      
      if (endDate != null) {
        whereClause += ' AND created_at <= ?';
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }
      
      // 总记录数
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM calculation_records WHERE $whereClause',
        whereArgs,
      );
      final totalCount = totalResult.first['count'] as int;
      
      // 按类型统计
      final typeStats = <String, int>{};
      for (final type in CalculationType.values) {
        final typeResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM calculation_records WHERE $whereClause AND calculation_type = ?',
          [...whereArgs, type.toString()],
        );
        typeStats[type.toString()] = typeResult.first['count'] as int;
      }
      
      // 按日期统计（最近7天）
      final dailyStats = <String, int>{};
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        
        final dayResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM calculation_records WHERE created_at >= ? AND created_at < ?',
          [dayStart.millisecondsSinceEpoch, dayEnd.millisecondsSinceEpoch],
        );
        
        final dateKey = '${date.month}-${date.day}';
        dailyStats[dateKey] = dayResult.first['count'] as int;
      }
      
      // 同步状态统计
      final syncedResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM calculation_records WHERE $whereClause AND sync_status = 1',
        whereArgs,
      );
      final syncedCount = syncedResult.first['count'] as int;
      
      return {
        'total_count': totalCount,
        'synced_count': syncedCount,
        'unsynced_count': totalCount - syncedCount,
        'sync_rate': totalCount > 0 ? syncedCount / totalCount : 0.0,
        'type_statistics': typeStats,
        'daily_statistics': dailyStats,
        'generated_at': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('获取计算统计失败: $e');
      rethrow;
    }
  }
  
  /// 删除计算记录
  Future<bool> deleteCalculationRecord(String id) async {
    await _ensureInitialized();
    
    try {
      final db = await _dbHelper.database;
      
      final deletedRows = await db.delete(
        'calculation_records',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (deletedRows > 0) {
        print('计算记录删除成功: $id');
        
        // 如果记录已同步，需要标记为删除状态同步到远程
        // 这里可以添加软删除逻辑
        
        return true;
      }
      
      return false;
      
    } catch (e) {
      print('删除计算记录失败: $e');
      rethrow;
    }
  }
  
  /// 批量删除计算记录
  Future<int> batchDeleteCalculationRecords(List<String> ids) async {
    if (ids.isEmpty) return 0;
    
    await _ensureInitialized();
    
    try {
      final db = await _dbHelper.database;
      
      final placeholders = ids.map((_) => '?').join(',');
      final deletedRows = await db.rawDelete(
        'DELETE FROM calculation_records WHERE id IN ($placeholders)',
        ids,
      );
      
      print('批量删除 $deletedRows 条计算记录');
      return deletedRows;
      
    } catch (e) {
      print('批量删除计算记录失败: $e');
      rethrow;
    }
  }
  
  /// 清理过期记录
  Future<int> cleanupExpiredRecords(Duration retentionPeriod) async {
    await _ensureInitialized();
    
    try {
      final db = await _dbHelper.database;
      final cutoffTime = DateTime.now().subtract(retentionPeriod).millisecondsSinceEpoch;
      
      final deletedRows = await db.delete(
        'calculation_records',
        where: 'created_at < ?',
        whereArgs: [cutoffTime],
      );
      
      print('清理了 $deletedRows 条过期记录');
      return deletedRows;
      
    } catch (e) {
      print('清理过期记录失败: $e');
      rethrow;
    }
  }
  
  /// 执行完整同步
  Future<sync_status_manager.SyncStatistics> performFullSync() async {
    await _ensureInitialized();
    
    try {
      return await _syncManager.startSync(forceFullSync: true);
    } catch (e) {
      print('完整同步失败: $e');
      rethrow;
    }
  }
  
  /// 执行增量同步
  Future<sync_status_manager.SyncStatistics> performIncrementalSync() async {
    await _ensureInitialized();
    
    try {
      return await _syncManager.startSync(forceFullSync: false);
    } catch (e) {
      print('增量同步失败: $e');
      rethrow;
    }
  }
  
  /// 批量同步未同步的记录
  Future<void> batchSyncUnsyncedRecords() async {
    await _ensureInitialized();
    
    try {
      final db = await _dbHelper.database;
      
      // 获取未同步的记录
      final unsyncedRecords = await db.query(
        'calculation_records',
        where: 'sync_status = 0',
        limit: 100, // 批量处理，避免一次性处理太多
      );
      
      if (unsyncedRecords.isEmpty) {
        print('没有需要同步的记录');
        return;
      }
      
      // 转换为CalculationResult对象
      final results = unsyncedRecords
          .map((row) => _mapToCalculationResult(row))
          .toList();
      
      // 批量同步到远程
      if (await _remoteDb.isConnected()) {
        await _remoteDb.batchSyncCalculationRecords(results, _syncManager.deviceId);
        
        // 更新本地同步状态
        final batch = db.batch();
        for (final record in unsyncedRecords) {
          batch.update(
            'calculation_records',
            {
              'sync_status': 1,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [record['id']],
          );
        }
        await batch.commit();
        
        print('批量同步 ${results.length} 条记录成功');
      } else {
        throw Exception('远程数据库连接不可用');
      }
      
    } catch (e) {
      print('批量同步失败: $e');
      rethrow;
    }
  }
  
  /// 导出计算记录
  Future<List<Map<String, dynamic>>> exportCalculationRecords({
    CalculationType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _ensureInitialized();
    
    try {
      final records = await getCalculationHistory(
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
      
      return records.map((record) => {
        'id': record.id,
        'calculation_type': record.calculationType.toString(),
        'calculation_time': record.calculationTime.toIso8601String(),
        'parameters': record.parameters.toJson(),
        'results': record.toJson(),
      }).toList();
      
    } catch (e) {
      print('导出计算记录失败: $e');
      rethrow;
    }
  }
  
  /// 导入计算记录
  Future<int> importCalculationRecords(List<Map<String, dynamic>> recordsData) async {
    await _ensureInitialized();
    
    try {
      final db = await _dbHelper.database;
      int importedCount = 0;
      
      final batch = db.batch();
      
      for (final recordData in recordsData) {
        try {
          // 验证数据格式
          if (!_validateImportData(recordData)) {
            print('跳过无效记录: ${recordData['id']}');
            continue;
          }
          
          batch.insert(
            'calculation_records',
            {
              'id': recordData['id'],
              'calculation_type': recordData['calculation_type'],
              'parameters': jsonEncode(recordData['parameters']),
              'results': jsonEncode(recordData['results']),
              'created_at': DateTime.parse(recordData['calculation_time']).millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
              'sync_status': 0, // 导入的记录标记为未同步
              'device_id': _syncManager.deviceId,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore, // 忽略重复记录
          );
          
          importedCount++;
          
        } catch (e) {
          print('导入记录失败: ${recordData['id']}, 错误: $e');
        }
      }
      
      await batch.commit();
      
      print('成功导入 $importedCount 条记录');
      return importedCount;
      
    } catch (e) {
      print('导入计算记录失败: $e');
      rethrow;
    }
  }
  
  /// 验证导入数据
  bool _validateImportData(Map<String, dynamic> data) {
    final requiredFields = ['id', 'calculation_type', 'calculation_time', 'parameters', 'results'];
    
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        return false;
      }
    }
    
    // 验证计算类型
    try {
      CalculationType.values.firstWhere(
        (type) => type.toString() == data['calculation_type'],
      );
    } catch (e) {
      return false;
    }
    
    // 验证时间格式
    try {
      DateTime.parse(data['calculation_time']);
    } catch (e) {
      return false;
    }
    
    return true;
  }
  
  /// 启动自动同步
  Future<void> _startAutoSyncIfEnabled() async {
    try {
      final db = await _dbHelper.database;
      
      final result = await db.query(
        'user_settings',
        where: 'key = ?',
        whereArgs: ['auto_sync'],
      );
      
      final autoSyncEnabled = result.isNotEmpty && result.first['value'] == 'true';
      
      if (autoSyncEnabled) {
        _autoSyncTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
          try {
            if (await _syncManager.needsSync()) {
              await performIncrementalSync();
            }
          } catch (e) {
            print('自动同步失败: $e');
          }
        });
        
        print('自动同步已启动');
      }
      
    } catch (e) {
      print('启动自动同步失败: $e');
    }
  }
  
  /// 停止自动同步
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    print('自动同步已停止');
  }
  
  /// 将数据库行映射为CalculationResult对象
  CalculationResult _mapToCalculationResult(Map<String, dynamic> row) {
    final calculationType = CalculationType.values.firstWhere(
      (type) => type.toString() == row['calculation_type'],
    );
    
    final parametersJson = jsonDecode(row['parameters'] as String);
    final resultsJson = jsonDecode(row['results'] as String);
    
    // 根据计算类型创建相应的参数对象
    // 这里需要根据实际的参数类型进行转换
    // 暂时返回一个基础的CalculationResult
    
    return CalculationResult.fromJson({
      'id': row['id'],
      'calculationType': calculationType.toString(),
      'calculationTime': DateTime.fromMillisecondsSinceEpoch(row['created_at']),
      'parameters': parametersJson,
      'results': resultsJson,
    });
  }
  
  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  /// 获取存储库状态
  Future<Map<String, dynamic>> getRepositoryStatus() async {
    await _ensureInitialized();
    
    try {
      final db = await _dbHelper.database;
      
      // 获取记录统计
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM calculation_records');
      final totalCount = totalResult.first['count'] as int;
      
      final syncedResult = await db.rawQuery('SELECT COUNT(*) as count FROM calculation_records WHERE sync_status = 1');
      final syncedCount = syncedResult.first['count'] as int;
      
      // 获取数据库大小信息
      final dbInfo = await _dbHelper.getDatabaseInfo();
      
      // 获取同步状态
      final syncStats = await _syncManager.getLastSyncStatistics();
      
      return {
        'initialized': _isInitialized,
        'total_records': totalCount,
        'synced_records': syncedCount,
        'unsynced_records': totalCount - syncedCount,
        'sync_rate': totalCount > 0 ? syncedCount / totalCount : 0.0,
        'database_info': dbInfo,
        'last_sync_statistics': syncStats?.toJson(),
        'auto_sync_enabled': _autoSyncTimer != null,
        'remote_connected': await _remoteDb.isConnected(),
      };
      
    } catch (e) {
      print('获取存储库状态失败: $e');
      return {
        'initialized': _isInitialized,
        'error': e.toString(),
      };
    }
  }
  
  /// 释放资源
  Future<void> dispose() async {
    stopAutoSync();
    await _remoteDb.close();
    await _dbHelper.close();
    _syncManager.dispose();
    _isInitialized = false;
    print('计算记录存储库已释放');
  }

  /// 确保云端同步已初始化
  Future<void> _ensureCloudSyncInitialized() async {
    if (_cloudSync == null) {
      _cloudSync = CloudSyncManager();
      try {
        await _cloudSync!.initialize();
      } catch (e) {
        print('云端同步初始化失败，将在测试环境中跳过: $e');
        // 不抛出异常，允许在测试环境中继续运行
      }
    }
  }
}