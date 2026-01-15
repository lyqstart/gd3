import 'package:flutter/material.dart';
import '../../services/safety_warning_system.dart';

/// 安全预警显示组件
class SafetyWarningWidget extends StatelessWidget {
  final List<SafetyWarning> warnings;
  final bool showDetails;
  final VoidCallback? onDismiss;
  final VoidCallback? onShowDetails;

  const SafetyWarningWidget({
    super.key,
    required this.warnings,
    this.showDetails = false,
    this.onDismiss,
    this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    final highestLevel = SafetyWarningSystem().getHighestWarningLevel(warnings);
    final stats = SafetyWarningSystem().getWarningStatistics(warnings);

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4.0,
      color: _getBackgroundColor(highestLevel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          _buildHeader(context, highestLevel, stats),
          
          // 详细信息（可展开）
          if (showDetails) _buildDetailsList(context),
          
          // 操作按钮
          _buildActionButtons(context),
        ],
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context, SafetyWarningLevel? highestLevel, Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: _getHeaderColor(highestLevel),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4.0),
          topRight: Radius.circular(4.0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getHeaderIcon(highestLevel),
            color: Colors.white,
            size: 24.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getHeaderTitle(highestLevel),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  _getStatsText(stats),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onDismiss,
              tooltip: '关闭警告',
            ),
        ],
      ),
    );
  }

  /// 构建详细信息列表
  Widget _buildDetailsList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '详细信息:',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          ...warnings.map((warning) => _buildWarningItem(context, warning)),
        ],
      ),
    );
  }

  /// 构建单个警告项
  Widget _buildWarningItem(BuildContext context, SafetyWarning warning) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.left(
          width: 4.0,
          color: warning.levelColor,
        ),
        color: warning.levelColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                warning.levelIcon,
                color: warning.levelColor,
                size: 16.0,
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  warning.title,
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: warning.levelColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            warning.message,
            style: const TextStyle(fontSize: 13.0),
          ),
          if (warning.recommendation != null) ...[
            const SizedBox(height: 4.0),
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue,
                    size: 14.0,
                  ),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      warning.recommendation!,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onShowDetails != null)
            TextButton.icon(
              onPressed: onShowDetails,
              icon: Icon(showDetails ? Icons.expand_less : Icons.expand_more),
              label: Text(showDetails ? '收起详情' : '查看详情'),
            ),
          const SizedBox(width: 8.0),
          ElevatedButton.icon(
            onPressed: () => _showDetailDialog(context),
            icon: const Icon(Icons.info_outline),
            label: const Text('详细说明'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示详细对话框
  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SafetyWarningDialog(warnings: warnings),
    );
  }

  /// 获取背景颜色
  Color _getBackgroundColor(SafetyWarningLevel? level) {
    if (level == null) return Colors.grey[100]!;
    
    switch (level) {
      case SafetyWarningLevel.info:
        return Colors.blue[50]!;
      case SafetyWarningLevel.warning:
        return Colors.orange[50]!;
      case SafetyWarningLevel.danger:
        return Colors.red[50]!;
      case SafetyWarningLevel.critical:
        return Colors.red[100]!;
    }
  }

  /// 获取标题栏颜色
  Color _getHeaderColor(SafetyWarningLevel? level) {
    if (level == null) return Colors.grey;
    
    switch (level) {
      case SafetyWarningLevel.info:
        return Colors.blue;
      case SafetyWarningLevel.warning:
        return Colors.orange;
      case SafetyWarningLevel.danger:
        return Colors.red;
      case SafetyWarningLevel.critical:
        return Colors.red[900]!;
    }
  }

  /// 获取标题栏图标
  IconData _getHeaderIcon(SafetyWarningLevel? level) {
    if (level == null) return Icons.info_outline;
    
    switch (level) {
      case SafetyWarningLevel.info:
        return Icons.info_outline;
      case SafetyWarningLevel.warning:
        return Icons.warning_amber_outlined;
      case SafetyWarningLevel.danger:
        return Icons.error_outline;
      case SafetyWarningLevel.critical:
        return Icons.dangerous_outlined;
    }
  }

  /// 获取标题文本
  String _getHeaderTitle(SafetyWarningLevel? level) {
    if (level == null) return '安全提示';
    
    switch (level) {
      case SafetyWarningLevel.info:
        return '安全提示';
      case SafetyWarningLevel.warning:
        return '安全警告';
      case SafetyWarningLevel.danger:
        return '安全风险';
      case SafetyWarningLevel.critical:
        return '严重安全风险';
    }
  }

  /// 获取统计文本
  String _getStatsText(Map<String, int> stats) {
    final parts = <String>[];
    
    if ((stats['critical'] ?? 0) > 0) {
      parts.add('严重: ${stats['critical']}');
    }
    if ((stats['danger'] ?? 0) > 0) {
      parts.add('危险: ${stats['danger']}');
    }
    if ((stats['warning'] ?? 0) > 0) {
      parts.add('警告: ${stats['warning']}');
    }
    if ((stats['info'] ?? 0) > 0) {
      parts.add('提示: ${stats['info']}');
    }
    
    return parts.isEmpty ? '共 ${stats['total']} 项' : parts.join(', ');
  }
}

/// 安全预警详细对话框
class SafetyWarningDialog extends StatelessWidget {
  final List<SafetyWarning> warnings;

  const SafetyWarningDialog({
    super.key,
    required this.warnings,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.security, color: Colors.red),
          SizedBox(width: 8.0),
          Text('安全预警详情'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400.0,
        child: ListView.builder(
          itemCount: warnings.length,
          itemBuilder: (context, index) {
            final warning = warnings[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          warning.levelIcon,
                          color: warning.levelColor,
                          size: 20.0,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            warning.title,
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: warning.levelColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      warning.message,
                      style: const TextStyle(fontSize: 14.0),
                    ),
                    if (warning.recommendation != null) ...[
                      const SizedBox(height: 8.0),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue,
                              size: 16.0,
                            ),
                            const SizedBox(width: 6.0),
                            Expanded(
                              child: Text(
                                '建议: ${warning.recommendation}',
                                style: const TextStyle(
                                  fontSize: 13.0,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4.0),
                    Text(
                      '时间: ${warning.timestamp.toString().substring(0, 19)}',
                      style: TextStyle(
                        fontSize: 11.0,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
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
        ElevatedButton(
          onPressed: () {
            // 可以添加导出或分享功能
            Navigator.of(context).pop();
          },
          child: const Text('了解'),
        ),
      ],
    );
  }
}

/// 安全状态指示器
class SafetyStatusIndicator extends StatelessWidget {
  final List<SafetyWarning> warnings;
  final double size;

  const SafetyStatusIndicator({
    super.key,
    required this.warnings,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) {
      return Icon(
        Icons.check_circle,
        color: Colors.green,
        size: size,
      );
    }

    final highestLevel = SafetyWarningSystem().getHighestWarningLevel(warnings);
    
    return Stack(
      children: [
        Icon(
          _getStatusIcon(highestLevel),
          color: _getStatusColor(highestLevel),
          size: size,
        ),
        if (warnings.length > 1)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2.0),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                warnings.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  IconData _getStatusIcon(SafetyWarningLevel? level) {
    if (level == null) return Icons.check_circle;
    
    switch (level) {
      case SafetyWarningLevel.info:
        return Icons.info;
      case SafetyWarningLevel.warning:
        return Icons.warning;
      case SafetyWarningLevel.danger:
        return Icons.error;
      case SafetyWarningLevel.critical:
        return Icons.dangerous;
    }
  }

  Color _getStatusColor(SafetyWarningLevel? level) {
    if (level == null) return Colors.green;
    
    switch (level) {
      case SafetyWarningLevel.info:
        return Colors.blue;
      case SafetyWarningLevel.warning:
        return Colors.orange;
      case SafetyWarningLevel.danger:
        return Colors.red;
      case SafetyWarningLevel.critical:
        return Colors.red[900]!;
    }
  }
}