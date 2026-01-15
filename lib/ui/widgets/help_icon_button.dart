import 'package:flutter/material.dart';
import '../../services/help_content_manager.dart';
import '../../models/help_content.dart';
import 'parameter_help_dialog.dart';

/// 参数帮助图标按钮
/// 
/// 在参数输入框旁边显示"?"图标，点击后显示参数帮助信息
class HelpIconButton extends StatelessWidget {
  /// 参数名称
  final String parameterName;
  
  /// 图标大小
  final double? iconSize;
  
  /// 图标颜色
  final Color? iconColor;

  const HelpIconButton({
    super.key,
    required this.parameterName,
    this.iconSize,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.help_outline,
        size: iconSize ?? 20.0,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      ),
      onPressed: () => _showParameterHelp(context),
      tooltip: '查看参数说明',
      padding: const EdgeInsets.all(4.0),
      constraints: const BoxConstraints(
        minWidth: 28.0,
        minHeight: 28.0,
      ),
    );
  }

  /// 显示参数帮助对话框
  void _showParameterHelp(BuildContext context) async {
    final helpManager = HelpContentManager.instance;
    final parameterHelp = helpManager.getParameterHelp(parameterName);
    
    if (parameterHelp != null) {
      showDialog(
        context: context,
        builder: (context) => ParameterHelpDialog(
          parameterHelp: parameterHelp,
        ),
      );
    } else {
      // 如果没有找到帮助信息，显示通用提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('暂无"$parameterName"参数的帮助信息'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

/// 紧凑型帮助图标按钮
/// 
/// 用于空间较小的场景，只显示图标不显示文字
class CompactHelpIconButton extends StatelessWidget {
  /// 参数名称
  final String parameterName;

  const CompactHelpIconButton({
    super.key,
    required this.parameterName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showParameterHelp(context),
      child: Container(
        width: 24.0,
        height: 24.0,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 1.0,
          ),
        ),
        child: Icon(
          Icons.question_mark,
          size: 14.0,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// 显示参数帮助对话框
  void _showParameterHelp(BuildContext context) async {
    final helpManager = HelpContentManager.instance;
    final parameterHelp = helpManager.getParameterHelp(parameterName);
    
    if (parameterHelp != null) {
      showDialog(
        context: context,
        builder: (context) => ParameterHelpDialog(
          parameterHelp: parameterHelp,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('暂无"$parameterName"参数的帮助信息'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}