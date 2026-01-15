import 'package:flutter_test/flutter_test.dart';
import 'package:pipeline_calculation_app/services/sync_service.dart';
import 'package:pipeline_calculation_app/services/local_data_service.dart';
import 'package:pipeline_calculation_app/models/calculation_record.dart';
import 'package:pipeline_calculation_app/models/parameter_set.dart';
import 'package:pipeline_calculation_app/models/enums.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// 生成Mock类
@GenerateMocks([http.Client, LocalDataService])
void main() {
  group('云同步服务单元测试', () {
    late SyncService syncService;
    late MockClient mockHttpClient;
    late MockLocalDataService mockLocalDataService;

    setUp(() {
      mockHttpClient = MockClient();
      mockLocalDataService = MockLocalDataService();
      syncService = SyncService(
        httpClient: mockHttpClient,
        localDataService: mockLocalDataService,
        baseUrl: 'https://api.example.com',
      );
    });

    group('用户认证', () {
      test('登录成功返回Token', () async {
        // Arrange
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success":true,"token":"test_token","userId":1,"username":"testuser"}',
          200,
        ));

        // Act
        final result = await syncService.login('testuser', 'password');

        // Assert
        expect(result.success, isTrue);
        expect(result.token, equals('test_token'));
        expect(result.userId, equals(1));
      });

      test('登录失败返回错误信息', () async {
        // Arrange
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success":false,"message":"用户名或密码错误"}',
          401,
        ));

        // Act
        final result = await syncService.login('testuser', 'wrongpassword');

        // Assert
        expect(result.success, isFalse);
        expect(result.message, contains('用户名或密码错误'));
      });

      test('注册成功返回Token', () async {
        // Arrange
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success":true,"token":"test_token","userId":1,"username":"newuser"}',
          200,
        ));

        // Act
        final result = await syncService.register(
          'newuser',
          'test@example.com',
          'password',
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.token, equals('test_token'));
      });
    });

    group('数据上传同步', () {
      test('上传计算记录成功', () async {
        // Arrange
        final record = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {'outerDiameter': 114.3},
          results: {'totalStroke': 65.8},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success":true,"serverId":100,"serverTimestamp":"2026-01-14T10:00:00Z"}',
          200,
        ));

        // Act
        final result = await syncService.uploadCalculationRecord(record, 'test_token');

        // Assert
        expect(result.success, isTrue);
        expect(result.serverId, equals(100));
      });

      test('上传参数组成功', () async {
        // Arrange
        final paramSet = ParameterSet(
          id: 1,
          name: '常用参数',
          calculationType: CalculationType.hole,
          parameters: {'outerDiameter': 114.3},
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
        );

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success":true,"serverId":50}',
          200,
        ));

        // Act
        final result = await syncService.uploadParameterSet(paramSet, 'test_token');

        // Assert
        expect(result.success, isTrue);
        expect(result.serverId, equals(50));
      });

      test('批量上传待同步记录', () async {
        // Arrange
        final records = List.generate(
          3,
          (i) => CalculationRecord(
            id: i + 1,
            calculationType: CalculationType.hole,
            parameters: {'index': i},
            results: {},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
          ),
        );

        when(mockLocalDataService.getPendingSyncRecords())
            .thenAnswer((_) async => records);

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success":true,"serverId":100}',
          200,
        ));

        // Act
        final results = await syncService.syncPendingRecords('test_token');

        // Assert
        expect(results.length, equals(3));
        expect(results.every((r) => r.success), isTrue);
      });
    });

    group('数据下载同步', () {
      test('下载新的计算记录', () async {
        // Arrange
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '[{"id":100,"calculationType":"hole","parameters":"{}","results":"{}","createdAt":"2026-01-14T10:00:00Z"}]',
          200,
        ));

        // Act
        final records = await syncService.downloadCalculationRecords(
          'test_token',
          DateTime.now().subtract(Duration(days: 1)),
        );

        // Assert
        expect(records, isNotEmpty);
        expect(records.first.id, equals(100));
      });

      test('下载新的参数组', () async {
        // Arrange
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '[{"id":50,"name":"参数组","calculationType":"hole","parameters":"{}"}]',
          200,
        ));

        // Act
        final sets = await syncService.downloadParameterSets(
          'test_token',
          DateTime.now().subtract(Duration(days: 1)),
        );

        // Assert
        expect(sets, isNotEmpty);
        expect(sets.first.id, equals(50));
      });
    });

    group('冲突检测', () {
      test('检测到数据冲突', () async {
        // Arrange
        final localRecord = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {'version': 1},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          clientId: 'client-123',
        );

        final serverRecord = CalculationRecord(
          id: 100,
          calculationType: CalculationType.hole,
          parameters: {'version': 2},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'client-123',
        );

        // Act
        final hasConflict = syncService.detectConflict(localRecord, serverRecord);

        // Assert
        expect(hasConflict, isTrue);
      });

      test('无冲突的记录', () async {
        // Arrange
        final localRecord = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {'version': 1},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          clientId: 'client-123',
        );

        final serverRecord = CalculationRecord(
          id: 100,
          calculationType: CalculationType.hole,
          parameters: {'version': 1},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'client-123',
        );

        // Act
        final hasConflict = syncService.detectConflict(localRecord, serverRecord);

        // Assert
        expect(hasConflict, isFalse);
      });
    });

    group('网络异常处理', () {
      test('网络超时重试', () async {
        // Arrange
        var attemptCount = 0;
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async {
          attemptCount++;
          if (attemptCount < 3) {
            throw Exception('网络超时');
          }
          return http.Response('{"success":true}', 200);
        });

        // Act
        final result = await syncService.uploadWithRetry(
          () => mockHttpClient.post(Uri.parse('https://api.example.com/test')),
          maxRetries: 3,
        );

        // Assert
        expect(result.statusCode, equals(200));
        expect(attemptCount, equals(3));
      });

      test('网络不可用时标记为失败', () async {
        // Arrange
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(Exception('网络不可用'));

        final record = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );

        // Act & Assert
        expect(
          () => syncService.uploadCalculationRecord(record, 'test_token'),
          throwsException,
        );
      });
    });

    group('同步状态管理', () {
      test('更新本地记录同步状态', () async {
        // Arrange
        final recordId = 1;
        when(mockLocalDataService.markRecordAsSynced(recordId))
            .thenAnswer((_) async => 1);

        // Act
        await syncService.markLocalRecordAsSynced(recordId);

        // Assert
        verify(mockLocalDataService.markRecordAsSynced(recordId)).called(1);
      });

      test('标记同步失败的记录', () async {
        // Arrange
        final recordId = 1;
        final errorMessage = '网络错误';
        when(mockLocalDataService.markRecordAsFailed(recordId, errorMessage))
            .thenAnswer((_) async => 1);

        // Act
        await syncService.markLocalRecordAsFailed(recordId, errorMessage);

        // Assert
        verify(mockLocalDataService.markRecordAsFailed(recordId, errorMessage))
            .called(1);
      });
    });

    group('完整同步流程', () {
      test('执行完整的双向同步', () async {
        // Arrange
        final pendingRecords = [
          CalculationRecord(
            id: 1,
            calculationType: CalculationType.hole,
            parameters: {},
            results: {},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
          ),
        ];

        when(mockLocalDataService.getPendingSyncRecords())
            .thenAnswer((_) async => pendingRecords);

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success":true,"serverId":100}',
          200,
        ));

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('[]', 200));

        // Act
        final result = await syncService.performFullSync('test_token');

        // Assert
        expect(result.success, isTrue);
        expect(result.uploadedCount, equals(1));
        expect(result.downloadedCount, equals(0));
      });
    });
  });
}
