import '../lib/models/calculation_parameters.dart';
import '../lib/services/calculation_engine.dart';

/// 下塞堵计算示例
/// 
/// 演示如何使用下塞堵计算功能，包括：
/// 1. 创建下塞堵参数
/// 2. 执行计算
/// 3. 获取计算结果
/// 4. 处理参数检查建议
void main() {
  print('=== 油气管道下塞堵计算示例 ===\n');

  // 创建计算引擎
  final engine = PrecisionCalculationEngine();

  // 示例1：标准下塞堵计算
  print('示例1：标准下塞堵计算');
  print('-------------------');
  
  final standardParams = PlugParameters(
    mValue: 50.0,  // M值：设备基础尺寸
    kValue: 30.0,  // K值：设备调节范围
    nValue: 25.0,  // N值：下塞堵深度
    tValue: 20.0,  // T值：螺纹长度
    wValue: 15.0,  // W值：螺纹深度
  );

  try {
    final result = engine.calculatePlug(standardParams);
    
    print('输入参数：');
    print('  M值: ${standardParams.mValue}mm');
    print('  K值: ${standardParams.kValue}mm');
    print('  N值: ${standardParams.nValue}mm');
    print('  T值: ${standardParams.tValue}mm');
    print('  W值: ${standardParams.wValue}mm');
    
    print('\n计算结果：');
    print('  螺纹咬合尺寸: ${result.threadEngagement}mm');
    print('  空行程: ${result.emptyStroke}mm');
    print('  总行程: ${result.totalStroke}mm');
    
    print('\n计算公式：');
    result.getFormulas().forEach((key, value) {
      print('  $key: $value');
    });
    
    print('\n计算步骤：');
    result.getCalculationSteps().forEach((key, value) {
      print('  $key: $value');
    });
    
    // 获取参数检查建议
    final suggestions = result.getParameterCheckSuggestions();
    if (suggestions.isNotEmpty) {
      print('\n参数检查建议：');
      for (final suggestion in suggestions) {
        print('  • $suggestion');
      }
    }
    
    // 获取安全提示
    final warnings = result.getSafetyWarnings();
    if (warnings.isNotEmpty) {
      print('\n安全提示：');
      for (final warning in warnings) {
        print('  ⚠️ $warning');
      }
    }
    
  } catch (e) {
    print('计算失败: $e');
  }

  print('\n' + '=' * 50 + '\n');

  // 示例2：螺纹咬合为负值的情况
  print('示例2：螺纹咬合为负值的情况');
  print('-------------------------');
  
  final negativeThreadParams = PlugParameters(
    mValue: 60.0,
    kValue: 40.0,
    nValue: 30.0,
    tValue: 15.0,  // T值较小
    wValue: 20.0,  // W值较大，导致螺纹咬合为负
  );

  try {
    final result = engine.calculatePlug(negativeThreadParams);
    
    print('输入参数：');
    print('  M值: ${negativeThreadParams.mValue}mm');
    print('  K值: ${negativeThreadParams.kValue}mm');
    print('  N值: ${negativeThreadParams.nValue}mm');
    print('  T值: ${negativeThreadParams.tValue}mm (较小)');
    print('  W值: ${negativeThreadParams.wValue}mm (较大)');
    
    print('\n计算结果：');
    print('  螺纹咬合尺寸: ${result.threadEngagement}mm (负值!)');
    print('  空行程: ${result.emptyStroke}mm');
    print('  总行程: ${result.totalStroke}mm');
    
    // 获取参数检查建议
    final suggestions = result.getParameterCheckSuggestions();
    print('\n参数检查建议：');
    for (final suggestion in suggestions) {
      print('  • $suggestion');
    }
    
    // 获取参数调整建议
    final adjustments = result.getParameterAdjustmentSuggestions();
    if (adjustments.isNotEmpty) {
      print('\n参数调整建议：');
      adjustments.forEach((key, value) {
        print('  $key: $value');
      });
    }
    
  } catch (e) {
    print('计算失败: $e');
  }

  print('\n' + '=' * 50 + '\n');

  // 示例3：参数验证失败的情况
  print('示例3：参数验证失败的情况');
  print('---------------------');
  
  final invalidParams = PlugParameters(
    mValue: 10.0,
    kValue: 5.0,
    nValue: 10.0,
    tValue: 50.0,  // T值过大，会导致空行程和总行程为负
    wValue: 5.0,
  );

  try {
    final result = engine.calculatePlug(invalidParams);
    print('意外成功: ${result.totalStroke}mm');
  } catch (e) {
    print('预期的验证失败: $e');
    
    // 显示参数验证结果
    final validation = invalidParams.validate();
    if (!validation.isValid) {
      print('\n参数验证错误：');
      print('  ${validation.message}');
    }
  }

  print('\n' + '=' * 50 + '\n');

  // 示例4：参数优化建议
  print('示例4：参数优化建议');
  print('---------------');
  
  final suboptimalParams = PlugParameters(
    mValue: 100.0,
    kValue: 80.0,
    nValue: 120.0,  // N值相对较大
    tValue: 25.0,
    wValue: 22.0,   // 螺纹咬合较小
  );

  try {
    final result = engine.calculatePlug(suboptimalParams);
    
    print('输入参数：');
    print('  M值: ${suboptimalParams.mValue}mm');
    print('  K值: ${suboptimalParams.kValue}mm');
    print('  N值: ${suboptimalParams.nValue}mm (较大)');
    print('  T值: ${suboptimalParams.tValue}mm');
    print('  W值: ${suboptimalParams.wValue}mm');
    
    print('\n计算结果：');
    print('  螺纹咬合尺寸: ${result.threadEngagement}mm');
    print('  空行程: ${result.emptyStroke}mm');
    print('  总行程: ${result.totalStroke}mm');
    
    // 获取优化建议
    final optimizations = suboptimalParams.getOptimizationSuggestions();
    if (optimizations.isNotEmpty) {
      print('\n参数优化建议：');
      for (final optimization in optimizations) {
        print('  💡 $optimization');
      }
    }
    
    // 检查参数组合安全性
    final isSafe = suboptimalParams.isSafeParameterCombination();
    print('\n参数组合安全性: ${isSafe ? "✅ 安全" : "⚠️ 需要注意"}');
    
  } catch (e) {
    print('计算失败: $e');
  }

  print('\n=== 下塞堵计算示例完成 ===');
}