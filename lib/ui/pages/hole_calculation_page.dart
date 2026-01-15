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

/// 开孔计算页面
/// 
/// 提供开孔尺寸计算的完整用户界面，包括参数输入、验证、计算和结果显示
class HoleCalculationPage extends StatefulWidget {
  const HoleCalculationPage({super.key});

  @override
  State<HoleCalculationPage> createState() => _HoleCalculationPageState();
}

class _HoleCalculationPageState extends State<HoleCalculationPage> {
  // 表单键
  final _formKey = GlobalKey<FormState>();
  
  // 参数控制器
  final _outerDiameterController = TextEditingController();
  final _innerDiameterController = TextEditingController();
  final _cutterOuterDiameterController = TextEditingController();
  final _cutterInnerDiameterController = TextEditingController();
  final _aValueController = TextEditingController();
  final _bValueController = TextEditingController();
  final _rValueController = TextEditingController();
  final _initialValueController = TextEditingController();
  final _gasketThicknessController = TextEditingController();
  
  // 当前参数值
  double? _outerDiameter;
  double? _innerDiameter;
  double? _cutterOuterDiameter;
  double? _cutterInnerDiameter;
  double? _aValue;
  double? _bValue;
  double? _rValue;
  double? _initialValue;
  double? _gasketThickness;
  
  // 当前单位
  UnitType _currentUnit = UnitType.millimeter;
  
  // 计算状态
  bool _isCalculating = false;
  String? _errorMessage;
  HoleCalculationResult? _calculationResult;
  
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
    _outerDiameterController.dispose();
    _innerDiameterController.dispose();
    _cutterOuterDiameterController.dispose();
    _cutterInnerDiameterController.dispose();
    _aValueController.dispose();
    _bValueController.dispose();
    _rValueController.dispose();
    _initialValueController.dispose();
    _gasketThicknessController.dispose();
    super.dispose();
  }

  /// 加载预设参数
  Future<void> _loadPresetParameters() async {
    setState(() {
      _isLoadingPresets = true;
    });

    try {
      final presets = await _parameterService.getPresetParameters(CalculationType.hole);
      
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
    _outerDiameterController.text = '114.3'; // DN100
    _innerDiameterController.text = '102.3';
    _cutterOuterDiameterController.text = '25.4'; // 1英寸
    _cutterInnerDiameterController.text = '19.1'; // 3/4英寸
    _aValueController.text = '50.0';
    _bValueController.text = '15.0';
    _rValueController.text = '20.0';
    _initialValueController.text = '5.0';
    _gasketThicknessController.text = '3.0';
    
    // 更新参数值
    _outerDiameter = 114.3;
    _innerDiameter = 102.3;
    _cutterOuterDiameter = 25.4;
    _cutterInnerDiameter = 19.1;
    _aValue = 50.0;
    _bValue = 15.0;
    _rValue = 20.0;
    _initialValue = 5.0;
    _gasketThickness = 3.0;
    
    _validateParameters();
  }

  /// 验证参数
  void _validateParameters() {
    if (_hasAllRequiredParameters()) {
      final parameters = _createHoleParameters();
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
    return _outerDiameter != null &&
           _innerDiameter != null &&
           _cutterOuterDiameter != null &&
           _cutterInnerDiameter != null &&
           _aValue != null &&
           _bValue != null &&
           _rValue != null &&
           _initialValue != null &&
           _gasketThickness != null;
  }

  /// 创建开孔参数对象
  HoleParameters _createHoleParameters() {
    return HoleParameters(
      outerDiameter: _outerDiameter!,
      innerDiameter: _innerDiameter!,
      cutterOuterDiameter: _cutterOuterDiameter!,
      cutterInnerDiameter: _cutterInnerDiameter!,
      aValue: _aValue!,
      bValue: _bValue!,
      rValue: _rValue!,
      initialValue: _initialValue!,
      gasketThickness: _gasketThickness!,
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

    final parameters = _createHoleParameters();
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
        CalculationType.hole,
        parameters.toJson(),
      );

      if (mounted) {
        setState(() {
          _calculationResult = result as HoleCalculationResult;
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
          calculationType: CalculationType.hole,
          parameters: _createHoleParameters(),
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
    if (parameterSet.calculationType != CalculationType.hole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('参数组类型不匹配'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final parameters = parameterSet.parameters as HoleParameters;
    
    // 转换单位（如果需要）
    final convertedParameters = _currentUnit == UnitType.millimeter 
        ? parameters 
        : _convertParametersToUnit(parameters, _currentUnit);
    
    // 更新控制器和参数值
    _outerDiameterController.text = convertedParameters.outerDiameter.toStringAsFixed(2);
    _innerDiameterController.text = convertedParameters.innerDiameter.toStringAsFixed(2);
    _cutterOuterDiameterController.text = convertedParameters.cutterOuterDiameter.toStringAsFixed(2);
    _cutterInnerDiameterController.text = convertedParameters.cutterInnerDiameter.toStringAsFixed(2);
    _aValueController.text = convertedParameters.aValue.toStringAsFixed(2);
    _bValueController.text = convertedParameters.bValue.toStringAsFixed(2);
    _rValueController.text = convertedParameters.rValue.toStringAsFixed(2);
    _initialValueController.text = convertedParameters.initialValue.toStringAsFixed(2);
    _gasketThicknessController.text = convertedParameters.gasketThickness.toStringAsFixed(2);
    
    _outerDiameter = convertedParameters.outerDiameter;
    _innerDiameter = convertedParameters.innerDiameter;
    _cutterOuterDiameter = convertedParameters.cutterOuterDiameter;
    _cutterInnerDiameter = convertedParameters.cutterInnerDiameter;
    _aValue = convertedParameters.aValue;
    _bValue = convertedParameters.bValue;
    _rValue = convertedParameters.rValue;
    _initialValue = convertedParameters.initialValue;
    _gasketThickness = convertedParameters.gasketThickness;
    
    _validateParameters();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已加载参数组 "${parameterSet.name}"'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 转换参数到指定单位
  HoleParameters _convertParametersToUnit(HoleParameters parameters, UnitType targetUnit) {
    return HoleParameters(
      outerDiameter: _parameterService.convertUnit(parameters.outerDiameter, UnitType.millimeter, targetUnit),
      innerDiameter: _parameterService.convertUnit(parameters.innerDiameter, UnitType.millimeter, targetUnit),
      cutterOuterDiameter: _parameterService.convertUnit(parameters.cutterOuterDiameter, UnitType.millimeter, targetUnit),
      cutterInnerDiameter: _parameterService.convertUnit(parameters.cutterInnerDiameter, UnitType.millimeter, targetUnit),
      aValue: _parameterService.convertUnit(parameters.aValue, UnitType.millimeter, targetUnit),
      bValue: _parameterService.convertUnit(parameters.bValue, UnitType.millimeter, targetUnit),
      rValue: _parameterService.convertUnit(parameters.rValue, UnitType.millimeter, targetUnit),
      initialValue: _parameterService.convertUnit(parameters.initialValue, UnitType.millimeter, targetUnit),
      gasketThickness: _parameterService.convertUnit(parameters.gasketThickness, UnitType.millimeter, targetUnit),
    );
  }

  /// 切换单位
  void _switchUnit(UnitType newUnit) {
    if (newUnit == _currentUnit) return;
    
    // 转换所有参数值
    if (_outerDiameter != null) {
      _outerDiameter = _parameterService.convertUnit(_outerDiameter!, _currentUnit, newUnit);
      _outerDiameterController.text = _outerDiameter!.toStringAsFixed(2);
    }
    
    if (_innerDiameter != null) {
      _innerDiameter = _parameterService.convertUnit(_innerDiameter!, _currentUnit, newUnit);
      _innerDiameterController.text = _innerDiameter!.toStringAsFixed(2);
    }
    
    if (_cutterOuterDiameter != null) {
      _cutterOuterDiameter = _parameterService.convertUnit(_cutterOuterDiameter!, _currentUnit, newUnit);
      _cutterOuterDiameterController.text = _cutterOuterDiameter!.toStringAsFixed(2);
    }
    
    if (_cutterInnerDiameter != null) {
      _cutterInnerDiameter = _parameterService.convertUnit(_cutterInnerDiameter!, _currentUnit, newUnit);
      _cutterInnerDiameterController.text = _cutterInnerDiameter!.toStringAsFixed(2);
    }
    
    if (_aValue != null) {
      _aValue = _parameterService.convertUnit(_aValue!, _currentUnit, newUnit);
      _aValueController.text = _aValue!.toStringAsFixed(2);
    }
    
    if (_bValue != null) {
      _bValue = _parameterService.convertUnit(_bValue!, _currentUnit, newUnit);
      _bValueController.text = _bValue!.toStringAsFixed(2);
    }
    
    if (_rValue != null) {
      _rValue = _parameterService.convertUnit(_rValue!, _currentUnit, newUnit);
      _rValueController.text = _rValue!.toStringAsFixed(2);
    }
    
    if (_initialValue != null) {
      _initialValue = _parameterService.convertUnit(_initialValue!, _currentUnit, newUnit);
      _initialValueController.text = _initialValue!.toStringAsFixed(2);
    }
    
    if (_gasketThickness != null) {
      _gasketThickness = _parameterService.convertUnit(_gasketThickness!, _currentUnit, newUnit);
      _gasketThicknessController.text = _gasketThickness!.toStringAsFixed(2);
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
      title: '开孔尺寸计算',
      calculationType: CalculationType.hole,
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
          
          // 管道参数
          _buildPipeParametersSection(),
          
          const SizedBox(height: 16),
          
          // 筒刀参数
          _buildCutterParametersSection(),
          
          const SizedBox(height: 16),
          
          // 作业参数
          _buildOperationParametersSection(),
          
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
            const Icon(Icons.straighten, color: Colors.orange),
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
                Icon(Icons.settings_suggest, color: Colors.orange),
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
    
    if (parameterName.contains('管外径')) {
      _outerDiameterController.text = value.toStringAsFixed(2);
      _outerDiameter = value;
    } else if (parameterName.contains('管内径')) {
      _innerDiameterController.text = value.toStringAsFixed(2);
      _innerDiameter = value;
    } else if (parameterName.contains('筒刀外径')) {
      _cutterOuterDiameterController.text = value.toStringAsFixed(2);
      _cutterOuterDiameter = value;
    } else if (parameterName.contains('筒刀内径')) {
      _cutterInnerDiameterController.text = value.toStringAsFixed(2);
      _cutterInnerDiameter = value;
    } else if (parameterName.contains('a值')) {
      _aValueController.text = value.toStringAsFixed(2);
      _aValue = value;
    } else if (parameterName.contains('b值')) {
      _bValueController.text = value.toStringAsFixed(2);
      _bValue = value;
    } else if (parameterName.contains('r值')) {
      _rValueController.text = value.toStringAsFixed(2);
      _rValue = value;
    } else if (parameterName.contains('初始值')) {
      _initialValueController.text = value.toStringAsFixed(2);
      _initialValue = value;
    } else if (parameterName.contains('垫片厚度')) {
      _gasketThicknessController.text = value.toStringAsFixed(2);
      _gasketThickness = value;
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

  /// 构建管道参数区域
  Widget _buildPipeParametersSection() {
    return ParameterInputSection(
      title: '管道参数',
      children: [
        NumberInputField(
          label: '管外径',
          unit: _currentUnit.symbol,
          value: _outerDiameter,
          onChanged: (value) {
            setState(() {
              _outerDiameter = value;
            });
            _validateParameters();
          },
          helpText: '管道的外径尺寸，通常根据管道规格确定',
          min: 10.0,
          max: 2000.0,
          isRequired: true,
        ),
        NumberInputField(
          label: '管内径',
          unit: _currentUnit.symbol,
          value: _innerDiameter,
          onChanged: (value) {
            setState(() {
              _innerDiameter = value;
            });
            _validateParameters();
          },
          helpText: '管道的内径尺寸，等于外径减去两倍壁厚',
          min: 5.0,
          max: 1900.0,
          isRequired: true,
        ),
      ],
    );
  }

  /// 构建筒刀参数区域
  Widget _buildCutterParametersSection() {
    return ParameterInputSection(
      title: '筒刀参数',
      children: [
        NumberInputField(
          label: '筒刀外径',
          unit: _currentUnit.symbol,
          value: _cutterOuterDiameter,
          onChanged: (value) {
            setState(() {
              _cutterOuterDiameter = value;
            });
            _validateParameters();
          },
          helpText: '筒刀的外径尺寸，根据筒刀规格确定',
          min: 5.0,
          max: 100.0,
          isRequired: true,
        ),
        NumberInputField(
          label: '筒刀内径',
          unit: _currentUnit.symbol,
          value: _cutterInnerDiameter,
          onChanged: (value) {
            setState(() {
              _cutterInnerDiameter = value;
            });
            _validateParameters();
          },
          helpText: '筒刀的内径尺寸，决定开孔的最终尺寸',
          min: 3.0,
          max: 95.0,
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
          label: 'A值 (中心钻关联联箱口)',
          unit: _currentUnit.symbol,
          value: _aValue,
          onChanged: (value) {
            setState(() {
              _aValue = value;
            });
            _validateParameters();
          },
          helpText: '中心钻关联联箱口的距离，根据设备配置确定',
          min: 5.0,
          max: 300.0,
          isRequired: true,
        ),
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
          max: 150.0,
          isRequired: true,
        ),
        NumberInputField(
          label: 'R值 (中心钻尖到筒刀)',
          unit: _currentUnit.symbol,
          value: _rValue,
          onChanged: (value) {
            setState(() {
              _rValue = value;
            });
            _validateParameters();
          },
          helpText: '中心钻尖端到筒刀的距离',
          min: 2.0,
          max: 100.0,
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
        NumberInputField(
          label: '垫片厚度',
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
          max: 20.0,
          isRequired: true,
        ),
      ],
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
    buffer.writeln('开孔尺寸计算结果');
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
    final holeResult = _calculationResult as HoleCalculationResult;
    buffer.writeln('空行程: ${holeResult.emptyStroke.toStringAsFixed(2)} ${_calculationResult!.getUnit()}');
    buffer.writeln('筒刀切削距离: ${holeResult.cuttingDistance.toStringAsFixed(2)} ${_calculationResult!.getUnit()}');
    buffer.writeln('掉板弦高: ${holeResult.chordHeight.toStringAsFixed(2)} ${_calculationResult!.getUnit()}');
    buffer.writeln('切削尺寸: ${holeResult.cuttingSize.toStringAsFixed(2)} ${_calculationResult!.getUnit()}');
    buffer.writeln('开孔总行程: ${holeResult.totalStroke.toStringAsFixed(2)} ${_calculationResult!.getUnit()}');
    buffer.writeln('掉板总行程: ${holeResult.plateStroke.toStringAsFixed(2)} ${_calculationResult!.getUnit()}');
    
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
    final steps = holeResult.getCalculationSteps();
    for (final entry in steps.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    
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