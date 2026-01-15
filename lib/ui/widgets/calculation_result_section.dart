import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/calculation_result.dart';
import '../../models/validation_result.dart';
import 'diagram_viewer.dart';

/// 计算结果显示区域组件
class CalculationResultSection extends StatelessWidget {
  final CalculationResult result;
  final VoidCallback? onCopyResult;
  final VoidCallback? onExport;
  final bool showFormulas;
  final bool showCalculationSteps;

  const CalculationResultSection({
    super.key,
    required this.result,
    this.onCopyResult,
    this.onExport,
    this.showFormulas = true,
    this.showCalculationSteps = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主要结果显示
        _buildMainResultsCard(context),
        
        const SizedBox(height: 16),
        
        // 所有结果详情
        _buildAllResultsCard(),
        
        if (showFormulas) ...[
          const SizedBox(height: 16),
          _buildFormulasCard(),
        ],
        
        if (showCalculationSteps) ...[
          const SizedBox(height: 16),
          _buildCalculationStepsCard(),
        ],
        
        // 验证结果和安全提示
        if (_hasValidationOrSafety()) ...[
          const SizedBox(height: 16),
          _buildValidationAndSafetyCard(),
        ],
      ],
    );
  }

  /// 构建主要结果卡片（核心结果高亮显示）
  Widget _buildMainResultsCard(BuildContext context) {
    final coreResults = result.getCoreResults();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '核心计算结果',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      tooltip: '查看示意图',
                      onPressed: () => showDiagramPreview(context, result),
                    ),
                    if (onCopyResult != null)
                      IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: '复制结果',
                        onPressed: onCopyResult,
                      ),
                    if (onExport != null)
                      IconButton(
                        icon: const Icon(Icons.share),
                        tooltip: '导出结果',
                        onPressed: onExport,
                      ),
                  ],
                ),
              ],
            ),
            
            const Divider(),
            
            // 核心结果列表（高亮显示）
            ...coreResults.entries.map((entry) => _buildHighlightedResultItem(
              entry.key,
              entry.value,
              result.getUnit(),
            )),
          ],
        ),
      ),
    );
  }

  /// 构建所有结果详情卡片
  Widget _buildAllResultsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '详细计算结果',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 根据计算类型显示不同的详细结果
            ..._buildDetailedResults(),
          ],
        ),
      ),
    );
  }

  /// 构建公式说明卡片
  Widget _buildFormulasCard() {
    final formulas = result.getFormulas();
    
    return Card(
      child: ExpansionTile(
        title: const Text(
          '计算公式',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: formulas.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建计算步骤卡片
  Widget _buildCalculationStepsCard() {
    Map<String, String>? steps;
    
    // 根据结果类型获取计算步骤
    if (result is HoleCalculationResult) {
      steps = (result as HoleCalculationResult).getCalculationSteps();
    } else if (result is SealingResult) {
      steps = (result as SealingResult).getCalculationSteps();
    } else if (result is PlugResult) {
      steps = (result as PlugResult).getCalculationSteps();
    } else if (result is StemResult) {
      steps = (result as StemResult).getCalculationSteps();
    }
    
    if (steps == null || steps.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: ExpansionTile(
        title: const Text(
          '计算步骤',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          entry.key.replaceAll('步骤', ''),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建验证结果和安全提示卡片
  Widget _buildValidationAndSafetyCard() {
    return Column(
      children: [
        // 验证结果
        if (_hasValidationResult())
          _buildValidationResultCard(),
        
        // 安全提示
        if (_hasSafetyWarnings()) ...[
          const SizedBox(height: 16),
          _buildSafetyWarningsCard(),
        ],
        
        // 参数检查建议（仅下塞堵）
        if (result is PlugResult) ...[
          const SizedBox(height: 16),
          _buildParameterCheckSuggestionsCard(),
        ],
      ],
    );
  }

  /// 构建验证结果卡片
  Widget _buildValidationResultCard() {
    ValidationResult? validation;
    
    if (result is HoleCalculationResult) {
      validation = (result as HoleCalculationResult).validateResults();
    } else if (result is SealingResult) {
      validation = (result as SealingResult).validateResults();
    } else if (result is PlugResult) {
      validation = (result as PlugResult).validateResults();
    } else if (result is StemResult) {
      validation = (result as StemResult).validateResults();
    }
    
    if (validation == null) return const SizedBox.shrink();
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    if (validation.isValid) {
      backgroundColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green;
      icon = Icons.check_circle;
    } else if (validation.isWarning) {
      backgroundColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange;
      icon = Icons.warning;
    } else {
      backgroundColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
      icon = Icons.error;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: textColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              validation.message,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建安全提示卡片
  Widget _buildSafetyWarningsCard() {
    List<String>? warnings;
    
    if (result is HoleCalculationResult) {
      warnings = (result as HoleCalculationResult).getSafetyWarnings();
    } else if (result is SealingResult) {
      warnings = (result as SealingResult).getSafetyWarnings();
    } else if (result is PlugResult) {
      warnings = (result as PlugResult).getSafetyWarnings();
    } else if (result is StemResult) {
      warnings = (result as StemResult).getSafetyWarnings();
    }
    
    if (warnings == null || warnings.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '安全提示',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...warnings.map((warning) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// 构建参数检查建议卡片（仅下塞堵）
  Widget _buildParameterCheckSuggestionsCard() {
    if (result is! PlugResult) return const SizedBox.shrink();
    
    final plugResult = result as PlugResult;
    final suggestions = plugResult.getParameterCheckSuggestions();
    
    if (suggestions.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.checklist, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '参数检查建议',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...suggestions.map((suggestion) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                suggestion,
                style: const TextStyle(fontSize: 14),
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// 构建高亮结果项
  Widget _buildHighlightedResultItem(String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${value.toStringAsFixed(2)} $unit',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建普通结果项
  Widget _buildResultItem(String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} $unit',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建详细结果列表
  List<Widget> _buildDetailedResults() {
    final unit = result.getUnit();
    
    if (result is HoleCalculationResult) {
      final holeResult = result as HoleCalculationResult;
      return [
        _buildResultItem('空行程', holeResult.emptyStroke, unit),
        _buildResultItem('筒刀切削距离', holeResult.cuttingDistance, unit),
        _buildResultItem('掉板弦高', holeResult.chordHeight, unit),
        _buildResultItem('切削尺寸', holeResult.cuttingSize, unit),
        _buildResultItem('开孔总行程', holeResult.totalStroke, unit),
        _buildResultItem('掉板总行程', holeResult.plateStroke, unit),
      ];
    } else if (result is ManualHoleResult) {
      final manualResult = result as ManualHoleResult;
      return [
        _buildResultItem('螺纹咬合尺寸', manualResult.threadEngagement, unit),
        _buildResultItem('空行程', manualResult.emptyStroke, unit),
        _buildResultItem('总行程', manualResult.totalStroke, unit),
      ];
    } else if (result is SealingResult) {
      final sealingResult = result as SealingResult;
      return [
        _buildResultItem('导向轮接触管线行程', sealingResult.guideWheelStroke, unit),
        _buildResultItem('封堵总行程', sealingResult.totalStroke, unit),
      ];
    } else if (result is PlugResult) {
      final plugResult = result as PlugResult;
      return [
        _buildResultItem('螺纹咬合尺寸', plugResult.threadEngagement, unit),
        _buildResultItem('空行程', plugResult.emptyStroke, unit),
        _buildResultItem('总行程', plugResult.totalStroke, unit),
      ];
    } else if (result is StemResult) {
      final stemResult = result as StemResult;
      return [
        _buildResultItem('总行程', stemResult.totalStroke, unit),
      ];
    }
    
    return [];
  }

  /// 检查是否有验证结果或安全提示
  bool _hasValidationOrSafety() {
    return _hasValidationResult() || _hasSafetyWarnings() || result is PlugResult;
  }

  /// 检查是否有验证结果
  bool _hasValidationResult() {
    return result is HoleCalculationResult ||
           result is SealingResult ||
           result is PlugResult ||
           result is StemResult;
  }

  /// 检查是否有安全提示
  bool _hasSafetyWarnings() {
    if (result is HoleCalculationResult) {
      return (result as HoleCalculationResult).getSafetyWarnings().isNotEmpty;
    } else if (result is SealingResult) {
      return (result as SealingResult).getSafetyWarnings().isNotEmpty;
    } else if (result is PlugResult) {
      return (result as PlugResult).getSafetyWarnings().isNotEmpty;
    } else if (result is StemResult) {
      return (result as StemResult).getSafetyWarnings().isNotEmpty;
    }
    return false;
  }
}

/// 结果项数据类
class ResultItem {
  final String label;
  final double value;
  final String? unit;
  final bool isHighlighted;
  final Color? highlightColor;
  final int decimalPlaces;

  const ResultItem({
    required this.label,
    required this.value,
    this.unit,
    this.isHighlighted = false,
    this.highlightColor,
    this.decimalPlaces = 2,
  });

  /// 格式化的数值字符串
  String get formattedValue {
    return value.toStringAsFixed(decimalPlaces);
  }
}

/// 计算过程显示组件
class CalculationProcessSection extends StatelessWidget {
  final String title;
  final List<ProcessStep> steps;

  const CalculationProcessSection({
    super.key,
    required this.title,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps.map((step) => _buildProcessStep(step)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建计算步骤
  Widget _buildProcessStep(ProcessStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${step.stepNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.description,
                  style: const TextStyle(fontSize: 14),
                ),
                if (step.formula != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        step.formula!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 计算步骤数据类
class ProcessStep {
  final int stepNumber;
  final String description;
  final String? formula;

  const ProcessStep({
    required this.stepNumber,
    required this.description,
    this.formula,
  });
}