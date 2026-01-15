/// 计算类型枚举
enum CalculationType {
  /// 开孔尺寸计算
  hole('hole', '开孔尺寸计算'),
  
  /// 手动开孔计算
  manualHole('manual_hole', '手动开孔计算'),
  
  /// 封堵计算
  sealing('sealing', '封堵计算'),
  
  /// 下塞堵计算
  plug('plug', '下塞堵计算'),
  
  /// 下塞柄计算
  stem('stem', '下塞柄计算');

  const CalculationType(this.value, this.displayName);
  
  /// 枚举值
  final String value;
  
  /// 显示名称
  final String displayName;
  
  @override
  String toString() => value;
}

/// 单位类型枚举
enum UnitType {
  /// 毫米
  millimeter('mm', '毫米', 1.0),
  
  /// 英寸
  inch('inch', '英寸', 25.4);

  const UnitType(this.symbol, this.displayName, this.toMillimeterFactor);
  
  /// 单位符号
  final String symbol;
  
  /// 显示名称
  final String displayName;
  
  /// 转换为毫米的系数
  final double toMillimeterFactor;
  
  @override
  String toString() => symbol;
}

/// 分享格式枚举
enum ShareFormat {
  /// PDF格式
  pdf('pdf', 'PDF文档'),
  
  /// Excel格式
  excel('excel', 'Excel表格'),
  
  /// 图片格式
  image('image', '图片');

  const ShareFormat(this.value, this.displayName);
  
  /// 格式值
  final String value;
  
  /// 显示名称
  final String displayName;
  
  @override
  String toString() => value;
}

/// 验证结果类型枚举
enum ValidationResultType {
  /// 验证成功
  success('success', '验证成功'),
  
  /// 警告
  warning('warning', '警告'),
  
  /// 错误
  error('error', '错误');

  const ValidationResultType(this.value, this.displayName);
  
  /// 结果类型值
  final String value;
  
  /// 显示名称
  final String displayName;
  
  @override
  String toString() => value;
}


/// 同步状态枚举
enum SyncStatus {
  /// 待同步
  pending('pending', '待同步'),
  
  /// 同步中
  syncing('syncing', '同步中'),
  
  /// 已同步
  synced('synced', '已同步'),
  
  /// 同步失败
  failed('failed', '同步失败'),
  
  /// 冲突
  conflict('conflict', '冲突');

  const SyncStatus(this.value, this.displayName);
  
  /// 状态值
  final String value;
  
  /// 显示名称
  final String displayName;
  
  @override
  String toString() => value;
}
