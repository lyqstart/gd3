import 'package:flutter_test/flutter_test.dart';
import 'package:pipeline_calculation_app/services/sync_service.dart';
import 'package:pipeline_calculation_app/services/local_data_service.dart';
import 'package:pipeline_calculation_app/database/database_helper.dart';
import 'package:pipeline_calculation_app/models/calculation_record.dart';
import 'package:pipeline_calculation_app/models/enums.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:convert';

/// Mock HTTP客户端
class MockClient extends Mock implements http.Client {
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    // 如果是下载计算记录的请求,返回模拟数据
    if (url.path.contains('/api/sync/calculations')) {
      return Future.value(http.Response(
        jsonEncode([
          {
            'id': 100,
            'calculationType': 'hole',
            'parameters': {'outerDiameter': 114.3},
            'results': {'emptyStroke': 45.5},
            'createdAt': DateTime.now().toIso8601String(),
            'clientId': 'test-record-1',
          }
        ]),
        200,
      ));
    }
    
    return super.noSuchMethod(
      Invocation.method(#get, [url], {#headers: headers}),
      returnValue: Future.value(http.Response('', 404)),
      returnValueForMissingStub: Future.value(http.Response('', 404)),
    );
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    // 如果是上传计算记录的请求,返回成功响应
    if (url.path.contains('/api/sync/calculations')) {
      return Future.value(http.Response(
        jsonEncode({
          'success': true,
          'serverId': 100,
          'serverTimestamp': DateTime.now().toIso8601String(),
        }),
        200,
      ));
    }
    
    return super.noSuchMethod(
      Invocation.method(
        #post,
        [url],
        {#headers: headers, #body: body, #encoding: encoding},
      ),
      returnValue: Future.value(http.Response('', 404)),
      returnValueForMissingStub: Future.value(http.Response('', 404)),
    );
  }
}

/// 云同步基础功能测试
void main() {
  // 初始化FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('云同步基础功能测试', () {
    late SyncService syncService;
    late LocalDataService localDataService;
    late DatabaseHelper dbHelper;
    late MockClient mockHttpClient;

    setUp(() async {
      mockHttpClient = MockClient();
      dbHelper = DatabaseHelper();
      await dbHelper.database;
      localDataService = LocalDataService(dbHelper);
      syncService = SyncService(
        httpClient: mockHttpClient,
        localDataService: localDataService,
        baseUrl: 'https://api.example.com',
      );
    });

    tearDown(() async {
      await dbHelper.deleteAllRecords();
      await dbHelper.deleteAllParameterSets();
    });

    test('上传计算记录应返回成功结果', () async {
      final record = CalculationRecord(
        id: null,
        calculationType: CalculationType.hole,
        parameters: {'outerDiameter': 114.3, 'innerDiameter': 102.3},
        results: {'emptyStroke': 45.5},
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        clientId: 'test-record-1',
      );

      // MockClient已经在类中配置了响应
      final result = await syncService.uploadCalculationRecord(record, 'test_token');

      expect(result.success, isTrue);
      expect(result.serverId, equals(100));
    });

    test('下载计算记录应返回记录列表', () async {
      // MockClient已经在类中配置了响应
      final records = await syncService.downloadCalculationRecords('test_token');

      expect(records.length, equals(1));
      expect(records.first.id, equals(100));
    });

    test('检测冲突应正确识别不同的记录', () async {
      final local = CalculationRecord(
        id: 1,
        calculationType: CalculationType.hole,
        parameters: {'version': 'local'},
        results: {},
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        clientId: 'conflict-record',
      );

      final server = CalculationRecord(
        id: 100,
        calculationType: CalculationType.hole,
        parameters: {'version': 'server'},
        results: {},
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        clientId: 'conflict-record',
      );

      final hasConflict = syncService.detectConflict(local, server);
      expect(hasConflict, isTrue);
    });

    test('解决冲突应根据策略选择正确的记录', () async {
      final local = CalculationRecord(
        id: 1,
        calculationType: CalculationType.hole,
        parameters: {'source': 'local'},
        results: {},
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        clientId: 'conflict-record',
      );

      final server = CalculationRecord(
        id: 100,
        calculationType: CalculationType.hole,
        parameters: {'source': 'server'},
        results: {},
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        clientId: 'conflict-record',
      );

      // 测试保留本地数据策略
      final resolvedLocal = syncService.resolveConflict(
        local,
        server,
        ConflictResolutionStrategy.keepLocal,
      );
      expect(resolvedLocal.parameters['source'], equals('local'));

      // 测试保留服务器数据策略
      final resolvedServer = syncService.resolveConflict(
        local,
        server,
        ConflictResolutionStrategy.keepServer,
      );
      expect(resolvedServer.parameters['source'], equals('server'));
    });

    test('同步待上传记录应处理所有pending状态的记录', () async {
      // 保存待同步记录
      final record = CalculationRecord(
        id: null,
        calculationType: CalculationType.hole,
        parameters: {'test': true},
        results: {},
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        clientId: 'pending-record',
      );
      await localDataService.saveCalculationRecord(record);

      // MockClient已经在类中配置了上传成功响应
      final results = await syncService.syncPendingRecords('test_token');

      expect(results.length, greaterThan(0));
      expect(results.first.success, isTrue);
    });
  });
}
