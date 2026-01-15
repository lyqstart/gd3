/// 简单的预设参数演示程序
/// 
/// 展示预设参数初始化器的核心功能，不依赖数据库
void main() {
  print('=== 油气管道开孔封堵计算APP - 预设参数演示 ===\n');

  // 演示1: 预设参数数据结构
  print('📊 演示1: 预设参数数据结构');
  print('=' * 50);
  
  final presetParameterSets = [
    {
      'id': 'preset_hole_small_pipe',
      'name': '小型管道开孔标准参数',
      'calculation_type': 'hole',
      'description': '适用于小型管道(DN50)的标准开孔参数',
      'tags': ['小型管道', '标准参数', 'DN50'],
      'parameters': {
        'outerDiameter': 60.3,
        'innerDiameter': 52.5,
        'cutterOuterDiameter': 25.4,
        'cutterInnerDiameter': 19.1,
        'aValue': 50.0,
        'bValue': 15.0,
        'rValue': 20.0,
        'initialValue': 5.0,
        'gasketThickness': 3.0,
      }
    },
    {
      'id': 'preset_hole_medium_pipe',
      'name': '中型管道开孔标准参数',
      'calculation_type': 'hole',
      'description': '适用于中型管道(DN100)的标准开孔参数',
      'tags': ['中型管道', '标准参数', 'DN100'],
      'parameters': {
        'outerDiameter': 114.3,
        'innerDiameter': 102.3,
        'cutterOuterDiameter': 25.4,
        'cutterInnerDiameter': 19.1,
        'aValue': 60.0,
        'bValue': 20.0,
        'rValue': 25.0,
        'initialValue': 5.0,
        'gasketThickness': 3.0,
      }
    },
  ];
  
  print('预设参数组数量: ${presetParameterSets.length}');
  for (final parameterSet in presetParameterSets) {
    print('   - ${parameterSet['name']}: ${parameterSet['description']}');
  }
  print('');

  // 演示2: 预设参数列表
  print('🔧 演示2: 预设参数列表');
  print('=' * 50);
  
  final presetParameters = [
    // 管道规格
    {'name': '管外径 - DN50 (2")', 'value': 60.3, 'unit': 'mm', 'category': '管道规格'},
    {'name': '管外径 - DN100 (4")', 'value': 114.3, 'unit': 'mm', 'category': '管道规格'},
    {'name': '管外径 - DN200 (8")', 'value': 219.1, 'unit': 'mm', 'category': '管道规格'},
    
    // 筒刀规格
    {'name': '筒刀外径 - 1" (25.4mm)', 'value': 25.4, 'unit': 'mm', 'category': '筒刀规格'},
    {'name': '筒刀外径 - 3/4" (19.1mm)', 'value': 19.1, 'unit': 'mm', 'category': '筒刀规格'},
    {'name': '筒刀内径 - 3/4" (19.1mm)', 'value': 19.1, 'unit': 'mm', 'category': '筒刀规格'},
    
    // 垫片规格
    {'name': '垫片厚度 - 薄型 (1.5mm)', 'value': 1.5, 'unit': 'mm', 'category': '垫片规格'},
    {'name': '垫片厚度 - 标准 (3.0mm)', 'value': 3.0, 'unit': 'mm', 'category': '垫片规格'},
    {'name': '垫片厚度 - 厚型 (6.0mm)', 'value': 6.0, 'unit': 'mm', 'category': '垫片规格'},
    
    // 作业参数
    {'name': 'A值 - 标准设置 (50mm)', 'value': 50.0, 'unit': 'mm', 'category': '作业参数'},
    {'name': 'B值 - 标准设置 (15mm)', 'value': 15.0, 'unit': 'mm', 'category': '作业参数'},
    {'name': 'R值 - 标准设置 (20mm)', 'value': 20.0, 'unit': 'mm', 'category': '作业参数'},
    
    // 螺纹参数
    {'name': 'T值 - M16螺纹 (16mm)', 'value': 16.0, 'unit': 'mm', 'category': '螺纹参数'},
    {'name': 'T值 - M20螺纹 (20mm)', 'value': 20.0, 'unit': 'mm', 'category': '螺纹参数'},
    {'name': 'W值 - 标准螺纹深度 (8mm)', 'value': 8.0, 'unit': 'mm', 'category': '螺纹参数'},
    
    // 初始设置
    {'name': '初始值 - 标准设置 (5mm)', 'value': 5.0, 'unit': 'mm', 'category': '初始设置'},
    {'name': '初始值 - 零位设置 (0mm)', 'value': 0.0, 'unit': 'mm', 'category': '初始设置'},
  ];
  
  print('预设参数总数: ${presetParameters.length}');
  print('');

  // 演示3: 按分类统计
  print('🏷️  演示3: 按分类统计');
  print('=' * 50);
  
  final categoryStats = <String, int>{};
  for (final param in presetParameters) {
    final category = param['category'] as String;
    categoryStats[category] = (categoryStats[category] ?? 0) + 1;
  }
  
  print('按分类统计:');
  for (final entry in categoryStats.entries) {
    print('   - ${entry.key}: ${entry.value} 个参数');
  }
  print('');

  // 演示4: 分类详细信息
  print('📋 演示4: 分类详细信息');
  print('=' * 50);
  
  for (final category in categoryStats.keys) {
    print('📂 $category:');
    final categoryParams = presetParameters
        .where((param) => param['category'] == category)
        .toList();
    
    for (final param in categoryParams) {
      print('   - ${param['name']}: ${param['value']} ${param['unit']}');
    }
    print('');
  }

  // 演示5: 参数验证
  print('✅ 演示5: 参数验证');
  print('=' * 50);
  
  bool allValid = true;
  int validCount = 0;
  
  for (final param in presetParameters) {
    final value = param['value'] as double;
    final name = param['name'] as String;
    
    if (value <= 0) {
      print('❌ 无效参数: $name = $value');
      allValid = false;
    } else {
      validCount++;
    }
  }
  
  print('参数验证结果: ${allValid ? '✅ 全部通过' : '❌ 存在问题'}');
  print('有效参数数量: $validCount / ${presetParameters.length}');
  print('');

  // 演示6: 参数ID生成
  print('🔑 演示6: 参数ID生成');
  print('=' * 50);
  
  final generatedIds = <String>{};
  
  for (final param in presetParameters.take(5)) { // 只演示前5个
    final name = param['name'] as String;
    final value = param['value'] as double;
    
    // 模拟ID生成逻辑
    final nameHash = name.hashCode.abs();
    final valueHash = value.hashCode.abs();
    final id = 'preset_${nameHash}_${valueHash}';
    
    print('   参数: $name');
    print('   生成ID: $id');
    print('   ID长度: ${id.length}');
    
    // 验证ID唯一性
    if (generatedIds.contains(id)) {
      print('   ⚠️  ID冲突!');
    } else {
      print('   ✅ ID唯一');
      generatedIds.add(id);
    }
    print('');
  }

  // 演示7: 参数名称提取
  print('📝 演示7: 参数名称提取');
  print('=' * 50);
  
  final testNames = [
    '管外径 - DN50 (2")',
    'A值 - 标准设置 (50mm)',
    '垫片厚度 - 标准 (3.0mm)',
    '简单参数名',
  ];
  
  for (final fullName in testNames) {
    String extractedName;
    if (fullName.contains(' - ')) {
      extractedName = fullName.split(' - ').first;
    } else {
      extractedName = fullName;
    }
    
    print('   完整名称: $fullName');
    print('   提取名称: $extractedName');
    print('');
  }

  // 演示8: 统计摘要
  print('📊 演示8: 统计摘要');
  print('=' * 50);
  
  final summary = {
    'version': 1,
    'parameter_sets_count': presetParameterSets.length,
    'preset_parameters_count': presetParameters.length,
    'categories_count': categoryStats.length,
    'validation_passed': allValid,
    'unique_ids_generated': generatedIds.length,
  };
  
  print('预设参数摘要:');
  for (final entry in summary.entries) {
    print('   - ${entry.key}: ${entry.value}');
  }
  print('');

  // 演示9: 使用场景
  print('💡 演示9: 使用场景');
  print('=' * 50);
  
  print('预设参数初始化器的主要用途:');
  print('   1. 应用启动时自动初始化预设数据');
  print('   2. 为用户提供常用的管道规格和参数');
  print('   3. 支持按计算类型和分类筛选参数');
  print('   4. 提供参数验证和数据完整性检查');
  print('   5. 支持版本管理和数据更新');
  print('   6. 生成唯一ID确保数据一致性');
  print('');

  print('🎉 演示完成！');
  print('');
  print('💡 提示: 在实际应用中，这些数据会存储在SQLite数据库中，');
  print('   并通过PresetParameterInitializer类进行管理和初始化。');
}