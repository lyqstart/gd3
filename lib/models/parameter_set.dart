/// 参数组数据模型
/// 
/// 用于存储和同步参数组
class ParameterSet {
  /// 参数组ID
  final String id;
  
  /// 用户ID
  final String userId;
  
  /// 参数组名称
  final String name;
  
  /// 计算类型
  final String calculationType;
  
  /// 参数JSON
  final Map<String, dynamic> parameters;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime updatedAt;
  
  /// 同步状态
  final String syncStatus;
  
  /// 是否为预设参数
  final bool isPreset;

  ParameterSet({
    required this.id,
    required this.userId,
    required this.name,
    required this.calculationType,
    required this.parameters,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isPreset = false,
  });

  /// 从JSON创建
  factory ParameterSet.fromJson(Map<String, dynamic> json) {
    return ParameterSet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      calculationType: json['calculation_type'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      syncStatus: json['sync_status'] as String,
      isPreset: json['is_preset'] as bool? ?? false,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'calculation_type': calculationType,
      'parameters': parameters,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
      'is_preset': isPreset,
    };
  }

  /// 复制并修改部分字段
  ParameterSet copyWith({
    String? id,
    String? userId,
    String? name,
    String? calculationType,
    Map<String, dynamic>? parameters,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    bool? isPreset,
  }) {
    return ParameterSet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      calculationType: calculationType ?? this.calculationType,
      parameters: parameters ?? this.parameters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isPreset: isPreset ?? this.isPreset,
    );
  }
}
