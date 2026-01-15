import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/calculation_parameters.dart';
import '../../lib/models/calculation_result.dart';
import '../../lib/models/enums.dart';
import '../../lib/services/calculation_engine.dart';

void main() {
  group('下塞堵计算测试', () {
    late PrecisionCalculationEngine engine;

    setUp(() {
      engine = PrecisionCalculationEngine();
    });

    group('正常计算测试', () {
      test('标准参数计算', () {
        // 准备测试数据
        final params = PlugParameters(
          mValue: 50.0,  // M值
          kValue: 30.0,  // K值
          nValue: 25.0,  // N值
          tValue: 20.0,  // T值
          wValue: 15.0,  // W值
        );

        // 执行计算
        final result = engine.calculatePlug(params);

        // 验证结果
        expect(result.threadEngagement, equals(5.0)); // T - W = 20 - 15 = 5
        expect(result.emptyStroke, equals(75.0)); // M + K - T + W = 50 + 30 - 20 + 15 = 75
        expect(result.totalStroke, equals(100.0)); // M + K + N - T + W = 50 + 30 + 25 - 20 + 15 = 100
        expect(result.calculationType, equals(CalculationType.plug));
        expect(result.parameters, equals(params));
      });

      test('边界值计算', () {
        final params = PlugParameters(
          mValue: 10.0,
          kValue: 5.0,
          nValue: 5.0,
          tValue: 10.0,
          wValue: 5.0,
        );

        final result = engine.calculatePlug(params);

        expect(result.threadEngagement, equals(5.0)); // 10 - 5 = 5
        expect(result.emptyStroke, equals(10.0)); // 10 + 5 - 10 + 5 = 10
        expect(result.totalStroke, equals(15.0)); // 10 + 5 + 5 - 10 + 5 = 15
      });

      test('大数值计算', () {
        final params = PlugParameters(
          mValue: 150.0,
          kValue: 80.0,
          nValue: 100.0,
          tValue: 50.0,
          wValue: 30.0,
        );

        final result = engine.calculatePlug(params);

        expect(result.threadEngagement, equals(20.0)); // 50 - 30 = 20
        expect(result.emptyStroke, equals(210.0)); // 150 + 80 - 50 + 30 = 210
        expect(result.totalStroke, equals(310.0)); // 150 + 80 + 100 - 50 + 30 = 310
      });
    });

    group('螺纹咬合尺寸测试', () {
      test('螺纹咬合尺寸为零', () {
        final params = PlugParameters(
          mValue: 50.0,
          kValue: 30.0,
          nValue: 25.0,
          tValue: 20.0,
          wValue: 20.0, // T = W
        );

        final result = engine.calculatePlug(params);

        expect(result.threadEngagement, equals(0.0));
        expect(result.emptyStroke, equals(80.0)); // 50 + 30 - 20 + 20 = 80
        expect(result.totalStroke, equals(105.0)); // 50 + 30 + 25 - 20 + 20 = 105
      });

      test('螺纹咬合尺寸为负值', () {
        final params = PlugParameters(
          mValue: 50.0,
          kValue: 30.0,
          nValue: 25.0,
          tValue: 15.0,
          wValue: 20.0, // W > T
        );

        final result = engine.calculatePlug(params);

        expect(result.threadEngagement, equals(-5.0)); // 15 - 20 = -5
        expect(result.emptyStroke, equals(85.0)); // 50 + 30 - 15 + 20 = 85
        expect(result.totalStroke, equals(110.0)); // 50 + 30 + 25 - 15 + 20 = 110
      });
    });

    group('异常情况测试', () {
      test('空行程为负值时抛出异常', () {
        final params = PlugParameters(
          mValue: 10.0,
          kValue: 5.0,
          nValue: 25.0,
          tValue: 50.0, // T值过大
          wValue: 5.0,
        );

        expect(
          () => engine.calculatePlug(params),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('总行程为负值时抛出异常', () {
        final params = PlugParameters(
          mValue: 10.0,
          kValue: 5.0,
          nValue: 5.0,
          tValue: 50.0, // T值过大
          wValue: 5.0,
        );

        expect(
          () => engine.calculatePlug(params),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('参数验证失败时抛出异常', () {
        final params = PlugParameters(
          mValue: -10.0, // 负值
          kValue: 30.0,
          nValue: 25.0,
          tValue: 20.0,
          wValue: 15.0,
        );

        expect(
          () => engine.calculatePlug(params),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('精度测试', () {
      test('计算结果精度控制', () {
        final params = PlugParameters(
          mValue: 50.33,
          kValue: 30.67,
          nValue: 25.44,
          tValue: 20.11,
          wValue: 15.22,
        );

        final result = engine.calculatePlug(params);

        // 验证精度控制到0.1mm
        expect(result.threadEngagement, equals(4.9)); // 20.11 - 15.22 = 4.89 ≈ 4.9
        expect(result.emptyStroke, equals(76.1)); // 50.33 + 30.67 - 20.11 + 15.22 = 76.11 ≈ 76.1
        expect(result.totalStroke, equals(101.6)); // 50.33 + 30.67 + 25.44 - 20.11 + 15.22 = 101.55 ≈ 101.6
      });
    });

    group('结果验证测试', () {
      test('结果验证方法', () {
        final params = PlugParameters(
          mValue: 50.0,
          kValue: 30.0,
          nValue: 25.0,
          tValue: 20.0,
          wValue: 15.0,
        );

        final result = engine.calculatePlug(params);
        final validation = result.validateResults();

        expect(validation.isValid, isTrue);
      });

      test('负值结果验证', () {
        final params = PlugParameters(
          mValue: 50.0,
          kValue: 30.0,
          nValue: 25.0,
          tValue: 15.0,
          wValue: 20.0, // W > T，螺纹咬合为负
        );

        final result = engine.calculatePlug(params);
        final validation = result.validateResults();

        // 螺纹咬合为负值时应该有警告
        expect(validation.isWarning, isTrue);
      });
    });

    group('参数检查建议测试', () {
      test('正常参数的建议', () {
        final params = PlugParameters(
          mValue: 50.0,
          kValue: 30.0,
          nValue: 25.0,
          tValue: 20.0,
          wValue: 15.0,
        );

        final result = engine.calculatePlug(params);
        final suggestions = result.getParameterCheckSuggestions();

        expect(suggestions, isNotEmpty);
        expect(suggestions.any((s) => s.contains('计算结果正常')), isTrue);
      });

      test('螺纹咬合为负值时的建议', () {
        final params = PlugParameters(
          mValue: 50.0,
          kValue: 30.0,
          nValue: 25.0,
          tValue: 15.0,
          wValue: 20.0, // W > T
        );

        final result = engine.calculatePlug(params);
        final suggestions = result.getParameterCheckSuggestions();

        expect(suggestions, isNotEmpty);
        expect(suggestions.any((s) => s.contains('螺纹咬合尺寸为负值')), isTrue);
        expect(suggestions.any((s) => s.contains('检查T值是否正确')), isTrue);
      });
    });

    group('安全提示测试', () {
      test('正常情况的安全提示', () {
        final params = PlugParameters(
          mValue: 50.0,
          kValue: 30.0,
          nValue: 25.0,
          tValue: 20.0,
          wValue: 15.0,
        );

        final result = engine.calculatePlug(params);
        final warnings = result.getSafetyWarnings();

        // 正常情况下可能没有特殊警告，或有一般性提示
        expect(warnings, isA<List<String>>());
      });

      test('大行程的安全提示', () {
        final params = PlugParameters(
          mValue: 200.0,
          kValue: 150.0,
          nValue: 100.0,
          tValue: 20.0,
          wValue: 15.0,
        );

        final result = engine.calculatePlug(params);
        final warnings = result.getSafetyWarnings();

        expect(warnings, isNotEmpty);
        expect(warnings.any((w) => w.contains('总行程较大')), isTrue);
      });
    });

    group('计算步骤说明测试', () {
      test('计算步骤详细说明', () {
        final params = PlugParameters(
          mValue: 50.0,
          kValue: 30.0,
          nValue: 25.0,
          tValue: 20.0,
          wValue: 15.0,
        );

        final result = engine.calculatePlug(params);
        final steps = result.getCalculationSteps();

        expect(steps, isNotEmpty);
        expect(steps.containsKey('步骤1'), isTrue);
        expect(steps.containsKey('步骤2'), isTrue);
        expect(steps.containsKey('步骤3'), isTrue);
        expect(steps['步骤1']!.contains('螺纹咬合'), isTrue);
        expect(steps['步骤2']!.contains('空行程'), isTrue);
        expect(steps['步骤3']!.contains('总行程'), isTrue);
      });
    });

    group('JSON序列化测试', () {
      test('结果JSON序列化和反序列化', () {
        final params = PlugParameters(
          mValue: 50.0,
          kValue: 30.0,
          nValue: 25.0,
          tValue: 20.0,
          wValue: 15.0,
        );

        final originalResult = engine.calculatePlug(params);
        final json = originalResult.toJson();
        final deserializedResult = PlugResult.fromJson(json);

        expect(deserializedResult.threadEngagement, equals(originalResult.threadEngagement));
        expect(deserializedResult.emptyStroke, equals(originalResult.emptyStroke));
        expect(deserializedResult.totalStroke, equals(originalResult.totalStroke));
        expect(deserializedResult.calculationType, equals(originalResult.calculationType));
      });

      test('参数JSON序列化和反序列化', () {
        final originalParams = PlugParameters(
          mValue: 50.0,
          kValue: 30.0,
          nValue: 25.0,
          tValue: 20.0,
          wValue: 15.0,
        );

        final json = originalParams.toJson();
        final deserializedParams = PlugParameters.fromJson(json);

        expect(deserializedParams.mValue, equals(originalParams.mValue));
        expect(deserializedParams.kValue, equals(originalParams.kValue));
        expect(deserializedParams.nValue, equals(originalParams.nValue));
        expect(deserializedParams.tValue, equals(originalParams.tValue));
        expect(deserializedParams.wValue, equals(originalParams.wValue));
      });
    });

    group('公式验证测试', () {
      test('公式说明正确性', () {
        final params = PlugParameters(
          mValue: 50.0,
          kValue: 30.0,
          nValue: 25.0,
          tValue: 20.0,
          wValue: 15.0,
        );

        final result = engine.calculatePlug(params);
        final formulas = result.getFormulas();

        expect(formulas['螺纹咬合尺寸'], equals('螺纹咬合尺寸 = T - W'));
        expect(formulas['空行程'], equals('空行程 = M + K - T + W'));
        expect(formulas['总行程'], equals('总行程 = M + K + N - T + W'));
      });

      test('核心结果标识', () {
        final params = PlugParameters(
          mValue: 50.0,
          kValue: 30.0,
          nValue: 25.0,
          tValue: 20.0,
          wValue: 15.0,
        );

        final result = engine.calculatePlug(params);
        final coreResults = result.getCoreResults();

        expect(coreResults.containsKey('螺纹咬合尺寸'), isTrue);
        expect(coreResults.containsKey('空行程'), isTrue);
        expect(coreResults.containsKey('总行程'), isTrue);
        expect(coreResults['螺纹咬合尺寸'], equals(5.0));
        expect(coreResults['空行程'], equals(75.0));
        expect(coreResults['总行程'], equals(100.0));
      });
    });
  });
}