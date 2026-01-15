import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/calculation_result.dart';
import '../models/calculation_parameters.dart';
import '../models/enums.dart';

/// 安全预警级别
enum SafetyWarningLevel {
  info,     // 信息提示
  warning,  // 警告
  danger,   // 危险
  critical, // 严重危险
}

/// 安全预警类型
enum SafetyWarningType {
  parameterRange,    // 参数范围警告
  calculationResult, // 计算结果警告
  operationSafety,   // 操作安全警告
  equipmentLimit,    // 设备限制警告
  materialStress,    // 材料应力警告
}

/// 安全预警信息
class SafetyWarning {
  final SafetyWarningLevel level;
  final SafetyWarningType type;
  final String title;
  final String message;
  final String? recommendation;
  final Map<String, dynamic>? relatedData;
  final DateTime timestamp;

  SafetyWarning({
    required this.level,
    required this.type,
    required this.title,
    required this.message,
    this.recommendation,
    this.relatedData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 获取警告级别的颜色
  Color get levelColor {
    switch (level) {
      case SafetyWarningLevel.info:
        return Colors.blue;
      case SafetyWarningLevel.warning:
        return Colors.orange;
      case SafetyWarningLevel.danger:
        return Colors.red;
      case SafetyWarningLevel.critical:
        return Colors.red[900]!;
    }
  }

  /// 获取警告级别的图标
  IconData get levelIcon {
    switch (level) {
      case SafetyWarningLevel.info:
        return Icons.info_outline;
      case SafetyWarningLevel.warning:
        return Icons.warning_amber_outlined;
      case SafetyWarningLevel.danger:
        return Icons.error_outline;
      case SafetyWarningLevel.critical:
        return Icons.dangerous_outlined;
    }
  }

  Map<String, dynamic> toJson() => {
    'level': level.toString(),
    'type': type.toString(),
    'title': title,
    'message': message,
    'recommendation': recommendation,
    'related_data': relatedData,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SafetyWarning.fromJson(Map<String, dynamic> json) => SafetyWarning(
    level: SafetyWarningLevel.values.firstWhere(
      (l) => l.toString() == json['level'],
    ),
    type: SafetyWarningType.values.firstWhere(
      (t) => t.toString() == json['type'],
    ),
    title: json['title'],
    message: json['message'],
    recommendation: json['recommendation'],
    relatedData: json['related_data'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

/// 安全范围配置
class SafetyRangeConfig {
  // 管道参数安全范围
  static const double minPipeDiameter = 50.0;    // 最小管径 (mm)
  static const double maxPipeDiameter = 2000.0;  // 最大管径 (mm)
  static const double minWallThickness = 3.0;    // 最小壁厚 (mm)
  static const double maxWallThickness = 100.0;  // 最大壁厚 (mm)
  
  // 筒刀参数安全范围
  static const double minCutterDiameter = 10.0;  // 最小筒刀直径 (mm)
  static const double maxCutterDiameter = 200.0; // 最大筒刀直径 (mm)
  
  // 行程安全范围
  static const double minStroke = 5.0;           // 最小行程 (mm)
  static const double maxStroke = 1000.0;       // 最大行程 (mm)
  static const double maxSafeStroke = 800.0;    // 安全行程上限 (mm)
  
  // 压力相关安全范围
  static const double maxWorkingPressure = 10.0; // 最大工作压力 (MPa)
  static const double safetyFactor = 2.0;        // 安全系数
  
  // 螺纹咬合安全范围
  static const double minThreadEngagement = 3.0; // 最小螺纹咬合长度 (mm)
  static const double safeThreadEngagement = 5.0; // 安全螺纹咬合长度 (mm)
  
  // 温度安全范围
  static const double minOperatingTemp = -40.0;  // 最低操作温度 (°C)
  static const double maxOperatingTemp = 200.0;  // 最高操作温度 (°C)
}

/// 安全预警系统
/// 
/// 负责检查计算结果的安全性，提供安全预警和建议
class SafetyWarningSystem {
  static SafetyWarningSystem? _instance;
  
  /// 单例模式
  SafetyWarningSystem._internal();
  
  factory SafetyWarningSystem() {
    _instance ??= SafetyWarningSystem._internal();
    return _instance!;
  }
  
  /// 检查开孔计算的安全性
  List<SafetyWarning> checkHoleCalculationSafety(HoleCalculationResult result) {
    final warnings = <SafetyWarning>[];
    final params = result.parameters as HoleParameters;
    
    // 检查管道参数安全性
    warnings.addAll(_checkPipeParameterSafety(params));
    
    // 检查筒刀参数安全性
    warnings.addAll(_checkCutterParameterSafety(params));
    
    // 检查计算结果安全性
    warnings.addAll(_checkHoleResultSafety(result));
    
    // 检查操作安全性
    warnings.addAll(_checkHoleOperationSafety(result));
    
    return warnings;
  }
  
  /// 检查手动开孔计算的安全性
  List<SafetyWarning> checkManualHoleCalculationSafety(ManualHoleResult result) {
    final warnings = <SafetyWarning>[];
    final params = result.parameters as ManualHoleParameters;
    
    // 检查螺纹咬合安全性
    warnings.addAll(_checkThreadEngagementSafety(result.threadEngagement, '手动开孔'));
    
    // 检查行程安全性
    warnings.addAll(_checkStrokeSafety(result.totalStroke, '手动开孔总行程'));
    
    // 检查参数比例合理性
    if (params.pValue > params.lValue + params.jValue) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.parameterRange,
        title: '参数比例异常',
        message: 'P值(${params.pValue.toStringAsFixed(1)}mm)过大，超过L+J值(${(params.lValue + params.jValue).toStringAsFixed(1)}mm)',
        recommendation: '请检查P值设置是否正确，过大的P值可能导致设备损坏',
      ));
    }
    
    return warnings;
  }
  
  /// 检查封堵计算的安全性
  List<SafetyWarning> checkSealingCalculationSafety(SealingResult result) {
    final warnings = <SafetyWarning>[];
    final params = result.parameters as SealingParameters;
    
    // 检查封堵深度安全性
    final sealingDepth = result.totalStroke - result.guideWheelStroke;
    if (sealingDepth < 10.0) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.danger,
        type: SafetyWarningType.operationSafety,
        title: '封堵深度不足',
        message: '封堵深度仅为${sealingDepth.toStringAsFixed(1)}mm，可能无法有效封堵',
        recommendation: '建议增加D值或检查其他参数设置，确保封堵深度至少10mm',
      ));
    } else if (sealingDepth > 200.0) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.operationSafety,
        title: '封堵深度过大',
        message: '封堵深度为${sealingDepth.toStringAsFixed(1)}mm，可能导致封堵器损坏',
        recommendation: '建议检查D值设置，过深的封堵可能影响后续解堵操作',
      ));
    }
    
    // 检查E值合理性（管内径相关）
    if (params.eValue < 20.0) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.parameterRange,
        title: 'E值偏小',
        message: 'E值(${params.eValue.toStringAsFixed(1)}mm)较小，请确认管道内径计算是否正确',
        recommendation: 'E值通常接近管道内径，过小的E值可能导致计算错误',
      ));
    }
    
    // 检查行程安全性
    warnings.addAll(_checkStrokeSafety(result.totalStroke, '封堵总行程'));
    warnings.addAll(_checkStrokeSafety(result.guideWheelStroke, '导向轮行程'));
    
    return warnings;
  }
  
  /// 检查下塞堵计算的安全性
  List<SafetyWarning> checkPlugCalculationSafety(PlugResult result) {
    final warnings = <SafetyWarning>[];
    final params = result.parameters as PlugParameters;
    
    // 检查螺纹咬合安全性
    warnings.addAll(_checkThreadEngagementSafety(result.threadEngagement, '下塞堵'));
    
    // 检查行程安全性
    warnings.addAll(_checkStrokeSafety(result.totalStroke, '下塞堵总行程'));
    
    // 检查下塞堵深度
    final plugDepth = result.totalStroke - result.emptyStroke;
    if (plugDepth < 5.0) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.operationSafety,
        title: '下塞堵深度不足',
        message: '下塞堵深度仅为${plugDepth.toStringAsFixed(1)}mm，可能影响塞堵效果',
        recommendation: '建议增加N值或检查其他参数，确保足够的塞堵深度',
      ));
    }
    
    // 检查参数合理性
    if (params.nValue > params.mValue + params.kValue) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.parameterRange,
        title: '参数设置异常',
        message: 'N值超过M+K值，请检查参数设置的合理性',
        recommendation: '通常N值不应超过M+K值，请确认测量数据是否正确',
      ));
    }
    
    return warnings;
  }
  
  /// 检查下塞柄计算的安全性
  List<SafetyWarning> checkStemCalculationSafety(StemResult result) {
    final warnings = <SafetyWarning>[];
    final params = result.parameters as StemParameters;
    
    // 检查行程安全性
    warnings.addAll(_checkStrokeSafety(result.totalStroke, '下塞柄总行程'));
    
    // 检查各参数的合理性
    if (params.hValue > result.totalStroke * 0.8) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.parameterRange,
        title: 'H值占比过大',
        message: 'H值占总行程的${(params.hValue / result.totalStroke * 100).toStringAsFixed(1)}%，可能影响操作稳定性',
        recommendation: '建议检查H值设置，通常不应超过总行程的80%',
      ));
    }
    
    if (params.gasketThickness > 25.0) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.equipmentLimit,
        title: '垫片厚度过大',
        message: '垫片厚度为${params.gasketThickness.toStringAsFixed(1)}mm，超出常规范围',
        recommendation: '请确认垫片规格是否正确，过厚的垫片可能影响密封效果',
      ));
    }
    
    return warnings;
  }
  
  /// 检查管道参数安全性
  List<SafetyWarning> _checkPipeParameterSafety(HoleParameters params) {
    final warnings = <SafetyWarning>[];
    
    // 检查管径范围
    if (params.outerDiameter < SafetyRangeConfig.minPipeDiameter) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.danger,
        type: SafetyWarningType.parameterRange,
        title: '管外径过小',
        message: '管外径${params.outerDiameter.toStringAsFixed(1)}mm小于最小安全值${SafetyRangeConfig.minPipeDiameter}mm',
        recommendation: '请确认管道规格，过小的管径可能不适合开孔作业',
      ));
    } else if (params.outerDiameter > SafetyRangeConfig.maxPipeDiameter) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.parameterRange,
        title: '管外径过大',
        message: '管外径${params.outerDiameter.toStringAsFixed(1)}mm超过常规范围${SafetyRangeConfig.maxPipeDiameter}mm',
        recommendation: '请确认管道规格和设备能力，大管径作业需要特殊设备',
      ));
    }
    
    // 检查壁厚
    final wallThickness = (params.outerDiameter - params.innerDiameter) / 2;
    if (wallThickness < SafetyRangeConfig.minWallThickness) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.critical,
        type: SafetyWarningType.materialStress,
        title: '管道壁厚不足',
        message: '管道壁厚${wallThickness.toStringAsFixed(1)}mm过薄，存在安全风险',
        recommendation: '薄壁管道开孔作业风险极高，建议重新评估作业方案',
      ));
    } else if (wallThickness > SafetyRangeConfig.maxWallThickness) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.equipmentLimit,
        title: '管道壁厚过大',
        message: '管道壁厚${wallThickness.toStringAsFixed(1)}mm较厚，可能超出设备能力',
        recommendation: '厚壁管道需要大功率设备，请确认设备规格是否匹配',
      ));
    }
    
    return warnings;
  }
  
  /// 检查筒刀参数安全性
  List<SafetyWarning> _checkCutterParameterSafety(HoleParameters params) {
    final warnings = <SafetyWarning>[];
    
    // 检查筒刀外径
    if (params.cutterOuterDiameter < SafetyRangeConfig.minCutterDiameter) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.parameterRange,
        title: '筒刀外径过小',
        message: '筒刀外径${params.cutterOuterDiameter.toStringAsFixed(1)}mm可能过小',
        recommendation: '请确认筒刀规格是否正确',
      ));
    } else if (params.cutterOuterDiameter > SafetyRangeConfig.maxCutterDiameter) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.parameterRange,
        title: '筒刀外径过大',
        message: '筒刀外径${params.cutterOuterDiameter.toStringAsFixed(1)}mm较大',
        recommendation: '大直径筒刀需要更大的切削力，请确认设备能力',
      ));
    }
    
    // 检查筒刀与管道的匹配性
    final wallThickness = (params.outerDiameter - params.innerDiameter) / 2;
    final pipeWallArea = math.sqrt(params.outerDiameter * params.outerDiameter - params.innerDiameter * params.innerDiameter);
    
    if (params.cutterOuterDiameter > pipeWallArea * 0.9) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.danger,
        type: SafetyWarningType.operationSafety,
        title: '筒刀尺寸不匹配',
        message: '筒刀外径接近或超过管道壁厚区域，可能导致切削失败',
        recommendation: '建议选择更小直径的筒刀，或重新确认管道参数',
      ));
    }
    
    return warnings;
  }
  
  /// 检查开孔结果安全性
  List<SafetyWarning> _checkHoleResultSafety(HoleCalculationResult result) {
    final warnings = <SafetyWarning>[];
    
    // 检查切削距离
    if (result.cuttingDistance < 0) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.critical,
        type: SafetyWarningType.calculationResult,
        title: '切削距离为负值',
        message: '筒刀切削距离为${result.cuttingDistance.toStringAsFixed(1)}mm，无法进行切削',
        recommendation: '筒刀外径过大，请选择更小的筒刀或重新确认参数',
      ));
    } else if (result.cuttingDistance < 2.0) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.operationSafety,
        title: '切削距离过小',
        message: '筒刀切削距离仅为${result.cuttingDistance.toStringAsFixed(1)}mm',
        recommendation: '切削距离过小可能导致切削不完整，建议调整筒刀规格',
      ));
    }
    
    // 检查掉板弦高
    if (result.chordHeight < 0) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.danger,
        type: SafetyWarningType.calculationResult,
        title: '掉板弦高为负值',
        message: '掉板弦高为${result.chordHeight.toStringAsFixed(1)}mm，掉板无法通过',
        recommendation: '筒刀内径过大，请选择更小内径的筒刀',
      ));
    }
    
    // 检查行程安全性
    warnings.addAll(_checkStrokeSafety(result.totalStroke, '开孔总行程'));
    warnings.addAll(_checkStrokeSafety(result.plateStroke, '掉板总行程'));
    
    return warnings;
  }
  
  /// 检查开孔操作安全性
  List<SafetyWarning> _checkHoleOperationSafety(HoleCalculationResult result) {
    final warnings = <SafetyWarning>[];
    
    // 检查行程差异合理性
    final strokeDifference = result.plateStroke - result.totalStroke;
    if (strokeDifference < 5.0) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.operationSafety,
        title: '掉板行程差异过小',
        message: '掉板行程与开孔行程差异仅为${strokeDifference.toStringAsFixed(1)}mm',
        recommendation: '行程差异过小可能导致掉板操作困难，请检查R值设置',
      ));
    }
    
    // 检查空行程合理性
    if (result.emptyStroke > result.totalStroke * 0.8) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.info,
        type: SafetyWarningType.operationSafety,
        title: '空行程占比较大',
        message: '空行程占总行程的${(result.emptyStroke / result.totalStroke * 100).toStringAsFixed(1)}%',
        recommendation: '空行程占比较大，实际切削行程较短，请确认是否符合预期',
      ));
    }
    
    return warnings;
  }
  
  /// 检查螺纹咬合安全性
  List<SafetyWarning> _checkThreadEngagementSafety(double threadEngagement, String context) {
    final warnings = <SafetyWarning>[];
    
    if (threadEngagement < 0) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.critical,
        type: SafetyWarningType.operationSafety,
        title: '螺纹咬合长度为负值',
        message: '$context螺纹咬合长度为${threadEngagement.toStringAsFixed(1)}mm，无法正常连接',
        recommendation: 'T值应大于W值，请检查参数设置',
      ));
    } else if (threadEngagement < SafetyRangeConfig.minThreadEngagement) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.danger,
        type: SafetyWarningType.operationSafety,
        title: '螺纹咬合长度不足',
        message: '$context螺纹咬合长度仅为${threadEngagement.toStringAsFixed(1)}mm，存在安全风险',
        recommendation: '螺纹咬合长度至少应为${SafetyRangeConfig.minThreadEngagement}mm，请调整T值或W值',
      ));
    } else if (threadEngagement < SafetyRangeConfig.safeThreadEngagement) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.operationSafety,
        title: '螺纹咬合长度偏小',
        message: '$context螺纹咬合长度为${threadEngagement.toStringAsFixed(1)}mm，建议增加',
        recommendation: '为确保连接强度，建议螺纹咬合长度至少为${SafetyRangeConfig.safeThreadEngagement}mm',
      ));
    }
    
    return warnings;
  }
  
  /// 检查行程安全性
  List<SafetyWarning> _checkStrokeSafety(double stroke, String context) {
    final warnings = <SafetyWarning>[];
    
    if (stroke < SafetyRangeConfig.minStroke) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.parameterRange,
        title: '行程过小',
        message: '$context为${stroke.toStringAsFixed(1)}mm，可能过小',
        recommendation: '请检查参数设置，确保行程满足作业要求',
      ));
    } else if (stroke > SafetyRangeConfig.maxStroke) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.danger,
        type: SafetyWarningType.equipmentLimit,
        title: '行程超出设备限制',
        message: '$context为${stroke.toStringAsFixed(1)}mm，超出设备最大行程',
        recommendation: '请检查参数设置或更换更大行程的设备',
      ));
    } else if (stroke > SafetyRangeConfig.maxSafeStroke) {
      warnings.add(SafetyWarning(
        level: SafetyWarningLevel.warning,
        type: SafetyWarningType.operationSafety,
        title: '行程较大',
        message: '$context为${stroke.toStringAsFixed(1)}mm，接近安全上限',
        recommendation: '大行程作业需要特别注意操作安全，建议分段进行',
      ));
    }
    
    return warnings;
  }
  
  /// 获取安全预警统计
  Map<String, int> getWarningStatistics(List<SafetyWarning> warnings) {
    final stats = <String, int>{
      'total': warnings.length,
      'info': 0,
      'warning': 0,
      'danger': 0,
      'critical': 0,
    };
    
    for (final warning in warnings) {
      switch (warning.level) {
        case SafetyWarningLevel.info:
          stats['info'] = (stats['info'] ?? 0) + 1;
          break;
        case SafetyWarningLevel.warning:
          stats['warning'] = (stats['warning'] ?? 0) + 1;
          break;
        case SafetyWarningLevel.danger:
          stats['danger'] = (stats['danger'] ?? 0) + 1;
          break;
        case SafetyWarningLevel.critical:
          stats['critical'] = (stats['critical'] ?? 0) + 1;
          break;
      }
    }
    
    return stats;
  }
  
  /// 检查是否有严重安全问题
  bool hasCriticalWarnings(List<SafetyWarning> warnings) {
    return warnings.any((w) => w.level == SafetyWarningLevel.critical);
  }
  
  /// 检查是否有危险警告
  bool hasDangerWarnings(List<SafetyWarning> warnings) {
    return warnings.any((w) => w.level == SafetyWarningLevel.danger);
  }
  
  /// 获取最高警告级别
  SafetyWarningLevel? getHighestWarningLevel(List<SafetyWarning> warnings) {
    if (warnings.isEmpty) return null;
    
    if (hasCriticalWarnings(warnings)) return SafetyWarningLevel.critical;
    if (hasDangerWarnings(warnings)) return SafetyWarningLevel.danger;
    if (warnings.any((w) => w.level == SafetyWarningLevel.warning)) return SafetyWarningLevel.warning;
    return SafetyWarningLevel.info;
  }
}