/// 简化的MySQL数据库连接测试程序
/// 
/// 此程序用于验证MySQL数据库连接和基本功能

import 'dart:convert';
import 'package:mysql1/mysql1.dart';

void main() async {
  print('=== MySQL数据库连接测试开始 ===');
  
  MySqlConnection? connection;
  
  try {
    // 1. 创建数据库连接
    print('\n1. 连接MySQL数据库...');
    final settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      password: '314697',
      db: 'pipeline_calc',
      timeout: Duration(seconds: 30),
    );
    
    connection = await MySqlConnection.connect(settings);
    print('✅ 数据库连接成功');
    
    // 2. 测试查询预设参数
    print('\n2. 查询预设参数数据...');
    final presetResults = await connection.query(
      'SELECT id, name, parameter_name, parameter_value, unit, category FROM preset_parameters WHERE is_deleted = FALSE ORDER BY category, name'
    );
    
    print('📋 预设参数列表 (共${presetResults.length}条):');
    String currentCategory = '';
    for (final row in presetResults) {
      final fields = row.fields;
      final category = fields['category'] ?? '';
      if (category != currentCategory) {
        currentCategory = category;
        print('  【$category】');
      }
      print('    - ${fields['name']}: ${fields['parameter_value']}${fields['unit']} (${fields['parameter_name']})');
    }
    
    // 3. 测试查询用户设置
    print('\n3. 查询用户设置数据...');
    final settingsResults = await connection.query(
      'SELECT setting_key, setting_value FROM user_settings ORDER BY setting_key'
    );
    
    print('⚙️ 用户设置列表 (共${settingsResults.length}条):');
    for (final row in settingsResults) {
      final fields = row.fields;
      print('    - ${fields['setting_key']}: ${fields['setting_value']}');
    }
    
    // 4. 测试插入计算记录
    print('\n4. 测试插入计算记录...');
    final testRecordId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    final testParameters = {
      'outerDiameter': 219.0,
      'innerDiameter': 200.0,
      'cutterOuterDiameter': 100.0,
      'gasketThickness': 3.0,
    };
    final testResults = {
      'emptyStroke': 150.5,
      'totalStroke': 250.8,
    };
    
    await connection.query('''
      INSERT INTO calculation_records 
      (id, calculation_type, parameters, results, created_at, updated_at, device_id)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', [
      testRecordId,
      'hole',
      jsonEncode(testParameters),
      jsonEncode(testResults),
      DateTime.now().millisecondsSinceEpoch,
      DateTime.now().millisecondsSinceEpoch,
      'test_device_001',
    ]);
    
    print('✅ 测试计算记录插入成功: $testRecordId');
    
    // 5. 查询刚插入的记录
    print('\n5. 验证插入的记录...');
    final recordResults = await connection.query(
      'SELECT id, calculation_type, parameters, results FROM calculation_records WHERE id = ?',
      [testRecordId]
    );
    
    if (recordResults.isNotEmpty) {
      final record = recordResults.first;
      final fields = record.fields;
      final params = jsonDecode(fields['parameters']);
      final results = jsonDecode(fields['results']);
      
      print('✅ 记录验证成功:');
      print('    - ID: ${fields['id']}');
      print('    - 类型: ${fields['calculation_type']}');
      print('    - 参数: 外径=${params['outerDiameter']}mm, 内径=${params['innerDiameter']}mm');
      print('    - 结果: 空行程=${results['emptyStroke']}mm, 总行程=${results['totalStroke']}mm');
    }
    
    // 6. 获取数据库统计信息
    print('\n6. 获取数据库统计信息...');
    final statsQueries = [
      'SELECT COUNT(*) as count FROM calculation_records WHERE is_deleted = FALSE',
      'SELECT COUNT(*) as count FROM preset_parameters WHERE is_deleted = FALSE',
      'SELECT COUNT(*) as count FROM user_settings',
      'SELECT COUNT(*) as count FROM parameter_sets WHERE is_deleted = FALSE',
    ];
    
    final tableNames = ['计算记录', '预设参数', '用户设置', '参数组'];
    
    print('📊 数据库统计:');
    for (int i = 0; i < statsQueries.length; i++) {
      final result = await connection.query(statsQueries[i]);
      final count = result.first.fields['count'];
      print('    - ${tableNames[i]}: $count 条');
    }
    
    // 7. 清理测试数据
    print('\n7. 清理测试数据...');
    await connection.query(
      'DELETE FROM calculation_records WHERE id = ?',
      [testRecordId]
    );
    print('✅ 测试数据清理完成');
    
    print('\n🎉 所有测试通过！MySQL数据库功能正常');
    
  } catch (e, stackTrace) {
    print('\n❌ 测试失败: $e');
    print('详细错误信息: $stackTrace');
  } finally {
    // 关闭数据库连接
    if (connection != null) {
      await connection.close();
      print('\n🔒 数据库连接已关闭');
    }
  }
  
  print('\n=== MySQL数据库连接测试结束 ===');
}