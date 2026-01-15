import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/parameter_input_section.dart';
import '../widgets/calculation_result_section.dart';
import 'calculation_page_template.dart';
import '../../models/enums.dart';
import '../../models/calculation_parameters.dart';
import '../../models/calculation_result.dart';
import '../../models/parameter_models.dart';
import '../../models/validation_result.dart';
import '../../services/calculation_service.dart';
import '../../services/parameter_service.dart';
import '../../utils/unit_converter.dart';

/// 下塞堵计算页面
/// 
/// 提供下塞堵尺寸计算的完整用户界面，包括参数输入、验证、计算和结果显示
class PlugCalculationPage extends StatefulWidget {
  const PlugCalculationPage({super.key});

  @override
  State<PlugCalculationPage> createState() => _PlugCalculationPageState();
}

class _PlugCalculationPageState extends State<PlugCalculationPage> {
  // 表单键
  final _formKey = GlobalKey<FormState>();
  
  // 参数控制器
  final _mValueController = TextEditingController();
  final _kValueController = TextEditingController();
  final _nValueController = TextEditingController();
  final _tValueController = TextEditingController();
  final _wValueController = TextEditingController();
  
  // 服务实例
  final _calculationService = CalculationService();
  final _parameterService = ParameterService();
  
  // 状态变量
  PlugResult? _result;
  bool _isCalculating = false;
  UnitType _currentUnit = UnitType.millimeter;
  String? _errorMessage;
  
  @override
  void dispose() {
    _mValueController.dispose();
    _kValueController.dispose();
    _nValueController.dispose();
    _tValueController.dispose();
    _wValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CalculationPageTemplate(
      title: '下塞堵计算',
      calculationType: CalculationType.plug,
      formKey: _formKey,
      isCalculating: _isCalculating,
      resultDisplay: _result != null ? CalculationResultSection(
        result: _result!,
        onCopyResult: _copyResult,
        onExport: _exportResult,
      ) : null,
      errorMessage: _errorMessage,
      onCalculate: _performCalculation,
      onSaveParameterGroup: _showSaveParameterDialog,
      parameterInputForm: _buildParameterInputs(),
    );
  }

  /// 构建参数输入组件
  Widget _buildParameterInputs() {
    return ParameterInputSection(
      title: '下塞堵参数',
      children: [
        _buildParameterField(
          controller: _mValueController,
          label: 'M值',
          hint: '请输入M值',
          helpText: 'M值：从联箱口到夹板阀顶的距离',
          unit: _currentUnit,
        ),
        const SizedBox(height: 16),
        _buildParameterField(
          controller: _kValueController,
          label: 'K值',
          hint: '请输入K值',
          helpText: 'K值：夹板阀顶到管外壁的距离',
          unit: _currentUnit,
        ),
        const SizedBox(height: 16),
        _buildParameterField(
          controller: _nValueController,
          label: 'N值',
          hint: '请输入N值',
          helpText: 'N值：塞堵深度',
          unit: _currentUnit,
        ),
        const SizedBox(height: 16),
        _buildParameterField(
          controller: _tValueController,
          label: 'T值',
          hint: '请输入T值',
          helpText: 'T值：螺纹长度',
          unit: _currentUnit,
        ),
        const SizedBox(height: 16),
        _buildParameterField(
          controller: _wValueController,
          label: 'W值',
          hint: '请输入W值',
          helpText: 'W值：螺纹咬合长度',
          unit: _currentUnit,
        ),
      ],
    );
  }

  /// 构建参数输入字段
  Widget _buildParameterField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String helpText,
    required UnitType unit,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              suffixText: unit == UnitType.millimeter ? 'mm' : 'inch',
              border: const OutlineInputBorder(),
              errorMaxLines: 2,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入$label';
              }
              final numValue = double.tryParse(value);
              if (numValue == null) {
                return '请输入有效的数值';
              }
              if (numValue < 0) {
                return '$label不能为负数';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(label, helpText),
            tooltip: '查看参数说明',
          ),
        ),
      ],
    );
  }

  /// 显示帮助对话框
  void _showHelpDialog(String parameter, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$parameter 说明'),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 处理单位切换
  void _handleUnitChange(UnitType newUnit) {
    if (newUnit == _currentUnit) return;
    
    setState(() {
      // 转换所有输入值
      _convertControllerValue(_mValueController, _currentUnit, newUnit);
      _convertControllerValue(_kValueController, _currentUnit, newUnit);
      _convertControllerValue(_nValueController, _currentUnit, newUnit);
      _convertControllerValue(_tValueController, _currentUnit, newUnit);
      _convertControllerValue(_wValueController, _currentUnit, newUnit);
      
      _currentUnit = newUnit;
    });
  }

  /// 转换控制器中的数值
  void _convertControllerValue(TextEditingController controller, UnitType from, UnitType to) {
    if (controller.text.isNotEmpty) {
      final value = double.tryParse(controller.text);
      if (value != null) {
        final convertedValue = UnitConverter.convertUnit(value, from, to);
        controller.text = convertedValue.toStringAsFixed(2);
      }
    }
  }

  /// 执行计算
  Future<void> _performCalculation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCalculating = true;
      _errorMessage = null;
    });

    try {
      // 获取输入参数
      final mValue = double.parse(_mValueController.text);
      final kValue = double.parse(_kValueController.text);
      final nValue = double.parse(_nValueController.text);
      final tValue = double.parse(_tValueController.text);
      final wValue = double.parse(_wValueController.text);

      // 转换为毫米单位进行计算
      final mValueMm = _currentUnit == UnitType.millimeter ? mValue : UnitConverter.inchToMm(mValue);
      final kValueMm = _currentUnit == UnitType.millimeter ? kValue : UnitConverter.inchToMm(kValue);
      final nValueMm = _currentUnit == UnitType.millimeter ? nValue : UnitConverter.inchToMm(nValue);
      final tValueMm = _currentUnit == UnitType.millimeter ? tValue : UnitConverter.inchToMm(tValue);
      final wValueMm = _currentUnit == UnitType.millimeter ? wValue : UnitConverter.inchToMm(wValue);

      // 创建参数对象
      final parameters = PlugParameters(
        mValue: mValueMm,
        kValue: kValueMm,
        nValue: nValueMm,
        tValue: tValueMm,
        wValue: wValueMm,
      );

      // 执行计算
      final result = await _calculationService.calculate(
        CalculationType.plug,
        parameters.toJson(),
      ) as PlugResult;

      setState(() {
        _result = result;
        _isCalculating = false;
      });

      // 检查负值结果并显示建议
      _checkNegativeResults(result);

    } catch (e) {
      setState(() {
        _errorMessage = '计算失败: ${e.toString()}';
        _isCalculating = false;
      });
    }
  }

  /// 检查负值结果并显示参数检查建议
  void _checkNegativeResults(PlugResult result) {
    final negativeResults = <String>[];
    
    if (result.threadEngagement < 0) {
      negativeResults.add('螺纹咬合尺寸为负值 (${result.threadEngagement.toStringAsFixed(2)}mm)');
    }
    if (result.emptyStroke < 0) {
      negativeResults.add('空行程为负值 (${result.emptyStroke.toStringAsFixed(2)}mm)');
    }
    if (result.totalStroke < 0) {
      negativeResults.add('总行程为负值 (${result.totalStroke.toStringAsFixed(2)}mm)');
    }

    if (negativeResults.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('参数检查建议'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('检测到以下负值结果，建议检查输入参数：'),
              const SizedBox(height: 8),
              ...negativeResults.map((result) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $result', style: const TextStyle(color: Colors.red)),
              )),
              const SizedBox(height: 12),
              const Text('建议：'),
              const Text('• 检查T值和W值的大小关系'),
              const Text('• 确认M值、K值、N值的测量准确性'),
              const Text('• 验证参数单位是否正确'),
            ],
          ),
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

  /// 保存参数组
  Future<void> _saveParameterSet(String name) async {
    try {
      final parameters = PlugParameters(
        mValue: double.tryParse(_mValueController.text) ?? 0.0,
        kValue: double.tryParse(_kValueController.text) ?? 0.0,
        nValue: double.tryParse(_nValueController.text) ?? 0.0,
        tValue: double.tryParse(_tValueController.text) ?? 0.0,
        wValue: double.tryParse(_wValueController.text) ?? 0.0,
      );

      final parameterSet = ParameterSet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        calculationType: CalculationType.plug,
        parameters: parameters,
        isPreset: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _parameterService.saveParameterSet(parameterSet);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('参数组 "$name" 保存成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: ${e.toString()}')),
        );
      }
    }
  }

  /// 显示保存参数对话框
  void _showSaveParameterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        return AlertDialog(
          title: const Text('保存参数组'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: '参数组名称',
              hintText: '请输入参数组名称',
            ),
            onChanged: (value) => name = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  Navigator.of(context).pop();
                  _saveParameterSet(name);
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  /// 加载参数组
  Future<void> _loadParameterSet(ParameterSet parameterSet) async {
    try {
      final params = parameterSet.parameters;
      
      // 确保参数类型正确
      if (params is! PlugParameters) {
        throw Exception('参数类型不匹配，期望PlugParameters');
      }
      
      // 设置参数值
      _mValueController.text = params.mValue.toString();
      _kValueController.text = params.kValue.toString();
      _nValueController.text = params.nValue.toString();
      _tValueController.text = params.tValue.toString();
      _wValueController.text = params.wValue.toString();
      
      // 注意：参数组中的值已经是正确的单位，无需转换
      
      setState(() {
        _result = null;
        _errorMessage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('参数组 "${parameterSet.name}" 加载成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: ${e.toString()}')),
        );
      }
    }
  }

  /// 复制计算结果
  void _copyResult() {
    if (_result == null) return;
    
    final resultText = '''
下塞堵计算结果:
螺纹咬合尺寸: ${_result!.threadEngagement.toStringAsFixed(2)} mm
空行程: ${_result!.emptyStroke.toStringAsFixed(2)} mm
总行程: ${_result!.totalStroke.toStringAsFixed(2)} mm
''';
    
    Clipboard.setData(ClipboardData(text: resultText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('计算结果已复制到剪贴板')),
    );
  }

  /// 导出计算结果
  void _exportResult() {
    if (_result == null) return;
    
    // 这里可以实现导出功能，比如生成PDF或Excel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出功能开发中')),
    );
  }
}