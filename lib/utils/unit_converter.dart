import 'dart:math';
import '../models/enums.dart';
import '../models/calculation_parameters.dart';
import '../models/parameter_models.dart';

/// 单位转换工具类
/// 
/// 提供高精度的单位转换功能，支持毫米和英寸之间的转换
class UnitConverter {
  /// 毫米到英寸的转换系数
  static const double _mmToInchFactor = 1.0 / 25.4;
  
  /// 英寸到毫米的转换系数
  static const double _inchToMmFactor = 25.4;
  
  /// 精度保持的小数位数
  static const int _precisionDecimalPlaces = 6;
  
  /// 显示精度的小数位数
  static const int _displayDecimalPlaces = 2;

  /// 执行单位转换
  /// 
  /// [value] 要转换的数值
  /// [from] 源单位
  /// [to] 目标单位
  /// 
  /// 返回转换后的数值，保持高精度
  static double convert(double value, UnitType from, UnitType to) {
    if (from == to) return value;
    
    double result;
    
    switch (from) {
      case UnitType.millimeter:
        switch (to) {
          case UnitType.inch:
            result = value * _mmToInchFactor;
            break;
          case UnitType.millimeter:
            result = value;
            break;
        }
        break;
      case UnitType.inch:
        switch (to) {
          case UnitType.millimeter:
            result = value * _inchToMmFactor;
            break;
          case UnitType.inch:
            result = value;
            break;
        }
        break;
    }
    
    // 保持精度，避免浮点数精度问题
    return _roundToPrecision(result, _precisionDecimalPlaces);
  }

  /// 执行单位转换（别名方法，兼容旧代码）
  /// 
  /// [value] 要转换的数值
  /// [from] 源单位
  /// [to] 目标单位
  /// 
  /// 返回转换后的数值，保持高精度
  static double convertUnit(double value, UnitType from, UnitType to) {
    return convert(value, from, to);
  }

  /// 英寸转毫米（便捷方法）
  /// 
  /// [inches] 英寸值
  /// 
  /// 返回毫米值
  static double inchToMm(double inches) {
    return convert(inches, UnitType.inch, UnitType.millimeter);
  }

  /// 毫米转英寸（便捷方法）
  /// 
  /// [millimeters] 毫米值
  /// 
  /// 返回英寸值
  static double mmToInch(double millimeters) {
    return convert(millimeters, UnitType.millimeter, UnitType.inch);
  }

  /// 批量转换参数
  /// 
  /// [parameters] 参数映射（参数名 -> 数值）
  /// [from] 源单位
  /// [to] 目标单位
  /// 
  /// 返回转换后的参数映射
  static Map<String, double> convertParameters(
    Map<String, double> parameters, 
    UnitType from, 
    UnitType to,
  ) {
    if (from == to) {
      return Map<String, double>.from(parameters);
    }
    
    final convertedParameters = <String, double>{};
    
    for (final entry in parameters.entries) {
      convertedParameters[entry.key] = convert(entry.value, from, to);
    }
    
    return convertedParameters;
  }

  /// 转换开孔参数
  /// 
  /// [parameters] 开孔参数对象
  /// [targetUnit] 目标单位
  /// 
  /// 返回转换后的开孔参数对象
  static HoleParameters convertHoleParameters(
    HoleParameters parameters, 
    UnitType targetUnit,
  ) {
    // 假设原始参数是毫米单位
    final sourceUnit = UnitType.millimeter;
    
    if (sourceUnit == targetUnit) {
      return parameters;
    }
    
    return HoleParameters(
      outerDiameter: convert(parameters.outerDiameter, sourceUnit, targetUnit),
      innerDiameter: convert(parameters.innerDiameter, sourceUnit, targetUnit),
      cutterOuterDiameter: convert(parameters.cutterOuterDiameter, sourceUnit, targetUnit),
      cutterInnerDiameter: convert(parameters.cutterInnerDiameter, sourceUnit, targetUnit),
      aValue: convert(parameters.aValue, sourceUnit, targetUnit),
      bValue: convert(parameters.bValue, sourceUnit, targetUnit),
      rValue: convert(parameters.rValue, sourceUnit, targetUnit),
      initialValue: convert(parameters.initialValue, sourceUnit, targetUnit),
      gasketThickness: convert(parameters.gasketThickness, sourceUnit, targetUnit),
    );
  }

  /// 转换手动开孔参数
  /// 
  /// [parameters] 手动开孔参数对象
  /// [targetUnit] 目标单位
  /// 
  /// 返回转换后的手动开孔参数对象
  static ManualHoleParameters convertManualHoleParameters(
    ManualHoleParameters parameters, 
    UnitType targetUnit,
  ) {
    final sourceUnit = UnitType.millimeter;
    
    if (sourceUnit == targetUnit) {
      return parameters;
    }
    
    return ManualHoleParameters(
      lValue: convert(parameters.lValue, sourceUnit, targetUnit),
      jValue: convert(parameters.jValue, sourceUnit, targetUnit),
      pValue: convert(parameters.pValue, sourceUnit, targetUnit),
      tValue: convert(parameters.tValue, sourceUnit, targetUnit),
      wValue: convert(parameters.wValue, sourceUnit, targetUnit),
    );
  }

  /// 转换封堵参数
  /// 
  /// [parameters] 封堵参数对象
  /// [targetUnit] 目标单位
  /// 
  /// 返回转换后的封堵参数对象
  static SealingParameters convertSealingParameters(
    SealingParameters parameters, 
    UnitType targetUnit,
  ) {
    final sourceUnit = UnitType.millimeter;
    
    if (sourceUnit == targetUnit) {
      return parameters;
    }
    
    return SealingParameters(
      rValue: convert(parameters.rValue, sourceUnit, targetUnit),
      bValue: convert(parameters.bValue, sourceUnit, targetUnit),
      dValue: convert(parameters.dValue, sourceUnit, targetUnit),
      eValue: convert(parameters.eValue, sourceUnit, targetUnit),
      gasketThickness: convert(parameters.gasketThickness, sourceUnit, targetUnit),
      initialValue: convert(parameters.initialValue, sourceUnit, targetUnit),
    );
  }

  /// 转换下塞堵参数
  /// 
  /// [parameters] 下塞堵参数对象
  /// [targetUnit] 目标单位
  /// 
  /// 返回转换后的下塞堵参数对象
  static PlugParameters convertPlugParameters(
    PlugParameters parameters, 
    UnitType targetUnit,
  ) {
    final sourceUnit = UnitType.millimeter;
    
    if (sourceUnit == targetUnit) {
      return parameters;
    }
    
    return PlugParameters(
      mValue: convert(parameters.mValue, sourceUnit, targetUnit),
      kValue: convert(parameters.kValue, sourceUnit, targetUnit),
      nValue: convert(parameters.nValue, sourceUnit, targetUnit),
      tValue: convert(parameters.tValue, sourceUnit, targetUnit),
      wValue: convert(parameters.wValue, sourceUnit, targetUnit),
    );
  }

  /// 转换下塞柄参数
  /// 
  /// [parameters] 下塞柄参数对象
  /// [targetUnit] 目标单位
  /// 
  /// 返回转换后的下塞柄参数对象
  static StemParameters convertStemParameters(
    StemParameters parameters, 
    UnitType targetUnit,
  ) {
    final sourceUnit = UnitType.millimeter;
    
    if (sourceUnit == targetUnit) {
      return parameters;
    }
    
    return StemParameters(
      fValue: convert(parameters.fValue, sourceUnit, targetUnit),
      gValue: convert(parameters.gValue, sourceUnit, targetUnit),
      hValue: convert(parameters.hValue, sourceUnit, targetUnit),
      gasketThickness: convert(parameters.gasketThickness, sourceUnit, targetUnit),
      initialValue: convert(parameters.initialValue, sourceUnit, targetUnit),
    );
  }

  /// 获取转换系数
  /// 
  /// [from] 源单位
  /// [to] 目标单位
  /// 
  /// 返回转换系数
  static double getConversionFactor(UnitType from, UnitType to) {
    if (from == to) return 1.0;
    
    switch (from) {
      case UnitType.millimeter:
        switch (to) {
          case UnitType.inch:
            return _mmToInchFactor;
          case UnitType.millimeter:
            return 1.0;
        }
        break;
      case UnitType.inch:
        switch (to) {
          case UnitType.millimeter:
            return _inchToMmFactor;
          case UnitType.inch:
            return 1.0;
        }
        break;
    }
  }

  /// 格式化显示数值
  /// 
  /// [value] 数值
  /// [unit] 单位
  /// [decimalPlaces] 小数位数（可选，默认为2位）
  /// 
  /// 返回格式化后的字符串
  static String formatValue(double value, UnitType unit, [int? decimalPlaces]) {
    final places = decimalPlaces ?? _displayDecimalPlaces;
    final formattedValue = value.toStringAsFixed(places);
    return '$formattedValue ${unit.symbol}';
  }

  /// 格式化显示数值（不带单位）
  /// 
  /// [value] 数值
  /// [decimalPlaces] 小数位数（可选，默认为2位）
  /// 
  /// 返回格式化后的数值字符串
  static String formatNumber(double value, [int? decimalPlaces]) {
    final places = decimalPlaces ?? _displayDecimalPlaces;
    return value.toStringAsFixed(places);
  }

  /// 解析数值字符串
  /// 
  /// [valueString] 数值字符串
  /// 
  /// 返回解析后的数值，如果解析失败返回null
  static double? parseValue(String valueString) {
    try {
      // 移除可能的单位符号和空格
      final cleanString = valueString
          .replaceAll(RegExp(r'[a-zA-Z\s]'), '')
          .trim();
      
      if (cleanString.isEmpty) return null;
      
      return double.parse(cleanString);
    } catch (e) {
      return null;
    }
  }

  /// 验证转换精度
  /// 
  /// [originalValue] 原始值
  /// [sourceUnit] 源单位
  /// [targetUnit] 目标单位
  /// 
  /// 返回往返转换后的精度损失百分比
  static double validateConversionPrecision(
    double originalValue, 
    UnitType sourceUnit, 
    UnitType targetUnit,
  ) {
    if (sourceUnit == targetUnit) return 0.0;
    
    // 执行往返转换
    final converted = convert(originalValue, sourceUnit, targetUnit);
    final backConverted = convert(converted, targetUnit, sourceUnit);
    
    // 计算精度损失
    final difference = (originalValue - backConverted).abs();
    final precisionLoss = (difference / originalValue) * 100;
    
    return precisionLoss;
  }

  /// 检查转换精度是否可接受
  /// 
  /// [originalValue] 原始值
  /// [sourceUnit] 源单位
  /// [targetUnit] 目标单位
  /// [maxLossPercent] 最大可接受的精度损失百分比（默认0.01%）
  /// 
  /// 返回精度是否可接受
  static bool isConversionPrecisionAcceptable(
    double originalValue, 
    UnitType sourceUnit, 
    UnitType targetUnit, {
    double maxLossPercent = 0.01,
  }) {
    final precisionLoss = validateConversionPrecision(
      originalValue, 
      sourceUnit, 
      targetUnit,
    );
    
    return precisionLoss <= maxLossPercent;
  }

  /// 获取单位转换的建议精度
  /// 
  /// [unit] 单位类型
  /// 
  /// 返回建议的小数位数
  static int getRecommendedPrecision(UnitType unit) {
    switch (unit) {
      case UnitType.millimeter:
        return 2; // 毫米保留2位小数
      case UnitType.inch:
        return 4; // 英寸保留4位小数（更高精度）
    }
  }

  /// 智能格式化数值
  /// 
  /// [value] 数值
  /// [unit] 单位
  /// 
  /// 返回根据单位类型智能格式化的字符串
  static String smartFormat(double value, UnitType unit) {
    final precision = getRecommendedPrecision(unit);
    return formatValue(value, unit, precision);
  }

  /// 创建单位转换映射表
  /// 
  /// [values] 数值列表
  /// [sourceUnit] 源单位
  /// [targetUnit] 目标单位
  /// 
  /// 返回转换映射表（原值 -> 转换值）
  static Map<double, double> createConversionTable(
    List<double> values, 
    UnitType sourceUnit, 
    UnitType targetUnit,
  ) {
    final conversionTable = <double, double>{};
    
    for (final value in values) {
      conversionTable[value] = convert(value, sourceUnit, targetUnit);
    }
    
    return conversionTable;
  }

  /// 数值精度舍入
  /// 
  /// [value] 要舍入的数值
  /// [decimalPlaces] 小数位数
  /// 
  /// 返回舍入后的数值
  static double _roundToPrecision(double value, int decimalPlaces) {
    final factor = pow(10, decimalPlaces);
    return (value * factor).round() / factor;
  }

  /// 获取常用转换示例
  /// 
  /// 返回常用的转换示例映射
  static Map<String, Map<String, String>> getCommonConversions() {
    return {
      '管道外径': {
        '60.3 mm': formatValue(convert(60.3, UnitType.millimeter, UnitType.inch), UnitType.inch),
        '114.3 mm': formatValue(convert(114.3, UnitType.millimeter, UnitType.inch), UnitType.inch),
        '219.1 mm': formatValue(convert(219.1, UnitType.millimeter, UnitType.inch), UnitType.inch),
      },
      '筒刀规格': {
        '25.4 mm': formatValue(convert(25.4, UnitType.millimeter, UnitType.inch), UnitType.inch),
        '19.1 mm': formatValue(convert(19.1, UnitType.millimeter, UnitType.inch), UnitType.inch),
      },
      '垫片厚度': {
        '1.5 mm': formatValue(convert(1.5, UnitType.millimeter, UnitType.inch), UnitType.inch),
        '3.0 mm': formatValue(convert(3.0, UnitType.millimeter, UnitType.inch), UnitType.inch),
        '6.0 mm': formatValue(convert(6.0, UnitType.millimeter, UnitType.inch), UnitType.inch),
      },
    };
  }

  /// 验证单位转换的数学正确性
  /// 
  /// 执行一系列测试来验证转换算法的正确性
  /// 
  /// 返回验证结果（true表示所有测试通过）
  static bool validateConversionMath() {
    final testCases = [
      {'value': 25.4, 'mm_to_inch': 1.0},
      {'value': 50.8, 'mm_to_inch': 2.0},
      {'value': 1.0, 'inch_to_mm': 25.4},
      {'value': 2.0, 'inch_to_mm': 50.8},
    ];
    
    for (final testCase in testCases) {
      final value = testCase['value'] as double;
      
      if (testCase.containsKey('mm_to_inch')) {
        final expected = testCase['mm_to_inch'] as double;
        final actual = convert(value, UnitType.millimeter, UnitType.inch);
        if ((actual - expected).abs() > 1e-3) {
          return false;
        }
      }
      
      if (testCase.containsKey('inch_to_mm')) {
        final expected = testCase['inch_to_mm'] as double;
        final actual = convert(value, UnitType.inch, UnitType.millimeter);
        if ((actual - expected).abs() > 1e-3) {
          return false;
        }
      }
    }
    
    // 测试往返转换精度
    final testValues = [1.0, 25.4, 50.8, 100.0, 219.1];
    for (final value in testValues) {
      final mmToInch = convert(value, UnitType.millimeter, UnitType.inch);
      final backToMm = convert(mmToInch, UnitType.inch, UnitType.millimeter);
      if ((value - backToMm).abs() > 1e-3) {
        return false;
      }
    }
    
    return true;
  }
}