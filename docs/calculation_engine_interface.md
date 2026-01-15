# 计算引擎接口文档

## 概述

本文档定义了油气管道开孔封堵计算系统的计算引擎接口规范。所有计算逻辑都通过标准化接口提供，确保跨平台一致性和模块化设计。

## 核心接口定义

### ICalculationEngine 接口

```dart
/// 计算引擎抽象接口
/// 
/// 定义了所有计算模块的标准接口，确保计算逻辑的一致性和可测试性
abstract class ICalculationEngine {
  /// 开孔尺寸计算
  /// 
  /// 根据管道参数和筒刀参数计算开孔作业的各项尺寸
  /// 
  /// 参数:
  /// - [params]: 开孔计算参数，包含管外径、内径、筒刀规格等
  /// 
  /// 返回:
  /// - [HoleCalculationResult]: 包含空行程、总行程、掉板行程等计算结果
  /// 
  /// 异常:
  /// - [ArgumentError]: 参数验证失败
  /// - [CalculationException]: 计算过程异常
  HoleCalculationResult calculateHoleSize(HoleParameters params);
  
  /// 手动开孔计算
  /// 
  /// 计算手动开孔机的尺寸参数
  /// 
  /// 参数:
  /// - [params]: 手动开孔参数，包含L、J、P、T、W值
  /// 
  /// 返回:
  /// - [ManualHoleResult]: 包含螺纹咬合尺寸、空行程、总行程
  ManualHoleResult calculateManualHole(ManualHoleParameters params);
  
  /// 封堵计算
  /// 
  /// 计算封堵和解堵作业的尺寸参数
  /// 
  /// 参数:
  /// - [params]: 封堵参数，包含R、B、D、E值等
  /// 
  /// 返回:
  /// - [SealingResult]: 包含导向轮行程、封堵总行程
  SealingResult calculateSealing(SealingParameters params);
  
  /// 下塞堵计算
  /// 
  /// 计算下塞堵作业的尺寸参数
  /// 
  /// 参数:
  /// - [params]: 下塞堵参数，包含M、K、N、T、W值
  /// 
  /// 返回:
  /// - [PlugResult]: 包含螺纹咬合尺寸、空行程、总行程
  PlugResult calculatePlug(PlugParameters params);
  
  /// 下塞柄计算
  /// 
  /// 计算下塞柄作业的尺寸参数
  /// 
  /// 参数:
  /// - [params]: 下塞柄参数，包含F、G、H值等
  /// 
  /// 返回:
  /// - [StemResult]: 包含总行程计算结果
  StemResult calculateStem(StemParameters params);
  
  /// 获取计算精度阈值
  /// 
  /// 返回:
  /// - [double]: 精度阈值（毫米），通常为0.1mm
  double getPrecisionThreshold();
}
```

## 实现类规范

### PrecisionCalculationEngine

高精度计算引擎实现，提供0.1mm精度的工程计算。

#### 特性
- **精度保证**: 所有计算结果精度≤0.1mm
- **双精度运算**: 使用双精度浮点数确保计算精度
- **异常处理**: 完善的参数验证和异常处理
- **性能优化**: 内置缓存机制和性能监控
- **工程验证**: 包含工程合理性检查和警告系统

#### 使用示例

```dart
// 创建计算引擎实例
final engine = PrecisionCalculationEngine();

// 开孔计算示例
final holeParams = HoleParameters(
  outerDiameter: 114.3,    // 管外径 (mm)
  innerDiameter: 102.3,    // 管内径 (mm)
  cutterOuterDiameter: 25.4, // 筒刀外径 (mm)
  cutterInnerDiameter: 19.1, // 筒刀内径 (mm)
  aValue: 50.0,            // A值 (mm)
  bValue: 30.0,            // B值 (mm)
  rValue: 15.0,            // R值 (mm)
  initialValue: 10.0,      // 初始值 (mm)
  gasketThickness: 3.0,    // 垫片厚度 (mm)
);

try {
  final result = engine.calculateHoleSize(holeParams);
  
  print('空行程: ${result.emptyStroke}mm');
  print('总行程: ${result.totalStroke}mm');
  print('掉板总行程: ${result.plateStroke}mm');
} catch (e) {
  print('计算失败: $e');
}
```

## 数学公式规范

### 开孔计算公式

1. **空行程**: `S空 = A + B + 初始值 + 垫片厚度`
2. **管道壁厚区域**: `√(管外径² - 管内径²)`
3. **筒刀切削距离**: `C1 = √(管外径² - 管内径²) - 筒刀外径`
4. **掉板弦高**: `C2 = √(管外径² - 管内径²) - 筒刀内径`
5. **切削尺寸**: `C = R + C1`
6. **开孔总行程**: `S总 = S空 + C`
7. **掉板总行程**: `S掉板 = S总 + R + C2`

### 手动开孔公式

1. **螺纹咬合尺寸**: `T - W`
2. **空行程**: `L + J + T + W`
3. **总行程**: `L + J + T + W + P`

### 封堵计算公式

1. **导向轮接触管线行程**: `R + B + E + 垫子厚度 + 初始值`
2. **封堵总行程**: `D + B + E + 垫子厚度 + 初始值`

### 下塞堵公式

1. **螺纹咬合尺寸**: `T - W`
2. **空行程**: `M + K - T + W`
3. **总行程**: `M + K + N - T + W`

### 下塞柄公式

1. **总行程**: `F + G + H + 垫子厚度 + 初始值`

## 参数验证规范

### 通用验证规则

1. **非空验证**: 所有必需参数不能为null
2. **数值范围**: 参数值必须在合理的工程范围内
3. **逻辑关系**: 相关参数之间的逻辑关系必须正确
4. **精度要求**: 输入参数精度应适合工程计算

### 开孔参数验证

```dart
class HoleParameters {
  // 验证方法
  ValidationResult validate() {
    // 1. 管外径必须大于管内径
    if (outerDiameter <= innerDiameter) {
      return ValidationResult.invalid('管外径必须大于管内径');
    }
    
    // 2. 筒刀外径必须大于筒刀内径
    if (cutterOuterDiameter <= cutterInnerDiameter) {
      return ValidationResult.invalid('筒刀外径必须大于筒刀内径');
    }
    
    // 3. 所有参数必须为正数
    if (aValue < 0 || bValue < 0 || rValue < 0) {
      return ValidationResult.invalid('A、B、R值必须为非负数');
    }
    
    // 4. 工程合理性检查
    if (outerDiameter > 2000.0) {
      return ValidationResult.warning('管外径超出常见范围，请确认');
    }
    
    return ValidationResult.valid();
  }
}
```

## 异常处理规范

### 异常类型

#### CalculationException

```dart
class CalculationException implements Exception {
  final String message;      // 异常消息
  final String? code;        // 异常代码
  final Map<String, dynamic>? relatedParameters; // 相关参数
  
  const CalculationException(
    this.message, {
    this.code,
    this.relatedParameters,
  });
}
```

### 异常处理策略

1. **参数验证异常**: 抛出ArgumentError，包含具体的验证失败信息
2. **计算异常**: 抛出CalculationException，包含计算失败的详细信息
3. **数学异常**: 处理除零、负数开方等数学异常
4. **工程警告**: 对于不合理但不致命的参数，输出警告信息

## 精度控制规范

### 精度要求

- **目标精度**: ≤ 0.1mm
- **舍入规则**: 使用标准的四舍五入规则
- **累积误差**: 多步计算允许适当的累积误差

### 精度实现

```dart
/// 精度控制方法
double _roundToPrecision(double value) {
  const precisionThreshold = 0.1; // 0.1mm精度
  final multiplier = 1.0 / precisionThreshold;
  return (value * multiplier).round() / multiplier;
}
```

## 性能规范

### 性能要求

- **单次计算**: < 1ms
- **批量计算**: 100次计算 < 50ms
- **内存使用**: 稳定，无内存泄漏
- **缓存机制**: 相同参数重复计算使用缓存

### 性能监控

```dart
// 性能监控示例
PerformanceMonitor.startMeasurement('hole_calculation');
final result = engine.calculateHoleSize(params);
PerformanceMonitor.endMeasurement('hole_calculation');
```

## 测试规范

### 测试覆盖要求

1. **单元测试**: 每个计算方法的基本功能测试
2. **属性测试**: 使用随机参数进行大量测试
3. **边界测试**: 极值参数和边界条件测试
4. **精度测试**: 验证计算精度符合要求
5. **性能测试**: 验证计算性能满足要求

### 测试标准

- **属性测试**: 每个属性至少100次随机测试
- **精度验证**: 所有结果误差 < 0.1mm
- **边界测试**: 覆盖最小值、最大值、零值等边界情况
- **异常测试**: 验证异常情况的正确处理

## 版本兼容性

### 接口稳定性

- **向后兼容**: 新版本必须保持向后兼容
- **接口变更**: 重大接口变更需要版本号升级
- **弃用策略**: 旧接口标记为@deprecated，提供迁移指南

### 计算一致性

- **跨版本一致**: 相同参数在不同版本中产生相同结果
- **跨平台一致**: Web、iOS、Android平台计算结果完全一致
- **精度保持**: 版本升级不能降低计算精度

## 集成指南

### 依赖注入

```dart
// 使用依赖注入管理计算引擎
class CalculationService {
  final ICalculationEngine _engine;
  
  CalculationService(this._engine);
  
  Future<HoleCalculationResult> calculateHole(HoleParameters params) async {
    return _engine.calculateHoleSize(params);
  }
}
```

### 错误处理

```dart
// 统一的错误处理
try {
  final result = await calculationService.calculateHole(params);
  // 处理成功结果
} on ArgumentError catch (e) {
  // 参数验证错误
  showErrorDialog('参数错误: ${e.message}');
} on CalculationException catch (e) {
  // 计算异常
  showErrorDialog('计算失败: ${e.message}');
} catch (e) {
  // 其他异常
  showErrorDialog('未知错误: $e');
}
```

## 最佳实践

### 使用建议

1. **参数验证**: 始终在计算前验证参数
2. **异常处理**: 妥善处理所有可能的异常情况
3. **结果验证**: 检查计算结果的工程合理性
4. **性能考虑**: 对于频繁计算，考虑使用缓存
5. **测试覆盖**: 确保充分的测试覆盖

### 常见陷阱

1. **精度丢失**: 避免不必要的类型转换
2. **参数混淆**: 确保参数单位和含义正确
3. **边界处理**: 注意极值参数的处理
4. **异常忽略**: 不要忽略计算警告和异常

---

**文档版本**: v1.0.0  
**最后更新**: ${DateTime.now().toIso8601String()}  
**维护者**: 计算引擎开发团队