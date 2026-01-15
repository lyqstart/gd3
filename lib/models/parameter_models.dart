import 'validation_result.dart';
import 'enums.dart';
import 'calculation_parameters.dart';
import '../utils/validators.dart';

/// 参数组类
class ParameterSet {
  /// 唯一标识符
  final String id;
  
  /// 参数组名称
  final String name;
  
  /// 计算类型
  final CalculationType calculationType;
  
  /// 参数数据对象
  final CalculationParameters parameters;
  
  /// 是否为预设参数
  final bool isPreset;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime updatedAt;
  
  /// 参数组描述
  final String? description;
  
  /// 参数组标签
  final List<String> tags;

  ParameterSet({
    required this.id,
    required this.name,
    required this.calculationType,
    required this.parameters,
    this.isPreset = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.description,
    this.tags = const [],
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// 验证参数组
  ValidationResult validate() {
    final validations = <ValidationResult>[
      // 验证参数组名称
      Validators.validateParameterSetName(name),
      
      // 验证参数数据
      parameters.validate(),
    ];

    return Validators.combineValidations(validations);
  }

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calculation_type': calculationType.value,
      'parameters': parameters.toJson(),
      'is_preset': isPreset,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'description': description,
      'tags': tags,
    };
  }

  /// 从JSON格式创建对象
  factory ParameterSet.fromJson(Map<String, dynamic> json) {
    final calculationType = CalculationType.values.firstWhere(
      (e) => e.value == json['calculation_type'],
    );
    
    return ParameterSet(
      id: json['id'] as String,
      name: json['name'] as String,
      calculationType: calculationType,
      parameters: CalculationParameters.fromJson(
        json['parameters'] as Map<String, dynamic>,
        calculationType,
      ),
      isPreset: json['is_preset'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at']),
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// 创建副本
  ParameterSet copyWith({
    String? id,
    String? name,
    CalculationType? calculationType,
    CalculationParameters? parameters,
    bool? isPreset,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    List<String>? tags,
  }) {
    return ParameterSet(
      id: id ?? this.id,
      name: name ?? this.name,
      calculationType: calculationType ?? this.calculationType,
      parameters: parameters ?? this.parameters,
      isPreset: isPreset ?? this.isPreset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      description: description ?? this.description,
      tags: tags ?? List<String>.from(this.tags),
    );
  }

  @override
  String toString() {
    return 'ParameterSet(id: $id, name: $name, type: $calculationType, isPreset: $isPreset)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParameterSet && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 预设参数类
class PresetParameter {
  /// 参数名称
  final String name;
  
  /// 参数值
  final double value;
  
  /// 参数单位
  final UnitType unit;
  
  /// 参数描述
  final String description;
  
  /// 适用的计算类型
  final List<CalculationType> applicableTypes;

  const PresetParameter({
    required this.name,
    required this.value,
    required this.unit,
    required this.description,
    required this.applicableTypes,
  });

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit.symbol,
      'description': description,
      'applicable_types': applicableTypes.map((e) => e.value).toList(),
    };
  }

  /// 从JSON格式创建对象
  factory PresetParameter.fromJson(Map<String, dynamic> json) {
    return PresetParameter(
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
      unit: UnitType.values.firstWhere((e) => e.symbol == json['unit']),
      description: json['description'] as String,
      applicableTypes: (json['applicable_types'] as List<dynamic>)
          .map((e) => CalculationType.values.firstWhere((type) => type.value == e))
          .toList(),
    );
  }
}

/// 导出选项类
class ExportOptions {
  /// 是否包含示意图
  final bool includeDiagram;
  
  /// 是否包含计算过程
  final bool includeProcess;
  
  /// 是否包含参数明细
  final bool includeParameters;
  
  /// 文件名前缀
  final String? fileNamePrefix;
  
  /// 导出格式
  final ShareFormat format;

  const ExportOptions({
    this.includeDiagram = true,
    this.includeProcess = true,
    this.includeParameters = true,
    this.fileNamePrefix,
    this.format = ShareFormat.pdf,
  });

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'include_diagram': includeDiagram,
      'include_process': includeProcess,
      'include_parameters': includeParameters,
      'file_name_prefix': fileNamePrefix,
      'format': format.value,
    };
  }

  /// 从JSON格式创建对象
  factory ExportOptions.fromJson(Map<String, dynamic> json) {
    return ExportOptions(
      includeDiagram: json['include_diagram'] as bool? ?? true,
      includeProcess: json['include_process'] as bool? ?? true,
      includeParameters: json['include_parameters'] as bool? ?? true,
      fileNamePrefix: json['file_name_prefix'] as String?,
      format: ShareFormat.values.firstWhere(
        (e) => e.value == json['format'],
        orElse: () => ShareFormat.pdf,
      ),
    );
  }

  /// 创建副本
  ExportOptions copyWith({
    bool? includeDiagram,
    bool? includeProcess,
    bool? includeParameters,
    String? fileNamePrefix,
    ShareFormat? format,
  }) {
    return ExportOptions(
      includeDiagram: includeDiagram ?? this.includeDiagram,
      includeProcess: includeProcess ?? this.includeProcess,
      includeParameters: includeParameters ?? this.includeParameters,
      fileNamePrefix: fileNamePrefix ?? this.fileNamePrefix,
      format: format ?? this.format,
    );
  }
}

/// 单位转换常量类
class UnitConversionConstants {
  /// 毫米到英寸的转换系数
  static const double mmToInch = 1.0 / 25.4;
  
  /// 英寸到毫米的转换系数
  static const double inchToMm = 25.4;
  
  /// 精度保持的小数位数
  static const int precisionDecimalPlaces = 4;
  
  /// 显示精度的小数位数
  static const int displayDecimalPlaces = 2;

  /// 执行单位转换
  static double convert(double value, UnitType from, UnitType to) {
    if (from == to) return value;
    
    // 先转换为毫米基准
    double valueInMm;
    switch (from) {
      case UnitType.millimeter:
        valueInMm = value;
        break;
      case UnitType.inch:
        valueInMm = value * inchToMm;
        break;
    }
    
    // 再转换为目标单位
    switch (to) {
      case UnitType.millimeter:
        return valueInMm;
      case UnitType.inch:
        return valueInMm * mmToInch;
    }
  }

  /// 格式化显示数值
  static String formatValue(double value, UnitType unit) {
    final formattedValue = value.toStringAsFixed(displayDecimalPlaces);
    return '$formattedValue ${unit.symbol}';
  }
}

/// 应用设置类
class AppSettings {
  /// 默认单位类型
  final UnitType defaultUnit;
  
  /// 是否启用高精度模式
  final bool highPrecisionMode;
  
  /// 是否启用自动保存
  final bool autoSave;
  
  /// 自动保存间隔（秒）
  final int autoSaveInterval;
  
  /// 是否启用云端同步
  final bool cloudSyncEnabled;
  
  /// 是否启用离线模式
  final bool offlineMode;
  
  /// 主题模式
  final ThemeMode themeMode;
  
  /// 语言设置
  final String language;
  
  /// 是否显示帮助提示
  final bool showHelpTips;
  
  /// 计算结果保留的小数位数
  final int resultDecimalPlaces;

  const AppSettings({
    this.defaultUnit = UnitType.millimeter,
    this.highPrecisionMode = true,
    this.autoSave = true,
    this.autoSaveInterval = 30,
    this.cloudSyncEnabled = false,
    this.offlineMode = false,
    this.themeMode = ThemeMode.dark,
    this.language = 'zh_CN',
    this.showHelpTips = true,
    this.resultDecimalPlaces = 2,
  });

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'default_unit': defaultUnit.symbol,
      'high_precision_mode': highPrecisionMode,
      'auto_save': autoSave,
      'auto_save_interval': autoSaveInterval,
      'cloud_sync_enabled': cloudSyncEnabled,
      'offline_mode': offlineMode,
      'theme_mode': themeMode.name,
      'language': language,
      'show_help_tips': showHelpTips,
      'result_decimal_places': resultDecimalPlaces,
    };
  }

  /// 从JSON格式创建对象
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      defaultUnit: UnitType.values.firstWhere(
        (e) => e.symbol == json['default_unit'],
        orElse: () => UnitType.millimeter,
      ),
      highPrecisionMode: json['high_precision_mode'] as bool? ?? true,
      autoSave: json['auto_save'] as bool? ?? true,
      autoSaveInterval: json['auto_save_interval'] as int? ?? 30,
      cloudSyncEnabled: json['cloud_sync_enabled'] as bool? ?? false,
      offlineMode: json['offline_mode'] as bool? ?? false,
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['theme_mode'],
        orElse: () => ThemeMode.dark,
      ),
      language: json['language'] as String? ?? 'zh_CN',
      showHelpTips: json['show_help_tips'] as bool? ?? true,
      resultDecimalPlaces: json['result_decimal_places'] as int? ?? 2,
    );
  }

  /// 创建副本
  AppSettings copyWith({
    UnitType? defaultUnit,
    bool? highPrecisionMode,
    bool? autoSave,
    int? autoSaveInterval,
    bool? cloudSyncEnabled,
    bool? offlineMode,
    ThemeMode? themeMode,
    String? language,
    bool? showHelpTips,
    int? resultDecimalPlaces,
  }) {
    return AppSettings(
      defaultUnit: defaultUnit ?? this.defaultUnit,
      highPrecisionMode: highPrecisionMode ?? this.highPrecisionMode,
      autoSave: autoSave ?? this.autoSave,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      offlineMode: offlineMode ?? this.offlineMode,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      showHelpTips: showHelpTips ?? this.showHelpTips,
      resultDecimalPlaces: resultDecimalPlaces ?? this.resultDecimalPlaces,
    );
  }

  @override
  String toString() {
    return 'AppSettings(defaultUnit: $defaultUnit, highPrecisionMode: $highPrecisionMode, '
           'autoSave: $autoSave, cloudSyncEnabled: $cloudSyncEnabled)';
  }
}

/// 主题模式枚举
enum ThemeMode {
  /// 浅色主题
  light('light', '浅色主题'),
  
  /// 深色主题
  dark('dark', '深色主题'),
  
  /// 跟随系统
  system('system', '跟随系统');

  const ThemeMode(this.value, this.displayName);
  
  /// 主题值
  final String value;
  
  /// 显示名称
  final String displayName;
  
  @override
  String toString() => value;
}

/// 计算历史记录过滤器
class CalculationHistoryFilter {
  /// 计算类型过滤
  final List<CalculationType>? calculationTypes;
  
  /// 开始日期
  final DateTime? startDate;
  
  /// 结束日期
  final DateTime? endDate;
  
  /// 搜索关键词
  final String? searchKeyword;
  
  /// 是否只显示收藏的记录
  final bool onlyFavorites;
  
  /// 排序方式
  final SortOrder sortOrder;
  
  /// 排序字段
  final SortField sortField;

  const CalculationHistoryFilter({
    this.calculationTypes,
    this.startDate,
    this.endDate,
    this.searchKeyword,
    this.onlyFavorites = false,
    this.sortOrder = SortOrder.descending,
    this.sortField = SortField.calculationTime,
  });

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'calculation_types': calculationTypes?.map((e) => e.value).toList(),
      'start_date': startDate?.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'search_keyword': searchKeyword,
      'only_favorites': onlyFavorites,
      'sort_order': sortOrder.value,
      'sort_field': sortField.value,
    };
  }

  /// 从JSON格式创建对象
  factory CalculationHistoryFilter.fromJson(Map<String, dynamic> json) {
    return CalculationHistoryFilter(
      calculationTypes: (json['calculation_types'] as List<dynamic>?)
          ?.map((e) => CalculationType.values.firstWhere((type) => type.value == e))
          .toList(),
      startDate: json['start_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['start_date'])
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['end_date'])
          : null,
      searchKeyword: json['search_keyword'] as String?,
      onlyFavorites: json['only_favorites'] as bool? ?? false,
      sortOrder: SortOrder.values.firstWhere(
        (e) => e.value == json['sort_order'],
        orElse: () => SortOrder.descending,
      ),
      sortField: SortField.values.firstWhere(
        (e) => e.value == json['sort_field'],
        orElse: () => SortField.calculationTime,
      ),
    );
  }

  /// 创建副本
  CalculationHistoryFilter copyWith({
    List<CalculationType>? calculationTypes,
    DateTime? startDate,
    DateTime? endDate,
    String? searchKeyword,
    bool? onlyFavorites,
    SortOrder? sortOrder,
    SortField? sortField,
  }) {
    return CalculationHistoryFilter(
      calculationTypes: calculationTypes ?? this.calculationTypes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      sortOrder: sortOrder ?? this.sortOrder,
      sortField: sortField ?? this.sortField,
    );
  }
}

/// 排序顺序枚举
enum SortOrder {
  /// 升序
  ascending('asc', '升序'),
  
  /// 降序
  descending('desc', '降序');

  const SortOrder(this.value, this.displayName);
  
  /// 排序值
  final String value;
  
  /// 显示名称
  final String displayName;
  
  @override
  String toString() => value;
}

/// 排序字段枚举
enum SortField {
  /// 计算时间
  calculationTime('calculation_time', '计算时间'),
  
  /// 计算类型
  calculationType('calculation_type', '计算类型'),
  
  /// 创建时间
  createdAt('created_at', '创建时间');

  const SortField(this.value, this.displayName);
  
  /// 字段值
  final String value;
  
  /// 显示名称
  final String displayName;
  
  @override
  String toString() => value;
}