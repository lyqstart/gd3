import 'package:flutter_test/flutter_test.dart';
import 'package:pipeline_calculation_app/services/calculation_engine.dart';
import 'package:pipeline_calculation_app/models/calculation_parameters.dart';
import 'package:pipeline_calculation_app/models/calculation_result.dart';

/// 手动开孔计算单元测试
/// 
/// 验证需求: 2.1, 2.2, 2.3, 2.4
void main() {
  group('手动开孔计算测试', () {
    late PrecisionCalculationEngine engine;

    setUp(() {
      engine = PrecisionCalculationEngine();
    });

    group('具体计算示例测试', () {
      test('标准手动开孔计算示例', () {
        // **功能: pipeline-calculation-app, 任务 5.1: 实现手动开孔计算**
        // **验证需求: 2.1, 2.2, 2.3, 2.4**
        
        final params = ManualHoleParameters(
          lValue: 80.0,    // L值
          jValue: 40.0,    // J值
          pValue: 25.0,    // P值
          tValue: 30.0,    // T值
          wValue: 20.0,    // W值
        );

        final result = engine.calculateManualHole(params);

        // 验证螺纹咬合尺寸: T - W = 30.0 - 20.0 = 10.0mm
        expect(result.threadEngagement, equals(10.0));

        // 验证空行程: L + J + T + W = 80.0 + 40.0 + 30.0 + 20.0 = 170.0mm
        expect(result.emptyStroke, equals(170.0));

        // 验证总行程: L + J + T + W + P = 80.0 + 40.0 + 30.0 + 20.0 + 25.0 = 195.0mm
        expect(result.totalStroke, equals(195.0));

        // 验证计算时间和参数保存
        expect(result.calculationTime, isNotNull);
        expect(result.manualHoleParameters, equals(params));
        expect(result.id, isNotEmpty);
      });

      test('螺纹咬合尺寸为负值的情况', () {
        // 测试T值小于W值的情况
        final params = ManualHoleParameters(
          lValue: 100.0,
          jValue: 50.0,
          pValue: 30.0,
          tValue: 15.0,    // T值小于W值
          wValue: 25.0,
        );

        final result = engine.calculateManualHole(params);

        // 验证螺纹咬合尺寸: T - W = 15.0 - 25.0 = -10.0mm
        expect(result.threadEngagement, equals(-10.0));

        // 验证空行程: L + J + T + W = 100.0 + 50.0 + 15.0 + 25.0 = 190.0mm
        expect(result.emptyStroke, equals(190.0));

        // 验证总行程: L + J + T + W + P = 100.0 + 50.0 + 15.0 + 25.0 + 30.0 = 220.0mm
        expect(result.totalStroke, equals(220.0));
      });

      test('最小参数值计算', () {
        final params = ManualHoleParameters(
          lValue: 10.0,    // 最小L值
          jValue: 5.0,     // 最小J值
          pValue: 2.0,     // 最小P值
          tValue: 8.0,     // T值
          wValue: 3.0,     // W值
        );

        final result = engine.calculateManualHole(params);

        // 验证螺纹咬合尺寸: 8.0 - 3.0 = 5.0mm
        expect(result.threadEngagement, equals(5.0));

        // 验证空行程: 10.0 + 5.0 + 8.0 + 3.0 = 26.0mm
        expect(result.emptyStroke, equals(26.0));

        // 验证总行程: 10.0 + 5.0 + 8.0 + 3.0 + 2.0 = 28.0mm
        expect(result.totalStroke, equals(28.0));
      });

      test('大数值参数计算', () {
        final params = ManualHoleParameters(
          lValue: 500.0,   // 大L值
          jValue: 300.0,   // 大J值
          pValue: 200.0,   // 大P值
          tValue: 150.0,   // 大T值
          wValue: 100.0,   // 大W值
        );

        final result = engine.calculateManualHole(params);

        // 验证螺纹咬合尺寸: 150.0 - 100.0 = 50.0mm
        expect(result.threadEngagement, equals(50.0));

        // 验证空行程: 500.0 + 300.0 + 150.0 + 100.0 = 1050.0mm
        expect(result.emptyStroke, equals(1050.0));

        // 验证总行程: 500.0 + 300.0 + 150.0 + 100.0 + 200.0 = 1250.0mm
        expect(result.totalStroke, equals(1250.0));

        // 验证结果在合理范围内
        expect(result.totalStroke, lessThan(10000.0));
        expect(result.totalStroke, greaterThan(result.emptyStroke));
      });
    });

    group('参数验证测试', () {
      test('有效参数验证', () {
        final params = ManualHoleParameters(
          lValue: 80.0,
          jValue: 40.0,
          pValue: 25.0,
          tValue: 30.0,
          wValue: 20.0,
        );

        final validation = params.validate();
        expect(validation.isValid, isTrue);
      });

      test('负数参数验证', () {
        final params = ManualHoleParameters(
          lValue: -10.0,   // 负L值
          jValue: 40.0,
          pValue: 25.0,
          tValue: 30.0,
          wValue: 20.0,
        );

        final validation = params.validate();
        expect(validation.isValid, isFalse);
        expect(validation.message, contains('L值必须大于0'));
      });

      test('零值参数验证', () {
        final params = ManualHoleParameters(
          lValue: 0.0,     // 零L值
          jValue: 40.0,
          pValue: 25.0,
          tValue: 30.0,
          wValue: 20.0,
        );

        final validation = params.validate();
        expect(validation.isValid, isFalse);
        expect(validation.message, contains('L值必须大于0'));
      });

      test('螺纹咬合参数验证', () {
        // 测试T值和W值的验证
        final params1 = ManualHoleParameters(
          lValue: 80.0,
          jValue: 40.0,
          pValue: 25.0,
          tValue: -5.0,    // 负T值
          wValue: 20.0,
        );

        final validation1 = params1.validate();
        expect(validation1.isValid, isFalse);

        final params2 = ManualHoleParameters(
          lValue: 80.0,
          jValue: 40.0,
          pValue: 25.0,
          tValue: 30.0,
          wValue: -10.0,   // 负W值
        );

        final validation2 = params2.validate();
        expect(validation2.isValid, isFalse);
      });
    });

    group('公式正确性验证', () {
      test('验证所有公式的数学正确性', () {
        final params = ManualHoleParameters(
          lValue: 120.0,
          jValue: 60.0,
          pValue: 35.0,
          tValue: 40.0,
          wValue: 25.0,
        );

        final result = engine.calculateManualHole(params);

        // 手动计算验证
        final expectedThreadEngagement = 40.0 - 25.0; // 15.0mm
        expect(result.threadEngagement, equals(expectedThreadEngagement));

        final expectedEmptyStroke = 120.0 + 60.0 + 40.0 + 25.0; // 245.0mm
        expect(result.emptyStroke, equals(expectedEmptyStroke));

        final expectedTotalStroke = 120.0 + 60.0 + 40.0 + 25.0 + 35.0; // 280.0mm
        expect(result.totalStroke, equals(expectedTotalStroke));

        // 验证逻辑关系
        expect(result.totalStroke, greaterThan(result.emptyStroke));
        expect(result.totalStroke - result.emptyStroke, equals(params.pValue));
      });

      test('验证精度控制 - 0.1mm精度', () {
        final params = ManualHoleParameters(
          lValue: 80.5,    // 带小数的参数
          jValue: 40.3,
          pValue: 25.7,
          tValue: 30.2,
          wValue: 20.1,
        );

        final result = engine.calculateManualHole(params);

        // 验证所有结果都符合0.1mm精度要求
        expect(_checkPrecision(result.threadEngagement), isTrue);
        expect(_checkPrecision(result.emptyStroke), isTrue);
        expect(_checkPrecision(result.totalStroke), isTrue);
      });
    });

    group('结果对象测试', () {
      test('验证ManualHoleResult的核心功能', () {
        final params = ManualHoleParameters(
          lValue: 80.0,
          jValue: 40.0,
          pValue: 25.0,
          tValue: 30.0,
          wValue: 20.0,
        );

        final result = engine.calculateManualHole(params);

        // 测试核心结果获取
        final coreResults = result.getCoreResults();
        expect(coreResults, isNotNull);
        expect(coreResults.containsKey('螺纹咬合尺寸'), isTrue);
        expect(coreResults.containsKey('空行程'), isTrue);
        expect(coreResults.containsKey('总行程'), isTrue);

        // 测试公式获取
        final formulas = result.getFormulas();
        expect(formulas, isNotNull);
        expect(formulas.containsKey('螺纹咬合尺寸'), isTrue);
        expect(formulas.containsKey('空行程'), isTrue);
        expect(formulas.containsKey('总行程'), isTrue);

        // 验证公式内容
        expect(formulas['螺纹咬合尺寸'], equals('螺纹咬合尺寸 = T - W'));
        expect(formulas['空行程'], equals('空行程 = L + J + T + W'));
        expect(formulas['总行程'], equals('总行程 = L + J + T + W + P'));
      });

      test('验证JSON序列化和反序列化', () {
        final params = ManualHoleParameters(
          lValue: 80.0,
          jValue: 40.0,
          pValue: 25.0,
          tValue: 30.0,
          wValue: 20.0,
        );

        final result = engine.calculateManualHole(params);

        // 测试JSON序列化
        final json = result.toJson();
        expect(json, isNotNull);
        expect(json['calculation_type'], equals('manual_hole'));
        expect(json['results'], isNotNull);

        // 测试反序列化
        final deserializedResult = ManualHoleResult.fromJson(json);
        expect(deserializedResult.threadEngagement, equals(result.threadEngagement));
        expect(deserializedResult.emptyStroke, equals(result.emptyStroke));
        expect(deserializedResult.totalStroke, equals(result.totalStroke));
      });

      test('验证参数访问器', () {
        final params = ManualHoleParameters(
          lValue: 80.0,
          jValue: 40.0,
          pValue: 25.0,
          tValue: 30.0,
          wValue: 20.0,
        );

        final result = engine.calculateManualHole(params);

        // 测试类型安全的参数访问器
        final manualParams = result.manualHoleParameters;
        expect(manualParams, isNotNull);
        expect(manualParams.lValue, equals(80.0));
        expect(manualParams.jValue, equals(40.0));
        expect(manualParams.pValue, equals(25.0));
        expect(manualParams.tValue, equals(30.0));
        expect(manualParams.wValue, equals(20.0));
      });
    });

    group('边界条件和错误处理', () {
      test('计算引擎异常处理', () {
        // 测试无效参数导致的计算异常
        final invalidParams = ManualHoleParameters(
          lValue: -10.0,   // 无效参数
          jValue: 40.0,
          pValue: 25.0,
          tValue: 30.0,
          wValue: 20.0,
        );

        expect(() => engine.calculateManualHole(invalidParams), 
               throwsA(isA<ArgumentError>()));
      });

      test('极值参数处理', () {
        // 测试极小值
        final minParams = ManualHoleParameters(
          lValue: 0.1,
          jValue: 0.1,
          pValue: 0.1,
          tValue: 0.2,
          wValue: 0.1,
        );

        final minResult = engine.calculateManualHole(minParams);
        expect(minResult.threadEngagement, equals(0.1));
        expect(minResult.emptyStroke, equals(0.5));
        expect(minResult.totalStroke, equals(0.6));

        // 测试极大值
        final maxParams = ManualHoleParameters(
          lValue: 9999.0,
          jValue: 9999.0,
          pValue: 9999.0,
          tValue: 9999.0,
          wValue: 1.0,
        );

        final maxResult = engine.calculateManualHole(maxParams);
        expect(maxResult.threadEngagement, equals(9998.0));
        expect(maxResult.emptyStroke, equals(29998.0)); // L + J + T + W = 9999 + 9999 + 9999 + 1 = 29998
        expect(maxResult.totalStroke, equals(39997.0)); // L + J + T + W + P = 9999 + 9999 + 9999 + 1 + 9999 = 39997
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