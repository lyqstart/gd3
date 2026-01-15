import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import '../../lib/services/diagram_generator.dart';
import '../../lib/models/calculation_result.dart';
import '../../lib/models/calculation_parameters.dart';
import '../../lib/models/enums.dart';

/// 示意图生成属性测试
/// 
/// 验证示意图生成功能的正确性属性
void main() {
  group('示意图生成属性测试', () {
    late DiagramGenerator diagramGenerator;

    setUpAll(() async {
      // 初始化Flutter绑定
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      diagramGenerator = DiagramGenerator();
    });

    group('属性 8: 示意图元素完整性', () {
      test('开孔示意图应包含所有必需元素', () async {
        // **功能: pipeline-calculation-app, 属性 8: 示意图元素完整性**
        // **验证需求: 7.2, 7.5**
        
        for (int i = 0; i < 20; i++) {
          // 生成随机的开孔参数
          final params = _generateRandomHoleParameters();
          
          // 创建计算结果
          final result = HoleCalculationResult(
            emptyStroke: params.aValue + params.bValue + params.initialValue + params.gasketThickness,
            cuttingDistance: sqrt(pow(params.outerDiameter, 2) - pow(params.innerDiameter, 2)) - params.cutterOuterDiameter,
            chordHeight: sqrt(pow(params.outerDiameter, 2) - pow(params.innerDiameter, 2)) - params.cutterInnerDiameter,
            cuttingSize: params.rValue + (sqrt(pow(params.outerDiameter, 2) - pow(params.innerDiameter, 2)) - params.cutterOuterDiameter),
            totalStroke: (params.aValue + params.bValue + params.initialValue + params.gasketThickness) + 
                        (params.rValue + (sqrt(pow(params.outerDiameter, 2) - pow(params.innerDiameter, 2)) - params.cutterOuterDiameter)),
            plateStroke: (params.aValue + params.bValue + params.initialValue + params.gasketThickness) + 
                        (params.rValue + (sqrt(pow(params.outerDiameter, 2) - pow(params.innerDiameter, 2)) - params.cutterOuterDiameter)) +
                        params.rValue + (sqrt(pow(params.outerDiameter, 2) - pow(params.innerDiameter, 2)) - params.cutterInnerDiameter),
            calculationTime: DateTime.now(),
            parameters: params,
          );

          try {
            // 生成示意图
            final image = await diagramGenerator.generateHoleDiagram(result);
            
            // 验证图像生成成功
            expect(image, isNotNull, reason: '示意图应该成功生成');
            expect(image.width, greaterThan(0), reason: '示意图宽度应该大于0');
            expect(image.height, greaterThan(0), reason: '示意图高度应该大于0');
            
            // 清理资源
            image.dispose();
          } catch (e) {
            fail('开孔示意图生成失败: $e');
          }
        }
      });

      test('手动开孔示意图应包含所有必需元素', () async {
        // **功能: pipeline-calculation-app, 属性 8: 示意图元素完整性**
        // **验证需求: 7.2, 7.5**
        
        for (int i = 0; i < 20; i++) {
          // 生成随机的手动开孔参数
          final params = _generateRandomManualHoleParameters();
          
          // 创建计算结果
          final result = ManualHoleResult(
            threadEngagement: params.tValue - params.wValue,
            emptyStroke: params.lValue + params.jValue + params.tValue + params.wValue,
            totalStroke: params.lValue + params.jValue + params.tValue + params.wValue + params.pValue,
            calculationTime: DateTime.now(),
            parameters: params,
          );

          try {
            // 生成示意图
            final image = await diagramGenerator.generateManualHoleDiagram(result);
            
            // 验证图像生成成功
            expect(image, isNotNull, reason: '手动开孔示意图应该成功生成');
            expect(image.width, greaterThan(0), reason: '示意图宽度应该大于0');
            expect(image.height, greaterThan(0), reason: '示意图高度应该大于0');
            
            // 清理资源
            image.dispose();
          } catch (e) {
            fail('手动开孔示意图生成失败: $e');
          }
        }
      });

      test('封堵示意图应包含所有必需元素', () async {
        // **功能: pipeline-calculation-app, 属性 8: 示意图元素完整性**
        // **验证需求: 7.2, 7.5**
        
        for (int i = 0; i < 20; i++) {
          // 生成随机的封堵参数
          final params = _generateRandomSealingParameters();
          
          // 创建计算结果
          final result = SealingResult(
            guideWheelStroke: params.rValue + params.bValue + params.eValue + params.gasketThickness + params.initialValue,
            totalStroke: params.dValue + params.bValue + params.eValue + params.gasketThickness + params.initialValue,
            calculationTime: DateTime.now(),
            parameters: params,
          );

          try {
            // 生成示意图
            final image = await diagramGenerator.generateSealingDiagram(result);
            
            // 验证图像生成成功
            expect(image, isNotNull, reason: '封堵示意图应该成功生成');
            expect(image.width, greaterThan(0), reason: '示意图宽度应该大于0');
            expect(image.height, greaterThan(0), reason: '示意图高度应该大于0');
            
            // 清理资源
            image.dispose();
          } catch (e) {
            fail('封堵示意图生成失败: $e');
          }
        }
      });

      test('下塞堵示意图应包含所有必需元素', () async {
        // **功能: pipeline-calculation-app, 属性 8: 示意图元素完整性**
        // **验证需求: 7.2, 7.5**
        
        for (int i = 0; i < 20; i++) {
          // 生成随机的下塞堵参数
          final params = _generateRandomPlugParameters();
          
          // 创建计算结果
          final result = PlugResult(
            threadEngagement: params.tValue - params.wValue,
            emptyStroke: params.mValue + params.kValue - params.tValue + params.wValue,
            totalStroke: params.mValue + params.kValue + params.nValue - params.tValue + params.wValue,
            calculationTime: DateTime.now(),
            parameters: params,
          );

          try {
            // 生成示意图
            final image = await diagramGenerator.generatePlugDiagram(result);
            
            // 验证图像生成成功
            expect(image, isNotNull, reason: '下塞堵示意图应该成功生成');
            expect(image.width, greaterThan(0), reason: '示意图宽度应该大于0');
            expect(image.height, greaterThan(0), reason: '示意图高度应该大于0');
            
            // 清理资源
            image.dispose();
          } catch (e) {
            fail('下塞堵示意图生成失败: $e');
          }
        }
      });

      test('下塞柄示意图应包含所有必需元素', () async {
        // **功能: pipeline-calculation-app, 属性 8: 示意图元素完整性**
        // **验证需求: 7.2, 7.5**
        
        for (int i = 0; i < 20; i++) {
          // 生成随机的下塞柄参数
          final params = _generateRandomStemParameters();
          
          // 创建计算结果
          final result = StemResult(
            totalStroke: params.fValue + params.gValue + params.hValue + params.gasketThickness + params.initialValue,
            calculationTime: DateTime.now(),
            parameters: params,
          );

          try {
            // 生成示意图
            final image = await diagramGenerator.generateStemDiagram(result);
            
            // 验证图像生成成功
            expect(image, isNotNull, reason: '下塞柄示意图应该成功生成');
            expect(image.width, greaterThan(0), reason: '示意图宽度应该大于0');
            expect(image.height, greaterThan(0), reason: '示意图高度应该大于0');
            
            // 清理资源
            image.dispose();
          } catch (e) {
            fail('下塞柄示意图生成失败: $e');
          }
        }
      });
    });

    group('示意图生成稳定性测试', () {
      test('相同参数应生成相同尺寸的示意图', () async {
        final params = HoleParameters(
          outerDiameter: 100.0,
          innerDiameter: 80.0,
          cutterOuterDiameter: 20.0,
          cutterInnerDiameter: 15.0,
          aValue: 50.0,
          bValue: 30.0,
          rValue: 10.0,
          initialValue: 5.0,
          gasketThickness: 2.0,
        );

        final result = HoleCalculationResult(
          emptyStroke: 87.0,
          cuttingDistance: 40.0,
          chordHeight: 45.0,
          cuttingSize: 50.0,
          totalStroke: 137.0,
          plateStroke: 192.0,
          calculationTime: DateTime.now(),
          parameters: params,
        );

        // 生成多次示意图
        final images = <ui.Image>[];
        for (int i = 0; i < 5; i++) {
          final image = await diagramGenerator.generateHoleDiagram(result);
          images.add(image);
        }

        // 验证所有图像尺寸相同
        final firstImage = images.first;
        for (int i = 1; i < images.length; i++) {
          expect(images[i].width, equals(firstImage.width), 
                 reason: '相同参数生成的示意图宽度应该相同');
          expect(images[i].height, equals(firstImage.height), 
                 reason: '相同参数生成的示意图高度应该相同');
        }

        // 清理资源
        for (final image in images) {
          image.dispose();
        }
      });

      test('极端参数值应能正常生成示意图', () async {
        // 测试极小值
        final minParams = HoleParameters(
          outerDiameter: 10.0,
          innerDiameter: 8.0,
          cutterOuterDiameter: 2.0,
          cutterInnerDiameter: 1.0,
          aValue: 1.0,
          bValue: 1.0,
          rValue: 0.5,
          initialValue: 0.1,
          gasketThickness: 0.1,
        );

        final minResult = HoleCalculationResult(
          emptyStroke: 2.7,
          cuttingDistance: 4.0,
          chordHeight: 5.0,
          cuttingSize: 4.5,
          totalStroke: 7.2,
          plateStroke: 12.2,
          calculationTime: DateTime.now(),
          parameters: minParams,
        );

        // 测试极大值
        final maxParams = HoleParameters(
          outerDiameter: 1000.0,
          innerDiameter: 900.0,
          cutterOuterDiameter: 200.0,
          cutterInnerDiameter: 150.0,
          aValue: 500.0,
          bValue: 300.0,
          rValue: 100.0,
          initialValue: 50.0,
          gasketThickness: 20.0,
        );

        final maxResult = HoleCalculationResult(
          emptyStroke: 870.0,
          cuttingDistance: 236.6,
          chordHeight: 286.6,
          cuttingSize: 336.6,
          totalStroke: 1206.6,
          plateStroke: 1693.2,
          calculationTime: DateTime.now(),
          parameters: maxParams,
        );

        // 验证极值情况下都能正常生成
        final minImage = await diagramGenerator.generateHoleDiagram(minResult);
        final maxImage = await diagramGenerator.generateHoleDiagram(maxResult);

        expect(minImage, isNotNull, reason: '极小参数应能生成示意图');
        expect(maxImage, isNotNull, reason: '极大参数应能生成示意图');

        minImage.dispose();
        maxImage.dispose();
      });
    });
  });
}

/// 生成随机开孔参数
HoleParameters _generateRandomHoleParameters() {
  final random = Random();
  final outerDiameter = 50.0 + random.nextDouble() * 500.0; // 50-550mm
  final innerDiameter = outerDiameter * (0.6 + random.nextDouble() * 0.3); // 60-90%
  
  return HoleParameters(
    outerDiameter: outerDiameter,
    innerDiameter: innerDiameter,
    cutterOuterDiameter: 10.0 + random.nextDouble() * 50.0,
    cutterInnerDiameter: 5.0 + random.nextDouble() * 30.0,
    aValue: random.nextDouble() * 200.0,
    bValue: random.nextDouble() * 100.0,
    rValue: random.nextDouble() * 50.0,
    initialValue: random.nextDouble() * 20.0,
    gasketThickness: 1.0 + random.nextDouble() * 10.0,
  );
}

/// 生成随机手动开孔参数
ManualHoleParameters _generateRandomManualHoleParameters() {
  final random = Random();
  
  return ManualHoleParameters(
    lValue: random.nextDouble() * 200.0,
    jValue: random.nextDouble() * 100.0,
    pValue: random.nextDouble() * 150.0,
    tValue: 20.0 + random.nextDouble() * 80.0,
    wValue: 10.0 + random.nextDouble() * 40.0,
  );
}

/// 生成随机封堵参数
SealingParameters _generateRandomSealingParameters() {
  final random = Random();
  
  return SealingParameters(
    rValue: random.nextDouble() * 100.0,
    bValue: random.nextDouble() * 80.0,
    dValue: random.nextDouble() * 120.0,
    eValue: random.nextDouble() * 60.0,
    gasketThickness: 1.0 + random.nextDouble() * 8.0,
    initialValue: random.nextDouble() * 15.0,
  );
}

/// 生成随机下塞堵参数
PlugParameters _generateRandomPlugParameters() {
  final random = Random();
  
  return PlugParameters(
    mValue: random.nextDouble() * 200.0,
    kValue: random.nextDouble() * 100.0,
    nValue: random.nextDouble() * 80.0,
    tValue: 20.0 + random.nextDouble() * 60.0,
    wValue: 10.0 + random.nextDouble() * 30.0,
  );
}

/// 生成随机下塞柄参数
StemParameters _generateRandomStemParameters() {
  final random = Random();
  
  return StemParameters(
    fValue: random.nextDouble() * 300.0,
    gValue: random.nextDouble() * 150.0,
    hValue: random.nextDouble() * 100.0,
    gasketThickness: 1.0 + random.nextDouble() * 8.0,
    initialValue: random.nextDouble() * 15.0,
  );
}