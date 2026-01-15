import 'dart:convert';
import 'dart:math';
import '../models/parameter_models.dart';
import '../models/calculation_parameters.dart';
import '../models/enums.dart';
import '../models/validation_result.dart';
import '../utils/validators.dart';
import '../utils/unit_converter.dart';

/// 参数管理器类
/// 
/// 负责管理预设参数、自定义参数组和单位转换等功能
class ParameterManager {
  /// 预设参数缓存
  static final Map<CalculationType, List<PresetParameter>> _presetCache = {};
  
  /// 单例实例
  static ParameterManager? _instance;
  
  /// 获取单例实例
  static ParameterManager get instance {
    _instance ??= ParameterManager._internal();
    return _instance!;
  }
  
  /// 私有构造函数
  ParameterManager._internal();

  /// 获取预设参数列表
  /// 
  /// [type] 计算类型
  /// 
  /// 返回适用于指定计算类型的预设参数列表
  List<PresetParameter> getPresetParameters(CalculationType type) {
    // 如果缓存中有数据，直接返回
    if (_presetCache.containsKey(type)) {
      return List<PresetParameter>.from(_presetCache[type]!);
    }
    
    // 初始化预设参数
    _initializePresetParametersForType(type);
    
    return List<PresetParameter>.from(_presetCache[type] ?? []);
  }

  /// 获取所有预设参数
  /// 
  /// 返回所有预设参数的列表
  List<PresetParameter> getAllPresetParameters() {
    final allPresets = <PresetParameter>[];
    
    for (final type in CalculationType.values) {
      allPresets.addAll(getPresetParameters(type));
    }
    
    return allPresets;
  }

  /// 单位转换
  /// 
  /// [value] 要转换的数值
  /// [from] 源单位
  /// [to] 目标单位
  /// 
  /// 返回转换后的数值
  double convertUnit(double value, UnitType from, UnitType to) {
    return UnitConverter.convert(value, from, to);
  }

  /// 批量单位转换
  /// 
  /// [parameters] 参数映射（参数名 -> 数值）
  /// [from] 源单位
  /// [to] 目标单位
  /// 
  /// 返回转换后的参数映射
  Map<String, double> convertParameters(
    Map<String, double> parameters, 
    UnitType from, 
    UnitType to,
  ) {
    return UnitConverter.convertParameters(parameters, from, to);
  }

  /// 转换计算参数对象
  /// 
  /// [parameters] 计算参数对象
  /// [targetUnit] 目标单位
  /// 
  /// 返回转换后的计算参数对象
  CalculationParameters convertCalculationParameters(
    CalculationParameters parameters,
    UnitType targetUnit,
  ) {
    if (parameters is HoleParameters) {
      return UnitConverter.convertHoleParameters(parameters, targetUnit);
    } else if (parameters is ManualHoleParameters) {
      return UnitConverter.convertManualHoleParameters(parameters, targetUnit);
    } else if (parameters is SealingParameters) {
      return UnitConverter.convertSealingParameters(parameters, targetUnit);
    } else if (parameters is PlugParameters) {
      return UnitConverter.convertPlugParameters(parameters, targetUnit);
    } else if (parameters is StemParameters) {
      return UnitConverter.convertStemParameters(parameters, targetUnit);
    } else {
      throw ArgumentError('不支持的参数类型: ${parameters.runtimeType}');
    }
  }

  /// 验证参数组名称
  /// 
  /// [name] 参数组名称
  /// 
  /// 返回验证结果
  ValidationResult validateParameterSetName(String name) {
    return Validators.validateParameterSetName(name);
  }

  /// 生成参数组ID
  /// 
  /// 返回唯一的参数组ID
  String generateParameterSetId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'param_${timestamp}_$random';
  }

  /// 创建参数组
  /// 
  /// [name] 参数组名称
  /// [calculationType] 计算类型
  /// [parameters] 参数数据
  /// [description] 参数组描述
  /// [tags] 参数组标签
  /// 
  /// 返回创建的参数组
  ParameterSet createParameterSet({
    required String name,
    required CalculationType calculationType,
    required CalculationParameters parameters,
    String? description,
    List<String> tags = const [],
  }) {
    return ParameterSet(
      id: generateParameterSetId(),
      name: name,
      calculationType: calculationType,
      parameters: parameters,
      description: description,
      tags: List<String>.from(tags),
    );
  }

  /// 为指定计算类型初始化预设参数
  void _initializePresetParametersForType(CalculationType type) {
    switch (type) {
      case CalculationType.hole:
        _presetCache[type] = _createHolePresetParameters();
        break;
      case CalculationType.manualHole:
        _presetCache[type] = _createManualHolePresetParameters();
        break;
      case CalculationType.sealing:
        _presetCache[type] = _createSealingPresetParameters();
        break;
      case CalculationType.plug:
        _presetCache[type] = _createPlugPresetParameters();
        break;
      case CalculationType.stem:
        _presetCache[type] = _createStemPresetParameters();
        break;
    }
  }

  /// 创建开孔计算预设参数
  List<PresetParameter> _createHolePresetParameters() {
    return [
      // 常用管外径
      const PresetParameter(
        name: '管外径 - 小型管道',
        value: 60.3,
        unit: UnitType.millimeter,
        description: '小型管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - 中型管道',
        value: 114.3,
        unit: UnitType.millimeter,
        description: '中型管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - 大型管道',
        value: 219.1,
        unit: UnitType.millimeter,
        description: '大型管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      
      // 常用管内径
      const PresetParameter(
        name: '管内径 - 小型管道',
        value: 52.5,
        unit: UnitType.millimeter,
        description: '小型管道标准内径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管内径 - 中型管道',
        value: 102.3,
        unit: UnitType.millimeter,
        description: '中型管道标准内径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管内径 - 大型管道',
        value: 206.4,
        unit: UnitType.millimeter,
        description: '大型管道标准内径',
        applicableTypes: [CalculationType.hole],
      ),
      
      // 常用筒刀规格
      const PresetParameter(
        name: '筒刀外径 - 标准规格',
        value: 25.4,
        unit: UnitType.millimeter,
        description: '标准筒刀外径规格',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '筒刀内径 - 标准规格',
        value: 19.1,
        unit: UnitType.millimeter,
        description: '标准筒刀内径规格',
        applicableTypes: [CalculationType.hole],
      ),
      
      // 常用垫片厚度
      const PresetParameter(
        name: '垫片厚度 - 薄型',
        value: 1.5,
        unit: UnitType.millimeter,
        description: '薄型垫片标准厚度',
        applicableTypes: [CalculationType.hole, CalculationType.sealing, CalculationType.stem],
      ),
      const PresetParameter(
        name: '垫片厚度 - 标准',
        value: 3.0,
        unit: UnitType.millimeter,
        description: '标准垫片厚度',
        applicableTypes: [CalculationType.hole, CalculationType.sealing, CalculationType.stem],
      ),
      const PresetParameter(
        name: '垫片厚度 - 厚型',
        value: 6.0,
        unit: UnitType.millimeter,
        description: '厚型垫片标准厚度',
        applicableTypes: [CalculationType.hole, CalculationType.sealing, CalculationType.stem],
      ),
    ];
  }

  /// 创建手动开孔计算预设参数
  List<PresetParameter> _createManualHolePresetParameters() {
    return [
      // 常用L值
      const PresetParameter(
        name: 'L值 - 标准设置',
        value: 50.0,
        unit: UnitType.millimeter,
        description: '手动开孔机标准L值设置',
        applicableTypes: [CalculationType.manualHole],
      ),
      
      // 常用J值
      const PresetParameter(
        name: 'J值 - 标准设置',
        value: 25.0,
        unit: UnitType.millimeter,
        description: '手动开孔机标准J值设置',
        applicableTypes: [CalculationType.manualHole],
      ),
      
      // 常用T值
      const PresetParameter(
        name: 'T值 - 标准螺纹',
        value: 15.0,
        unit: UnitType.millimeter,
        description: '标准螺纹T值设置',
        applicableTypes: [CalculationType.manualHole, CalculationType.plug],
      ),
      
      // 常用W值
      const PresetParameter(
        name: 'W值 - 标准螺纹',
        value: 8.0,
        unit: UnitType.millimeter,
        description: '标准螺纹W值设置',
        applicableTypes: [CalculationType.manualHole, CalculationType.plug],
      ),
      
      // 常用P值
      const PresetParameter(
        name: 'P值 - 标准设置',
        value: 30.0,
        unit: UnitType.millimeter,
        description: '手动开孔机标准P值设置',
        applicableTypes: [CalculationType.manualHole],
      ),
    ];
  }

  /// 创建封堵计算预设参数
  List<PresetParameter> _createSealingPresetParameters() {
    return [
      // 常用R值
      const PresetParameter(
        name: 'R值 - 标准设置',
        value: 20.0,
        unit: UnitType.millimeter,
        description: '封堵作业标准R值设置',
        applicableTypes: [CalculationType.sealing],
      ),
      
      // 常用B值
      const PresetParameter(
        name: 'B值 - 标准设置',
        value: 15.0,
        unit: UnitType.millimeter,
        description: '封堵作业标准B值设置',
        applicableTypes: [CalculationType.sealing],
      ),
      
      // 常用D值
      const PresetParameter(
        name: 'D值 - 标准设置',
        value: 40.0,
        unit: UnitType.millimeter,
        description: '封堵作业标准D值设置',
        applicableTypes: [CalculationType.sealing],
      ),
      
      // 常用初始值
      const PresetParameter(
        name: '初始值 - 标准设置',
        value: 5.0,
        unit: UnitType.millimeter,
        description: '封堵作业标准初始值设置',
        applicableTypes: [CalculationType.sealing, CalculationType.stem],
      ),
    ];
  }

  /// 创建下塞堵计算预设参数
  List<PresetParameter> _createPlugPresetParameters() {
    return [
      // 常用M值
      const PresetParameter(
        name: 'M值 - 标准设置',
        value: 35.0,
        unit: UnitType.millimeter,
        description: '下塞堵作业标准M值设置',
        applicableTypes: [CalculationType.plug],
      ),
      
      // 常用K值
      const PresetParameter(
        name: 'K值 - 标准设置',
        value: 20.0,
        unit: UnitType.millimeter,
        description: '下塞堵作业标准K值设置',
        applicableTypes: [CalculationType.plug],
      ),
      
      // 常用N值
      const PresetParameter(
        name: 'N值 - 标准设置',
        value: 25.0,
        unit: UnitType.millimeter,
        description: '下塞堵作业标准N值设置',
        applicableTypes: [CalculationType.plug],
      ),
    ];
  }

  /// 创建下塞柄计算预设参数
  List<PresetParameter> _createStemPresetParameters() {
    return [
      // 常用F值
      const PresetParameter(
        name: 'F值 - 标准设置',
        value: 30.0,
        unit: UnitType.millimeter,
        description: '下塞柄作业标准F值设置',
        applicableTypes: [CalculationType.stem],
      ),
      
      // 常用G值
      const PresetParameter(
        name: 'G值 - 标准设置',
        value: 25.0,
        unit: UnitType.millimeter,
        description: '下塞柄作业标准G值设置',
        applicableTypes: [CalculationType.stem],
      ),
      
      // 常用H值
      const PresetParameter(
        name: 'H值 - 标准设置',
        value: 20.0,
        unit: UnitType.millimeter,
        description: '下塞柄作业标准H值设置',
        applicableTypes: [CalculationType.stem],
      ),
    ];
  }

  /// 清除预设参数缓存
  void clearPresetCache() {
    _presetCache.clear();
  }

  /// 重新加载预设参数
  void reloadPresetParameters() {
    clearPresetCache();
    // 重新初始化所有类型的预设参数
    for (final type in CalculationType.values) {
      _initializePresetParametersForType(type);
    }
  }

  /// 格式化数值显示
  /// 
  /// [value] 数值
  /// [unit] 单位
  /// 
  /// 返回格式化后的字符串
  String formatValue(double value, UnitType unit) {
    return UnitConverter.formatValue(value, unit);
  }

  /// 智能格式化数值
  /// 
  /// [value] 数值
  /// [unit] 单位
  /// 
  /// 返回根据单位类型智能格式化的字符串
  String smartFormatValue(double value, UnitType unit) {
    return UnitConverter.smartFormat(value, unit);
  }

  /// 获取单位转换系数
  /// 
  /// [from] 源单位
  /// [to] 目标单位
  /// 
  /// 返回转换系数
  double getConversionFactor(UnitType from, UnitType to) {
    return UnitConverter.getConversionFactor(from, to);
  }

  /// 验证单位转换精度
  /// 
  /// [value] 原始值
  /// [from] 源单位
  /// [to] 目标单位
  /// 
  /// 返回往返转换的精度损失百分比
  double validateConversionPrecision(double value, UnitType from, UnitType to) {
    return UnitConverter.validateConversionPrecision(value, from, to);
  }

  /// 检查转换精度是否可接受
  /// 
  /// [value] 原始值
  /// [from] 源单位
  /// [to] 目标单位
  /// 
  /// 返回精度是否可接受
  bool isConversionPrecisionAcceptable(double value, UnitType from, UnitType to) {
    return UnitConverter.isConversionPrecisionAcceptable(value, from, to);
  }

  /// 检查参数值是否在合理范围内
  /// 
  /// [value] 参数值
  /// [parameterName] 参数名称
  /// [calculationType] 计算类型
  /// 
  /// 返回验证结果
  ValidationResult validateParameterRange(
    double value, 
    String parameterName, 
    CalculationType calculationType,
  ) {
    // 基本范围检查
    if (value < 0) {
      return ValidationResult.error('$parameterName 不能为负数');
    }
    
    if (value == 0) {
      return ValidationResult.error('$parameterName 不能为零');
    }
    
    // 根据参数类型进行具体范围检查
    switch (parameterName.toLowerCase()) {
      case '管外径':
      case 'outer_diameter':
        if (value < 10.0 || value > 2000.0) {
          return ValidationResult.warning('管外径建议在10-2000mm范围内');
        }
        break;
        
      case '管内径':
      case 'inner_diameter':
        if (value < 5.0 || value > 1900.0) {
          return ValidationResult.warning('管内径建议在5-1900mm范围内');
        }
        break;
        
      case '筒刀外径':
      case 'cutter_outer_diameter':
        if (value < 5.0 || value > 100.0) {
          return ValidationResult.warning('筒刀外径建议在5-100mm范围内');
        }
        break;
        
      case '垫片厚度':
      case 'gasket_thickness':
        if (value > 20.0) {
          return ValidationResult.warning('垫片厚度过大，请检查是否正确');
        }
        break;
    }
    
    return ValidationResult.success();
  }
}