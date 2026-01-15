import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/sync_status_manager.dart';
import '../../services/calculation_repository.dart';
import '../../services/offline_storage_optimizer.dart';

/// 同步状态显示组件
/// 
/// 显示数据同步进度、状态和统计信息
class SyncStatusDisplay extends StatefulWidget {
  final bool showProgress; // 是否显示进度条
  final bool compact; // 是否使用紧凑模式
  final VoidCallback? onTap; // 点击回调
  
  const SyncStatusDisplay({
    Key? key,
    this.showProgress = true,
    this.compact = false,
    this.onTap,
  }) : super(key: key);
  
  @override
  State<SyncStatusDisplay> createState() => _SyncStatusDisplayState();
}

class _SyncStatusDisplayState extends State<SyncStatusDisplay>
    with SingleTickerProviderStateMixin {
  final SyncStatusManager _syncManager = SyncStatusManager();
  final CalculationRepository _calcRepository = CalculationRepository();
  final OfflineStorageOptimizer _storageOptimizer = OfflineStorageOptimizer();
  
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  
  StreamSubscription<SyncStatus>? _syncStatusSubscription;
  StreamSubscription<SyncStatistics>? _syncStatsSubscription;
  StreamSubscription<OfflineStorageStatistics>? _storageStatsSubscription;
  
  SyncStatus _currentSyncStatus = SyncStatus.idle;
  SyncStatistics? _lastSyncStats;
  OfflineStorageStatistics? _storageStats;
  Map<String, int> _unsyncedCounts = {};
  
  @override
  void initState() {
    super.initState();
    
    // 初始化动画
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
    
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      // 初始化服务
      await _syncManager.initialize();
      await _calcRepository.initialize();
      await _storageOptimizer.initialize();
      
      // 获取当前状态
      _currentSyncStatus = _syncManager.currentStatus;
      _lastSyncStats = await _syncManager.getLastSyncStatistics();
      _unsyncedCounts = await _syncManager.getUnsyncedCounts();
      
      // 监听同步状态变化
      _syncStatusSubscription = _syncManager.statusStream.listen((status) {
        if (mounted) {
          setState(() {
            _currentSyncStatus = status;
          });
          
          // 根据状态控制动画
          if (status == SyncStatus.syncing) {
            _animationController.repeat();
          } else {
            _animationController.stop();
            _animationController.reset();
          }
        }
      });
      
      // 监听同步统计变化
      _syncStatsSubscription = _syncManager.statisticsStream.listen((stats) {
        if (mounted) {
          setState(() {
            _lastSyncStats = stats;
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
      
      // 定期更新未同步计数
      Timer.periodic(const Duration(minutes: 1), (timer) async {
        if (mounted) {
          final counts = await _syncManager.getUnsyncedCounts();
          setState(() {
            _unsyncedCounts = counts;
          });
        } else {
          timer.cancel();
        }
      });
      
    } catch (e) {
      print('初始化同步状态显示组件失败: $e');
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _syncStatusSubscription?.cancel();
    _syncStatsSubscription?.cancel();
    _storageStatsSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactDisplay();
    } else {
      return _buildFullDisplay();
    }
  }
  
  /// 构建紧凑显示
  Widget _buildCompactDisplay() {
    final totalUnsynced = _unsyncedCounts.values.fold(0, (sum, count) => sum + count);
    
    return GestureDetector(
      onTap: widget.onTap ?? _showSyncStatusDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getSyncStatusColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getSyncStatusColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _currentSyncStatus == SyncStatus.syncing 
                      ? _rotationAnimation.value * 2 * 3.14159 
                      : 0,
                  child: Icon(
                    _getSyncStatusIcon(),
                    size: 14,
                    color: _getSyncStatusColor(),
                  ),
                );
              },
            ),
            if (totalUnsynced > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  totalUnsynced.toString(),
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
  
  /// 构建完整显示
  Widget _buildFullDisplay() {
    return GestureDetector(
      onTap: widget.onTap ?? _showSyncStatusDialog,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSyncStatusHeader(),
              if (widget.showProgress && _lastSyncStats != null) ...[
                const SizedBox(height: 8),
                _buildSyncProgress(),
              ],
              if (_storageStats != null && _storageStats!.pendingItems > 0) ...[
                const SizedBox(height: 8),
                _buildPendingItemsInfo(),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  /// 构建同步状态头部
  Widget _buildSyncStatusHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _currentSyncStatus == SyncStatus.syncing 
                  ? _rotationAnimation.value * 2 * 3.14159 
                  : 0,
              child: Icon(
                _getSyncStatusIcon(),
                size: 20,
                color: _getSyncStatusColor(),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getSyncStatusText(),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _getSyncStatusColor(),
                ),
              ),
              if (_lastSyncStats != null)
                Text(
                  '上次同步: ${_formatLastSyncTime()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
        if (_hasUnsyncedItems())
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_getTotalUnsyncedCount()}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
  
  /// 构建同步进度
  Widget _buildSyncProgress() {
    final stats = _lastSyncStats!;
    
    return Column(
      children: [
        LinearProgressIndicator(
          value: stats.successRate,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            stats.successRate >= 0.9 ? Colors.green : 
            stats.successRate >= 0.7 ? Colors.orange : Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '成功率: ${(stats.successRate * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '${stats.syncedRecords}/${stats.totalRecords}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
  
  /// 构建待处理项信息
  Widget _buildPendingItemsInfo() {
    final stats = _storageStats!;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync, size: 16, color: Colors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '有 ${stats.pendingItems} 项待同步',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _forceSyncNow,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '立即同步',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 获取同步状态颜色
  Color _getSyncStatusColor() {
    switch (_currentSyncStatus) {
      case SyncStatus.idle:
        return _hasUnsyncedItems() ? Colors.orange : Colors.grey;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.failed:
        return Colors.red;
      case SyncStatus.conflict:
        return Colors.purple;
    }
  }
  
  /// 获取同步状态图标
  IconData _getSyncStatusIcon() {
    switch (_currentSyncStatus) {
      case SyncStatus.idle:
        return _hasUnsyncedItems() ? Icons.sync_problem : Icons.sync;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.success:
        return Icons.sync_alt;
      case SyncStatus.failed:
        return Icons.sync_problem;
      case SyncStatus.conflict:
        return Icons.sync_problem;
    }
  }
  
  /// 获取同步状态文本
  String _getSyncStatusText() {
    switch (_currentSyncStatus) {
      case SyncStatus.idle:
        return _hasUnsyncedItems() ? '有数据待同步' : '数据已同步';
      case SyncStatus.syncing:
        return '正在同步...';
      case SyncStatus.success:
        return '同步成功';
      case SyncStatus.failed:
        return '同步失败';
      case SyncStatus.conflict:
        return '同步冲突';
    }
  }
  
  /// 格式化上次同步时间
  String _formatLastSyncTime() {
    if (_lastSyncStats == null) return '从未同步';
    
    final now = DateTime.now();
    final lastSync = _lastSyncStats!.lastSyncTime;
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }
  
  /// 是否有未同步项
  bool _hasUnsyncedItems() {
    return _unsyncedCounts.values.any((count) => count > 0);
  }
  
  /// 获取总未同步数量
  int _getTotalUnsyncedCount() {
    return _unsyncedCounts.values.fold(0, (sum, count) => sum + count);
  }
  
  /// 强制立即同步
  Future<void> _forceSyncNow() async {
    try {
      await _calcRepository.performIncrementalSync();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同步已启动')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步启动失败: $e')),
        );
      }
    }
  }
  
  /// 显示同步状态详情对话框
  void _showSyncStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => SyncStatusDialog(
        syncStatus: _currentSyncStatus,
        syncStats: _lastSyncStats,
        storageStats: _storageStats,
        unsyncedCounts: _unsyncedCounts,
      ),
    );
  }
}

/// 同步状态详情对话框
class SyncStatusDialog extends StatefulWidget {
  final SyncStatus syncStatus;
  final SyncStatistics? syncStats;
  final OfflineStorageStatistics? storageStats;
  final Map<String, int> unsyncedCounts;
  
  const SyncStatusDialog({
    Key? key,
    required this.syncStatus,
    this.syncStats,
    this.storageStats,
    required this.unsyncedCounts,
  }) : super(key: key);
  
  @override
  State<SyncStatusDialog> createState() => _SyncStatusDialogState();
}

class _SyncStatusDialogState extends State<SyncStatusDialog> {
  final CalculationRepository _calcRepository = CalculationRepository();
  final SyncStatusManager _syncManager = SyncStatusManager();
  
  bool _isSyncing = false;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.sync, size: 24),
          SizedBox(width: 8),
          Text('同步状态'),
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
            _buildUnsyncedDataSection(),
            if (widget.syncStats != null) ...[
              const SizedBox(height: 16),
              _buildLastSyncSection(),
            ],
            if (widget.storageStats != null) ...[
              const SizedBox(height: 16),
              _buildStorageQueueSection(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        if (_hasUnsyncedData())
          ElevatedButton(
            onPressed: _isSyncing ? null : _performFullSync,
            child: _isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('立即同步'),
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
                  _getSyncStatusIcon(),
                  color: _getSyncStatusColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSyncStatusDescription(),
                    style: TextStyle(
                      color: _getSyncStatusColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建未同步数据部分
  Widget _buildUnsyncedDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '待同步数据',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_hasUnsyncedData()) ...[
              ...widget.unsyncedCounts.entries.map((entry) {
                if (entry.value == 0) return const SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_getTableDisplayName(entry.key)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
          ],
        ),
      ),
    );
  }
  
  /// 构建上次同步部分
  Widget _buildLastSyncSection() {
    final stats = widget.syncStats!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '上次同步',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('同步时间'),
                Text(_formatSyncTime(stats.lastSyncTime)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('耗时'),
                Text('${stats.syncDuration.inSeconds}秒'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('成功率'),
                Text(
                  '${(stats.successRate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: stats.successRate >= 0.9 ? Colors.green : 
                           stats.successRate >= 0.7 ? Colors.orange : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: stats.successRate,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                stats.successRate >= 0.9 ? Colors.green : 
                stats.successRate >= 0.7 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '成功: ${stats.syncedRecords}',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
                Text(
                  '失败: ${stats.failedRecords}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
                Text(
                  '冲突: ${stats.conflictRecords}',
                  style: const TextStyle(fontSize: 12, color: Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建存储队列部分
  Widget _buildStorageQueueSection() {
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
            fontSize: 16,
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
  
  /// 获取同步状态图标
  IconData _getSyncStatusIcon() {
    switch (widget.syncStatus) {
      case SyncStatus.idle:
        return Icons.sync;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.success:
        return Icons.check_circle;
      case SyncStatus.failed:
        return Icons.error;
      case SyncStatus.conflict:
        return Icons.warning;
    }
  }
  
  /// 获取同步状态颜色
  Color _getSyncStatusColor() {
    switch (widget.syncStatus) {
      case SyncStatus.idle:
        return Colors.grey;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.failed:
        return Colors.red;
      case SyncStatus.conflict:
        return Colors.purple;
    }
  }
  
  /// 获取同步状态描述
  String _getSyncStatusDescription() {
    switch (widget.syncStatus) {
      case SyncStatus.idle:
        return _hasUnsyncedData() ? '有数据待同步' : '所有数据已同步';
      case SyncStatus.syncing:
        return '正在同步数据...';
      case SyncStatus.success:
        return '数据同步成功';
      case SyncStatus.failed:
        return '数据同步失败';
      case SyncStatus.conflict:
        return '数据同步存在冲突';
    }
  }
  
  /// 获取表显示名称
  String _getTableDisplayName(String tableName) {
    switch (tableName) {
      case 'calculation_records':
        return '计算记录';
      case 'parameter_sets':
        return '参数组';
      default:
        return tableName;
    }
  }
  
  /// 格式化同步时间
  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
  
  /// 是否有未同步数据
  bool _hasUnsyncedData() {
    return widget.unsyncedCounts.values.any((count) => count > 0);
  }
  
  /// 执行完整同步
  Future<void> _performFullSync() async {
    setState(() {
      _isSyncing = true;
    });
    
    try {
      await _calcRepository.performFullSync();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同步完成')),
        );
        Navigator.of(context).pop();
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
          _isSyncing = false;
        });
      }
    }
  }
}