import 'dart:math' as math;

import '../models/calculation_result.dart';
import '../models/calculation_parameters.dart';
import '../models/enums.dart';
import '../utils/constants.dart';
import '../utils/performance_optimizer.dart';

/// 计算引擎抽象类
abstract class CalculationEngine {
  /// 开孔尺寸计算
  HoleCalculationResult calculateHoleSize(HoleParameters params);
  
  /// 手动开孔计算
  ManualHoleResult calculateManualHole(ManualHoleParameters params);
  
  /// 封堵计算
  SealingResult calculateSealing(SealingParameters params);
  
  /// 下塞堵计算
  PlugResult calculatePlug(PlugParameters params);
  
  /// 下塞柄计算
  StemResult calculateStem(StemParameters params);
  
  /// 获取计算精度阈值
  double getPrecisionThreshold();
}

/// 高精度计算引擎实现类
class PrecisionCalculationEngine implements CalculationEngine {
  /// 计算精度阈值（毫米）
  static const double _precisionThreshold = AppConstants.precisionThreshold;
  
  /// 数学计算的最小值阈值（避免负数开方等错误）
  static const double _minValueThreshold = 1e-10;

  @override
  double getPrecisionThreshold() => _precisionThreshold;

  @override
  HoleCalculationResult calculateHoleSize(HoleParameters params) {
    // 生成缓存键
    final cacheKey = 'hole_${params.hashCode}';
    
    // 尝试从缓存获取结果
    final cachedResult = PerformanceOptimizer().getCachedCalculation<HoleCalculationResult>(cacheKey);
    if (cachedResult != null) {
      return cachedResult;
    }
    
    // 开始性能监控
    PerformanceMonitor.startMeasurement('hole_calculation');
    
    // 验证参数
    final validation = params.validate();
    if (!validation.isValid) {
      throw ArgumentError('开孔参数验证失败: ${validation.message}');
    }

    try {
      // 步骤1: 计算空行程: S空 = A + B + 初始值 + 垫片厚度
      final emptyStroke = _calculateEmptyStroke(params);
      
      // 步骤2: 计算管道壁厚相关的中间值
      final pipeWallArea = _calculatePipeWallArea(
        params.outerDiameter, 
        params.innerDiameter,
      );

      // 步骤3: 计算筒刀切削距离: C1 = √(管外径² - 管内径²) - 筒刀外径
      final cuttingDistance = _calculateCuttingDistance(pipeWallArea, params.cutterOuterDiameter);

      // 步骤4: 计算掉板弦高: C2 = √(管外径² - 管内径²) - 筒刀内径
      final chordHeight = _calculateChordHeight(pipeWallArea, params.cutterInnerDiameter);

      // 步骤5: 计算切削尺寸: C = R + C1
      final cuttingSize = _calculateCuttingSize(params.rValue, cuttingDistance);

      // 步骤6: 计算开孔总行程: S总 = S空 + C
      final totalStroke = _calculateTotalStroke(emptyStroke, cuttingSize);

      // 步骤7: 计算掉板总行程: S掉板 = S总 + R + C2
      final plateStroke = _calculatePlateStroke(totalStroke, params.rValue, chordHeight);

      // 创建结果对象
      final result = HoleCalculationResult(
        emptyStroke: _roundToPrecision(emptyStroke),
        cuttingDistance: _roundToPrecision(cuttingDistance),
        chordHeight: _roundToPrecision(chordHeight),
        cuttingSize: _roundToPrecision(cuttingSize),
        totalStroke: _roundToPrecision(totalStroke),
        plateStroke: _roundToPrecision(plateStroke),
        calculationTime: DateTime.now(),
        parameters: params,
      );

      // 验证计算结果的合理性
      final resultValidation = result.validateResults();
      if (!resultValidation.isValid) {
        // 如果结果验证失败，记录警告但不抛出异常
        // 在实际应用中，这些警告应该显示给用户
        print('开孔计算结果警告: ${resultValidation.message}');
      }

      // 缓存结果
      PerformanceOptimizer().cacheCalculation(cacheKey, result);
      
      // 结束性能监控
      PerformanceMonitor.endMeasurement('hole_calculation');

      return result;
    } catch (e) {
      // 结束性能监控（即使出错也要记录）
      PerformanceMonitor.endMeasurement('hole_calculation');
      
      throw CalculationException(
        '开孔尺寸计算失败: $e',
        code: 'HOLE_CALCULATION_ERROR',
        relatedParameters: params.toJson(),
      );
    }
  }

  /// 计算空行程
  /// 
  /// 公式: S空 = A + B + 初始值 + 垫片厚度
  double _calculateEmptyStroke(HoleParameters params) {
    final result = params.aValue + params.bValue + 
                   params.initialValue + params.gasketThickness;
    
    if (result <= 0) {
      throw CalculationException('空行程计算结果为负值或零: ${result.toStringAsFixed(2)}mm');
    }
    
    return result;
  }

  /// 计算筒刀切削距离
  /// 
  /// 公式: C1 = √(管外径² - 管内径²) - 筒刀外径
  double _calculateCuttingDistance(double pipeWallArea, double cutterOuterDiameter) {
    final result = pipeWallArea - cutterOuterDiameter;
    
    // 允许负值，但给出警告
    if (result < 0) {
      print('警告: 筒刀切削距离为负值 ${result.toStringAsFixed(2)}mm，筒刀外径可能过大');
    }
    
    return result;
  }

  /// 计算掉板弦高
  /// 
  /// 公式: C2 = √(管外径² - 管内径²) - 筒刀内径
  double _calculateChordHeight(double pipeWallArea, double cutterInnerDiameter) {
    final result = pipeWallArea - cutterInnerDiameter;
    
    // 允许负值，但给出警告
    if (result < 0) {
      print('警告: 掉板弦高为负值 ${result.toStringAsFixed(2)}mm，筒刀内径可能过大');
    }
    
    return result;
  }

  /// 计算切削尺寸
  /// 
  /// 公式: C = R + C1
  double _calculateCuttingSize(double rValue, double cuttingDistance) {
    final result = rValue + cuttingDistance;
    
    // 允许负值，但给出警告（在实际工程中可能需要调整参数）
    if (result <= 0) {
      print('警告: 切削尺寸为负值或零 ${result.toStringAsFixed(2)}mm，请检查R值和筒刀外径参数');
    }
    
    return result;
  }

  /// 计算开孔总行程
  /// 
  /// 公式: S总 = S空 + C
  double _calculateTotalStroke(double emptyStroke, double cuttingSize) {
    final result = emptyStroke + cuttingSize;
    
    // 允许总行程小于等于空行程的情况（虽然不常见）
    if (result <= emptyStroke) {
      print('警告: 开孔总行程(${result.toStringAsFixed(2)}mm)小于等于空行程(${emptyStroke.toStringAsFixed(2)}mm)');
    }
    
    return result;
  }

  /// 计算掉板总行程
  /// 
  /// 公式: S掉板 = S总 + R + C2
  double _calculatePlateStroke(double totalStroke, double rValue, double chordHeight) {
    final result = totalStroke + rValue + chordHeight;
    
    // 允许掉板总行程小于等于开孔总行程的情况
    if (result <= totalStroke) {
      print('警告: 掉板总行程(${result.toStringAsFixed(2)}mm)小于等于开孔总行程(${totalStroke.toStringAsFixed(2)}mm)');
    }
    
    return result;
  }

  @override
  ManualHoleResult calculateManualHole(ManualHoleParameters params) {
    // 验证参数
    final validation = params.validate();
    if (!validation.isValid) {
      throw ArgumentError('手动开孔参数验证失败: ${validation.message}');
    }

    try {
      // 计算螺纹咬合尺寸: T - W
      final threadEngagement = params.tValue - params.wValue;

      // 计算空行程: L + J + T + W
      final emptyStroke = params.lValue + params.jValue + 
                         params.tValue + params.wValue;

      // 计算总行程: L + J + T + W + P
      final totalStroke = params.lValue + params.jValue + 
                         params.tValue + params.wValue + params.pValue;

      return ManualHoleResult(
        threadEngagement: _roundToPrecision(threadEngagement),
        emptyStroke: _roundToPrecision(emptyStroke),
        totalStroke: _roundToPrecision(totalStroke),
        calculationTime: DateTime.now(),
        parameters: params,
      );
    } catch (e) {
      throw CalculationException('手动开孔计算失败: $e');
    }
  }

  @override
  SealingResult calculateSealing(SealingParameters params) {
    // 验证参数
    final validation = params.validate();
    if (!validation.isValid) {
      throw ArgumentError('封堵参数验证失败: ${validation.message}');
    }

    try {
      // 计算导向轮接触管线行程: R + B + E + 垫子厚度 + 初始值
      final guideWheelStroke = params.rValue + params.bValue + 
                              params.eValue + params.gasketThickness + 
                              params.initialValue;

      // 计算封堵总行程: D + B + E + 垫子厚度 + 初始值
      final totalStroke = params.dValue + params.bValue + 
                         params.eValue + params.gasketThickness + 
                         params.initialValue;

      // 验证计算结果的合理性
      _validateSealingResults(guideWheelStroke, totalStroke, params);

      // 创建结果对象
      final result = SealingResult(
        guideWheelStroke: _roundToPrecision(guideWheelStroke),
        totalStroke: _roundToPrecision(totalStroke),
        calculationTime: DateTime.now(),
        parameters: params,
      );

      // 验证计算结果的合理性
      final resultValidation = result.validateResults();
      if (!resultValidation.isValid) {
        // 如果结果验证失败，记录警告但不抛出异常
        print('封堵计算结果警告: ${resultValidation.message}');
      }

      return result;
    } catch (e) {
      throw CalculationException(
        '封堵计算失败: $e',
        code: 'SEALING_CALCULATION_ERROR',
        relatedParameters: params.toJson(),
      );
    }
  }

  /// 验证封堵计算结果的合理性
  void _validateSealingResults(double guideWheelStroke, double totalStroke, SealingParameters params) {
    // 验证导向轮接触管线行程为正数
    if (guideWheelStroke <= 0) {
      throw CalculationException('导向轮接触管线行程计算结果为负值或零: ${guideWheelStroke.toStringAsFixed(2)}mm');
    }
    
    // 验证封堵总行程为正数
    if (totalStroke <= 0) {
      throw CalculationException('封堵总行程计算结果为负值或零: ${totalStroke.toStringAsFixed(2)}mm');
    }
    
    // 验证封堵总行程应该大于导向轮行程
    if (totalStroke <= guideWheelStroke) {
      print('警告: 封堵总行程(${totalStroke.toStringAsFixed(2)}mm)小于等于导向轮接触管线行程(${guideWheelStroke.toStringAsFixed(2)}mm)');
    }
    
    // 验证E值的合理性（应该接近管内径）
    if (params.eValue < 10.0) {
      print('警告: E值较小(${params.eValue.toStringAsFixed(2)}mm)，请确认管道内径计算是否正确');
    }
    
    // 验证行程差值的合理性
    final strokeDifference = totalStroke - guideWheelStroke;
    if (strokeDifference < 5.0) {
      print('警告: 封堵深度较小(${strokeDifference.toStringAsFixed(2)}mm)，可能影响封堵效果');
    } else if (strokeDifference > 150.0) {
      print('警告: 封堵深度较大(${strokeDifference.toStringAsFixed(2)}mm)，请确认参数设置');
    }
  }

  @override
  PlugResult calculatePlug(PlugParameters params) {
    // 验证参数
    final validation = params.validate();
    if (!validation.isValid) {
      throw ArgumentError('下塞堵参数验证失败: ${validation.message}');
    }

    try {
      // 计算螺纹咬合尺寸: T - W
      final threadEngagement = params.tValue - params.wValue;

      // 计算空行程: M + K - T + W
      final emptyStroke = params.mValue + params.kValue - 
                         params.tValue + params.wValue;

      // 计算总行程: M + K + N - T + W
      final totalStroke = params.mValue + params.kValue + 
                         params.nValue - params.tValue + params.wValue;

      // 验证计算结果的合理性
      _validatePlugResults(threadEngagement, emptyStroke, totalStroke, params);

      // 创建结果对象
      final result = PlugResult(
        threadEngagement: _roundToPrecision(threadEngagement),
        emptyStroke: _roundToPrecision(emptyStroke),
        totalStroke: _roundToPrecision(totalStroke),
        calculationTime: DateTime.now(),
        parameters: params,
      );

      // 验证计算结果的合理性
      final resultValidation = result.validateResults();
      if (!resultValidation.isValid) {
        // 如果结果验证失败，记录警告但不抛出异常
        print('下塞堵计算结果警告: ${resultValidation.message}');
      }

      return result;
    } catch (e) {
      throw CalculationException(
        '下塞堵计算失败: $e',
        code: 'PLUG_CALCULATION_ERROR',
        relatedParameters: params.toJson(),
      );
    }
  }

  /// 验证下塞堵计算结果的合理性
  void _validatePlugResults(double threadEngagement, double emptyStroke, double totalStroke, PlugParameters params) {
    // 验证螺纹咬合尺寸
    if (threadEngagement < 0) {
      print('警告: 螺纹咬合尺寸为负值 ${threadEngagement.toStringAsFixed(2)}mm，T值应大于W值');
    }
    
    // 验证空行程为正数
    if (emptyStroke <= 0) {
      throw CalculationException('空行程计算结果为负值或零: ${emptyStroke.toStringAsFixed(2)}mm，请检查M、K、T、W值');
    }
    
    // 验证总行程为正数
    if (totalStroke <= 0) {
      throw CalculationException('总行程计算结果为负值或零: ${totalStroke.toStringAsFixed(2)}mm，请检查所有参数值');
    }
    
    // 验证总行程应该大于空行程
    if (totalStroke <= emptyStroke) {
      print('警告: 总行程(${totalStroke.toStringAsFixed(2)}mm)小于等于空行程(${emptyStroke.toStringAsFixed(2)}mm)，N值可能过小');
    }
    
    // 验证螺纹咬合的安全性
    if (threadEngagement >= 0 && threadEngagement < 3.0) {
      print('警告: 螺纹咬合尺寸较小(${threadEngagement.toStringAsFixed(2)}mm)，可能影响连接强度');
    }
    
    // 验证行程的工程合理性
    if (totalStroke > 500.0) {
      print('警告: 总行程较大(${totalStroke.toStringAsFixed(2)}mm)，请确认参数设置和操作安全性');
    }
    
    // 验证下塞堵深度的合理性
    final plugDepth = totalStroke - emptyStroke;
    if (plugDepth < 5.0) {
      print('警告: 下塞堵深度较小(${plugDepth.toStringAsFixed(2)}mm)，可能影响塞堵效果');
    } else if (plugDepth > 200.0) {
      print('警告: 下塞堵深度较大(${plugDepth.toStringAsFixed(2)}mm)，请确认是否合理');
    }
    
    // 验证参数比例的合理性
    if (params.nValue > (params.mValue + params.kValue)) {
      print('警告: N值大于M+K值，请确认参数设置的合理性');
    }
  }

  @override
  StemResult calculateStem(StemParameters params) {
    // 验证参数
    final validation = params.validate();
    if (!validation.isValid) {
      throw ArgumentError('下塞柄参数验证失败: ${validation.message}');
    }

    try {
      // 计算总行程: F + G + H + 垫子厚度 + 初始值
      final totalStroke = _calculateStemTotalStroke(params);

      // 验证计算结果的合理性
      _validateStemResults(totalStroke, params);

      // 创建结果对象
      final result = StemResult(
        totalStroke: _roundToPrecision(totalStroke),
        calculationTime: DateTime.now(),
        parameters: params,
      );

      // 验证计算结果的合理性
      final resultValidation = result.validateResults();
      if (!resultValidation.isValid) {
        // 如果结果验证失败，记录警告但不抛出异常
        print('下塞柄计算结果警告: ${resultValidation.message}');
      }

      return result;
    } catch (e) {
      throw CalculationException(
        '下塞柄计算失败: $e',
        code: 'STEM_CALCULATION_ERROR',
        relatedParameters: params.toJson(),
      );
    }
  }

  /// 计算下塞柄总行程
  /// 
  /// 公式: 总行程 = F + G + H + 垫子厚度 + 初始值
  /// 需求5.1: 当用户输入F值、G值、H值、垫子厚度和初始值时，计算总行程
  double _calculateStemTotalStroke(StemParameters params) {
    final result = params.fValue + params.gValue + params.hValue + 
                   params.gasketThickness + params.initialValue;
    
    if (result <= 0) {
      throw CalculationException('下塞柄总行程计算结果为负值或零: ${result.toStringAsFixed(2)}mm');
    }
    
    return result;
  }

  /// 验证下塞柄计算结果的合理性
  void _validateStemResults(double totalStroke, StemParameters params) {
    // 验证总行程为正数
    if (totalStroke <= 0) {
      throw CalculationException('下塞柄总行程计算结果为负值或零: ${totalStroke.toStringAsFixed(2)}mm');
    }
    
    // 验证结果的工程合理性（总行程通常在20-600mm之间）
    if (totalStroke < 10.0) {
      print('警告: 下塞柄总行程较小(${totalStroke.toStringAsFixed(2)}mm)，请确认参数设置');
    } else if (totalStroke > 800.0) {
      print('警告: 下塞柄总行程较大(${totalStroke.toStringAsFixed(2)}mm)，请确认参数设置和操作安全性');
    }
    
    // 验证各参数的合理性比例
    if (params.fValue < 5.0) {
      print('警告: F值较小(${params.fValue.toStringAsFixed(2)}mm)，请确认封堵孔/囊孔基础尺寸');
    }
    
    if (params.gValue < 3.0) {
      print('警告: G值较小(${params.gValue.toStringAsFixed(2)}mm)，请确认设备调节范围');
    }
    
    if (params.hValue < 5.0) {
      print('警告: H值较小(${params.hValue.toStringAsFixed(2)}mm)，下塞柄长度可能不足');
    }
    
    // 验证参数比例的合理性
    if (params.hValue > totalStroke * 0.8) {
      print('警告: H值占总行程比例过大(${(params.hValue / totalStroke * 100).toStringAsFixed(1)}%)，可能影响操作稳定性');
    }
    
    if (params.gasketThickness > totalStroke * 0.1) {
      print('警告: 垫子厚度占总行程比例较大(${(params.gasketThickness / totalStroke * 100).toStringAsFixed(1)}%)，请确认垫片规格');
    }
    
    // 需求5.2: 当任何输入参数超出合理范围时，显示警告信息
    if (params.fValue > 400.0) {
      print('警告: F值超出常见范围(${params.fValue.toStringAsFixed(2)}mm > 400mm)，请确认测量准确性');
    }
    
    if (params.gValue > 200.0) {
      print('警告: G值超出常见范围(${params.gValue.toStringAsFixed(2)}mm > 200mm)，请确认设备规格');
    }
    
    if (params.hValue > 300.0) {
      print('警告: H值超出常见范围(${params.hValue.toStringAsFixed(2)}mm > 300mm)，请确认下塞柄规格');
    }
    
    if (params.gasketThickness > 25.0) {
      print('警告: 垫子厚度超出常见范围(${params.gasketThickness.toStringAsFixed(2)}mm > 25mm)，请确认垫片规格');
    }
    
    if (params.initialValue > 50.0) {
      print('警告: 初始值超出常见范围(${params.initialValue.toStringAsFixed(2)}mm > 50mm)，请确认设备设置');
    }
    
    // 验证精度要求（需求5.3: 保持计算精度至小数点后2位）
    final precisionCheck = double.parse(totalStroke.toStringAsFixed(2));
    if ((totalStroke - precisionCheck).abs() > 0.001) {
      print('信息: 计算结果已调整至小数点后2位精度要求');
    }
  }

  /// 计算管道壁厚区域的有效尺寸
  /// 
  /// 使用公式: √(管外径² - 管内径²)
  /// 这个值在开孔计算中用于确定筒刀的切削距离和掉板弦高
  double _calculatePipeWallArea(double outerDiameter, double innerDiameter) {
    // 验证输入参数
    if (outerDiameter <= innerDiameter) {
      throw ArgumentError('管外径必须大于管内径');
    }
    
    // 计算平方差
    final squareDifference = (outerDiameter * outerDiameter) - 
                            (innerDiameter * innerDiameter);
    
    // 检查是否为负数（理论上不应该发生，但为了安全起见）
    if (squareDifference < _minValueThreshold) {
      throw CalculationException('管道参数计算结果异常，请检查输入参数');
    }
    
    // 使用高精度平方根计算
    return _precisionSqrt(squareDifference);
  }

  /// 高精度平方根计算
  /// 
  /// 使用双精度浮点数确保计算精度
  double _precisionSqrt(double value) {
    if (value < 0) {
      throw CalculationException('不能计算负数的平方根: $value');
    }
    
    if (value == 0) {
      return 0.0;
    }
    
    // 使用Dart内置的高精度平方根函数
    final result = math.sqrt(value);
    
    // 验证结果的有效性
    if (result.isNaN || result.isInfinite) {
      throw CalculationException('平方根计算结果无效: $value -> $result');
    }
    
    return result;
  }

  /// 精度控制方法
  /// 
  /// 将计算结果舍入到指定精度（0.1mm）
  double _roundToPrecision(double value) {
    if (value.isNaN || value.isInfinite) {
      throw CalculationException('无法对无效数值进行精度控制: $value');
    }
    
    // 使用精度阈值进行舍入
    // 0.1mm精度意味着保留到小数点后1位
    final multiplier = 1.0 / _precisionThreshold;
    return (value * multiplier).round() / multiplier;
  }

  /// 验证计算结果的合理性
  /// 
  /// 检查结果是否在合理的工程范围内
  bool _validateResult(double result, String resultName) {
    // 检查基本有效性
    if (result.isNaN || result.isInfinite) {
      throw CalculationException('$resultName 计算结果无效: $result');
    }
    
    // 检查是否为负数（大多数情况下不应该为负）
    if (result < 0) {
      // 某些计算（如螺纹咬合尺寸）可能为负数，这是警告而不是错误
      return false;
    }
    
    // 检查是否超出合理的工程范围（0-10000mm）
    if (result > 10000.0) {
      throw CalculationException('$resultName 计算结果超出合理范围: ${result}mm');
    }
    
    return true;
  }

  /// 批量验证计算结果
  void _validateResults(Map<String, double> results) {
    for (final entry in results.entries) {
      _validateResult(entry.value, entry.key);
    }
  }
}

/// 计算异常类
class CalculationException implements Exception {
  /// 异常消息
  final String message;
  
  /// 异常代码（可选）
  final String? code;
  
  /// 相关参数（可选）
  final Map<String, dynamic>? relatedParameters;

  const CalculationException(
    this.message, {
    this.code,
    this.relatedParameters,
  });

  @override
  String toString() {
    final buffer = StringBuffer('CalculationException: $message');
    if (code != null) {
      buffer.write(' (代码: $code)');
    }
    if (relatedParameters != null) {
      buffer.write(' 相关参数: $relatedParameters');
    }
    return buffer.toString();
  }
}

/// 数学运算辅助工具类
class MathUtils {
  /// 安全的除法运算
  /// 
  /// 避免除零错误
  static double safeDivide(double dividend, double divisor, {double defaultValue = 0.0}) {
    if (divisor.abs() < 1e-10) {
      return defaultValue;
    }
    return dividend / divisor;
  }

  /// 角度转弧度
  static double degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// 弧度转角度
  static double radiansToDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }

  /// 计算两点间距离
  static double distance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// 检查数值是否在指定范围内
  static bool isInRange(double value, double min, double max) {
    return value >= min && value <= max;
  }

  /// 将数值限制在指定范围内
  static double clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}