/// MySQL数据库连接测试程序
/// 
/// 此程序用于验证Flutter应用与MySQL数据库的连接是否正常工作
/// 测试内容包括：
/// 1. 数据库连接测试
/// 2. 预设参数数据读取测试
/// 3. 用户设置数据读取测试
/// 4. 计算记录插入测试

import 'dart:io';
import '../lib/services/remote_database_service.dart';
import '../lib/models/calculation_result.dart';
import '../lib/models/calculation_parameters.dart';
import '../lib/models/enums.dart';

void main() async {
  print('=== MySQL数据库连接测试开始 ===');
  
  final dbService = RemoteDatabaseService();
  
  try {
    // 1. 测试数据库连接
    print('\n1. 测试数据库连接...');
    await dbService.initializeDatabase();
    
    final isConnected = await dbService.isConnected();
    if (isConnected) {
      print('✅ 数据库连接成功');
    } else {
      print('❌ 数据库连接失败');
      return;
    }
    
    // 2. 测试获取数据库统计信息
    print('\n2. 获取数据库统计信息...');
    final stats = await dbService.getDatabaseStats();
    print('📊 数据库统计信息:');
    print('   - 总记录数: ${stats['total_records']}');
    print('   - 活跃设备数: ${stats['table_counts']['active_devices']}');
    print('   - 预设参数数: ${stats['table_counts']['preset_parameters']}');
    print('   - 用户设置数: ${stats['table_counts']['user_settings']}');
    
    // 3. 测试设备注册
    print('\n3. 测试设备注册...');
    const deviceId = 'test_device_001';
    const deviceName = 'Flutter测试设备';
    const platform = 'Windows';
    const appVersion = '1.0.0';
    
    await dbService.registerDevice(deviceId, deviceName, platform, appVersion);
    print('✅ 设备注册成功: $deviceName');
    
    // 4. 测试计算记录同步
    print('\n4. 测试计算记录同步...');
    
    // 创建测试计算参数
    final testParams = HoleCalculationParameters(
      outerDiameter: 219.0,
      innerDiameter: 200.0,
      cutterOuterDiameter: 100.0,
      gasketThickness: 3.0,
      threadPitch: 2.0,
      workingPressure: 4.0,
    );
    
    // 创建测试计算结果
    final testResult = CalculationResult(
      id: 'test_calc_${DateTime.now().millisecondsSinceEpoch}',
      calculationType: CalculationType.hole,
      parameters: testParams,
      emptyStroke: 150.5,
      totalStroke: 250.8,
      calculationTime: DateTime.now(),
    );
    
    // 同步到远程数据库
    await dbService.syncCalculationRecord(testResult, deviceId);
    print('✅ 计算记录同步成功: ${testResult.id}');
    
    // 5. 测试获取远程计算记录
    print('\n5. 测试获取远程计算记录...');
    final remoteRecords = await dbService.getRemoteCalculationRecords(
      deviceId: deviceId,
      limit: 5,
    );
    
    print('📋 获取到 ${remoteRecords.length} 条远程计算记录:');
    for (final record in remoteRecords) {
      print('   - ID: ${record['id']}');
      print('   - 类型: ${record['calculation_type']}');
      print('   - 创建时间: ${DateTime.fromMillisecondsSinceEpoch(record['created_at'])}');
    }
    
    // 6. 测试同步状态更新
    print('\n6. 测试同步状态更新...');
    await dbService.updateSyncStatus(
      deviceId,
      totalRecords: 1,
      syncedRecords: 1,
      failedRecords: 0,
    );
    print('✅ 同步状态更新成功');
    
    // 7. 获取最新统计信息
    print('\n7. 获取最新统计信息...');
    final finalStats = await dbService.getDatabaseStats();
    print('📊 最新数据库统计:');
    print('   - 计算记录数: ${finalStats['table_counts']['calculation_records']}');
    print('   - 活跃设备数: ${finalStats['table_counts']['active_devices']}');
    print('   - 最后更新: ${finalStats['last_updated']}');
    
    print('\n✅ 所有测试通过！MySQL数据库连接和功能正常');
    
  } catch (e, stackTrace) {
    print('\n❌ 测试失败: $e');
    print('堆栈跟踪: $stackTrace');
  } finally {
    // 清理资源
    await dbService.close();
    print('\n🔒 数据库连接已关闭');
  }
  
  print('\n=== MySQL数据库连接测试结束 ===');
}

/// 辅助函数：格式化时间戳
String formatTimestamp(int timestamp) {
  final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
         '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
}