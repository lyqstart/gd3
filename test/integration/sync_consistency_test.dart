import 'package:flutter_test/flutter_test.dart';
import 'package:pipeline_calculation_app/services/sync_service.dart';
import 'package:pipeline_calculation_app/services/local_data_service.dart';
import 'package:pipeline_calculation_app/database/database_helper.dart';
import 'package:pipeline_calculation_app/models/calculation_record.dart';
import 'package:pipeline_calculation_app/models/parameter_set.dart';
import 'package:pipeline_calculation_app/models/enums.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:convert';

/// Mock HTTP客户端 - 用于同步一致性测试
class MockClient extends Mock implements http.Client {}

/// H3: 同步一致性测试
/// 
/// 验证多设备数据同步的一致性、冲突解决的正确性、
/// 网络异常情况下的数据完整性和同步性能可靠性
/// 
/// 需求: 9.3-9.6, 13.2
void main() {
  // 初始化FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('H3: 同步一致性测试', () {
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

    group('多设备数据同步一致性(需求9.3, 9.4)', () {
      test('设备A上传数据后，设备B应能下载到相同数据', () async {
        // 模拟设备A上传数据
        final recordA = CalculationRecord(
          id: null,
          calculationType: CalculationType.hole,
          parameters: {
            'outerDiameter': 114.3,
            'innerDiameter': 102.3,
            'aValue': 50.0,
          },
          results: {
            'emptyStroke': 45.5,
            'totalStroke': 65.8,
          },
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          clientId: 'device-A-record-1',
        );

        // 模拟上传成功响应
        when(mockHttpClient.post(
          argThat(isA<Uri>()),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'success': true,
            'serverId': 100,
            'serverTimestamp': DateTime.now().toIso8601String(),
          }),
          200,
        ));

        final uploadResult = await syncService.uploadCalculationRecord(
          recordA,
          'test_token',
        );

        expect(uploadResult.success, isTrue);
        expect(uploadResult.serverId, equals(100));

        // 模拟设备B下载数据
        when(mockHttpClient.get(
          argThat(isA<Uri>()),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode([
            {
              'id': 100,
              'calculationType': 'hole',
              'parameters': jsonEncode(recordA.parameters),
              'results': jsonEncode(recordA.results),
              'createdAt': recordA.createdAt.toIso8601String(),
              'clientId': 'device-A-record-1',
            }
          ]),
          200,
        ));

        final downloadedRecords = await syncService.downloadCalculationRecords(
          'test_token',
          DateTime.now().subtract(Duration(hours: 1)),
        );

        expect(downloadedRecords.length, equals(1));
        final recordB = downloadedRecords.first;

        // 验证数据一致性
        expect(recordB.id, equals(100));
        expect(recordB.calculationType, equals(recordA.calculationType));
        expect(recordB.parameters['outerDiameter'], 
               equals(recordA.parameters['outerDiameter']));
        expect(recordB.results['totalStroke'], 
               equals(recordA.results['totalStroke']));
        expect(recordB.clientId, equals(recordA.clientId));
      });

      test('多设备同时上传不同数据应都能成功', () async {
        final records = <CalculationRecord>[];
        
        // 模拟3个设备同时上传数据
        for (int i = 0; i < 3; i++) {
          records.add(CalculationRecord(
            id: null,
            calculationType: CalculationType.hole,
            parameters: {'deviceId': i, 'value': 100.0 + i},
            results: {'result': 200.0 + i},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
            clientId: 'device-$i-record-1',
          ));
        }

        var serverId = 100;
        when(mockHttpClient.post(
          argThat(isA<Uri>()),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async {
          final response = {
            'success': true,
            'serverId': serverId++,
            'serverTimestamp': DateTime.now().toIso8601String(),
          };
          return http.Response(jsonEncode(response), 200);
        });

        // 上传所有记录
        final uploadResults = <dynamic>[];
        for (final record in records) {
          final result = await syncService.uploadCalculationRecord(
            record,
            'test_token',
          );
          uploadResults.add(result);
        }

        // 验证所有上传都成功
        expect(uploadResults.length, equals(3));
        expect(uploadResults.every((r) => r.success), isTrue);
        
        // 验证服务器ID唯一
        final serverIds = uploadResults.map((r) => r.serverId).toSet();
        expect(serverIds.length, equals(3));
      });

      test('设备离线期间的数据应在重新上线后同步', () async {
        // 模拟离线期间保存的数据
        final offlineRecords = <CalculationRecord>[];
        for (int i = 0; i < 5; i++) {
          final record = CalculationRecord(
            id: null,
            calculationType: CalculationType.hole,
            parameters: {'offline': true, 'index': i},
            results: {},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
            clientId: 'offline-record-$i',
          );
          
          final id = await localDataService.saveCalculationRecord(record);
          offlineRecords.add(record.copyWith(id: id));
        }

        // 模拟重新上线后同步
        when(mockHttpClient.post(
          argThat(isA<Uri>()),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'success': true,
            'serverId': 100,
            'serverTimestamp': DateTime.now().toIso8601String(),
          }),
          200,
        ));

        final syncResults = await syncService.syncPendingRecords('test_token');

        // 验证所有离线数据都已同步
        expect(syncResults.length, equals(5));
        expect(syncResults.every((r) => r.success), isTrue);
      });
    });

    group('冲突检测和解决机制 (需求9.6)', () {
      test('检测到冲突时应提示用户选择解决策略', () async {
        final localRecord = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {'version': 'local', 'value': 100.0},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          clientId: 'conflict-record',
        );

        final serverRecord = CalculationRecord(
          id: 100,
          calculationType: CalculationType.hole,
          parameters: {'version': 'server', 'value': 200.0},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'conflict-record',
        );

        final hasConflict = syncService.detectConflict(localRecord, serverRecord);
        
        expect(hasConflict, isTrue);
      });

      test('用户选择保留本地数据后应正确解决冲突', () async {
        final localRecord = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {'source': 'local'},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          clientId: 'conflict-record',
        );

        final serverRecord = CalculationRecord(
          id: 100,
          calculationType: CalculationType.hole,
          parameters: {'source': 'server'},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'conflict-record',
        );

        final resolved = syncService.resolveConflict(
          localRecord,
          serverRecord,
          ConflictResolutionStrategy.keepLocal,
        );

        expect(resolved.parameters['source'], equals('local'));
      });

      test('用户选择保留服务器数据后应正确解决冲突', () async {
        final localRecord = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {'source': 'local'},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          clientId: 'conflict-record',
        );

        final serverRecord = CalculationRecord(
          id: 100,
          calculationType: CalculationType.hole,
          parameters: {'source': 'server'},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'conflict-record',
        );

        final resolved = syncService.resolveConflict(
          localRecord,
          serverRecord,
          ConflictResolutionStrategy.keepServer,
        );

        expect(resolved.parameters['source'], equals('server'));
      });

      test('用户选择保留最新数据后应正确解决冲突', () async {
        final now = DateTime.now();
        final olderTime = now.subtract(Duration(hours: 1));

        final olderRecord = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {'timestamp': 'older'},
          results: {},
          createdAt: olderTime,
          syncStatus: SyncStatus.pending,
          clientId: 'conflict-record',
        );

        final newerRecord = CalculationRecord(
          id: 100,
          calculationType: CalculationType.hole,
          parameters: {'timestamp': 'newer'},
          results: {},
          createdAt: now,
          syncStatus: SyncStatus.synced,
          clientId: 'conflict-record',
        );

        final resolved = syncService.resolveConflict(
          olderRecord,
          newerRecord,
          ConflictResolutionStrategy.keepNewest,
        );

        expect(resolved.parameters['timestamp'], equals('newer'));
      });
    });

    group('网络异常情况下的数据完整性', () {
      test('网络超时时应重试上传', () async {
        var attemptCount = 0;
        
        when(mockHttpClient.post(
          argThat(isA<Uri>()),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async {
          attemptCount++;
          if (attemptCount < 3) {
            throw Exception('网络超时');
          }
          return http.Response(
            jsonEncode({'success': true, 'serverId': 100}),
            200,
          );
        });

        final record = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );

        final result = await syncService.uploadCalculationRecordWithRetry(
          record,
          'test_token',
          maxRetries: 3,
        );

        expect(result.success, isTrue);
        expect(attemptCount, equals(3));
      });

      test('网络完全不可用时应标记为失败并保留本地数据', () async {
        when(mockHttpClient.post(
          argThat(isA<Uri>()),
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

        await localDataService.saveCalculationRecord(record);

        try {
          await syncService.uploadCalculationRecord(record, 'test_token');
          fail('应该抛出异常');
        } catch (e) {
          // 验证本地数据仍然存在
          final localRecord = await localDataService.getCalculationRecord(1);
          expect(localRecord, isNotNull);
          expect(localRecord!.syncStatus, equals(SyncStatus.pending));
        }
      });

      test('部分数据上传失败时应记录失败项并继续其他项', () async {
        final records = <CalculationRecord>[];
        for (int i = 0; i < 5; i++) {
          records.add(CalculationRecord(
            id: i + 1,
            calculationType: CalculationType.hole,
            parameters: {'index': i},
            results: {},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
            clientId: 'record-$i',
          ));
        }

        var callCount = 0;
        when(mockHttpClient.post(
          argThat(isA<Uri>()),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async {
          callCount++;
          // 第3个请求失败
          if (callCount == 3) {
            throw Exception('上传失败');
          }
          return http.Response(
            jsonEncode({'success': true, 'serverId': 100 + callCount}),
            200,
          );
        });

        final results = <dynamic>[];
        for (final record in records) {
          try {
            final result = await syncService.uploadCalculationRecord(
              record,
              'test_token',
            );
            results.add(result);
          } catch (e) {
            results.add({'success': false, 'error': e.toString()});
          }
        }

        // 验证4个成功，1个失败
        final successCount = results.where((r) => r.success == true).length;
        expect(successCount, equals(4));
      });
    });

    group('同步性能和可靠性', () {
      test('批量同步100条记录应在合理时间内完成', () async {
        final records = <CalculationRecord>[];
        for (int i = 0; i < 100; i++) {
          records.add(CalculationRecord(
            id: i + 1,
            calculationType: CalculationType.hole,
            parameters: {'index': i},
            results: {},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
            clientId: 'batch-record-$i',
          ));
        }

        when(mockHttpClient.post(
          argThat(isA<Uri>()),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'success': true, 'serverId': 100}),
          200,
        ));

        final stopwatch = Stopwatch()..start();
        
        final results = <dynamic>[];
        for (final record in records) {
          final result = await syncService.uploadCalculationRecord(
            record,
            'test_token',
          );
          results.add(result);
        }

        stopwatch.stop();

        // 验证所有记录都成功
        expect(results.length, equals(100));
        expect(results.every((r) => r.success), isTrue);
        
        // 验证性能（应在10秒内完成）
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      });

      test('同步过程中断后应能从断点继续', () async {
        // 保存10条待同步记录
        for (int i = 0; i < 10; i++) {
          await localDataService.saveCalculationRecord(CalculationRecord(
            id: null,
            calculationType: CalculationType.hole,
            parameters: {'index': i},
            results: {},
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
            clientId: 'resume-record-$i',
          ));
        }

        var callCount = 0;
        when(mockHttpClient.post(
          argThat(isA<Uri>()),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async {
          callCount++;
          // 前5个成功
          if (callCount <= 5) {
            return http.Response(
              jsonEncode({'success': true, 'serverId': 100 + callCount}),
              200,
            );
          }
          // 后5个失败，模拟中断
          throw Exception('同步中断');
        });

        // 第一次同步（会在第6个记录时中断）
        try {
          await syncService.syncPendingRecords('test_token');
        } catch (e) {
          // 预期会失败
        }

        // 验证前5个已标记为已同步
        final pendingRecords = await localDataService.getPendingSyncRecords();
        expect(pendingRecords.length, lessThan(10));
      });
    });

    group('数据一致性验证(需求13.2)', () {
      test('同步后本地和服务器数据应完全一致', () async {
        final originalRecord = CalculationRecord(
          id: null,
          calculationType: CalculationType.hole,
          parameters: {
            'outerDiameter': 114.3,
            'innerDiameter': 102.3,
            'aValue': 50.0,
            'bValue': 30.0,
          },
          results: {
            'emptyStroke': 45.5,
            'totalStroke': 65.8,
            'plateStroke': 78.9,
          },
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          clientId: 'consistency-test',
        );

        // 上传到服务器
        when(mockHttpClient.post(
          argThat(isA<Uri>()),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'success': true,
            'serverId': 100,
            'serverTimestamp': DateTime.now().toIso8601String(),
          }),
          200,
        ));

        await syncService.uploadCalculationRecord(originalRecord, 'test_token');

        // 从服务器下载
        when(mockHttpClient.get(
          argThat(isA<Uri>()),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode([
            {
              'id': 100,
              'calculationType': 'hole',
              'parameters': jsonEncode(originalRecord.parameters),
              'results': jsonEncode(originalRecord.results),
              'createdAt': originalRecord.createdAt.toIso8601String(),
              'clientId': 'consistency-test',
            }
          ]),
          200,
        ));

        final downloadedRecords = await syncService.downloadCalculationRecords(
          'test_token',
          DateTime.now().subtract(Duration(hours: 1)),
        );

        final downloadedRecord = downloadedRecords.first;

        // 验证数据完全一致
        expect(downloadedRecord.calculationType, equals(originalRecord.calculationType));
        expect(downloadedRecord.parameters, equals(originalRecord.parameters));
        expect(downloadedRecord.results, equals(originalRecord.results));
        expect(downloadedRecord.clientId, equals(originalRecord.clientId));
      });
    });
  });
}
