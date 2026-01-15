import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:typed_data';
import '../../lib/services/help_content_manager.dart';
import '../../lib/models/help_content.dart';
import '../../lib/models/enums.dart';

/// 帮助系统属性测试
/// 
/// 验证帮助信息完整性的属性测试
/// **功能: pipeline-calculation-app, 属性 11: 帮助信息完整性**
/// **验证需求: 8.2, 8.5**

void main() {
  group('帮助系统属性测试', () {
    late HelpContentManager helpManager;

    setUpAll(() async {
      // 设置测试环境
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // 模拟资源加载
      _setupMockAssets();
      
      helpManager = HelpContentManager.instance;
      await helpManager.initialize();
    });

    group('属性 11: 帮助信息完整性', () {
      test('所有计算类型都有对应的参数帮助信息', () {
        // **功能: pipeline-calculation-app, 属性 11: 帮助信息完整性**
        // **验证需求: 8.2, 8.5**
        
        // 对于任何计算类型，都应该有完整的参数帮助信息
        for (final calculationType in CalculationType.values) {
          final parameterHelps = helpManager.getParameterHelpsForCalculationType(calculationType);
          
          // 验证每个计算类型都有参数帮助
          expect(parameterHelps.isNotEmpty, isTrue, 
              reason: '计算类型 $calculationType 应该有参数帮助信息');
          
          // 验证每个参数帮助都有必要的字段
          for (final help in parameterHelps) {
            _validateParameterHelp(help);
          }
        }
      });

      test('所有参数帮助信息都包含必要字段', () {
        // **功能: pipeline-calculation-app, 属性 11: 帮助信息完整性**
        // **验证需求: 8.2, 8.5**
        
        // 生成随机参数名称进行测试
        final random = Random();
        final parameterNames = [
          'outerDiameter', 'innerDiameter', 'cutterOuterDiameter', 
          'cutterInnerDiameter', 'a', 'b', 'r', 'initialValue', 'gasketThickness',
          'l', 'j', 'p', 't', 'w', 'd', 'e', 'm', 'k', 'n', 'f', 'g', 'h'
        ];
        
        // 随机选择参数进行测试
        for (int i = 0; i < 10; i++) {
          final parameterName = parameterNames[random.nextInt(parameterNames.length)];
          final help = helpManager.getParameterHelp(parameterName);
          
          if (help != null) {
            _validateParameterHelp(help);
          }
        }
      });

      test('搜索功能能够找到相关帮助内容', () {
        // **功能: pipeline-calculation-app, 属性 11: 帮助信息完整性**
        // **验证需求: 8.2, 8.5**
        
        // 对于任何有效的搜索关键词，都应该能找到相关内容
        final searchQueries = [
          '管外径', '筒刀', '开孔', '封堵', '计算', '参数', '测量', '螺纹', '行程'
        ];
        
        for (final query in searchQueries) {
          final results = helpManager.searchHelpContent(query);
          
          // 验证搜索结果的完整性
          for (final result in results) {
            expect(result.title.isNotEmpty, isTrue, 
                reason: '搜索结果应该有标题');
            expect(result.summary.isNotEmpty, isTrue, 
                reason: '搜索结果应该有摘要');
            expect(result.relevanceScore, greaterThan(0.0), 
                reason: '搜索结果应该有相关性评分');
            expect(result.relevanceScore, lessThanOrEqualTo(1.0), 
                reason: '相关性评分不应超过1.0');
          }
        }
      });

      test('教程内容结构完整', () {
        // **功能: pipeline-calculation-app, 属性 11: 帮助信息完整性**
        // **验证需求: 8.2, 8.5**
        
        final tutorials = helpManager.getAllTutorials();
        
        // 验证每个教程都有完整的结构
        for (final tutorial in tutorials) {
          expect(tutorial.title.isNotEmpty, isTrue, 
              reason: '教程应该有标题');
          expect(tutorial.description.isNotEmpty, isTrue, 
              reason: '教程应该有描述');
          expect(tutorial.steps.isNotEmpty, isTrue, 
              reason: '教程应该有步骤');
          expect(tutorial.estimatedMinutes, greaterThan(0), 
              reason: '教程应该有预计时间');
          
          // 验证每个步骤的完整性
          for (final step in tutorial.steps) {
            expect(step.title.isNotEmpty, isTrue, 
                reason: '教程步骤应该有标题');
            expect(step.description.isNotEmpty, isTrue, 
                reason: '教程步骤应该有描述');
          }
        }
      });

      test('FAQ内容结构完整', () {
        // **功能: pipeline-calculation-app, 属性 11: 帮助信息完整性**
        // **验证需求: 8.2, 8.5**
        
        final faqs = helpManager.getAllFAQs();
        
        // 验证每个FAQ都有完整的结构
        for (final faq in faqs) {
          expect(faq.question.isNotEmpty, isTrue, 
              reason: 'FAQ应该有问题');
          expect(faq.answer.isNotEmpty, isTrue, 
              reason: 'FAQ应该有答案');
          expect(faq.id.isNotEmpty, isTrue, 
              reason: 'FAQ应该有ID');
        }
      });

      test('故障排除建议结构完整', () {
        // **功能: pipeline-calculation-app, 属性 11: 帮助信息完整性**
        // **验证需求: 8.2, 8.5**
        
        final tips = helpManager.getAllTroubleshootingTips();
        
        // 验证每个故障排除建议都有完整的结构
        for (final tip in tips) {
          expect(tip.symptom.isNotEmpty, isTrue, 
              reason: '故障排除建议应该有症状描述');
          expect(tip.possibleCauses.isNotEmpty, isTrue, 
              reason: '故障排除建议应该有可能原因');
          expect(tip.solutions.isNotEmpty, isTrue, 
              reason: '故障排除建议应该有解决方案');
          expect(tip.id.isNotEmpty, isTrue, 
              reason: '故障排除建议应该有ID');
          
          // 验证每个原因和解决方案都不为空
          for (final cause in tip.possibleCauses) {
            expect(cause.isNotEmpty, isTrue, 
                reason: '可能原因不应为空');
          }
          
          for (final solution in tip.solutions) {
            expect(solution.isNotEmpty, isTrue, 
                reason: '解决方案不应为空');
          }
        }
      });

      test('帮助内容搜索结果相关性合理', () {
        // **功能: pipeline-calculation-app, 属性 11: 帮助信息完整性**
        // **验证需求: 8.2, 8.5**
        
        // 对于任何搜索查询，相关性评分应该合理
        final testQueries = ['开孔', '封堵', '参数', '计算', '测量'];
        
        for (final query in testQueries) {
          final results = helpManager.searchHelpContent(query);
          
          if (results.isNotEmpty) {
            // 验证结果按相关性排序
            for (int i = 0; i < results.length - 1; i++) {
              expect(results[i].relevanceScore, 
                  greaterThanOrEqualTo(results[i + 1].relevanceScore),
                  reason: '搜索结果应该按相关性降序排列');
            }
            
            // 验证最高相关性结果确实包含搜索词
            final topResult = results.first;
            final containsQuery = topResult.title.toLowerCase().contains(query.toLowerCase()) ||
                                topResult.summary.toLowerCase().contains(query.toLowerCase());
            expect(containsQuery, isTrue, 
                reason: '最相关的结果应该包含搜索关键词');
          }
        }
      });

      test('参数帮助信息覆盖所有必要参数', () {
        // **功能: pipeline-calculation-app, 属性 11: 帮助信息完整性**
        // **验证需求: 8.2, 8.5**
        
        // 定义每个计算类型必须的参数
        final requiredParameters = {
          CalculationType.hole: [
            'outerDiameter', 'innerDiameter', 'cutterOuterDiameter', 
            'cutterInnerDiameter', 'a', 'b', 'r', 'initialValue', 'gasketThickness'
          ],
          CalculationType.manualHole: ['l', 'j', 'p', 't', 'w'],
          CalculationType.sealing: ['r', 'b', 'e', 'gasketThickness', 'initialValue', 'd'],
          CalculationType.plug: ['m', 'k', 'n', 't', 'w'],
          CalculationType.stem: ['f', 'g', 'h', 'gasketThickness', 'initialValue'],
        };
        
        // 验证每个计算类型的必要参数都有帮助信息
        for (final entry in requiredParameters.entries) {
          final calculationType = entry.key;
          final parameters = entry.value;
          
          for (final parameterName in parameters) {
            final help = helpManager.getParameterHelp(parameterName);
            expect(help, isNotNull, 
                reason: '参数 $parameterName (计算类型: $calculationType) 应该有帮助信息');
            
            if (help != null) {
              _validateParameterHelp(help);
            }
          }
        }
      });
    });
  });
}

/// 验证参数帮助信息的完整性
void _validateParameterHelp(ParameterHelp help) {
  expect(help.parameterName.isNotEmpty, isTrue, 
      reason: '参数名称不应为空');
  expect(help.displayName.isNotEmpty, isTrue, 
      reason: '参数显示名称不应为空');
  expect(help.description.isNotEmpty, isTrue, 
      reason: '参数描述不应为空');
  expect(help.measurementMethod.isNotEmpty, isTrue, 
      reason: '测量方法不应为空');
  expect(help.example.isNotEmpty, isTrue, 
      reason: '示例值不应为空');
  expect(help.unit.isNotEmpty, isTrue, 
      reason: '单位不应为空');
  
  // 验证示例值是有效的数字
  final exampleValue = double.tryParse(help.example);
  expect(exampleValue, isNotNull, 
      reason: '示例值应该是有效的数字');
  expect(exampleValue!, greaterThan(0), 
      reason: '示例值应该大于0');
}

/// 设置模拟资源
void _setupMockAssets() {
  // 模拟参数帮助资源
  const parameterHelpsJson = '''
  {
    "outerDiameter": {
      "parameterName": "outerDiameter",
      "displayName": "管外径",
      "description": "管道的外部直径尺寸",
      "measurementMethod": "使用卡尺测量",
      "example": "219.1",
      "unit": "mm",
      "valueRange": "50-1000mm",
      "notes": ["确保测量准确"]
    }
  }
  ''';
  
  // 模拟教程资源
  const tutorialsJson = '''
  {
    "hole_tutorial": {
      "id": "hole_tutorial",
      "title": "开孔计算教程",
      "description": "学习开孔计算",
      "calculationType": "CalculationType.hole",
      "estimatedMinutes": 10,
      "steps": [
        {
          "title": "准备工作",
          "description": "准备测量工具",
          "tips": ["准备卡尺"]
        }
      ]
    }
  }
  ''';
  
  // 模拟FAQ资源
  const faqsJson = '''
  [
    {
      "id": "faq_001",
      "question": "如何使用应用？",
      "answer": "按照教程操作",
      "tags": ["使用方法"],
      "relatedCalculationTypes": ["CalculationType.hole"]
    }
  ]
  ''';
  
  // 模拟故障排除资源
  const troubleshootingJson = '''
  [
    {
      "id": "trouble_001",
      "symptom": "计算错误",
      "possibleCauses": ["参数错误"],
      "solutions": ["检查参数"],
      "preventionTips": ["仔细输入"]
    }
  ]
  ''';
  
  // 设置资源束模拟
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
    final String key = String.fromCharCodes(message!.buffer.asUint8List());
    
    if (key.contains('parameter_helps.json')) {
      return ByteData.sublistView(Uint8List.fromList(parameterHelpsJson.codeUnits));
    } else if (key.contains('tutorials.json')) {
      return ByteData.sublistView(Uint8List.fromList(tutorialsJson.codeUnits));
    } else if (key.contains('faqs.json')) {
      return ByteData.sublistView(Uint8List.fromList(faqsJson.codeUnits));
    } else if (key.contains('troubleshooting.json')) {
      return ByteData.sublistView(Uint8List.fromList(troubleshootingJson.codeUnits));
    }
    
    return null;
  });
}