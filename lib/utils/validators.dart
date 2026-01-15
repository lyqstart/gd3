import '../models/validation_result.dart';
import '../models/calculation_parameters.dart';

/// 输入验证工具类
class Validators {
  /// 验证数值是否为正数
  /// 
  /// [value] 待验证的数值
  /// [fieldName] 字段名称
  /// [allowZero] 是否允许零值，默认为false
  /// 
  /// 返回验证结果
  static ValidationResult validatePositiveNumber(
    double? value, 
    String fieldName, 
    {bool allowZero = false}
  ) {
    if (value == null) {
      return ValidationResult.error('$fieldName不能为空', fieldName: fieldName);
    }
    
    if (allowZero && value < 0) {
      return ValidationResult.error('$fieldName不能为负数', fieldName: fieldName);
    } else if (!allowZero && value <= 0) {
      return ValidationResult.error('$fieldName必须大于0', fieldName: fieldName);
    }
    
    return ValidationResult.success();
  }

  /// 验证数值范围
  /// 
  /// [value] 待验证的数值
  /// [fieldName] 字段名称
  /// [min] 最小值（可选）
  /// [max] 最大值（可选）
  /// 
  /// 返回验证结果
  static ValidationResult validateNumberRange(
    double? value, 
    String fieldName, 
    {double? min, double? max}
  ) {
    if (value == null) {
      return ValidationResult.error('$fieldName不能为空', fieldName: fieldName);
    }
    
    if (min != null && value < min) {
      return ValidationResult.error('$fieldName不能小于$min', fieldName: fieldName);
    }
    
    if (max != null && value > max) {
      return ValidationResult.error('$fieldName不能大于$max', fieldName: fieldName);
    }
    
    return ValidationResult.success();
  }

  /// 验证字符串是否为空
  /// 
  /// [value] 待验证的字符串
  /// [fieldName] 字段名称
  /// 
  /// 返回验证结果
  static ValidationResult validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.error('$fieldName不能为空', fieldName: fieldName);
    }
    
    return ValidationResult.success();
  }

  /// 验证字符串长度
  /// 
  /// [value] 待验证的字符串
  /// [fieldName] 字段名称
  /// [minLength] 最小长度（可选）
  /// [maxLength] 最大长度（可选）
  /// 
  /// 返回验证结果
  static ValidationResult validateStringLength(
    String? value, 
    String fieldName, 
    {int? minLength, int? maxLength}
  ) {
    if (value == null) {
      return ValidationResult.error('$fieldName不能为空', fieldName: fieldName);
    }
    
    if (minLength != null && value.length < minLength) {
      return ValidationResult.error('$fieldName长度不能少于$minLength个字符', fieldName: fieldName);
    }
    
    if (maxLength != null && value.length > maxLength) {
      return ValidationResult.error('$fieldName长度不能超过$maxLength个字符', fieldName: fieldName);
    }
    
    return ValidationResult.success();
  }

  /// 验证管道参数的逻辑关系
  /// 
  /// [outerDiameter] 管外径
  /// [innerDiameter] 管内径
  /// 
  /// 返回验证结果
  static ValidationResult validatePipeParameters(
    double? outerDiameter, 
    double? innerDiameter,
  ) {
    // 首先验证单个参数
    final outerValidation = validatePositiveNumber(outerDiameter, '管外径');
    if (!outerValidation.isValid) return outerValidation;
    
    final innerValidation = validatePositiveNumber(innerDiameter, '管内径');
    if (!innerValidation.isValid) return innerValidation;
    
    // 验证逻辑关系
    if (outerDiameter! <= innerDiameter!) {
      return ValidationResult.error('管外径必须大于管内径');
    }
    
    return ValidationResult.success();
  }

  /// 验证筒刀参数的逻辑关系
  /// 
  /// [cutterOuterDiameter] 筒刀外径
  /// [cutterInnerDiameter] 筒刀内径
  /// 
  /// 返回验证结果
  static ValidationResult validateCutterParameters(
    double? cutterOuterDiameter, 
    double? cutterInnerDiameter,
  ) {
    // 首先验证单个参数
    final outerValidation = validatePositiveNumber(cutterOuterDiameter, '筒刀外径');
    if (!outerValidation.isValid) return outerValidation;
    
    final innerValidation = validatePositiveNumber(cutterInnerDiameter, '筒刀内径');
    if (!innerValidation.isValid) return innerValidation;
    
    // 验证逻辑关系
    if (cutterOuterDiameter! <= cutterInnerDiameter!) {
      return ValidationResult.error('筒刀外径必须大于筒刀内径');
    }
    
    return ValidationResult.success();
  }

  /// 验证螺纹咬合参数
  /// 
  /// [tValue] T值
  /// [wValue] W值
  /// 
  /// 返回验证结果
  static ValidationResult validateThreadEngagementParameters(
    double? tValue, 
    double? wValue,
  ) {
    // 首先验证单个参数
    final tValidation = validatePositiveNumber(tValue, 'T值');
    if (!tValidation.isValid) return tValidation;
    
    final wValidation = validatePositiveNumber(wValue, 'W值');
    if (!wValidation.isValid) return wValidation;
    
    // 检查螺纹咬合尺寸是否为负
    if (tValue! < wValue!) {
      return ValidationResult.warning('螺纹咬合尺寸为负值，请检查T值和W值');
    }
    
    return ValidationResult.success();
  }

  /// 验证E值（管外径-壁厚）
  /// 
  /// [eValue] E值
  /// 
  /// 返回验证结果
  static ValidationResult validateEValue(double? eValue) {
    if (eValue == null) {
      return ValidationResult.error('E值不能为空', fieldName: 'e_value');
    }
    
    if (eValue <= 0) {
      return ValidationResult.error('E值（管外径-壁厚）必须大于0，请检查管道参数', fieldName: 'e_value');
    }
    
    return ValidationResult.success();
  }

  /// 验证数值精度
  /// 
  /// [value] 待验证的数值
  /// [maxDecimalPlaces] 最大小数位数
  /// 
  /// 返回验证结果
  static ValidationResult validateDecimalPrecision(
    double? value, 
    String fieldName, 
    int maxDecimalPlaces,
  ) {
    if (value == null) {
      return ValidationResult.error('$fieldName不能为空', fieldName: fieldName);
    }
    
    final valueString = value.toString();
    final decimalIndex = valueString.indexOf('.');
    
    if (decimalIndex != -1) {
      final decimalPlaces = valueString.length - decimalIndex - 1;
      if (decimalPlaces > maxDecimalPlaces) {
        return ValidationResult.warning(
          '$fieldName的小数位数不应超过$maxDecimalPlaces位', 
          fieldName: fieldName,
        );
      }
    }
    
    return ValidationResult.success();
  }

  /// 验证参数组名称
  /// 
  /// [name] 参数组名称
  /// 
  /// 返回验证结果
  static ValidationResult validateParameterSetName(String? name) {
    final emptyValidation = validateNotEmpty(name, '参数组名称');
    if (!emptyValidation.isValid) return emptyValidation;
    
    final lengthValidation = validateStringLength(name, '参数组名称', minLength: 1, maxLength: 50);
    if (!lengthValidation.isValid) return lengthValidation;
    
    // 检查特殊字符
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(name!)) {
      return ValidationResult.error('参数组名称不能包含特殊字符 < > : " / \\ | ? *', fieldName: 'name');
    }
    
    return ValidationResult.success();
  }

  /// 验证开孔计算的工程合理性
  /// 
  /// [holeParams] 开孔参数
  /// 
  /// 返回验证结果
  static ValidationResult validateHoleCalculationFeasibility(HoleParameters holeParams) {
    final validations = <ValidationResult>[];
    
    // 计算管道壁厚
    final wallThickness = (holeParams.outerDiameter - holeParams.innerDiameter) / 2;
    
    // 验证壁厚的合理性
    if (wallThickness < 3.0) {
      validations.add(ValidationResult.warning('管道壁厚较薄(${wallThickness.toStringAsFixed(1)}mm)，开孔作业风险较高'));
    } else if (wallThickness > 50.0) {
      validations.add(ValidationResult.warning('管道壁厚较厚(${wallThickness.toStringAsFixed(1)}mm)，可能需要特殊工具'));
    }
    
    // 验证筒刀与管道的匹配性
    final cutterToWallRatio = holeParams.cutterOuterDiameter / (holeParams.outerDiameter - holeParams.innerDiameter);
    if (cutterToWallRatio > 0.8) {
      validations.add(ValidationResult.warning('筒刀外径与管道壁厚比例较高，可能影响切削效果'));
    }
    
    // 验证开孔深度的安全性
    final estimatedDepth = holeParams.rValue + wallThickness;
    if (estimatedDepth > holeParams.innerDiameter / 4) {
      validations.add(ValidationResult.warning('预估开孔深度较大，请确保不会影响管道结构安全'));
    }
    
    return combineValidations(validations);
  }

  /// 验证开孔作业的环境条件
  /// 
  /// [pressure] 管道压力 (MPa)，可选
  /// [temperature] 管道温度 (°C)，可选
  /// [medium] 介质类型，可选
  /// 
  /// 返回验证结果
  static ValidationResult validateHoleOperationConditions({
    double? pressure,
    double? temperature,
    String? medium,
  }) {
    final validations = <ValidationResult>[];
    
    if (pressure != null) {
      if (pressure > 4.0) {
        validations.add(ValidationResult.error('管道压力过高(${pressure}MPa)，不建议进行开孔作业'));
      } else if (pressure > 2.0) {
        validations.add(ValidationResult.warning('管道压力较高(${pressure}MPa)，请采取额外安全措施'));
      }
    }
    
    if (temperature != null) {
      if (temperature > 200.0) {
        validations.add(ValidationResult.error('管道温度过高(${temperature}°C)，不建议进行开孔作业'));
      } else if (temperature > 100.0) {
        validations.add(ValidationResult.warning('管道温度较高(${temperature}°C)，请注意防护'));
      } else if (temperature < -20.0) {
        validations.add(ValidationResult.warning('管道温度较低(${temperature}°C)，材料可能变脆'));
      }
    }
    
    if (medium != null) {
      final hazardousMediums = ['氢气', '氨气', '硫化氢', '一氧化碳'];
      if (hazardousMediums.any((m) => medium.contains(m))) {
        validations.add(ValidationResult.error('危险介质($medium)，需要特殊安全程序'));
      }
      
      final corrosiveMediums = ['酸', '碱', '盐水'];
      if (corrosiveMediums.any((m) => medium.contains(m))) {
        validations.add(ValidationResult.warning('腐蚀性介质($medium)，请选择耐腐蚀工具'));
      }
    }
    
    return combineValidations(validations);
  }

  /// 批量验证参数
  /// 
  /// [validations] 验证结果列表
  /// 
  /// 返回合并的验证结果
  static ValidationResult combineValidations(List<ValidationResult> validations) {
    final errors = validations.where((v) => v.isError).toList();
    final warnings = validations.where((v) => v.isWarning).toList();
    
    if (errors.isNotEmpty) {
      final errorMessages = errors.map((e) => e.message).join('; ');
      return ValidationResult.error(errorMessages);
    }
    
    if (warnings.isNotEmpty) {
      final warningMessages = warnings.map((w) => w.message).join('; ');
      return ValidationResult.warning(warningMessages);
    }
    
    return ValidationResult.success();
  }
}