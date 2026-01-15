import 'package:flutter/material.dart';
import '../../models/help_content.dart';

/// 教程对话框
/// 
/// 显示操作教程的详细内容，包括步骤说明和提示
class TutorialDialog extends StatefulWidget {
  /// 教程信息
  final Tutorial tutorial;

  const TutorialDialog({
    super.key,
    required this.tutorial,
  });

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  int _currentStepIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500.0,
          maxHeight: 700.0,
        ),
        child: Column(
          children: [
            // 标题栏
            _buildHeader(context),
            
            // 教程信息
            _buildTutorialInfo(),
            
            // 步骤内容
            Expanded(
              child: _buildStepContent(),
            ),
            
            // 导航按钮
            _buildNavigation(context),
          ],
        ),
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.school,
            color: Colors.white,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              widget.tutorial.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 构建教程信息
  Widget _buildTutorialInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.tutorial.description,
            style: const TextStyle(
              fontSize: 14.0,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16.0,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4.0),
              Text(
                '预计用时：${widget.tutorial.estimatedMinutes}分钟',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16.0),
              Icon(
                Icons.list,
                size: 16.0,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4.0),
              Text(
                '共${widget.tutorial.steps.length}个步骤',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建步骤内容
  Widget _buildStepContent() {
    final step = widget.tutorial.steps[_currentStepIndex];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤进度指示器
          _buildStepIndicator(),
          const SizedBox(height: 20.0),
          
          // 步骤标题
          Text(
            '步骤 ${_currentStepIndex + 1}：${step.title}',
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // 步骤描述
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: Text(
              step.description,
              style: const TextStyle(
                fontSize: 14.0,
                height: 1.5,
              ),
            ),
          ),
          
          // 提示信息
          if (step.tips.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            const Text(
              '💡 操作提示',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8.0),
            ...step.tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6.0, right: 8.0),
                    width: 4.0,
                    height: 4.0,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 13.0,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }

  /// 构建步骤进度指示器
  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(
        widget.tutorial.steps.length,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < widget.tutorial.steps.length - 1 ? 4.0 : 0.0,
            ),
            height: 4.0,
            decoration: BoxDecoration(
              color: index <= _currentStepIndex 
                  ? Colors.green 
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建导航按钮
  Widget _buildNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 上一步按钮
          TextButton.icon(
            onPressed: _currentStepIndex > 0 
                ? () => setState(() => _currentStepIndex--) 
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('上一步'),
          ),
          
          // 步骤指示器
          Text(
            '${_currentStepIndex + 1} / ${widget.tutorial.steps.length}',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey.shade600,
            ),
          ),
          
          // 下一步/完成按钮
          _currentStepIndex < widget.tutorial.steps.length - 1
              ? TextButton.icon(
                  onPressed: () => setState(() => _currentStepIndex++),
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('下一步'),
                )
              : ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check),
                  label: const Text('完成'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
        ],
      ),
    );
  }
}