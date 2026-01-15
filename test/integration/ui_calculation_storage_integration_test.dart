// 检查点3: 基础功能集成测试
// 验证UI界面、计算引擎和本地存储的集成

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/services/calculation_service.dart';
import '../../lib/services/local_data_service.dart';
import '../../lib/database/database_helper.dart';
import '../../lib/models/calculation_parameters.dart';
import '../../lib/models/calculation_record.dart';
import '../../lib/models/enums.dart';

void main() {
  // 初始化sqflite_ffi用于测试
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('检查点3: 基础功能集成测试', () {
    late DatabaseHelper dbHelper;
    late LocalDataService localDataService;
    late CalculationService calculationService;

    setUp(() async {
      // 删除现有数据库，确保使用新的schema
      dbHelper = DatabaseHelper();
      try {
        await dbHelper.deleteDatabase();
      } catch (e) {
        // 如果数据库不存在，忽略错误
      }
      
      // 重新创建数据库实例
      dbHelper = DatabaseHelper();
      localDataService = LocalDataService(dbHelper);
      calculationService = CalculationService();
      
      // 清空测试数据
      await dbHelper.clearAllData();
    });

    tearDown(() async {
      // 清理测试数据
      await dbHelper.clearAllData();
    });

    test('1. UI调用计算引擎 - 开孔计算', () async {
      // 模拟UI层创建参数
      final parameters = HoleParameters(
        outerDiameter: 114.3,
        innerDiameter: 102.3,
        cutterOuterDiameter: 25.4,
        cutterInnerDiameter: 19.1,
        aValue: 50.0,
        bValue: 15.0,
        rValue: 20.0,
        initialValue: 5.0,
        gasketThickness: 3.0,
      );

      // UI调用计算服务
      final result = await calculationService.calculate(
        CalculationType.hole,
        parameters.toJson(),
      );

      // 验证计算结果
      expect(result, isNotNull);
      expect(result.calculationType, CalculationType.hole);
      expect(result.getCoreResults(), isNotEmpty);
      
      print('✓ UI成功调用计算引擎完成开孔计算');
    });

    test('2. UI调用计算引擎 - 下塞堵计算', () async {
      // 模拟UI层创建参数
      final parameters = PlugParameters(
        mValue: 120.0,
        kValue: 60.0,
        nValue: 40.0,
        tValue: 20.0,
        wValue: 15.0,
      );

      // UI调用计算服务
      final result = await calculationService.calculate(
        CalculationType.plug,
        parameters.toJson(),
      );

      // 验证计算结果
      expect(result, isNotNull);
      expect(result.calculationType, CalculationType.plug);
      
      print('✓ UI成功调用计算引擎完成下塞堵计算');
    });

    test('3. UI调用计算引擎 - 下塞柄计算', () async {
      // 模拟UI层创建参数
      final parameters = StemParameters(
        fValue: 80.0,
        gValue: 60.0,
        hValue: 40.0,
        gasketThickness: 3.0,
        initialValue: 10.0,
      );

      // UI调用计算服务
      final result = await calculationService.calculate(
        CalculationType.stem,
        parameters.toJson(),
      );

      // 验证计算结果
      expect(result, isNotNull);
      expect(result.calculationType, CalculationType.stem);
      
      print('✓ UI成功调用计算引擎完成下塞柄计算');
    });

    test('4. 计算结果保存到本地存储', () async {
      // 执行计算
      final parameters = HoleParameters(
        outerDiameter: 114.3,
        innerDiameter: 102.3,
        cutterOuterDiameter: 25.4,
        cutterInnerDiameter: 19.1,
        aValue: 50.0,
        bValue: 15.0,
        rValue: 20.0,
        initialValue: 5.0,
        gasketThickness: 3.0,
      );

      final result = await calculationService.calculate(
        CalculationType.hole,
        parameters.toJson(),
      );

      // 创建计算记录（id为null，让数据库自动生成）
      final record = CalculationRecord(
        id: null,
        calculationType: CalculationType.hole,
        parameters: parameters.toJson(),
        results: result.toJson(),
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      // 保存到本地存储
      final recordId = await localDataService.saveCalculationRecord(record);
      expect(recordId, greaterThan(0));

      // 从本地存储读取（使用数据库生成的ID）
      final allRecords = await localDataService.getAllCalculationRecords();
      final savedRecord = allRecords.firstWhere(
        (r) => r.calculationType == CalculationType.hole && 
               r.parameters['outer_diameter'] == parameters.outerDiameter,
      );
      expect(savedRecord, isNotNull);
      expect(savedRecord.calculationType, CalculationType.hole);
      
      print('✓ 计算结果成功保存到本地存储');
    });

    test('5. 从本地存储加载历史记录', () async {
      // 保存多条计算记录
      for (int i = 0; i < 3; i++) {
        final parameters = HoleParameters(
          outerDiameter: 114.3 + i,
          innerDiameter: 102.3 + i,
          cutterOuterDiameter: 25.4,
          cutterInnerDiameter: 19.1,
          aValue: 50.0,
          bValue: 15.0,
          rValue: 20.0,
          initialValue: 5.0,
          gasketThickness: 3.0,
        );

        final result = await calculationService.calculate(
          CalculationType.hole,
          parameters.toJson(),
        );

        final record = CalculationRecord(
          id: null, // 让数据库自动生成ID
          calculationType: CalculationType.hole,
          parameters: parameters.toJson(),
          results: result.toJson(),
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );

        await localDataService.saveCalculationRecord(record);
      }

      // 从本地存储加载所有记录
      final allRecords = await localDataService.getAllCalculationRecords();
      expect(allRecords.length, greaterThanOrEqualTo(3));
      
      print('✓ 成功从本地存储加载${allRecords.length}条历史记录');
    });

    test('6. 完整工作流: UI输入 -> 计算 -> 保存 -> 读取', () async {
      // 步骤1: UI层创建参数（模拟用户输入）
      final parameters = StemParameters(
        fValue: 80.0,
        gValue: 60.0,
        hValue: 40.0,
        gasketThickness: 3.0,
        initialValue: 10.0,
      );
      print('  步骤1: UI创建参数 ✓');

      // 步骤2: 调用计算引擎
      final result = await calculationService.calculate(
        CalculationType.stem,
        parameters.toJson(),
      );
      expect(result, isNotNull);
      print('  步骤2: 计算引擎执行计算 ✓');

      // 步骤3: 保存到本地存储
      final record = CalculationRecord(
        id: null, // 让数据库自动生成ID
        calculationType: CalculationType.stem,
        parameters: parameters.toJson(),
        results: result.toJson(),
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );
      final recordId = await localDataService.saveCalculationRecord(record);
      expect(recordId, greaterThan(0));
      print('  步骤3: 保存到本地存储 ✓');

      // 步骤4: 从本地存储读取
      final savedRecord = await localDataService.getCalculationRecord(recordId);
      expect(savedRecord, isNotNull);
      expect(savedRecord!.calculationType, CalculationType.stem);
      print('  步骤4: 从本地存储读取 ✓');

      // 步骤5: 验证数据完整性
      expect(savedRecord.parameters, equals(parameters.toJson()));
      expect(savedRecord.results, equals(result.toJson()));
      print('  步骤5: 数据完整性验证 ✓');

      print('✓ 完整工作流测试通过');
    });

    test('7. 参数验证集成', () async {
      // 测试无效参数
      final invalidParameters = HoleParameters(
        outerDiameter: -10.0, // 无效：负数
        innerDiameter: 102.3,
        cutterOuterDiameter: 25.4,
        cutterInnerDiameter: 19.1,
        aValue: 50.0,
        bValue: 15.0,
        rValue: 20.0,
        initialValue: 5.0,
        gasketThickness: 3.0,
      );

      // 验证参数
      final validation = await calculationService.validateParameters(
        CalculationType.hole,
        invalidParameters.toJson(),
      );

      expect(validation.isValid, false);
      expect(validation.message, isNotEmpty);
      
      print('✓ 参数验证正常工作');
    });

    test('8. 多种计算类型的集成', () async {
      final calculationTypes = [
        CalculationType.hole,
        CalculationType.plug,
        CalculationType.stem,
      ];

      for (final type in calculationTypes) {
        // 创建对应类型的参数
        Map<String, dynamic> parameters;
        switch (type) {
          case CalculationType.hole:
            parameters = HoleParameters(
              outerDiameter: 114.3,
              innerDiameter: 102.3,
              cutterOuterDiameter: 25.4,
              cutterInnerDiameter: 19.1,
              aValue: 50.0,
              bValue: 15.0,
              rValue: 20.0,
              initialValue: 5.0,
              gasketThickness: 3.0,
            ).toJson();
            break;
          case CalculationType.plug:
            parameters = PlugParameters(
              mValue: 120.0,
              kValue: 60.0,
              nValue: 40.0,
              tValue: 20.0,
              wValue: 15.0,
            ).toJson();
            break;
          case CalculationType.stem:
            parameters = StemParameters(
              fValue: 80.0,
              gValue: 60.0,
              hValue: 40.0,
              gasketThickness: 3.0,
              initialValue: 10.0,
            ).toJson();
            break;
          default:
            continue;
        }

        // 执行计算
        final result = await calculationService.calculate(type, parameters);
        expect(result, isNotNull);

        // 保存记录
        final record = CalculationRecord(
          id: null, // 让数据库自动生成ID
          calculationType: type,
          parameters: parameters,
          results: result.toJson(),
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );
        await localDataService.saveCalculationRecord(record);

        print('  ${type.displayName}: 计算 + 存储 ✓');
      }

      // 验证所有记录都已保存
      final allRecords = await localDataService.getAllCalculationRecords();
      expect(allRecords.length, greaterThanOrEqualTo(3));
      
      print('✓ 多种计算类型集成测试通过');
    });

    test('9. 本地存储的CRUD操作', () async {
      // Create - 创建记录
      final parameters = HoleParameters(
        outerDiameter: 114.3,
        innerDiameter: 102.3,
        cutterOuterDiameter: 25.4,
        cutterInnerDiameter: 19.1,
        aValue: 50.0,
        bValue: 15.0,
        rValue: 20.0,
        initialValue: 5.0,
        gasketThickness: 3.0,
      );

      final result = await calculationService.calculate(
        CalculationType.hole,
        parameters.toJson(),
      );

      final record = CalculationRecord(
        id: null, // 让数据库自动生成ID
        calculationType: CalculationType.hole,
        parameters: parameters.toJson(),
        results: result.toJson(),
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      final recordId = await localDataService.saveCalculationRecord(record);
      expect(recordId, greaterThan(0));
      print('  Create: 创建记录 ✓');

      // Read - 读取记录
      final readRecord = await localDataService.getCalculationRecord(recordId);
      expect(readRecord, isNotNull);
      print('  Read: 读取记录 ✓');

      // Update - 更新记录
      final updatedRecord = CalculationRecord(
        id: recordId,
        calculationType: readRecord!.calculationType,
        parameters: readRecord.parameters,
        results: readRecord.results,
        createdAt: readRecord.createdAt,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );
      await localDataService.updateCalculationRecord(updatedRecord);
      
      final verifyUpdate = await localDataService.getCalculationRecord(recordId);
      expect(verifyUpdate!.syncStatus, SyncStatus.synced);
      print('  Update: 更新记录 ✓');

      // Delete - 删除记录
      await localDataService.deleteCalculationRecord(recordId);
      final verifyDelete = await localDataService.getCalculationRecord(recordId);
      expect(verifyDelete, isNull);
      print('  Delete: 删除记录 ✓');

      print('✓ 本地存储CRUD操作测试通过');
    });

    test('10. 数据库统计信息', () async {
      // 保存一些测试数据
      for (int i = 0; i < 5; i++) {
        final parameters = HoleParameters(
          outerDiameter: 114.3,
          innerDiameter: 102.3,
          cutterOuterDiameter: 25.4,
          cutterInnerDiameter: 19.1,
          aValue: 50.0,
          bValue: 15.0,
          rValue: 20.0,
          initialValue: 5.0,
          gasketThickness: 3.0,
        );

        final result = await calculationService.calculate(
          CalculationType.hole,
          parameters.toJson(),
        );

        final record = CalculationRecord(
          id: null, // 让数据库自动生成ID
          calculationType: CalculationType.hole,
          parameters: parameters.toJson(),
          results: result.toJson(),
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );

        await localDataService.saveCalculationRecord(record);
      }

      // 获取统计信息
      final stats = await dbHelper.getDatabaseStats();
      expect(stats['calculation_records'], greaterThanOrEqualTo(5));
      
      print('✓ 数据库统计: ${stats['calculation_records']}条计算记录');
    });
  });
}
