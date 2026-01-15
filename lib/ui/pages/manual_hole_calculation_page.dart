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

/// 手动开孔计算页面
/// 
/// 提供手动开孔尺寸计算的完整用户界面，包括参数输入、验证、计算和结果显示
class ManualHoleCalculationPage extends StatefulWidget {
  const ManualHoleCalculationPage({super.key});

  @override
  State<ManualHoleCalculationPage> createState() => _ManualHoleCalculationPageState();
}

class _ManualHoleCalculationPageState extends State<ManualHoleCalculationPage> {
  // 表单键
  final _formKey = GlobalKey<FormState>();
  
  // 参数控制器
  final _lValueController = TextEditingController();
  final _jValueController = TextEditingController();
  final _pValueController = TextEditingController();
  final _tValueController = TextEditingController();
  final _wValueController = TextEditingController();
  
  // 当前参数值
  double? _lValue;
  double? _jValue;
  double? _pValue;
  double? _tValue;
  double? _wValue;
  
  // 当前单位
  UnitType _currentUnit = UnitType.millimeter;
  
  // 计算状态
  bool _isCalculating = false;
  String? _errorMessage;
  ManualHoleResult? _calculationResult;
  
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
    _lValueController.dispose();
    _jValueController.dispose();
    _pValueController.dispose();
    _tValueController.dispose();
    _wValueController.dispose();
    super.dispose();
  }

  /// 加载预设参数
  Future<void> _loadPresetParameters() async {
    setState(() {
      _isLoadingPresets = true;
    });

    try {
      final presets = await _parameterService.getPresetParameters(CalculationType.manualHole);
      
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
    _lValueController.text = '80.0';
    _jValueController.text = '25.0';
    _pValueController.text = '30.0';
    _tValueController.text = '40.0';
    _wValueController.text = '35.0';
    
    // 更新参数值
    _lValue = 80.0;
    _jValue = 25.0;
    _pValue = 30.0;
    _tValue = 40.0;
    _wValue = 35.0;
    
    _validateParameters();
  }

  /// 验证参数
  void _validateParameters() {
    if (_hasAllRequiredParameters()) {
      final parameters = _createManualHoleParameters();
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
    return _lValue != null &&
           _jValue != null &&
           _pValue != null &&
           _tValue != null &&
           _wValue != null;
  }

  /// 创建手动开孔参数对象
  ManualHoleParameters _createManualHoleParameters() {
    return ManualHoleParameters(
      lValue: _lValue!,
      jValue: _jValue!,
      pValue: _pValue!,
      tValue: _tValue!,
      wValue: _wValue!,
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

    final parameters = _createManualHoleParameters();
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
        CalculationType.manualHole,
        parameters.toJson(),
      );

      if (mounted) {
        setState(() {
          _calculationResult = result as ManualHoleResult;
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
          calculationType: CalculationType.manualHole,
          parameters: _createManualHoleParameters(),
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
    if (parameterSet.calculationType != CalculationType.manualHole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('参数组类型不匹配'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final parameters = parameterSet.parameters as ManualHoleParameters;
    
    // 转换单位（如果需要）
    final convertedParameters = _currentUnit == UnitType.millimeter 
        ? parameters 
        : _convertParametersToUnit(parameters, _currentUnit);
    
    // 更新控制器和参数值
    _lValueController.text = convertedParameters.lValue.toStringAsFixed(2);
    _jValueController.text = convertedParameters.jValue.toStringAsFixed(2);
    _pValueController.text = convertedParameters.pValue.toStringAsFixed(2);
    _tValueController.text = convertedParameters.tValue.toStringAsFixed(2);
    _wValueController.text = convertedParameters.wValue.toStringAsFixed(2);
    
    _lValue = convertedParameters.lValue;
    _jValue = convertedParameters.jValue;
    _pValue = convertedParameters.pValue;
    _tValue = convertedParameters.tValue;
    _wValue = convertedParameters.wValue;
    
    _validateParameters();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已加载参数组 "${parameterSet.name}"'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 转换参数到指定单位
  ManualHoleParameters _convertParametersToUnit(ManualHoleParameters parameters, UnitType targetUnit) {
    return ManualHoleParameters(
      lValue: _parameterService.convertUnit(parameters.lValue, UnitType.millimeter, targetUnit),
      jValue: _parameterService.convertUnit(parameters.jValue, UnitType.millimeter, targetUnit),
      pValue: _parameterService.convertUnit(parameters.pValue, UnitType.millimeter, targetUnit),
      tValue: _parameterService.convertUnit(parameters.tValue, UnitType.millimeter, targetUnit),
      wValue: _parameterService.convertUnit(parameters.wValue, UnitType.millimeter, targetUnit),
    );
  }

  /// 切换单位
  void _switchUnit(UnitType newUnit) {
    if (newUnit == _currentUnit) return;
    
    // 转换所有参数值
    if (_lValue != null) {
      _lValue = _parameterService.convertUnit(_lValue!, _currentUnit, newUnit);
      _lValueController.text = _lValue!.toStringAsFixed(2);
    }
    
    if (_jValue != null) {
      _jValue = _parameterService.convertUnit(_jValue!, _currentUnit, newUnit);
      _jValueController.text = _jValue!.toStringAsFixed(2);
    }
    
    if (_pValue != null) {
      _pValue = _parameterService.convertUnit(_pValue!, _currentUnit, newUnit);
      _pValueController.text = _pValue!.toStringAsFixed(2);
    }
    
    if (_tValue != null) {
      _tValue = _parameterService.convertUnit(_tValue!, _currentUnit, newUnit);
      _tValueController.text = _tValue!.toStringAsFixed(2);
    }
    
    if (_wValue != null) {
      _wValue = _parameterService.convertUnit(_wValue!, _currentUnit, newUnit);
      _wValueController.text = _wValue!.toStringAsFixed(2);
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
      title: '手动开孔计算',
      calculationType: CalculationType.manualHole,
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
          
          // 螺纹参数
          _buildThreadParametersSection(),
          
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
            const Icon(Icons.straighten, color: Colors.blue),
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
                Icon(Icons.settings_suggest, color: Colors.blue),
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
    
    if (parameterName.contains('l值')) {
      _lValueController.text = value.toStringAsFixed(2);
      _lValue = value;
    } else if (parameterName.contains('j值')) {
      _jValueController.text = value.toStringAsFixed(2);
      _jValue = value;
    } else if (parameterName.contains('p值')) {
      _pValueController.text = value.toStringAsFixed(2);
      _pValue = value;
    } else if (parameterName.contains('t值')) {
      _tValueController.text = value.toStringAsFixed(2);
      _tValue = value;
    } else if (parameterName.contains('w值')) {
      _wValueController.text = value.toStringAsFixed(2);
      _wValue = value;
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
          label: 'L值',
          unit: _currentUnit.symbol,
          value: _lValue,
          onChanged: (value) {
            setState(() {
              _lValue = value;
            });
            _validateParameters();
          },
          helpText: '设备基础尺寸，从设备基准点到操作起始点的距离',
          min: 10.0,
          max: 500.0,
          isRequired: true,
        ),
        NumberInputField(
          label: 'J值',
          unit: _currentUnit.symbol,
          value: _jValue,
          onChanged: (value) {
            setState(() {
              _jValue = value;
            });
            _validateParameters();
          },
          helpText: '设备调节范围，设备可调节的最大行程',
          min: 5.0,
          max: 200.0,
          isRequired: true,
        ),
        NumberInputField(
          label: 'P值',
          unit: _currentUnit.symbol,
          value: _pValue,
          onChanged: (value) {
            setState(() {
              _pValue = value;
            });
            _validateParameters();
          },
          helpText: '开孔深度，开孔器需要切削的深度',
          min: 5.0,
          max: 150.0,
          isRequired: true,
        ),
      ],
    );
  }

  /// 构建螺纹参数区域
  Widget _buildThreadParametersSection() {
    return ParameterInputSection(
      title: '螺纹参数',
      children: [
        NumberInputField(
          label: 'T值 (螺纹长度)',
          unit: _currentUnit.symbol,
          value: _tValue,
          onChanged: (value) {
            setState(() {
              _tValue = value;
            });
            _validateParameters();
          },
          helpText: '螺纹连接的总长度，使用螺纹规或卡尺测量',
          min: 5.0,
          max: 100.0,
          isRequired: true,
        ),
        NumberInputField(
          label: 'W值 (螺纹深度)',
          unit: _currentUnit.symbol,
          value: _wValue,
          onChanged: (value) {
            setState(() {
              _wValue = value;
            });
            _validateParameters();
          },
          helpText: '螺纹实际啮合深度，通常小于T值',
          min: 3.0,
          max: 80.0,
          isRequired: true,
        ),
        // 螺纹咬合尺寸预览
        if (_tValue != null && _wValue != null)
          _buildThreadEngagementPreview(),
      ],
    );
  }

  /// 构建螺纹咬合尺寸预览
  Widget _buildThreadEngagementPreview() {
    final threadEngagement = _tValue! - _wValue!;
    
    Color textColor;
    IconData icon;
    String message;
    
    if (threadEngagement < 0) {
      textColor = Colors.red;
      icon = Icons.error;
      message = '螺纹咬合尺寸为负值 (${threadEngagement.toStringAsFixed(2)} ${_currentUnit.symbol})';
    } else if (threadEngagement < 3.0) {
      textColor = Colors.orange;
      icon = Icons.warning;
      message = '螺纹咬合尺寸较小 (${threadEngagement.toStringAsFixed(2)} ${_currentUnit.symbol})，可能影响连接强度';
    } else {
      textColor = Colors.green;
      icon = Icons.check_circle;
      message = '螺纹咬合尺寸正常 (${threadEngagement.toStringAsFixed(2)} ${_currentUnit.symbol})';
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.1),
        border: Border.all(color: textColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontSize: 14),
            ),
          ),
        ],
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
    buffer.writeln('手动开孔计算结果');
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
    final manualResult = _calculationResult as ManualHoleResult;
    buffer.writeln('螺纹咬合尺寸: ${manualResult.threadEngagement.toStringAsFixed(2)} ${_calculationResult!.getUnit()}');
    buffer.writeln('空行程: ${manualResult.emptyStroke.toStringAsFixed(2)} ${_calculationResult!.getUnit()}');
    buffer.writeln('总行程: ${manualResult.totalStroke.toStringAsFixed(2)} ${_calculationResult!.getUnit()}');
    
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
    final params = manualResult.manualHoleParameters;
    buffer.writeln('步骤1: 计算螺纹咬合尺寸：${params.tValue} - ${params.wValue} = ${manualResult.threadEngagement.toStringAsFixed(2)}mm');
    buffer.writeln('步骤2: 计算空行程：${params.lValue} + ${params.jValue} + ${params.tValue} + ${params.wValue} = ${manualResult.emptyStroke.toStringAsFixed(2)}mm');
    buffer.writeln('步骤3: 计算总行程：${params.lValue} + ${params.jValue} + ${params.tValue} + ${params.wValue} + ${params.pValue} = ${manualResult.totalStroke.toStringAsFixed(2)}mm');
    
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