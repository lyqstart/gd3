import 'package:flutter_test/flutter_test.dart';
import 'package:pipeline_calculation_app/models/calculation_parameters.dart';
import 'package:pipeline_calculation_app/models/validation_result.dart';
import 'package:pipeline_calculation_app/models/enums.dart';

void main() {
  group('开孔参数验证测试', () {
    test('基本参数验证', () {
      // 测试有效参数
      final validParams = HoleParameters(
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

      final validation = validParams.validate();
      expect(validation.isValid, isTrue);
    });

    test('管道参数逻辑验证', () {
      // 测试管外径小于等于管内径的情况
      final invalidParams = HoleParameters(
        outerDiameter: 100.0,
        innerDiameter: 110.0, // 内径大于外径
        cutterOuterDiameter: 25.4,
        cutterInnerDiameter: 19.1,
        aValue: 50.0,
        bValue: 30.0,
        rValue: 15.0,
        initialValue: 10.0,
        gasketThickness: 3.0,
      );

      final validation = invalidParams.validate();
      expect(validation.isValid, isFalse);
      expect(validation.message, contains('管外径必须大于管内径'));
    });

    test('筒刀参数逻辑验证', () {
      // 测试筒刀外径小于等于筒刀内径的情况
      final invalidParams = HoleParameters(
        outerDiameter: 114.3,
        innerDiameter: 102.3,
        cutterOuterDiameter: 20.0,
        cutterInnerDiameter: 25.0, // 内径大于外径
        aValue: 50.0,
        bValue: 30.0,
        rValue: 15.0,
        initialValue: 10.0,
        gasketThickness: 3.0,
      );

      final validation = invalidParams.validate();
      expect(validation.isValid, isFalse);
      expect(validation.message, contains('筒刀外径必须大于筒刀内径'));
    });

    test('开孔特定验证规则', () {
      // 测试筒刀内径大于等于管内径的情况
      final warningParams = HoleParameters(
        outerDiameter: 114.3,
        innerDiameter: 102.3,
        cutterOuterDiameter: 25.4,
        cutterInnerDiameter: 105.0, // 筒刀内径大于管内径
        aValue: 50.0,
        bValue: 30.0,
        rValue: 15.0,
        initialValue: 10.0,
        gasketThickness: 3.0,
      );

      final validation = warningParams.validate();
      expect(validation.isValid, isFalse);
      expect(validation.message, contains('筒刀内径'));
      expect(validation.message, contains('管内径'));
    });

    test('参数范围警告验证', () {
      // 测试A值过小的警告
      final smallAParams = HoleParameters(
        outerDiameter: 114.3,
        innerDiameter: 102.3,
        cutterOuterDiameter: 25.4,
        cutterInnerDiameter: 19.1,
        aValue: 5.0, // A值过小
        bValue: 30.0,
        rValue: 15.0,
        initialValue: 10.0,
        gasketThickness: 3.0,
      );

      final validation = smallAParams.validate();
      // 应该有警告但仍然有效
      expect(validation.type, ValidationResultType.warning);
      expect(validation.message, contains('A值较小'));
    });

    test('负数参数验证', () {
      // 测试负数参数
      final negativeParams = HoleParameters(
        outerDiameter: 114.3,
        innerDiameter: 102.3,
        cutterOuterDiameter: 25.4,
        cutterInnerDiameter: 19.1,
        aValue: -10.0, // 负数
        bValue: 30.0,
        rValue: 15.0,
        initialValue: 10.0,
        gasketThickness: 3.0,
      );

      final validation = negativeParams.validate();
      expect(validation.isValid, isFalse);
      expect(validation.message, contains('A值必须大于0'));
    });

    test('零值参数验证', () {
      // 测试允许零值的参数
      final zeroParams = HoleParameters(
        outerDiameter: 114.3,
        innerDiameter: 102.3,
        cutterOuterDiameter: 25.4,
        cutterInnerDiameter: 19.1,
        aValue: 50.0,
        bValue: 30.0,
        rValue: 15.0,
        initialValue: 0.0, // 允许为零
        gasketThickness: 0.0, // 允许为零
      );

      final validation = zeroParams.validate();
      expect(validation.isValid, isTrue);
    });
  });
}