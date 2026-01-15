import 'validation_result.dart';
import 'enums.dart';
import '../utils/validators.dart';

/// 计算参数基类
abstract class CalculationParameters {
  /// 参数验证
  ValidationResult validate();
  
  /// 转换为JSON格式
  Map<String, dynamic> toJson();
  
  /// 从JSON格式创建对象
  static CalculationParameters fromJson(Map<String, dynamic> json, CalculationType type) {
    switch (type) {
      case CalculationType.hole:
        return HoleParameters.fromJson(json);
      case CalculationType.manualHole:
        return ManualHoleParameters.fromJson(json);
      case CalculationType.sealing:
        return SealingParameters.fromJson(json);
      case CalculationType.plug:
        return PlugParameters.fromJson(json);
      case CalculationType.stem:
        return StemParameters.fromJson(json);
    }
  }
}

/// 开孔参数类
class HoleParameters extends CalculationParameters {
  /// 管外径 (mm)
  final double outerDiameter;
  
  /// 管内径 (mm)
  final double innerDiameter;
  
  /// 筒刀外径 (mm)
  final double cutterOuterDiameter;
  
  /// 筒刀内径 (mm)
  final double cutterInnerDiameter;
  
  /// A值 - 中心钻关联联箱口 (mm)
  final double aValue;
  
  /// B值 - 夹板顶到管外壁 (mm)
  final double bValue;
  
  /// R值 - 中心钻尖到筒刀 (mm)
  final double rValue;
  
  /// 初始值 (mm)
  final double initialValue;
  
  /// 垫片厚度 (mm)
  final double gasketThickness;

  HoleParameters({
    required this.outerDiameter,
    required this.innerDiameter,
    required this.cutterOuterDiameter,
    required this.cutterInnerDiameter,
    required this.aValue,
    required this.bValue,
    required this.rValue,
    required this.initialValue,
    required this.gasketThickness,
  });

  @override
  ValidationResult validate() {
    final validations = <ValidationResult>[
      // 验证管道参数
      Validators.validatePipeParameters(outerDiameter, innerDiameter),
      
      // 验证筒刀参数
      Validators.validateCutterParameters(cutterOuterDiameter, cutterInnerDiameter),
      
      // 验证其他参数为正数
      Validators.validatePositiveNumber(aValue, 'A值'),
      Validators.validatePositiveNumber(bValue, 'B值'),
      Validators.validatePositiveNumber(rValue, 'R值'),
      Validators.validatePositiveNumber(initialValue, '初始值', allowZero: true),
      Validators.validatePositiveNumber(gasketThickness, '垫片厚度', allowZero: true),
      
      // 开孔特定的验证规则
      _validateHoleSpecificRules(),
    ];

    return Validators.combineValidations(validations);
  }

  /// 开孔特定的验证规则
  ValidationResult _validateHoleSpecificRules() {
    final validations = <ValidationResult>[];
    
    // 验证筒刀尺寸与管道尺寸的关系
    final pipeWallThickness = (outerDiameter - innerDiameter) / 2;
    final cutterWallThickness = (cutterOuterDiameter - cutterInnerDiameter) / 2;
    
    // 筒刀外径不应超过管道壁厚区域
    final maxCutterOuterDiameter = outerDiameter - innerDiameter;
    if (cutterOuterDiameter > maxCutterOuterDiameter) {
      validations.add(ValidationResult.warning(
        '筒刀外径(${cutterOuterDiameter.toStringAsFixed(1)}mm)可能过大，'
        '建议不超过管道壁厚区域(${maxCutterOuterDiameter.toStringAsFixed(1)}mm)'
      ));
    }
    
    // 筒刀内径应小于管内径
    if (cutterInnerDiameter >= innerDiameter) {
      validations.add(ValidationResult.error(
        '筒刀内径(${cutterInnerDiameter.toStringAsFixed(1)}mm)不能大于等于管内径(${innerDiameter.toStringAsFixed(1)}mm)'
      ));
    }
    
    // 验证A值的合理范围（通常在10-200mm之间）
    if (aValue < 10.0) {
      validations.add(ValidationResult.warning('A值较小(${aValue.toStringAsFixed(1)}mm)，请确认中心钻关联联箱口距离'));
    } else if (aValue > 200.0) {
      validations.add(ValidationResult.warning('A值较大(${aValue.toStringAsFixed(1)}mm)，请确认中心钻关联联箱口距离'));
    }
    
    // 验证B值的合理范围（通常在5-100mm之间）
    if (bValue < 5.0) {
      validations.add(ValidationResult.warning('B值较小(${bValue.toStringAsFixed(1)}mm)，请确认夹板顶到管外壁距离'));
    } else if (bValue > 100.0) {
      validations.add(ValidationResult.warning('B值较大(${bValue.toStringAsFixed(1)}mm)，请确认夹板顶到管外壁距离'));
    }
    
    // 验证R值的合理范围（通常在5-50mm之间）
    if (rValue < 5.0) {
      validations.add(ValidationResult.warning('R值较小(${rValue.toStringAsFixed(1)}mm)，请确认中心钻尖到筒刀距离'));
    } else if (rValue > 50.0) {
      validations.add(ValidationResult.warning('R值较大(${rValue.toStringAsFixed(1)}mm)，请确认中心钻尖到筒刀距离'));
    }
    
    // 验证垫片厚度的合理范围（通常在0-10mm之间）
    if (gasketThickness > 10.0) {
      validations.add(ValidationResult.warning('垫片厚度较大(${gasketThickness.toStringAsFixed(1)}mm)，请确认是否正确'));
    }
    
    // 验证初始值的合理范围（通常在0-20mm之间）
    if (initialValue > 20.0) {
      validations.add(ValidationResult.warning('初始值较大(${initialValue.toStringAsFixed(1)}mm)，请确认是否正确'));
    }
    
    return Validators.combineValidations(validations);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'outer_diameter': outerDiameter,
      'inner_diameter': innerDiameter,
      'cutter_outer_diameter': cutterOuterDiameter,
      'cutter_inner_diameter': cutterInnerDiameter,
      'a_value': aValue,
      'b_value': bValue,
      'r_value': rValue,
      'initial_value': initialValue,
      'gasket_thickness': gasketThickness,
    };
  }

  factory HoleParameters.fromJson(Map<String, dynamic> json) {
    return HoleParameters(
      outerDiameter: (json['outer_diameter'] as num).toDouble(),
      innerDiameter: (json['inner_diameter'] as num).toDouble(),
      cutterOuterDiameter: (json['cutter_outer_diameter'] as num).toDouble(),
      cutterInnerDiameter: (json['cutter_inner_diameter'] as num).toDouble(),
      aValue: (json['a_value'] as num).toDouble(),
      bValue: (json['b_value'] as num).toDouble(),
      rValue: (json['r_value'] as num).toDouble(),
      initialValue: (json['initial_value'] as num).toDouble(),
      gasketThickness: (json['gasket_thickness'] as num).toDouble(),
    );
  }

  /// 创建副本
  HoleParameters copyWith({
    double? outerDiameter,
    double? innerDiameter,
    double? cutterOuterDiameter,
    double? cutterInnerDiameter,
    double? aValue,
    double? bValue,
    double? rValue,
    double? initialValue,
    double? gasketThickness,
  }) {
    return HoleParameters(
      outerDiameter: outerDiameter ?? this.outerDiameter,
      innerDiameter: innerDiameter ?? this.innerDiameter,
      cutterOuterDiameter: cutterOuterDiameter ?? this.cutterOuterDiameter,
      cutterInnerDiameter: cutterInnerDiameter ?? this.cutterInnerDiameter,
      aValue: aValue ?? this.aValue,
      bValue: bValue ?? this.bValue,
      rValue: rValue ?? this.rValue,
      initialValue: initialValue ?? this.initialValue,
      gasketThickness: gasketThickness ?? this.gasketThickness,
    );
  }

  @override
  String toString() {
    return 'HoleParameters(outerDiameter: $outerDiameter, innerDiameter: $innerDiameter, '
           'cutterOuterDiameter: $cutterOuterDiameter, cutterInnerDiameter: $cutterInnerDiameter, '
           'aValue: $aValue, bValue: $bValue, rValue: $rValue, '
           'initialValue: $initialValue, gasketThickness: $gasketThickness)';
  }
}

/// 手动开孔参数类
class ManualHoleParameters extends CalculationParameters {
  /// L值 (mm)
  final double lValue;
  
  /// J值 (mm)
  final double jValue;
  
  /// P值 (mm)
  final double pValue;
  
  /// T值 (mm)
  final double tValue;
  
  /// W值 (mm)
  final double wValue;

  ManualHoleParameters({
    required this.lValue,
    required this.jValue,
    required this.pValue,
    required this.tValue,
    required this.wValue,
  });

  @override
  ValidationResult validate() {
    final validations = <ValidationResult>[
      // 验证所有参数为正数
      Validators.validatePositiveNumber(lValue, 'L值'),
      Validators.validatePositiveNumber(jValue, 'J值'),
      Validators.validatePositiveNumber(pValue, 'P值'),
      
      // 验证螺纹咬合参数
      Validators.validateThreadEngagementParameters(tValue, wValue),
    ];

    return Validators.combineValidations(validations);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'l_value': lValue,
      'j_value': jValue,
      'p_value': pValue,
      't_value': tValue,
      'w_value': wValue,
    };
  }

  factory ManualHoleParameters.fromJson(Map<String, dynamic> json) {
    return ManualHoleParameters(
      lValue: (json['l_value'] as num).toDouble(),
      jValue: (json['j_value'] as num).toDouble(),
      pValue: (json['p_value'] as num).toDouble(),
      tValue: (json['t_value'] as num).toDouble(),
      wValue: (json['w_value'] as num).toDouble(),
    );
  }

  /// 创建副本
  ManualHoleParameters copyWith({
    double? lValue,
    double? jValue,
    double? pValue,
    double? tValue,
    double? wValue,
  }) {
    return ManualHoleParameters(
      lValue: lValue ?? this.lValue,
      jValue: jValue ?? this.jValue,
      pValue: pValue ?? this.pValue,
      tValue: tValue ?? this.tValue,
      wValue: wValue ?? this.wValue,
    );
  }

  @override
  String toString() {
    return 'ManualHoleParameters(lValue: $lValue, jValue: $jValue, pValue: $pValue, '
           'tValue: $tValue, wValue: $wValue)';
  }
}

/// 封堵参数类
class SealingParameters extends CalculationParameters {
  /// R值 (mm)
  final double rValue;
  
  /// B值 (mm)
  final double bValue;
  
  /// D值 (mm)
  final double dValue;
  
  /// E值 - 管外径减壁厚 (mm)
  final double eValue;
  
  /// 垫子厚度 (mm)
  final double gasketThickness;
  
  /// 初始值 (mm)
  final double initialValue;

  SealingParameters({
    required this.rValue,
    required this.bValue,
    required this.dValue,
    required this.eValue,
    required this.gasketThickness,
    required this.initialValue,
  });

  @override
  ValidationResult validate() {
    final validations = <ValidationResult>[
      // 验证基本参数为正数
      Validators.validatePositiveNumber(rValue, 'R值'),
      Validators.validatePositiveNumber(bValue, 'B值'),
      Validators.validatePositiveNumber(dValue, 'D值'),
      Validators.validatePositiveNumber(gasketThickness, '垫子厚度', allowZero: true),
      Validators.validatePositiveNumber(initialValue, '初始值', allowZero: true),
      
      // 验证E值（特殊验证）
      Validators.validateEValue(eValue),
      
      // 封堵特定的验证规则
      _validateSealingSpecificRules(),
    ];

    return Validators.combineValidations(validations);
  }

  /// 封堵特定的验证规则
  ValidationResult _validateSealingSpecificRules() {
    final validations = <ValidationResult>[];
    
    // 验证R值的合理范围（通常在5-100mm之间）
    if (rValue < 5.0) {
      validations.add(ValidationResult.warning('R值较小(${rValue.toStringAsFixed(1)}mm)，请确认导向轮到管线距离'));
    } else if (rValue > 100.0) {
      validations.add(ValidationResult.warning('R值较大(${rValue.toStringAsFixed(1)}mm)，请确认导向轮到管线距离'));
    }
    
    // 验证B值的合理范围（通常在5-50mm之间）
    if (bValue < 5.0) {
      validations.add(ValidationResult.warning('B值较小(${bValue.toStringAsFixed(1)}mm)，请确认夹板顶到管外壁距离'));
    } else if (bValue > 50.0) {
      validations.add(ValidationResult.warning('B值较大(${bValue.toStringAsFixed(1)}mm)，请确认夹板顶到管外壁距离'));
    }
    
    // 验证D值的合理范围（通常在10-200mm之间）
    if (dValue < 10.0) {
      validations.add(ValidationResult.warning('D值较小(${dValue.toStringAsFixed(1)}mm)，请确认封堵器到管线距离'));
    } else if (dValue > 200.0) {
      validations.add(ValidationResult.warning('D值较大(${dValue.toStringAsFixed(1)}mm)，请确认封堵器到管线距离'));
    }
    
    // 验证E值的合理范围（应该是管内径的近似值）
    if (eValue < 20.0) {
      validations.add(ValidationResult.warning('E值较小(${eValue.toStringAsFixed(1)}mm)，请确认管道内径计算'));
    } else if (eValue > 2000.0) {
      validations.add(ValidationResult.warning('E值较大(${eValue.toStringAsFixed(1)}mm)，请确认管道内径计算'));
    }
    
    // 验证垫子厚度的合理范围（通常在0-20mm之间）
    if (gasketThickness > 20.0) {
      validations.add(ValidationResult.warning('垫子厚度较大(${gasketThickness.toStringAsFixed(1)}mm)，请确认是否正确'));
    }
    
    // 验证初始值的合理范围（通常在0-30mm之间）
    if (initialValue > 30.0) {
      validations.add(ValidationResult.warning('初始值较大(${initialValue.toStringAsFixed(1)}mm)，请确认是否正确'));
    }
    
    // 验证D值应该大于R值（封堵器应该比导向轮更深入）
    if (dValue <= rValue) {
      validations.add(ValidationResult.warning('D值(${dValue.toStringAsFixed(1)}mm)应该大于R值(${rValue.toStringAsFixed(1)}mm)，确保封堵器比导向轮更深入'));
    }
    
    return Validators.combineValidations(validations);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'r_value': rValue,
      'b_value': bValue,
      'd_value': dValue,
      'e_value': eValue,
      'gasket_thickness': gasketThickness,
      'initial_value': initialValue,
    };
  }

  factory SealingParameters.fromJson(Map<String, dynamic> json) {
    return SealingParameters(
      rValue: (json['r_value'] as num).toDouble(),
      bValue: (json['b_value'] as num).toDouble(),
      dValue: (json['d_value'] as num).toDouble(),
      eValue: (json['e_value'] as num).toDouble(),
      gasketThickness: (json['gasket_thickness'] as num).toDouble(),
      initialValue: (json['initial_value'] as num).toDouble(),
    );
  }

  /// 创建副本
  SealingParameters copyWith({
    double? rValue,
    double? bValue,
    double? dValue,
    double? eValue,
    double? gasketThickness,
    double? initialValue,
  }) {
    return SealingParameters(
      rValue: rValue ?? this.rValue,
      bValue: bValue ?? this.bValue,
      dValue: dValue ?? this.dValue,
      eValue: eValue ?? this.eValue,
      gasketThickness: gasketThickness ?? this.gasketThickness,
      initialValue: initialValue ?? this.initialValue,
    );
  }

  @override
  String toString() {
    return 'SealingParameters(rValue: $rValue, bValue: $bValue, dValue: $dValue, '
           'eValue: $eValue, gasketThickness: $gasketThickness, initialValue: $initialValue)';
  }
}

/// 下塞堵参数类
class PlugParameters extends CalculationParameters {
  /// M值 (mm)
  final double mValue;
  
  /// K值 (mm)
  final double kValue;
  
  /// N值 (mm)
  final double nValue;
  
  /// T值 (mm)
  final double tValue;
  
  /// W值 (mm)
  final double wValue;

  PlugParameters({
    required this.mValue,
    required this.kValue,
    required this.nValue,
    required this.tValue,
    required this.wValue,
  });

  @override
  ValidationResult validate() {
    final validations = <ValidationResult>[
      // 验证基本参数为正数
      Validators.validatePositiveNumber(mValue, 'M值'),
      Validators.validatePositiveNumber(kValue, 'K值'),
      Validators.validatePositiveNumber(nValue, 'N值'),
      
      // 验证螺纹咬合参数
      Validators.validateThreadEngagementParameters(tValue, wValue),
      
      // 下塞堵特定的验证规则
      _validatePlugSpecificRules(),
    ];

    return Validators.combineValidations(validations);
  }

  /// 下塞堵特定的验证规则
  ValidationResult _validatePlugSpecificRules() {
    final validations = <ValidationResult>[];
    
    // 验证M值的合理范围（通常在10-200mm之间）
    if (mValue < 10.0) {
      validations.add(ValidationResult.warning('M值较小(${mValue.toStringAsFixed(1)}mm)，请确认测量是否准确'));
    } else if (mValue > 200.0) {
      validations.add(ValidationResult.warning('M值较大(${mValue.toStringAsFixed(1)}mm)，请确认测量是否准确'));
    }
    
    // 验证K值的合理范围（通常在5-100mm之间）
    if (kValue < 5.0) {
      validations.add(ValidationResult.warning('K值较小(${kValue.toStringAsFixed(1)}mm)，请确认设备规格参数'));
    } else if (kValue > 100.0) {
      validations.add(ValidationResult.warning('K值较大(${kValue.toStringAsFixed(1)}mm)，请确认设备规格参数'));
    }
    
    // 验证N值的合理范围（通常在5-150mm之间）
    if (nValue < 5.0) {
      validations.add(ValidationResult.warning('N值较小(${nValue.toStringAsFixed(1)}mm)，下塞堵深度可能不足'));
    } else if (nValue > 150.0) {
      validations.add(ValidationResult.warning('N值较大(${nValue.toStringAsFixed(1)}mm)，请确认下塞堵深度是否合理'));
    }
    
    // 验证T值的合理范围（通常在10-80mm之间）
    if (tValue < 10.0) {
      validations.add(ValidationResult.warning('T值较小(${tValue.toStringAsFixed(1)}mm)，请确认螺纹长度测量'));
    } else if (tValue > 80.0) {
      validations.add(ValidationResult.warning('T值较大(${tValue.toStringAsFixed(1)}mm)，请确认螺纹长度测量'));
    }
    
    // 验证W值的合理范围（通常在5-60mm之间）
    if (wValue < 5.0) {
      validations.add(ValidationResult.warning('W值较小(${wValue.toStringAsFixed(1)}mm)，请确认螺纹深度测量'));
    } else if (wValue > 60.0) {
      validations.add(ValidationResult.warning('W值较大(${wValue.toStringAsFixed(1)}mm)，请确认螺纹深度测量'));
    }
    
    // 验证螺纹咬合的合理性
    if (wValue > tValue * 0.9) {
      validations.add(ValidationResult.warning('W值接近T值，螺纹咬合尺寸将很小，请确认测量精度'));
    }
    
    // 预验证计算结果的可行性
    final predictedEmptyStroke = mValue + kValue - tValue + wValue;
    if (predictedEmptyStroke <= 0) {
      validations.add(ValidationResult.error('根据当前参数，空行程将为负值(${predictedEmptyStroke.toStringAsFixed(2)}mm)，请调整参数'));
    }
    
    final predictedTotalStroke = mValue + kValue + nValue - tValue + wValue;
    if (predictedTotalStroke <= 0) {
      validations.add(ValidationResult.error('根据当前参数，总行程将为负值(${predictedTotalStroke.toStringAsFixed(2)}mm)，请调整参数'));
    }
    
    // 验证参数组合的工程合理性
    if (nValue > (mValue + kValue) * 0.8) {
      validations.add(ValidationResult.warning('N值相对较大，可能影响操作安全性'));
    }
    
    // 验证螺纹参数的匹配性
    final threadEngagement = tValue - wValue;
    if (threadEngagement > 0 && threadEngagement < 3.0) {
      validations.add(ValidationResult.warning('螺纹咬合尺寸较小(${threadEngagement.toStringAsFixed(2)}mm)，可能影响连接强度'));
    }
    
    return Validators.combineValidations(validations);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'm_value': mValue,
      'k_value': kValue,
      'n_value': nValue,
      't_value': tValue,
      'w_value': wValue,
    };
  }

  factory PlugParameters.fromJson(Map<String, dynamic> json) {
    return PlugParameters(
      mValue: (json['m_value'] as num).toDouble(),
      kValue: (json['k_value'] as num).toDouble(),
      nValue: (json['n_value'] as num).toDouble(),
      tValue: (json['t_value'] as num).toDouble(),
      wValue: (json['w_value'] as num).toDouble(),
    );
  }

  /// 创建副本
  PlugParameters copyWith({
    double? mValue,
    double? kValue,
    double? nValue,
    double? tValue,
    double? wValue,
  }) {
    return PlugParameters(
      mValue: mValue ?? this.mValue,
      kValue: kValue ?? this.kValue,
      nValue: nValue ?? this.nValue,
      tValue: tValue ?? this.tValue,
      wValue: wValue ?? this.wValue,
    );
  }

  /// 获取参数说明
  Map<String, String> getParameterDescriptions() {
    return {
      'M值': '设备基础尺寸，从设备基准点到操作点的距离',
      'K值': '设备调节范围，设备可调节的最大行程',
      'N值': '下塞堵深度，塞堵器需要插入的深度',
      'T值': '螺纹长度，螺纹连接的总长度',
      'W值': '螺纹深度，螺纹啮合的有效深度',
    };
  }

  /// 获取参数测量建议
  Map<String, String> getMeasurementTips() {
    return {
      'M值': '使用卷尺或测量工具，从设备固定基准点到操作起始点测量',
      'K值': '参考设备技术规格书，或实际测量设备最大调节范围',
      'N值': '根据管道规格和塞堵要求确定，通常为管径的1/4到1/3',
      'T值': '使用螺纹规或卡尺测量螺纹连接的完整长度',
      'W值': '测量螺纹实际啮合深度，通常小于T值',
    };
  }

  /// 检查参数组合的安全性
  bool isSafeParameterCombination() {
    // 检查基本计算结果是否为正
    final emptyStroke = mValue + kValue - tValue + wValue;
    final totalStroke = mValue + kValue + nValue - tValue + wValue;
    final threadEngagement = tValue - wValue;
    
    return emptyStroke > 0 && totalStroke > 0 && threadEngagement >= 0;
  }

  /// 获取参数优化建议
  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];
    
    final emptyStroke = mValue + kValue - tValue + wValue;
    final totalStroke = mValue + kValue + nValue - tValue + wValue;
    final threadEngagement = tValue - wValue;
    
    if (threadEngagement < 3.0 && threadEngagement >= 0) {
      suggestions.add('建议增加T值或减少W值，以获得更好的螺纹咬合效果');
    }
    
    if (emptyStroke < 20.0 && emptyStroke > 0) {
      suggestions.add('空行程较小，建议增加M值或K值以获得更大的操作余量');
    }
    
    if (nValue > totalStroke * 0.6) {
      suggestions.add('N值相对较大，建议评估是否需要如此深的下塞堵深度');
    }
    
    if (totalStroke > 400.0) {
      suggestions.add('总行程较大，建议检查是否可以优化参数以减少操作行程');
    }
    
    return suggestions;
  }

  @override
  String toString() {
    return 'PlugParameters(mValue: $mValue, kValue: $kValue, nValue: $nValue, '
           'tValue: $tValue, wValue: $wValue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlugParameters &&
        other.mValue == mValue &&
        other.kValue == kValue &&
        other.nValue == nValue &&
        other.tValue == tValue &&
        other.wValue == wValue;
  }

  @override
  int get hashCode {
    return Object.hash(mValue, kValue, nValue, tValue, wValue);
  }

  /// 操作符重载，支持通过字符串键访问参数值
  dynamic operator [](String key) {
    switch (key) {
      case 'mValue':
        return mValue;
      case 'kValue':
        return kValue;
      case 'nValue':
        return nValue;
      case 'tValue':
        return tValue;
      case 'wValue':
        return wValue;
      case 'unit':
        return 'UnitType.millimeter'; // 默认单位
      default:
        throw ArgumentError('未知的参数键: $key');
    }
  }
}

/// 下塞柄参数类
class StemParameters extends CalculationParameters {
  /// F值 (mm) - 封堵孔/囊孔基础尺寸
  final double fValue;
  
  /// G值 (mm) - 设备调节范围
  final double gValue;
  
  /// H值 (mm) - 下塞柄长度
  final double hValue;
  
  /// 垫子厚度 (mm)
  final double gasketThickness;
  
  /// 初始值 (mm)
  final double initialValue;

  StemParameters({
    required this.fValue,
    required this.gValue,
    required this.hValue,
    required this.gasketThickness,
    required this.initialValue,
  });

  @override
  ValidationResult validate() {
    final validations = <ValidationResult>[
      // 验证所有参数为正数
      Validators.validatePositiveNumber(fValue, 'F值'),
      Validators.validatePositiveNumber(gValue, 'G值'),
      Validators.validatePositiveNumber(hValue, 'H值'),
      Validators.validatePositiveNumber(gasketThickness, '垫子厚度', allowZero: true),
      Validators.validatePositiveNumber(initialValue, '初始值', allowZero: true),
      
      // 下塞柄特定的验证规则
      _validateStemSpecificRules(),
    ];

    return Validators.combineValidations(validations);
  }

  /// 下塞柄特定的验证规则
  ValidationResult _validateStemSpecificRules() {
    final validations = <ValidationResult>[];
    
    // 验证F值的合理范围（通常在10-300mm之间）
    if (fValue < 10.0) {
      validations.add(ValidationResult.warning('F值较小(${fValue.toStringAsFixed(1)}mm)，请确认封堵孔/囊孔基础尺寸测量'));
    } else if (fValue > 300.0) {
      validations.add(ValidationResult.warning('F值较大(${fValue.toStringAsFixed(1)}mm)，请确认封堵孔/囊孔基础尺寸测量'));
    }
    
    // 验证G值的合理范围（通常在5-150mm之间）
    if (gValue < 5.0) {
      validations.add(ValidationResult.warning('G值较小(${gValue.toStringAsFixed(1)}mm)，请确认设备调节范围'));
    } else if (gValue > 150.0) {
      validations.add(ValidationResult.warning('G值较大(${gValue.toStringAsFixed(1)}mm)，请确认设备调节范围'));
    }
    
    // 验证H值的合理范围（通常在10-200mm之间）
    if (hValue < 10.0) {
      validations.add(ValidationResult.warning('H值较小(${hValue.toStringAsFixed(1)}mm)，下塞柄长度可能不足'));
    } else if (hValue > 200.0) {
      validations.add(ValidationResult.warning('H值较大(${hValue.toStringAsFixed(1)}mm)，请确认下塞柄长度是否合理'));
    }
    
    // 验证垫子厚度的合理范围（通常在0-20mm之间）
    if (gasketThickness > 20.0) {
      validations.add(ValidationResult.warning('垫子厚度较大(${gasketThickness.toStringAsFixed(1)}mm)，请确认是否正确'));
    }
    
    // 验证初始值的合理范围（通常在0-30mm之间）
    if (initialValue > 30.0) {
      validations.add(ValidationResult.warning('初始值较大(${initialValue.toStringAsFixed(1)}mm)，请确认是否正确'));
    }
    
    // 预验证计算结果的可行性
    final predictedTotalStroke = fValue + gValue + hValue + gasketThickness + initialValue;
    if (predictedTotalStroke <= 0) {
      validations.add(ValidationResult.error('根据当前参数，总行程将为负值或零(${predictedTotalStroke.toStringAsFixed(2)}mm)，请调整参数'));
    }
    
    // 验证参数组合的工程合理性
    if (hValue > (fValue + gValue) * 0.8) {
      validations.add(ValidationResult.warning('H值相对较大，可能影响操作稳定性'));
    }
    
    // 验证总行程的合理性（通常在50-500mm之间）
    if (predictedTotalStroke < 20.0) {
      validations.add(ValidationResult.warning('预计总行程较小(${predictedTotalStroke.toStringAsFixed(2)}mm)，请确认参数设置'));
    } else if (predictedTotalStroke > 600.0) {
      validations.add(ValidationResult.warning('预计总行程较大(${predictedTotalStroke.toStringAsFixed(2)}mm)，请确认参数设置和操作安全性'));
    }
    
    return Validators.combineValidations(validations);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'f_value': fValue,
      'g_value': gValue,
      'h_value': hValue,
      'gasket_thickness': gasketThickness,
      'initial_value': initialValue,
    };
  }

  factory StemParameters.fromJson(Map<String, dynamic> json) {
    return StemParameters(
      fValue: (json['f_value'] as num).toDouble(),
      gValue: (json['g_value'] as num).toDouble(),
      hValue: (json['h_value'] as num).toDouble(),
      gasketThickness: (json['gasket_thickness'] as num).toDouble(),
      initialValue: (json['initial_value'] as num).toDouble(),
    );
  }

  /// 创建副本
  StemParameters copyWith({
    double? fValue,
    double? gValue,
    double? hValue,
    double? gasketThickness,
    double? initialValue,
  }) {
    return StemParameters(
      fValue: fValue ?? this.fValue,
      gValue: gValue ?? this.gValue,
      hValue: hValue ?? this.hValue,
      gasketThickness: gasketThickness ?? this.gasketThickness,
      initialValue: initialValue ?? this.initialValue,
    );
  }

  /// 获取参数说明
  Map<String, String> getParameterDescriptions() {
    return {
      'F值': '封堵孔/囊孔基础尺寸，从基准点到操作起始位置的距离',
      'G值': '设备调节范围，设备可调节的最大行程',
      'H值': '下塞柄长度，塞柄的有效长度',
      '垫子厚度': '密封垫片的厚度',
      '初始值': '设备初始位置的偏移量',
    };
  }

  /// 获取参数测量建议
  Map<String, String> getMeasurementTips() {
    return {
      'F值': '使用卷尺或测量工具，从设备固定基准点到封堵孔/囊孔起始位置测量',
      'G值': '参考设备技术规格书，或实际测量设备最大调节范围',
      'H值': '使用卷尺测量下塞柄的完整有效长度',
      '垫子厚度': '使用卡尺或厚度规测量密封垫片厚度',
      '初始值': '测量设备初始位置的偏移量，通常为小数值',
    };
  }

  /// 检查参数组合的安全性
  bool isSafeParameterCombination() {
    // 检查基本计算结果是否为正
    final totalStroke = fValue + gValue + hValue + gasketThickness + initialValue;
    
    return totalStroke > 0 && 
           fValue > 0 && 
           gValue > 0 && 
           hValue > 0 && 
           gasketThickness >= 0 && 
           initialValue >= 0;
  }

  /// 获取参数优化建议
  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];
    
    final totalStroke = fValue + gValue + hValue + gasketThickness + initialValue;
    
    if (totalStroke < 50.0 && totalStroke > 0) {
      suggestions.add('总行程较小，建议增加F值、G值或H值以获得更大的操作余量');
    }
    
    if (hValue > totalStroke * 0.6) {
      suggestions.add('H值相对较大，建议评估是否需要如此长的下塞柄');
    }
    
    if (totalStroke > 500.0) {
      suggestions.add('总行程较大，建议检查是否可以优化参数以减少操作行程');
    }
    
    if (gasketThickness > 15.0) {
      suggestions.add('垫子厚度较大，建议确认是否使用了正确的垫片规格');
    }
    
    if (initialValue > 20.0) {
      suggestions.add('初始值较大，建议检查设备初始位置设置');
    }
    
    return suggestions;
  }

  /// 获取安全操作建议
  List<String> getSafetyRecommendations() {
    final recommendations = <String>[];
    final totalStroke = fValue + gValue + hValue + gasketThickness + initialValue;
    
    if (totalStroke > 300.0) {
      recommendations.add('总行程较大，操作时请确保设备稳定性和安全距离');
    }
    
    if (hValue > 150.0) {
      recommendations.add('下塞柄较长，操作时请注意防止弯曲变形');
    }
    
    if (fValue < 20.0) {
      recommendations.add('F值较小，请确保有足够的操作空间');
    }
    
    recommendations.add('操作前请确认所有参数测量准确');
    recommendations.add('操作过程中请保持设备稳定');
    recommendations.add('完成操作后请检查密封效果');
    
    return recommendations;
  }

  @override
  String toString() {
    return 'StemParameters(fValue: $fValue, gValue: $gValue, hValue: $hValue, '
           'gasketThickness: $gasketThickness, initialValue: $initialValue)';
  }
}