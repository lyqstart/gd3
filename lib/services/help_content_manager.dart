import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/help_content.dart';
import '../models/enums.dart';

/// 帮助内容管理器
/// 
/// 负责管理应用中的所有帮助内容，包括参数说明、操作教程、
/// 常见问题解答和故障排除建议等。
class HelpContentManager {
  static HelpContentManager? _instance;
  static HelpContentManager get instance => _instance ??= HelpContentManager._();
  
  HelpContentManager._();

  /// 参数帮助信息缓存
  Map<String, ParameterHelp>? _parameterHelps;
  
  /// 操作教程缓存
  Map<String, Tutorial>? _tutorials;
  
  /// 常见问题解答缓存
  Map<String, FAQ>? _faqs;
  
  /// 故障排除建议缓存
  Map<String, TroubleshootingTip>? _troubleshootingTips;

  /// 初始化帮助内容
  Future<void> initialize() async {
    await Future.wait([
      _loadParameterHelps(),
      _loadTutorials(),
      _loadFAQs(),
      _loadTroubleshootingTips(),
    ]);
  }

  /// 加载参数帮助信息
  Future<void> _loadParameterHelps() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/help/parameter_helps.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      _parameterHelps = {};
      for (final entry in jsonData.entries) {
        _parameterHelps![entry.key] = ParameterHelp.fromJson(entry.value);
      }
    } catch (e) {
      // 如果加载失败，使用默认的参数帮助信息
      _parameterHelps = _getDefaultParameterHelps();
    }
  }

  /// 加载操作教程
  Future<void> _loadTutorials() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/help/tutorials.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      _tutorials = {};
      for (final entry in jsonData.entries) {
        _tutorials![entry.key] = Tutorial.fromJson(entry.value);
      }
    } catch (e) {
      // 如果加载失败，使用默认的教程
      _tutorials = _getDefaultTutorials();
    }
  }

  /// 加载常见问题解答
  Future<void> _loadFAQs() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/help/faqs.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      _faqs = {};
      for (final item in jsonData) {
        final faq = FAQ.fromJson(item);
        _faqs![faq.id] = faq;
      }
    } catch (e) {
      // 如果加载失败，使用默认的FAQ
      _faqs = _getDefaultFAQs();
    }
  }

  /// 加载故障排除建议
  Future<void> _loadTroubleshootingTips() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/help/troubleshooting.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      _troubleshootingTips = {};
      for (final item in jsonData) {
        final tip = TroubleshootingTip.fromJson(item);
        _troubleshootingTips![tip.id] = tip;
      }
    } catch (e) {
      // 如果加载失败，使用默认的故障排除建议
      _troubleshootingTips = _getDefaultTroubleshootingTips();
    }
  }

  /// 获取参数帮助信息
  ParameterHelp? getParameterHelp(String parameterName) {
    return _parameterHelps?[parameterName];
  }

  /// 获取计算类型的所有参数帮助
  List<ParameterHelp> getParameterHelpsForCalculationType(CalculationType calculationType) {
    if (_parameterHelps == null) return [];
    
    final List<String> parameterNames = _getParameterNamesForCalculationType(calculationType);
    return parameterNames
        .map((name) => _parameterHelps![name])
        .where((help) => help != null)
        .cast<ParameterHelp>()
        .toList();
  }

  /// 获取操作教程
  Tutorial? getTutorial(String tutorialId) {
    return _tutorials?[tutorialId];
  }

  /// 获取计算类型的教程
  List<Tutorial> getTutorialsForCalculationType(CalculationType calculationType) {
    if (_tutorials == null) return [];
    
    return _tutorials!.values
        .where((tutorial) => tutorial.calculationType == calculationType.toString())
        .toList();
  }

  /// 获取所有教程
  List<Tutorial> getAllTutorials() {
    return _tutorials?.values.toList() ?? [];
  }

  /// 获取常见问题解答
  FAQ? getFAQ(String faqId) {
    return _faqs?[faqId];
  }

  /// 获取所有FAQ
  List<FAQ> getAllFAQs() {
    return _faqs?.values.toList() ?? [];
  }

  /// 获取计算类型相关的FAQ
  List<FAQ> getFAQsForCalculationType(CalculationType calculationType) {
    if (_faqs == null) return [];
    
    return _faqs!.values
        .where((faq) => faq.relatedCalculationTypes.contains(calculationType.toString()))
        .toList();
  }

  /// 获取故障排除建议
  TroubleshootingTip? getTroubleshootingTip(String tipId) {
    return _troubleshootingTips?[tipId];
  }

  /// 获取所有故障排除建议
  List<TroubleshootingTip> getAllTroubleshootingTips() {
    return _troubleshootingTips?.values.toList() ?? [];
  }

  /// 搜索帮助内容
  List<HelpSearchResult> searchHelpContent(String query) {
    final List<HelpSearchResult> results = [];
    final String lowerQuery = query.toLowerCase();

    // 搜索参数帮助
    if (_parameterHelps != null) {
      for (final help in _parameterHelps!.values) {
        final double score = _calculateRelevanceScore(lowerQuery, [
          help.displayName,
          help.description,
          help.parameterName,
        ]);
        
        if (score > 0.1) {
          results.add(HelpSearchResult(
            contentType: HelpContentType.parameterHelp,
            contentId: help.parameterName,
            title: help.displayName,
            summary: help.description,
            relevanceScore: score,
          ));
        }
      }
    }

    // 搜索教程
    if (_tutorials != null) {
      for (final tutorial in _tutorials!.values) {
        final double score = _calculateRelevanceScore(lowerQuery, [
          tutorial.title,
          tutorial.description,
        ]);
        
        if (score > 0.1) {
          results.add(HelpSearchResult(
            contentType: HelpContentType.tutorial,
            contentId: tutorial.id,
            title: tutorial.title,
            summary: tutorial.description,
            relevanceScore: score,
          ));
        }
      }
    }

    // 搜索FAQ
    if (_faqs != null) {
      for (final faq in _faqs!.values) {
        final double score = _calculateRelevanceScore(lowerQuery, [
          faq.question,
          faq.answer,
        ]);
        
        if (score > 0.1) {
          results.add(HelpSearchResult(
            contentType: HelpContentType.faq,
            contentId: faq.id,
            title: faq.question,
            summary: faq.answer.length > 100 
                ? '${faq.answer.substring(0, 100)}...' 
                : faq.answer,
            relevanceScore: score,
          ));
        }
      }
    }

    // 搜索故障排除建议
    if (_troubleshootingTips != null) {
      for (final tip in _troubleshootingTips!.values) {
        final double score = _calculateRelevanceScore(lowerQuery, [
          tip.symptom,
          ...tip.possibleCauses,
          ...tip.solutions,
        ]);
        
        if (score > 0.1) {
          results.add(HelpSearchResult(
            contentType: HelpContentType.troubleshooting,
            contentId: tip.id,
            title: tip.symptom,
            summary: tip.possibleCauses.isNotEmpty 
                ? tip.possibleCauses.first 
                : '',
            relevanceScore: score,
          ));
        }
      }
    }

    // 按相关性排序
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results;
  }

  /// 计算相关性评分
  double _calculateRelevanceScore(String query, List<String> texts) {
    double maxScore = 0.0;
    
    for (final text in texts) {
      final String lowerText = text.toLowerCase();
      double score = 0.0;
      
      // 完全匹配得分最高
      if (lowerText.contains(query)) {
        score = 1.0;
      } else {
        // 部分匹配计算
        final List<String> queryWords = query.split(' ');
        int matchCount = 0;
        
        for (final word in queryWords) {
          if (lowerText.contains(word)) {
            matchCount++;
          }
        }
        
        if (queryWords.isNotEmpty) {
          score = matchCount / queryWords.length;
        }
      }
      
      maxScore = score > maxScore ? score : maxScore;
    }
    
    return maxScore;
  }

  /// 获取计算类型对应的参数名称列表
  List<String> _getParameterNamesForCalculationType(CalculationType calculationType) {
    switch (calculationType) {
      case CalculationType.hole:
        return [
          'outerDiameter', 'innerDiameter', 'cutterOuterDiameter', 
          'cutterInnerDiameter', 'a', 'b', 'r', 'initialValue', 'gasketThickness'
        ];
      case CalculationType.manualHole:
        return ['l', 'j', 'p', 't', 'w'];
      case CalculationType.sealing:
        return ['r', 'b', 'e', 'gasketThickness', 'initialValue', 'd'];
      case CalculationType.plug:
        return ['m', 'k', 'n', 't', 'w'];
      case CalculationType.stem:
        return ['f', 'g', 'h', 'gasketThickness', 'initialValue'];
    }
  }

  /// 获取默认参数帮助信息
  Map<String, ParameterHelp> _getDefaultParameterHelps() {
    return {
      'outerDiameter': const ParameterHelp(
        parameterName: 'outerDiameter',
        displayName: '管外径',
        description: '管道的外部直径尺寸',
        measurementMethod: '使用卡尺或测径器测量管道外壁的直径',
        example: '219.1',
        unit: 'mm',
        valueRange: '50-1000mm',
        notes: ['确保测量位置垂直于管道轴线', '多点测量取平均值'],
      ),
      'innerDiameter': const ParameterHelp(
        parameterName: 'innerDiameter',
        displayName: '管内径',
        description: '管道的内部直径尺寸',
        measurementMethod: '使用内径卡尺测量管道内壁的直径',
        example: '203.2',
        unit: 'mm',
        valueRange: '40-950mm',
        notes: ['内径必须小于外径', '注意管道内壁的腐蚀情况'],
      ),
      'cutterOuterDiameter': const ParameterHelp(
        parameterName: 'cutterOuterDiameter',
        displayName: '筒刀外径',
        description: '筒刀的外部直径尺寸',
        measurementMethod: '使用卡尺测量筒刀外壁的直径',
        example: '25.4',
        unit: 'mm',
        valueRange: '10-50mm',
        notes: ['选择合适规格的筒刀', '检查筒刀是否有磨损'],
      ),
      'cutterInnerDiameter': const ParameterHelp(
        parameterName: 'cutterInnerDiameter',
        displayName: '筒刀内径',
        description: '筒刀的内部直径尺寸',
        measurementMethod: '使用内径卡尺测量筒刀内壁的直径',
        example: '19.1',
        unit: 'mm',
        valueRange: '8-45mm',
        notes: ['内径必须小于外径', '确保筒刀内壁光滑'],
      ),
      'a': const ParameterHelp(
        parameterName: 'a',
        displayName: 'A值(中心钻关联联箱口)',
        description: '中心钻到联箱口的距离',
        measurementMethod: '测量中心钻尖端到联箱口边缘的直线距离',
        example: '15.0',
        unit: 'mm',
        valueRange: '5-50mm',
        notes: ['确保测量基准点准确', '考虑设备安装误差'],
      ),
      'b': const ParameterHelp(
        parameterName: 'b',
        displayName: 'B值(夹板顶到管外壁)',
        description: '夹板顶部到管道外壁的距离',
        measurementMethod: '测量夹板顶面到管道外壁表面的垂直距离',
        example: '12.5',
        unit: 'mm',
        valueRange: '5-30mm',
        notes: ['确保夹板安装牢固', '测量时保持垂直'],
      ),
      'r': const ParameterHelp(
        parameterName: 'r',
        displayName: 'R值(中心钻尖到筒刀)',
        description: '中心钻尖端到筒刀的距离',
        measurementMethod: '测量中心钻尖端到筒刀前端的直线距离',
        example: '8.0',
        unit: 'mm',
        valueRange: '3-20mm',
        notes: ['确保中心钻和筒刀对齐', '检查设备装配精度'],
      ),
      'initialValue': const ParameterHelp(
        parameterName: 'initialValue',
        displayName: '初始值',
        description: '设备的初始位置偏移量',
        measurementMethod: '根据设备说明书或现场测量确定',
        example: '5.0',
        unit: 'mm',
        valueRange: '0-15mm',
        notes: ['参考设备技术参数', '考虑温度补偿'],
      ),
      'gasketThickness': const ParameterHelp(
        parameterName: 'gasketThickness',
        displayName: '垫片厚度',
        description: '密封垫片的厚度',
        measurementMethod: '使用千分尺测量垫片厚度',
        example: '3.0',
        unit: 'mm',
        valueRange: '1-10mm',
        notes: ['选择合适材质的垫片', '检查垫片是否完整'],
      ),
    };
  }

  /// 获取默认教程
  Map<String, Tutorial> _getDefaultTutorials() {
    return {
      'hole_calculation_tutorial': Tutorial(
        id: 'hole_calculation_tutorial',
        title: '开孔尺寸计算教程',
        description: '学习如何正确进行开孔尺寸计算',
        calculationType: 'CalculationType.hole',
        estimatedMinutes: 10,
        steps: [
          const TutorialStep(
            title: '准备工作',
            description: '准备测量工具：卡尺、内径卡尺、测径器等',
            tips: ['确保测量工具精度', '检查工具校准状态'],
          ),
          const TutorialStep(
            title: '测量管道参数',
            description: '测量管道外径和内径，记录准确数值',
            tips: ['多点测量取平均值', '注意测量位置的选择'],
          ),
          const TutorialStep(
            title: '输入参数',
            description: '在应用中输入测量得到的各项参数',
            tips: ['仔细核对输入数值', '注意单位统一'],
          ),
          const TutorialStep(
            title: '查看结果',
            description: '查看计算结果，重点关注空行程和总行程',
            tips: ['核对关键尺寸', '保存计算记录'],
          ),
        ],
      ),
    };
  }

  /// 获取默认FAQ
  Map<String, FAQ> _getDefaultFAQs() {
    return {
      'faq_001': const FAQ(
        id: 'faq_001',
        question: '为什么计算结果出现负数？',
        answer: '计算结果出现负数通常是因为输入参数不合理，比如管内径大于外径，或者筒刀尺寸设置错误。请检查输入参数的合理性。',
        tags: ['计算错误', '参数验证'],
        relatedCalculationTypes: ['CalculationType.hole', 'CalculationType.manualHole'],
      ),
      'faq_002': const FAQ(
        id: 'faq_002',
        question: '如何选择合适的筒刀规格？',
        answer: '筒刀规格应根据管道直径和开孔要求选择。一般情况下，筒刀外径应小于管道内径，具体规格请参考设备技术手册。',
        tags: ['设备选择', '筒刀规格'],
        relatedCalculationTypes: ['CalculationType.hole'],
      ),
      'faq_003': const FAQ(
        id: 'faq_003',
        question: '计算精度如何保证？',
        answer: '应用采用高精度数学运算，计算误差控制在0.1mm以内。为确保精度，请使用精确的测量工具，并仔细核对输入参数。',
        tags: ['计算精度', '测量准确性'],
        relatedCalculationTypes: ['CalculationType.hole', 'CalculationType.manualHole', 'CalculationType.sealing'],
      ),
    };
  }

  /// 获取默认故障排除建议
  Map<String, TroubleshootingTip> _getDefaultTroubleshootingTips() {
    return {
      'trouble_001': const TroubleshootingTip(
        id: 'trouble_001',
        symptom: '计算结果明显不合理',
        possibleCauses: [
          '输入参数错误',
          '单位不统一',
          '测量数据有误',
        ],
        solutions: [
          '重新检查所有输入参数',
          '确认使用统一的单位制',
          '重新测量关键尺寸',
          '参考类似工况的历史数据',
        ],
        preventionTips: [
          '建立参数检查清单',
          '使用校准过的测量工具',
          '多人交叉验证重要参数',
        ],
      ),
      'trouble_002': const TroubleshootingTip(
        id: 'trouble_002',
        symptom: '应用计算速度很慢',
        possibleCauses: [
          '设备性能不足',
          '后台应用过多',
          '数据库同步问题',
        ],
        solutions: [
          '关闭不必要的后台应用',
          '重启应用程序',
          '检查网络连接状态',
          '清理应用缓存',
        ],
        preventionTips: [
          '定期清理设备存储空间',
          '保持应用版本更新',
          '避免同时运行过多应用',
        ],
      ),
    };
  }
}