import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/data_integrity_service.dart';

/// 数据完整性管理组件
/// 
/// 显示数据备份、恢复和完整性检查功能
class DataIntegrityWidget extends StatefulWidget {
  const DataIntegrityWidget({Key? key}) : super(key: key);
  
  @override
  State<DataIntegrityWidget> createState() => _DataIntegrityWidgetState();
}

class _DataIntegrityWidgetState extends State<DataIntegrityWidget> {
  final DataIntegrityService _integrityService = DataIntegrityService();
  
  bool _isLoading = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _healthStatus;
  List<DataBackup> _backups = [];
  List<IntegrityIssue> _issues = [];
  
  StreamSubscription<IntegrityCheckResult>? _checkResultSubscription;
  StreamSubscription<DataBackup>? _backupSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeService();
  }
  
  @override
  void dispose() {
    _checkResultSubscription?.cancel();
    _backupSubscription?.cancel();
    super.dispose();
  }
  
  /// 初始化数据完整性服务
  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 初始化服务
      await _integrityService.initialize();
      
      // 订阅事件流
      _checkResultSubscription = _integrityService.checkResultStream.listen(
        (result) {
          if (mounted) {
            _handleCheckResult(result);
          }
        },
      );
      
      _backupSubscription = _integrityService.backupStream.listen(
        (backup) {
          if (mounted) {
            _handleNewBackup(backup);
          }
        },
      );
      
      // 加载初始数据
      await _loadData();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isInitialized = false;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('数据完整性服务初始化失败: $e')),
        );
      }
    }
  }
  
  /// 加载数据
  Future<void> _loadData() async {
    try {
      final healthStatus = await _integrityService.getDatabaseHealthStatus();
      final backups = await _integrityService.getBackupList();
      final issues = await _integrityService.getIntegrityIssues(isFixed: false);
      
      if (mounted) {
        setState(() {
          _healthStatus = healthStatus;
          _backups = backups;
          _issues = issues;
        });
      }
    } catch (e) {
      print('加载数据失败: $e');
    }
  }
  
  /// 处理完整性检查结果
  void _handleCheckResult(IntegrityCheckResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.passed 
            ? '完整性检查通过，未发现问题' 
            : '发现 ${result.issues.length} 个问题',
        ),
        backgroundColor: result.passed ? Colors.green : Colors.orange,
      ),
    );
    
    // 刷新数据
    _loadData();
  }
  
  /// 处理新备份
  void _handleNewBackup(DataBackup backup) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('备份创建成功: ${backup.name}'),
        backgroundColor: Colors.green,
      ),
    );
    
    // 刷新备份列表
    _loadData();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    if (!_isInitialized) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              const Text('数据完整性服务初始化失败'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitialized = true;
                  });
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildHealthStatus(),
            const SizedBox(height: 16),
            _buildIssuesSection(),
            const SizedBox(height: 16),
            _buildBackupSection(),
            const SizedBox(height: 16),
            _buildIntegritySection(),
          ],
        ),
      ),
    );
  }
  
  /// 构建头部
  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.security, size: 24),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '数据完整性保护',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: _refreshStatus,
          icon: const Icon(Icons.refresh),
          tooltip: '刷新状态',
        ),
      ],
    );
  }
  
  /// 构建健康状态部分
  Widget _buildHealthStatus() {
    if (_healthStatus == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.grey, size: 20),
            SizedBox(width: 8),
            Text('正在加载健康状态...'),
          ],
        ),
      );
    }
    
    final healthScore = (_healthStatus!['health_score'] as num?)?.toDouble() ?? 0.0;
    final integrityPassed = _healthStatus!['database_integrity'] as bool? ?? false;
    final quickCheckPassed = _healthStatus!['quick_check_passed'] as bool? ?? false;
    final hasBackup = (_healthStatus!['backup_count'] as int? ?? 0) > 0;
    
    final statusColor = healthScore >= 90 
        ? Colors.green 
        : healthScore >= 70 
            ? Colors.orange 
            : Colors.red;
    
    final statusText = healthScore >= 90 
        ? '数据库状态优秀' 
        : healthScore >= 70 
            ? '数据库状态良好' 
            : '数据库需要维护';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                healthScore >= 90 ? Icons.check_circle : Icons.warning,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(statusText)),
              Text(
                '${healthScore.toInt()}分',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: healthScore / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatusItem('完整性', integrityPassed),
              const SizedBox(width: 16),
              _buildStatusItem('快速检查', quickCheckPassed),
              const SizedBox(width: 16),
              _buildStatusItem('备份', hasBackup),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 构建状态项
  Widget _buildStatusItem(String label, bool passed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed ? Icons.check : Icons.close,
          size: 16,
          color: passed ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  
  /// 构建问题部分
  Widget _buildIssuesSection() {
    if (_issues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text('未发现数据完整性问题'),
          ],
        ),
      );
    }
    
    final criticalCount = _issues.where((i) => i.level == IntegrityIssueLevel.critical).length;
    final errorCount = _issues.where((i) => i.level == IntegrityIssueLevel.error).length;
    final warningCount = _issues.where((i) => i.level == IntegrityIssueLevel.warning).length;
    
    final hasSerious = criticalCount > 0 || errorCount > 0;
    final statusColor = hasSerious ? Colors.red : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasSerious ? Icons.error : Icons.warning,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('发现 ${_issues.length} 个数据完整性问题'),
              ),
              TextButton(
                onPressed: _showIssuesList,
                child: const Text('查看详情'),
              ),
            ],
          ),
          if (hasSerious) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (criticalCount > 0) ...[
                  Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text('严重: $criticalCount', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 12),
                ],
                if (errorCount > 0) ...[
                  Icon(Icons.error_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text('错误: $errorCount', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 12),
                ],
                if (warningCount > 0) ...[
                  Icon(Icons.warning, color: Colors.yellow[700], size: 16),
                  const SizedBox(width: 4),
                  Text('警告: $warningCount', style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  /// 构建备份部分
  Widget _buildBackupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '数据备份',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '共 ${_backups.length} 个备份',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _createBackup,
                icon: const Icon(Icons.backup, size: 18),
                label: const Text('创建备份'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showBackupList,
                icon: const Icon(Icons.list, size: 18),
                label: const Text('备份列表'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildLatestBackupInfo(),
      ],
    );
  }
  
  /// 构建最新备份信息
  Widget _buildLatestBackupInfo() {
    if (_backups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, size: 16, color: Colors.orange),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                '暂无备份',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }
    
    final latestBackup = _backups.first;
    final now = DateTime.now();
    final timeDiff = now.difference(latestBackup.createdAt);
    
    String timeAgo;
    if (timeDiff.inDays > 0) {
      timeAgo = '${timeDiff.inDays}天前';
    } else if (timeDiff.inHours > 0) {
      timeAgo = '${timeDiff.inHours}小时前';
    } else if (timeDiff.inMinutes > 0) {
      timeAgo = '${timeDiff.inMinutes}分钟前';
    } else {
      timeAgo = '刚刚';
    }
    
    final fileSizeMB = (latestBackup.fileSize / (1024 * 1024)).toStringAsFixed(1);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            latestBackup.isAutomatic ? Icons.schedule : Icons.backup,
            size: 16,
            color: Colors.blue,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  latestBackup.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${fileSizeMB}MB • $timeAgo',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建完整性检查部分
  Widget _buildIntegritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '完整性检查',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _performIntegrityCheck,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('检查完整性'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _repairDatabase,
                icon: const Icon(Icons.build, size: 18),
                label: const Text('修复数据库'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _autoFixIssues,
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: const Text('自动修复'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _cleanupOldBackups,
                icon: const Icon(Icons.cleaning_services, size: 18),
                label: const Text('清理备份'),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// 创建备份
  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final timestamp = DateTime.now();
      final backupName = '手动备份_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}';
      
      await _integrityService.createBackup(
        name: backupName,
        description: '用户手动创建的数据备份',
        isAutomatic: false,
        triggerReason: 'manual_backup',
      );
      
      // 备份成功会通过流事件处理，这里不需要额外处理
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份创建失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// 刷新状态
  Future<void> _refreshStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('状态刷新完成'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// 显示备份列表
  void _showBackupList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup),
            SizedBox(width: 8),
            Text('数据备份列表'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _backups.isEmpty
              ? const Center(
                  child: Text('暂无备份'),
                )
              : ListView.builder(
                  itemCount: _backups.length,
                  itemBuilder: (context, index) {
                    final backup = _backups[index];
                    final fileSizeMB = (backup.fileSize / (1024 * 1024)).toStringAsFixed(1);
                    
                    final now = DateTime.now();
                    final timeDiff = now.difference(backup.createdAt);
                    String timeAgo;
                    if (timeDiff.inDays > 0) {
                      timeAgo = '${timeDiff.inDays}天前';
                    } else if (timeDiff.inHours > 0) {
                      timeAgo = '${timeDiff.inHours}小时前';
                    } else if (timeDiff.inMinutes > 0) {
                      timeAgo = '${timeDiff.inMinutes}分钟前';
                    } else {
                      timeAgo = '刚刚';
                    }
                    
                    return ListTile(
                      leading: Icon(
                        backup.isAutomatic ? Icons.schedule : Icons.backup,
                        color: backup.isAutomatic ? Colors.blue : Colors.green,
                      ),
                      title: Text(backup.name),
                      subtitle: Text('${fileSizeMB}MB • $timeAgo'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          Navigator.of(context).pop();
                          if (value == 'restore') {
                            _restoreBackup(backup.id);
                          } else if (value == 'delete') {
                            _deleteBackup(backup.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'restore',
                            child: Row(
                              children: [
                                Icon(Icons.restore),
                                SizedBox(width: 8),
                                Text('恢复'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('删除'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
  
  /// 执行完整性检查
  Future<void> _performIntegrityCheck() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 执行多种类型的完整性检查
      await _integrityService.performIntegrityCheck(IntegrityCheckType.structure);
      await _integrityService.performIntegrityCheck(IntegrityCheckType.content);
      await _integrityService.performIntegrityCheck(IntegrityCheckType.consistency);
      await _integrityService.performIntegrityCheck(IntegrityCheckType.corruption);
      
      // 检查结果会通过流事件处理
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('完整性检查失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// 清理旧备份
  Future<void> _cleanupOldBackups() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理旧备份'),
        content: const Text('这将删除超过30天或超过10个的旧备份文件。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _integrityService.cleanupOldBackups(maxBackups: 10, maxDays: 30);
        
        // 刷新备份列表
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('旧备份清理完成'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('清理失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 恢复备份
  Future<void> _restoreBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复备份'),
        content: const Text('恢复备份将覆盖当前数据库，此操作不可撤销。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确定恢复'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _integrityService.restoreBackup(backupId);
        
        // 刷新数据
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('备份恢复成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('恢复失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 删除备份
  Future<void> _deleteBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除备份'),
        content: const Text('确定要删除这个备份吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _integrityService.deleteBackup(backupId);
        
        // 刷新备份列表
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('备份删除成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  /// 修复数据库
  Future<void> _repairDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修复数据库'),
        content: const Text('这将尝试自动修复数据库问题。修复前会自动创建备份。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('开始修复'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final success = await _integrityService.repairDatabase();
        
        // 刷新数据
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? '数据库修复成功' : '数据库修复部分完成，请检查剩余问题'),
              backgroundColor: success ? Colors.green : Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('修复失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 自动修复问题
  Future<void> _autoFixIssues() async {
    if (_issues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有需要修复的问题'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自动修复问题'),
        content: Text('发现 ${_issues.length} 个问题，将尝试自动修复非严重问题。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('开始修复'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final fixedIssues = await _integrityService.autoFixIssues(
          maxLevel: IntegrityIssueLevel.error,
        );
        
        // 刷新数据
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('自动修复完成，共修复 ${fixedIssues.length} 个问题'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('自动修复失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 显示问题列表
  void _showIssuesList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.list),
            SizedBox(width: 8),
            Text('数据完整性问题'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _issues.isEmpty
              ? const Center(child: Text('没有发现问题'))
              : ListView.builder(
                  itemCount: _issues.length,
                  itemBuilder: (context, index) {
                    final issue = _issues[index];
                    
                    Color levelColor;
                    IconData levelIcon;
                    switch (issue.level) {
                      case IntegrityIssueLevel.critical:
                        levelColor = Colors.red;
                        levelIcon = Icons.error;
                        break;
                      case IntegrityIssueLevel.error:
                        levelColor = Colors.orange;
                        levelIcon = Icons.error_outline;
                        break;
                      case IntegrityIssueLevel.warning:
                        levelColor = Colors.yellow[700]!;
                        levelIcon = Icons.warning;
                        break;
                      case IntegrityIssueLevel.info:
                        levelColor = Colors.blue;
                        levelIcon = Icons.info;
                        break;
                    }
                    
                    return Card(
                      child: ListTile(
                        leading: Icon(levelIcon, color: levelColor),
                        title: Text(
                          issue.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('表: ${issue.tableName}'),
                            if (issue.suggestion != null)
                              Text(
                                '建议: ${issue.suggestion}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: issue.isFixed
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          if (_issues.any((i) => !i.isFixed)) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _autoFixIssues();
              },
              child: const Text('自动修复'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}