/// 基础MySQL数据库连接测试
/// 验证数据库连接和基本CRUD操作

import 'dart:convert';
import 'package:mysql1/mysql1.dart';

void main() async {
  print('=== 基础MySQL数据库测试 ===');
  
  MySqlConnection? connection;
  
  try {
    // 连接数据库
    print('\n🔗 连接MySQL数据库...');
    final settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      password: '314697',
      db: 'pipeline_calc',
    );
    
    connection = await MySqlConnection.connect(settings);
    print('✅ 数据库连接成功');
    
    // 测试基本查询
    print('\n📊 测试数据库表统计...');
    
    // 查询预设参数数量
    var result = await connection.query('SELECT COUNT(*) as count FROM preset_parameters WHERE is_deleted = 0');
    if (result.isNotEmpty) {
      var presetCount = result.first[0];
      print('预设参数数量: $presetCount');
    }
    
    // 查询用户设置数量
    result = await connection.query('SELECT COUNT(*) as count FROM user_settings');
    if (result.isNotEmpty) {
      var settingsCount = result.first[0];
      print('用户设置数量: $settingsCount');
    }
    
    // 查询计算记录数量
    result = await connection.query('SELECT COUNT(*) as count FROM calculation_records WHERE is_deleted = 0');
    if (result.isNotEmpty) {
      var recordsCount = result.first[0];
      print('计算记录数量: $recordsCount');
    }
    
    // 测试插入和查询
    print('\n🧪 测试数据插入和查询...');
    
    final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    final testParams = jsonEncode({
      'outerDiameter': 219.0,
      'innerDiameter': 200.0,
      'cutterOuterDiameter': 100.0,
    });
    final testResults = jsonEncode({
      'emptyStroke': 150.5,
      'totalStroke': 250.8,
    });
    
    // 插入测试记录
    await connection.query('''
      INSERT INTO calculation_records 
      (id, calculation_type, parameters, results, created_at, updated_at, device_id, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      testId,
      'hole',
      testParams,
      testResults,
      DateTime.now().millisecondsSinceEpoch,
      DateTime.now().millisecondsSinceEpoch,
      'test_device',
      0,
    ]);
    
    print('✅ 测试记录插入成功: $testId');
    
    // 查询刚插入的记录
    result = await connection.query(
      'SELECT id, calculation_type, parameters, results FROM calculation_records WHERE id = ?',
      [testId]
    );
    
    if (result.isNotEmpty) {
      final row = result.first;
      print('✅ 记录查询成功:');
      print('   ID: ${row[0]}');
      print('   类型: ${row[1]}');
      print('   参数: ${row[2]}');
      print('   结果: ${row[3]}');
    }
    
    // 清理测试数据
    await connection.query('DELETE FROM calculation_records WHERE id = ?', [testId]);
    print('✅ 测试数据清理完成');
    
    // 显示一些预设参数示例
    print('\n📋 预设参数示例:');
    result = await connection.query(
      'SELECT name, parameter_value, unit, category FROM preset_parameters WHERE is_deleted = 0 LIMIT 5'
    );
    
    for (final row in result) {
      print('   ${row[0]}: ${row[1]}${row[2]} (${row[3]})');
    }
    
    // 显示用户设置
    print('\n⚙️ 用户设置:');
    result = await connection.query('SELECT setting_key, setting_value FROM user_settings LIMIT 6');
    
    for (final row in result) {
      print('   ${row[0]}: ${row[1]}');
    }
    
    print('\n🎉 所有测试通过！数据库功能正常');
    
  } catch (e, stackTrace) {
    print('\n❌ 测试失败: $e');
    print('堆栈跟踪: $stackTrace');
  } finally {
    if (connection != null) {
      await connection.close();
      print('\n🔒 数据库连接已关闭');
    }
  }
  
  print('\n=== 测试完成 ===');
}