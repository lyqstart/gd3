import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/calculation_parameters.dart';
import '../../lib/models/calculation_result.dart';
import '../../lib/models/enums.dart';
import '../../lib/services/calculation_engine.dart';
import '../../lib/models/validation_result.dart';

void main() {
  group('下塞柄计算测试', () {
    late PrecisionCalculationEngine engine;

    setUp(() {
      engine = PrecisionCalculationEngine();
    });

    group('StemParameters 参数验证测试', () {
      test('有效参数应该通过验证', () {
        final params = StemParameters(
          fValue: 50.0,
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        final validation = params.validate();
        expect(validation.isValid, isTrue);
      });

      test('负数参数应该验证失败', () {
        final params = StemParameters(
          fValue: -10.0,  // 负数
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        final validation = params.validate();
        expect(validation.isValid, isFalse);
        expect(validation.message, contains('F值'));
      });

      test('零值参数应该验证失败（除了垫子厚度和初始值）', () {
        final params = StemParameters(
          fValue: 0.0,  // 零值
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 0.0,  // 允许为零
          initialValue: 0.0,     // 允许为零
        );

        final validation = params.validate();
        expect(validation.isValid, isFalse);
        expect(validation.message, contains('F值'));
      });

      test('超出合理范围的参数应该产生警告', () {
        final params = StemParameters(
          fValue: 500.0,  // 超出合理范围
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        final validation = params.validate();
        // 应该通过验证但有警告
        expect(validation.isValid, isTrue);
        expect(validation.isWarning, isTrue);
      });

      test('参数组合安全性检查', () {
        final safeParams = StemParameters(
          fValue: 50.0,
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        expect(safeParams.isSafeParameterCombination(), isTrue);

        final unsafeParams = StemParameters(
          fValue: -10.0,
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        expect(unsafeParams.isSafeParameterCombination(), isFalse);
      });
    });

    group('下塞柄计算功能测试', () {
      test('基本计算功能 - 需求5.1', () {
        // 测试基本的下塞柄总行程计算
        final params = StemParameters(
          fValue: 50.0,
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        final result = engine.calculateStem(params);

        // 验证计算公式: 总行程 = F + G + H + 垫子厚度 + 初始值
        final expectedTotalStroke = 50.0 + 30.0 + 80.0 + 2.0 + 5.0;
        expect(result.totalStroke, equals(expectedTotalStroke));
        expect(result.totalStroke, equals(167.0));
      });

      test('精度控制测试 - 需求5.3', () {
        // 测试计算精度保持至小数点后2位
        final params = StemParameters(
          fValue: 50.123,
          gValue: 30.456,
          hValue: 80.789,
          gasketThickness: 2.111,
          initialValue: 5.222,
        );

        final result = engine.calculateStem(params);

        // 验证结果精度（应该保持到小数点后1位，因为精度阈值是0.1mm）
        final expectedTotal = 50.123 + 30.456 + 80.789 + 2.111 + 5.222;
        expect(result.totalStroke, closeTo(expectedTotal, 0.1));
        
        // 验证精度格式
        final decimalPlaces = result.totalStroke.toString().split('.').length > 1 
            ? result.totalStroke.toString().split('.')[1].length 
            : 0;
        expect(decimalPlaces, lessThanOrEqualTo(1)); // 0.1mm精度
      });

      test('边界值测试', () {
        // 测试最小有效值
        final minParams = StemParameters(
          fValue: 0.1,
          gValue: 0.1,
          hValue: 0.1,
          gasketThickness: 0.0,
          initialValue: 0.0,
        );

        final minResult = engine.calculateStem(minParams);
        expect(minResult.totalStroke, equals(0.3));

        // 测试较大值
        final maxParams = StemParameters(
          fValue: 300.0,
          gValue: 150.0,
          hValue: 200.0,
          gasketThickness: 20.0,
          initialValue: 30.0,
        );

        final maxResult = engine.calculateStem(maxParams);
        expect(maxResult.totalStroke, equals(700.0));
      });

      test('计算结果验证', () {
        final params = StemParameters(
          fValue: 50.0,
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        final result = engine.calculateStem(params);

        // 验证结果对象的完整性
        expect(result.calculationType, equals(CalculationType.stem));
        expect(result.parameters, equals(params));
        expect(result.calculationTime, isNotNull);
        expect(result.id, isNotNull);

        // 验证核心结果
        final coreResults = result.getCoreResults();
        expect(coreResults['总行程'], equals(result.totalStroke));

        // 验证公式说明
        final formulas = result.getFormulas();
        expect(formulas['总行程'], contains('F + G + H + 垫子厚度 + 初始值'));
      });

      test('JSON序列化和反序列化', () {
        final params = StemParameters(
          fValue: 50.0,
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        final result = engine.calculateStem(params);

        // 测试序列化
        final json = result.toJson();
        expect(json['calculation_type'], equals('stem'));
        expect(json['results']['total_stroke'], equals(result.totalStroke));

        // 测试反序列化
        final deserializedResult = StemResult.fromJson(json);
        expect(deserializedResult.totalStroke, equals(result.totalStroke));
        expect(deserializedResult.calculationType, equals(result.calculationType));
      });
    });

    group('错误处理测试', () {
      test('无效参数应该抛出异常', () {
        final invalidParams = StemParameters(
          fValue: -10.0,  // 无效参数
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        expect(
          () => engine.calculateStem(invalidParams),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('计算异常处理', () {
        // 创建会导致计算异常的参数（所有值为零）
        final zeroParams = StemParameters(
          fValue: 0.0,
          gValue: 0.0,
          hValue: 0.0,
          gasketThickness: 0.0,
          initialValue: 0.0,
        );

        expect(
          () => engine.calculateStem(zeroParams),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('参数辅助功能测试', () {
      test('参数说明功能', () {
        final params = StemParameters(
          fValue: 50.0,
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        final descriptions = params.getParameterDescriptions();
        expect(descriptions['F值'], isNotNull);
        expect(descriptions['G值'], isNotNull);
        expect(descriptions['H值'], isNotNull);
        expect(descriptions['垫子厚度'], isNotNull);
        expect(descriptions['初始值'], isNotNull);

        final tips = params.getMeasurementTips();
        expect(tips['F值'], contains('测量'));
        expect(tips['G值'], contains('设备'));
        expect(tips['H值'], contains('下塞柄'));
      });

      test('优化建议功能', () {
        final params = StemParameters(
          fValue: 10.0,  // 较小值，应该产生建议
          gValue: 5.0,
          hValue: 15.0,
          gasketThickness: 1.0,
          initialValue: 1.0,
        );

        final suggestions = params.getOptimizationSuggestions();
        expect(suggestions, isNotEmpty);
        expect(suggestions.any((s) => s.contains('总行程较小')), isTrue);
      });

      test('安全建议功能', () {
        final params = StemParameters(
          fValue: 50.0,
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        final recommendations = params.getSafetyRecommendations();
        expect(recommendations, isNotEmpty);
        expect(recommendations.any((r) => r.contains('确认')), isTrue);
      });
    });

    group('结果分析功能测试', () {
      test('计算步骤说明', () {
        final params = StemParameters(
          fValue: 50.0,
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        final result = engine.calculateStem(params);
        final steps = result.getCalculationSteps();

        expect(steps, isNotEmpty);
        expect(steps['步骤1'], contains('F值=50.00'));
        expect(steps['步骤3'], contains('总行程 = '));
      });

      test('操作指导信息', () {
        final params = StemParameters(
          fValue: 50.0,
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        final result = engine.calculateStem(params);
        final guidance = result.getOperationGuidance();

        expect(guidance['准备阶段'], isNotNull);
        expect(guidance['操作阶段'], contains('167.0'));
        expect(guidance['监控要点'], isNotNull);
        expect(guidance['完成检查'], isNotNull);
      });

      test('参数影响分析', () {
        final params = StemParameters(
          fValue: 50.0,
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        final result = engine.calculateStem(params);
        final analysis = result.getParameterImpactAnalysis();

        expect(analysis['F值影响'], contains('%'));
        expect(analysis['G值影响'], contains('%'));
        expect(analysis['H值影响'], contains('%'));
      });

      test('质量控制要点', () {
        final params = StemParameters(
          fValue: 50.0,
          gValue: 30.0,
          hValue: 80.0,
          gasketThickness: 2.0,
          initialValue: 5.0,
        );

        final result = engine.calculateStem(params);
        final qcPoints = result.getQualityControlPoints();

        expect(qcPoints, isNotEmpty);
        expect(qcPoints.any((p) => p.contains('精度')), isTrue);
        expect(qcPoints.any((p) => p.contains('0.1mm')), isTrue);
      });
    });

    group('实际工程案例测试', () {
      test('典型工程案例1 - 小型管道', () {
        final params = StemParameters(
          fValue: 25.0,   // 小型封堵孔
          gValue: 15.0,   // 小调节范围
          hValue: 40.0,   // 短塞柄
          gasketThickness: 1.5,
          initialValue: 2.0,
        );

        final result = engine.calculateStem(params);
        expect(result.totalStroke, equals(83.5));

        final validation = result.validateResults();
        expect(validation.isValid, isTrue);
      });

      test('典型工程案例2 - 大型管道', () {
        final params = StemParameters(
          fValue: 120.0,  // 大型封堵孔
          gValue: 80.0,   // 大调节范围
          hValue: 150.0,  // 长塞柄
          gasketThickness: 5.0,
          initialValue: 10.0,
        );

        final result = engine.calculateStem(params);
        expect(result.totalStroke, equals(365.0));

        final validation = result.validateResults();
        expect(validation.isValid, isTrue);
      });

      test('边界工程案例 - 最小配置', () {
        final params = StemParameters(
          fValue: 15.0,   // 最小封堵孔
          gValue: 8.0,    // 最小调节范围
          hValue: 20.0,   // 最短塞柄
          gasketThickness: 0.5,
          initialValue: 1.0,
        );

        final result = engine.calculateStem(params);
        expect(result.totalStroke, equals(44.5));

        // 应该产生警告但仍然有效
        final validation = result.validateResults();
        expect(validation.isValid, isTrue);
      });
    });
  });
}