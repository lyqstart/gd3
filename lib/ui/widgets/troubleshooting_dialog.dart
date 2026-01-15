import 'package:flutter/material.dart';
import '../../models/help_content.dart';

/// 故障排除对话框
/// 
/// 显示故障排除建议的详细内容
class TroubleshootingDialog extends StatelessWidget {
  /// 故障排除建议
  final TroubleshootingTip troubleshootingTip;

  const TroubleshootingDialog({
    super.key,
    required this.troubleshootingTip,
  });

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
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            _buildHeader(context),
            
            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSymptom(),
                    const SizedBox(height: 20.0),
                    _buildPossibleCauses(),
                    const SizedBox(height: 20.0),
                    _buildSolutions(),
                    if (troubleshootingTip.preventionTips.isNotEmpty) ...[
                      const SizedBox(height: 20.0),
                      _buildPreventionTips(),
                    ],
                  ],
                ),
              ),
            ),
            
            // 按钮栏
            _buildActions(context),
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
        color: Colors.red,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.build,
            color: Colors.white,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          const Expanded(
            child: Text(
              '故障排除建议',
              style: TextStyle(
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

  /// 构建问题症状部分
  Widget _buildSymptom() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 20.0,
            ),
            SizedBox(width: 8.0),
            Text(
              '问题症状',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          child: Text(
            troubleshootingTip.symptom,
            style: const TextStyle(
              fontSize: 14.0,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建可能原因部分
  Widget _buildPossibleCauses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.orange,
              size: 20.0,
            ),
            SizedBox(width: 8.0),
            Text(
              '可能原因',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        ...troubleshootingTip.possibleCauses.asMap().entries.map((entry) {
          final index = entry.key;
          final cause = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20.0,
                  height: 20.0,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.orange,
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    cause,
                    style: const TextStyle(
                      fontSize: 14.0,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 构建解决方案部分
  Widget _buildSolutions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Colors.green,
              size: 20.0,
            ),
            SizedBox(width: 8.0),
            Text(
              '解决方案',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        ...troubleshootingTip.solutions.asMap().entries.map((entry) {
          final index = entry.key;
          final solution = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20.0,
                  height: 20.0,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    solution,
                    style: const TextStyle(
                      fontSize: 14.0,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 构建预防措施部分
  Widget _buildPreventionTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.shield_outlined,
              color: Colors.blue,
              size: 20.0,
            ),
            SizedBox(width: 8.0),
            Text(
              '预防措施',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        ...troubleshootingTip.preventionTips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6.0, right: 8.0),
                width: 4.0,
                height: 4.0,
                decoration: const BoxDecoration(
                  color: Colors.blue,
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
    );
  }

  /// 构建操作按钮
  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}