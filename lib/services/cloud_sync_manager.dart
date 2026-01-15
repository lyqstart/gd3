import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/calculation_result.dart';
import '../models/parameter_models.dart';
import 'remote_database_service.dart';
import 'auth_state_manager.dart';
import 'network_status_service.dart';

/// 云端同步管理器
/// 统一管理MySQL的数据同步
class CloudSyncManager extends ChangeNotifier {
  static final CloudSyncManager _instance = CloudSyncManager._internal();
  factory CloudSyncManager() => _instance;
  CloudSyncManager._internal();

  RemoteDatabaseService? _mysqlSync;
  AuthStateManager? _authManager;
  NetworkStatusService? _networkService;

  bool _isInitialized = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastSyncError;
  SyncStatus _syncStatus = SyncStatus.idle;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 是否正在同步
  bool get isSyncing => _isSyncing;

  /// 最后同步时间
  DateTime? get lastSyncTime => _lastSyncTime;

  /// 最后同步错误
  String? get lastSyncError => _lastSyncError;

  /// 同步状态
  SyncStatus get syncStatus => _syncStatus;

  /// 是否可以同步
  bool get canSync => _isInitialized &&
                     _authManager?.isSignedIn == true && 
                     _authManager?.currentUser?.isAnonymous != true &&
                     _networkService?.isConnected == true;

  /// 初始化同步管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 初始化MySQL同步服务
      _mysqlSync = RemoteDatabaseService();
      _authManager = AuthStateManager();
      _networkService = NetworkStatusService();
      
      // 初始化网络状态服务
      await _networkService!.initialize();
      
      // 监听认证状态变化
      _authManager!.addListener(_onAuthStateChanged);
      
      // 监听网络状态变化
      _networkService!.addListener(_onNetworkStateChanged);

      _isInitialized = true;
      _updateSyncStatus(SyncStatus.ready);
      
      print('云端同步管理器初始化完成');
    } catch (e) {
      print('云端同步管理器初始化失败: $e');
      _lastSyncError = '初始化失败: $e';
      _updateSyncStatus(SyncStatus.error);
      // 不抛出异常，允许应用继续运行
    }
  }

  /// 处理认证状态变化
  void _onAuthStateChanged() {
    if (_authManager?.isSignedIn == true && _authManager?.currentUser?.isAnonymous != true) {
      // 用户登录，触发自动同步
      _scheduleAutoSync();
    } else {
      // 用户登出，停止同步
      _updateSyncStatus(SyncStatus.idle);
    }
    notifyListeners();
  }

  /// 处理网络状态变化
  void _onNetworkStateChanged() {
    if (_networkService?.isConnected == true && canSync) {
      // 网络恢复，触发自动同步
      _scheduleAutoSync();
    }
    notifyListeners();
  }

  /// 安排自动同步
  void _scheduleAutoSync() {
    if (!canSync || _isSyncing) return;

    // 延迟执行同步，避免频繁触发
    Timer(const Duration(seconds: 2), () {
      if (canSync && !_isSyncing) {
        performFullSync();
      }
    });
  }

  /// 执行完整同步
  Future<SyncResult> performFullSync() async {
    if (!_isInitialized) {
      return SyncResult(
        success: false,
        message: '云端同步未初始化',
      );
    }

    if (!canSync) {
      return SyncResult(
        success: false,
        message: '无法同步：用户未登录、为匿名用户或网络不可用',
      );
    }

    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: '同步正在进行中，请稍候',
      );
    }

    _setSyncing(true);
    _updateSyncStatus(SyncStatus.syncing);

    try {
      // 1. 从本地数据库获取需要同步的数据
      final localData = await _getLocalDataForSync();

      // 2. 初始化MySQL连接
      await _mysqlSync!.initializeDatabase();

      // 3. 同步所有计算记录到MySQL
      int successCount = 0;
      int failureCount = 0;
      List<String> errors = [];

      for (final calculation in localData.calculations) {
        try {
          await _mysqlSync!.syncCalculationRecord(calculation, await _getDeviceId());
          successCount++;
        } catch (e) {
          failureCount++;
          errors.add('同步记录 ${calculation.id} 失败: $e');
        }
      }

      _lastSyncTime = DateTime.now();
      _lastSyncError = null;
      _updateSyncStatus(SyncStatus.completed);

      final result = SyncResult(
        success: failureCount == 0,
        message: '同步完成 - 成功: $successCount, 失败: $failureCount',
        successCount: successCount,
        failureCount: failureCount,
        errors: errors,
      );

      return result;
    } catch (e) {
      _lastSyncError = e.toString();
      _updateSyncStatus(SyncStatus.error);
      
      return SyncResult(
        success: false,
        message: '同步失败: $e',
      );
    } finally {
      _setSyncing(false);
    }
  }

  /// 同步单个计算记录
  Future<bool> syncCalculationRecord(CalculationResult result) async {
    if (!_isInitialized || !canSync) return false;

    try {
      // 同步到MySQL
      await _mysqlSync!.syncCalculationRecord(result, await _getDeviceId());
      return true;
    } catch (e) {
      print('同步计算记录失败: $e');
      return false;
    }
  }

  /// 同步单个参数组
  Future<bool> syncParameterSet(ParameterSet parameterSet) async {
    if (!_isInitialized || !canSync) return false;

    try {
      // MySQL暂不支持参数组同步
      print('参数组同步功能暂未实现');
      return true;
    } catch (e) {
      print('同步参数组失败: $e');
      return false;
    }
  }

  /// 删除云端计算记录
  Future<bool> deleteCloudCalculationRecord(String recordId) async {
    if (!_isInitialized || !canSync) return false;

    try {
      // MySQL暂不支持删除操作
      print('删除云端记录功能暂未实现');
      return true;
    } catch (e) {
      print('删除云端计算记录失败: $e');
      return false;
    }
  }

  /// 删除云端参数组
  Future<bool> deleteCloudParameterSet(String parameterSetId) async {
    if (!_isInitialized || !canSync) return false;

    try {
      // MySQL暂不支持删除操作
      print('删除云端参数组功能暂未实现');
      return true;
    } catch (e) {
      print('删除云端参数组失败: $e');
      return false;
    }
  }

  /// 获取本地需要同步的数据
  Future<LocalSyncData> _getLocalDataForSync() async {
    // 这里应该从本地数据库获取数据
    // 为了简化，返回空数据
    return LocalSyncData(
      calculations: [],
      parameterSets: [],
    );
  }

  /// 从云端数据更新本地数据库
  Future<void> _updateLocalDataFromCloud(dynamic cloudData) async {
    // 这里应该更新本地数据库
    // 为了简化，暂时跳过
    print('从云端更新本地数据');
  }

  /// 设置同步状态
  void _setSyncing(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

  /// 更新同步状态
  void _updateSyncStatus(SyncStatus status) {
    _syncStatus = status;
    notifyListeners();
  }

  /// 清理用户数据
  Future<bool> clearUserData() async {
    if (!_isInitialized) return false;
    
    try {
      // MySQL暂不支持清理用户数据
      print('清理用户数据功能暂未实现');
      return true;
    } catch (e) {
      print('清理用户数据失败: $e');
      return false;
    }
  }

  /// 获取同步统计信息
  SyncStats getSyncStats() {
    return SyncStats(
      lastSyncTime: _lastSyncTime,
      syncStatus: _syncStatus,
      canSync: canSync,
      isOnline: _networkService?.isConnected ?? false,
      isAuthenticated: _authManager?.isSignedIn == true && _authManager?.currentUser?.isAnonymous != true,
      lastError: _lastSyncError,
    );
  }

  /// 获取设备ID
  Future<String> _getDeviceId() async {
    // 这里应该使用设备唯一标识符
    // 为了简化，暂时使用用户ID或生成随机ID
    return _authManager?.currentUser?.uid ?? 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _authManager?.removeListener(_onAuthStateChanged);
    _networkService?.removeListener(_onNetworkStateChanged);
    super.dispose();
  }
}

/// 同步结果
class SyncResult {
  final bool success;
  final String message;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    this.successCount = 0,
    this.failureCount = 0,
    this.errors = const [],
  });
}

/// 本地同步数据
class LocalSyncData {
  final List<CalculationResult> calculations;
  final List<ParameterSet> parameterSets;

  LocalSyncData({
    required this.calculations,
    required this.parameterSets,
  });
}

/// 同步状态
enum SyncStatus {
  idle,       // 空闲
  ready,      // 准备就绪
  syncing,    // 同步中
  completed,  // 同步完成
  error,      // 同步错误
}

/// 同步统计信息
class SyncStats {
  final DateTime? lastSyncTime;
  final SyncStatus syncStatus;
  final bool canSync;
  final bool isOnline;
  final bool isAuthenticated;
  final String? lastError;

  SyncStats({
    this.lastSyncTime,
    required this.syncStatus,
    required this.canSync,
    required this.isOnline,
    required this.isAuthenticated,
    this.lastError,
  });

  String get statusDisplayName {
    switch (syncStatus) {
      case SyncStatus.idle:
        return '空闲';
      case SyncStatus.ready:
        return '准备就绪';
      case SyncStatus.syncing:
        return '同步中';
      case SyncStatus.completed:
        return '同步完成';
      case SyncStatus.error:
        return '同步错误';
    }
  }
}