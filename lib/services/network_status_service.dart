import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../utils/constants.dart';

/// 网络连接类型
enum NetworkType {
  none,      // 无网络连接
  wifi,      // WiFi连接
  mobile,    // 移动网络
  ethernet,  // 以太网
  bluetooth, // 蓝牙
  vpn,       // VPN连接
  other,     // 其他类型
}

/// 网络状态
enum NetworkStatus {
  connected,    // 已连接
  disconnected, // 已断开
  connecting,   // 连接中
  unstable,     // 连接不稳定
}

/// 离线操作类型
enum OfflineOperationType {
  create,  // 创建
  update,  // 更新
  delete,  // 删除
  sync,    // 同步
}

/// 离线队列项
class OfflineQueueItem {
  final String id;
  final OfflineOperationType operationType;
  final String tableName;
  final String recordId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;
  DateTime? lastRetryAt;
  String? errorMessage;
  
  OfflineQueueItem({
    required this.id,
    required this.operationType,
    required this.tableName,
    required this.recordId,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.lastRetryAt,
    this.errorMessage,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'operation_type': operationType.toString(),
    'table_name': tableName,
    'record_id': recordId,
    'data': data,
    'created_at': createdAt.millisecondsSinceEpoch,
    'retry_count': retryCount,
    'last_retry_at': lastRetryAt?.millisecondsSinceEpoch,
    'error_message': errorMessage,
  };
  
  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) => OfflineQueueItem(
    id: json['id'],
    operationType: OfflineOperationType.values.firstWhere(
      (type) => type.toString() == json['operation_type'],
    ),
    tableName: json['table_name'],
    recordId: json['record_id'],
    data: Map<String, dynamic>.from(json['data']),
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
    retryCount: json['retry_count'] ?? 0,
    lastRetryAt: json['last_retry_at'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['last_retry_at'])
        : null,
    errorMessage: json['error_message'],
  );
}

/// 网络状态服务
/// 
/// 负责网络连接状态监控、离线队列管理、重试机制、数据库连接错误处理
class NetworkStatusService {
  static NetworkStatusService? _instance;
  final Connectivity _connectivity = Connectivity();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  NetworkStatus _currentStatus = NetworkStatus.disconnected;
  NetworkType _currentType = NetworkType.none;
  
  final StreamController<NetworkStatus> _statusController = StreamController<NetworkStatus>.broadcast();
  final StreamController<NetworkType> _typeController = StreamController<NetworkType>.broadcast();
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _connectionCheckTimer;
  Timer? _retryTimer;
  
  bool _isInitialized = false;
  int _consecutiveFailures = 0;
  DateTime? _lastSuccessfulConnection;
  
  // 监听器列表
  final List<VoidCallback> _listeners = [];
  
  /// 最大重试次数
  static const int maxRetryAttempts = AppConstants.maxRetryAttempts;
  
  /// 重试间隔（秒）
  static const List<int> retryIntervals = [5, 15, 30, 60, 300]; // 5秒, 15秒, 30秒, 1分钟, 5分钟
  
  /// 单例模式
  NetworkStatusService._internal();
  
  factory NetworkStatusService() {
    _instance ??= NetworkStatusService._internal();
    return _instance!;
  }
  
  /// 网络状态流
  Stream<NetworkStatus> get statusStream => _statusController.stream;
  
  /// 网络类型流
  Stream<NetworkType> get typeStream => _typeController.stream;
  
  /// 当前网络状态
  NetworkStatus get currentStatus => _currentStatus;
  
  /// 当前网络类型
  NetworkType get currentType => _currentType;
  
  /// 是否已连接
  bool get isConnected => _currentStatus == NetworkStatus.connected;
  
  /// 是否为移动网络
  bool get isMobileNetwork => _currentType == NetworkType.mobile;
  
  /// 是否为WiFi网络
  bool get isWifiNetwork => _currentType == NetworkType.wifi;
  
  /// 添加监听器
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  /// 移除监听器
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
  
  /// 通知所有监听器
  void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        print('监听器通知失败: $e');
      }
    }
  }
  
  /// 初始化网络状态服务
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 检查初始网络状态
      await _checkInitialNetworkStatus();
      
      // 监听网络状态变化
      _startNetworkMonitoring();
      
      // 启动定期连接检查
      _startConnectionCheck();
      
      // 启动离线队列处理
      _startOfflineQueueProcessing();
      
      _isInitialized = true;
      print('网络状态服务初始化完成');
      
    } catch (e) {
      print('网络状态服务初始化失败: $e');
      rethrow;
    }
  }
  
  /// 检查初始网络状态
  Future<void> _checkInitialNetworkStatus() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      await _updateNetworkStatus(connectivityResult);
      
      // 验证实际网络连接
      if (_currentType != NetworkType.none) {
        final isReachable = await _checkInternetReachability();
        if (!isReachable) {
          _updateStatus(NetworkStatus.disconnected);
        }
      }
      
    } catch (e) {
      print('检查初始网络状态失败: $e');
      _updateStatus(NetworkStatus.disconnected);
      _updateType(NetworkType.none);
    }
  }
  
  /// 开始网络监控
  void _startNetworkMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        await _updateNetworkStatus(result);
        
        // 网络状态变化时，尝试处理离线队列
        if (_currentStatus == NetworkStatus.connected) {
          _processOfflineQueue();
        }
      },
      onError: (error) {
        print('网络监控错误: $error');
        _updateStatus(NetworkStatus.disconnected);
      },
    );
  }
  
  /// 更新网络状态
  Future<void> _updateNetworkStatus(ConnectivityResult result) async {
    final previousStatus = _currentStatus;
    final previousType = _currentType;
    
    // 更新网络类型
    _updateType(_mapConnectivityResult(result));
    
    // 更新网络状态
    if (_currentType == NetworkType.none) {
      _updateStatus(NetworkStatus.disconnected);
    } else {
      _updateStatus(NetworkStatus.connecting);
      
      // 验证实际连接
      final isReachable = await _checkInternetReachability();
      if (isReachable) {
        _updateStatus(NetworkStatus.connected);
        _consecutiveFailures = 0;
        _lastSuccessfulConnection = DateTime.now();
      } else {
        _updateStatus(NetworkStatus.disconnected);
        _consecutiveFailures++;
      }
    }
    
    // 记录状态变化
    if (previousStatus != _currentStatus || previousType != _currentType) {
      await _logNetworkStatusChange(previousStatus, _currentStatus, previousType, _currentType);
    }
  }
  
  /// 映射连接结果到网络类型
  NetworkType _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return NetworkType.wifi;
      case ConnectivityResult.mobile:
        return NetworkType.mobile;
      case ConnectivityResult.ethernet:
        return NetworkType.ethernet;
      case ConnectivityResult.bluetooth:
        return NetworkType.bluetooth;
      case ConnectivityResult.vpn:
        return NetworkType.vpn;
      case ConnectivityResult.other:
        return NetworkType.other;
      case ConnectivityResult.none:
      default:
        return NetworkType.none;
    }
  }
  
  /// 更新网络状态
  void _updateStatus(NetworkStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
      _notifyListeners(); // 通知监听器
      print('网络状态更新: $status');
    }
  }
  
  /// 更新网络类型
  void _updateType(NetworkType type) {
    if (_currentType != type) {
      _currentType = type;
      _typeController.add(type);
      _notifyListeners(); // 通知监听器
      print('网络类型更新: $type');
    }
  }
  
  /// 检查互联网可达性
  Future<bool> _checkInternetReachability() async {
    try {
      // 尝试连接多个可靠的服务器
      final hosts = [
        'www.google.com',
        'www.baidu.com',
        '8.8.8.8',
        '114.114.114.114',
      ];
      
      for (final host in hosts) {
        try {
          final result = await InternetAddress.lookup(host).timeout(
            const Duration(seconds: 5),
          );
          
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            return true;
          }
        } catch (e) {
          // 继续尝试下一个主机
          continue;
        }
      }
      
      return false;
      
    } catch (e) {
      print('检查网络可达性失败: $e');
      return false;
    }
  }
  
  /// 开始定期连接检查
  void _startConnectionCheck() {
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_currentType != NetworkType.none) {
        final isReachable = await _checkInternetReachability();
        
        if (isReachable && _currentStatus != NetworkStatus.connected) {
          _updateStatus(NetworkStatus.connected);
          _consecutiveFailures = 0;
          _lastSuccessfulConnection = DateTime.now();
          
          // 网络恢复时处理离线队列
          _processOfflineQueue();
          
        } else if (!isReachable && _currentStatus == NetworkStatus.connected) {
          _updateStatus(NetworkStatus.unstable);
          _consecutiveFailures++;
          
          // 连续失败多次后标记为断开
          if (_consecutiveFailures >= 3) {
            _updateStatus(NetworkStatus.disconnected);
          }
        }
      }
    });
  }
  
  /// 添加到离线队列
  Future<void> addToOfflineQueue(OfflineQueueItem item) async {
    try {
      final db = await _dbHelper.database;
      
      await db.insert(
        'offline_queue',
        {
          'id': item.id,
          'operation_type': item.operationType.toString(),
          'table_name': item.tableName,
          'record_id': item.recordId,
          'data': item.data.toString(), // 这里应该使用JSON编码
          'created_at': item.createdAt.millisecondsSinceEpoch,
          'retry_count': item.retryCount,
          'last_retry_at': item.lastRetryAt?.millisecondsSinceEpoch,
          'error_message': item.errorMessage,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('操作已添加到离线队列: ${item.id}');
      
    } catch (e) {
      print('添加到离线队列失败: $e');
      rethrow;
    }
  }
  
  /// 开始离线队列处理
  void _startOfflineQueueProcessing() {
    _retryTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_currentStatus == NetworkStatus.connected) {
        _processOfflineQueue();
      }
    });
  }
  
  /// 处理离线队列
  Future<void> _processOfflineQueue() async {
    if (_currentStatus != NetworkStatus.connected) {
      return;
    }
    
    try {
      final db = await _dbHelper.database;
      
      // 获取待处理的离线操作
      final queueItems = await db.query(
        'offline_queue',
        orderBy: 'created_at ASC',
        limit: 50, // 批量处理，避免一次性处理太多
      );
      
      if (queueItems.isEmpty) {
        return;
      }
      
      print('开始处理 ${queueItems.length} 个离线操作');
      
      for (final itemData in queueItems) {
        try {
          final item = OfflineQueueItem.fromJson(itemData);
          
          // 检查是否超过最大重试次数
          if (item.retryCount >= maxRetryAttempts) {
            await _removeFromOfflineQueue(item.id);
            print('操作超过最大重试次数，已移除: ${item.id}');
            continue;
          }
          
          // 执行离线操作
          final success = await _executeOfflineOperation(item);
          
          if (success) {
            await _removeFromOfflineQueue(item.id);
            print('离线操作执行成功: ${item.id}');
          } else {
            await _updateOfflineQueueItem(item);
            print('离线操作执行失败，将重试: ${item.id}');
          }
          
        } catch (e) {
          print('处理离线操作失败: $e');
        }
      }
      
    } catch (e) {
      print('处理离线队列失败: $e');
    }
  }
  
  /// 执行离线操作
  Future<bool> _executeOfflineOperation(OfflineQueueItem item) async {
    try {
      // 这里应该根据操作类型执行相应的远程操作
      // 暂时模拟执行成功
      
      switch (item.operationType) {
        case OfflineOperationType.create:
          // 执行创建操作
          break;
        case OfflineOperationType.update:
          // 执行更新操作
          break;
        case OfflineOperationType.delete:
          // 执行删除操作
          break;
        case OfflineOperationType.sync:
          // 执行同步操作
          break;
      }
      
      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 100));
      
      return true;
      
    } catch (e) {
      print('执行离线操作失败: $e');
      return false;
    }
  }
  
  /// 更新离线队列项
  Future<void> _updateOfflineQueueItem(OfflineQueueItem item) async {
    try {
      final db = await _dbHelper.database;
      
      final retryCount = item.retryCount + 1;
      final now = DateTime.now();
      
      await db.update(
        'offline_queue',
        {
          'retry_count': retryCount,
          'last_retry_at': now.millisecondsSinceEpoch,
          'error_message': '重试第 $retryCount 次',
        },
        where: 'id = ?',
        whereArgs: [item.id],
      );
      
    } catch (e) {
      print('更新离线队列项失败: $e');
    }
  }
  
  /// 从离线队列移除
  Future<void> _removeFromOfflineQueue(String itemId) async {
    try {
      final db = await _dbHelper.database;
      
      await db.delete(
        'offline_queue',
        where: 'id = ?',
        whereArgs: [itemId],
      );
      
    } catch (e) {
      print('从离线队列移除失败: $e');
    }
  }
  
  /// 记录网络状态变化
  Future<void> _logNetworkStatusChange(
    NetworkStatus previousStatus,
    NetworkStatus currentStatus,
    NetworkType previousType,
    NetworkType currentType,
  ) async {
    try {
      final db = await _dbHelper.database;
      
      await db.insert(
        'user_settings',
        {
          'key': 'network_status_log_${DateTime.now().millisecondsSinceEpoch}',
          'value': 'Status: $previousStatus -> $currentStatus, Type: $previousType -> $currentType',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
    } catch (e) {
      print('记录网络状态变化失败: $e');
    }
  }
  
  /// 获取网络统计信息
  Future<Map<String, dynamic>> getNetworkStatistics() async {
    try {
      final db = await _dbHelper.database;
      
      // 获取离线队列统计
      final queueResult = await db.rawQuery('SELECT COUNT(*) as count FROM offline_queue');
      final queueCount = queueResult.first['count'] as int;
      
      // 获取失败次数统计
      final failedResult = await db.rawQuery('SELECT COUNT(*) as count FROM offline_queue WHERE retry_count >= ?', [maxRetryAttempts]);
      final failedCount = failedResult.first['count'] as int;
      
      return {
        'current_status': _currentStatus.toString(),
        'current_type': _currentType.toString(),
        'consecutive_failures': _consecutiveFailures,
        'last_successful_connection': _lastSuccessfulConnection?.toIso8601String(),
        'offline_queue_count': queueCount,
        'failed_operations_count': failedCount,
        'is_connected': isConnected,
        'is_mobile_network': isMobileNetwork,
        'is_wifi_network': isWifiNetwork,
      };
      
    } catch (e) {
      print('获取网络统计信息失败: $e');
      return {
        'current_status': _currentStatus.toString(),
        'current_type': _currentType.toString(),
        'error': e.toString(),
      };
    }
  }
  
  /// 清理离线队列
  Future<int> cleanupOfflineQueue({Duration? olderThan}) async {
    try {
      final db = await _dbHelper.database;
      
      String whereClause = '1=1';
      final whereArgs = <dynamic>[];
      
      if (olderThan != null) {
        final cutoffTime = DateTime.now().subtract(olderThan).millisecondsSinceEpoch;
        whereClause = 'created_at < ?';
        whereArgs.add(cutoffTime);
      }
      
      final deletedCount = await db.delete(
        'offline_queue',
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      );
      
      print('清理了 $deletedCount 个离线队列项');
      return deletedCount;
      
    } catch (e) {
      print('清理离线队列失败: $e');
      return 0;
    }
  }
  
  /// 强制重新检查网络状态
  Future<void> forceNetworkCheck() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      await _updateNetworkStatus(connectivityResult);
      
      print('强制网络检查完成');
      
    } catch (e) {
      print('强制网络检查失败: $e');
    }
  }
  
  /// 测试网络连接
  Future<Map<String, dynamic>> testNetworkConnection() async {
    final startTime = DateTime.now();
    
    try {
      // 测试DNS解析
      final dnsStart = DateTime.now();
      final dnsResult = await InternetAddress.lookup('www.google.com').timeout(
        const Duration(seconds: 5),
      );
      final dnsTime = DateTime.now().difference(dnsStart).inMilliseconds;
      
      // 测试HTTP连接
      final httpStart = DateTime.now();
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      final request = await client.getUrl(Uri.parse('https://www.google.com'));
      final response = await request.close().timeout(const Duration(seconds: 10));
      final httpTime = DateTime.now().difference(httpStart).inMilliseconds;
      
      client.close();
      
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      
      return {
        'success': true,
        'dns_resolution_time': dnsTime,
        'http_response_time': httpTime,
        'total_time': totalTime,
        'dns_addresses': dnsResult.map((addr) => addr.address).toList(),
        'http_status_code': response.statusCode,
        'test_time': startTime.toIso8601String(),
      };
      
    } catch (e) {
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      
      return {
        'success': false,
        'error': e.toString(),
        'total_time': totalTime,
        'test_time': startTime.toIso8601String(),
      };
    }
  }
  
  /// 释放资源
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionCheckTimer?.cancel();
    _retryTimer?.cancel();
    _statusController.close();
    _typeController.close();
    _isInitialized = false;
    print('网络状态服务已释放');
  }
}