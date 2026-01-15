import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/network_status_service.dart';
import '../../services/offline_storage_optimizer.dart';

/// 网络状态指示器组件
/// 
/// 显示当前网络连接状态、离线模式状态和同步状态
class NetworkStatusIndicator extends StatefulWidget {
  final bool showDetails; // 是否显示详细信息
  final bool compact; // 是否使用紧凑模式
  final VoidCallback? onTap; // 点击回调
  
  const NetworkStatusIndicator({
    Key? key,
    this.showDetails = false,
    this.compact = false,
    this.onTap,
  }) : super(key: key);
  
  @override
  State<NetworkStatusIndicator> createState() => _NetworkStatusIndicatorState();
}

class _NetworkStatusIndicatorState extends State<NetworkStatusIndicator>
    with SingleTickerProviderStateMixin {
  final NetworkStatusService _networkService = NetworkStatusService();
  final OfflineStorageOptimizer _storageOptimizer = OfflineStorageOptimizer();
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  StreamSubscription<NetworkStatus>? _networkStatusSubscription;
  StreamSubscription<OfflineStorageStatistics>? _storageStatsSubscription;
  
  NetworkStatus _currentNetworkStatus = NetworkStatus.disconnected;
  NetworkType _currentNetworkType = NetworkType.none;
  OfflineStorageStatistics? _storageStats;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化动画
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      // 初始化网络状态服务
      await _networkService.initialize();
      
      // 初始化存储优化器
      await _storageOptimizer.initialize();
      
      // 获取当前状态
      _currentNetworkStatus = _networkService.currentStatus;
      _currentNetworkType = _networkService.currentType;
      
      // 监听网络状态变化
      _networkStatusSubscription = _networkService.statusStream.listen((status) {
        if (mounted) {
          setState(() {
            _currentNetworkStatus = status;
          });
          
          // 根据状态控制动画
          if (status == NetworkStatus.connecting) {
            _animationController.repeat(reverse: true);
          } else {
            _animationController.stop();
            _animationController.reset();
          }
        }
      });
      
      // 监听网络类型变化
      _networkService.typeStream.listen((type) {
        if (mounted) {
          setState(() {
            _currentNetworkType = type;
          });
        }
      });
      
      // 监听存储统计变化
      _storageStatsSubscription = _storageOptimizer.statisticsStream.listen((stats) {
        if (mounted) {
          setState(() {
            _storageStats = stats;
          });
        }
      });
      
    } catch (e) {
      print('初始化网络状态指示器失败: $e');
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _networkStatusSubscription?.cancel();
    _storageStatsSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactIndicator();
    } else {
      return _buildFullIndicator();
    }
  }
  
  /// 构建紧凑指示器
  Widget _buildCompactIndicator() {
    return GestureDetector(
      onTap: widget.onTap ?? _showNetworkStatusDialog,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _currentNetworkStatus == NetworkStatus.connecting 
                ? _pulseAnimation.value 
                : 1.0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor(),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// 构建完整指示器
  Widget _buildFullIndicator() {
    return GestureDetector(
      onTap: widget.onTap ?? _showNetworkStatusDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _currentNetworkStatus == NetworkStatus.connecting 
                      ? _pulseAnimation.value 
                      : 1.0,
                  child: Icon(
                    _getStatusIcon(),
                    size: 16,
                    color: _getStatusColor(),
                  ),
                );
              },
            ),
            if (widget.showDetails) ...[
              const SizedBox(width: 6),
              Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 获取状态颜色
  Color _getStatusColor() {
    switch (_currentNetworkStatus) {
      case NetworkStatus.connected:
        return Colors.green;
      case NetworkStatus.connecting:
        return Colors.orange;
      case NetworkStatus.unstable:
        return Colors.yellow;
      case NetworkStatus.disconnected:
        return Colors.red;
    }
  }
  
  /// 获取状态图标
  IconData _getStatusIcon() {
    if (_currentNetworkStatus == NetworkStatus.disconnected) {
      return Icons.cloud_off;
    }
    
    switch (_currentNetworkType) {
      case NetworkType.wifi:
        return Icons.wifi;
      case NetworkType.mobile:
        return Icons.signal_cellular_4_bar;
      case NetworkType.ethernet:
        return Icons.settings_ethernet;
      case NetworkType.bluetooth:
        return Icons.bluetooth;
      case NetworkType.vpn:
        return Icons.vpn_lock;
      case NetworkType.other:
        return Icons.device_hub;
      case NetworkType.none:
      default:
        return Icons.cloud_off;
    }
  }
  
  /// 获取状态文本
  String _getStatusText() {
    switch (_currentNetworkStatus) {
      case NetworkStatus.connected:
        return _getNetworkTypeText();
      case NetworkStatus.connecting:
        return '连接中';
      case NetworkStatus.unstable:
        return '连接不稳定';
      case NetworkStatus.disconnected:
        return '离线模式';
    }
  }
  
  /// 获取网络类型文本
  String _getNetworkTypeText() {
    switch (_currentNetworkType) {
      case NetworkType.wifi:
        return 'WiFi';
      case NetworkType.mobile:
        return '移动网络';
      case NetworkType.ethernet:
        return '以太网';
      case NetworkType.bluetooth:
        return '蓝牙';
      case NetworkType.vpn:
        return 'VPN';
      case NetworkType.other:
        return '其他网络';
      case NetworkType.none:
      default:
        return '无网络';
    }
  }
  
  /// 显示网络状态详情对话框
  void _showNetworkStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => NetworkStatusDialog(
        networkStatus: _currentNetworkStatus,
        networkType: _currentNetworkType,
        storageStats: _storageStats,
      ),
    );
  }
}

/// 网络状态详情对话框
class NetworkStatusDialog extends StatefulWidget {
  final NetworkStatus networkStatus;
  final NetworkType networkType;
  final OfflineStorageStatistics? storageStats;
  
  const NetworkStatusDialog({
    Key? key,
    required this.networkStatus,
    required this.networkType,
    this.storageStats,
  }) : super(key: key);
  
  @override
  State<NetworkStatusDialog> createState() => _NetworkStatusDialogState();
}

class _NetworkStatusDialogState extends State<NetworkStatusDialog> {
  final NetworkStatusService _networkService = NetworkStatusService();
  final OfflineStorageOptimizer _storageOptimizer = OfflineStorageOptimizer();
  
  bool _isTestingConnection = false;
  Map<String, dynamic>? _connectionTestResult;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.network_check, size: 24),
          SizedBox(width: 8),
          Text('网络状态'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNetworkStatusSection(),
            const SizedBox(height: 16),
            _buildOfflineQueueSection(),
            const SizedBox(height: 16),
            _buildStorageSection(),
            const SizedBox(height: 16),
            _buildConnectionTestSection(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        ElevatedButton(
          onPressed: _forceNetworkCheck,
          child: const Text('刷新状态'),
        ),
      ],
    );
  }
  
  /// 构建网络状态部分
  Widget _buildNetworkStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '网络连接',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_getStatusDescription()),
                ),
              ],
            ),
            if (widget.networkStatus == NetworkStatus.connected) ...[
              const SizedBox(height: 8),
              Text(
                '网络类型: ${_getNetworkTypeText()}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 构建离线队列部分
  Widget _buildOfflineQueueSection() {
    if (widget.storageStats == null) {
      return const SizedBox.shrink();
    }
    
    final stats = widget.storageStats!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '离线队列',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQueueStatItem('待处理', stats.pendingItems, Colors.orange),
                _buildQueueStatItem('已完成', stats.completedItems, Colors.green),
                _buildQueueStatItem('失败', stats.failedItems, Colors.red),
              ],
            ),
            if (stats.pendingItems > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: stats.totalQueueItems > 0 
                    ? stats.completedItems / stats.totalQueueItems 
                    : 0.0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  stats.failedItems > 0 ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '同步进度: ${stats.completedItems}/${stats.totalQueueItems}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 构建队列统计项
  Widget _buildQueueStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
  
  /// 构建存储部分
  Widget _buildStorageSection() {
    if (widget.storageStats == null) {
      return const SizedBox.shrink();
    }
    
    final stats = widget.storageStats!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '本地存储',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: stats.storageUsagePercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      stats.storageUsagePercentage > 75 
                          ? Colors.red 
                          : stats.storageUsagePercentage > 50 
                              ? Colors.orange 
                              : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${stats.storageUsagePercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '已使用: ${stats.storageUsage.toStringAsFixed(1)} MB / ${stats.availableStorage.toStringAsFixed(1)} MB',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (stats.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...stats.warnings.map((warning) => Row(
                children: [
                  const Icon(Icons.warning, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              )),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 构建连接测试部分
  Widget _buildConnectionTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '连接测试',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _isTestingConnection ? null : _testConnection,
                  child: _isTestingConnection 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('测试'),
                ),
              ],
            ),
            if (_connectionTestResult != null) ...[
              const SizedBox(height: 8),
              _buildTestResult(),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 构建测试结果
  Widget _buildTestResult() {
    final result = _connectionTestResult!;
    final success = result['success'] as bool;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              success ? '连接正常' : '连接失败',
              style: TextStyle(
                color: success ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (success) ...[
          Text(
            'DNS解析: ${result['dns_resolution_time']}ms',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            'HTTP响应: ${result['http_response_time']}ms',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ] else ...[
          Text(
            '错误: ${result['error']}',
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
        ],
      ],
    );
  }
  
  /// 获取状态图标
  IconData _getStatusIcon() {
    switch (widget.networkStatus) {
      case NetworkStatus.connected:
        return Icons.check_circle;
      case NetworkStatus.connecting:
        return Icons.sync;
      case NetworkStatus.unstable:
        return Icons.warning;
      case NetworkStatus.disconnected:
        return Icons.cloud_off;
    }
  }
  
  /// 获取状态颜色
  Color _getStatusColor() {
    switch (widget.networkStatus) {
      case NetworkStatus.connected:
        return Colors.green;
      case NetworkStatus.connecting:
        return Colors.orange;
      case NetworkStatus.unstable:
        return Colors.yellow;
      case NetworkStatus.disconnected:
        return Colors.red;
    }
  }
  
  /// 获取状态描述
  String _getStatusDescription() {
    switch (widget.networkStatus) {
      case NetworkStatus.connected:
        return '网络连接正常，所有功能可用';
      case NetworkStatus.connecting:
        return '正在连接网络...';
      case NetworkStatus.unstable:
        return '网络连接不稳定，部分功能可能受限';
      case NetworkStatus.disconnected:
        return '网络连接断开，使用离线模式';
    }
  }
  
  /// 获取网络类型文本
  String _getNetworkTypeText() {
    switch (widget.networkType) {
      case NetworkType.wifi:
        return 'WiFi';
      case NetworkType.mobile:
        return '移动网络';
      case NetworkType.ethernet:
        return '以太网';
      case NetworkType.bluetooth:
        return '蓝牙';
      case NetworkType.vpn:
        return 'VPN';
      case NetworkType.other:
        return '其他网络';
      case NetworkType.none:
      default:
        return '无网络';
    }
  }
  
  /// 强制网络检查
  Future<void> _forceNetworkCheck() async {
    try {
      await _networkService.forceNetworkCheck();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络状态已刷新')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刷新失败: $e')),
        );
      }
    }
  }
  
  /// 测试网络连接
  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
    });
    
    try {
      final result = await _networkService.testNetworkConnection();
      
      if (mounted) {
        setState(() {
          _connectionTestResult = result;
          _isTestingConnection = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionTestResult = {
            'success': false,
            'error': e.toString(),
          };
          _isTestingConnection = false;
        });
      }
    }
  }
}