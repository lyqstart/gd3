import 'interfaces/i_calculation_engine.dart';
import 'calculation_engine.dart';
import '../models/calculation_result.dart';
import '../models/calculation_parameters.dart';
import '../models/validation_result.dart';
import '../models/enums.dart';

/// 计算引擎适配器
/// 
/// 将现有的PrecisionCalculationEngine适配为标准的ICalculationEngine接口
/// 此适配器不修改任何计算逻辑，仅提供接口标准化
class CalculationEngineAdapter implements ICalculationEngine {
  /// 内部计算引擎实例
  final PrecisionCalculationEngine _engine;
  
  /// 版本信息
  static const String _version = '1.0.0';
  
  /// 构造函数
  CalculationEngineAdapter() : _engine = PrecisionCalculationEngine();
  
  /// 使用指定引擎实例的构造函数
  CalculationEngineAdapter.withEngine(this._engine);
  
  /// 获取内部引擎实例（用于测试）
  PrecisionCalculationEngine get internalEngine => _engine;

  @override
  HoleCalculationResult calculateHoleSize(HoleParameters params) {
    // 直接委托给内部引擎，不修改任何计算逻辑
    return _engine.calculateHoleSize(params);
  }

  @override
  ManualHoleResult calculateManualHole(ManualHoleParameters params) {
    // 直接委托给内部引擎，不修改任何计算逻辑
    return _engine.calculateManualHole(params);
  }

  @override
  SealingResult calculateSealing(SealingParameters params) {
    // 直接委托给内部引擎，不修改任何计算逻辑
    return _engine.calculateSealing(params);
  }

  @override
  PlugResult calculatePlug(PlugParameters params) {
    // 直接委托给内部引擎，不修改任何计算逻辑
    return _engine.calculatePlug(params);
  }

  @override
  StemResult calculateStem(StemParameters params) {
    // 直接委托给内部引擎，不修改任何计算逻辑
    return _engine.calculateStem(params);
  }

  @override
  ValidationResult validateParameters(CalculationType type, dynamic params) {
    try {
      // 根据计算类型验证相应的参数
      switch (type) {
        case CalculationType.hole:
          if (params is! HoleParameters) {
            return ValidationResult.error('参数类型错误，期望HoleParameters');
          }
          return params.validate();
          
        case CalculationType.manualHole:
          if (params is! ManualHoleParameters) {
            return ValidationResult.error('参数类型错误，期望ManualHoleParameters');
          }
          return params.validate();
          
        case CalculationType.sealing:
          if (params is! SealingParameters) {
            return ValidationResult.error('参数类型错误，期望SealingParameters');
          }
          return params.validate();
          
        case CalculationType.plug:
          if (params is! PlugParameters) {
            return ValidationResult.error('参数类型错误，期望PlugParameters');
          }
          return params.validate();
          
        case CalculationType.stem:
          if (params is! StemParameters) {
            return ValidationResult.error('参数类型错误，期望StemParameters');
          }
          return params.validate();
          
        default:
          return ValidationResult.error('不支持的计算类型: $type');
      }
    } catch (e) {
      return ValidationResult.error('参数验证异常: $e');
    }
  }

  @override
  double getPrecisionThreshold() {
    // 委托给内部引擎
    return _engine.getPrecisionThreshold();
  }

  @override
  List<CalculationType> getSupportedCalculationTypes() {
    // 返回所有支持的计算类型
    return [
      CalculationType.hole,
      CalculationType.manualHole,
      CalculationType.sealing,
      CalculationType.plug,
      CalculationType.stem,
    ];
  }

  @override
  String getVersion() {
    return _version;
  }
}

/// 计算引擎工厂实现
/// 
/// 提供计算引擎实例的创建和管理
class CalculationEngineFactory implements ICalculationEngineFactory {
  /// 单例实例
  static CalculationEngineFactory? _instance;
  
  /// 默认引擎实例（单例）
  static ICalculationEngine? _defaultEngine;
  
  /// 私有构造函数
  CalculationEngineFactory._();
  
  /// 获取工厂单例实例
  static CalculationEngineFactory get instance {
    _instance ??= CalculationEngineFactory._();
    return _instance!;
  }

  @override
  ICalculationEngine createEngine() {
    return CalculationEngineAdapter();
  }

  @override
  ICalculationEngine createPrecisionEngine() {
    // 创建高精度计算引擎（当前实现已经是高精度）
    return CalculationEngineAdapter();
  }

  @override
  ICalculationEngine getDefaultEngine() {
    // 返回单例的默认引擎
    _defaultEngine ??= CalculationEngineAdapter();
    return _defaultEngine!;
  }
  
  /// 重置默认引擎（主要用于测试）
  static void resetDefaultEngine() {
    _defaultEngine = null;
  }
}

/// 计算结果验证器实现
/// 
/// 验证计算结果的工程合理性
class CalculationResultValidator implements ICalculationResultValidator {
  /// 精度阈值
  static const double _precisionThreshold = 0.1;

  @override
  ValidationResult validateHoleResult(
    HoleCalculationResult result, 
    HoleParameters params,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // 验证计算结果的基本有效性
    if (!_isValidNumber(result.emptyStroke)) {
      errors.add('空行程计算结果无效');
    }
    if (!_isValidNumber(result.totalStroke)) {
      errors.add('总行程计算结果无效');
    }
    if (!_isValidNumber(result.plateStroke)) {
      errors.add('掉板总行程计算结果无效');
    }
    
    // 验证工程合理性
    if (result.emptyStroke <= 0) {
      errors.add('空行程应为正数');
    }
    if (result.totalStroke <= result.emptyStroke) {
      warnings.add('总行程应大于空行程');
    }
    if (result.plateStroke <= result.totalStroke) {
      warnings.add('掉板总行程应大于总行程');
    }
    
    // 验证精度
    if (!_checkPrecision(result.emptyStroke) || 
        !_checkPrecision(result.totalStroke) || 
        !_checkPrecision(result.plateStroke)) {
      warnings.add('计算结果精度可能不符合0.1mm要求');
    }
    
    if (errors.isNotEmpty) {
      return ValidationResult.error(errors.join('; '));
    } else if (warnings.isNotEmpty) {
      return ValidationResult.warning(warnings.join('; '));
    } else {
      return ValidationResult.success();
    }
  }

  @override
  ValidationResult validateManualHoleResult(
    ManualHoleResult result, 
    ManualHoleParameters params,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // 验证基本有效性
    if (!_isValidNumber(result.emptyStroke) || 
        !_isValidNumber(result.totalStroke)) {
      errors.add('计算结果包含无效数值');
    }
    
    // 验证工程合理性
    if (result.emptyStroke <= 0) {
      errors.add('空行程应为正数');
    }
    if (result.totalStroke <= result.emptyStroke) {
      warnings.add('总行程应大于空行程');
    }
    if (result.threadEngagement < 0) {
      warnings.add('螺纹咬合尺寸为负值，请检查T值和W值');
    }
    
    if (errors.isNotEmpty) {
      return ValidationResult.error(errors.join('; '));
    } else if (warnings.isNotEmpty) {
      return ValidationResult.warning(warnings.join('; '));
    } else {
      return ValidationResult.success();
    }
  }

  @override
  ValidationResult validateSealingResult(
    SealingResult result, 
    SealingParameters params,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // 验证基本有效性
    if (!_isValidNumber(result.guideWheelStroke) || 
        !_isValidNumber(result.totalStroke)) {
      errors.add('计算结果包含无效数值');
    }
    
    // 验证工程合理性
    if (result.guideWheelStroke <= 0 || result.totalStroke <= 0) {
      errors.add('行程计算结果应为正数');
    }
    if (result.totalStroke <= result.guideWheelStroke) {
      warnings.add('封堵总行程应大于导向轮接触管线行程');
    }
    
    if (errors.isNotEmpty) {
      return ValidationResult.error(errors.join('; '));
    } else if (warnings.isNotEmpty) {
      return ValidationResult.warning(warnings.join('; '));
    } else {
      return ValidationResult.success();
    }
  }

  @override
  ValidationResult validatePlugResult(
    PlugResult result, 
    PlugParameters params,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // 验证基本有效性
    if (!_isValidNumber(result.emptyStroke) || 
        !_isValidNumber(result.totalStroke)) {
      errors.add('计算结果包含无效数值');
    }
    
    // 验证工程合理性
    if (result.emptyStroke <= 0 || result.totalStroke <= 0) {
      errors.add('行程计算结果应为正数');
    }
    if (result.totalStroke <= result.emptyStroke) {
      warnings.add('总行程应大于空行程');
    }
    if (result.threadEngagement < 0) {
      warnings.add('螺纹咬合尺寸为负值，请检查T值和W值');
    }
    
    if (errors.isNotEmpty) {
      return ValidationResult.error(errors.join('; '));
    } else if (warnings.isNotEmpty) {
      return ValidationResult.warning(warnings.join('; '));
    } else {
      return ValidationResult.success();
    }
  }

  @override
  ValidationResult validateStemResult(
    StemResult result, 
    StemParameters params,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // 验证基本有效性
    if (!_isValidNumber(result.totalStroke)) {
      errors.add('总行程计算结果无效');
    }
    
    // 验证工程合理性
    if (result.totalStroke <= 0) {
      errors.add('总行程应为正数');
    }
    if (result.totalStroke > 800.0) {
      warnings.add('总行程较大，请确认参数设置');
    }
    if (result.totalStroke < 10.0) {
      warnings.add('总行程较小，请确认参数设置');
    }
    
    if (errors.isNotEmpty) {
      return ValidationResult.error(errors.join('; '));
    } else if (warnings.isNotEmpty) {
      return ValidationResult.warning(warnings.join('; '));
    } else {
      return ValidationResult.success();
    }
  }
  
  /// 检查数值是否有效
  bool _isValidNumber(double value) {
    return !value.isNaN && !value.isInfinite;
  }
  
  /// 检查精度是否符合要求
  bool _checkPrecision(double value) {
    final decimal = (value * 10) % 1;
    return decimal.abs() < 1e-10; // 考虑浮点数精度误差
  }
}

/// 计算性能监控器实现
/// 
/// 监控计算性能和统计信息
class CalculationPerformanceMonitor implements ICalculationPerformanceMonitor {
  /// 性能测量数据
  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _durations = {};
  final Map<String, int> _counts = {};
  
  @override
  void startMeasurement(String operationName) {
    _startTimes[operationName] = DateTime.now();
  }

  @override
  Duration endMeasurement(String operationName) {
    final startTime = _startTimes[operationName];
    if (startTime == null) {
      throw ArgumentError('未找到操作 $operationName 的开始时间');
    }
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    
    // 记录统计信息
    _durations.putIfAbsent(operationName, () => []).add(duration);
    _counts[operationName] = (_counts[operationName] ?? 0) + 1;
    
    // 清理开始时间
    _startTimes.remove(operationName);
    
    return duration;
  }

  @override
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    
    for (final operation in _durations.keys) {
      final durations = _durations[operation]!;
      final count = _counts[operation]!;
      
      final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
      final avgMs = totalMs / count;
      final minMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
      final maxMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
      
      stats[operation] = {
        'count': count,
        'totalMs': totalMs,
        'averageMs': avgMs,
        'minMs': minMs,
        'maxMs': maxMs,
      };
    }
    
    return stats;
  }

  @override
  void resetStats() {
    _startTimes.clear();
    _durations.clear();
    _counts.clear();
  }
}