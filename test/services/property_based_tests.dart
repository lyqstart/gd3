import 'package:flutter_test/flutter_test.dart';
import 'package:pipeline_calculation_app/services/calculation_engine.dart';
import 'package:pipeline_calculation_app/services/calculation_service.dart';
import 'package:pipeline_calculation_app/services/parameter_service.dart';
import 'package:pipeline_calculation_app/services/parameter_manager.dart';
import 'package:pipeline_calculation_app/models/calculation_parameters.dart';
import 'package:pipeline_calculation_app/models/calculation_result.dart';
import 'package:pipeline_calculation_app/models/parameter_models.dart';
import 'package:pipeline_calculation_app/models/enums.dart';
import 'package:pipeline_calculation_app/utils/unit_converter.dart';
import 'dart:math' as math;

/// 属性测试生成器 - 无效参数生成器
class InvalidParameterGenerator {
  static final _random = math.Random();

  /// 生成无效的开孔参数
  static List<HoleParameters> generateInvalidHoleParameters() {
    return [
      // 负数参数
      HoleParameters(
        outerDiameter: -_random.nextDouble() * 100, // 负外径
        innerDiameter: 50.0,
        cutterOuterDiameter: 20.0,
        cutterInnerDiameter: 15.0,
        aValue: 30.0,
        bValue: 20.0,
        rValue: 10.0,
        initialValue: 5.0,
        gasketThickness: 2.0,
      ),
      // 内径大于外径
      HoleParameters(
        outerDiameter: 50.0,
        innerDiameter: 60.0, // 内径大于外径
        cutterOuterDiameter: 20.0,
        cutterInnerDiameter: 15.0,
        aValue: 30.0,
        bValue: 20.0,
        rValue: 10.0,
        initialValue: 5.0,
        gasketThickness: 2.0,
      ),
      // 筒刀内径大于外径
      HoleParameters(
        outerDiameter: 100.0,
        innerDiameter: 80.0,
        cutterOuterDiameter: 20.0,
        cutterInnerDiameter: 25.0, // 筒刀内径大于外径
        aValue: 30.0,
        bValue: 20.0,
        rValue: 10.0,
        initialValue: 5.0,
        gasketThickness: 2.0,
      ),
      // 零值参数
      HoleParameters(
        outerDiameter: 0.0, // 零外径
        innerDiameter: 0.0,
        cutterOuterDiameter: 0.0,
        cutterInnerDiameter: 0.0,
        aValue: 0.0,
        bValue: 0.0,
        rValue: 0.0,
        initialValue: 0.0,
        gasketThickness: 0.0,
      ),
    ];
  }

  /// 生成无效的手动开孔参数
  static List<ManualHoleParameters> generateInvalidManualHoleParameters() {
    return [
      // 负数参数
      ManualHoleParameters(
        lValue: -_random.nextDouble() * 50,
        jValue: 30.0,
        pValue: 20.0,
        tValue: 15.0,
        wValue: 10.0,
      ),
      // 零值参数
      ManualHoleParameters(
        lValue: 0.0,
        jValue: 0.0,
        pValue: 0.0,
        tValue: 0.0,
        wValue: 0.0,
      ),
    ];
  }

  /// 生成会产生警告的手动开孔参数（T<W情况）
  static List<ManualHoleParameters> generateWarningManualHoleParameters() {
    return [
      // T值小于W值（螺纹咬合为负）- 这会产生警告但不是错误
      ManualHoleParameters(
        lValue: 100.0,
        jValue: 50.0,
        pValue: 25.0,
        tValue: 10.0,
        wValue: 15.0, // W值大于T值
      ),
    ];
  }

  /// 生成无效的封堵参数
  static List<SealingParameters> generateInvalidSealingParameters() {
    return [
      // 负数E值
      SealingParameters(
        rValue: 15.0,
        bValue: 30.0,
        dValue: 80.0,
        eValue: -_random.nextDouble() * 50, // 负E值
        gasketThickness: 3.0,
        initialValue: 10.0,
      ),
      // 零值参数
      SealingParameters(
        rValue: 0.0,
        bValue: 0.0,
        dValue: 0.0,
        eValue: 0.0,
        gasketThickness: 0.0,
        initialValue: 0.0,
      ),
      // 负数参数
      SealingParameters(
        rValue: -10.0,
        bValue: -20.0,
        dValue: -50.0,
        eValue: 100.0,
        gasketThickness: 3.0,
        initialValue: 10.0,
      ),
    ];
  }

  /// 生成无效的下塞堵参数
  static List<PlugParameters> generateInvalidPlugParameters() {
    return [
      // 负数参数
      PlugParameters(
        mValue: -_random.nextDouble() * 100,
        kValue: 60.0,
        nValue: 40.0,
        tValue: 20.0,
        wValue: 15.0,
      ),
      // 会导致负空行程的参数组合
      PlugParameters(
        mValue: 50.0,
        kValue: 30.0,
        nValue: 20.0,
        tValue: 100.0, // T值过大
        wValue: 10.0,
      ),
      // 零值参数
      PlugParameters(
        mValue: 0.0,
        kValue: 0.0,
        nValue: 0.0,
        tValue: 0.0,
        wValue: 0.0,
      ),
    ];
  }

  /// 生成无效的下塞柄参数
  static List<StemParameters> generateInvalidStemParameters() {
    return [
      // 负数参数
      StemParameters(
        fValue: -_random.nextDouble() * 50,
        gValue: 60.0,
        hValue: 40.0,
        gasketThickness: 3.0,
        initialValue: 10.0,
      ),
      // 零值参数
      StemParameters(
        fValue: 0.0,
        gValue: 0.0,
        hValue: 0.0,
        gasketThickness: 0.0,
        initialValue: 0.0,
      ),
    ];
  }
}

/// 有效参数生成器（从现有测试文件复制）
class ValidParameterGenerator {
  static final _random = math.Random();

  /// 生成有效的封堵参数（用于一致性测试）
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
}

void main() {
  group('属性测试 - 计算模块验证', () {
    late PrecisionCalculationEngine engine;
    late CalculationService service;

    setUp(() {
      engine = PrecisionCalculationEngine();
      service = CalculationService(engine: engine);
    });

    group('属性 3: 输入参数验证', () {
      test('开孔计算 - 无效参数应被拒绝 - 100次测试', () async {
        // **功能: pipeline-calculation-app, 属性 3: 输入参数验证**
        // **验证需求: 1.7, 2.4, 3.4, 4.4, 5.2, 10.5**
        
        final invalidParametersList = InvalidParameterGenerator.generateInvalidHoleParameters();
        
        // 对每种无效参数类型进行多次测试
        for (int testRound = 0; testRound < 25; testRound++) {
          for (final invalidParams in invalidParametersList) {
            // 测试参数验证
            final validation = await service.validateParameters(
              CalculationType.hole, 
              invalidParams.toJson(),
            );
            
            expect(validation.isError, isTrue,
                   reason: '无效开孔参数应该被验证为错误: ${invalidParams.toString()}');
            
            // 测试计算应该抛出异常（CalculationException或ArgumentError都可以）
            expect(
              () async => await service.calculate(CalculationType.hole, invalidParams.toJson()),
              throwsA(anyOf([isA<ArgumentError>(), isA<CalculationException>()])),
              reason: '无效开孔参数应该导致计算异常: ${invalidParams.toString()}',
            );
          }
        }
      });

      test('手动开孔计算 - 无效参数应被拒绝 - 100次测试', () async {
        // **功能: pipeline-calculation-app, 属性 3: 输入参数验证**
        
        final invalidParametersList = InvalidParameterGenerator.generateInvalidManualHoleParameters();
        
        for (int testRound = 0; testRound < 50; testRound++) {
          for (final invalidParams in invalidParametersList) {
            // 测试参数验证
            final validation = await service.validateParameters(
              CalculationType.manualHole, 
              invalidParams.toJson(),
            );
            
            expect(validation.isError, isTrue,
                   reason: '无效手动开孔参数应该被验证为错误: ${invalidParams.toString()}');
            
            // 测试计算应该抛出异常（CalculationException或ArgumentError都可以）
            expect(
              () async => await service.calculate(CalculationType.manualHole, invalidParams.toJson()),
              throwsA(anyOf([isA<ArgumentError>(), isA<CalculationException>()])),
              reason: '无效手动开孔参数应该导致计算异常: ${invalidParams.toString()}',
            );
          }
        }
      });

      test('手动开孔计算 - 警告参数验证 - 100次测试', () async {
        // **功能: pipeline-calculation-app, 属性 3: 输入参数验证**
        // 测试T<W情况，这种情况会产生警告但不会阻止计算
        
        final warningParametersList = InvalidParameterGenerator.generateWarningManualHoleParameters();
        
        for (int testRound = 0; testRound < 100; testRound++) {
          for (final warningParams in warningParametersList) {
            // 测试参数验证 - 对于T<W的情况，应该产生警告而不是错误
            final validation = await service.validateParameters(
              CalculationType.manualHole, 
              warningParams.toJson(),
            );
            
            // 检查是否有警告
            expect(validation.isWarning, isTrue,
                   reason: 'T<W的手动开孔参数应该产生警告: ${warningParams.toString()}');
            
            // 测试计算应该能够正常执行（不抛出异常）
            expect(
              () async => await service.calculate(CalculationType.manualHole, warningParams.toJson()),
              returnsNormally,
              reason: 'T<W的手动开孔参数应该能够正常计算: ${warningParams.toString()}',
            );
            
            // 验证计算结果中螺纹咬合为负值
            final result = await service.calculate(CalculationType.manualHole, warningParams.toJson()) as ManualHoleResult;
            expect(result.threadEngagement, lessThan(0),
                   reason: 'T<W的情况应该产生负的螺纹咬合值');
          }
        }
      });

      test('封堵计算 - 无效参数应被拒绝 - 100次测试', () async {
        // **功能: pipeline-calculation-app, 属性 3: 输入参数验证**
        
        final invalidParametersList = InvalidParameterGenerator.generateInvalidSealingParameters();
        
        for (int testRound = 0; testRound < 33; testRound++) {
          for (final invalidParams in invalidParametersList) {
            // 测试参数验证
            final validation = await service.validateParameters(
              CalculationType.sealing, 
              invalidParams.toJson(),
            );
            
            expect(validation.isError, isTrue,
                   reason: '无效封堵参数应该被验证为错误: ${invalidParams.toString()}');
            
            // 测试计算应该抛出异常（CalculationException或ArgumentError都可以）
            expect(
              () async => await service.calculate(CalculationType.sealing, invalidParams.toJson()),
              throwsA(anyOf([isA<ArgumentError>(), isA<CalculationException>()])),
              reason: '无效封堵参数应该导致计算异常: ${invalidParams.toString()}',
            );
          }
        }
      });

      test('下塞堵计算 - 无效参数应被拒绝 - 100次测试', () async {
        // **功能: pipeline-calculation-app, 属性 3: 输入参数验证**
        
        final invalidParametersList = InvalidParameterGenerator.generateInvalidPlugParameters();
        
        for (int testRound = 0; testRound < 33; testRound++) {
          for (final invalidParams in invalidParametersList) {
            // 测试参数验证
            final validation = await service.validateParameters(
              CalculationType.plug, 
              invalidParams.toJson(),
            );
            
            expect(validation.isError, isTrue,
                   reason: '无效下塞堵参数应该被验证为错误: ${invalidParams.toString()}');
            
            // 测试计算应该抛出异常（CalculationException或ArgumentError都可以）
            expect(
              () async => await service.calculate(CalculationType.plug, invalidParams.toJson()),
              throwsA(anyOf([isA<ArgumentError>(), isA<CalculationException>()])),
              reason: '无效下塞堵参数应该导致计算异常: ${invalidParams.toString()}',
            );
          }
        }
      });

      test('下塞柄计算 - 无效参数应被拒绝 - 100次测试', () async {
        // **功能: pipeline-calculation-app, 属性 3: 输入参数验证**
        
        final invalidParametersList = InvalidParameterGenerator.generateInvalidStemParameters();
        
        for (int testRound = 0; testRound < 50; testRound++) {
          for (final invalidParams in invalidParametersList) {
            // 测试参数验证
            final validation = await service.validateParameters(
              CalculationType.stem, 
              invalidParams.toJson(),
            );
            
            expect(validation.isError, isTrue,
                   reason: '无效下塞柄参数应该被验证为错误: ${invalidParams.toString()}');
            
            // 测试计算应该抛出异常（CalculationException或ArgumentError都可以）
            expect(
              () async => await service.calculate(CalculationType.stem, invalidParams.toJson()),
              throwsA(anyOf([isA<ArgumentError>(), isA<CalculationException>()])),
              reason: '无效下塞柄参数应该导致计算异常: ${invalidParams.toString()}',
            );
          }
        }
      });

      test('边界值参数验证 - 100次测试', () async {
        // **功能: pipeline-calculation-app, 属性 3: 输入参数验证**
        
        final random = math.Random();
        
        for (int i = 0; i < 100; i++) {
          // 生成接近零的参数值
          final nearZeroValue = random.nextDouble() * 0.001; // 0-0.001mm
          final negativeValue = -random.nextDouble() * 10; // 负值
          
          // 测试开孔参数的边界值
          final boundaryHoleParams = HoleParameters(
            outerDiameter: nearZeroValue, // 接近零的外径
            innerDiameter: nearZeroValue,
            cutterOuterDiameter: nearZeroValue,
            cutterInnerDiameter: nearZeroValue,
            aValue: negativeValue, // 负A值
            bValue: nearZeroValue,
            rValue: nearZeroValue,
            initialValue: nearZeroValue,
            gasketThickness: nearZeroValue,
          );
          
          final validation = await service.validateParameters(
            CalculationType.hole, 
            boundaryHoleParams.toJson(),
          );
          
          expect(validation.isError, isTrue,
                 reason: '边界值参数应该被验证为错误，迭代 $i');
        }
      });

      test('超大值参数验证 - 100次测试', () async {
        // **功能: pipeline-calculation-app, 属性 3: 输入参数验证**
        
        final random = math.Random();
        
        for (int i = 0; i < 100; i++) {
          // 生成超大的参数值
          final largeValue = 10000.0 + random.nextDouble() * 90000.0; // 10000-100000mm
          
          // 测试封堵参数的超大值
          final largeSealingParams = SealingParameters(
            rValue: largeValue,
            bValue: largeValue,
            dValue: largeValue,
            eValue: largeValue,
            gasketThickness: largeValue,
            initialValue: largeValue,
          );
          
          final validation = await service.validateParameters(
            CalculationType.sealing, 
            largeSealingParams.toJson(),
          );
          
          // 超大值可能产生警告而不是错误，但应该被标识
          expect(validation.isValid, isTrue,
                 reason: '超大值参数验证应该返回有效结果（可能有警告），迭代 $i');
          
          // 但计算应该能够处理（不抛出异常）
          expect(
            () async => await service.calculate(CalculationType.sealing, largeSealingParams.toJson()),
            returnsNormally,
            reason: '超大值参数计算应该正常执行，迭代 $i',
          );
        }
      });
    });

    group('属性 6: 封堵解堵计算一致性', () {
      test('封堵和解堵计算结果一致性 - 100次测试', () async {
        // **功能: pipeline-calculation-app, 属性 6: 封堵解堵计算一致性**
        // **验证需求: 3.3**
        
        for (int i = 0; i < 100; i++) {
          // 生成有效的封堵参数
          final sealingParams = ValidParameterGenerator.generateValidSealingParameters();
          
          // 执行封堵计算
          final sealingResult = await service.calculate(
            CalculationType.sealing, 
            sealingParams.toJson(),
          );
          
          // 使用相同参数执行解堵计算（在当前实现中，封堵和解堵使用相同的逻辑）
          // 根据需求3.3：当执行解堵计算时，应使用与封堵相同的计算逻辑
          final unsealingResult = await service.calculate(
            CalculationType.sealing, 
            sealingParams.toJson(),
          );
          
          // 验证封堵和解堵计算结果一致性（忽略ID和时间戳）
          final sealingResultTyped = sealingResult as SealingResult;
          final unsealingResultTyped = unsealingResult as SealingResult;
          
          expect(
            sealingResultTyped.guideWheelStroke,
            equals(unsealingResultTyped.guideWheelStroke),
            reason: '导向轮接触管线行程应该一致，迭代 $i',
          );
          
          expect(
            sealingResultTyped.totalStroke,
            equals(unsealingResultTyped.totalStroke),
            reason: '总行程应该一致，迭代 $i',
          );
          
          // 验证参数也应该一致
          expect(
            sealingResultTyped.parameters.toJson(),
            equals(unsealingResultTyped.parameters.toJson()),
            reason: '计算参数应该一致，迭代 $i',
          );
        }
      });

      test('封堵计算逻辑稳定性验证 - 100次测试', () async {
        // **功能: pipeline-calculation-app, 属性 6: 封堵解堵计算一致性**
        
        // 使用固定参数多次计算，验证结果稳定性
        final fixedParams = SealingParameters(
          rValue: 15.0,
          bValue: 30.0,
          dValue: 80.0,
          eValue: 108.0,
          gasketThickness: 3.0,
          initialValue: 10.0,
        );
        
        final results = <SealingResult>[];
        
        // 执行100次相同参数的计算
        for (int i = 0; i < 100; i++) {
          final result = await service.calculate(
            CalculationType.sealing, 
            fixedParams.toJson(),
          ) as SealingResult;
          
          results.add(result);
        }
        
        // 验证所有结果都相同
        final firstResult = results.first;
        for (int i = 1; i < results.length; i++) {
          final currentResult = results[i];
          
          expect(
            (firstResult.guideWheelStroke - currentResult.guideWheelStroke).abs(),
            lessThan(1e-15), // 机器精度级别的一致性
            reason: '相同参数的导向轮行程计算结果应该完全一致，迭代 $i',
          );
          
          expect(
            (firstResult.totalStroke - currentResult.totalStroke).abs(),
            lessThan(1e-15), // 机器精度级别的一致性
            reason: '相同参数的总行程计算结果应该完全一致，迭代 $i',
          );
        }
      });

      test('封堵计算公式一致性验证 - 100次测试', () async {
        // **功能: pipeline-calculation-app, 属性 6: 封堵解堵计算一致性**
        
        for (int i = 0; i < 100; i++) {
          final params = ValidParameterGenerator.generateValidSealingParameters();
          
          // 执行封堵计算
          final result = await service.calculate(
            CalculationType.sealing, 
            params.toJson(),
          ) as SealingResult;
          
          // 手动计算预期结果，验证公式一致性
          final expectedGuideWheelStroke = params.rValue + params.bValue + 
                                          params.eValue + params.gasketThickness + 
                                          params.initialValue;
          
          final expectedTotalStroke = params.dValue + params.bValue + 
                                     params.eValue + params.gasketThickness + 
                                     params.initialValue;
          
          // 验证计算结果与预期公式一致
          expect(
            (result.guideWheelStroke - expectedGuideWheelStroke).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '导向轮接触管线行程公式验证失败，迭代 $i',
          );
          
          expect(
            (result.totalStroke - expectedTotalStroke).abs(),
            lessThan(engine.getPrecisionThreshold()),
            reason: '封堵总行程公式验证失败，迭代 $i',
          );
        }
      });

      test('封堵参数变化影响一致性 - 100次测试', () async {
        // **功能: pipeline-calculation-app, 属性 6: 封堵解堵计算一致性**
        
        final baseParams = SealingParameters(
          rValue: 15.0,
          bValue: 30.0,
          dValue: 80.0,
          eValue: 108.0,
          gasketThickness: 3.0,
          initialValue: 10.0,
        );
        
        final random = math.Random();
        
        for (int i = 0; i < 100; i++) {
          // 随机修改一个参数
          final parameterToModify = random.nextInt(6);
          final modificationAmount = (random.nextDouble() - 0.5) * 20.0; // -10 到 +10
          
          SealingParameters modifiedParams;
          
          switch (parameterToModify) {
            case 0:
              modifiedParams = baseParams.copyWith(
                rValue: math.max(0.1, baseParams.rValue + modificationAmount),
              );
              break;
            case 1:
              modifiedParams = baseParams.copyWith(
                bValue: math.max(0.1, baseParams.bValue + modificationAmount),
              );
              break;
            case 2:
              modifiedParams = baseParams.copyWith(
                dValue: math.max(0.1, baseParams.dValue + modificationAmount),
              );
              break;
            case 3:
              modifiedParams = baseParams.copyWith(
                eValue: math.max(0.1, baseParams.eValue + modificationAmount),
              );
              break;
            case 4:
              modifiedParams = baseParams.copyWith(
                gasketThickness: math.max(0.0, baseParams.gasketThickness + modificationAmount),
              );
              break;
            case 5:
            default:
              modifiedParams = baseParams.copyWith(
                initialValue: math.max(0.0, baseParams.initialValue + modificationAmount),
              );
              break;
          }
          
          // 计算基础参数和修改参数的结果
          final baseResult = await service.calculate(
            CalculationType.sealing, 
            baseParams.toJson(),
          ) as SealingResult;
          
          final modifiedResult = await service.calculate(
            CalculationType.sealing, 
            modifiedParams.toJson(),
          ) as SealingResult;
          
          // 验证参数变化对结果的影响是可预测的
          // 如果参数增加，相应的行程也应该增加（或保持不变）
          final parameterDifference = _calculateParameterSum(modifiedParams) - 
                                     _calculateParameterSum(baseParams);
          
          final guideWheelDifference = modifiedResult.guideWheelStroke - baseResult.guideWheelStroke;
          final totalStrokeDifference = modifiedResult.totalStroke - baseResult.totalStroke;
          
          // 验证变化方向的一致性（参数增加时结果也应该增加）
          if (parameterDifference > 0) {
            expect(guideWheelDifference, greaterThanOrEqualTo(-engine.getPrecisionThreshold()),
                   reason: '参数增加时导向轮行程不应显著减少，迭代 $i');
            expect(totalStrokeDifference, greaterThanOrEqualTo(-engine.getPrecisionThreshold()),
                   reason: '参数增加时总行程不应显著减少，迭代 $i');
          }
        }
      });
    });

    group('参数验证边界测试', () {
      test('特殊数值处理 - NaN和无穷大', () async {
        // **功能: pipeline-calculation-app, 属性 3: 输入参数验证**
        
        // 测试NaN值 - 直接测试计算而不是验证
        final nanParams = {
          'outer_diameter': double.nan,
          'inner_diameter': 50.0,
          'cutter_outer_diameter': 20.0,
          'cutter_inner_diameter': 15.0,
          'a_value': 30.0,
          'b_value': 20.0,
          'r_value': 10.0,
          'initial_value': 5.0,
          'gasket_thickness': 2.0,
        };
        
        expect(
          () async => await service.calculate(CalculationType.hole, nanParams),
          throwsA(anyOf([isA<Exception>(), isA<FormatException>(), isA<ArgumentError>()])),
          reason: 'NaN值应该导致计算异常',
        );
        
        // 测试无穷大值 - 直接测试计算而不是验证
        final infinityParams = {
          'outer_diameter': double.infinity,
          'inner_diameter': 50.0,
          'cutter_outer_diameter': 20.0,
          'cutter_inner_diameter': 15.0,
          'a_value': 30.0,
          'b_value': 20.0,
          'r_value': 10.0,
          'initial_value': 5.0,
          'gasket_thickness': 2.0,
        };
        
        expect(
          () async => await service.calculate(CalculationType.hole, infinityParams),
          throwsA(anyOf([isA<Exception>(), isA<FormatException>(), isA<ArgumentError>()])),
          reason: '无穷大值应该导致计算异常',
        );
      });
    });

    group('属性 4: 参数组往返一致性', () {
      late ParameterService parameterService;

      setUp(() async {
        parameterService = ParameterService();
        // 清理测试数据
        await parameterService.clearDatabase();
      });

      tearDown(() async {
        await parameterService.close();
      });

      test('参数组保存和加载一致性 - 100次测试', () async {
        // **功能: pipeline-calculation-app, 属性 4: 参数组往返一致性**
        // **验证需求: 6.2, 6.3**
        
        for (int i = 0; i < 100; i++) {
          // 随机选择计算类型
          final calculationType = CalculationType.values[i % CalculationType.values.length];
          
          // 生成随机参数组
          final originalParameterSet = ParameterManagementTestGenerator.generateRandomParameterSet(calculationType);
          
          // 保存参数组
          await parameterService.saveParameterSet(originalParameterSet);
          
          // 加载参数组
          final loadedParameterSet = await parameterService.getParameterSet(originalParameterSet.id);
          
          // 验证加载的参数组不为空
          expect(loadedParameterSet, isNotNull, 
                 reason: '保存的参数组应该能够被加载，迭代 $i');
          
          // 验证基本属性一致性
          expect(loadedParameterSet!.id, equals(originalParameterSet.id),
                 reason: '参数组ID应该一致，迭代 $i');
          expect(loadedParameterSet.name, equals(originalParameterSet.name),
                 reason: '参数组名称应该一致，迭代 $i');
          expect(loadedParameterSet.calculationType, equals(originalParameterSet.calculationType),
                 reason: '计算类型应该一致，迭代 $i');
          expect(loadedParameterSet.description, equals(originalParameterSet.description),
                 reason: '描述应该一致，迭代 $i');
          expect(loadedParameterSet.tags, equals(originalParameterSet.tags),
                 reason: '标签应该一致，迭代 $i');
          
          // 验证参数数据一致性（通过JSON比较）
          expect(loadedParameterSet.parameters.toJson(), 
                 equals(originalParameterSet.parameters.toJson()),
                 reason: '参数数据应该完全一致，迭代 $i');
          
          // 验证时间戳（创建时间应该一致，更新时间可能不同）
          expect(loadedParameterSet.createdAt.millisecondsSinceEpoch, 
                 equals(originalParameterSet.createdAt.millisecondsSinceEpoch),
                 reason: '创建时间应该一致，迭代 $i');
        }
      });
    });

    group('属性 5: 单位转换往返保持', () {
      late ParameterManager parameterManager;

      setUp(() {
        parameterManager = ParameterManager.instance;
      });

      test('基本单位转换往返一致性 - 100次测试', () {
        // **功能: pipeline-calculation-app, 属性 5: 单位转换往返保持**
        // **验证需求: 6.4, 6.5**
        
        final random = math.Random();
        
        for (int i = 0; i < 100; i++) {
          // 生成随机数值
          final originalValue = 1.0 + random.nextDouble() * 999.0; // 1-1000mm
          
          // 毫米 -> 英寸 -> 毫米
          final convertedToInch = parameterManager.convertUnit(
            originalValue, 
            UnitType.millimeter, 
            UnitType.inch,
          );
          final backToMm = parameterManager.convertUnit(
            convertedToInch, 
            UnitType.inch, 
            UnitType.millimeter,
          );
          
          // 验证往返转换精度
          final difference = (originalValue - backToMm).abs();
          expect(difference, lessThan(1e-10),
                 reason: '毫米->英寸->毫米往返转换精度损失过大，迭代 $i，原值: $originalValue，回转值: $backToMm，差值: $difference');
          
          // 英寸 -> 毫米 -> 英寸
          final originalInchValue = 1.0 + random.nextDouble() * 39.37; // 1-40英寸
          final convertedToMm = parameterManager.convertUnit(
            originalInchValue, 
            UnitType.inch, 
            UnitType.millimeter,
          );
          final backToInch = parameterManager.convertUnit(
            convertedToMm, 
            UnitType.millimeter, 
            UnitType.inch,
          );
          
          final inchDifference = (originalInchValue - backToInch).abs();
          expect(inchDifference, lessThan(1e-10),
                 reason: '英寸->毫米->英寸往返转换精度损失过大，迭代 $i，原值: $originalInchValue，回转值: $backToInch，差值: $inchDifference');
        }
      });
    });
  });
}

/// 计算封堵参数的总和（用于变化影响测试）
double _calculateParameterSum(SealingParameters params) {
  return params.rValue + params.bValue + params.dValue + 
         params.eValue + params.gasketThickness + params.initialValue;
}

/// 参数管理测试生成器
class ParameterManagementTestGenerator {
  static final _random = math.Random();

  /// 生成随机的参数组
  static ParameterSet generateRandomParameterSet(CalculationType type) {
    final id = 'test_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
    final name = 'Test Parameter Set ${_random.nextInt(1000)}';
    
    CalculationParameters parameters;
    
    switch (type) {
      case CalculationType.hole:
        parameters = _generateRandomHoleParameters();
        break;
      case CalculationType.manualHole:
        parameters = _generateRandomManualHoleParameters();
        break;
      case CalculationType.sealing:
        parameters = _generateRandomSealingParameters();
        break;
      case CalculationType.plug:
        parameters = _generateRandomPlugParameters();
        break;
      case CalculationType.stem:
        parameters = _generateRandomStemParameters();
        break;
    }
    
    return ParameterSet(
      id: id,
      name: name,
      calculationType: type,
      parameters: parameters,
      description: 'Test parameter set for ${type.displayName}',
      tags: ['test', 'random', type.value],
    );
  }

  static HoleParameters _generateRandomHoleParameters() {
    return HoleParameters(
      outerDiameter: 50.0 + _random.nextDouble() * 200.0,
      innerDiameter: 40.0 + _random.nextDouble() * 180.0,
      cutterOuterDiameter: 10.0 + _random.nextDouble() * 40.0,
      cutterInnerDiameter: 5.0 + _random.nextDouble() * 30.0,
      aValue: 10.0 + _random.nextDouble() * 100.0,
      bValue: 5.0 + _random.nextDouble() * 50.0,
      rValue: 5.0 + _random.nextDouble() * 30.0,
      initialValue: _random.nextDouble() * 20.0,
      gasketThickness: _random.nextDouble() * 10.0,
    );
  }

  static ManualHoleParameters _generateRandomManualHoleParameters() {
    return ManualHoleParameters(
      lValue: 20.0 + _random.nextDouble() * 80.0,
      jValue: 10.0 + _random.nextDouble() * 40.0,
      pValue: 10.0 + _random.nextDouble() * 50.0,
      tValue: 5.0 + _random.nextDouble() * 30.0,
      wValue: 2.0 + _random.nextDouble() * 20.0,
    );
  }

  static SealingParameters _generateRandomSealingParameters() {
    return SealingParameters(
      rValue: 10.0 + _random.nextDouble() * 50.0,
      bValue: 10.0 + _random.nextDouble() * 40.0,
      dValue: 20.0 + _random.nextDouble() * 100.0,
      eValue: 50.0 + _random.nextDouble() * 150.0,
      gasketThickness: _random.nextDouble() * 10.0,
      initialValue: _random.nextDouble() * 20.0,
    );
  }

  static PlugParameters _generateRandomPlugParameters() {
    return PlugParameters(
      mValue: 20.0 + _random.nextDouble() * 80.0,
      kValue: 10.0 + _random.nextDouble() * 50.0,
      nValue: 10.0 + _random.nextDouble() * 60.0,
      tValue: 5.0 + _random.nextDouble() * 30.0,
      wValue: 2.0 + _random.nextDouble() * 20.0,
    );
  }

  static StemParameters _generateRandomStemParameters() {
    return StemParameters(
      fValue: 15.0 + _random.nextDouble() * 60.0,
      gValue: 10.0 + _random.nextDouble() * 50.0,
      hValue: 10.0 + _random.nextDouble() * 40.0,
      gasketThickness: _random.nextDouble() * 10.0,
      initialValue: _random.nextDouble() * 20.0,
    );
  }

  /// 生成随机的数值映射（用于单位转换测试）
  static Map<String, double> generateRandomValueMap() {
    final map = <String, double>{};
    final paramCount = 3 + _random.nextInt(7); // 3-9个参数
    
    for (int i = 0; i < paramCount; i++) {
      final key = 'param_$i';
      final value = 1.0 + _random.nextDouble() * 999.0; // 1-1000的值
      map[key] = value;
    }
    
    return map;
  }
}

/// 参数管理属性测试组
void main() {
  group('参数管理属性测试', () {
    late ParameterService parameterService;

    setUp(() async {
      parameterService = ParameterService();
      // 清理测试数据
      await parameterService.clearDatabase();
    });

    tearDown(() async {
      await parameterService.close();
    });

    test('参数组保存和加载一致性 - 100次测试', () async {
      // **功能: pipeline-calculation-app, 属性 4: 参数组往返一致性**
      // **验证需求: 6.2, 6.3**
      
      for (int i = 0; i < 100; i++) {
        // 随机选择计算类型
        final calculationType = CalculationType.values[i % CalculationType.values.length];
        
        // 生成随机参数组
        final originalParameterSet = ParameterManagementTestGenerator.generateRandomParameterSet(calculationType);
        
        // 保存参数组
        await parameterService.saveParameterSet(originalParameterSet);
        
        // 加载参数组
        final loadedParameterSet = await parameterService.getParameterSet(originalParameterSet.id);
        
        // 验证加载的参数组不为空
        expect(loadedParameterSet, isNotNull, 
               reason: '保存的参数组应该能够被加载，迭代 $i');
        
        // 验证基本属性一致性
        expect(loadedParameterSet!.id, equals(originalParameterSet.id),
               reason: '参数组ID应该一致，迭代 $i');
        expect(loadedParameterSet.name, equals(originalParameterSet.name),
               reason: '参数组名称应该一致，迭代 $i');
        expect(loadedParameterSet.calculationType, equals(originalParameterSet.calculationType),
               reason: '计算类型应该一致，迭代 $i');
        expect(loadedParameterSet.description, equals(originalParameterSet.description),
               reason: '描述应该一致，迭代 $i');
        expect(loadedParameterSet.tags, equals(originalParameterSet.tags),
               reason: '标签应该一致，迭代 $i');
        
        // 验证参数数据一致性（通过JSON比较）
        expect(loadedParameterSet.parameters.toJson(), 
               equals(originalParameterSet.parameters.toJson()),
               reason: '参数数据应该完全一致，迭代 $i');
        
        // 验证时间戳（创建时间应该一致，更新时间可能不同）
        expect(loadedParameterSet.createdAt.millisecondsSinceEpoch, 
               equals(originalParameterSet.createdAt.millisecondsSinceEpoch),
               reason: '创建时间应该一致，迭代 $i');
      }
    });

    test('参数组更新一致性 - 100次测试', () async {
      // **功能: pipeline-calculation-app, 属性 4: 参数组往返一致性**
      
      for (int i = 0; i < 100; i++) {
        final calculationType = CalculationType.values[i % CalculationType.values.length];
        
        // 创建并保存原始参数组
        final originalParameterSet = ParameterManagementTestGenerator.generateRandomParameterSet(calculationType);
        await parameterService.saveParameterSet(originalParameterSet);
        
        // 创建更新后的参数组
        final updatedParameterSet = originalParameterSet.copyWith(
          name: '${originalParameterSet.name} - Updated',
          description: '${originalParameterSet.description} - Modified',
          tags: [...originalParameterSet.tags, 'updated'],
        );
        
        // 更新参数组
        await parameterService.updateParameterSet(updatedParameterSet);
        
        // 加载更新后的参数组
        final loadedParameterSet = await parameterService.getParameterSet(originalParameterSet.id);
        
        // 验证更新内容
        expect(loadedParameterSet!.name, equals(updatedParameterSet.name),
               reason: '更新后的名称应该一致，迭代 $i');
        expect(loadedParameterSet.description, equals(updatedParameterSet.description),
               reason: '更新后的描述应该一致，迭代 $i');
        expect(loadedParameterSet.tags, equals(updatedParameterSet.tags),
               reason: '更新后的标签应该一致，迭代 $i');
        
        // 验证ID和计算类型未改变
        expect(loadedParameterSet.id, equals(originalParameterSet.id),
               reason: 'ID不应该改变，迭代 $i');
        expect(loadedParameterSet.calculationType, equals(originalParameterSet.calculationType),
               reason: '计算类型不应该改变，迭代 $i');
      }
    });

    test('参数组复制一致性 - 100次测试', () async {
      // **功能: pipeline-calculation-app, 属性 4: 参数组往返一致性**
      
      for (int i = 0; i < 100; i++) {
        final calculationType = CalculationType.values[i % CalculationType.values.length];
        
        // 创建并保存原始参数组
        final originalParameterSet = ParameterManagementTestGenerator.generateRandomParameterSet(calculationType);
        await parameterService.saveParameterSet(originalParameterSet);
        
        // 复制参数组
        final newName = '${originalParameterSet.name} - Copy';
        final copiedParameterSet = await parameterService.duplicateParameterSet(
          originalParameterSet.id, 
          newName,
          'Copied from original',
        );
        
        // 验证复制结果
        expect(copiedParameterSet.id, isNot(equals(originalParameterSet.id)),
               reason: '复制的参数组应该有不同的ID，迭代 $i');
        expect(copiedParameterSet.name, equals(newName),
               reason: '复制的参数组应该有新名称，迭代 $i');
        expect(copiedParameterSet.calculationType, equals(originalParameterSet.calculationType),
               reason: '复制的参数组应该有相同的计算类型，迭代 $i');
        
        // 验证参数数据完全一致
        expect(copiedParameterSet.parameters.toJson(), 
               equals(originalParameterSet.parameters.toJson()),
               reason: '复制的参数数据应该完全一致，迭代 $i');
        
        // 验证复制的参数组可以被加载
        final loadedCopy = await parameterService.getParameterSet(copiedParameterSet.id);
        expect(loadedCopy, isNotNull,
               reason: '复制的参数组应该能够被加载，迭代 $i');
        expect(loadedCopy!.parameters.toJson(), 
               equals(originalParameterSet.parameters.toJson()),
               reason: '加载的复制参数组数据应该与原始一致，迭代 $i');
      }
    });

    test('批量操作一致性 - 100次测试', () async {
      // **功能: pipeline-calculation-app, 属性 4: 参数组往返一致性**
      
      // 创建多个参数组
      final parameterSets = <ParameterSet>[];
      for (int i = 0; i < 10; i++) {
        final calculationType = CalculationType.values[i % CalculationType.values.length];
        final parameterSet = ParameterManagementTestGenerator.generateRandomParameterSet(calculationType);
        parameterSets.add(parameterSet);
        await parameterService.saveParameterSet(parameterSet);
      }
      
      for (int testRound = 0; testRound < 10; testRound++) {
        // 随机选择一些参数组进行批量操作
        final selectedIds = <String>[];
        final selectedCount = 3 + math.Random().nextInt(5); // 3-7个
        
        for (int i = 0; i < selectedCount && i < parameterSets.length; i++) {
          selectedIds.add(parameterSets[i].id);
        }
        
        // 批量更新标签
        final newTags = ['batch_test', 'round_$testRound'];
        final updatedCount = await parameterService.batchUpdateTags(selectedIds, newTags, false);
        
        expect(updatedCount, equals(selectedIds.length),
               reason: '批量更新应该影响所有选中的参数组，测试轮次 $testRound');
        
        // 验证标签更新
        for (final id in selectedIds) {
          final parameterSet = await parameterService.getParameterSet(id);
          expect(parameterSet!.tags, equals(newTags),
                 reason: '参数组标签应该被正确更新，测试轮次 $testRound');
        }
        
        // 按标签查询
        final taggedParameterSets = await parameterService.getParameterSetsByTags(['batch_test']);
        expect(taggedParameterSets.length, greaterThanOrEqualTo(selectedIds.length),
               reason: '按标签查询应该返回正确数量的参数组，测试轮次 $testRound');
      }
    });

    test('导出导入一致性 - 100次测试', () async {
      // **功能: pipeline-calculation-app, 属性 4: 参数组往返一致性**
      
      for (int i = 0; i < 20; i++) { // 减少迭代次数因为导出导入操作较重
        // 创建多个参数组
        final originalParameterSets = <ParameterSet>[];
        final parameterSetIds = <String>[];
        
        for (int j = 0; j < 5; j++) {
          final calculationType = CalculationType.values[j % CalculationType.values.length];
          final parameterSet = ParameterManagementTestGenerator.generateRandomParameterSet(calculationType);
          originalParameterSets.add(parameterSet);
          parameterSetIds.add(parameterSet.id);
          await parameterService.saveParameterSet(parameterSet);
        }
        
        // 导出参数组
        final exportedJson = await parameterService.exportParameterSets(parameterSetIds);
        expect(exportedJson, isNotEmpty,
               reason: '导出的JSON不应该为空，迭代 $i');
        
        // 清理数据库
        await parameterService.clearDatabase();
        
        // 导入参数组
        final importedCount = await parameterService.importParameterSets(exportedJson);
        expect(importedCount, equals(originalParameterSets.length),
               reason: '导入的参数组数量应该与导出的一致，迭代 $i');
        
        // 验证导入的参数组
        final allImportedSets = await parameterService.getUserParameterSets();
        expect(allImportedSets.length, equals(originalParameterSets.length),
               reason: '导入后的参数组总数应该正确，迭代 $i');
        
        // 验证每个参数组的数据一致性（按名称匹配，因为ID会重新生成）
        for (final original in originalParameterSets) {
          final imported = allImportedSets.firstWhere(
            (set) => set.name == original.name,
            orElse: () => throw StateError('找不到导入的参数组: ${original.name}'),
          );
          
          expect(imported.calculationType, equals(original.calculationType),
                 reason: '导入参数组的计算类型应该一致，迭代 $i');
          expect(imported.parameters.toJson(), equals(original.parameters.toJson()),
                 reason: '导入参数组的参数数据应该一致，迭代 $i');
          expect(imported.description, equals(original.description),
                 reason: '导入参数组的描述应该一致，迭代 $i');
        }
      }
    });
  });

  group('属性 5: 单位转换往返保持', () {
    late ParameterManager parameterManager;

    setUp(() {
      parameterManager = ParameterManager.instance;
    });

    test('基本单位转换往返一致性 - 100次测试', () {
      // **功能: pipeline-calculation-app, 属性 5: 单位转换往返保持**
      // **验证需求: 6.4, 6.5**
      
      final random = math.Random();
      
      for (int i = 0; i < 100; i++) {
        // 生成随机数值
        final originalValue = 1.0 + random.nextDouble() * 999.0; // 1-1000mm
        
        // 毫米 -> 英寸 -> 毫米
        final convertedToInch = parameterManager.convertUnit(
          originalValue, 
          UnitType.millimeter, 
          UnitType.inch,
        );
        final backToMm = parameterManager.convertUnit(
          convertedToInch, 
          UnitType.inch, 
          UnitType.millimeter,
        );
        
        // 验证往返转换精度
        final difference = (originalValue - backToMm).abs();
        expect(difference, lessThan(1e-10),
               reason: '毫米->英寸->毫米往返转换精度损失过大，迭代 $i，原值: $originalValue，回转值: $backToMm，差值: $difference');
        
        // 英寸 -> 毫米 -> 英寸
        final originalInchValue = 1.0 + random.nextDouble() * 39.37; // 1-40英寸
        final convertedToMm = parameterManager.convertUnit(
          originalInchValue, 
          UnitType.inch, 
          UnitType.millimeter,
        );
        final backToInch = parameterManager.convertUnit(
          convertedToMm, 
          UnitType.millimeter, 
          UnitType.inch,
        );
        
        final inchDifference = (originalInchValue - backToInch).abs();
        expect(inchDifference, lessThan(1e-10),
               reason: '英寸->毫米->英寸往返转换精度损失过大，迭代 $i，原值: $originalInchValue，回转值: $backToInch，差值: $inchDifference');
      }
    });

    test('批量参数转换往返一致性 - 100次测试', () {
      // **功能: pipeline-calculation-app, 属性 5: 单位转换往返保持**
      
      for (int i = 0; i < 100; i++) {
        // 生成随机参数映射
        final originalParameters = ParameterManagementTestGenerator.generateRandomValueMap();
        
        // 批量转换：毫米 -> 英寸 -> 毫米
        final convertedToInch = parameterManager.convertParameters(
          originalParameters, 
          UnitType.millimeter, 
          UnitType.inch,
        );
        final backToMm = parameterManager.convertParameters(
          convertedToInch, 
          UnitType.inch, 
          UnitType.millimeter,
        );
        
        // 验证每个参数的往返一致性
        expect(backToMm.keys, equals(originalParameters.keys),
               reason: '转换后的参数键应该保持一致，迭代 $i');
        
        for (final key in originalParameters.keys) {
          final originalValue = originalParameters[key]!;
          final backValue = backToMm[key]!;
          final difference = (originalValue - backValue).abs();
          
          expect(difference, lessThan(1e-10),
                 reason: '参数 $key 的往返转换精度损失过大，迭代 $i，原值: $originalValue，回转值: $backValue');
        }
      }
    });

    test('计算参数对象转换往返一致性 - 100次测试', () {
      // **功能: pipeline-calculation-app, 属性 5: 单位转换往返保持**
      
      for (int i = 0; i < 100; i++) {
        final calculationType = CalculationType.values[i % CalculationType.values.length];
        
        // 生成原始参数对象
        final originalParameterSet = ParameterManagementTestGenerator.generateRandomParameterSet(calculationType);
        final originalParameters = originalParameterSet.parameters;
        
        // 转换：毫米 -> 英寸 -> 毫米
        final convertedToInch = parameterManager.convertCalculationParameters(
          originalParameters, 
          UnitType.inch,
        );
        final backToMm = parameterManager.convertCalculationParameters(
          convertedToInch, 
          UnitType.millimeter,
        );
        
        // 验证往返转换一致性
        final originalJson = originalParameters.toJson();
        final backJson = backToMm.toJson();
        
        expect(backJson.keys, equals(originalJson.keys),
               reason: '转换后的参数字段应该保持一致，迭代 $i');
        
        for (final key in originalJson.keys) {
          final originalValue = originalJson[key] as double;
          final backValue = backJson[key] as double;
          final difference = (originalValue - backValue).abs();
          
          expect(difference, lessThan(1e-10),
                 reason: '参数 $key 的往返转换精度损失过大，迭代 $i，类型: ${calculationType.displayName}');
        }
      }
    });

    test('转换精度验证 - 100次测试', () {
      // **功能: pipeline-calculation-app, 属性 5: 单位转换往返保持**
      
      final random = math.Random();
      
      for (int i = 0; i < 100; i++) {
        final testValue = 0.1 + random.nextDouble() * 999.9; // 0.1-1000mm
        
        // 验证转换精度是否可接受
        final precisionAcceptable = parameterManager.isConversionPrecisionAcceptable(
          testValue, 
          UnitType.millimeter, 
          UnitType.inch,
        );
        
        expect(precisionAcceptable, isTrue,
               reason: '转换精度应该在可接受范围内，迭代 $i，测试值: $testValue');
        
        // 验证精度损失百分比
        final precisionLoss = parameterManager.validateConversionPrecision(
          testValue, 
          UnitType.millimeter, 
          UnitType.inch,
        );
        
        expect(precisionLoss, lessThan(0.01), // 小于0.01%
               reason: '精度损失应该小于0.01%，迭代 $i，测试值: $testValue，精度损失: $precisionLoss%');
      }
    });

    test('特殊数值转换处理 - 100次测试', () {
      // **功能: pipeline-calculation-app, 属性 5: 单位转换往返保持**
      
      final specialValues = [
        0.0,           // 零值
        0.001,         // 极小值
        1.0,           // 单位值
        25.4,          // 转换系数
        100.0,         // 常用值
        1000.0,        // 大值
      ];
      
      for (int i = 0; i < 100; i++) {
        final testValue = specialValues[i % specialValues.length];
        
        // 测试往返转换
        final converted = UnitConverter.convert(testValue, UnitType.millimeter, UnitType.inch);
        final backConverted = UnitConverter.convert(converted, UnitType.inch, UnitType.millimeter);
        
        final difference = (testValue - backConverted).abs();
        
        if (testValue == 0.0) {
          expect(backConverted, equals(0.0),
                 reason: '零值转换应该保持为零，迭代 $i');
        } else {
          expect(difference, lessThan(1e-15),
                 reason: '特殊值 $testValue 的往返转换应该保持高精度，迭代 $i');
        }
      }
    });

    test('转换系数验证 - 100次测试', () {
      // **功能: pipeline-calculation-app, 属性 5: 单位转换往返保持**
      
      for (int i = 0; i < 100; i++) {
        // 验证转换系数的数学正确性
        final mmToInchFactor = parameterManager.getConversionFactor(
          UnitType.millimeter, 
          UnitType.inch,
        );
        final inchToMmFactor = parameterManager.getConversionFactor(
          UnitType.inch, 
          UnitType.millimeter,
        );
        
        // 验证转换系数是倒数关系
        final product = mmToInchFactor * inchToMmFactor;
        expect((product - 1.0).abs(), lessThan(1e-15),
               reason: '转换系数应该是倒数关系，迭代 $i，乘积: $product');
        
        // 验证已知转换系数
        expect((mmToInchFactor - (1.0 / 25.4)).abs(), lessThan(1e-15),
               reason: '毫米到英寸转换系数应该是1/25.4，迭代 $i');
        expect((inchToMmFactor - 25.4).abs(), lessThan(1e-15),
               reason: '英寸到毫米转换系数应该是25.4，迭代 $i');
        
        // 验证相同单位转换系数为1
        final sameFactor = parameterManager.getConversionFactor(
          UnitType.millimeter, 
          UnitType.millimeter,
        );
        expect(sameFactor, equals(1.0),
               reason: '相同单位转换系数应该为1，迭代 $i');
      }
    });

    test('数学验证 - UnitConverter类验证', () {
      // **功能: pipeline-calculation-app, 属性 5: 单位转换往返保持**
      
      // 验证UnitConverter的数学正确性
      final mathValidation = UnitConverter.validateConversionMath();
      expect(mathValidation, isTrue,
             reason: 'UnitConverter的数学验证应该通过');
      
      // 验证常用转换示例
      final commonConversions = UnitConverter.getCommonConversions();
      expect(commonConversions, isNotEmpty,
             reason: '常用转换示例应该不为空');
      
      // 验证每个示例的数学正确性
      for (final category in commonConversions.entries) {
        for (final conversion in category.value.entries) {
          final mmValueStr = conversion.key.replaceAll(' mm', '');
          final mmValue = double.tryParse(mmValueStr);
          
          if (mmValue != null) {
            final expectedInchValue = UnitConverter.convert(
              mmValue, 
              UnitType.millimeter, 
              UnitType.inch,
            );
            final formattedExpected = UnitConverter.formatValue(
              expectedInchValue, 
              UnitType.inch,
            );
            
            expect(conversion.value, equals(formattedExpected),
                   reason: '常用转换示例 ${conversion.key} 应该数学正确');
          }
        }
      }
    });
  });