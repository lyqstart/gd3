/// 应用程序常量定义
class AppConstants {
  /// 应用名称
  static const String appName = '油气管道开孔封堵计算APP';
  
  /// 应用版本
  static const String appVersion = '1.0.0';
  
  /// 计算精度阈值（毫米）
  static const double precisionThreshold = 0.1;
  
  /// 默认小数位数
  static const int defaultDecimalPlaces = 2;
  
  /// 数据库名称
  static const String databaseName = 'pipeline_calc.db';
  
  /// 数据库版本
  static const int databaseVersion = 1;
  
  /// 远程数据库配置
  static const String remoteDbHost = 'localhost';
  static const int remoteDbPort = 3306;
  static const String remoteDbName = 'pipeline_calc';
  static const String remoteDbUsername = 'root';
  static const String remoteDbPassword = '314697';
  
  /// 文件导出配置
  static const String exportDirectory = 'PipelineCalculations';
  static const String pdfFilePrefix = 'calculation_';
  static const String excelFilePrefix = 'batch_calculation_';
  
  /// UI配置
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  /// 颜色配置
  static const int primaryColorValue = 0xFFFF9800; // Orange
  static const int secondaryColorValue = 0xFFF44336; // Red
  static const int backgroundColorValue = 0xFF121212; // Dark background
  static const int surfaceColorValue = 0xFF1E1E1E; // Dark surface
  
  /// 动画配置
  static const int defaultAnimationDuration = 300; // 毫秒
  static const int longAnimationDuration = 500; // 毫秒
  
  /// 网络配置
  static const int connectionTimeout = 30; // 秒
  static const int receiveTimeout = 30; // 秒
  static const int maxRetryAttempts = 3;
  
  /// 缓存配置
  static const int maxCacheSize = 100; // 最大缓存条目数
  static const int cacheExpirationHours = 24; // 缓存过期时间（小时）
}

/// 计算公式常量
class FormulaConstants {
  /// 开孔计算公式标识
  static const String holeEmptyStroke = 'S空 = A + B + 初始值 + 垫片厚度';
  static const String holeCuttingDistance = 'C1 = √(管外径² - 管内径²) - 筒刀外径';
  static const String holeChordHeight = 'C2 = √(管外径² - 管内径²) - 筒刀内径';
  static const String holeCuttingSize = 'C = R + C1';
  static const String holeTotalStroke = 'S总 = S空 + C';
  static const String holePlateStroke = 'S掉板 = S总 + R + C2';
  
  /// 手动开孔计算公式标识
  static const String manualHoleThreadEngagement = '螺纹咬合尺寸 = T - W';
  static const String manualHoleEmptyStroke = '空行程 = L + J + T + W';
  static const String manualHoleTotalStroke = '总行程 = L + J + T + W + P';
  
  /// 封堵计算公式标识
  static const String sealingGuideWheelStroke = '导向轮接触管线行程 = R + B + E + 垫子厚度 + 初始值';
  static const String sealingTotalStroke = '封堵总行程 = D + B + E + 垫子厚度 + 初始值';
  
  /// 下塞堵计算公式标识
  static const String plugThreadEngagement = '螺纹咬合尺寸 = T - W';
  static const String plugEmptyStroke = '空行程 = M + K - T + W';
  static const String plugTotalStroke = '总行程 = M + K + N - T + W';
  
  /// 下塞柄计算公式标识
  static const String stemTotalStroke = '总行程 = F + G + H + 垫子厚度 + 初始值';
}

/// 错误消息常量
class ErrorMessages {
  /// 参数验证错误
  static const String invalidOuterDiameter = '管外径必须大于0';
  static const String invalidInnerDiameter = '管内径必须大于0';
  static const String outerDiameterTooSmall = '管外径必须大于管内径';
  static const String invalidCutterOuterDiameter = '筒刀外径必须大于0';
  static const String invalidCutterInnerDiameter = '筒刀内径必须大于0';
  static const String cutterOuterDiameterTooSmall = '筒刀外径必须大于筒刀内径';
  static const String negativeThreadEngagement = '螺纹咬合尺寸为负值，请检查T值和W值';
  static const String invalidEValue = 'E值（管外径-壁厚）必须大于0，请检查管道参数';
  
  /// 计算错误
  static const String calculationFailed = '计算失败，请检查输入参数';
  static const String precisionOverflow = '计算结果超出精度范围';
  static const String mathError = '数学运算错误';
  static const String negativeSquareRoot = '不能计算负数的平方根';
  
  /// 数据库错误
  static const String databaseConnectionFailed = '数据库连接失败';
  static const String databaseOperationFailed = '数据库操作失败';
  static const String syncFailed = '数据同步失败';
  
  /// 文件操作错误
  static const String fileExportFailed = '文件导出失败';
  static const String filePermissionDenied = '文件权限不足';
  static const String storageSpaceInsufficient = '存储空间不足';
  
  /// 网络错误
  static const String networkConnectionFailed = '网络连接失败';
  static const String networkTimeout = '网络请求超时';
  static const String serverError = '服务器错误';
}

/// 成功消息常量
class SuccessMessages {
  /// 计算成功
  static const String calculationCompleted = '计算完成';
  static const String parametersSaved = '参数组保存成功';
  static const String parametersLoaded = '参数组加载成功';
  
  /// 导出成功
  static const String pdfExported = 'PDF文件导出成功';
  static const String excelExported = 'Excel文件导出成功';
  static const String resultShared = '结果分享成功';
  
  /// 同步成功
  static const String syncCompleted = '数据同步完成';
  static const String backupCompleted = '数据备份完成';
}