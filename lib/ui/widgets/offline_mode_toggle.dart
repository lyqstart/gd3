import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/network_status_service.dart';
import '../../services/offline_storage_optimizer.dart';

/// 离线模式切换组件
/// 
/// 允许用户手动切换离线模式，显示离线功能状态
class OfflineModeToggle extends StatefulWidget {
  final bool showLabel; // 是否显示标签
  final VoidCallback? onModeChanged; // 模式变化回调
  
  const OfflineModeToggle({
    Key? key,
    this.showLabel = true,
    this.onModeChanged,
  }) : super(key: key);
  
  @override
  State<OfflineModeToggle> createState() => _OfflineModeToggleState();
}

class _OfflineModeToggleState extends State<OfflineModeToggle> {
  final NetworkStatusService _networkService = NetworkStatusService();
  final OfflineStorageOptimizer _storageOptimizer = OfflineStorageOptimizer();
  
  StreamSubscription<NetworkStatus>? _networkStatusSubscription;
  StreamSubscription<OfflineStorageStatistics>? _storageStatsSubscription;
  
  bool _isOfflineMode = false;
  bool _isForceOffline = false; // 用户强制离线模式
  NetworkStatus _networkStatus = NetworkStatus.disconnected;
  OfflineStorageStatistics? _storageStats;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      // 初始化服务
      await _networkService.initialize();
      await _storageOptimizer.initialize();
      
      // 获取当前状态
      _networkStatus = _networkService.currentStatus;
      _updateOfflineMode();
      
      // 监听网络状态变化
      _networkStatusSubscription = _networkService.statusStream.listen((status) {
        if (mounted) {
          setState(() {
            _networkStatus = status;
            _updateOfflineMode();
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
      
      // 加载用户偏好设置
      await _loadOfflinePreference();
      
    } catch (e) {
      print('初始化离线模式切换组件失败: $e');
    }
  }
  
  /// 更新离线模式状态
  void _updateOfflineMode() {
    final wasOffline = _isOfflineMode;
    
    // 如果用户强制离线模式，或者网络断开，则进入离线模式
    _isOfflineMode = _isForceOffline || _networkStatus == NetworkStatus.disconnected;
    
    if (wasOffline != _isOfflineMode && widget.onModeChanged != null) {
      widget.onModeChanged!();
    }
  }
  
  /// 加载离线偏好设置
  Future<void> _loadOfflinePreference() async {
    // 这里可以从SharedPreferences或数据库加载用户的离线模式偏好
    // 暂时使用默认值
    setState(() {
      _isForceOffline = false;
      _updateOfflineMode();
    });
  }
  
  /// 保存离线偏好设置
  Future<void> _saveOfflinePreference(bool forceOffline) async {
    // 这里可以保存到SharedPreferences或数据库
    // 暂时只更新内存状态
    setState(() {
      _isForceOffline = forceOffline;
      _updateOfflineMode();
    });
  }
  
  @override
  void dispose() {
    _networkStatusSubscription?.cancel();
    _storageStatsSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showOfflineModeDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isOfflineMode 
              ? Colors.orange.withOpacity(0.1)
              : Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isOfflineMode ? Colors.orange : Colors.green,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isOfflineMode ? Icons.cloud_off : Icons.cloud_done,
              size: 16,
              color: _isOfflineMode ? Colors.orange : Colors.green,
            ),
            if (widget.showLabel) ...[
              const SizedBox(width: 6),
              Text(
                _isOfflineMode ? '离线模式' : '在线模式',
                style: TextStyle(
                  fontSize: 12,
                  color: _isOfflineMode ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (_storageStats != null && _storageStats!.pendingItems > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_storageStats!.pendingItems}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 显示离线模式对话框
  void _showOfflineModeDialog() {
    showDialog(
      context: context,
      builder: (context) => OfflineModeDialog(
        isOfflineMode: _isOfflineMode,
        isForceOffline: _isForceOffline,
        networkStatus: _networkStatus,
        storageStats: _storageStats,
        onModeChanged: (forceOffline) async {
          await _saveOfflinePreference(forceOffline);
        },
      ),
    );
  }
}

/// 离线模式对话框
class OfflineModeDialog extends StatefulWidget {
  final bool isOfflineMode;
  final bool isForceOffline;
  final NetworkStatus networkStatus;
  final OfflineStorageStatistics? storageStats;
  final Function(bool) onModeChanged;
  
  const OfflineModeDialog({
    Key? key,
    required this.isOfflineMode,
    required this.isForceOffline,
    required this.networkStatus,
    this.storageStats,
    required this.onModeChanged,
  }) : super(key: key);
  
  @override
  State<OfflineModeDialog> createState() => _OfflineModeDialogState();
}

class _OfflineModeDialogState extends State<OfflineModeDialog> {
  final OfflineStorageOptimizer _storageOptimizer = OfflineStorageOptimizer();
  
  bool _forceOffline = false;
  bool _isProcessingQueue = false;
  
  @override
  void initState() {
    super.initState();
    _forceOffline = widget.isForceOffline;
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cloud_off, size: 24),
          SizedBox(width: 8),
          Text('离线模式设置'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentStatusSection(),
            const SizedBox(height: 16),
            _buildOfflineModeToggle(),
            const SizedBox(height: 16),
            _buildOfflineFeaturesSection(),
            if (widget.storageStats != null) ...[
              const SizedBox(height: 16),
              _buildSyncStatusSection(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: const Text('保存'),
        ),
      ],
    );
  }
  
  /// 构建当前状态部分
  Widget _buildCurrentStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '当前状态',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  widget.isOfflineMode ? Icons.cloud_off : Icons.cloud_done,
                  color: widget.isOfflineMode ? Colors.orange : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isOfflineMode ? '当前处于离线模式' : '当前处于在线模式',
                    style: TextStyle(
                      color: widget.isOfflineMode ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _getStatusDescription(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建离线模式切换
  Widget _buildOfflineModeToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '离线模式设置',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('强制离线模式'),
              subtitle: const Text('即使有网络连接也使用离线模式'),
              value: _forceOffline,
              onChanged: widget.networkStatus == NetworkStatus.disconnected 
                  ? null // 网络断开时不允许切换
                  : (value) {
                      setState(() {
                        _forceOffline = value;
                      });
                    },
              contentPadding: EdgeInsets.zero,
            ),
            if (widget.networkStatus == NetworkStatus.disconnected)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '网络连接断开，自动进入离线模式',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// 构建离线功能部分
  Widget _buildOfflineFeaturesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '离线功能',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem(
              Icons.calculate,
              '计算功能',
              '所有计算模块完全可用',
              true,
            ),
            _buildFeatureItem(
              Icons.save,
              '数据保存',
              '计算记录和参数组本地保存',
              true,
            ),
            _buildFeatureItem(
              Icons.history,
              '历史记录',
              '查看和管理本地历史记录',
              true,
            ),
            _buildFeatureItem(
              Icons.file_download,
              '导出功能',
              'PDF和Excel导出功能',
              true,
            ),
            _buildFeatureItem(
              Icons.sync,
              '数据同步',
              '网络恢复后自动同步',
              false,
            ),
            _buildFeatureItem(
              Icons.cloud_upload,
              '云端备份',
              '需要网络连接',
              false,
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建功能项
  Widget _buildFeatureItem(IconData icon, String title, String description, bool available) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: available ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: available ? null : Colors.grey,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: available ? Colors.grey : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: available ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }
  
  /// 构建同步状态部分
  Widget _buildSyncStatusSection() {
    final stats = widget.storageStats!;
    
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
                  '同步状态',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (stats.pendingItems > 0 && !widget.isOfflineMode)
                  ElevatedButton(
                    onPressed: _isProcessingQueue ? null : _forceProcessQueue,
                    child: _isProcessingQueue
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('立即同步'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (stats.pendingItems > 0) ...[
              Row(
                children: [
                  const Icon(Icons.sync, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '有 ${stats.pendingItems} 项待同步',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: stats.totalQueueItems > 0 
                    ? stats.completedItems / stats.totalQueueItems 
                    : 0.0,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ] else ...[
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    '所有数据已同步',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ],
            if (stats.failedItems > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    '有 ${stats.failedItems} 项同步失败',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 获取状态描述
  String _getStatusDescription() {
    if (widget.networkStatus == NetworkStatus.disconnected) {
      return '网络连接断开，自动使用离线模式';
    } else if (widget.isForceOffline) {
      return '用户设置为强制离线模式';
    } else {
      return '网络连接正常，所有功能可用';
    }
  }
  
  /// 强制处理队列
  Future<void> _forceProcessQueue() async {
    setState(() {
      _isProcessingQueue = true;
    });
    
    try {
      await _storageOptimizer.forceProcessQueue();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同步队列处理完成')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingQueue = false;
        });
      }
    }
  }
  
  /// 保存设置
  void _saveSettings() {
    widget.onModeChanged(_forceOffline);
    Navigator.of(context).pop();
  }
}