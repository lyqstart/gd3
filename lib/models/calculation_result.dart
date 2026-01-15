import 'enums.dart';
import 'calculation_parameters.dart';
import 'validation_result.dart';
import '../utils/validators.dart';

/// 计算结果基类
abstract class CalculationResult {
  /// 计算类型
  final CalculationType calculationType;
  
  /// 计算时间
  final DateTime calculationTime;
  
  /// 计算参数对象
  final CalculationParameters parameters;
  
  /// 唯一标识符
  final String id;

  CalculationResult({
    required this.calculationType,
    required this.calculationTime,
    required this.parameters,
    String? id,
  }) : id = id ?? _generateId();

  /// 生成唯一ID
  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// 转换为JSON格式
  Map<String, dynamic> toJson();

  /// 从JSON格式创建对象
  static CalculationResult fromJson(Map<String, dynamic> json) {
    final type = CalculationType.values.firstWhere(
      (e) => e.value == json['calculation_type'],
    );
    
    switch (type) {
      case CalculationType.hole:
        return HoleCalculationResult.fromJson(json);
      case CalculationType.manualHole:
        return ManualHoleResult.fromJson(json);
      case CalculationType.sealing:
        return SealingResult.fromJson(json);
      case CalculationType.plug:
        return PlugResult.fromJson(json);
      case CalculationType.stem:
        return StemResult.fromJson(json);
    }
  }

  /// 获取核心结果值（用于高亮显示）
  Map<String, double> getCoreResults();

  /// 获取计算公式说明
  Map<String, String> getFormulas();

  /// 获取结果单位
  String getUnit() => 'mm';

  @override
  String toString() {
    return 'CalculationResult(id: $id, type: $calculationType, time: $calculationTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalculationResult &&
        other.id == id &&
        other.calculationType == calculationType;
  }

  @override
  int get hashCode => Object.hash(id, calculationType);
}

/// 开孔计算结果
class HoleCalculationResult extends CalculationResult {
  /// 空行程 (mm)
  final double emptyStroke;
  
  /// 筒刀切削距离 (mm)
  final double cuttingDistance;
  
  /// 掉板弦高 (mm)
  final double chordHeight;
  
  /// 切削尺寸 (mm)
  final double cuttingSize;
  
  /// 开孔总行程 (mm)
  final double totalStroke;
  
  /// 掉板总行程 (mm)
  final double plateStroke;

  HoleCalculationResult({
    required this.emptyStroke,
    required this.cuttingDistance,
    required this.chordHeight,
    required this.cuttingSize,
    required this.totalStroke,
    required this.plateStroke,
    required DateTime calculationTime,
    required HoleParameters parameters,
    String? id,
  }) : super(
    calculationType: CalculationType.hole,
    calculationTime: calculationTime,
    parameters: parameters,
    id: id,
  );

  @override
  Map<String, double> getCoreResults() {
    return {
      '空行程': emptyStroke,
      '开孔总行程': totalStroke,
      '掉板总行程': plateStroke,
    };
  }

  @override
  Map<String, String> getFormulas() {
    return {
      '空行程': 'S空 = A + B + 初始值 + 垫片厚度',
      '筒刀切削距离': 'C1 = √(管外径² - 管内径²) - 筒刀外径',
      '掉板弦高': 'C2 = √(管外径² - 管内径²) - 筒刀内径',
      '切削尺寸': 'C = R + C1',
      '开孔总行程': 'S总 = S空 + C',
      '掉板总行程': 'S掉板 = S总 + R + C2',
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'calculation_type': calculationType.value,
      'calculation_time': calculationTime.millisecondsSinceEpoch,
      'parameters': parameters.toJson(),
      'results': {
        'empty_stroke': emptyStroke,
        'cutting_distance': cuttingDistance,
        'chord_height': chordHeight,
        'cutting_size': cuttingSize,
        'total_stroke': totalStroke,
        'plate_stroke': plateStroke,
      },
    };
  }

  factory HoleCalculationResult.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>;
    return HoleCalculationResult(
      emptyStroke: (results['empty_stroke'] as num).toDouble(),
      cuttingDistance: (results['cutting_distance'] as num).toDouble(),
      chordHeight: (results['chord_height'] as num).toDouble(),
      cuttingSize: (results['cutting_size'] as num).toDouble(),
      totalStroke: (results['total_stroke'] as num).toDouble(),
      plateStroke: (results['plate_stroke'] as num).toDouble(),
      calculationTime: DateTime.fromMillisecondsSinceEpoch(json['calculation_time']),
      parameters: HoleParameters.fromJson(json['parameters'] as Map<String, dynamic>),
      id: json['id'] as String,
    );
  }

  /// 获取开孔参数（类型安全的访问器）
  HoleParameters get holeParameters => parameters as HoleParameters;

  /// 验证计算结果的合理性
  ValidationResult validateResults() {
    final validations = <ValidationResult>[];
    
    // 验证空行程为正数
    if (emptyStroke <= 0) {
      validations.add(ValidationResult.error('空行程计算结果异常：${emptyStroke.toStringAsFixed(2)}mm'));
    }
    
    // 验证切削距离为正数
    if (cuttingDistance <= 0) {
      validations.add(ValidationResult.warning('筒刀切削距离为负值：${cuttingDistance.toStringAsFixed(2)}mm，请检查筒刀外径参数'));
    }
    
    // 验证掉板弦高为正数
    if (chordHeight <= 0) {
      validations.add(ValidationResult.warning('掉板弦高为负值：${chordHeight.toStringAsFixed(2)}mm，请检查筒刀内径参数'));
    }
    
    // 验证总行程大于空行程
    if (totalStroke <= emptyStroke) {
      validations.add(ValidationResult.error('开孔总行程(${totalStroke.toStringAsFixed(2)}mm)应大于空行程(${emptyStroke.toStringAsFixed(2)}mm)'));
    }
    
    // 验证掉板总行程大于开孔总行程
    if (plateStroke <= totalStroke) {
      validations.add(ValidationResult.error('掉板总行程(${plateStroke.toStringAsFixed(2)}mm)应大于开孔总行程(${totalStroke.toStringAsFixed(2)}mm)'));
    }
    
    // 验证结果的工程合理性（总行程通常在50-500mm之间）
    if (totalStroke < 10.0) {
      validations.add(ValidationResult.warning('开孔总行程较小(${totalStroke.toStringAsFixed(2)}mm)，请确认参数设置'));
    } else if (totalStroke > 1000.0) {
      validations.add(ValidationResult.warning('开孔总行程较大(${totalStroke.toStringAsFixed(2)}mm)，请确认参数设置'));
    }
    
    return Validators.combineValidations(validations);
  }

  /// 获取安全提示信息
  List<String> getSafetyWarnings() {
    final warnings = <String>[];
    
    // 基于计算结果提供安全提示
    if (totalStroke > 300.0) {
      warnings.add('总行程较大，操作时请注意安全距离');
    }
    
    if (cuttingDistance < 5.0) {
      warnings.add('切削距离较小，请确认筒刀规格是否合适');
    }
    
    if (plateStroke - totalStroke > 100.0) {
      warnings.add('掉板行程差值较大，操作时请特别注意');
    }
    
    return warnings;
  }

  /// 获取详细的计算步骤说明
  Map<String, String> getCalculationSteps() {
    final params = holeParameters;
    return {
      '步骤1': '计算空行程：S空 = ${params.aValue} + ${params.bValue} + ${params.initialValue} + ${params.gasketThickness} = ${emptyStroke.toStringAsFixed(2)}mm',
      '步骤2': '计算管道壁厚区域：√(${params.outerDiameter}² - ${params.innerDiameter}²) = ${(cuttingDistance + params.cutterOuterDiameter).toStringAsFixed(2)}mm',
      '步骤3': '计算筒刀切削距离：C1 = ${(cuttingDistance + params.cutterOuterDiameter).toStringAsFixed(2)} - ${params.cutterOuterDiameter} = ${cuttingDistance.toStringAsFixed(2)}mm',
      '步骤4': '计算掉板弦高：C2 = ${(chordHeight + params.cutterInnerDiameter).toStringAsFixed(2)} - ${params.cutterInnerDiameter} = ${chordHeight.toStringAsFixed(2)}mm',
      '步骤5': '计算切削尺寸：C = ${params.rValue} + ${cuttingDistance.toStringAsFixed(2)} = ${cuttingSize.toStringAsFixed(2)}mm',
      '步骤6': '计算开孔总行程：S总 = ${emptyStroke.toStringAsFixed(2)} + ${cuttingSize.toStringAsFixed(2)} = ${totalStroke.toStringAsFixed(2)}mm',
      '步骤7': '计算掉板总行程：S掉板 = ${totalStroke.toStringAsFixed(2)} + ${params.rValue} + ${chordHeight.toStringAsFixed(2)} = ${plateStroke.toStringAsFixed(2)}mm',
    };
  }

  @override
  String toString() {
    return 'HoleCalculationResult(id: $id, emptyStroke: $emptyStroke, totalStroke: $totalStroke, plateStroke: $plateStroke)';
  }
}

/// 手动开孔计算结果
class ManualHoleResult extends CalculationResult {
  /// 螺纹咬合尺寸 (mm)
  final double threadEngagement;
  
  /// 空行程 (mm)
  final double emptyStroke;
  
  /// 总行程 (mm)
  final double totalStroke;

  ManualHoleResult({
    required this.threadEngagement,
    required this.emptyStroke,
    required this.totalStroke,
    required DateTime calculationTime,
    required ManualHoleParameters parameters,
    String? id,
  }) : super(
    calculationType: CalculationType.manualHole,
    calculationTime: calculationTime,
    parameters: parameters,
    id: id,
  );

  @override
  Map<String, double> getCoreResults() {
    return {
      '螺纹咬合尺寸': threadEngagement,
      '空行程': emptyStroke,
      '总行程': totalStroke,
    };
  }

  @override
  Map<String, String> getFormulas() {
    return {
      '螺纹咬合尺寸': '螺纹咬合尺寸 = T - W',
      '空行程': '空行程 = L + J + T + W',
      '总行程': '总行程 = L + J + T + W + P',
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'calculation_type': calculationType.value,
      'calculation_time': calculationTime.millisecondsSinceEpoch,
      'parameters': parameters.toJson(),
      'results': {
        'thread_engagement': threadEngagement,
        'empty_stroke': emptyStroke,
        'total_stroke': totalStroke,
      },
    };
  }

  factory ManualHoleResult.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>;
    return ManualHoleResult(
      threadEngagement: (results['thread_engagement'] as num).toDouble(),
      emptyStroke: (results['empty_stroke'] as num).toDouble(),
      totalStroke: (results['total_stroke'] as num).toDouble(),
      calculationTime: DateTime.fromMillisecondsSinceEpoch(json['calculation_time']),
      parameters: ManualHoleParameters.fromJson(json['parameters'] as Map<String, dynamic>),
      id: json['id'] as String,
    );
  }

  /// 获取手动开孔参数（类型安全的访问器）
  ManualHoleParameters get manualHoleParameters => parameters as ManualHoleParameters;

  @override
  String toString() {
    return 'ManualHoleResult(id: $id, threadEngagement: $threadEngagement, emptyStroke: $emptyStroke, totalStroke: $totalStroke)';
  }
}

/// 封堵计算结果
class SealingResult extends CalculationResult {
  /// 导向轮接触管线行程 (mm)
  final double guideWheelStroke;
  
  /// 封堵总行程 (mm)
  final double totalStroke;

  SealingResult({
    required this.guideWheelStroke,
    required this.totalStroke,
    required DateTime calculationTime,
    required SealingParameters parameters,
    String? id,
  }) : super(
    calculationType: CalculationType.sealing,
    calculationTime: calculationTime,
    parameters: parameters,
    id: id,
  );

  @override
  Map<String, double> getCoreResults() {
    return {
      '导向轮接触管线行程': guideWheelStroke,
      '封堵总行程': totalStroke,
    };
  }

  @override
  Map<String, String> getFormulas() {
    return {
      '导向轮接触管线行程': '导向轮接触管线行程 = R + B + E + 垫子厚度 + 初始值',
      '封堵总行程': '封堵总行程 = D + B + E + 垫子厚度 + 初始值',
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'calculation_type': calculationType.value,
      'calculation_time': calculationTime.millisecondsSinceEpoch,
      'parameters': parameters.toJson(),
      'results': {
        'guide_wheel_stroke': guideWheelStroke,
        'total_stroke': totalStroke,
      },
    };
  }

  factory SealingResult.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>;
    return SealingResult(
      guideWheelStroke: (results['guide_wheel_stroke'] as num).toDouble(),
      totalStroke: (results['total_stroke'] as num).toDouble(),
      calculationTime: DateTime.fromMillisecondsSinceEpoch(json['calculation_time']),
      parameters: SealingParameters.fromJson(json['parameters'] as Map<String, dynamic>),
      id: json['id'] as String,
    );
  }

  /// 获取封堵参数（类型安全的访问器）
  SealingParameters get sealingParameters => parameters as SealingParameters;

  /// 验证计算结果的合理性
  ValidationResult validateResults() {
    final validations = <ValidationResult>[];
    
    // 验证导向轮接触管线行程为正数
    if (guideWheelStroke <= 0) {
      validations.add(ValidationResult.error('导向轮接触管线行程计算结果异常：${guideWheelStroke.toStringAsFixed(2)}mm'));
    }
    
    // 验证封堵总行程为正数
    if (totalStroke <= 0) {
      validations.add(ValidationResult.error('封堵总行程计算结果异常：${totalStroke.toStringAsFixed(2)}mm'));
    }
    
    // 验证封堵总行程应该大于导向轮行程
    if (totalStroke <= guideWheelStroke) {
      validations.add(ValidationResult.error('封堵总行程(${totalStroke.toStringAsFixed(2)}mm)应大于导向轮接触管线行程(${guideWheelStroke.toStringAsFixed(2)}mm)'));
    }
    
    // 验证结果的工程合理性（总行程通常在20-300mm之间）
    if (totalStroke < 10.0) {
      validations.add(ValidationResult.warning('封堵总行程较小(${totalStroke.toStringAsFixed(2)}mm)，请确认参数设置'));
    } else if (totalStroke > 500.0) {
      validations.add(ValidationResult.warning('封堵总行程较大(${totalStroke.toStringAsFixed(2)}mm)，请确认参数设置'));
    }
    
    // 验证导向轮行程的合理性
    if (guideWheelStroke < 5.0) {
      validations.add(ValidationResult.warning('导向轮接触管线行程较小(${guideWheelStroke.toStringAsFixed(2)}mm)，请确认参数设置'));
    } else if (guideWheelStroke > 400.0) {
      validations.add(ValidationResult.warning('导向轮接触管线行程较大(${guideWheelStroke.toStringAsFixed(2)}mm)，请确认参数设置'));
    }
    
    return Validators.combineValidations(validations);
  }

  /// 获取安全提示信息
  List<String> getSafetyWarnings() {
    final warnings = <String>[];
    
    // 基于计算结果提供安全提示
    if (totalStroke > 200.0) {
      warnings.add('封堵总行程较大，操作时请注意安全距离和设备稳定性');
    }
    
    if (totalStroke - guideWheelStroke < 10.0) {
      warnings.add('封堵器与导向轮行程差值较小，请确认封堵深度是否足够');
    }
    
    if (totalStroke - guideWheelStroke > 100.0) {
      warnings.add('封堵器与导向轮行程差值较大，操作时请特别注意');
    }
    
    return warnings;
  }

  /// 获取详细的计算步骤说明
  Map<String, String> getCalculationSteps() {
    final params = sealingParameters;
    return {
      '步骤1': '计算导向轮接触管线行程：导向轮行程 = ${params.rValue} + ${params.bValue} + ${params.eValue} + ${params.gasketThickness} + ${params.initialValue} = ${guideWheelStroke.toStringAsFixed(2)}mm',
      '步骤2': '计算封堵总行程：封堵总行程 = ${params.dValue} + ${params.bValue} + ${params.eValue} + ${params.gasketThickness} + ${params.initialValue} = ${totalStroke.toStringAsFixed(2)}mm',
      '步骤3': '验证封堵深度：封堵深度 = ${totalStroke.toStringAsFixed(2)} - ${guideWheelStroke.toStringAsFixed(2)} = ${(totalStroke - guideWheelStroke).toStringAsFixed(2)}mm',
    };
  }

  /// 检查是否适用于解堵操作
  /// 
  /// 根据需求3.3，封堵和解堵使用相同的计算逻辑
  bool isApplicableForUnsealing() {
    // 封堵计算结果完全适用于解堵操作
    // 解堵时使用相同的行程参数，只是操作方向相反
    return true;
  }

  /// 获取解堵操作说明
  String getUnsealingInstructions() {
    return '解堵操作使用相同的行程参数：'
           '导向轮接触管线行程 ${guideWheelStroke.toStringAsFixed(2)}mm，'
           '解堵总行程 ${totalStroke.toStringAsFixed(2)}mm。'
           '操作方向与封堵相反，请确保设备稳定性。';
  }

  @override
  String toString() {
    return 'SealingResult(id: $id, guideWheelStroke: $guideWheelStroke, totalStroke: $totalStroke)';
  }
}

/// 下塞堵计算结果
class PlugResult extends CalculationResult {
  /// 螺纹咬合尺寸 (mm)
  final double threadEngagement;
  
  /// 空行程 (mm)
  final double emptyStroke;
  
  /// 总行程 (mm)
  final double totalStroke;

  PlugResult({
    required this.threadEngagement,
    required this.emptyStroke,
    required this.totalStroke,
    required DateTime calculationTime,
    required PlugParameters parameters,
    String? id,
  }) : super(
    calculationType: CalculationType.plug,
    calculationTime: calculationTime,
    parameters: parameters,
    id: id,
  );

  @override
  Map<String, double> getCoreResults() {
    return {
      '螺纹咬合尺寸': threadEngagement,
      '空行程': emptyStroke,
      '总行程': totalStroke,
    };
  }

  @override
  Map<String, String> getFormulas() {
    return {
      '螺纹咬合尺寸': '螺纹咬合尺寸 = T - W',
      '空行程': '空行程 = M + K - T + W',
      '总行程': '总行程 = M + K + N - T + W',
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'calculation_type': calculationType.value,
      'calculation_time': calculationTime.millisecondsSinceEpoch,
      'parameters': parameters.toJson(),
      'results': {
        'thread_engagement': threadEngagement,
        'empty_stroke': emptyStroke,
        'total_stroke': totalStroke,
      },
    };
  }

  factory PlugResult.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>;
    return PlugResult(
      threadEngagement: (results['thread_engagement'] as num).toDouble(),
      emptyStroke: (results['empty_stroke'] as num).toDouble(),
      totalStroke: (results['total_stroke'] as num).toDouble(),
      calculationTime: DateTime.fromMillisecondsSinceEpoch(json['calculation_time']),
      parameters: PlugParameters.fromJson(json['parameters'] as Map<String, dynamic>),
      id: json['id'] as String,
    );
  }

  /// 获取下塞堵参数（类型安全的访问器）
  PlugParameters get plugParameters => parameters as PlugParameters;

  /// 验证计算结果的合理性
  ValidationResult validateResults() {
    final validations = <ValidationResult>[];
    
    // 验证螺纹咬合尺寸
    if (threadEngagement < 0) {
      validations.add(ValidationResult.warning('螺纹咬合尺寸为负值：${threadEngagement.toStringAsFixed(2)}mm，请检查T值和W值'));
    } else if (threadEngagement < 3.0) {
      validations.add(ValidationResult.warning('螺纹咬合尺寸较小(${threadEngagement.toStringAsFixed(2)}mm)，可能影响连接强度'));
    }
    
    // 验证空行程为正数
    if (emptyStroke <= 0) {
      validations.add(ValidationResult.error('空行程计算结果异常：${emptyStroke.toStringAsFixed(2)}mm'));
    }
    
    // 验证总行程为正数
    if (totalStroke <= 0) {
      validations.add(ValidationResult.error('总行程计算结果异常：${totalStroke.toStringAsFixed(2)}mm'));
    }
    
    // 验证总行程应该大于空行程
    if (totalStroke <= emptyStroke) {
      validations.add(ValidationResult.error('总行程(${totalStroke.toStringAsFixed(2)}mm)应大于空行程(${emptyStroke.toStringAsFixed(2)}mm)'));
    }
    
    // 验证结果的工程合理性（总行程通常在20-400mm之间）
    if (totalStroke < 10.0) {
      validations.add(ValidationResult.warning('总行程较小(${totalStroke.toStringAsFixed(2)}mm)，请确认参数设置'));
    } else if (totalStroke > 600.0) {
      validations.add(ValidationResult.warning('总行程较大(${totalStroke.toStringAsFixed(2)}mm)，请确认参数设置'));
    }
    
    return Validators.combineValidations(validations);
  }

  /// 获取参数检查建议（需求4.4）
  List<String> getParameterCheckSuggestions() {
    final suggestions = <String>[];
    
    // 当计算结果出现负值时，提供参数检查建议
    if (threadEngagement < 0) {
      suggestions.add('螺纹咬合尺寸为负值，建议：');
      suggestions.add('• 检查T值是否正确测量（螺纹长度）');
      suggestions.add('• 检查W值是否正确测量（螺纹深度）');
      suggestions.add('• 确认T值应大于W值');
    }
    
    if (emptyStroke < 0) {
      suggestions.add('空行程为负值，建议：');
      suggestions.add('• 检查M值和K值是否正确');
      suggestions.add('• 确认T值和W值的测量精度');
      suggestions.add('• 验证公式：M + K - T + W > 0');
    }
    
    if (totalStroke < 0) {
      suggestions.add('总行程为负值，建议：');
      suggestions.add('• 检查所有输入参数的正确性');
      suggestions.add('• 确认N值（下塞堵深度）是否合理');
      suggestions.add('• 验证公式：M + K + N - T + W > 0');
    }
    
    // 基于参数值提供额外建议
    final params = plugParameters;
    
    if (params.mValue < 10.0) {
      suggestions.add('M值较小，请确认测量是否准确');
    }
    
    if (params.kValue < 5.0) {
      suggestions.add('K值较小，请确认设备规格参数');
    }
    
    if (params.nValue > 100.0) {
      suggestions.add('N值较大，请确认下塞堵深度是否合理');
    }
    
    if (params.tValue > 50.0) {
      suggestions.add('T值较大，请确认螺纹长度测量');
    }
    
    if (params.wValue > params.tValue * 0.8) {
      suggestions.add('W值接近T值，请确认螺纹深度测量');
    }
    
    // 如果没有问题，提供一般性建议
    if (suggestions.isEmpty && threadEngagement >= 0 && emptyStroke > 0 && totalStroke > 0) {
      suggestions.add('计算结果正常，建议：');
      suggestions.add('• 作业前再次确认所有参数测量值');
      suggestions.add('• 检查设备状态和工具规格');
      suggestions.add('• 确保作业环境安全');
    }
    
    return suggestions;
  }

  /// 获取安全提示信息
  List<String> getSafetyWarnings() {
    final warnings = <String>[];
    
    // 基于计算结果提供安全提示
    if (totalStroke > 300.0) {
      warnings.add('总行程较大，操作时请注意安全距离和设备稳定性');
    }
    
    if (threadEngagement < 3.0 && threadEngagement >= 0) {
      warnings.add('螺纹咬合尺寸较小，请确保连接牢固性');
    }
    
    if (totalStroke - emptyStroke > 150.0) {
      warnings.add('下塞堵行程较大，操作时请特别注意');
    }
    
    if (threadEngagement < 0) {
      warnings.add('螺纹咬合尺寸为负值，存在安全风险，请重新检查参数');
    }
    
    return warnings;
  }

  /// 获取详细的计算步骤说明
  Map<String, String> getCalculationSteps() {
    final params = plugParameters;
    return {
      '步骤1': '计算螺纹咬合尺寸：螺纹咬合 = ${params.tValue} - ${params.wValue} = ${threadEngagement.toStringAsFixed(2)}mm',
      '步骤2': '计算空行程：空行程 = ${params.mValue} + ${params.kValue} - ${params.tValue} + ${params.wValue} = ${emptyStroke.toStringAsFixed(2)}mm',
      '步骤3': '计算总行程：总行程 = ${params.mValue} + ${params.kValue} + ${params.nValue} - ${params.tValue} + ${params.wValue} = ${totalStroke.toStringAsFixed(2)}mm',
      '步骤4': '验证结果：下塞堵深度 = ${totalStroke.toStringAsFixed(2)} - ${emptyStroke.toStringAsFixed(2)} = ${(totalStroke - emptyStroke).toStringAsFixed(2)}mm',
    };
  }

  /// 检查是否需要参数调整
  bool needsParameterAdjustment() {
    return threadEngagement < 0 || emptyStroke <= 0 || totalStroke <= 0;
  }

  /// 获取参数调整建议
  Map<String, String> getParameterAdjustmentSuggestions() {
    final suggestions = <String, String>{};
    
    if (threadEngagement < 0) {
      suggestions['螺纹咬合'] = '增加T值或减少W值，确保T > W';
    }
    
    if (emptyStroke <= 0) {
      suggestions['空行程'] = '增加M值或K值，或减少T值，确保M + K - T + W > 0';
    }
    
    if (totalStroke <= 0) {
      suggestions['总行程'] = '增加N值或调整其他参数，确保M + K + N - T + W > 0';
    }
    
    return suggestions;
  }

  @override
  String toString() {
    return 'PlugResult(id: $id, threadEngagement: $threadEngagement, emptyStroke: $emptyStroke, totalStroke: $totalStroke)';
  }
}

/// 下塞柄计算结果
class StemResult extends CalculationResult {
  /// 总行程 (mm)
  final double totalStroke;

  StemResult({
    required this.totalStroke,
    required DateTime calculationTime,
    required StemParameters parameters,
    String? id,
  }) : super(
    calculationType: CalculationType.stem,
    calculationTime: calculationTime,
    parameters: parameters,
    id: id,
  );

  @override
  Map<String, double> getCoreResults() {
    return {
      '总行程': totalStroke,
    };
  }

  @override
  Map<String, String> getFormulas() {
    return {
      '总行程': '总行程 = F + G + H + 垫子厚度 + 初始值',
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'calculation_type': calculationType.value,
      'calculation_time': calculationTime.millisecondsSinceEpoch,
      'parameters': parameters.toJson(),
      'results': {
        'total_stroke': totalStroke,
      },
    };
  }

  factory StemResult.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>;
    return StemResult(
      totalStroke: (results['total_stroke'] as num).toDouble(),
      calculationTime: DateTime.fromMillisecondsSinceEpoch(json['calculation_time']),
      parameters: StemParameters.fromJson(json['parameters'] as Map<String, dynamic>),
      id: json['id'] as String,
    );
  }

  /// 获取下塞柄参数（类型安全的访问器）
  StemParameters get stemParameters => parameters as StemParameters;

  /// 验证计算结果的合理性
  ValidationResult validateResults() {
    final validations = <ValidationResult>[];
    
    // 验证总行程为正数
    if (totalStroke <= 0) {
      validations.add(ValidationResult.error('总行程计算结果异常：${totalStroke.toStringAsFixed(2)}mm'));
    }
    
    // 验证结果的工程合理性（总行程通常在20-600mm之间）
    if (totalStroke < 20.0) {
      validations.add(ValidationResult.warning('总行程较小(${totalStroke.toStringAsFixed(2)}mm)，请确认参数设置'));
    } else if (totalStroke > 600.0) {
      validations.add(ValidationResult.warning('总行程较大(${totalStroke.toStringAsFixed(2)}mm)，请确认参数设置和操作安全性'));
    }
    
    // 验证精度要求（需求5.3：保持计算精度至小数点后2位）
    final roundedStroke = double.parse(totalStroke.toStringAsFixed(2));
    if ((totalStroke - roundedStroke).abs() > 0.001) {
      validations.add(ValidationResult.warning('计算结果精度超出要求，已调整至小数点后2位'));
    }
    
    return Validators.combineValidations(validations);
  }

  /// 获取安全提示信息
  List<String> getSafetyWarnings() {
    final warnings = <String>[];
    
    // 基于计算结果提供安全提示
    if (totalStroke > 400.0) {
      warnings.add('总行程较大，操作时请注意安全距离和设备稳定性');
    }
    
    if (totalStroke < 30.0) {
      warnings.add('总行程较小，请确认下塞柄长度是否足够');
    }
    
    final params = stemParameters;
    if (params.hValue > totalStroke * 0.7) {
      warnings.add('下塞柄长度占总行程比例较大，操作时请特别注意');
    }
    
    return warnings;
  }

  /// 获取详细的计算步骤说明
  Map<String, String> getCalculationSteps() {
    final params = stemParameters;
    return {
      '步骤1': '收集参数：F值=${params.fValue.toStringAsFixed(2)}mm, G值=${params.gValue.toStringAsFixed(2)}mm, H值=${params.hValue.toStringAsFixed(2)}mm',
      '步骤2': '收集辅助参数：垫子厚度=${params.gasketThickness.toStringAsFixed(2)}mm, 初始值=${params.initialValue.toStringAsFixed(2)}mm',
      '步骤3': '计算总行程：总行程 = ${params.fValue.toStringAsFixed(2)} + ${params.gValue.toStringAsFixed(2)} + ${params.hValue.toStringAsFixed(2)} + ${params.gasketThickness.toStringAsFixed(2)} + ${params.initialValue.toStringAsFixed(2)} = ${totalStroke.toStringAsFixed(2)}mm',
      '步骤4': '验证结果：总行程为${totalStroke.toStringAsFixed(2)}mm，精度保持至小数点后2位',
    };
  }

  /// 获取操作指导信息
  Map<String, String> getOperationGuidance() {
    return {
      '准备阶段': '确认所有参数测量准确，检查设备状态和工具规格',
      '操作阶段': '按照计算的总行程${totalStroke.toStringAsFixed(2)}mm进行下塞柄安装',
      '监控要点': '操作过程中保持设备稳定，注意行程控制精度',
      '完成检查': '安装完成后检查密封效果和位置准确性',
    };
  }

  /// 获取参数影响分析
  Map<String, String> getParameterImpactAnalysis() {
    final params = stemParameters;
    final analysis = <String, String>{};
    
    // 分析各参数对总行程的贡献
    final fContribution = (params.fValue / totalStroke * 100);
    final gContribution = (params.gValue / totalStroke * 100);
    final hContribution = (params.hValue / totalStroke * 100);
    final gasketContribution = (params.gasketThickness / totalStroke * 100);
    final initialContribution = (params.initialValue / totalStroke * 100);
    
    analysis['F值影响'] = 'F值占总行程的${fContribution.toStringAsFixed(1)}%，是${fContribution > 40 ? '主要' : fContribution > 20 ? '重要' : '次要'}影响因素';
    analysis['G值影响'] = 'G值占总行程的${gContribution.toStringAsFixed(1)}%，是${gContribution > 40 ? '主要' : gContribution > 20 ? '重要' : '次要'}影响因素';
    analysis['H值影响'] = 'H值占总行程的${hContribution.toStringAsFixed(1)}%，是${hContribution > 40 ? '主要' : hContribution > 20 ? '重要' : '次要'}影响因素';
    
    if (gasketContribution > 5) {
      analysis['垫子厚度影响'] = '垫子厚度占总行程的${gasketContribution.toStringAsFixed(1)}%，影响相对较大';
    }
    
    if (initialContribution > 5) {
      analysis['初始值影响'] = '初始值占总行程的${initialContribution.toStringAsFixed(1)}%，影响相对较大';
    }
    
    return analysis;
  }

  /// 检查是否需要参数调整
  bool needsParameterAdjustment() {
    return totalStroke <= 0 || totalStroke < 20.0 || totalStroke > 600.0;
  }

  /// 获取参数调整建议
  Map<String, String> getParameterAdjustmentSuggestions() {
    final suggestions = <String, String>{};
    
    if (totalStroke <= 0) {
      suggestions['总行程异常'] = '总行程为负值或零，请检查所有输入参数的正确性';
    } else if (totalStroke < 20.0) {
      suggestions['总行程过小'] = '建议增加F值、G值或H值以获得合适的操作行程';
    } else if (totalStroke > 600.0) {
      suggestions['总行程过大'] = '建议检查参数设置，确认是否需要如此大的操作行程';
    }
    
    final params = stemParameters;
    
    if (params.hValue > totalStroke * 0.8) {
      suggestions['H值比例'] = '下塞柄长度占比过大，建议调整H值或其他参数的比例';
    }
    
    if (params.gasketThickness > 20.0) {
      suggestions['垫子厚度'] = '垫子厚度较大，建议确认垫片规格是否正确';
    }
    
    return suggestions;
  }

  /// 获取质量控制要点
  List<String> getQualityControlPoints() {
    return [
      '确保所有参数测量精度达到±0.1mm要求',
      '验证计算结果精度保持在小数点后2位',
      '检查总行程是否在合理的工程范围内(20-600mm)',
      '确认下塞柄长度与总行程的比例合理',
      '验证垫子厚度和初始值设置的准确性',
      '操作前进行试运行，确认行程计算的准确性',
    ];
  }

  @override
  String toString() {
    return 'StemResult(id: $id, totalStroke: ${totalStroke.toStringAsFixed(2)}mm)';
  }
}