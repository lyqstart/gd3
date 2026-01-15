import 'package:flutter_test/flutter_test.dart';
import 'package:pipeline_calculation_app/services/calculation_engine.dart';
import 'package:pipeline_calculation_app/models/calculation_parameters.dart';
import 'package:pipeline_calculation_app/models/enums.dart';
import 'dart:math' as math;

/// 属性测试生成器 - 管道参数生成器
class PipeParameterGenerator {
  static final _random = math.Random();

  /// 生成有效的开孔参数
  static HoleParameters generateValidHoleParameters() {
    final outerDiameter = 50.0 + _random.nextDouble() * 500.0; // 50-550mm
    final innerDiameter = outerDiameter * (0.6 + _random.nextDouble() * 0.3); // 60-90%
    final cutterOuterDiameter = 10.0 + _random.nextDouble() * 30.0;
    final cutterInnerDiameter = cutterOuterDiameter * (0.5 + _random.nextDouble() * 0.4); // 50-90%
    
    return HoleParameters(
      outerDiameter: outerDiameter,
      innerDiameter: innerDiameter,
      cutterOuterDiameter: cutterOuterDiameter,
      cutterInnerDiameter: cutterInnerDiameter,
      aValue: _random.nextDouble() * 100.0,
      bValue: _random.nextDouble() * 50.0,
      rValue: _random.nextDouble() * 20.0,
      initialValue: _random.nextDouble() * 10.0,
      gasketThickness: 1.0 + _random.nextDouble() * 5.0,
    );
  }

  /// 生成有效的手动开孔参数
  static ManualHoleParameters generateValidManualHoleParameters() {
    final tValue = 10.0 + _random.nextDouble() * 30.0;
    final wValue = tValue * (0.3 + _random.nextDouble() * 0.6); // 确保T > W
    
    return ManualHoleParameters(
      lValue: 50.0 + _random.nextDouble() * 100.0,
      jValue: 20.0 + _random.nextDouble() * 50.0,
      pValue: 10.0 + _random.nextDouble() * 40.0,
      tValue: tValue,
      wValue: wValue,
    );
  }

  /// 生成有效的封堵参数
  static SealingParameters generateValidSealingParameters() {
    return SealingParameters(
      rValue: 10.0 + _random.nextDouble() * 30.0,
      bValue: 20.0 + _random.nextDouble() * 50.0,
      dValue: 50.0 + _random.nextDouble() * 100.0,
      eValue: 80.0 + _random.nextDouble() * 120.0, // 确保E值为正
      gasketThickness: 1.0 + _random.nextDouble() * 5.0,
      initialValue: _random.nextDouble() * 10.0,
    );
  }

  /// 生成有效的下塞堵参数
  static PlugParameters generateValidPlugParameters() {
    final tValue = 10.0 + _random.nextDouble() * 30.0;
    final wValue = tValue * (0.3 + _random.nextDouble() * 0.6); // 确保T > W
    
    return PlugParameters(
      mValue: 80.0 + _random.nextDouble() * 100.0,
      kValue: 40.0 + _random.nextDouble() * 80.0,
      nValue: 20.0 + _random.nextDouble() * 60.0,
      tValue: tValue,
      wValue: wValue,
    );
  }

  /// 生成有效的下塞柄参数
  static StemParameters generateValidStemParameters() {
    return StemParameters(
      fValue: 50.0 + _random.nextDouble() * 80.0,
      gValue: 40.0 + _random.nextDouble() * 60.0,
      hValue: 30.0 + _random.nextDouble() * 50.0,
      gasketThickness: 1.0 + _random.nextDouble() * 5.0,
      initialValue: _random.nextDouble() * 10.0,
    );
  }
}

void main() {
  group('计算引擎属性测试', () {
    late PrecisionCalculationEngine engine;

    setUp(() {
      engine = PrecisionCalculationEngine();
    });

    group('属性 1: 数学公式计算正确性', () {
      test('开孔计算公式正确性 - 100次随机测试', () {
        // **功能: pipeline-calculation-app, 属性 1: 数学公式计算正确性**
        // **验证需求: 1.1, 1.4, 1.5, 1.6, 2.1, 2.2, 2.3, 3.1, 3.2, 4.1, 4.2, 4.3, 5.1**
        
        for (int i = 0; i < 100; i++) {
          final params = PipeParameterGenerator.generateValidHoleParameters();
          final result = engine.calculateHoleSize(params);

          // 验证空行程公式: S空 = A + B + 初始值 + 垫片厚度
          final expectedEmptyStroke = params.aValue + params.bValue + 
                                     params.initialValue + params.gasketThickness;
          expect(
            (result.emptyStroke - expectedEmptyStroke).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '空行程计算公式验证失败，迭代 $i',
          );

          // 验证管道壁厚区域计算
          final pipeWallArea = math.sqrt(
            params.outerDiameter * params.outerDiameter - 
            params.innerDiameter * params.innerDiameter
          );

          // 验证筒刀切削距离公式: C1 = √(管外径² - 管内径²) - 筒刀外径
          final expectedCuttingDistance = pipeWallArea - params.cutterOuterDiameter;
          expect(
            (result.cuttingDistance - expectedCuttingDistance).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '筒刀切削距离计算公式验证失败，迭代 $i',
          );

          // 验证掉板弦高公式: C2 = √(管外径² - 管内径²) - 筒刀内径
          final expectedChordHeight = pipeWallArea - params.cutterInnerDiameter;
          expect(
            (result.chordHeight - expectedChordHeight).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '掉板弦高计算公式验证失败，迭代 $i',
          );

          // 验证切削尺寸公式: C = R + C1
          final expectedCuttingSize = params.rValue + result.cuttingDistance;
          expect(
            (result.cuttingSize - expectedCuttingSize).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '切削尺寸计算公式验证失败，迭代 $i',
          );

          // 验证开孔总行程公式: S总 = S空 + C
          final expectedTotalStroke = result.emptyStroke + result.cuttingSize;
          expect(
            (result.totalStroke - expectedTotalStroke).abs(),
            lessThan(engine.getPrecisionThreshold() * 2), // 允许累积误差
            reason: '开孔总行程计算公式验证失败，迭代 $i',
          );

          // 验证掉板总行程公式: S掉板 = S总 + R + C2
          final expectedPlateStroke = result.totalStroke + params.rValue + result.chordHeight;
          expect(
            (result.plateStroke - expectedPlateStroke).abs(),
            lessThan(engine.getPrecisionThreshold() * 2), // 允许累积误差
            reason: '掉板总行程计算公式验证失败，迭代 $i',
          );
        }
      });

      test('手动开孔计算公式正确性 - 100次随机测试', () {
        // **功能: pipeline-calculation-app, 属性 1: 数学公式计算正确性**
        
        for (int i = 0; i < 100; i++) {
          final params = PipeParameterGenerator.generateValidManualHoleParameters();
          final result = engine.calculateManualHole(params);

          // 验证螺纹咬合尺寸公式: T - W
          final expectedThreadEngagement = params.tValue - params.wValue;
          expect(
            (result.threadEngagement - expectedThreadEngagement).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '螺纹咬合尺寸计算公式验证失败，迭代 $i',
          );

          // 验证空行程公式: L + J + T + W
          final expectedEmptyStroke = params.lValue + params.jValue + 
                                     params.tValue + params.wValue;
          expect(
            (result.emptyStroke - expectedEmptyStroke).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '手动开孔空行程计算公式验证失败，迭代 $i',
          );

          // 验证总行程公式: L + J + T + W + P
          final expectedTotalStroke = params.lValue + params.jValue + 
                                     params.tValue + params.wValue + params.pValue;
          expect(
            (result.totalStroke - expectedTotalStroke).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '手动开孔总行程计算公式验证失败，迭代 $i',
          );
        }
      });

      test('封堵计算公式正确性 - 100次随机测试', () {
        // **功能: pipeline-calculation-app, 属性 1: 数学公式计算正确性**
        
        for (int i = 0; i < 100; i++) {
          final params = PipeParameterGenerator.generateValidSealingParameters();
          final result = engine.calculateSealing(params);

          // 验证导向轮接触管线行程公式: R + B + E + 垫子厚度 + 初始值
          final expectedGuideWheelStroke = params.rValue + params.bValue + 
                                          params.eValue + params.gasketThickness + 
                                          params.initialValue;
          expect(
            (result.guideWheelStroke - expectedGuideWheelStroke).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '导向轮接触管线行程计算公式验证失败，迭代 $i',
          );

          // 验证封堵总行程公式: D + B + E + 垫子厚度 + 初始值
          final expectedTotalStroke = params.dValue + params.bValue + 
                                     params.eValue + params.gasketThickness + 
                                     params.initialValue;
          expect(
            (result.totalStroke - expectedTotalStroke).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '封堵总行程计算公式验证失败，迭代 $i',
          );
        }
      });

      test('下塞堵计算公式正确性 - 100次随机测试', () {
        // **功能: pipeline-calculation-app, 属性 1: 数学公式计算正确性**
        
        for (int i = 0; i < 100; i++) {
          final params = PipeParameterGenerator.generateValidPlugParameters();
          final result = engine.calculatePlug(params);

          // 验证螺纹咬合尺寸公式: T - W
          final expectedThreadEngagement = params.tValue - params.wValue;
          expect(
            (result.threadEngagement - expectedThreadEngagement).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '下塞堵螺纹咬合尺寸计算公式验证失败，迭代 $i',
          );

          // 验证空行程公式: M + K - T + W
          final expectedEmptyStroke = params.mValue + params.kValue - 
                                     params.tValue + params.wValue;
          expect(
            (result.emptyStroke - expectedEmptyStroke).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '下塞堵空行程计算公式验证失败，迭代 $i',
          );

          // 验证总行程公式: M + K + N - T + W
          final expectedTotalStroke = params.mValue + params.kValue + 
                                     params.nValue - params.tValue + params.wValue;
          expect(
            (result.totalStroke - expectedTotalStroke).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '下塞堵总行程计算公式验证失败，迭代 $i',
          );
        }
      });

      test('下塞柄计算公式正确性 - 100次随机测试', () {
        // **功能: pipeline-calculation-app, 属性 2: 平方根运算精度**
        
        for (int i = 0; i < 100; i++) {
          final params = PipeParameterGenerator.generateValidStemParameters();
          final result = engine.calculateStem(params);

          // 验证总行程公式: F + G + H + 垫子厚度 + 初始值
          final expectedTotalStroke = params.fValue + params.gValue + 
                                     params.hValue + params.gasketThickness + 
                                     params.initialValue;
          expect(
            (result.totalStroke - expectedTotalStroke).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '下塞柄总行程计算公式验证失败，迭代 $i',
          );
        }
      });
    });

    group('属性 2: 平方根运算精度', () {
      test('平方根运算工程精度验证 - 50次随机测试', () {
        // **功能: pipeline-calculation-app, 属性 2: 平方根运算精度**
        // **验证需求: 1.2, 1.3, 10.2**
        
        final random = math.Random();
        
        for (int i = 0; i < 50; i++) {
          // 生成随机的管道参数用于平方根计算
          final outerDiameter = 50.0 + random.nextDouble() * 500.0; // 50-550mm
          final innerDiameter = outerDiameter * (0.6 + random.nextDouble() * 0.3); // 60-90%
          
          // 确保外径大于内径
          expect(outerDiameter, greaterThan(innerDiameter));
          
          // 创建开孔参数进行测试
          final params = HoleParameters(
            outerDiameter: outerDiameter,
            innerDiameter: innerDiameter,
            cutterOuterDiameter: 20.0,
            cutterInnerDiameter: 15.0,
            aValue: 50.0,
            bValue: 30.0,
            rValue: 15.0,
            initialValue: 10.0,
            gasketThickness: 3.0,
          );

          // 执行计算，这会触发内部的平方根运算
          final result = engine.calculateHoleSize(params);

          // 验证计算结果的有效性
          expect(result.cuttingDistance.isFinite, isTrue, 
                 reason: '筒刀切削距离计算结果应为有限数值');
          expect(result.chordHeight.isFinite, isTrue, 
                 reason: '掉板弦高计算结果应为有限数值');
          
          // 验证平方根运算不会产生NaN或无穷大
          expect(result.cuttingDistance.isNaN, isFalse, 
                 reason: '平方根运算不应产生NaN');
          expect(result.cuttingDistance.isInfinite, isFalse, 
                 reason: '平方根运算不应产生无穷大');
          expect(result.chordHeight.isNaN, isFalse, 
                 reason: '掉板弦高运算不应产生NaN');
          expect(result.chordHeight.isInfinite, isFalse, 
                 reason: '掉板弦高运算不应产生无穷大');
        }
      });

      test('平方根运算边界条件测试', () {
        // **功能: pipeline-calculation-app, 属性 2: 平方根运算精度**
        
        // 测试接近零的情况
        final nearZeroParams = HoleParameters(
          outerDiameter: 10.001, // 非常接近内径
          innerDiameter: 10.0,
          cutterOuterDiameter: 5.0,
          cutterInnerDiameter: 4.0,
          aValue: 10.0,
          bValue: 10.0,
          rValue: 5.0,
          initialValue: 0.0,
          gasketThickness: 0.0,
        );

        expect(() => engine.calculateHoleSize(nearZeroParams), returnsNormally,
               reason: '接近零的平方根运算应该正常执行');

        // 测试较大数值的平方根运算
        final largeParams = HoleParameters(
          outerDiameter: 1000.0,
          innerDiameter: 900.0,
          cutterOuterDiameter: 50.0,
          cutterInnerDiameter: 40.0,
          aValue: 100.0,
          bValue: 80.0,
          rValue: 50.0,
          initialValue: 20.0,
          gasketThickness: 5.0,
        );

        final result = engine.calculateHoleSize(largeParams);
        
        // 验证大数值计算结果的有效性
        expect(result.cuttingDistance.isFinite, isTrue,
               reason: '大数值平方根运算结果应为有限数值');
        expect(result.cuttingDistance, greaterThan(0),
               reason: '平方根运算结果应为正数');
        expect(result.chordHeight.isFinite, isTrue,
               reason: '大数值掉板弦高运算结果应为有限数值');
        expect(result.chordHeight, greaterThan(0),
               reason: '掉板弦高运算结果应为正数');
      });

      test('平方根运算一致性验证', () {
        // **功能: pipeline-calculation-app, 属性 2: 平方根运算精度**
        
        // 使用相同参数多次计算，验证结果一致性
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

        final results = <double>[];
        
        // 执行多次计算
        for (int i = 0; i < 10; i++) {
          final result = engine.calculateHoleSize(params);
          results.add(result.cuttingDistance);
        }

        // 验证所有结果都相同（平方根运算应该是确定性的）
        final firstResult = results.first;
        for (final result in results) {
          expect(
            (result - firstResult).abs(),
            lessThan(1e-15), // 机器精度级别的一致性
            reason: '相同参数的平方根运算结果应该完全一致',
          );
        }
      });
    });

    group('计算结果精度验证', () {
      test('所有计算结果应保持0.1mm精度', () {
        for (int i = 0; i < 50; i++) {
          // 测试开孔计算精度
          final holeParams = PipeParameterGenerator.generateValidHoleParameters();
          final holeResult = engine.calculateHoleSize(holeParams);
          
          expect(_checkPrecision(holeResult.emptyStroke), isTrue, 
                 reason: '开孔空行程精度不符合要求');
          expect(_checkPrecision(holeResult.totalStroke), isTrue, 
                 reason: '开孔总行程精度不符合要求');
          expect(_checkPrecision(holeResult.plateStroke), isTrue, 
                 reason: '掉板总行程精度不符合要求');

          // 测试其他计算类型的精度
          final manualParams = PipeParameterGenerator.generateValidManualHoleParameters();
          final manualResult = engine.calculateManualHole(manualParams);
          
          expect(_checkPrecision(manualResult.totalStroke), isTrue, 
                 reason: '手动开孔总行程精度不符合要求');
        }
      });
    });

    group('边界条件测试', () {
      test('最小有效参数值计算', () {
        // 测试接近最小值的参数
        final minParams = HoleParameters(
          outerDiameter: 10.1, // 略大于内径
          innerDiameter: 10.0,
          cutterOuterDiameter: 5.1, // 略大于内径
          cutterInnerDiameter: 5.0,
          aValue: 0.1,
          bValue: 0.1,
          rValue: 0.1,
          initialValue: 0.0,
          gasketThickness: 0.0,
        );

        expect(() => engine.calculateHoleSize(minParams), returnsNormally);
      });

      test('大数值参数计算', () {
        // 测试较大的参数值
        final largeParams = HoleParameters(
          outerDiameter: 1000.0,
          innerDiameter: 900.0,
          cutterOuterDiameter: 100.0,
          cutterInnerDiameter: 80.0,
          aValue: 500.0,
          bValue: 300.0,
          rValue: 200.0,
          initialValue: 100.0,
          gasketThickness: 50.0,
        );

        final result = engine.calculateHoleSize(largeParams);
        expect(result.totalStroke, greaterThan(0));
        expect(result.totalStroke, lessThan(10000)); // 合理的工程范围
      });
    });
  });
}

/// 检查数值是否符合0.1mm精度要求
bool _checkPrecision(double value) {
  // 检查小数部分是否为0.1的倍数
  final decimal = (value * 10) % 1;
  return decimal.abs() < 1e-10; // 考虑浮点数精度误差
}