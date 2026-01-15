import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../lib/services/preset_parameter_initializer.dart';
import '../../lib/models/enums.dart';
import '../../lib/models/parameter_models.dart';

void main() {
  // 初始化FFI
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('预设参数初始化器测试', () {
    late Database testDatabase;

    setUp(() async {
      // 创建内存数据库用于测试
      testDatabase = await openDatabase(
        ':memory:',
        version: 1,
        onCreate: (db, version) async {
          // 创建测试所需的表结构
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

          await db.execute('''
            CREATE TABLE user_settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
        },
      );
    });

    tearDown(() async {
      await testDatabase.close();
    });

    test('应该成功初始化所有预设参数', () async {
      // 执行初始化
      final result = await PresetParameterInitializer.initializeAllPresetParameters(testDatabase);
      
      // 验证初始化成功
      expect(result, isTrue);
      
      // 验证参数组数据
      final parameterSets = await testDatabase.query('parameter_sets', where: 'is_preset = 1');
      expect(parameterSets.length, greaterThan(0));
      
      // 验证预设参数数据
      final presetParameters = await testDatabase.query('preset_parameters');
      expect(presetParameters.length, greaterThan(0));
      
      // 验证版本号设置
      final versionResult = await testDatabase.query(
        'user_settings',
        where: 'key = ?',
        whereArgs: ['preset_parameters_version'],
      );
      expect(versionResult.length, equals(1));
      expect(int.parse(versionResult.first['value'] as String), 
             equals(PresetParameterInitializer.currentVersion));
    });

    test('应该正确分类预设参数', () {
      final statistics = PresetParameterInitializer.getCategorizedStatistics();
      
      // 验证分类存在
      expect(statistics.containsKey('管道规格'), isTrue);
      expect(statistics.containsKey('筒刀规格'), isTrue);
      expect(statistics.containsKey('垫片规格'), isTrue);
      expect(statistics.containsKey('螺纹参数'), isTrue);
      expect(statistics.containsKey('作业参数'), isTrue);
      expect(statistics.containsKey('初始设置'), isTrue);
      
      // 验证每个分类都有参数
      for (final category in statistics.keys) {
        final categoryStats = statistics[category]!;
        expect(categoryStats.values.any((count) => count > 0), isTrue);
      }
    });

    test('应该按计算类型正确统计预设参数', () {
      final statistics = PresetParameterInitializer.getPresetParameterStatistics();
      
      // 验证所有计算类型都有统计
      for (final type in CalculationType.values) {
        expect(statistics.containsKey(type.displayName), isTrue);
        expect(statistics[type.displayName], greaterThanOrEqualTo(0));
      }
      
      // 验证总计
      expect(statistics.containsKey('总计'), isTrue);
      expect(statistics['总计'], greaterThan(0));
    });

    test('应该验证预设参数数据的完整性', () {
      final isValid = PresetParameterInitializer.validatePresetParameterData();
      expect(isValid, isTrue);
    });

    test('应该按分类获取预设参数', () {
      final pipeParameters = PresetParameterInitializer.getPresetParametersByCategory('管道规格');
      expect(pipeParameters.length, greaterThan(0));
      
      // 验证所有参数都属于管道规格分类
      for (final parameter in pipeParameters) {
        expect(parameter.name.toLowerCase(), anyOf(
          contains('管外径'),
          contains('管内径'),
        ));
      }
    });

    test('应该按计算类型和分类获取预设参数', () {
      final holeParameters = PresetParameterInitializer.getPresetParametersByTypeAndCategory(
        CalculationType.hole,
        '管道规格',
      );
      
      expect(holeParameters.length, greaterThan(0));
      
      // 验证所有参数都适用于开孔计算
      for (final parameter in holeParameters) {
        expect(parameter.applicableTypes, contains(CalculationType.hole));
      }
    });

    test('应该生成详细的统计信息', () {
      final detailedStats = PresetParameterInitializer.getDetailedStatistics();
      
      // 验证统计信息结构
      expect(detailedStats.containsKey('version'), isTrue);
      expect(detailedStats.containsKey('total_parameter_sets'), isTrue);
      expect(detailedStats.containsKey('total_parameters'), isTrue);
      expect(detailedStats.containsKey('parameter_sets_by_type'), isTrue);
      expect(detailedStats.containsKey('parameters_by_unit'), isTrue);
      expect(detailedStats.containsKey('parameters_by_category'), isTrue);
      expect(detailedStats.containsKey('validation_passed'), isTrue);
      expect(detailedStats.containsKey('available_categories'), isTrue);
      
      // 验证数据有效性
      expect(detailedStats['validation_passed'], isTrue);
      expect(detailedStats['total_parameter_sets'], greaterThan(0));
      expect(detailedStats['total_parameters'], greaterThan(0));
    });

    test('应该检测是否需要更新', () async {
      // 初始状态应该需要更新
      final needsUpdateBefore = await PresetParameterInitializer.needsUpdate(testDatabase);
      expect(needsUpdateBefore, isTrue);
      
      // 初始化后不应该需要更新
      await PresetParameterInitializer.initializeAllPresetParameters(testDatabase);
      final needsUpdateAfter = await PresetParameterInitializer.needsUpdate(testDatabase);
      expect(needsUpdateAfter, isFalse);
    });

    test('应该支持强制重新初始化', () async {
      // 先进行初始化
      await PresetParameterInitializer.initializeAllPresetParameters(testDatabase);
      
      // 获取初始化后的记录数
      final initialParameterSets = await testDatabase.query('parameter_sets', where: 'is_preset = 1');
      final initialPresetParameters = await testDatabase.query('preset_parameters');
      
      // 强制重新初始化
      final result = await PresetParameterInitializer.forceReinitialize(testDatabase);
      expect(result, isTrue);
      
      // 验证数据重新生成
      final newParameterSets = await testDatabase.query('parameter_sets', where: 'is_preset = 1');
      final newPresetParameters = await testDatabase.query('preset_parameters');
      
      expect(newParameterSets.length, equals(initialParameterSets.length));
      expect(newPresetParameters.length, greaterThanOrEqualTo(initialPresetParameters.length));
    });

    test('应该生成有效的预设参数ID', () {
      // 由于_generatePresetParameterId是私有方法，我们通过其他方式测试
      final allPresets = PresetParameterInitializer.getPresetParametersByCategory('管道规格');
      expect(allPresets.length, greaterThan(0));
      
      // 验证预设参数的基本属性
      for (final preset in allPresets) {
        expect(preset.name, isNotEmpty);
        expect(preset.value, greaterThan(0));
        expect(preset.description, isNotEmpty);
        expect(preset.applicableTypes, isNotEmpty);
      }
    });

    test('应该正确提取参数名称', () {
      // 由于_extractParameterName是私有方法，我们通过公共接口测试
      final allPresets = PresetParameterInitializer.getPresetParametersByCategory('管道规格');
      
      // 验证参数名称格式
      for (final preset in allPresets) {
        expect(preset.name, contains(' - '));
        final parts = preset.name.split(' - ');
        expect(parts.length, greaterThanOrEqualTo(2));
        expect(parts.first, isNotEmpty);
      }
    });

    test('应该正确分类预设参数', () {
      // 测试各个分类的参数
      final categories = ['管道规格', '筒刀规格', '垫片规格', '螺纹参数', '初始设置', '作业参数'];
      
      for (final category in categories) {
        final parameters = PresetParameterInitializer.getPresetParametersByCategory(category);
        
        // 验证分类不为空（除了可能的其他参数分类）
        if (category != '其他参数') {
          expect(parameters.length, greaterThan(0), reason: '分类 $category 应该有参数');
        }
        
        // 验证参数名称与分类匹配
        for (final parameter in parameters) {
          switch (category) {
            case '管道规格':
              expect(parameter.name.toLowerCase(), anyOf(
                contains('管外径'),
                contains('管内径'),
              ));
              break;
            case '筒刀规格':
              expect(parameter.name.toLowerCase(), contains('筒刀'));
              break;
            case '垫片规格':
              expect(parameter.name.toLowerCase(), anyOf(
                contains('垫片'),
                contains('垫子'),
              ));
              break;
            case '螺纹参数':
              expect(parameter.name.toLowerCase(), anyOf(
                contains('螺纹'),
                contains('t值'),
                contains('w值'),
              ));
              break;
            case '初始设置':
              expect(parameter.name.toLowerCase(), contains('初始值'));
              break;
            case '作业参数':
              expect(parameter.name.toLowerCase(), contains('值'));
              break;
          }
        }
      }
    });

    test('重复初始化应该不会重复插入数据', () async {
      // 第一次初始化
      await PresetParameterInitializer.initializeAllPresetParameters(testDatabase);
      final firstCount = await testDatabase.query('preset_parameters');
      
      // 第二次初始化
      await PresetParameterInitializer.initializeAllPresetParameters(testDatabase);
      final secondCount = await testDatabase.query('preset_parameters');
      
      // 数据量应该相同（不重复插入）
      expect(secondCount.length, equals(firstCount.length));
    });
  });
}