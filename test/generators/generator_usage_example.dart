/// 测试生成器使用示例
/// 
/// 本文件展示了如何使用 PipeParameterGenerator 来生成各种测试数据

import 'dart:math' as math;
import 'pipe_parameter_generator.dart';
import '../../lib/models/calculation_parameters.dart';

void main() {
  print('=== 管道参数测试生成器使用示例 ===\n');
  
  // 1. 生成有效参数示例
  print('1. 生成有效参数:');
  final validHoleParams = PipeParameterGenerator.generateValidHoleParameters();
  print('开孔参数: 管外径=${validHoleParams.outerDiameter}mm, 管内径=${validHoleParams.innerDiameter}mm');
  print('验证结果: ${validHoleParams.validate().message}\n');
  
  // 2. 生成边界值参数示例
  print('2. 生成边界值参数:');
  final boundaryParams = PipeParameterGenerator.generateBoundaryHoleParameters();
  print('边界参数: 管外径=${boundaryParams.outerDiameter}mm, 管内径=${boundaryParams.innerDiameter}mm');
  print('验证结果: ${boundaryParams.validate().message}\n');
  
  // 3. 生成无效参数示例
  print('3. 生成无效参数:');
  final invalidParams = PipeParameterGenerator.generateInvalidHoleParameters();
  print('无效参数: 管外径=${invalidParams.outerDiameter}mm, 管内径=${invalidParams.innerDiameter}mm');
  print('验证结果: ${invalidParams.validate().message}\n');
  
  // 4. 生成特殊场景参数示例
  print('4. 生成特殊场景参数:');
  final smallPipeParams = PipeParameterGenerator.generateSpecialScenarioHoleParameters('small_pipe');
  print('小管道场景: 管外径=${smallPipeParams.outerDiameter}mm, 管内径=${smallPipeParams.innerDiameter}mm');
  
  final largePipeParams = PipeParameterGenerator.generateSpecialScenarioHoleParameters('large_pipe');
  print('大管道场景: 管外径=${largePipeParams.outerDiameter}mm, 管内径=${largePipeParams.innerDiameter}mm\n');
  
  // 5. 生成压力测试参数集合
  print('5. 生成压力测试参数集合:');
  final stressTestParams = PipeParameterGenerator.generateStressTestParameters(10);
  print('生成了 ${stressTestParams.length} 个压力测试参数');
  
  // 统计有效参数比例
  final stats = PipeParameterGenerator.getGenerationStatistics(stressTestParams);
  print('统计信息: ${stats}\n');
  
  // 6. 生成参数变化序列
  print('6. 生成参数变化序列:');
  final baseParams = PipeParameterGenerator.generateValidHoleParameters();
  final sequence = PipeParameterGenerator.generateParameterSequence(
    baseParams,
    'outerDiameter',
    100.0,
    200.0,
    5,
  );
  
  print('管外径变化序列:');
  for (int i = 0; i < sequence.length; i++) {
    print('  步骤 ${i + 1}: ${sequence[i].outerDiameter}mm');
  }
  print('');
  
  // 7. 生成对称性测试参数
  print('7. 生成对称性测试参数:');
  final symmetryParams = PipeParameterGenerator.generateSymmetryTestParameters();
  print('生成了 ${symmetryParams.length} 个对称性测试参数');
  for (int i = 0; i < symmetryParams.length; i++) {
    print('  参数组 ${i + 1}: A值=${symmetryParams[i].aValue}mm, B值=${symmetryParams[i].bValue}mm');
  }
  print('');
  
  // 8. 验证生成器功能
  print('8. 验证生成器功能:');
  
  // 测试有效参数生成的成功率
  int validCount = 0;
  int totalCount = 100;
  
  for (int i = 0; i < totalCount; i++) {
    final params = PipeParameterGenerator.generateValidHoleParameters();
    if (PipeParameterGenerator.validateGeneratedParameters(params)) {
      validCount++;
    }
  }
  
  print('有效参数生成成功率: ${(validCount / totalCount * 100).toStringAsFixed(1)}%');
  
  // 测试无效参数生成的成功率
  int invalidCount = 0;
  
  for (int i = 0; i < totalCount; i++) {
    final params = PipeParameterGenerator.generateInvalidHoleParameters();
    if (!PipeParameterGenerator.validateGeneratedParameters(params)) {
      invalidCount++;
    }
  }
  
  print('无效参数生成成功率: ${(invalidCount / totalCount * 100).toStringAsFixed(1)}%');
  
  // 9. 精度验证示例
  print('\n9. 精度验证示例:');
  final precisionParams = PipeParameterGenerator.generateValidHoleParameters();
  print('生成的参数精度验证:');
  print('  管外径: ${precisionParams.outerDiameter}mm (精度: ${_checkPrecision(precisionParams.outerDiameter)})');
  print('  管内径: ${precisionParams.innerDiameter}mm (精度: ${_checkPrecision(precisionParams.innerDiameter)})');
  print('  A值: ${precisionParams.aValue}mm (精度: ${_checkPrecision(precisionParams.aValue)})');
  
  print('\n=== 示例完成 ===');
}

/// 检查数值精度
String _checkPrecision(double value) {
  final rounded = (value * 10).round() / 10;
  final diff = (value - rounded).abs();
  return diff <= 0.01 ? '符合0.1mm精度' : '精度不符合要求';
}

/// 演示如何在实际测试中使用生成器
void demonstrateTestUsage() {
  print('\n=== 实际测试使用演示 ===');
  
  // 在属性测试中使用
  print('属性测试示例:');
  for (int i = 0; i < 10; i++) {
    final params = PipeParameterGenerator.generateValidHoleParameters();
    
    // 模拟计算引擎调用
    final emptyStroke = params.aValue + params.bValue + params.initialValue + params.gasketThickness;
    
    // 验证计算结果的合理性
    assert(emptyStroke > 0, '空行程必须为正值');
    assert(emptyStroke < 1000, '空行程不应过大');
    
    print('  测试 ${i + 1}: 空行程 = ${emptyStroke.toStringAsFixed(1)}mm');
  }
  
  // 在边界测试中使用
  print('\n边界测试示例:');
  final boundaryParams = PipeParameterGenerator.generateBoundaryHoleParameters();
  print('边界参数测试: 管外径=${boundaryParams.outerDiameter}mm');
  
  // 在错误处理测试中使用
  print('\n错误处理测试示例:');
  final invalidParams = PipeParameterGenerator.generateInvalidHoleParameters();
  final validation = invalidParams.validate();
  print('无效参数验证: ${validation.isError ? "正确识别错误" : "验证失败"}');
  
  print('=== 演示完成 ===');
}