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

/// 下塞柄计算页面
/// 
/// 提供下塞柄尺寸计算的完整用户界面，包括参数输入、验证、计算和结果显示
class StemCalculationPage extends StatefulWidget {
  const StemCalculationPage({super.key});

  @override
  State<StemCalculationPage> createState() => _StemCalculationPageState();
}

class _StemCalculationPageState extends State<StemCalculationPage> {
  // 表单键
  final _formKey = GlobalKey<FormState>();
  
  // 参数控制器
  final _fValueController = TextEditingController();
  final _gValueController = TextEditingController();
  final _hValueController = TextEditingController();
  final _gasketThicknessController = TextEditingController();
  final _initialValueController = TextEditingController();
  
  // 服务实例
  final _calculationService = CalculationService();
  final _parameterService = ParameterService();
  
  // 状态变量
  StemResult? _result;
  bool _isCalculating = false;
  UnitType _currentUnit = UnitType.millimeter;
  String? _errorMessage;
  
  @override
  void dispose() {
    _fValueController.dispose();
    _gValueController.dispose();
    _hValueController.dispose();
    _gasketThicknessController.dispose();
    _initialValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CalculationPageTemplate(
      title: '下塞柄计算',
      calculationType: CalculationType.stem,
      parameterInputForm: Form(
        key: _formKey,
        child: _buildParameterInputs(),
      ),
      resultDisplay: _result != null ? CalculationResultSection(result: _result!) : null,
      isCalculating: _isCalculating,
      errorMessage: _errorMessage,
      onCalculate: _performCalculation,
      onSaveParameterGroup: () => _showSaveParameterDialog(),
      onParameterGroupSelected: _loadParameterSet,
    );
  }

  /// 构建参数输入组件
  Widget _buildParameterInputs() {
    return ParameterInputSection(
      title: '下塞柄参数',
      children: [
        _buildParameterField(
          controller: _fValueController,
          label: 'F值',
          hint: '请输入F值',
          helpText: 'F值：从联箱口到夹板阀顶的距离',
          unit: _currentUnit,
        ),
        const SizedBox(height: 16),
        _buildParameterField(
          controller: _gValueController,
          label: 'G值',
          hint: '请输入G值',
          helpText: 'G值：夹板阀顶到管外壁的距离',
          unit: _currentUnit,
        ),
        const SizedBox(height: 16),
        _buildParameterField(
          controller: _hValueController,
          label: 'H值',
          hint: '请输入H值',
          helpText: 'H值：塞柄插入深度',
          unit: _currentUnit,
        ),
        const SizedBox(height: 16),
        _buildParameterField(
          controller: _gasketThicknessController,
          label: '垫子厚度',
          hint: '请输入垫子厚度',
          helpText: '垫子厚度：密封垫片的厚度',
          unit: _currentUnit,
        ),
        const SizedBox(height: 16),
        _buildParameterField(
          controller: _initialValueController,
          label: '初始值',
          hint: '请输入初始值',
          helpText: '初始值：设备的初始设定值',
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
              
              // 参数范围验证
              if (label == 'F值' && numValue > 1000) {
                return 'F值超出合理范围 (建议 < 1000mm)';
              }
              if (label == 'G值' && numValue > 500) {
                return 'G值超出合理范围 (建议 < 500mm)';
              }
              if (label == 'H值' && numValue > 200) {
                return 'H值超出合理范围 (建议 < 200mm)';
              }
              if (label == '垫子厚度' && numValue > 20) {
                return '垫子厚度超出合理范围 (建议 < 20mm)';
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 12),
            const Text('测量要点：', style: TextStyle(fontWeight: FontWeight.bold)),
            if (parameter == 'F值') ...[
              const Text('• 使用卷尺从联箱口中心测量到夹板阀顶面'),
              const Text('• 确保测量路径垂直于管道轴线'),
            ] else if (parameter == 'G值') ...[
              const Text('• 测量夹板阀顶面到管道外壁的垂直距离'),
              const Text('• 注意管道保温层的影响'),
            ] else if (parameter == 'H值') ...[
              const Text('• 根据封堵要求确定塞柄插入深度'),
              const Text('• 考虑管道内流体压力和安全要求'),
            ] else if (parameter == '垫子厚度') ...[
              const Text('• 使用游标卡尺精确测量'),
              const Text('• 考虑垫片压缩后的实际厚度'),
            ] else if (parameter == '初始值') ...[
              const Text('• 参考设备说明书或标准作业程序'),
              const Text('• 根据具体设备型号确定'),
            ],
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

  /// 处理单位切换
  void _handleUnitChange(UnitType newUnit) {
    if (newUnit == _currentUnit) return;
    
    setState(() {
      // 转换所有输入值
      _convertControllerValue(_fValueController, _currentUnit, newUnit);
      _convertControllerValue(_gValueController, _currentUnit, newUnit);
      _convertControllerValue(_hValueController, _currentUnit, newUnit);
      _convertControllerValue(_gasketThicknessController, _currentUnit, newUnit);
      _convertControllerValue(_initialValueController, _currentUnit, newUnit);
      
      _currentUnit = newUnit;
    });
  }

  /// 转换控制器中的数值
  void _convertControllerValue(TextEditingController controller, UnitType from, UnitType to) {
    if (controller.text.isNotEmpty) {
      final value = double.tryParse(controller.text);
      if (value != null) {
        final convertedValue = UnitConverter.convert(value, from, to);
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
      final fValue = double.parse(_fValueController.text);
      final gValue = double.parse(_gValueController.text);
      final hValue = double.parse(_hValueController.text);
      final gasketThickness = double.parse(_gasketThicknessController.text);
      final initialValue = double.parse(_initialValueController.text);

      // 转换为毫米单位进行计算
      final fValueMm = _currentUnit == UnitType.millimeter ? fValue : UnitConverter.convert(fValue, UnitType.inch, UnitType.millimeter);
      final gValueMm = _currentUnit == UnitType.millimeter ? gValue : UnitConverter.convert(gValue, UnitType.inch, UnitType.millimeter);
      final hValueMm = _currentUnit == UnitType.millimeter ? hValue : UnitConverter.convert(hValue, UnitType.inch, UnitType.millimeter);
      final gasketThicknessMm = _currentUnit == UnitType.millimeter ? gasketThickness : UnitConverter.convert(gasketThickness, UnitType.inch, UnitType.millimeter);
      final initialValueMm = _currentUnit == UnitType.millimeter ? initialValue : UnitConverter.convert(initialValue, UnitType.inch, UnitType.millimeter);

      // 创建参数对象
      final parameters = StemParameters(
        fValue: fValueMm,
        gValue: gValueMm,
        hValue: hValueMm,
        gasketThickness: gasketThicknessMm,
        initialValue: initialValueMm,
      );

      // 执行计算
      final result = await _calculationService.calculate(
        CalculationType.stem,
        parameters.toJson(),
      ) as StemResult;

      setState(() {
        _result = result;
        _isCalculating = false;
      });

      // 检查参数范围并显示警告
      _checkParameterRanges(result);

    } catch (e) {
      setState(() {
        _errorMessage = '计算失败: ${e.toString()}';
        _isCalculating = false;
      });
    }
  }

  /// 检查参数范围并显示警告
  void _checkParameterRanges(StemResult result) {
    final warnings = <String>[];
    
    // 检查总行程是否在合理范围内
    if (result.totalStroke > 1500) {
      warnings.add('总行程过大 (${result.totalStroke.toStringAsFixed(2)}mm)，可能超出设备行程范围');
    }
    
    // 检查各参数的合理性
    final params = result.parameters as StemParameters;
    if (params.fValue > 800) {
      warnings.add('F值较大，请确认测量准确性');
    }
    if (params.hValue < 10) {
      warnings.add('H值较小，可能影响封堵效果');
    }
    if (params.gasketThickness > 15) {
      warnings.add('垫子厚度较大，请确认规格正确');
    }

    if (warnings.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('参数范围提醒'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('检测到以下参数可能需要注意：'),
              const SizedBox(height: 8),
              ...warnings.map((warning) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $warning', style: const TextStyle(color: Colors.orange)),
              )),
              const SizedBox(height: 12),
              const Text('建议：'),
              const Text('• 重新确认参数测量的准确性'),
              const Text('• 检查设备规格和作业要求'),
              const Text('• 必要时咨询技术人员'),
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

  /// 显示保存参数组对话框
  void _showSaveParameterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        return AlertDialog(
          title: const Text('保存参数组'),
          content: TextField(
            onChanged: (value) => name = value,
            decoration: const InputDecoration(
              labelText: '参数组名称',
              hintText: '请输入参数组名称',
            ),
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

  /// 保存参数组
  Future<void> _saveParameterSet(String name) async {
    try {
      final stemParameters = StemParameters(
        fValue: double.tryParse(_fValueController.text) ?? 0.0,
        gValue: double.tryParse(_gValueController.text) ?? 0.0,
        hValue: double.tryParse(_hValueController.text) ?? 0.0,
        gasketThickness: double.tryParse(_gasketThicknessController.text) ?? 0.0,
        initialValue: double.tryParse(_initialValueController.text) ?? 0.0,
      );

      final parameterSet = ParameterSet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        calculationType: CalculationType.stem,
        parameters: stemParameters,
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

  /// 加载参数组
  Future<void> _loadParameterSet(ParameterSet parameterSet) async {
    try {
      final params = parameterSet.parameters;
      
      // 确保参数是StemParameters类型
      if (params is! StemParameters) {
        throw ArgumentError('参数组类型不匹配，期望StemParameters');
      }
      
      final stemParams = params as StemParameters;
      
      // 设置参数值
      _fValueController.text = stemParams.fValue.toString();
      _gValueController.text = stemParams.gValue.toString();
      _hValueController.text = stemParams.hValue.toString();
      _gasketThicknessController.text = stemParams.gasketThickness.toString();
      _initialValueController.text = stemParams.initialValue.toString();

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
}