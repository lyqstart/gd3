import 'package:flutter_test/flutter_test.dart';
import 'package:pipeline_calculation_app/services/calculation_engine.dart';
import 'package:pipeline_calculation_app/models/calculation_parameters.dart';
import 'dart:math' as math;

void main() {
  group('平方根运算精度测试', () {
    late PrecisionCalculationEngine engine;

    setUp(() {
      engine = PrecisionCalculationEngine();
    });

    test('属性 2: 平方根运算精度验证', () {
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
      }
    });

    test('平方根运算边界条件测试', () {
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
    });
  });
}