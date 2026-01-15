import 'package:flutter_test/flutter_test.dart';
import 'package:pipeline_calculation_app/services/local_data_service.dart';
import 'package:pipeline_calculation_app/database/database_helper.dart';
import 'package:pipeline_calculation_app/models/calculation_record.dart';
import 'package:pipeline_calculation_app/models/parameter_set.dart';
import 'package:pipeline_calculation_app/models/enums.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // 初始化FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('本地数据服务单元测试', () {
    late LocalDataService dataService;
    late DatabaseHelper dbHelper;

    setUp(() async {
      // 使用内存数据库进行测试
      dbHelper = DatabaseHelper.instance;
      await dbHelper.database; // 初始化数据库
      dataService = LocalDataService(dbHelper);
    });

    tearDown(() async {
      // 清理测试数据
      await dbHelper.deleteAllRecords();
      await dbHelper.deleteAllParameterSets();
    });

    group('计算记录CRUD操作', () {
      test('保存计算记录', () async {
        final record = CalculationRecord(
          id: null,
          calculationType: CalculationType.hole,
          parameters: {
            'outerDiameter': 114.3,
            'innerDiameter': 102.3,
            'cutterOuterDiameter': 25.4,
          },
          results: {
            'emptyStroke': 45.5,
            'totalStroke': 65.8,
          },
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );

        final savedId = await dataService.saveCalculationRecord(record);
        
        expect(savedId, isNotNull);
        expect(savedId, greaterThan(0));
      });

      test('读取计算记录', () async {
        // 先保存一条记录
        final record = CalculationRecord(
          id: null,
          calculationType: CalculationType.sealing,
          parameters: {'rValue': 20.0},
          results: {'totalStroke': 100.0},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );

        final savedId = await dataService.saveCalculationRecord(record);
        
        // 读取记录
        final retrieved = await dataService.getCalculationRecord(savedId);
        
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(savedId));
        expect(retrieved.calculationType, equals(CalculationType.sealing));
        expect(retrieved.parameters['rValue'], equals(20.0));
      });

      test('更新计算记录', () async {
        // 保存记录
        final record = CalculationRecord(
          id: null,
          calculationType: CalculationType.plug,
          parameters: {'mValue': 100.0},
          results: {'totalStroke': 150.0},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );

        final savedId = await dataService.saveCalculationRecord(record);
        
        // 更新记录
        final updatedRecord = record.copyWith(
          id: savedId,
          syncStatus: SyncStatus.synced,
        );

        final updateCount = await dataService.updateCalculationRecord(updatedRecord);
        
        expect(updateCount, equals(1));
        
        // 验证更新
        final retrieved = await dataService.getCalculationRecord(savedId);
        expect(retrieved!.syncStatus, equals(SyncStatus.synced));
      });

      test('删除计算记录', () async {
        // 保存记录
        final record = CalculationRecord(
          id: null,
          calculationType: CalculationType.stem,
          parameters: {'fValue': 60.0},
          results: {'totalStroke': 138.0},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );

        final savedId = await dataService.saveCalculationRecord(record);
        
        // 删除记录
        final deleteCount = await dataService.deleteCalculationRecord(savedId);
        
        expect(deleteCount, equals(1));
        
        // 验证删除
        final retrieved = await dataService.getCalculationRecord(savedId);
        expect(retrieved, isNull);
      });

      test('查询所有计算记录', () async {
        // 保存多条记录
        for (int i = 0; i < 5; i++) {
          final record = CalculationRecord(
            id: null,
            calculationType: CalculationType.hole,
            parameters: {'outerDiameter': 100.0 + i},
            results: {'totalStroke': 50.0 + i},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
          );
          await dataService.saveCalculationRecord(record);
        }

        final allRecords = await dataService.getAllCalculationRecords();
        
        expect(allRecords.length, greaterThanOrEqualTo(5));
      });

      test('按类型查询计算记录', () async {
        // 保存不同类型的记录
        await dataService.saveCalculationRecord(CalculationRecord(
          id: null,
          calculationType: CalculationType.hole,
          parameters: {},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        ));

        await dataService.saveCalculationRecord(CalculationRecord(
          id: null,
          calculationType: CalculationType.sealing,
          parameters: {},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        ));

        final holeRecords = await dataService.getRecordsByType(CalculationType.hole);
        
        expect(holeRecords, isNotEmpty);
        expect(holeRecords.every((r) => r.calculationType == CalculationType.hole), isTrue);
      });
    });

    group('参数组CRUD操作', () {
      test('保存参数组', () async {
        final paramSet = ParameterSet(
          id: null,
          name: '常用管道参数',
          calculationType: CalculationType.hole,
          parameters: {
            'outerDiameter': 114.3,
            'innerDiameter': 102.3,
          },
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
        );

        final savedId = await dataService.saveParameterSet(paramSet);
        
        expect(savedId, isNotNull);
        expect(savedId, greaterThan(0));
      });

      test('读取参数组', () async {
        final paramSet = ParameterSet(
          id: null,
          name: '测试参数组',
          calculationType: CalculationType.sealing,
          parameters: {'rValue': 20.0},
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
        );

        final savedId = await dataService.saveParameterSet(paramSet);
        final retrieved = await dataService.getParameterSet(savedId);
        
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('测试参数组'));
        expect(retrieved.calculationType, equals(CalculationType.sealing));
      });

      test('更新参数组', () async {
        final paramSet = ParameterSet(
          id: null,
          name: '原始名称',
          calculationType: CalculationType.plug,
          parameters: {'mValue': 100.0},
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
        );

        final savedId = await dataService.saveParameterSet(paramSet);
        
        final updatedSet = paramSet.copyWith(
          id: savedId,
          name: '更新后的名称',
        );

        final updateCount = await dataService.updateParameterSet(updatedSet);
        
        expect(updateCount, equals(1));
        
        final retrieved = await dataService.getParameterSet(savedId);
        expect(retrieved!.name, equals('更新后的名称'));
      });

      test('删除参数组', () async {
        final paramSet = ParameterSet(
          id: null,
          name: '待删除参数组',
          calculationType: CalculationType.stem,
          parameters: {'fValue': 60.0},
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
        );

        final savedId = await dataService.saveParameterSet(paramSet);
        final deleteCount = await dataService.deleteParameterSet(savedId);
        
        expect(deleteCount, equals(1));
        
        final retrieved = await dataService.getParameterSet(savedId);
        expect(retrieved, isNull);
      });

      test('查询所有参数组', () async {
        for (int i = 0; i < 3; i++) {
          await dataService.saveParameterSet(ParameterSet(
            id: null,
            name: '参数组$i',
            calculationType: CalculationType.hole,
            parameters: {},
            createdAt: DateTime.now(),
            lastUsedAt: DateTime.now(),
          ));
        }

        final allSets = await dataService.getAllParameterSets();
        
        expect(allSets.length, greaterThanOrEqualTo(3));
      });

      test('按类型查询参数组', () async {
        await dataService.saveParameterSet(ParameterSet(
          id: null,
          name: '开孔参数',
          calculationType: CalculationType.hole,
          parameters: {},
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
        ));

        await dataService.saveParameterSet(ParameterSet(
          id: null,
          name: '封堵参数',
          calculationType: CalculationType.sealing,
          parameters: {},
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
        ));

        final holeSets = await dataService.getParameterSetsByType(CalculationType.hole);
        
        expect(holeSets, isNotEmpty);
        expect(holeSets.every((s) => s.calculationType == CalculationType.hole), isTrue);
      });
    });

    group('同步状态管理', () {
      test('获取待同步记录', () async {
        // 保存待同步记录
        await dataService.saveCalculationRecord(CalculationRecord(
          id: null,
          calculationType: CalculationType.hole,
          parameters: {},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        ));

        // 保存已同步记录
        await dataService.saveCalculationRecord(CalculationRecord(
          id: null,
          calculationType: CalculationType.sealing,
          parameters: {},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
        ));

        final pendingRecords = await dataService.getPendingSyncRecords();
        
        expect(pendingRecords, isNotEmpty);
        expect(pendingRecords.every((r) => r.syncStatus == SyncStatus.pending), isTrue);
      });

      test('标记记录为已同步', () async {
        final record = CalculationRecord(
          id: null,
          calculationType: CalculationType.plug,
          parameters: {},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );

        final savedId = await dataService.saveCalculationRecord(record);
        
        await dataService.markRecordAsSynced(savedId);
        
        final retrieved = await dataService.getCalculationRecord(savedId);
        expect(retrieved!.syncStatus, equals(SyncStatus.synced));
      });

      test('标记记录为同步失败', () async {
        final record = CalculationRecord(
          id: null,
          calculationType: CalculationType.stem,
          parameters: {},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );

        final savedId = await dataService.saveCalculationRecord(record);
        
        await dataService.markRecordAsFailed(savedId, '网络错误');
        
        final retrieved = await dataService.getCalculationRecord(savedId);
        expect(retrieved!.syncStatus, equals(SyncStatus.failed));
      });
    });

    group('离线功能测试', () {
      test('离线保存和读取', () async {
        // 模拟离线状态
        final record = CalculationRecord(
          id: null,
          calculationType: CalculationType.hole,
          parameters: {'outerDiameter': 114.3},
          results: {'totalStroke': 65.8},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );

        final savedId = await dataService.saveCalculationRecord(record);
        final retrieved = await dataService.getCalculationRecord(savedId);
        
        expect(retrieved, isNotNull);
        expect(retrieved!.syncStatus, equals(SyncStatus.pending));
      });

      test('离线数据完整性', () async {
        // 保存多条记录
        final records = <int>[];
        for (int i = 0; i < 10; i++) {
          final id = await dataService.saveCalculationRecord(CalculationRecord(
            id: null,
            calculationType: CalculationType.hole,
            parameters: {'index': i},
            results: {},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
          ));
          records.add(id);
        }

        // 验证所有记录都能读取
        for (final id in records) {
          final record = await dataService.getCalculationRecord(id);
          expect(record, isNotNull);
        }
      });
    });
  });
}
