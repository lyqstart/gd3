import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../lib/services/preset_parameter_initializer.dart';
import '../lib/services/database_helper.dart';
import '../lib/models/enums.dart';

/// 预设参数初始化器演示程序
/// 
/// 展示如何使用预设参数初始化器来管理预设数据
void main() async {
  print('=== 油气管道开孔封堵计算APP - 预设参数初始化器演示 ===\n');

  try {
    // 初始化FFI（用于桌面平台的SQLite支持）
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // 创建临时数据库用于演示
    final database = await openDatabase(
      ':memory:',
      version: 1,
      onCreate: (db, version) async {
        print('📊 创建演示数据库表结构...');
        
        // 创建参数组表
        await db.execute('''
          CREATE TABLE parameter_sets (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            calculation_type TEXT NOT NULL,
            parameters TEXT NOT NULL,
            is_preset INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            description TEXT,
            tags TEXT
          )
        ''');

        // 创建预设参数表
        await db.execute('''
          CREATE TABLE preset_parameters (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            calculation_type TEXT NOT NULL,
            parameter_name TEXT NOT NULL,
            parameter_value REAL NOT NULL,
            unit TEXT,
            description TEXT,
            category TEXT,
            created_at INTEGER NOT NULL
          )
        ''');

        // 创建用户设置表
        await db.execute('''
          CREATE TABLE user_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        
        print('✅ 数据库表结构创建完成\n');
      },
    );

    // 演示1: 初始化预设参数
    print('🚀 演示1: 初始化预设参数');
    print('=' * 50);
    
    final initResult = await PresetParameterInitializer.initializeAllPresetParameters(database);
    if (initResult) {
      print('✅ 预设参数初始化成功');
    } else {
      print('ℹ️  预设参数已是最新版本');
    }

    // 验证初始化结果
    final parameterSets = await database.query('parameter_sets', where: 'is_preset = 1');
    final presetParameters = await database.query('preset_parameters');
    
    print('📈 初始化统计:');
    print('   - 预设参数组数量: ${parameterSets.length}');
    print('   - 预设参数数量: ${presetParameters.length}');
    print('');

    // 演示2: 获取预设参数统计信息
    print('📊 演示2: 预设参数统计信息');
    print('=' * 50);
    
    final statistics = PresetParameterInitializer.getPresetParameterStatistics();
    print('按计算类型统计:');
    for (final entry in statistics.entries) {
      print('   - ${entry.key}: ${entry.value} 个参数');
    }
    print('');

    // 演示3: 获取分类统计信息
    print('🏷️  演示3: 分类统计信息');
    print('=' * 50);
    
    final categoryStats = PresetParameterInitializer.getCategorizedStatistics();
    print('按分类和计算类型统计:');
    for (final categoryEntry in categoryStats.entries) {
      print('   📂 ${categoryEntry.key}:');
      for (final typeEntry in categoryEntry.value.entries) {
        print('      - ${typeEntry.key}: ${typeEntry.value} 个参数');
      }
    }
    print('');

    // 演示4: 获取特定分类的预设参数
    print('🔧 演示4: 管道规格预设参数');
    print('=' * 50);
    
    final pipeParameters = PresetParameterInitializer.getPresetParametersByCategory('管道规格');
    print('管道规格参数 (${pipeParameters.length} 个):');
    for (final param in pipeParameters.take(5)) { // 只显示前5个
      print('   - ${param.name}: ${param.value} ${param.unit.symbol}');
      print('     描述: ${param.description}');
    }
    if (pipeParameters.length > 5) {
      print('   ... 还有 ${pipeParameters.length - 5} 个参数');
    }
    print('');

    // 演示5: 获取特定计算类型的预设参数
    print('⚙️  演示5: 开孔计算相关预设参数');
    print('=' * 50);
    
    final holeParameters = PresetParameterInitializer.getPresetParametersByTypeAndCategory(
      CalculationType.hole,
      '作业参数',
    );
    print('开孔计算作业参数 (${holeParameters.length} 个):');
    for (final param in holeParameters) {
      print('   - ${param.name}: ${param.value} ${param.unit.symbol}');
      print('     描述: ${param.description}');
    }
    print('');

    // 演示6: 获取详细统计信息
    print('📋 演示6: 详细统计信息');
    print('=' * 50);
    
    final detailedStats = PresetParameterInitializer.getDetailedStatistics();
    print('详细统计信息:');
    print('   - 版本: ${detailedStats['version']}');
    print('   - 参数组总数: ${detailedStats['total_parameter_sets']}');
    print('   - 参数总数: ${detailedStats['total_parameters']}');
    print('   - 数据验证: ${detailedStats['validation_passed'] ? '✅ 通过' : '❌ 失败'}');
    
    final availableCategories = detailedStats['available_categories'] as List<String>;
    print('   - 可用分类: ${availableCategories.join(', ')}');
    
    final parametersByUnit = detailedStats['parameters_by_unit'] as Map<String, int>;
    print('   - 按单位统计:');
    for (final entry in parametersByUnit.entries) {
      print('     * ${entry.key}: ${entry.value} 个参数');
    }
    print('');

    // 演示7: 验证预设参数数据
    print('✅ 演示7: 数据验证');
    print('=' * 50);
    
    final isValid = PresetParameterInitializer.validatePresetParameterData();
    print('预设参数数据验证结果: ${isValid ? '✅ 通过' : '❌ 失败'}');
    
    if (isValid) {
      print('所有预设参数数据都符合要求:');
      print('   - 参数值都大于0');
      print('   - 每个参数都有适用的计算类型');
      print('   - 参数组验证通过');
    }
    print('');

    // 演示8: 检查更新需求
    print('🔄 演示8: 检查更新需求');
    print('=' * 50);
    
    final needsUpdate = await PresetParameterInitializer.needsUpdate(database);
    print('是否需要更新: ${needsUpdate ? '是' : '否'}');
    
    if (!needsUpdate) {
      print('当前预设参数已是最新版本 v${PresetParameterInitializer.currentVersion}');
    }
    print('');

    // 演示9: 获取预设参数摘要
    print('📄 演示9: 预设参数摘要');
    print('=' * 50);
    
    final summary = PresetParameterInitializer.getPresetDataSummary();
    print('预设参数摘要:');
    for (final entry in summary.entries) {
      if (entry.value is Map) {
        print('   - ${entry.key}:');
        final map = entry.value as Map<String, dynamic>;
        for (final subEntry in map.entries) {
          print('     * ${subEntry.key}: ${subEntry.value}');
        }
      } else {
        print('   - ${entry.key}: ${entry.value}');
      }
    }
    print('');

    // 关闭数据库
    await database.close();
    
    print('🎉 演示完成！预设参数初始化器功能展示结束。');
    print('');
    print('💡 提示: 在实际应用中，预设参数初始化器会在应用启动时自动运行，');
    print('   确保所有必要的预设数据都已正确初始化到数据库中。');

  } catch (e, stackTrace) {
    print('❌ 演示过程中发生错误: $e');
    print('堆栈跟踪: $stackTrace');
    exit(1);
  }
}