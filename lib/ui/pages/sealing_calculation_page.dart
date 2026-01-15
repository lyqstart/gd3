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

/// 封堵计算页面
/// 
/// 提供封堵和解堵尺寸计算的完整用户界面，包括参数输入、验证、计算和结果显示
class SealingCalculationPage extends StatefulWidget {
  const SealingCalculationPage({super.key});

  @override
  State<SealingCalculationPage> createState() => _SealingCalculationPageState();
}

class _SealingCalculationPageState extends State<SealingCalculationPage> {
  // 表单键
  final _formKey = GlobalKey<FormState>();
  
  // 参数控制器
  final _rValueController = TextEditingController();
  final _bValueController = TextEditingController();
  final _dValueController = TextEditingController();
  final _eValueController = TextEditingController();
  final _gasketThicknessController = TextEditingController();
  final _initialValueController = TextEditingController();
  
  // 当前参数值
  double? _rValue;
  double? _bValue;
  double? _dValue;
  double? _eValue;
  double? _gasketThickness;
  double? _initialValue;
  
  // 当前单位
  UnitType _currentUnit = UnitType.millimeter;
  
  // 计算状态
  bool _isCalculating = false;
  String? _errorMessage;
  SealingResult? _calculationResult;
  
  // 验证结果
  ValidationResult? _validationResult;
  
  // 预设参数
  List<PresetParameter> _presetParameters = [];
  bool _isLoadingPresets = false;

  // 服务实例
  late final CalculationService _calculationService;
  late final ParameterService _parameterService;

  @override
  void initState() {
    super.initState();
    _calculationService = CalculationService();
    _parameterService = ParameterService();
    _loadPresetParameters();
    _setDefaultValues();
  }

  @override
  void dispose() {
    _rValueController.dispose();
    _bValueController.dispose();
    _dValueController.dispose();
    _eValueController.dispose();
    _gasketThicknessController.dispose();
    _initialValueController.dispose();
    super.dispose();
  }

  /// 加载预设参数
  Future<void> _loadPresetParameters() async {
    setState(() {
      _isLoadingPresets = true;
    });

    try {
      final presets = await _parameterService.getPresetParameters(CalculationType.sealing);
      
      if (mounted) {
        setState(() {
          _presetParameters = presets;
          _isLoadingPresets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPresets = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载预设参数失败: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// 设置默认值
  void _setDefaultValues() {
    // 设置常用的默认值
    _rValueController.text = '60.0';
    _bValueController.text = '20.0';
    _dValueController.text = '80.0';
    _eValueController.text = '100.0';
    _gasketThicknessController.text = '5.0';
    _initialValueController.text = '3.0';
    
    // 更新参数值
    _rValue = 60.0;
    _bValue = 20.0;
    _dValue = 80.0;
    _eValue = 100.0;
    _gasketThickness = 5.0;
    _initialValue = 3.0;
    
    _validateParameters();
  }

  /// 验证参数
  void _validateParameters() {
    if (_hasAllRequiredParameters()) {
      final parameters = _createSealingParameters();
      setState(() {
        _validationResult = parameters.validate();
      });
    } else {
      setState(() {
        _validationResult = null;
      });
    }
  }

  /// 检查是否有所有必需参数
  bool _hasAllRequiredParameters() {
    return _rValue != null &&
           _bValue != null &&
           _dValue != null &&
           _eValue != null &&
           _gasketThickness != null &&
           _initialValue != null;
  }

  /// 创建封堵参数对象
  SealingParameters _createSealingParameters() {
    return SealingParameters(
      rValue: _rValue!,
      bValue: _bValue!,
      dValue: _dValue!,
      eValue: _eValue!,
      gasketThickness: _gasketThickness!,
      initialValue: _initialValue!,
    );
  }

  /// 执行计算
  Future<void> _performCalculation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasAllRequiredParameters()) {
      setState(() {
        _errorMessage = '请填写所有必需的参数';
      });
      return;
    }

    final parameters = _createSealingParameters();
    final validation = parameters.validate();
    
    if (!validation.isValid) {
      setState(() {
        _errorMessage = validation.message;
      });
      return;
    }

    setState(() {
      _isCalculating = true;
      _errorMessage = null;
    });

    try {
      final result = await _calculationService.calculate(
        CalculationType.sealing,
        parameters.toJson(),
      );

      if (mounted) {
        setState(() {
          _calculationResult = result as SealingResult;
          _isCalculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '计算失败: $e';
          _isCalculating = false;
        });
      }
    }
  }

  /// 保存参数组
  Future<void> _saveParameterGroup() async {
    if (!_hasAllRequiredParameters()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先填写完整的参数'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存参数组'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '参数组名称 *',
                hintText: '请输入参数组名称',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '请输入参数组描述',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请输入参数组名称'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        final parameterSet = ParameterSet(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: nameController.text.trim(),
          calculationType: CalculationType.sealing,
          parameters: _createSealingParameters(),
          description: descriptionController.text.trim(),
        );

        await _parameterService.saveParameterSet(parameterSet);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('参数组 "${parameterSet.name}" 保存成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('保存参数组失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  /// 加载参数组
  void _loadParameterGroup(ParameterSet parameterSet) {
    if (parameterSet.calculationType != CalculationType.sealing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('参数组类型不匹配'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final parameters = parameterSet.parameters as SealingParameters;
    
    // 转换单位（如果需要）
    final convertedParameters = _currentUnit == UnitType.millimeter 
        ? parameters 
        : _convertParametersToUnit(parameters, _currentUnit);
    
    // 更新控制器和参数值
    _rValueController.text = convertedParameters.rValue.toStringAsFixed(2);
    _bValueController.text = convertedParameters.bValue.toStringAsFixed(2);
    _dValueController.text = convertedParameters.dValue.toStringAsFixed(2);
    _eValueController.text = convertedParameters.eValue.toStringAsFixed(2);
    _gasketThicknessController.text = convertedParameters.gasketThickness.toStringAsFixed(2);
    _initialValueController.text = convertedParameters.initialValue.toStringAsFixed(2);
    
    _rValue = convertedParameters.rValue;
    _bValue = convertedParameters.bValue;
    _dValue = convertedParameters.dValue;
    _eValue = convertedParameters.eValue;
    _gasketThickness = convertedParameters.gasketThickness;
    _initialValue = convertedParameters.initialValue;
    
    _validateParameters();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已加载参数组 "${parameterSet.name}"'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 转换参数到指定单位
  SealingParameters _convertParametersToUnit(SealingParameters parameters, UnitType targetUnit) {
    return SealingParameters(
      rValue: _parameterService.convertUnit(parameters.rValue, UnitType.millimeter, targetUnit),
      bValue: _parameterService.convertUnit(parameters.bValue, UnitType.millimeter, targetUnit),
      dValue: _parameterService.convertUnit(parameters.dValue, UnitType.millimeter, targetUnit),
      eValue: _parameterService.convertUnit(parameters.eValue, UnitType.millimeter, targetUnit),
      gasketThickness: _parameterService.convertUnit(parameters.gasketThickness, UnitType.millimeter, targetUnit),
      initialValue: _parameterService.convertUnit(parameters.initialValue, UnitType.millimeter, targetUnit),
    );
  }

  /// 切换单位
  void _switchUnit(UnitType newUnit) {
    if (newUnit == _currentUnit) return;
    
    // 转换所有参数值
    if (_rValue != null) {
      _rValue = _parameterService.convertUnit(_rValue!, _currentUnit, newUnit);
      _rValueController.text = _rValue!.toStringAsFixed(2);
    }
    
    if (_bValue != null) {
      _bValue = _parameterService.convertUnit(_bValue!, _currentUnit, newUnit);
      _bValueController.text = _bValue!.toStringAsFixed(2);
    }
    
    if (_dValue != null) {
      _dValue = _parameterService.convertUnit(_dValue!, _currentUnit, newUnit);
      _dValueController.text = _dValue!.toStringAsFixed(2);
    }
    
    if (_eValue != null) {
      _eValue = _parameterService.convertUnit(_eValue!, _currentUnit, newUnit);
      _eValueController.text = _eValue!.toStringAsFixed(2);
    }
    
    if (_gasketThickness != null) {
      _gasketThickness = _parameterService.convertUnit(_gasketThickness!, _currentUnit, newUnit);
      _gasketThicknessController.text = _gasketThickness!.toStringAsFixed(2);
    }
    
    if (_initialValue != null) {
      _initialValue = _parameterService.convertUnit(_initialValue!, _currentUnit, newUnit);
      _initialValueController.text = _initialValue!.toStringAsFixed(2);
    }
    
    setState(() {
      _currentUnit = newUnit;
    });
    
    _validateParameters();
  }

  /// 导出结果
  Future<void> _exportResult() async {
    if (_calculationResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先进行计算'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: 实现导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('导出功能开发中...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalculationPageTemplate(
      title: '封堵计算',
      calculationType: CalculationType.sealing,
      parameterInputForm: _buildParameterInputForm(),
      resultDisplay: _calculationResult != null 
          ? _buildResultDisplay() 
          : null,
      onCalculate: _performCalculation,
      onSaveParameterGroup: _saveParameterGroup,
      onParameterGroupSelected: _loadParameterGroup,
      onExport: _exportResult,
      isCalculating: _isCalculating,
      errorMessage: _errorMessage,
    );
  }

  /// 构建参数输入表单
  Widget _buildParameterInputForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 单位选择器
          _buildUnitSelector(),
          
          const SizedBox(height: 16),
          
          // 预设参数快速选择
          _buildPresetParameterSelector(),
          
          const SizedBox(height: 16),
          
          // 设备参数
          _buildEquipmentParametersSection(),
          
          const SizedBox(height: 16),
          
          // 管道参数
          _buildPipeParametersSection(),
          
          const SizedBox(height: 16),
          
          // 作业参数
          _buildOperationParametersSection(),
          
          const SizedBox(height: 16),
          
          // E值计算提示
          _buildEValueCalculationTip(),
          
          const SizedBox(height: 16),
          
          // 验证结果显示
          if (_validationResult != null)
            _buildValidationResultDisplay(),
        ],
      ),
    );
  }

  /// 构建单位选择器
  Widget _buildUnitSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.block, color: Colors.red),
            const SizedBox(width: 8),
            const Text(
              '测量单位:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SegmentedButton<UnitType>(
                segments: const [
                  ButtonSegment<UnitType>(
                    value: UnitType.millimeter,
                    label: Text('毫米 (mm)'),
                    icon: Icon(Icons.straighten),
                  ),
                  ButtonSegment<UnitType>(
                    value: UnitType.inch,
                    label: Text('英寸 (in)'),
                    icon: Icon(Icons.straighten),
                  ),
                ],
                selected: {_currentUnit},
                onSelectionChanged: (Set<UnitType> selection) {
                  _switchUnit(selection.first);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建预设参数选择器
  Widget _buildPresetParameterSelector() {
    if (_isLoadingPresets) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('加载预设参数中...'),
            ],
          ),
        ),
      );
    }

    if (_presetParameters.isEmpty) {
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
                Icon(Icons.settings_suggest, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  '快速填入预设参数:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetParameters.map((preset) {
                return ActionChip(
                  label: Text(preset.name),
                  onPressed: () => _applyPresetParameter(preset),
                  avatar: const Icon(Icons.add, size: 16),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 应用预设参数
  void _applyPresetParameter(PresetParameter preset) {
    // 根据参数名称确定要填入的字段
    final parameterName = preset.name.toLowerCase();
    double value = preset.value;
    
    // 如果当前单位与预设参数单位不同，进行转换
    if (_currentUnit != preset.unit) {
      value = _parameterService.convertUnit(value, preset.unit, _currentUnit);
    }
    
    if (parameterName.contains('r值')) {
      _rValueController.text = value.toStringAsFixed(2);
      _rValue = value;
    } else if (parameterName.contains('b值')) {
      _bValueController.text = value.toStringAsFixed(2);
      _bValue = value;
    } else if (parameterName.contains('d值')) {
      _dValueController.text = value.toStringAsFixed(2);
      _dValue = value;
    } else if (parameterName.contains('e值')) {
      _eValueController.text = value.toStringAsFixed(2);
      _eValue = value;
    } else if (parameterName.contains('垫子厚度')) {
      _gasketThicknessController.text = value.toStringAsFixed(2);
      _gasketThickness = value;
    } else if (parameterName.contains('初始值')) {
      _initialValueController.text = value.toStringAsFixed(2);
      _initialValue = value;
    }
    
    _validateParameters();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已应用预设参数: ${preset.name}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 构建设备参数区域
  Widget _buildEquipmentParametersSection() {
    return ParameterInputSection(
      title: '设备参数',
      children: [
        NumberInputField(
          label: 'R值 (导向轮到管线距离)',
          unit: _currentUnit.symbol,
          value: _rValue,
          onChanged: (value) {
            setState(() {
              _rValue = value;
            });
            _validateParameters();
          },
          helpText: '导向轮接触管线的距离，根据设备配置确定',
          min: 5.0,
          max: 200.0,
          isRequired: true,
        ),
        NumberInputField(
          label: 'D值 (封堵器到管线距离)',
          unit: _currentUnit.symbol,
          value: _dValue,
          onChanged: (value) {
            setState(() {
              _dValue = value;
            });
            _validateParameters();
          },
          helpText: '封堵器到管线的距离，通常大于R值',
          min: 10.0,
          max: 300.0,
          isRequired: true,
        ),
      ],
    );
  }

  /// 构建管道参数区域
  Widget _buildPipeParametersSection() {
    return ParameterInputSection(
      title: '管道参数',
      children: [
        NumberInputField(
          label: 'B值 (夹板顶到管外壁)',
          unit: _currentUnit.symbol,
          value: _bValue,
          onChanged: (value) {
            setState(() {
              _bValue = value;
            });
            _validateParameters();
          },
          helpText: '夹板顶部到管道外壁的距离',
          min: 2.0,
          max: 100.0,
          isRequired: true,
        ),
        NumberInputField(
          label: 'E值 (管外径减壁厚)',
          unit: _currentUnit.symbol,
          value: _eValue,
          onChanged: (value) {
            setState(() {
              _eValue = value;
            });
            _validateParameters();
          },
          helpText: 'E值 = 管外径 - 壁厚，用于计算管道内径相关参数',
          min: 10.0,
          max: 2000.0,
          isRequired: true,
        ),
      ],
    );
  }

  /// 构建作业参数区域
  Widget _buildOperationParametersSection() {
    return ParameterInputSection(
      title: '作业参数',
      children: [
        NumberInputField(
          label: '垫子厚度',
          unit: _currentUnit.symbol,
          value: _gasketThickness,
          onChanged: (value) {
            setState(() {
              _gasketThickness = value;
            });
            _validateParameters();
          },
          helpText: '密封垫片的厚度，根据垫片规格确定',
          min: 0.0,
          max: 30.0,
          isRequired: true,
        ),
        NumberInputField(
          label: '初始值',
          unit: _currentUnit.symbol,
          value: _initialValue,
          onChanged: (value) {
            setState(() {
              _initialValue = value;
            });
            _validateParameters();
          },
          helpText: '设备初始位置的偏移量，通常为小数值',
          min: 0.0,
          max: 50.0,
          isRequired: true,
        ),
      ],
    );
  }

  /// 构建E值计算提示
  Widget _buildEValueCalculationTip() {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'E值计算说明',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'E值 = 管外径 - 壁厚',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '• 如果E值计算结果为负数，说明壁厚参数可能有误\n'
              '• E值应该接近管道内径的数值\n'
              '• 请确保使用正确的管道规格参数',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建验证结果显示
  Widget _buildValidationResultDisplay() {
    final validation = _validationResult!;
    
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

  /// 构建结果显示
  Widget _buildResultDisplay() {
    if (_calculationResult == null) return const SizedBox.shrink();
    
    return CalculationResultSection(
      result: _calculationResult!,
      onCopyResult: _copyResultToClipboard,
      showCalculationSteps: true,
    );
  }

  /// 复制结果到剪贴板
  void _copyResultToClipboard() {
    if (_calculationResult == null) return;
    
    final buffer = StringBuffer();
    buffer.writeln('封堵计算结果');
    buffer.writeln('=' * 30);
    buffer.writeln('计算时间: ${_calculationResult!.calculationTime}');
    buffer.writeln();
    
    // 核心结果
    final coreResults = _calculationResult!.getCoreResults();
    buffer.writeln('核心结果:');
    for (final entry in coreResults.entries) {
      buffer.writeln('${entry.key}: ${entry.value.toStringAsFixed(2)} ${_calculationResult!.getUnit()}');
    }
    
    // 详细结果
    buffer.writeln();
    buffer.writeln('详细结果:');
    final sealingResult = _calculationResult as SealingResult;
    buffer.writeln('导向轮接触管线行程: ${sealingResult.guideWheelStroke.toStringAsFixed(2)} ${_calculationResult!.getUnit()}');
    buffer.writeln('封堵总行程: ${sealingResult.totalStroke.toStringAsFixed(2)} ${_calculationResult!.getUnit()}');
    
    // 计算公式
    buffer.writeln();
    buffer.writeln('计算公式:');
    final formulas = _calculationResult!.getFormulas();
    for (final entry in formulas.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    
    // 计算步骤
    buffer.writeln();
    buffer.writeln('计算步骤:');
    final params = sealingResult.sealingParameters;
    buffer.writeln('步骤1: 计算导向轮接触管线行程：${params.rValue} + ${params.bValue} + ${params.eValue} + ${params.gasketThickness} + ${params.initialValue} = ${sealingResult.guideWheelStroke.toStringAsFixed(2)}mm');
    buffer.writeln('步骤2: 计算封堵总行程：${params.dValue} + ${params.bValue} + ${params.eValue} + ${params.gasketThickness} + ${params.initialValue} = ${sealingResult.totalStroke.toStringAsFixed(2)}mm');
    
    // 封堵解堵一致性说明
    buffer.writeln();
    buffer.writeln('注意事项:');
    buffer.writeln('• 封堵和解堵使用相同的计算逻辑');
    buffer.writeln('• 确保E值计算正确（E值 = 管外径 - 壁厚）');
    buffer.writeln('• D值应该大于R值，确保封堵器比导向轮更深入');
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('计算结果已复制到剪贴板'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}