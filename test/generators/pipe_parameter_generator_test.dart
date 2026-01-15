import 'package:test/test.dart';
import 'dart:math' as math;

import 'pipe_parameter_generator.dart';
import '../../lib/models/calculation_parameters.dart';
import '../../lib/models/enums.dart';
import '../../lib/utils/constants.dart';

void main() {
  group('PipeParameterGenerator 测试', () {
    group('有效参数生成测试', () {
      test('生成有效的开孔参数', () {
        for (int i = 0; i < 50; i++) {
          final params = PipeParameterGenerator.generateValidHoleParameters();
          final validation = params.validate();
          
          // 验证参数基本有效性
          expect(params.outerDiameter, greaterThan(0));
          expect(params.innerDiameter, greaterThan(0));
          expect(params.outerDiameter, greaterThan(params.innerDiameter));
          expect(params.cutterOuterDiameter, greaterThan(0));
          expect(params.cutterInnerDiameter, greaterThan(0));
          expect(params.cutterOuterDiameter, greaterThan(params.cutterInnerDiameter));
          expect(params.aValue, greaterThanOrEqualTo(0));
          expect(params.bValue, greaterThanOrEqualTo(0));
          expect(params.rValue, greaterThanOrEqualTo(0));
          expect(params.initialValue, greaterThanOrEqualTo(0));
          expect(params.gasketThickness, greaterThanOrEqualTo(0));
          
          // 验证参数在合理范围内
          expect(params.outerDiameter, lessThanOrEqualTo(2000.0));
          expect(params.innerDiameter, lessThanOrEqualTo(params.outerDiameter));
          expect(params.cutterInnerDiameter, lessThan(params.innerDiameter));
          
          // 验证精度
          expect(_isPrecisionMaintained(params.outerDiameter), isTrue);
          expect(_isPrecisionMaintained(params.innerDiameter), isTrue);
          expect(_isPrecisionMaintained(params.cutterOuterDiameter), isTrue);
          expect(_isPrecisionMaintained(params.cutterInnerDiameter), isTrue);
          
          // 验证参数验证结果（应该是有效的或只有警告）
          expect(validation.isValid, isTrue,
              reason: '生成的参数应该是有效的: ${validation.message}');
        }
      });
      
      test('生成有效的手动开孔参数', () {
        for (int i = 0; i < 50; i++) {
          final params = PipeParameterGenerator.generateValidManualHoleParameters();
          final validation = params.validate();
          
          // 验证参数基本有效性
          expect(params.lValue, greaterThan(0));
          expect(params.jValue, greaterThan(0));
          expect(params.pValue, greaterThan(0));
          expect(params.tValue, greaterThan(0));
          expect(params.wValue, greaterThan(0));
          
          // 验证螺纹咬合尺寸为正
          expect(params.tValue - params.wValue, greaterThanOrEqualTo(0));
          
          // 验证参数验证结果
          expect(validation.isValid, isTrue,
              reason: '生成的手动开孔参数应该是有效的: ${validation.message}');
        }
      });
      
      test('生成有效的封堵参数', () {
        for (int i = 0; i < 50; i++) {
          final params = PipeParameterGenerator.generateValidSealingParameters();
          final validation = params.validate();
          
          // 验证参数基本有效性
          expect(params.rValue, greaterThan(0));
          expect(params.bValue, greaterThan(0));
          expect(params.dValue, greaterThan(0));
          expect(params.eValue, greaterThan(0));
          expect(params.gasketThickness, greaterThanOrEqualTo(0));
          expect(params.initialValue, greaterThanOrEqualTo(0));
          
          // 验证D值大于R值
          expect(params.dValue, greaterThan(params.rValue));
          
          // 验证参数验证结果
          expect(validation.isValid, isTrue,
              reason: '生成的封堵参数应该是有效的: ${validation.message}');
        }
      });
      
      test('生成有效的下塞堵参数', () {
        for (int i = 0; i < 50; i++) {
          final params = PipeParameterGenerator.generateValidPlugParameters();
          final validation = params.validate();
          
          // 验证参数基本有效性
          expect(params.mValue, greaterThan(0));
          expect(params.kValue, greaterThan(0));
          expect(params.nValue, greaterThan(0));
          expect(params.tValue, greaterThan(0));
          expect(params.wValue, greaterThan(0));
          
          // 验证螺纹咬合尺寸为正
          expect(params.tValue - params.wValue, greaterThanOrEqualTo(0));
          
          // 验证空行程为正
          final emptyStroke = params.mValue + params.kValue - params.tValue + params.wValue;
          expect(emptyStroke, greaterThan(0));
          
          // 验证总行程为正
          final totalStroke = params.mValue + params.kValue + params.nValue - params.tValue + params.wValue;
          expect(totalStroke, greaterThan(0));
          
          // 验证参数验证结果
          expect(validation.isValid, isTrue,
              reason: '生成的下塞堵参数应该是有效的: ${validation.message}');
        }
      });
      
      test('生成有效的下塞柄参数', () {
        for (int i = 0; i < 50; i++) {
          final params = PipeParameterGenerator.generateValidStemParameters();
          final validation = params.validate();
          
          // 验证参数基本有效性
          expect(params.fValue, greaterThan(0));
          expect(params.gValue, greaterThan(0));
          expect(params.hValue, greaterThan(0));
          expect(params.gasketThickness, greaterThanOrEqualTo(0));
          expect(params.initialValue, greaterThanOrEqualTo(0));
          
          // 验证总行程为正
          final totalStroke = params.fValue + params.gValue + params.hValue + 
                            params.gasketThickness + params.initialValue;
          expect(totalStroke, greaterThan(0));
          
          // 验证参数验证结果
          expect(validation.isValid, isTrue,
              reason: '生成的下塞柄参数应该是有效的: ${validation.message}');
        }
      });
    });
    
    group('边界值参数生成测试', () {
      test('生成边界值开孔参数', () {
        for (int i = 0; i < 20; i++) {
          final params = PipeParameterGenerator.generateBoundaryHoleParameters();
          
          // 验证参数基本有效性（边界值仍应该是有效的）
          expect(params.outerDiameter, greaterThan(0));
          expect(params.innerDiameter, greaterThan(0));
          expect(params.outerDiameter, greaterThan(params.innerDiameter));
          expect(params.cutterOuterDiameter, greaterThan(0));
          expect(params.cutterInnerDiameter, greaterThan(0));
          expect(params.cutterOuterDiameter, greaterThan(params.cutterInnerDiameter));
          
          // 验证数值的有限性
          expect(params.outerDiameter.isFinite, isTrue);
          expect(params.innerDiameter.isFinite, isTrue);
          expect(params.cutterOuterDiameter.isFinite, isTrue);
          expect(params.cutterInnerDiameter.isFinite, isTrue);
        }
      });
    });
    
    group('无效参数生成测试', () {
      test('生成无效的开孔参数', () {
        for (int i = 0; i < 30; i++) {
          final params = PipeParameterGenerator.generateInvalidHoleParameters();
          final validation = params.validate();
          
          // 验证参数确实是无效的
          expect(validation.isValid, isFalse,
              reason: '生成的参数应该是无效的，但验证通过了');
          
          // 验证至少有一个错误消息
          expect(validation.message.isNotEmpty, isTrue);
        }
      });
      
      test('生成无效的手动开孔参数', () {
        for (int i = 0; i < 30; i++) {
          final params = PipeParameterGenerator.generateInvalidManualHoleParameters();
          final validation = params.validate();
          
          // 验证参数确实是无效的（有错误或严重警告）
          expect(validation.isError || 
                 (validation.isWarning && validation.message.contains('负值')), isTrue,
              reason: '生成的手动开孔参数应该有错误或严重警告: ${validation.message}');
        }
      });
      
      test('生成无效的封堵参数', () {
        for (int i = 0; i < 30; i++) {
          final params = PipeParameterGenerator.generateInvalidSealingParameters();
          final validation = params.validate();
          
          // 验证参数确实是无效的
          expect(validation.isValid, isFalse,
              reason: '生成的封堵参数应该是无效的，但验证通过了');
        }
      });
      
      test('生成无效的下塞堵参数', () {
        for (int i = 0; i < 30; i++) {
          final params = PipeParameterGenerator.generateInvalidPlugParameters();
          final validation = params.validate();
          
          // 验证参数确实是无效的（有错误或严重警告）
          expect(validation.isError || 
                 (validation.isWarning && validation.message.contains('负值')), isTrue,
              reason: '生成的下塞堵参数应该有错误或严重警告: ${validation.message}');
        }
      });
      
      test('生成无效的下塞柄参数', () {
        for (int i = 0; i < 30; i++) {
          final params = PipeParameterGenerator.generateInvalidStemParameters();
          final validation = params.validate();
          
          // 验证参数确实是无效的
          expect(validation.isValid, isFalse,
              reason: '生成的下塞柄参数应该是无效的，但验证通过了');
        }
      });
    });
    
    group('特殊场景参数生成测试', () {
      test('生成小管道场景参数', () {
        final params = PipeParameterGenerator.generateSpecialScenarioHoleParameters('small_pipe');
        
        expect(params.outerDiameter, lessThan(100.0));
        expect(params.innerDiameter, lessThan(params.outerDiameter));
        
        final validation = params.validate();
        expect(validation.isValid, isTrue);
      });
      
      test('生成大管道场景参数', () {
        final params = PipeParameterGenerator.generateSpecialScenarioHoleParameters('large_pipe');
        
        expect(params.outerDiameter, greaterThan(1000.0));
        expect(params.innerDiameter, lessThan(params.outerDiameter));
        
        final validation = params.validate();
        expect(validation.isValid, isTrue);
      });
      
      test('生成厚壁管道场景参数', () {
        final params = PipeParameterGenerator.generateSpecialScenarioHoleParameters('thick_wall');
        
        final wallThickness = params.outerDiameter - params.innerDiameter;
        expect(wallThickness, greaterThan(20.0)); // 厚壁管道
        
        final validation = params.validate();
        expect(validation.isValid, isTrue);
      });
      
      test('生成薄壁管道场景参数', () {
        final params = PipeParameterGenerator.generateSpecialScenarioHoleParameters('thin_wall');
        
        final wallThickness = params.outerDiameter - params.innerDiameter;
        expect(wallThickness, lessThan(15.0)); // 薄壁管道
        
        final validation = params.validate();
        expect(validation.isValid, isTrue);
      });
      
      test('生成精度要求严格的场景参数', () {
        final params = PipeParameterGenerator.generateSpecialScenarioHoleParameters('precision_critical');
        
        // 验证所有参数都符合精度要求
        expect(_isPrecisionMaintained(params.outerDiameter), isTrue,
            reason: '管外径精度不符合要求: ${params.outerDiameter}');
        expect(_isPrecisionMaintained(params.innerDiameter), isTrue,
            reason: '管内径精度不符合要求: ${params.innerDiameter}');
        expect(_isPrecisionMaintained(params.cutterOuterDiameter), isTrue,
            reason: '筒刀外径精度不符合要求: ${params.cutterOuterDiameter}');
        expect(_isPrecisionMaintained(params.cutterInnerDiameter), isTrue,
            reason: '筒刀内径精度不符合要求: ${params.cutterInnerDiameter}');
        expect(_isPrecisionMaintained(params.aValue), isTrue,
            reason: 'A值精度不符合要求: ${params.aValue}');
        expect(_isPrecisionMaintained(params.bValue), isTrue,
            reason: 'B值精度不符合要求: ${params.bValue}');
        expect(_isPrecisionMaintained(params.rValue), isTrue,
            reason: 'R值精度不符合要求: ${params.rValue}');
        expect(_isPrecisionMaintained(params.initialValue), isTrue,
            reason: '初始值精度不符合要求: ${params.initialValue}');
        expect(_isPrecisionMaintained(params.gasketThickness), isTrue,
            reason: '垫片厚度精度不符合要求: ${params.gasketThickness}');
        
        final validation = params.validate();
        expect(validation.isValid, isTrue,
            reason: '精度严格场景参数验证失败: ${validation.message}');
      });
    });
    
    group('压力测试参数生成', () {
      test('生成压力测试参数集合', () {
        final paramsList = PipeParameterGenerator.generateStressTestParameters(100);
        
        expect(paramsList.length, equals(100));
        
        // 验证参数多样性
        final outerDiameters = paramsList.map((p) => p.outerDiameter).toSet();
        expect(outerDiameters.length, greaterThan(30)); // 应该有足够的多样性
        
        // 验证大部分参数是有效的
        final validCount = paramsList.where((p) => 
            p.validate().isValid).length;
        expect(validCount / paramsList.length, greaterThan(0.6)); // 至少60%有效
      });
    });
    
    group('参数序列生成测试', () {
      test('生成参数变化序列', () {
        final baseParams = PipeParameterGenerator.generateValidHoleParameters();
        final sequence = PipeParameterGenerator.generateParameterSequence(
          baseParams,
          'outerDiameter',
          100.0,
          200.0,
          11,
        );
        
        expect(sequence.length, equals(11));
        expect(sequence.first.outerDiameter, equals(100.0));
        expect(sequence.last.outerDiameter, equals(200.0));
        
        // 验证序列的连续性
        for (int i = 1; i < sequence.length; i++) {
          final diff = sequence[i].outerDiameter - sequence[i-1].outerDiameter;
          expect(diff, closeTo(10.0, 0.01)); // 步长应该是10.0
        }
      });
    });
    
    group('对称性测试参数生成', () {
      test('生成对称性测试参数', () {
        final paramsList = PipeParameterGenerator.generateSymmetryTestParameters();
        
        expect(paramsList.length, equals(3));
        
        // 验证所有参数都是有效的
        for (final params in paramsList) {
          final validation = params.validate();
          expect(validation.isValid, isTrue);
        }
      });
    });
    
    group('生成器统计功能测试', () {
      test('获取参数生成统计信息', () {
        final validParams = List.generate(70, (_) => 
            PipeParameterGenerator.generateValidHoleParameters());
        final invalidParams = List.generate(30, (_) => 
            PipeParameterGenerator.generateInvalidHoleParameters());
        
        final allParams = [...validParams, ...invalidParams];
        final stats = PipeParameterGenerator.getGenerationStatistics(allParams);
        
        expect(stats['total'], equals(100));
        expect(stats['valid'], greaterThanOrEqualTo(60)); // 大部分有效参数应该通过验证
        expect(stats['invalid'], lessThanOrEqualTo(40));
        expect(stats['validPercentage'], isA<String>());
      });
    });
    
    group('参数验证功能测试', () {
      test('验证生成的参数', () {
        final validParams = PipeParameterGenerator.generateValidHoleParameters();
        final invalidParams = PipeParameterGenerator.generateInvalidHoleParameters();
        
        expect(PipeParameterGenerator.validateGeneratedParameters(validParams), isTrue);
        expect(PipeParameterGenerator.validateGeneratedParameters(invalidParams), isFalse);
      });
    });
    
    group('精度保持测试', () {
      test('所有生成的参数都保持精度要求', () {
        for (int i = 0; i < 100; i++) {
          final params = PipeParameterGenerator.generateValidHoleParameters();
          
          expect(_isPrecisionMaintained(params.outerDiameter), isTrue);
          expect(_isPrecisionMaintained(params.innerDiameter), isTrue);
          expect(_isPrecisionMaintained(params.cutterOuterDiameter), isTrue);
          expect(_isPrecisionMaintained(params.cutterInnerDiameter), isTrue);
          expect(_isPrecisionMaintained(params.aValue), isTrue);
          expect(_isPrecisionMaintained(params.bValue), isTrue);
          expect(_isPrecisionMaintained(params.rValue), isTrue);
          expect(_isPrecisionMaintained(params.initialValue), isTrue);
          expect(_isPrecisionMaintained(params.gasketThickness), isTrue);
        }
      });
    });
    
    group('边界条件覆盖测试', () {
      test('边界参数覆盖所有关键边界', () {
        final boundaryParams = List.generate(50, (_) => 
            PipeParameterGenerator.generateBoundaryHoleParameters());
        
        // 检查是否包含最小值边界
        final hasMinValues = boundaryParams.any((p) => 
            p.outerDiameter <= 60.0 || p.aValue <= 12.0);
        expect(hasMinValues, isTrue);
        
        // 检查是否包含最大值边界
        final hasMaxValues = boundaryParams.any((p) => 
            p.outerDiameter >= 1500.0 || p.aValue >= 150.0);
        expect(hasMaxValues, isTrue);
        
        // 检查是否包含接近相等的边界
        final hasCloseValues = boundaryParams.any((p) => 
            (p.outerDiameter - p.innerDiameter) / p.outerDiameter < 0.05);
        expect(hasCloseValues, isTrue);
      });
    });
  });
}

/// 检查数值是否保持在0.1mm精度范围内
bool _isPrecisionMaintained(double value) {
  if (!value.isFinite) return false;
  
  final rounded = (value * 10).round() / 10;
  return (value - rounded).abs() <= AppConstants.precisionThreshold / 10;
}