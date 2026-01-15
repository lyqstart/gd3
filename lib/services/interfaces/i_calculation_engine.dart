import '../../models/calculation_result.dart';
import '../../models/calculation_parameters.dart';
import '../../models/validation_result.dart';
import '../../models/enums.dart';

/// 计算引擎标准接口
/// 
/// 定义了所有计算模块的标准接口，确保计算逻辑的一致性和可测试性。
/// 此接口是对现有计算引擎的标准化封装，不修改任何计算逻辑。
abstract class ICalculationEngine {
  /// 开孔尺寸计算
  /// 
  /// 根据管道参数和筒刀参数计算开孔作业的各项尺寸
  /// 
  /// 参数:
  /// - [params]: 开孔计算参数，包含管外径、内径、筒刀规格等
  /// 
  /// 返回:
  /// - [HoleCalculationResult]: 包含空行程、总行程、掉板行程等计算结果
  /// 
  /// 异常:
  /// - [ArgumentError]: 参数验证失败
  /// - [CalculationException]: 计算过程异常
  /// 
  /// 验证需求: 1.1-1.7
  HoleCalculationResult calculateHoleSize(HoleParameters params);
  
  /// 手动开孔计算
  /// 
  /// 计算手动开孔机的尺寸参数
  /// 
  /// 参数:
  /// - [params]: 手动开孔参数，包含L、J、P、T、W值
  /// 
  /// 返回:
  /// - [ManualHoleResult]: 包含螺纹咬合尺寸、空行程、总行程
  /// 
  /// 验证需求: 2.1-2.4
  ManualHoleResult calculateManualHole(ManualHoleParameters params);
  
  /// 封堵计算
  /// 
  /// 计算封堵和解堵作业的尺寸参数
  /// 
  /// 参数:
  /// - [params]: 封堵参数，包含R、B、D、E值等
  /// 
  /// 返回:
  /// - [SealingResult]: 包含导向轮行程、封堵总行程
  /// 
  /// 验证需求: 3.1-3.4
  SealingResult calculateSealing(SealingParameters params);
  
  /// 下塞堵计算
  /// 
  /// 计算下塞堵作业的尺寸参数
  /// 
  /// 参数:
  /// - [params]: 下塞堵参数，包含M、K、N、T、W值
  /// 
  /// 返回:
  /// - [PlugResult]: 包含螺纹咬合尺寸、空行程、总行程
  /// 
  /// 验证需求: 4.1-4.4
  PlugResult calculatePlug(PlugParameters params);
  
  /// 下塞柄计算
  /// 
  /// 计算下塞柄作业的尺寸参数
  /// 
  /// 参数:
  /// - [params]: 下塞柄参数，包含F、G、H值等
  /// 
  /// 返回:
  /// - [StemResult]: 包含总行程计算结果
  /// 
  /// 验证需求: 5.1-5.2
  StemResult calculateStem(StemParameters params);
  
  /// 验证计算参数
  /// 
  /// 对指定类型的计算参数进行验证
  /// 
  /// 参数:
  /// - [type]: 计算类型
  /// - [params]: 待验证的参数对象
  /// 
  /// 返回:
  /// - [ValidationResult]: 验证结果，包含是否有效和错误信息
  /// 
  /// 验证需求: 1.7, 2.4, 3.4, 4.4, 5.2, 10.5
  ValidationResult validateParameters(CalculationType type, dynamic params);
  
  /// 获取计算精度阈值
  /// 
  /// 返回:
  /// - [double]: 精度阈值（毫米），通常为0.1mm
  /// 
  /// 验证需求: 10.1
  double getPrecisionThreshold();
  
  /// 获取支持的计算类型
  /// 
  /// 返回:
  /// - [List<CalculationType>]: 支持的计算类型列表
  List<CalculationType> getSupportedCalculationTypes();
  
  /// 获取计算引擎版本信息
  /// 
  /// 返回:
  /// - [String]: 版本信息字符串
  String getVersion();
}

/// 计算引擎工厂接口
/// 
/// 用于创建和管理计算引擎实例
abstract class ICalculationEngineFactory {
  /// 创建计算引擎实例
  /// 
  /// 返回:
  /// - [ICalculationEngine]: 计算引擎实例
  ICalculationEngine createEngine();
  
  /// 创建高精度计算引擎实例
  /// 
  /// 返回:
  /// - [ICalculationEngine]: 高精度计算引擎实例
  ICalculationEngine createPrecisionEngine();
  
  /// 获取默认计算引擎实例
  /// 
  /// 返回:
  /// - [ICalculationEngine]: 默认计算引擎实例（单例）
  ICalculationEngine getDefaultEngine();
}

/// 计算结果验证接口
/// 
/// 用于验证计算结果的合理性
abstract class ICalculationResultValidator {
  /// 验证开孔计算结果
  /// 
  /// 参数:
  /// - [result]: 开孔计算结果
  /// - [params]: 原始计算参数
  /// 
  /// 返回:
  /// - [ValidationResult]: 验证结果
  ValidationResult validateHoleResult(
    HoleCalculationResult result, 
    HoleParameters params,
  );
  
  /// 验证手动开孔计算结果
  ValidationResult validateManualHoleResult(
    ManualHoleResult result, 
    ManualHoleParameters params,
  );
  
  /// 验证封堵计算结果
  ValidationResult validateSealingResult(
    SealingResult result, 
    SealingParameters params,
  );
  
  /// 验证下塞堵计算结果
  ValidationResult validatePlugResult(
    PlugResult result, 
    PlugParameters params,
  );
  
  /// 验证下塞柄计算结果
  ValidationResult validateStemResult(
    StemResult result, 
    StemParameters params,
  );
}

/// 计算性能监控接口
/// 
/// 用于监控计算性能和统计信息
abstract class ICalculationPerformanceMonitor {
  /// 开始性能测量
  /// 
  /// 参数:
  /// - [operationName]: 操作名称
  void startMeasurement(String operationName);
  
  /// 结束性能测量
  /// 
  /// 参数:
  /// - [operationName]: 操作名称
  /// 
  /// 返回:
  /// - [Duration]: 操作耗时
  Duration endMeasurement(String operationName);
  
  /// 获取性能统计信息
  /// 
  /// 返回:
  /// - [Map<String, dynamic>]: 性能统计数据
  Map<String, dynamic> getPerformanceStats();
  
  /// 重置性能统计
  void resetStats();
}