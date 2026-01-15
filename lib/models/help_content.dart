/// 帮助内容数据模型
/// 
/// 定义帮助系统中使用的各种数据结构，包括参数说明、操作教程、
/// 常见问题解答等内容的数据模型。

/// 帮助内容类型枚举
enum HelpContentType {
  /// 参数说明
  parameterHelp,
  /// 操作教程
  tutorial,
  /// 常见问题解答
  faq,
  /// 计算异常诊断
  troubleshooting,
}

/// 参数帮助信息
class ParameterHelp {
  /// 参数名称
  final String parameterName;
  /// 参数显示名称（中文）
  final String displayName;
  /// 参数描述
  final String description;
  /// 测量方法说明
  final String measurementMethod;
  /// 示例值
  final String example;
  /// 单位
  final String unit;
  /// 取值范围
  final String? valueRange;
  /// 注意事项
  final List<String> notes;

  const ParameterHelp({
    required this.parameterName,
    required this.displayName,
    required this.description,
    required this.measurementMethod,
    required this.example,
    required this.unit,
    this.valueRange,
    this.notes = const [],
  });

  /// 从JSON创建对象
  factory ParameterHelp.fromJson(Map<String, dynamic> json) {
    return ParameterHelp(
      parameterName: json['parameterName'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      measurementMethod: json['measurementMethod'] as String,
      example: json['example'] as String,
      unit: json['unit'] as String,
      valueRange: json['valueRange'] as String?,
      notes: List<String>.from(json['notes'] ?? []),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'parameterName': parameterName,
      'displayName': displayName,
      'description': description,
      'measurementMethod': measurementMethod,
      'example': example,
      'unit': unit,
      'valueRange': valueRange,
      'notes': notes,
    };
  }
}

/// 操作教程步骤
class TutorialStep {
  /// 步骤标题
  final String title;
  /// 步骤描述
  final String description;
  /// 图片路径（可选）
  final String? imagePath;
  /// 提示信息
  final List<String> tips;

  const TutorialStep({
    required this.title,
    required this.description,
    this.imagePath,
    this.tips = const [],
  });

  /// 从JSON创建对象
  factory TutorialStep.fromJson(Map<String, dynamic> json) {
    return TutorialStep(
      title: json['title'] as String,
      description: json['description'] as String,
      imagePath: json['imagePath'] as String?,
      tips: List<String>.from(json['tips'] ?? []),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'tips': tips,
    };
  }
}

/// 操作教程
class Tutorial {
  /// 教程ID
  final String id;
  /// 教程标题
  final String title;
  /// 教程描述
  final String description;
  /// 适用的计算类型
  final String calculationType;
  /// 教程步骤
  final List<TutorialStep> steps;
  /// 预计完成时间（分钟）
  final int estimatedMinutes;

  const Tutorial({
    required this.id,
    required this.title,
    required this.description,
    required this.calculationType,
    required this.steps,
    required this.estimatedMinutes,
  });

  /// 从JSON创建对象
  factory Tutorial.fromJson(Map<String, dynamic> json) {
    return Tutorial(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      calculationType: json['calculationType'] as String,
      steps: (json['steps'] as List)
          .map((step) => TutorialStep.fromJson(step))
          .toList(),
      estimatedMinutes: json['estimatedMinutes'] as int,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'calculationType': calculationType,
      'steps': steps.map((step) => step.toJson()).toList(),
      'estimatedMinutes': estimatedMinutes,
    };
  }
}

/// 常见问题解答
class FAQ {
  /// 问题ID
  final String id;
  /// 问题
  final String question;
  /// 答案
  final String answer;
  /// 相关标签
  final List<String> tags;
  /// 相关计算类型
  final List<String> relatedCalculationTypes;

  const FAQ({
    required this.id,
    required this.question,
    required this.answer,
    this.tags = const [],
    this.relatedCalculationTypes = const [],
  });

  /// 从JSON创建对象
  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      relatedCalculationTypes: List<String>.from(json['relatedCalculationTypes'] ?? []),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'tags': tags,
      'relatedCalculationTypes': relatedCalculationTypes,
    };
  }
}

/// 故障排除建议
class TroubleshootingTip {
  /// 建议ID
  final String id;
  /// 问题症状
  final String symptom;
  /// 可能原因
  final List<String> possibleCauses;
  /// 解决方案
  final List<String> solutions;
  /// 预防措施
  final List<String> preventionTips;

  const TroubleshootingTip({
    required this.id,
    required this.symptom,
    required this.possibleCauses,
    required this.solutions,
    this.preventionTips = const [],
  });

  /// 从JSON创建对象
  factory TroubleshootingTip.fromJson(Map<String, dynamic> json) {
    return TroubleshootingTip(
      id: json['id'] as String,
      symptom: json['symptom'] as String,
      possibleCauses: List<String>.from(json['possibleCauses']),
      solutions: List<String>.from(json['solutions']),
      preventionTips: List<String>.from(json['preventionTips'] ?? []),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symptom': symptom,
      'possibleCauses': possibleCauses,
      'solutions': solutions,
      'preventionTips': preventionTips,
    };
  }
}

/// 帮助内容搜索结果
class HelpSearchResult {
  /// 内容类型
  final HelpContentType contentType;
  /// 内容ID
  final String contentId;
  /// 标题
  final String title;
  /// 摘要
  final String summary;
  /// 匹配度评分（0-1）
  final double relevanceScore;

  const HelpSearchResult({
    required this.contentType,
    required this.contentId,
    required this.title,
    required this.summary,
    required this.relevanceScore,
  });
}