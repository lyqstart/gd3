# 管道参数测试生成器

## 概述

`PipeParameterGenerator` 是一个智能的测试数据生成器，专门为油气管道开孔封堵计算APP设计。它能够生成各种类型的测试参数，包括有效参数、边界值参数、无效参数和特殊场景参数。

## 主要功能

### 1. 有效参数生成
生成符合工程实际应用的有效参数，确保所有参数都在合理范围内且通过验证。

```dart
// 生成有效的开孔参数
final holeParams = PipeParameterGenerator.generateValidHoleParameters();

// 生成有效的手动开孔参数
final manualParams = PipeParameterGenerator.generateValidManualHoleParameters();

// 生成有效的封堵参数
final sealingParams = PipeParameterGenerator.generateValidSealingParameters();

// 生成有效的下塞堵参数
final plugParams = PipeParameterGenerator.generateValidPlugParameters();

// 生成有效的下塞柄参数
final stemParams = PipeParameterGenerator.generateValidStemParameters();
```

### 2. 边界值参数生成
生成处于参数范围边界的测试用例，用于测试边界条件。

```dart
// 生成边界值开孔参数
final boundaryParams = PipeParameterGenerator.generateBoundaryHoleParameters();
```

### 3. 无效参数生成
生成会导致验证失败的参数组合，用于测试错误处理。

```dart
// 生成无效的开孔参数
final invalidHoleParams = PipeParameterGenerator.generateInvalidHoleParameters();

// 生成无效的手动开孔参数
final invalidManualParams = PipeParameterGenerator.generateInvalidManualHoleParameters();

// 其他类型的无效参数...
```

### 4. 特殊场景参数生成
基于实际工程应用场景生成参数。

```dart
// 小口径管道场景
final smallPipeParams = PipeParameterGenerator.generateSpecialScenarioHoleParameters('small_pipe');

// 大口径管道场景
final largePipeParams = PipeParameterGenerator.generateSpecialScenarioHoleParameters('large_pipe');

// 厚壁管道场景
final thickWallParams = PipeParameterGenerator.generateSpecialScenarioHoleParameters('thick_wall');

// 薄壁管道场景
final thinWallParams = PipeParameterGenerator.generateSpecialScenarioHoleParameters('thin_wall');

// 精度要求严格的场景
final precisionParams = PipeParameterGenerator.generateSpecialScenarioHoleParameters('precision_critical');
```

### 5. 压力测试参数生成
生成大量参数用于性能和压力测试。

```dart
// 生成100个压力测试参数
final stressTestParams = PipeParameterGenerator.generateStressTestParameters(100);
```

### 6. 参数序列生成
生成一系列渐变的参数，用于测试参数变化对计算结果的影响。

```dart
final baseParams = PipeParameterGenerator.generateValidHoleParameters();
final sequence = PipeParameterGenerator.generateParameterSequence(
  baseParams,
  'outerDiameter',  // 要变化的参数名
  100.0,            // 起始值
  200.0,            // 结束值
  11,               // 步数
);
```

### 7. 对称性测试参数生成
生成用于测试计算对称性的参数对。

```dart
final symmetryParams = PipeParameterGenerator.generateSymmetryTestParameters();
```

## 工具方法

### 参数验证
```dart
// 验证生成的参数是否符合预期
final isValid = PipeParameterGenerator.validateGeneratedParameters(params);
```

### 生成统计
```dart
// 获取参数生成统计信息
final stats = PipeParameterGenerator.getGenerationStatistics(paramsList);
// 返回: {total: 100, valid: 85, invalid: 15, validPercentage: "85.00"}
```

## 参数范围

生成器使用以下工程实际参数范围：

### 开孔参数
- 管外径: 50.0 - 2000.0 mm
- 管内径比例: 60% - 95% 的管外径
- 筒刀外径: 10.0 - 200.0 mm
- 筒刀内径比例: 50% - 90% 的筒刀外径
- A值: 10.0 - 200.0 mm
- B值: 5.0 - 100.0 mm
- R值: 5.0 - 50.0 mm
- 初始值: 0.0 - 20.0 mm
- 垫片厚度: 1.0 - 10.0 mm

### 手动开孔参数
- L值: 10.0 - 200.0 mm
- J值: 5.0 - 100.0 mm
- P值: 5.0 - 150.0 mm
- T值: 10.0 - 80.0 mm
- W值: 5.0 - 60.0 mm (确保 W < T)

### 封堵参数
- R值: 5.0 - 100.0 mm
- B值: 5.0 - 50.0 mm
- D值: 10.0 - 200.0 mm (确保 D > R)
- E值: 20.0 - 1800.0 mm
- 垫子厚度: 1.0 - 10.0 mm
- 初始值: 0.0 - 20.0 mm

## 精度保证

所有生成的参数都保持0.1mm的精度要求，符合应用的精度标准。

## 使用示例

查看 `generator_usage_example.dart` 文件获取完整的使用示例。

## 在测试中的应用

### 属性测试
```dart
test('开孔计算属性测试', () {
  for (int i = 0; i < 100; i++) {
    final params = PipeParameterGenerator.generateValidHoleParameters();
    final result = calculationEngine.calculateHoleSize(params);
    
    // 验证属性
    expect(result.emptyStroke, greaterThan(0));
    expect(result.totalStroke, greaterThan(result.emptyStroke));
  }
});
```

### 边界测试
```dart
test('边界条件测试', () {
  final boundaryParams = PipeParameterGenerator.generateBoundaryHoleParameters();
  final result = calculationEngine.calculateHoleSize(boundaryParams);
  
  // 验证边界条件下的行为
  expect(result.emptyStroke.isFinite, isTrue);
});
```

### 错误处理测试
```dart
test('错误处理测试', () {
  final invalidParams = PipeParameterGenerator.generateInvalidHoleParameters();
  
  expect(() => calculationEngine.calculateHoleSize(invalidParams),
         throwsA(isA<ValidationException>()));
});
```

## 注意事项

1. **参数关系**: 生成器确保参数之间的逻辑关系正确（如管外径 > 管内径）
2. **工程合理性**: 所有参数都在工程实际应用的合理范围内
3. **精度控制**: 所有数值都符合0.1mm的精度要求
4. **验证一致性**: 生成的参数与应用的验证逻辑保持一致

## 扩展

如需添加新的参数类型或场景，可以：

1. 在生成器中添加新的参数范围常量
2. 实现对应的生成方法
3. 添加相应的测试用例
4. 更新文档说明

生成器设计为可扩展的，便于随着应用功能的增加而扩展。