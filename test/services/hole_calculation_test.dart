import 'package:flutter_test/flutter_test.dart';
import 'package:pipeline_calculation_app/services/calculation_engine.dart';
import 'package:pipeline_calculation_app/models/calculation_parameters.dart';
import 'package:pipeline_calculation_app/models/calculation_result.dart';
import 'dart:math' as math;

/// 开孔计算单元测试
/// 
/// 测试具体计算示例、边界条件和错误情况
/// 验证所有公式的正确性
void main() {
  group('开孔计算单元测试', () {
    late PrecisionCalculationEngine engine;

    setUp(() {
      engine = PrecisionCalculationEngine();
    });

    group('具体计算示例测试', () {
      test('标准开孔计算示例 - 114.3mm管道', () {
        // **功能: pipeline-calculation-app, 任务 4.3: 为开孔计算编写单元测试**
        // **验证需求: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7**
        
        // 使用实际工程中常见的114.3mm管道参数
        final params = HoleParameters(
          outerDiameter: 114.3,      // 管外径
          innerDiameter: 102.3,      // 管内径
          cutterOuterDiameter: 25.4, // 筒刀外径 (1英寸)
          cutterInnerDiameter: 19.1, // 筒刀内径
          aValue: 50.0,              // A值 - 中心钻关联联箱口
          bValue: 30.0,              // B值 - 夹板顶到管外壁
          rValue: 15.0,              // R值 - 中心钻尖到筒刀
          initialValue: 10.0,        // 初始值
          gasketThickness: 3.0,      // 垫片厚度
        );

        final result = engine.calculateHoleSize(params);

        // 验证空行程计算: S空 = A + B + 初始值 + 垫片厚度
        // S空 = 50.0 + 30.0 + 10.0 + 3.0 = 93.0mm
        expect(result.emptyStroke, equals(93.0));

        // 验证管道壁厚区域计算: √(114.3² - 102.3²)
        final expectedPipeWallArea = math.sqrt(114.3 * 114.3 - 102.3 * 102.3);
        expect(expectedPipeWallArea, closeTo(50.98, 1.0)); // 实际约50.98mm

        // 验证筒刀切削距离: C1 = √(管外径² - 管内径²) - 筒刀外径
        // C1 = 50.98 - 25.4 = 25.58mm
        expect(result.cuttingDistance, closeTo(25.6, 0.1));

        // 验证掉板弦高: C2 = √(管外径² - 管内径²) - 筒刀内径
        // C2 = 50.98 - 19.1 = 31.88mm
        expect(result.chordHeight, closeTo(31.9, 0.1));

        // 验证切削尺寸: C = R + C1
        // C = 15.0 + 25.6 = 40.6mm
        expect(result.cuttingSize, closeTo(40.6, 0.1));

        // 验证开孔总行程: S总 = S空 + C
        // S总 = 93.0 + 40.6 = 133.6mm
        expect(result.totalStroke, closeTo(133.6, 0.1));

        // 验证掉板总行程: S掉板 = S总 + R + C2
        // S掉板 = 133.6 + 15.0 + 31.9 = 180.5mm
        expect(result.plateStroke, closeTo(180.5, 0.1));

        // 验证计算时间和参数保存
        expect(result.calculationTime, isNotNull);
        expect(result.holeParameters, equals(params));
        expect(result.id, isNotEmpty);
      });

      test('大口径管道计算示例 - 508mm管道', () {
        // 测试大口径管道的计算
        final params = HoleParameters(
          outerDiameter: 508.0,      // 20英寸管道
          innerDiameter: 482.6,      // 内径
          cutterOuterDiameter: 50.8, // 2英寸筒刀
          cutterInnerDiameter: 38.1, // 筒刀内径
          aValue: 80.0,
          bValue: 50.0,
          rValue: 25.0,
          initialValue: 15.0,
          gasketThickness: 5.0,
        );

        final result = engine.calculateHoleSize(params);

        // 验证空行程: 80 + 50 + 15 + 5 = 150mm
        expect(result.emptyStroke, equals(150.0));

        // 验证管道壁厚区域: √(508² - 482.6²)
        final expectedPipeWallArea = math.sqrt(508.0 * 508.0 - 482.6 * 482.6);
        expect(expectedPipeWallArea, closeTo(158.6, 1.0)); // 实际约158.6mm

        // 验证筒刀切削距离: 158.6 - 50.8 = 107.8mm
        expect(result.cuttingDistance, closeTo(107.8, 0.1));

        // 验证切削尺寸: 25 + 107.8 = 132.8mm
        expect(result.cuttingSize, closeTo(132.8, 0.1));

        // 验证开孔总行程: 150 + 132.8 = 282.8mm
        expect(result.totalStroke, closeTo(282.8, 0.1));

        // 验证结果的合理性
        expect(result.totalStroke, greaterThan(result.emptyStroke));
        expect(result.plateStroke, greaterThan(result.totalStroke));
      });

      test('小口径管道计算示例 - 60.3mm管道', () {
        // 测试小口径管道的计算
        final params = HoleParameters(
          outerDiameter: 60.3,       // 2英寸管道
          innerDiameter: 52.5,       // 内径
          cutterOuterDiameter: 12.7, // 0.5英寸筒刀
          cutterInnerDiameter: 9.5,  // 筒刀内径
          aValue: 30.0,
          bValue: 20.0,
          rValue: 10.0,
          initialValue: 5.0,
          gasketThickness: 2.0,
        );

        final result = engine.calculateHoleSize(params);

        // 验证空行程: 30 + 20 + 5 + 2 = 57mm
        expect(result.emptyStroke, equals(57.0));

        // 验证管道壁厚区域计算
        final expectedPipeWallArea = math.sqrt(60.3 * 60.3 - 52.5 * 52.5);
        expect(expectedPipeWallArea, closeTo(29.7, 0.5)); // 实际约29.7mm

        // 验证筒刀切削距离: 29.7 - 12.7 = 17.0mm
        expect(result.cuttingDistance, closeTo(17.0, 0.1));

        // 验证切削尺寸: 10 + 17.0 = 27.0mm
        expect(result.cuttingSize, closeTo(27.0, 0.1));

        // 验证开孔总行程: 57 + 27.0 = 84.0mm
        expect(result.totalStroke, closeTo(84.0, 0.1));
      });
    });

    group('边界条件测试', () {
      test('最小有效参数测试', () {
        // 测试接近最小值的参数
        final params = HoleParameters(
          outerDiameter: 21.3,       // 最小常用管径
          innerDiameter: 15.8,       // 内径
          cutterOuterDiameter: 6.4,  // 小筒刀
          cutterInnerDiameter: 4.8,  // 筒刀内径
          aValue: 10.0,              // 最小A值
          bValue: 5.0,               // 最小B值
          rValue: 5.0,               // 最小R值
          initialValue: 0.0,         // 零初始值
          gasketThickness: 0.0,      // 无垫片
        );

        final result = engine.calculateHoleSize(params);

        // 验证计算能够正常完成
        expect(result.emptyStroke, equals(15.0)); // 10 + 5 + 0 + 0 = 15
        expect(result.cuttingDistance, greaterThan(0));
        expect(result.totalStroke, greaterThan(result.emptyStroke));
        expect(result.plateStroke, greaterThan(result.totalStroke));

        // 验证所有结果都是有限数值
        expect(result.emptyStroke.isFinite, isTrue);
        expect(result.cuttingDistance.isFinite, isTrue);
        expect(result.chordHeight.isFinite, isTrue);
        expect(result.cuttingSize.isFinite, isTrue);
        expect(result.totalStroke.isFinite, isTrue);
        expect(result.plateStroke.isFinite, isTrue);
      });

      test('筒刀过大的边界情况', () {
        // 测试筒刀外径接近管道壁厚区域的情况
        final params = HoleParameters(
          outerDiameter: 60.3,
          innerDiameter: 52.5,
          cutterOuterDiameter: 25.0, // 接近管道壁厚区域
          cutterInnerDiameter: 20.0,
          aValue: 50.0,
          bValue: 30.0,
          rValue: 15.0,
          initialValue: 10.0,
          gasketThickness: 3.0,
        );

        // 应该能够计算，但可能产生警告
        final result = engine.calculateHoleSize(params);
        
        // 验证计算完成
        expect(result, isNotNull);
        expect(result.emptyStroke, equals(93.0)); // 50 + 30 + 10 + 3 = 93
        
        // 筒刀切削距离可能为负值，但计算应该继续
        expect(result.cuttingDistance.isFinite, isTrue);
      });

      test('零值和负值处理', () {
        // 测试包含零值的参数（允许零值的参数）
        final params = HoleParameters(
          outerDiameter: 114.3,
          innerDiameter: 102.3,
          cutterOuterDiameter: 25.4,
          cutterInnerDiameter: 19.1,
          aValue: 10.0,              // 最小正值A值
          bValue: 10.0,              // 最小正值B值
          rValue: 5.0,               // 最小正值R值
          initialValue: 0.0,         // 零初始值（允许）
          gasketThickness: 0.0,      // 零垫片厚度（允许）
        );

        final result = engine.calculateHoleSize(params);

        // 验证空行程: 10 + 10 + 0 + 0 = 20mm
        expect(result.emptyStroke, equals(20.0));
        
        // 验证其他计算仍然有效
        expect(result.cuttingDistance.isFinite, isTrue);
        expect(result.chordHeight.isFinite, isTrue);
        expect(result.totalStroke.isFinite, isTrue);
        expect(result.plateStroke.isFinite, isTrue);
      });

      test('大数值参数测试', () {
        // 测试较大的参数值
        final params = HoleParameters(
          outerDiameter: 1219.2,     // 48英寸管道
          innerDiameter: 1193.8,     // 内径
          cutterOuterDiameter: 101.6, // 4英寸筒刀
          cutterInnerDiameter: 76.2,  // 筒刀内径
          aValue: 200.0,
          bValue: 150.0,
          rValue: 100.0,
          initialValue: 50.0,
          gasketThickness: 20.0,
        );

        final result = engine.calculateHoleSize(params);

        // 验证空行程: 200 + 150 + 50 + 20 = 420mm
        expect(result.emptyStroke, equals(420.0));

        // 验证结果在合理范围内
        expect(result.totalStroke, lessThan(10000.0)); // 不超过10米
        expect(result.plateStroke, lessThan(10000.0));
        
        // 验证结果的逻辑关系
        expect(result.totalStroke, greaterThan(result.emptyStroke));
        expect(result.plateStroke, greaterThan(result.totalStroke));
      });
    });

    group('错误情况测试', () {
      test('无效管道参数 - 外径小于内径', () {
        final params = HoleParameters(
          outerDiameter: 50.0,       // 外径小于内径
          innerDiameter: 60.0,
          cutterOuterDiameter: 25.4,
          cutterInnerDiameter: 19.1,
          aValue: 50.0,
          bValue: 30.0,
          rValue: 15.0,
          initialValue: 10.0,
          gasketThickness: 3.0,
        );
        
        // 参数验证应该失败
        final validation = params.validate();
        expect(validation.isValid, isFalse);
        expect(validation.message, contains('管外径必须大于管内径'));
      });

      test('无效筒刀参数 - 外径小于内径', () {
        final params = HoleParameters(
          outerDiameter: 114.3,
          innerDiameter: 102.3,
          cutterOuterDiameter: 19.1, // 筒刀外径小于内径
          cutterInnerDiameter: 25.4,
          aValue: 50.0,
          bValue: 30.0,
          rValue: 15.0,
          initialValue: 10.0,
          gasketThickness: 3.0,
        );
        
        // 参数验证应该失败
        final validation = params.validate();
        expect(validation.isValid, isFalse);
        expect(validation.message, contains('筒刀外径必须大于筒刀内径'));
      });

      test('负数参数验证', () {
        final params = HoleParameters(
          outerDiameter: 114.3,
          innerDiameter: 102.3,
          cutterOuterDiameter: 25.4,
          cutterInnerDiameter: 19.1,
          aValue: -10.0,             // 负A值
          bValue: 30.0,
          rValue: 15.0,
          initialValue: 10.0,
          gasketThickness: 3.0,
        );
        
        // 参数验证应该失败
        final validation = params.validate();
        expect(validation.isValid, isFalse);
        expect(validation.message, contains('A值必须大于0'));
      });

      test('筒刀内径大于管内径的错误', () {
        expect(() {
          final params = HoleParameters(
            outerDiameter: 60.3,
            innerDiameter: 52.5,
            cutterOuterDiameter: 25.4,
            cutterInnerDiameter: 55.0, // 筒刀内径大于管内径
            aValue: 50.0,
            bValue: 30.0,
            rValue: 15.0,
            initialValue: 10.0,
            gasketThickness: 3.0,
          );
          
          // 参数验证应该失败
          final validation = params.validate();
          expect(validation.isValid, isFalse);
        }, returnsNormally);
      });
    });

    group('公式正确性验证', () {
      test('验证所有公式的数学正确性', () {
        final params = HoleParameters(
          outerDiameter: 168.3,      // 6英寸管道
          innerDiameter: 154.1,      // 内径
          cutterOuterDiameter: 31.8, // 1.25英寸筒刀
          cutterInnerDiameter: 25.4, // 1英寸筒刀内径
          aValue: 60.0,
          bValue: 40.0,
          rValue: 20.0,
          initialValue: 12.0,
          gasketThickness: 4.0,
        );

        final result = engine.calculateHoleSize(params);

        // 手动计算验证
        final expectedEmptyStroke = 60.0 + 40.0 + 12.0 + 4.0; // 116.0mm
        expect(result.emptyStroke, equals(expectedEmptyStroke));

        // 管道壁厚区域计算
        final pipeWallArea = math.sqrt(168.3 * 168.3 - 154.1 * 154.1);
        expect(pipeWallArea, closeTo(67.7, 1.0)); // 实际约67.7mm

        // 筒刀切削距离: pipeWallArea - 31.8
        final expectedCuttingDistance = pipeWallArea - 31.8;
        expect(result.cuttingDistance, closeTo(expectedCuttingDistance, 0.1));

        // 掉板弦高: pipeWallArea - 25.4
        final expectedChordHeight = pipeWallArea - 25.4;
        expect(result.chordHeight, closeTo(expectedChordHeight, 0.1));

        // 切削尺寸: 20.0 + expectedCuttingDistance
        final expectedCuttingSize = 20.0 + expectedCuttingDistance;
        expect(result.cuttingSize, closeTo(expectedCuttingSize, 0.1));

        // 开孔总行程: expectedEmptyStroke + expectedCuttingSize
        final expectedTotalStroke = expectedEmptyStroke + expectedCuttingSize;
        expect(result.totalStroke, closeTo(expectedTotalStroke, 0.1));

        // 掉板总行程: expectedTotalStroke + 20.0 + expectedChordHeight
        final expectedPlateStroke = expectedTotalStroke + 20.0 + expectedChordHeight;
        expect(result.plateStroke, closeTo(expectedPlateStroke, 0.1));
      });

      test('验证精度控制 - 0.1mm精度', () {
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

        final result = engine.calculateHoleSize(params);

        // 验证所有结果都符合0.1mm精度要求
        expect(_checkPrecision(result.emptyStroke), isTrue);
        expect(_checkPrecision(result.cuttingDistance), isTrue);
        expect(_checkPrecision(result.chordHeight), isTrue);
        expect(_checkPrecision(result.cuttingSize), isTrue);
        expect(_checkPrecision(result.totalStroke), isTrue);
        expect(_checkPrecision(result.plateStroke), isTrue);
      });

      test('验证计算结果的JSON序列化', () {
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

        final result = engine.calculateHoleSize(params);
        
        // 测试JSON序列化和反序列化
        final json = result.toJson();
        expect(json, isNotNull);
        expect(json['calculation_type'], equals('hole'));
        expect(json['results'], isNotNull);
        
        // 测试反序列化
        final deserializedResult = HoleCalculationResult.fromJson(json);
        expect(deserializedResult.emptyStroke, equals(result.emptyStroke));
        expect(deserializedResult.totalStroke, equals(result.totalStroke));
        expect(deserializedResult.plateStroke, equals(result.plateStroke));
      });
    });

    group('结果验证和安全检查', () {
      test('验证计算结果的合理性检查', () {
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

        final result = engine.calculateHoleSize(params);
        
        // 测试结果验证方法
        final validation = result.validateResults();
        expect(validation, isNotNull);
        
        // 测试安全警告
        final warnings = result.getSafetyWarnings();
        expect(warnings, isNotNull);
        expect(warnings, isA<List<String>>());
        
        // 测试计算步骤说明
        final steps = result.getCalculationSteps();
        expect(steps, isNotNull);
        expect(steps.length, equals(7)); // 7个计算步骤
      });

      test('验证核心结果获取', () {
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

        final result = engine.calculateHoleSize(params);
        
        // 测试核心结果获取
        final coreResults = result.getCoreResults();
        expect(coreResults, isNotNull);
        expect(coreResults.containsKey('空行程'), isTrue);
        expect(coreResults.containsKey('开孔总行程'), isTrue);
        expect(coreResults.containsKey('掉板总行程'), isTrue);
        
        // 测试公式获取
        final formulas = result.getFormulas();
        expect(formulas, isNotNull);
        expect(formulas.length, greaterThan(5));
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