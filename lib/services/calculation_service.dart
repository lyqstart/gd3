import '../models/calculation_result.dart';
import '../models/calculation_parameters.dart';
import '../models/validation_result.dart';
import '../models/enums.dart';
import 'interfaces/i_calculation_service.dart';
import 'calculation_engine.dart';

/// 计算服务实现类
class CalculationService implements ICalculationService {
  /// 计算引擎实例
  final CalculationEngine _engine;

  /// 构造函数
  CalculationService({CalculationEngine? engine}) 
      : _engine = engine ?? PrecisionCalculationEngine();

  @override
  Future<CalculationResult> calculate(
    CalculationType type, 
    Map<String, dynamic> parameters,
  ) async {
    try {
      // 将JSON参数转换为强类型参数对象
      final parameterObject = CalculationParameters.fromJson(parameters, type);
      
      // 验证参数
      final validation = await validateParameters(type, parameters);
      if (!validation.isValid) {
        throw ArgumentError('参数验证失败: ${validation.message}');
      }

      // 根据计算类型执行相应的计算
      switch (type) {
        case CalculationType.hole:
          return _engine.calculateHoleSize(parameterObject as HoleParameters);
        case CalculationType.manualHole:
          return _engine.calculateManualHole(parameterObject as ManualHoleParameters);
        case CalculationType.sealing:
          return _engine.calculateSealing(parameterObject as SealingParameters);
        case CalculationType.plug:
          return _engine.calculatePlug(parameterObject as PlugParameters);
        case CalculationType.stem:
          return _engine.calculateStem(parameterObject as StemParameters);
      }
    } catch (e) {
      if (e is CalculationException) {
        rethrow;
      }
      throw CalculationException('计算过程中发生错误: $e');
    }
  }

  @override
  Future<ValidationResult> validateParameters(
    CalculationType type, 
    Map<String, dynamic> parameters,
  ) async {
    try {
      // 将JSON参数转换为强类型参数对象并验证
      final parameterObject = CalculationParameters.fromJson(parameters, type);
      return parameterObject.validate();
    } catch (e) {
      return ValidationResult.error('参数格式错误: $e');
    }
  }

  @override
  List<CalculationType> getSupportedCalculationTypes() {
    return CalculationType.values;
  }

  @override
  Map<String, dynamic> getParameterTemplate(CalculationType type) {
    switch (type) {
      case CalculationType.hole:
        return {
          'outer_diameter': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': '管道外径',
            'example': 114.3,
          },
          'inner_diameter': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': '管道内径',
            'example': 102.3,
          },
          'cutter_outer_diameter': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': '筒刀外径',
            'example': 25.4,
          },
          'cutter_inner_diameter': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': '筒刀内径',
            'example': 19.1,
          },
          'a_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'A值 - 中心钻关联联箱口',
            'example': 50.0,
          },
          'b_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'B值 - 夹板顶到管外壁',
            'example': 30.0,
          },
          'r_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'R值 - 中心钻尖到筒刀',
            'example': 15.0,
          },
          'initial_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': '初始值',
            'example': 10.0,
          },
          'gasket_thickness': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': '垫片厚度',
            'example': 3.0,
          },
        };
      case CalculationType.manualHole:
        return {
          'l_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'L值',
            'example': 100.0,
          },
          'j_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'J值',
            'example': 50.0,
          },
          'p_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'P值',
            'example': 25.0,
          },
          't_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'T值',
            'example': 20.0,
          },
          'w_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'W值',
            'example': 15.0,
          },
        };
      case CalculationType.sealing:
        return {
          'r_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'R值',
            'example': 15.0,
          },
          'b_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'B值',
            'example': 30.0,
          },
          'd_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'D值',
            'example': 80.0,
          },
          'e_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'E值 - 管外径减壁厚',
            'example': 108.0,
          },
          'gasket_thickness': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': '垫子厚度',
            'example': 3.0,
          },
          'initial_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': '初始值',
            'example': 10.0,
          },
        };
      case CalculationType.plug:
        return {
          'm_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'M值',
            'example': 120.0,
          },
          'k_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'K值',
            'example': 60.0,
          },
          'n_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'N值',
            'example': 40.0,
          },
          't_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'T值',
            'example': 20.0,
          },
          'w_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'W值',
            'example': 15.0,
          },
        };
      case CalculationType.stem:
        return {
          'f_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'F值',
            'example': 80.0,
          },
          'g_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'G值',
            'example': 60.0,
          },
          'h_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': 'H值',
            'example': 40.0,
          },
          'gasket_thickness': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': '垫子厚度',
            'example': 3.0,
          },
          'initial_value': {
            'type': 'double', 
            'required': true, 
            'min': 0.0, 
            'unit': 'mm',
            'description': '初始值',
            'example': 10.0,
          },
        };
    }
  }

  @override
  double getPrecisionThreshold() {
    return _engine.getPrecisionThreshold();
  }

  /// 获取计算引擎实例（用于测试）
  CalculationEngine get engine => _engine;

  /// 批量计算
  /// 
  /// [calculations] 计算请求列表，每个元素包含type和parameters
  /// 
  /// 返回计算结果列表
  Future<List<CalculationResult>> batchCalculate(
    List<Map<String, dynamic>> calculations,
  ) async {
    final results = <CalculationResult>[];
    
    for (final calculation in calculations) {
      final type = CalculationType.values.firstWhere(
        (e) => e.value == calculation['type'],
      );
      final parameters = calculation['parameters'] as Map<String, dynamic>;
      
      try {
        final result = await calculate(type, parameters);
        results.add(result);
      } catch (e) {
        // 批量计算中的单个错误不应该中断整个过程
        // 可以考虑添加错误结果或跳过
        rethrow;
      }
    }
    
    return results;
  }

  /// 获取计算类型的显示信息
  /// 
  /// [type] 计算类型
  /// 
  /// 返回包含显示名称、描述、图标等信息的映射
  Map<String, dynamic> getCalculationTypeInfo(CalculationType type) {
    switch (type) {
      case CalculationType.hole:
        return {
          'name': type.displayName,
          'description': '计算开孔作业的各项尺寸参数，包括空行程、切削尺寸、总行程等',
          'icon': 'hole_icon',
          'color': 0xFFFF9800, // Orange
          'complexity': 'high',
          'estimatedTime': '2-3分钟',
        };
      case CalculationType.manualHole:
        return {
          'name': type.displayName,
          'description': '计算手动开孔机作业的尺寸参数，包括螺纹咬合尺寸、行程计算',
          'icon': 'manual_hole_icon',
          'color': 0xFF2196F3, // Blue
          'complexity': 'medium',
          'estimatedTime': '1-2分钟',
        };
      case CalculationType.sealing:
        return {
          'name': type.displayName,
          'description': '计算封堵和解堵作业的尺寸参数，确保封堵操作的准确性',
          'icon': 'sealing_icon',
          'color': 0xFF4CAF50, // Green
          'complexity': 'medium',
          'estimatedTime': '1-2分钟',
        };
      case CalculationType.plug:
        return {
          'name': type.displayName,
          'description': '计算下塞堵作业的尺寸参数，包括螺纹咬合和行程计算',
          'icon': 'plug_icon',
          'color': 0xFF9C27B0, // Purple
          'complexity': 'medium',
          'estimatedTime': '1-2分钟',
        };
      case CalculationType.stem:
        return {
          'name': type.displayName,
          'description': '计算下塞柄作业的总行程参数，适用于封堵孔/囊孔作业',
          'icon': 'stem_icon',
          'color': 0xFFFF5722, // Deep Orange
          'complexity': 'low',
          'estimatedTime': '1分钟',
        };
    }
  }

  /// 获取所有计算类型的信息
  List<Map<String, dynamic>> getAllCalculationTypesInfo() {
    return CalculationType.values
        .map((type) => {
              'type': type,
              ...getCalculationTypeInfo(type),
            })
        .toList();
  }
}