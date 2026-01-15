import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pipeline_calculation_app/services/parameter_service.dart';
import 'package:pipeline_calculation_app/services/parameter_manager.dart';
import 'package:pipeline_calculation_app/models/parameter_models.dart';
import 'package:pipeline_calculation_app/models/calculation_parameters.dart';
import 'package:pipeline_calculation_app/models/enums.dart';
import 'package:pipeline_calculation_app/utils/unit_converter.dart';
import 'dart:math' as math;

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
    final outerDiameter = 50.0 + _random.nextDouble() * 200.0;
    final innerDiameter = outerDiameter - 5.0 - _random.nextDouble() * 15.0; // 确保内径小于外径
    final cutterOuterDiameter = 10.0 + _random.nextDouble() * 40.0;
    final cutterInnerDiameter = cutterOuterDiameter - 2.0 - _random.nextDouble() * 8.0; // 确保内径小于外径
    
    return HoleParameters(
      outerDiameter: outerDiameter,
      innerDiameter: innerDiameter,
      cutterOuterDiameter: cutterOuterDiameter,
      cutterInnerDiameter: cutterInnerDiameter,
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

void main() {
  // 初始化FFI数据库工厂用于测试
  setUpAll(() {
    // 初始化FFI
    sqfliteFfiInit();
    // 设置数据库工厂
    databaseFactory = databaseFactoryFfi;
  });

  group('参数管理属性测试', () {
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
          expect(difference, lessThan(1e-3),
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
          expect(inchDifference, lessThan(1e-3),
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
            
            expect(difference, lessThan(1e-3),
                   reason: '参数 $key 的往返转换精度损失过大，迭代 $i，原值: $originalValue，回转值: $backValue');
          }
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
      });
    });
  });
}