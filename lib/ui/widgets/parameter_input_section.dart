import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'help_icon_button.dart';

/// 参数输入区域组件
class ParameterInputSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isCollapsible;
  final bool initiallyExpanded;

  const ParameterInputSection({
    super.key,
    required this.title,
    required this.children,
    this.isCollapsible = false,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isCollapsible) {
      return Card(
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          initiallyExpanded: initiallyExpanded,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// 数值输入字段组件
class NumberInputField extends StatelessWidget {
  final String label;
  final String? unit;
  final double? value;
  final ValueChanged<double?> onChanged;
  final String? errorText;
  final String? helpText;
  final String? parameterName; // 新增：参数名称，用于获取帮助信息
  final double? min;
  final double? max;
  final int? decimalPlaces;
  final bool isRequired;

  const NumberInputField({
    super.key,
    required this.label,
    this.unit,
    this.value,
    required this.onChanged,
    this.errorText,
    this.helpText,
    this.parameterName, // 新增参数
    this.min,
    this.max,
    this.decimalPlaces = 2,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: value?.toString(),
                decoration: InputDecoration(
                  labelText: label + (isRequired ? ' *' : ''),
                  suffixText: unit,
                  errorText: errorText,
                  helperText: helpText,
                  suffixIcon: parameterName != null
                      ? HelpIconButton(parameterName: parameterName!)
                      : (helpText != null
                          ? IconButton(
                              icon: const Icon(Icons.help_outline, size: 20),
                              onPressed: () => _showHelpDialog(context),
                            )
                          : null),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (text) {
                  if (text.isEmpty) {
                    onChanged(null);
                    return;
                  }
                  
                  final parsedValue = double.tryParse(text);
                  if (parsedValue != null) {
                    // 检查范围
                    if (min != null && parsedValue < min!) return;
                    if (max != null && parsedValue > max!) return;
                    
                    onChanged(parsedValue);
                  }
                },
                validator: (value) {
                  if (isRequired && (value == null || value.isEmpty)) {
                    return '此字段为必填项';
                  }
                  
                  if (value != null && value.isNotEmpty) {
                    final parsedValue = double.tryParse(value);
                    if (parsedValue == null) {
                      return '请输入有效的数值';
                    }
                    
                    if (min != null && parsedValue < min!) {
                      return '数值不能小于 $min';
                    }
                    
                    if (max != null && parsedValue > max!) {
                      return '数值不能大于 $max';
                    }
                  }
                  
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 显示帮助对话框
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Text(helpText ?? '暂无帮助信息'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 单位选择器组件
class UnitSelector extends StatelessWidget {
  final String currentUnit;
  final List<String> availableUnits;
  final ValueChanged<String> onUnitChanged;

  const UnitSelector({
    super.key,
    required this.currentUnit,
    required this.availableUnits,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[600]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentUnit,
          items: availableUnits.map((unit) {
            return DropdownMenuItem<String>(
              value: unit,
              child: Text(unit),
            );
          }).toList(),
          onChanged: (newUnit) {
            if (newUnit != null) {
              onUnitChanged(newUnit);
            }
          },
        ),
      ),
    );
  }
}