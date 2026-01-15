import 'dart:convert';
import 'enums.dart';

/// 计算记录数据模型
/// 
/// 用于存储和同步计算记录
class CalculationRecord {
  /// 记录ID（可为null表示未保存到数据库）
  final int? id;
  
  /// 用户ID（可选）
  final String? userId;
  
  /// 计算类型
  final CalculationType calculationType;
  
  /// 参数JSON
  final Map<String, dynamic> parameters;
  
  /// 结果JSON
  final Map<String, dynamic> results;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间（可选）
  final DateTime? updatedAt;
  
  /// 同步状态
  final SyncStatus syncStatus;
  
  /// 设备ID
  final String? deviceId;
  
  /// 客户端ID（用于冲突检测）
  final String? clientId;

  CalculationRecord({
    this.id,
    this.userId,
    required this.calculationType,
    required this.parameters,
    required this.results,
    required this.createdAt,
    DateTime? updatedAt,
    required this.syncStatus,
    this.deviceId,
    this.clientId,
  }) : updatedAt = updatedAt ?? createdAt;

  /// 从JSON创建
  factory CalculationRecord.fromJson(Map<String, dynamic> json) {
    return CalculationRecord(
      id: json['id'] as int?,
      userId: json['user_id'] as String?,
      calculationType: CalculationType.values.firstWhere(
        (e) => e.value == json['calculation_type'] || e.value == json['calculationType'],
        orElse: () => CalculationType.hole,
      ),
      parameters: json['parameters'] is String 
          ? Map<String, dynamic>.from(jsonDecode(json['parameters'] as String))
          : Map<String, dynamic>.from(json['parameters'] as Map),
      results: json['results'] is String
          ? Map<String, dynamic>.from(jsonDecode(json['results'] as String))
          : Map<String, dynamic>.from(json['results'] as Map),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] as String),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'] as String)
          : null,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.value == json['sync_status'] || e.value == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      deviceId: json['device_id'] as String? ?? json['deviceId'] as String?,
      clientId: json['client_id'] as String? ?? json['clientId'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'calculation_type': calculationType.value,
      'parameters': jsonEncode(parameters),  // 转换为JSON字符串
      'results': jsonEncode(results),  // 转换为JSON字符串
      'created_at': createdAt.toIso8601String(),
      'updated_at': (updatedAt ?? createdAt).toIso8601String(),
      'sync_status': syncStatus.value,
      if (deviceId != null) 'device_id': deviceId,
      if (clientId != null) 'client_id': clientId,
    };
  }

  /// 复制并修改部分字段
  CalculationRecord copyWith({
    int? id,
    String? userId,
    CalculationType? calculationType,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? results,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    String? deviceId,
    String? clientId,
  }) {
    return CalculationRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      calculationType: calculationType ?? this.calculationType,
      parameters: parameters ?? this.parameters,
      results: results ?? this.results,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deviceId: deviceId ?? this.deviceId,
      clientId: clientId ?? this.clientId,
    );
  }
}
