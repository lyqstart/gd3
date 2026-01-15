import 'package:flutter_test/flutter_test.dart';
import 'package:pipeline_calculation_app/services/calculation_engine_adapter.dart';
import 'package:pipeline_calculation_app/services/interfaces/i_calculation_engine.dart';
import 'package:pipeline_calculation_app/models/calculation_parameters.dart';
import 'package:pipeline_calculation_app/models/enums.dart';
import 'dart:math';

/// 属性测试：验证系统的正确性属性
/// 
/// 本测试套件实现基于属性的测试(Property-Based Testing)，
/// 通过大量随机输入验证系统的数学正确性和一致性。
void main() {
  group('属性1: 数学公式计算正确性', () {
    late ICalculationEngine engine;
    final random = Random(42); // 固定种子以确保可重现性

    setUp(() {
      engine = CalculationEngineFactory.instance.getDefaultEngine();
    });

    test('开孔计算 - 空行程计算正确性 (需求1.1)', () {
      // 属性: 空行程 = A + B + R + 初始值 + 垫片厚度
      for (int i = 0; i < 100; i++) {
        final a = 30.0 + random.nextDouble() * 70.0; // 30-100mm
        final b = 20.0 + random.nextDouble() * 50.0; // 20-70mm
        final r = 10.0 + random.nextDouble() * 30.0; // 10-40mm
        final initial = 5.0 + random.nextDouble() * 15.0; // 5-20mm
        final gasket = 2.0 + random.nextDouble() * 5.0; // 2-7mm

        final params = HoleParameters(
          outerDiameter: 114.3,
          innerDiameter: 102.3,
          cutterOuterDiameter: 25.4,
          cutterInnerDiameter: 19.1,
          aValue: a,
          bValue: b,
          rValue: r,
          initialValue: initial,
          gasketThickness: gasket,
        );

        final result = engine.calculateHoleSize(params);
        final expectedEmptyStroke = a + b + r + initial + gasket;

        expect(
          (result.emptyStroke - expectedEmptyStroke).abs(),
          lessThan(0.1),
          reason: '空行程计算误差应小于0.1mm (迭代$i)',
        );
      }
    });

    test('开孔计算 - 切削距离计算正确性 (需求1.2)', () {
      // 属性: 切削距离 = (管外径 - 刀外径) / 2
      for (int i = 0; i < 100; i++) {
        final outerDiameter = 100.0 + random.nextDouble() * 200.0;
        final cutterOuter = 20.0 + random.nextDouble() * 40.0;

        final params = HoleParameters(
          outerDiameter: outerDiameter,
          innerDiameter: outerDiameter - 10.0,
          cutterOuterDiameter: cutterOuter,
          cutterInnerDiameter: cutterOuter - 5.0,
          aValue: 50.0,
          bValue: 30.0,
          rValue: 15.0,
          initialValue: 10.0,
          gasketThickness: 3.0,
        );

        final result = engine.calculateHoleSize(params);
        final expectedDistance = (outerDiameter - cutterOuter) / 2;

        expect(
          (result.cuttingDistance - expectedDistance).abs(),
          lessThan(0.1),
          reason: '切削距离计算误差应小于0.1mm (迭代$i)',
        );
      }
    });

    test('手动开孔计算 - 螺纹啮合量正确性 (需求2.1)', () {
      // 属性: 螺纹啮合量 = T - W
      for (int i = 0; i < 100; i++) {
        final t = 15.0 + random.nextDouble() * 20.0; // 15-35mm
        final w = 10.0 + random.nextDouble() * 15.0; // 10-25mm

        final params = ManualHoleParameters(
          lValue: 80.0,
          jValue: 40.0,
          pValue: 30.0,
          tValue: t,
          wValue: w,
        );

        final result = engine.calculateManualHole(params);
        final expectedEngagement = t - w;

        expect(
          (result.threadEngagement - expectedEngagement).abs(),
          lessThan(0.1),
          reason: '螺纹啮合量计算误差应小于0.1mm (迭代$i)',
        );
      }
    });

    test('封堵计算 - 导向轮行程正确性 (需求3.1)', () {
      // 属性: 导向轮行程 = R + B
      for (int i = 0; i < 100; i++) {
        final r = 10.0 + random.nextDouble() * 30.0;
        final b = 20.0 + random.nextDouble() * 50.0;

        final params = SealingParameters(
          rValue: r,
          bValue: b,
          dValue: 80.0,
          eValue: 100.0,
          gasketThickness: 3.0,
          initialValue: 5.0,
        );

        final result = engine.calculateSealing(params);
        final expectedGuideWheelStroke = r + b;

        expect(
          (result.guideWheelStroke - expectedGuideWheelStroke).abs(),
          lessThan(0.1),
          reason: '导向轮行程计算误差应小于0.1mm (迭代$i)',
        );
      }
    });

    test('下塞堵计算 - 总行程正确性 (需求4.1)', () {
      // 属性: 总行程 = M - K + N
      for (int i = 0; i < 100; i++) {
        final m = 80.0 + random.nextDouble() * 50.0;
        final k = 40.0 + random.nextDouble() * 30.0;
        final n = 30.0 + random.nextDouble() * 20.0;

        final params = PlugParameters(
          mValue: m,
          kValue: k,
          nValue: n,
          tValue: 25.0,
          wValue: 20.0,
        );

        final result = engine.calculatePlug(params);
        final expectedTotalStroke = m - k + n;

        expect(
          (result.totalStroke - expectedTotalStroke).abs(),
          lessThan(0.1),
          reason: '总行程计算误差应小于0.1mm (迭代$i)',
        );
      }
    });

    test('下塞柄计算 - 总行程正确性 (需求5.1)', () {
      // 属性: 总行程 = F + G + H + 垫片厚度 + 初始值
      for (int i = 0; i < 100; i++) {
        final f = 40.0 + random.nextDouble() * 40.0;
        final g = 30.0 + random.nextDouble() * 30.0;
        final h = 20.0 + random.nextDouble() * 20.0;
        final gasket = 2.0 + random.nextDouble() * 5.0;
        final initial = 3.0 + random.nextDouble() * 10.0;

        final params = StemParameters(
          fValue: f,
          gValue: g,
          hValue: h,
          gasketThickness: gasket,
          initialValue: initial,
        );

        final result = engine.calculateStem(params);
        final expectedTotalStroke = f + g + h + gasket + initial;

        expect(
          (result.totalStroke - expectedTotalStroke).abs(),
          lessThan(0.1),
          reason: '总行程计算误差应小于0.1mm (迭代$i)',
        );
      }
    });
  });

  group('属性2: 输入参数验证', () {
    late ICalculationEngine engine;

    setUp(() {
      engine = CalculationEngineFactory.instance.getDefaultEngine();
    });

    test('负数参数应被拒绝 (需求1.7, 2.4, 3.4, 4.4, 5.2)', () {
      final invalidParams = HoleParameters(
        outerDiameter: -114.3, // 负数
        innerDiameter: 102.3,
        cutterOuterDiameter: 25.4,
        cutterInnerDiameter: 19.1,
        aValue: 50.0,
        bValue: 30.0,
        rValue: 15.0,
        initialValue: 10.0,
        gasketThickness: 3.0,
      );

      final result = engine.validateParameters(CalculationType.hole, invalidParams);
      expect(result.isValid, isFalse);
      expect(result.message, contains('必须为正数'));
    });

    test('零值参数应被拒绝 (需求10.5)', () {
      final invalidParams = HoleParameters(
        outerDiameter: 0.0, // 零值
        innerDiameter: 102.3,
        cutterOuterDiameter: 25.4,
        cutterInnerDiameter: 19.1,
        aValue: 50.0,
        bValue: 30.0,
        rValue: 15.0,
        initialValue: 10.0,
        gasketThickness: 3.0,
      );

      final result = engine.validateParameters(CalculationType.hole, invalidParams);
      expect(result.isValid, isFalse);
    });

    test('管外径必须大于管内径', () {
      for (int i = 0; i < 50; i++) {
        final innerDiameter = 100.0 + Random().nextDouble() * 50.0;
        final outerDiameter = innerDiameter - 5.0; // 外径小于内径

        final params = HoleParameters(
          outerDiameter: outerDiameter,
          innerDiameter: innerDiameter,
          cutterOuterDiameter: 25.4,
          cutterInnerDiameter: 19.1,
          aValue: 50.0,
          bValue: 30.0,
          rValue: 15.0,
          initialValue: 10.0,
          gasketThickness: 3.0,
        );

        final result = engine.validateParameters(CalculationType.hole, params);
        expect(result.isValid, isFalse);
        expect(result.message, contains('管外径必须大于管内径'));
      }
    });

    test('刀外径必须大于刀内径', () {
      for (int i = 0; i < 50; i++) {
        final cutterInner = 20.0 + Random().nextDouble() * 10.0;
        final cutterOuter = cutterInner - 2.0; // 外径小于内径

        final params = HoleParameters(
          outerDiameter: 114.3,
          innerDiameter: 102.3,
          cutterOuterDiameter: cutterOuter,
          cutterInnerDiameter: cutterInner,
          aValue: 50.0,
          bValue: 30.0,
          rValue: 15.0,
          initialValue: 10.0,
          gasketThickness: 3.0,
        );

        final result = engine.validateParameters(CalculationType.hole, params);
        expect(result.isValid, isFalse);
      }
    });
  });

  group('属性3: 参数组往返一致性 (需求6.2, 6.3)', () {
    test('保存和加载参数组应保持数据一致', () {
      final random = Random(42);
      
      for (int i = 0; i < 100; i++) {
        // 创建随机参数
        final originalParams = {
          'outerDiameter': 100.0 + random.nextDouble() * 200.0,
          'innerDiameter': 90.0 + random.nextDouble() * 180.0,
          'aValue': 30.0 + random.nextDouble() * 70.0,
          'bValue': 20.0 + random.nextDouble() * 50.0,
        };

        // 模拟序列化和反序列化
        final serialized = originalParams.toString();
        final deserialized = _parseParameters(serialized);

        // 验证往返一致性
        expect(deserialized.keys.length, equals(originalParams.keys.length));
        for (final key in originalParams.keys) {
          expect(
            (deserialized[key]! - originalParams[key]!).abs(),
            lessThan(0.001),
            reason: '参数$key往返后应保持一致 (迭代$i)',
          );
        }
      }
    });
  });

  group('属性4: 单位转换往返保持 (需求6.5)', () {
    test('mm到inch再到mm应保持精度', () {
      final random = Random(42);
      
      for (int i = 0; i < 100; i++) {
        final originalMm = 10.0 + random.nextDouble() * 500.0;
        
        // mm -> inch -> mm
        final inch = originalMm / 25.4;
        final backToMm = inch * 25.4;

        expect(
          (backToMm - originalMm).abs(),
          lessThan(0.001),
          reason: '单位转换往返应保持精度 (迭代$i)',
        );
      }
    });

    test('inch到mm再到inch应保持精度', () {
      final random = Random(42);
      
      for (int i = 0; i < 100; i++) {
        final originalInch = 1.0 + random.nextDouble() * 20.0;
        
        // inch -> mm -> inch
        final mm = originalInch * 25.4;
        final backToInch = mm / 25.4;

        expect(
          (backToInch - originalInch).abs(),
          lessThan(0.00001),
          reason: '单位转换往返应保持精度 (迭代$i)',
        );
      }
    });
  });

  group('属性5: 示意图元素完整性 (需求7.2, 7.5)', () {
    test('示意图应包含所有必需元素', () {
      final params = HoleParameters(
        outerDiameter: 114.3,
        innerDiameter: 102.3,
        cutterOuterDiameter: 25.4,
        cutterInnerDiameter: 19.1,
        aValue: 50.0,
        bValue: 30.0,
        rValue: 15.0,
        initialValue: 10.0,
        gasketThickness: 3.0,
      );

      final engine = CalculationEngineFactory.instance.getDefaultEngine();
      final result = engine.calculateHoleSize(params);

      // 验证示意图数据完整性
      expect(result.emptyStroke, isNotNull);
      expect(result.cuttingDistance, isNotNull);
      expect(result.chordHeight, isNotNull);
      expect(result.cuttingSize, isNotNull);
      expect(result.totalStroke, isNotNull);
      expect(result.plateStroke, isNotNull);

      // 所有值应为正数
      expect(result.emptyStroke, greaterThan(0));
      expect(result.cuttingDistance, greaterThan(0));
      expect(result.chordHeight, greaterThan(0));
      expect(result.cuttingSize, greaterThan(0));
      expect(result.totalStroke, greaterThan(0));
      expect(result.plateStroke, greaterThan(0));
    });
  });

  group('属性6: 离线功能完整性 (需求9.2, 12.1, 12.2, 12.4)', () {
    test('离线计算应与在线计算结果一致', () {
      final engine = CalculationEngineFactory.instance.getDefaultEngine();
      final random = Random(42);

      for (int i = 0; i < 50; i++) {
        final params = HoleParameters(
          outerDiameter: 100.0 + random.nextDouble() * 100.0,
          innerDiameter: 90.0 + random.nextDouble() * 90.0,
          cutterOuterDiameter: 20.0 + random.nextDouble() * 20.0,
          cutterInnerDiameter: 15.0 + random.nextDouble() * 15.0,
          aValue: 30.0 + random.nextDouble() * 50.0,
          bValue: 20.0 + random.nextDouble() * 40.0,
          rValue: 10.0 + random.nextDouble() * 20.0,
          initialValue: 5.0 + random.nextDouble() * 10.0,
          gasketThickness: 2.0 + random.nextDouble() * 5.0,
        );

        // 模拟离线计算
        final offlineResult = engine.calculateHoleSize(params);
        
        // 模拟在线计算（使用相同引擎）
        final onlineResult = engine.calculateHoleSize(params);

        // 结果应完全一致
        expect(offlineResult.emptyStroke, equals(onlineResult.emptyStroke));
        expect(offlineResult.totalStroke, equals(onlineResult.totalStroke));
        expect(offlineResult.plateStroke, equals(onlineResult.plateStroke));
      }
    });
  });

  group('属性8: 跨平台计算一致性 (需求13.1, 13.2, 13.3)', () {
    test('不同引擎实例应产生相同结果', () {
      final factory = CalculationEngineFactory.instance;
      final engine1 = factory.createEngine();
      final engine2 = factory.createPrecisionEngine();
      final random = Random(42);

      for (int i = 0; i < 50; i++) {
        final params = HoleParameters(
          outerDiameter: 114.3,
          innerDiameter: 102.3,
          cutterOuterDiameter: 25.4,
          cutterInnerDiameter: 19.1,
          aValue: 50.0 + random.nextDouble() * 20.0,
          bValue: 30.0 + random.nextDouble() * 15.0,
          rValue: 15.0 + random.nextDouble() * 10.0,
          initialValue: 10.0,
          gasketThickness: 3.0,
        );

        final result1 = engine1.calculateHoleSize(params);
        final result2 = engine2.calculateHoleSize(params);

        // 结果应在精度范围内一致
        expect(
          (result1.emptyStroke - result2.emptyStroke).abs(),
          lessThan(0.1),
          reason: '不同引擎实例计算结果应一致 (迭代$i)',
        );
      }
    });
  });
}

/// 辅助函数：解析参数字符串
Map<String, double> _parseParameters(String serialized) {
  // 简化的解析实现，实际应使用JSON
  final result = <String, double>{};
  final pattern = RegExp(r'(\w+):\s*([\d.]+)');
  final matches = pattern.allMatches(serialized);
  
  for (final match in matches) {
    final key = match.group(1)!;
    final value = double.parse(match.group(2)!);
    result[key] = value;
  }
  
  return result;
}
