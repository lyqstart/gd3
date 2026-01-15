import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calculation_record.dart';
import '../models/parameter_set.dart';
import '../models/enums.dart';
import 'local_data_service.dart';

/// 上传结果
class UploadResult {
  final bool success;
  final int? serverId;
  final String? serverTimestamp;
  final String? error;

  UploadResult({
    required this.success,
    this.serverId,
    this.serverTimestamp,
    this.error,
  });
}

/// 同步结果
class SyncResult {
  final bool success;
  final String? message;
  final int uploadedCount;
  final int downloadedCount;
  final List<String> conflicts;

  SyncResult({
    required this.success,
    this.message,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.conflicts = const [],
  });
}

/// 冲突解决策略
enum ConflictResolutionStrategy {
  /// 保留本地数据
  keepLocal,
  
  /// 保留服务器数据
  keepServer,
  
  /// 保留最新数据
  keepNewest,
}

/// 云同步服务
/// 
/// 提供数据上传、下载和冲突解决功能
class SyncService {
  final http.Client httpClient;
  final LocalDataService localDataService;
  final String baseUrl;
  final String? authToken;

  SyncService({
    required this.httpClient,
    required this.localDataService,
    required this.baseUrl,
    this.authToken,
  });

  /// 上传计算记录
  Future<UploadResult> uploadCalculationRecord(
    CalculationRecord record,
    String token,
  ) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/sync/calculations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(record.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // 更新本地记录的同步状态
        final updatedRecord = record.copyWith(syncStatus: SyncStatus.synced);
        
        // 如果记录有ID,更新它;否则保存为新记录
        if (record.id != null) {
          await localDataService.updateCalculationRecord(updatedRecord);
        } else {
          // 新记录,保存它(会自动分配ID)
          await localDataService.saveCalculationRecord(updatedRecord);
        }
        
        return UploadResult(
          success: true,
          serverId: data['serverId'] as int?,
          serverTimestamp: data['serverTimestamp'] as String?,
        );
      }

      return UploadResult(
        success: false,
        error: 'HTTP ${response.statusCode}',
      );
    } catch (e) {
      print('上传计算记录失败: $e');
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 下载计算记录
  Future<List<CalculationRecord>> downloadCalculationRecords(
    String token, [
    DateTime? since,
  ]) async {
    try {
      final uri = Uri.parse('$baseUrl/api/sync/calculations').replace(
        queryParameters: {
          if (since != null) 'since': since.toIso8601String(),
        },
      );

      final response = await httpClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CalculationRecord.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('下载计算记录失败: $e');
      return [];
    }
  }

  /// 上传参数组
  Future<bool> uploadParameterSet(ParameterSet parameterSet) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/sync/parameters'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(parameterSet.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 更新本地参数组的同步状态
        final updatedSet = parameterSet.copyWith(syncStatus: 'synced');
        await localDataService.updateParameterSet(updatedSet);
        return true;
      }

      return false;
    } catch (e) {
      print('上传参数组失败: $e');
      return false;
    }
  }

  /// 下载参数组
  Future<List<ParameterSet>> downloadParameterSets({
    DateTime? since,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/sync/parameters').replace(
        queryParameters: {
          if (since != null) 'since': since.toIso8601String(),
        },
      );

      final response = await httpClient.get(
        uri,
        headers: {
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ParameterSet.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('下载参数组失败: $e');
      return [];
    }
  }

  /// 执行完整同步
  Future<SyncResult> performFullSync({
    required String token,
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.keepNewest,
  }) async {
    int uploadedCount = 0;
    int downloadedCount = 0;
    final conflicts = <String>[];

    try {
      // 1. 上传待同步的计算记录
      final pendingRecords = await localDataService.getPendingCalculationRecords();
      for (final record in pendingRecords) {
        final result = await uploadCalculationRecord(record, token);
        if (result.success) uploadedCount++;
      }

      // 2. 下载服务器上的新记录
      final serverRecords = await downloadCalculationRecords(token);
      for (final serverRecord in serverRecords) {
        final localRecord = await localDataService.getCalculationRecord(serverRecord.id);
        
        if (localRecord == null) {
          // 本地不存在,直接保存
          await localDataService.saveCalculationRecord(serverRecord);
          downloadedCount++;
        } else {
          // 检测冲突
          final localTime = localRecord.updatedAt ?? localRecord.createdAt;
          final serverTime = serverRecord.updatedAt ?? serverRecord.createdAt;
          if (localTime != serverTime) {
            conflicts.add(serverRecord.id.toString());
            
            // 根据策略解决冲突
            final resolvedRecord = _resolveConflict(
              localRecord,
              serverRecord,
              strategy,
            );
            await localDataService.updateCalculationRecord(resolvedRecord);
          }
        }
      }

      // 3. 上传待同步的参数组
      final pendingSets = await localDataService.getPendingParameterSets();
      for (final set in pendingSets) {
        final success = await uploadParameterSet(set);
        if (success) uploadedCount++;
      }

      // 4. 下载服务器上的新参数组
      final serverSets = await downloadParameterSets();
      for (final serverSet in serverSets) {
        final localSet = await localDataService.getParameterSet(serverSet.id);
        
        if (localSet == null) {
          await localDataService.saveParameterSet(serverSet);
          downloadedCount++;
        } else {
          final localTime = localSet.updatedAt ?? localSet.createdAt;
          final serverTime = serverSet.updatedAt ?? serverSet.createdAt;
          if (localTime != serverTime) {
            conflicts.add(serverSet.id);
            
            final resolvedSet = _resolveParameterSetConflict(
              localSet,
              serverSet,
              strategy,
            );
            await localDataService.updateParameterSet(resolvedSet);
          }
        }
      }

      return SyncResult(
        success: true,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        conflicts: conflicts,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: '同步失败: $e',
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        conflicts: conflicts,
      );
    }
  }

  /// 解决计算记录冲突
  CalculationRecord _resolveConflict(
    CalculationRecord local,
    CalculationRecord server,
    ConflictResolutionStrategy strategy,
  ) {
    switch (strategy) {
      case ConflictResolutionStrategy.keepLocal:
        return local;
      case ConflictResolutionStrategy.keepServer:
        return server;
      case ConflictResolutionStrategy.keepNewest:
        final localTime = local.updatedAt ?? local.createdAt;
        final serverTime = server.updatedAt ?? server.createdAt;
        return localTime.isAfter(serverTime) ? local : server;
    }
  }

  /// 检测冲突（公开方法）
  bool detectConflict(CalculationRecord local, CalculationRecord server) {
    // 如果clientId相同但内容不同，则存在冲突
    if (local.clientId != null && 
        local.clientId == server.clientId &&
        local.parameters != server.parameters) {
      return true;
    }
    return false;
  }

  /// 解决冲突（公开方法）
  CalculationRecord resolveConflict(
    CalculationRecord local,
    CalculationRecord server,
    ConflictResolutionStrategy strategy,
  ) {
    return _resolveConflict(local, server, strategy);
  }

  /// 同步待上传的记录
  Future<List<UploadResult>> syncPendingRecords(String token) async {
    final pendingRecords = await localDataService.getPendingSyncRecords();
    final results = <UploadResult>[];
    
    for (final record in pendingRecords) {
      final result = await uploadCalculationRecord(record, token);
      results.add(result);
    }
    
    return results;
  }

  /// 带重试的上传计算记录
  Future<UploadResult> uploadCalculationRecordWithRetry(
    CalculationRecord record,
    String token, {
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      attempts++;
      
      try {
        final result = await uploadCalculationRecord(record, token);
        if (result.success) {
          return result;
        }
        
        // 如果不是最后一次尝试，等待后重试
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: attempts));
        }
      } catch (e) {
        if (attempts >= maxRetries) {
          return UploadResult(
            success: false,
            error: '重试${maxRetries}次后仍失败: $e',
          );
        }
        // 等待后重试
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    
    return UploadResult(
      success: false,
      error: '达到最大重试次数',
    );
  }

  /// 解决参数组冲突
  ParameterSet _resolveParameterSetConflict(
    ParameterSet local,
    ParameterSet server,
    ConflictResolutionStrategy strategy,
  ) {
    switch (strategy) {
      case ConflictResolutionStrategy.keepLocal:
        return local;
      case ConflictResolutionStrategy.keepServer:
        return server;
      case ConflictResolutionStrategy.keepNewest:
        final localTime = local.updatedAt ?? local.createdAt;
        final serverTime = server.updatedAt ?? server.createdAt;
        return localTime.isAfter(serverTime) ? local : server;
    }
  }

  /// 删除计算记录（同步到服务器）
  Future<bool> deleteCalculationRecord(String id) async {
    try {
      final response = await httpClient.delete(
        Uri.parse('$baseUrl/api/sync/calculations/$id'),
        headers: {
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await localDataService.deleteCalculationRecord(id);
        return true;
      }

      return false;
    } catch (e) {
      print('删除计算记录失败: $e');
      return false;
    }
  }

  /// 更新计算记录（同步到服务器）
  Future<bool> updateCalculationRecord(CalculationRecord record) async {
    try {
      final response = await httpClient.put(
        Uri.parse('$baseUrl/api/sync/calculations/${record.id}'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(record.toJson()),
      );

      if (response.statusCode == 200) {
        await localDataService.updateCalculationRecord(record);
        return true;
      }

      return false;
    } catch (e) {
      print('更新计算记录失败: $e');
      return false;
    }
  }
}
