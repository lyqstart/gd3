import '../../models/calculation_result.dart';
import '../../models/validation_result.dart';
import '../../models/enums.dart';

/// 计算服务接口
abstract class ICalculationService {
  /// 执行计算
  /// 
  /// [type] 计算类型
  /// [parameters] 计算参数
  /// 
  /// 返回计算结果
  Future<CalculationResult> calculate(
    CalculationType type, 
    Map<String, dynamic> parameters,
  );

  /// 验证参数
  /// 
  /// [type] 计算类型
  /// [parameters] 待验证的参数
  /// 
  /// 返回验证结果
  Future<ValidationResult> validateParameters(
    CalculationType type, 
    Map<String, dynamic> parameters,
  );

  /// 获取支持的计算类型列表
  /// 
  /// 返回支持的计算类型
  List<CalculationType> getSupportedCalculationTypes();

  /// 获取指定计算类型的参数模板
  /// 
  /// [type] 计算类型
  /// 
  /// 返回参数模板（包含参数名称、类型、默认值等信息）
  Map<String, dynamic> getParameterTemplate(CalculationType type);

  /// 获取计算精度阈值
  /// 
  /// 返回精度阈值（毫米）
  double getPrecisionThreshold();
}