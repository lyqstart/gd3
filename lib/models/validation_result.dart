import 'enums.dart';

/// 参数验证结果类
class ValidationResult {
  /// 验证结果类型
  final ValidationResultType type;
  
  /// 验证消息
  final String message;
  
  /// 相关字段名称（可选）
  final String? fieldName;

  const ValidationResult({
    required this.type,
    required this.message,
    this.fieldName,
  });

  /// 创建成功验证结果
  factory ValidationResult.success([String message = '验证通过']) {
    return ValidationResult(
      type: ValidationResultType.success,
      message: message,
    );
  }

  /// 创建警告验证结果
  factory ValidationResult.warning(String message, {String? fieldName}) {
    return ValidationResult(
      type: ValidationResultType.warning,
      message: message,
      fieldName: fieldName,
    );
  }

  /// 创建错误验证结果
  factory ValidationResult.error(String message, {String? fieldName}) {
    return ValidationResult(
      type: ValidationResultType.error,
      message: message,
      fieldName: fieldName,
    );
  }

  /// 是否验证成功
  bool get isSuccess => type == ValidationResultType.success;

  /// 是否有警告
  bool get isWarning => type == ValidationResultType.warning;

  /// 是否有错误
  bool get isError => type == ValidationResultType.error;

  /// 是否验证通过（成功或警告）
  bool get isValid => isSuccess || isWarning;

  @override
  String toString() {
    return 'ValidationResult(type: $type, message: $message, fieldName: $fieldName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidationResult &&
        other.type == type &&
        other.message == message &&
        other.fieldName == fieldName;
  }

  @override
  int get hashCode => Object.hash(type, message, fieldName);
}