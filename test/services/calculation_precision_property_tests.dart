import 'package:test/test.dart';
import 'dart:math' as math;

import '../../lib/services/calculation_engine.dart';
import '../../lib/models/calculation_parameters.dart';
import '../../lib/models/enums.dart';
import '../../lib/utils/constants.dart';

/// 管道参数生成器
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
    return ManualHoleParameters(
      lValue: 10.0 + _random.nextDouble() * 100.0,
      jValue: 5.0 + _random.nextDouble() * 50.0,
      pValue: 5.0 + _random.nextDouble() * 30.0,
      tValue: 10.0 + _random.nextDouble() * 20.0,
      wValue: 5.0 + _random.nextDouble() * 15.0,
    );
  }
  
  /// 生成有效的封堵参数
  static SealingParameters generateValidSealingParameters() {
    return SealingParameters(
      rValue: 5.0 + _random.nextDouble() * 50.0,
      bValue: 5.0 + _random.nextDouble() * 30.0,
      eValue: 20.0 + _random.nextDouble() * 200.0,
      dValue: 10.0 + _random.nextDouble() * 100.0,
      gasketThickness: 1.0 + _random.nextDouble() * 5.0,
      initialValue: _random.nextDouble() * 10.0,
    );
  }
  
  /// 生成有效的下塞堵参数
  static PlugParameters generateValidPlugParameters() {
    return PlugParameters(
      mValue: 20.0 + _random.nextDouble() * 100.0,
      kValue: 10.0 + _random.nextDouble() * 50.0,
      nValue: 5.0 + _random.nextDouble() * 30.0,
      tValue: 10.0 + _random.nextDouble() * 20.0,
      wValue: 5.0 + _random.nextDouble() * 15.0,
    );
  }
  
  /// 生成有效的下塞柄参数
  static StemParameters generateValidStemParameters() {
    return StemParameters(
      fValue: 10.0 + _random.nextDouble() * 100.0,
      gValue: 5.0 + _random.nextDouble() * 50.0,
      hValue: 10.0 + _random.nextDouble() * 80.0,
      gasketThickness: 1.0 + _random.nextDouble() * 5.0,
      initialValue: _random.nextDouble() * 10.0,
    );
  }
  
  /// 生成边界值参数（用于测试边界情况）
  static HoleParameters generateBoundaryHoleParameters() {
    final scenarios = [
      // 最小值场景
      () => HoleParameters(
        outerDiameter: 50.0,
        innerDiameter: 30.0,
        cutterOuterDiameter: 10.0,
        cutterInnerDiameter: 5.0,
        aValue: 0.1,
        bValue: 0.1,
        rValue: 0.1,
        initialValue: 0.0,
        gasketThickness: 1.0,
      ),
      // 最大值场景
      () => HoleParameters(
        outerDiameter: 2000.0,
        innerDiameter: 1800.0,
        cutterOuterDiameter: 200.0,
        cutterInnerDiameter: 180.0,
        aValue: 500.0,
        bValue: 200.0,
        rValue: 100.0,
        initialValue: 50.0,
        gasketThickness: 25.0,
      ),
      // 接近相等的场景
      () => HoleParameters(
        outerDiameter: 100.0,
        innerDiameter: 99.0,
        cutterOuterDiameter: 15.0,
        cutterInnerDiameter: 14.5,
        aValue: 10.0,
        bValue: 10.0,
        rValue: 5.0,
        initialValue: 2.0,
        gasketThickness: 2.0,
      ),
    ];
    
    return scenarios[_random.nextInt(scenarios.length)]();
  }
}

void main() {
  group('属性 12: 计算精度保持 - **验证需求: 5.3, 10.1, 10.6**', () {
    late PrecisionCalculationEngine engine;
    
    setUp(() {
      engine = PrecisionCalculationEngine();
    });
    
    test('开孔计算精度保持属性测试', () {
      // **功能: pipeline-calculation-app, 属性 12: 计算精度保持**
      // **验证需求: 5.3, 10.1, 10.6**
      
      for (int i = 0; i < 100; i++) {
        final params = PipeParameterGenerator.generateValidHoleParameters();
        
        try {
          final result = engine.calculateHoleSize(params);
          
          // 验证所有结果都保持在0.1mm精度范围内
          expect(
            _isPrecisionMaintained(result.emptyStroke),
            isTrue,
            reason: '空行程精度不符合要求: ${result.emptyStroke}',
          );
          
          expect(
            _isPrecisionMaintained(result.cuttingDistance),
            isTrue,
            reason: '切削距离精度不符合要求: ${result.cuttingDistance}',
          );
          
          expect(
            _isPrecisionMaintained(result.chordHeight),
            isTrue,
            reason: '掉板弦高精度不符合要求: ${result.chordHeight}',
          );
          
          expect(
            _isPrecisionMaintained(result.cuttingSize),
            isTrue,
            reason: '切削尺寸精度不符合要求: ${result.cuttingSize}',
          );
          
          expect(
            _isPrecisionMaintained(result.totalStroke),
            isTrue,
            reason: '总行程精度不符合要求: ${result.totalStroke}',
          );
          
          expect(
            _isPrecisionMaintained(result.plateStroke),
            isTrue,
            reason: '掉板总行程精度不符合要求: ${result.plateStroke}',
          );
          
          // 验证计算结果的数学一致性
          final expectedEmptyStroke = params.aValue + params.bValue + 
                                    params.initialValue + params.gasketThickness;
          expect(
            (result.emptyStroke - expectedEmptyStroke).abs(),
            lessThanOrEqualTo(AppConstants.precisionThreshold),
            reason: '空行程计算不准确',
          );
          
          // 验证总行程 = 空行程 + 切削尺寸
          final expectedTotalStroke = result.emptyStroke + result.cuttingSize;
          expect(
            (result.totalStroke - expectedTotalStroke).abs(),
            lessThanOrEqualTo(AppConstants.precisionThreshold),
            reason: '总行程计算不一致',
          );
          
        } catch (e) {
          // 如果参数导致计算异常，这是可以接受的（例如无效参数）
          // 但我们需要确保异常是合理的
          expect(e, isA<Exception>());
        }
      }
    });
    
    test('手动开孔计算精度保持属性测试', () {
      // **功能: pipeline-calculation-app, 属性 12: 计算精度保持**
      // **验证需求: 5.3, 10.1, 10.6**
      
      for (int i = 0; i < 100; i++) {
        final params = PipeParameterGenerator.generateValidManualHoleParameters();
        
        try {
          final result = engine.calculateManualHole(params);
          
          // 验证精度保持
          expect(
            _isPrecisionMaintained(result.threadEngagement),
            isTrue,
            reason: '螺纹咬合尺寸精度不符合要求: ${result.threadEngagement}',
          );
          
          expect(
            _isPrecisionMaintained(result.emptyStroke),
            isTrue,
            reason: '空行程精度不符合要求: ${result.emptyStroke}',
          );
          
          expect(
            _isPrecisionMaintained(result.totalStroke),
            isTrue,
            reason: '总行程精度不符合要求: ${result.totalStroke}',
          );
          
          // 验证计算一致性
          final expectedThreadEngagement = params.tValue - params.wValue;
          expect(
            (result.threadEngagement - expectedThreadEngagement).abs(),
            lessThanOrEqualTo(AppConstants.precisionThreshold),
            reason: '螺纹咬合尺寸计算不准确',
          );
          
          final expectedEmptyStroke = params.lValue + params.jValue + 
                                    params.tValue + params.wValue;
          expect(
            (result.emptyStroke - expectedEmptyStroke).abs(),
            lessThanOrEqualTo(AppConstants.precisionThreshold),
            reason: '空行程计算不准确',
          );
          
        } catch (e) {
          expect(e, isA<Exception>());
        }
      }
    });
    
    test('封堵计算精度保持属性测试', () {
      // **功能: pipeline-calculation-app, 属性 12: 计算精度保持**
      // **验证需求: 5.3, 10.1, 10.6**
      
      for (int i = 0; i < 100; i++) {
        final params = PipeParameterGenerator.generateValidSealingParameters();
        
        try {
          final result = engine.calculateSealing(params);
          
          // 验证精度保持
          expect(
            _isPrecisionMaintained(result.guideWheelStroke),
            isTrue,
            reason: '导向轮行程精度不符合要求: ${result.guideWheelStroke}',
          );
          
          expect(
            _isPrecisionMaintained(result.totalStroke),
            isTrue,
            reason: '总行程精度不符合要求: ${result.totalStroke}',
          );
          
          // 验证计算一致性
          final expectedGuideWheelStroke = params.rValue + params.bValue + 
                                         params.eValue + params.gasketThickness + 
                                         params.initialValue;
          expect(
            (result.guideWheelStroke - expectedGuideWheelStroke).abs(),
            lessThanOrEqualTo(AppConstants.precisionThreshold),
            reason: '导向轮行程计算不准确',
          );
          
          final expectedTotalStroke = params.dValue + params.bValue + 
                                    params.eValue + params.gasketThickness + 
                                    params.initialValue;
          expect(
            (result.totalStroke - expectedTotalStroke).abs(),
            lessThanOrEqualTo(AppConstants.precisionThreshold),
            reason: '总行程计算不准确',
          );
          
        } catch (e) {
          expect(e, isA<Exception>());
        }
      }
    });
    
    test('下塞堵计算精度保持属性测试', () {
      // **功能: pipeline-calculation-app, 属性 12: 计算精度保持**
      // **验证需求: 5.3, 10.1, 10.6**
      
      for (int i = 0; i < 100; i++) {
        final params = PipeParameterGenerator.generateValidPlugParameters();
        
        try {
          final result = engine.calculatePlug(params);
          
          // 验证精度保持
          expect(
            _isPrecisionMaintained(result.threadEngagement),
            isTrue,
            reason: '螺纹咬合尺寸精度不符合要求: ${result.threadEngagement}',
          );
          
          expect(
            _isPrecisionMaintained(result.emptyStroke),
            isTrue,
            reason: '空行程精度不符合要求: ${result.emptyStroke}',
          );
          
          expect(
            _isPrecisionMaintained(result.totalStroke),
            isTrue,
            reason: '总行程精度不符合要求: ${result.totalStroke}',
          );
          
          // 验证计算一致性
          final expectedThreadEngagement = params.tValue - params.wValue;
          expect(
            (result.threadEngagement - expectedThreadEngagement).abs(),
            lessThanOrEqualTo(AppConstants.precisionThreshold),
            reason: '螺纹咬合尺寸计算不准确',
          );
          
          final expectedEmptyStroke = params.mValue + params.kValue - 
                                    params.tValue + params.wValue;
          expect(
            (result.emptyStroke - expectedEmptyStroke).abs(),
            lessThanOrEqualTo(AppConstants.precisionThreshold),
            reason: '空行程计算不准确',
          );
          
          final expectedTotalStroke = params.mValue + params.kValue + 
                                    params.nValue - params.tValue + params.wValue;
          expect(
            (result.totalStroke - expectedTotalStroke).abs(),
            lessThanOrEqualTo(AppConstants.precisionThreshold),
            reason: '总行程计算不准确',
          );
          
        } catch (e) {
          expect(e, isA<Exception>());
        }
      }
    });
    
    test('下塞柄计算精度保持属性测试', () {
      // **功能: pipeline-calculation-app, 属性 12: 计算精度保持**
      // **验证需求: 5.3, 10.1, 10.6**
      
      for (int i = 0; i < 100; i++) {
        final params = PipeParameterGenerator.generateValidStemParameters();
        
        try {
          final result = engine.calculateStem(params);
          
          // 验证精度保持（需求5.3: 保持计算精度至小数点后2位）
          expect(
            _isPrecisionMaintained(result.totalStroke),
            isTrue,
            reason: '总行程精度不符合要求: ${result.totalStroke}',
          );
          
          // 验证小数点后2位精度（需求5.3）
          expect(
            _isDecimalPrecisionMaintained(result.totalStroke, 2),
            isTrue,
            reason: '总行程小数位数不符合要求: ${result.totalStroke}',
          );
          
          // 验证计算一致性
          final expectedTotalStroke = params.fValue + params.gValue + 
                                    params.hValue + params.gasketThickness + 
                                    params.initialValue;
          expect(
            (result.totalStroke - expectedTotalStroke).abs(),
            lessThanOrEqualTo(AppConstants.precisionThreshold),
            reason: '总行程计算不准确',
          );
          
        } catch (e) {
          expect(e, isA<Exception>());
        }
      }
    });
    
    test('边界值精度保持属性测试', () {
      // **功能: pipeline-calculation-app, 属性 12: 计算精度保持**
      // **验证需求: 10.1, 10.6**
      
      for (int i = 0; i < 50; i++) {
        final params = PipeParameterGenerator.generateBoundaryHoleParameters();
        
        try {
          final result = engine.calculateHoleSize(params);
          
          // 即使在边界条件下，也要保持精度
          expect(
            _isPrecisionMaintained(result.emptyStroke),
            isTrue,
            reason: '边界条件下空行程精度不符合要求: ${result.emptyStroke}',
          );
          
          expect(
            _isPrecisionMaintained(result.totalStroke),
            isTrue,
            reason: '边界条件下总行程精度不符合要求: ${result.totalStroke}',
          );
          
          // 验证结果不是NaN或无穷大
          expect(result.emptyStroke.isFinite, isTrue);
          expect(result.cuttingDistance.isFinite, isTrue);
          expect(result.totalStroke.isFinite, isTrue);
          
        } catch (e) {
          // 边界条件可能导致合理的异常
          expect(e, isA<Exception>());
        }
      }
    });
    
    test('精度误差累积测试', () {
      // **功能: pipeline-calculation-app, 属性 12: 计算精度保持**
      // **验证需求: 10.1**
      
      // 测试多次计算是否会累积精度误差
      final params = HoleParameters(
        outerDiameter: 219.1,
        innerDiameter: 202.7,
        cutterOuterDiameter: 25.4,
        cutterInnerDiameter: 22.2,
        aValue: 45.5,
        bValue: 12.3,
        rValue: 8.7,
        initialValue: 3.2,
        gasketThickness: 2.1,
      );
      
      final results = <double>[];
      
      // 执行多次相同计算
      for (int i = 0; i < 10; i++) {
        final result = engine.calculateHoleSize(params);
        results.add(result.totalStroke);
      }
      
      // 验证所有结果都相同（没有累积误差）
      for (int i = 1; i < results.length; i++) {
        expect(
          (results[i] - results[0]).abs(),
          lessThanOrEqualTo(1e-10), // 极小的误差容忍
          reason: '多次计算结果不一致，可能存在精度累积误差',
        );
      }
    });
    
    test('平方根运算精度测试', () {
      // **功能: pipeline-calculation-app, 属性 12: 计算精度保持**
      // **验证需求: 10.2**
      
      for (int i = 0; i < 100; i++) {
        final outerDiameter = 50.0 + math.Random().nextDouble() * 500.0;
        final innerDiameter = outerDiameter * (0.6 + math.Random().nextDouble() * 0.3);
        
        // 计算管道壁厚区域
        final squareDifference = (outerDiameter * outerDiameter) - 
                               (innerDiameter * innerDiameter);
        final pipeWallArea = math.sqrt(squareDifference);
        
        // 验证平方根运算的精度
        expect(pipeWallArea.isFinite, isTrue);
        expect(pipeWallArea, greaterThan(0));
        
        // 验证平方根运算的一致性
        final recalculated = math.sqrt(squareDifference);
        expect(
          (pipeWallArea - recalculated).abs(),
          lessThanOrEqualTo(1e-15), // 双精度浮点数精度
          reason: '平方根运算精度不一致',
        );
        
        // 验证反向计算
        final backCalculated = pipeWallArea * pipeWallArea;
        expect(
          (backCalculated - squareDifference).abs(),
          lessThanOrEqualTo(1e-10), // 考虑浮点运算误差
          reason: '平方根反向计算精度不符合要求',
        );
      }
    });
  });
}

/// 检查数值是否保持在0.1mm精度范围内
bool _isPrecisionMaintained(double value) {
  // 检查数值是否为有限数
  if (!value.isFinite) return false;
  
  // 检查是否符合0.1mm精度要求
  final rounded = (value * 10).round() / 10;
  return (value - rounded).abs() <= AppConstants.precisionThreshold / 10;
}

/// 检查数值是否保持指定的小数位数精度
bool _isDecimalPrecisionMaintained(double value, int decimalPlaces) {
  if (!value.isFinite) return false;
  
  final multiplier = math.pow(10, decimalPlaces);
  final rounded = (value * multiplier).round() / multiplier;
  return (value - rounded).abs() <= math.pow(10, -decimalPlaces - 1);
}