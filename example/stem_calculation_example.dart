import '../lib/models/calculation_parameters.dart';
import '../lib/services/calculation_engine.dart';

/// 下塞柄计算示例
/// 
/// 演示如何使用下塞柄计算功能进行封堵孔/囊孔下塞柄作业的尺寸计算
void main() {
  print('=== 油气管道下塞柄计算示例 ===\n');

  // 创建计算引擎
  final engine = PrecisionCalculationEngine();

  // 示例1: 典型小型管道下塞柄计算
  print('示例1: 小型管道下塞柄计算');
  print('场景: DN100管道，封堵孔下塞柄安装');
  
  final smallPipeParams = StemParameters(
    fValue: 25.0,        // 封堵孔基础尺寸 25mm
    gValue: 15.0,        // 设备调节范围 15mm
    hValue: 40.0,        // 下塞柄长度 40mm
    gasketThickness: 1.5, // 垫子厚度 1.5mm
    initialValue: 2.0,   // 初始值 2mm
  );

  try {
    final result1 = engine.calculateStem(smallPipeParams);
    
    print('输入参数:');
    print('  F值(封堵孔基础尺寸): ${smallPipeParams.fValue}mm');
    print('  G值(设备调节范围): ${smallPipeParams.gValue}mm');
    print('  H值(下塞柄长度): ${smallPipeParams.hValue}mm');
    print('  垫子厚度: ${smallPipeParams.gasketThickness}mm');
    print('  初始值: ${smallPipeParams.initialValue}mm');
    
    print('\n计算结果:');
    print('  总行程: ${result1.totalStroke}mm');
    
    print('\n计算公式: ${result1.getFormulas()['总行程']}');
    
    // 显示计算步骤
    print('\n详细计算步骤:');
    final steps1 = result1.getCalculationSteps();
    steps1.forEach((step, description) {
      print('  $step: $description');
    });
    
  } catch (e) {
    print('计算失败: $e');
  }

  print('\n' + '='*60 + '\n');

  // 示例2: 大型管道下塞柄计算
  print('示例2: 大型管道下塞柄计算');
  print('场景: DN300管道，囊孔下塞柄安装');
  
  final largePipeParams = StemParameters(
    fValue: 80.0,        // 囊孔基础尺寸 80mm
    gValue: 50.0,        // 设备调节范围 50mm
    hValue: 120.0,       // 下塞柄长度 120mm
    gasketThickness: 3.0, // 垫子厚度 3mm
    initialValue: 5.0,   // 初始值 5mm
  );

  try {
    final result2 = engine.calculateStem(largePipeParams);
    
    print('输入参数:');
    print('  F值(囊孔基础尺寸): ${largePipeParams.fValue}mm');
    print('  G值(设备调节范围): ${largePipeParams.gValue}mm');
    print('  H值(下塞柄长度): ${largePipeParams.hValue}mm');
    print('  垫子厚度: ${largePipeParams.gasketThickness}mm');
    print('  初始值: ${largePipeParams.initialValue}mm');
    
    print('\n计算结果:');
    print('  总行程: ${result2.totalStroke}mm');
    
    // 显示操作指导
    print('\n操作指导:');
    final guidance = result2.getOperationGuidance();
    guidance.forEach((stage, instruction) {
      print('  $stage: $instruction');
    });
    
    // 显示安全提示
    final warnings = result2.getSafetyWarnings();
    if (warnings.isNotEmpty) {
      print('\n安全提示:');
      warnings.forEach((warning) {
        print('  ⚠️  $warning');
      });
    }
    
  } catch (e) {
    print('计算失败: $e');
  }

  print('\n' + '='*60 + '\n');

  // 示例3: 参数验证和错误处理
  print('示例3: 参数验证和错误处理演示');
  
  final invalidParams = StemParameters(
    fValue: -10.0,       // 无效的负数
    gValue: 30.0,
    hValue: 80.0,
    gasketThickness: 2.0,
    initialValue: 5.0,
  );

  // 验证参数
  final validation = invalidParams.validate();
  print('参数验证结果:');
  print('  是否有效: ${validation.isValid}');
  print('  验证消息: ${validation.message}');
  
  if (!validation.isValid) {
    print('  建议: 请检查F值，确保所有参数为正数');
  }

  print('\n程序结束');
}