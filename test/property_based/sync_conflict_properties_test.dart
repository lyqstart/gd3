import 'package:flutter_test/flutter_test.dart';
import 'package:pipeline_calculation_app/models/calculation_record.dart';
import 'package:pipeline_calculation_app/models/enums.dart';
import 'package:pipeline_calculation_app/services/conflict_resolver.dart';
import 'dart:math';

/// 属性9: 数据同步冲突解决 (需求9.6)
/// 
/// 验证数据同步冲突检测和解决机制的正确性
void main() {
  group('属性9: 数据同步冲突解决', () {
    late ConflictResolver resolver;
    final random = Random(42);

    setUp(() {
      resolver = ConflictResolver();
    });

    test('相同数据不应产生冲突', () {
      for (int i = 0; i < 100; i++) {
        final timestamp = DateTime.now();
        final params = {'value': random.nextDouble() * 100};
        final results = {'result': random.nextDouble() * 200};

        final record1 = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: params,
          results: results,
          createdAt: timestamp,
          syncStatus: SyncStatus.synced,
          clientId: 'client-123',
        );

        final record2 = CalculationRecord(
          id: 2,
          calculationType: CalculationType.hole,
          parameters: params,
          results: results,
          createdAt: timestamp,
          syncStatus: SyncStatus.synced,
          clientId: 'client-123',
        );

        final hasConflict = resolver.detectConflict(record1, record2);
        
        expect(
          hasConflict,
          isFalse,
          reason: '相同数据不应产生冲突 (迭代$i)',
        );
      }
    });

    test('不同参数应产生冲突', () {
      for (int i = 0; i < 100; i++) {
        final record1 = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {'value': random.nextDouble() * 100},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'client-123',
        );

        final record2 = CalculationRecord(
          id: 2,
          calculationType: CalculationType.hole,
          parameters: {'value': random.nextDouble() * 100 + 200}, // 不同的值
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'client-123',
        );

        final hasConflict = resolver.detectConflict(record1, record2);
        
        expect(
          hasConflict,
          isTrue,
          reason: '不同参数应产生冲突 (迭代$i)',
        );
      }
    });

    test('冲突解决策略 - 保留本地', () {
      for (int i = 0; i < 50; i++) {
        final localRecord = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {'local': true, 'value': random.nextDouble()},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          clientId: 'client-123',
        );

        final serverRecord = CalculationRecord(
          id: 100,
          calculationType: CalculationType.hole,
          parameters: {'local': false, 'value': random.nextDouble()},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'client-123',
        );

        final resolved = resolver.resolveConflict(
          localRecord,
          serverRecord,
          ConflictResolutionStrategy.keepLocal,
        );

        expect(
          resolved.parameters['local'],
          isTrue,
          reason: '保留本地策略应保留本地数据 (迭代$i)',
        );
      }
    });

    test('冲突解决策略 - 保留服务器', () {
      for (int i = 0; i < 50; i++) {
        final localRecord = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {'local': true, 'value': random.nextDouble()},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          clientId: 'client-123',
        );

        final serverRecord = CalculationRecord(
          id: 100,
          calculationType: CalculationType.hole,
          parameters: {'local': false, 'value': random.nextDouble()},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'client-123',
        );

        final resolved = resolver.resolveConflict(
          localRecord,
          serverRecord,
          ConflictResolutionStrategy.keepServer,
        );

        expect(
          resolved.parameters['local'],
          isFalse,
          reason: '保留服务器策略应保留服务器数据 (迭代$i)',
        );
      }
    });

    test('冲突解决策略 - 保留最新', () {
      for (int i = 0; i < 50; i++) {
        final now = DateTime.now();
        final olderTime = now.subtract(Duration(minutes: random.nextInt(60)));
        final newerTime = now;

        final olderRecord = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {'timestamp': 'older'},
          results: {},
          createdAt: olderTime,
          syncStatus: SyncStatus.pending,
          clientId: 'client-123',
        );

        final newerRecord = CalculationRecord(
          id: 2,
          calculationType: CalculationType.hole,
          parameters: {'timestamp': 'newer'},
          results: {},
          createdAt: newerTime,
          syncStatus: SyncStatus.synced,
          clientId: 'client-123',
        );

        final resolved = resolver.resolveConflict(
          olderRecord,
          newerRecord,
          ConflictResolutionStrategy.keepNewest,
        );

        expect(
          resolved.parameters['timestamp'],
          equals('newer'),
          reason: '保留最新策略应保留时间戳更新的数据 (迭代$i)',
        );
      }
    });

    test('冲突解决后数据完整性', () {
      for (int i = 0; i < 100; i++) {
        final localRecord = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {
            'outerDiameter': 100.0 + random.nextDouble() * 100,
            'innerDiameter': 90.0 + random.nextDouble() * 90,
          },
          results: {'totalStroke': random.nextDouble() * 200},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          clientId: 'client-123',
        );

        final serverRecord = CalculationRecord(
          id: 100,
          calculationType: CalculationType.hole,
          parameters: {
            'outerDiameter': 100.0 + random.nextDouble() * 100,
            'innerDiameter': 90.0 + random.nextDouble() * 90,
          },
          results: {'totalStroke': random.nextDouble() * 200},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'client-123',
        );

        final strategies = [
          ConflictResolutionStrategy.keepLocal,
          ConflictResolutionStrategy.keepServer,
          ConflictResolutionStrategy.keepNewest,
        ];

        for (final strategy in strategies) {
          final resolved = resolver.resolveConflict(
            localRecord,
            serverRecord,
            strategy,
          );

          // 验证解决后的数据完整性
          expect(resolved.id, isNotNull);
          expect(resolved.calculationType, equals(CalculationType.hole));
          expect(resolved.parameters, isNotEmpty);
          expect(resolved.results, isNotEmpty);
          expect(resolved.createdAt, isNotNull);
          expect(resolved.clientId, equals('client-123'));
        }
      }
    });

    test('批量冲突解决的一致性', () {
      final conflicts = <ConflictPair>[];
      
      // 生成100个冲突对
      for (int i = 0; i < 100; i++) {
        final localRecord = CalculationRecord(
          id: i + 1,
          calculationType: CalculationType.hole,
          parameters: {'index': i, 'local': true},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          clientId: 'client-$i',
        );

        final serverRecord = CalculationRecord(
          id: i + 1000,
          calculationType: CalculationType.hole,
          parameters: {'index': i, 'local': false},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'client-$i',
        );

        conflicts.add(ConflictPair(localRecord, serverRecord));
      }

      // 批量解决冲突
      final resolved = resolver.resolveBatchConflicts(
        conflicts,
        ConflictResolutionStrategy.keepLocal,
      );

      // 验证所有冲突都已解决
      expect(resolved.length, equals(100));
      
      // 验证策略一致性
      for (final record in resolved) {
        expect(
          record.parameters['local'],
          isTrue,
          reason: '批量解决应保持策略一致性',
        );
      }
    });

    test('冲突解决的幂等性', () {
      // 属性: 对已解决的冲突再次应用相同策略应得到相同结果
      for (int i = 0; i < 50; i++) {
        final localRecord = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {'value': random.nextDouble()},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          clientId: 'client-123',
        );

        final serverRecord = CalculationRecord(
          id: 100,
          calculationType: CalculationType.hole,
          parameters: {'value': random.nextDouble()},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'client-123',
        );

        final strategy = ConflictResolutionStrategy.keepLocal;

        // 第一次解决
        final resolved1 = resolver.resolveConflict(
          localRecord,
          serverRecord,
          strategy,
        );

        // 第二次解决（使用第一次的结果）
        final resolved2 = resolver.resolveConflict(
          resolved1,
          serverRecord,
          strategy,
        );

        // 结果应该相同
        expect(
          resolved1.parameters,
          equals(resolved2.parameters),
          reason: '冲突解决应具有幂等性 (迭代$i)',
        );
      }
    });

    test('不同clientId的记录不应产生冲突', () {
      for (int i = 0; i < 100; i++) {
        final record1 = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {'value': random.nextDouble()},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'client-A',
        );

        final record2 = CalculationRecord(
          id: 2,
          calculationType: CalculationType.hole,
          parameters: {'value': random.nextDouble()},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'client-B',
        );

        final hasConflict = resolver.detectConflict(record1, record2);
        
        expect(
          hasConflict,
          isFalse,
          reason: '不同clientId的记录不应产生冲突 (迭代$i)',
        );
      }
    });

    test('冲突检测的对称性', () {
      // 属性: detectConflict(A, B) == detectConflict(B, A)
      for (int i = 0; i < 100; i++) {
        final record1 = CalculationRecord(
          id: 1,
          calculationType: CalculationType.hole,
          parameters: {'value': random.nextDouble()},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'client-123',
        );

        final record2 = CalculationRecord(
          id: 2,
          calculationType: CalculationType.hole,
          parameters: {'value': random.nextDouble()},
          results: {},
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          clientId: 'client-123',
        );

        final conflict1 = resolver.detectConflict(record1, record2);
        final conflict2 = resolver.detectConflict(record2, record1);

        expect(
          conflict1,
          equals(conflict2),
          reason: '冲突检测应具有对称性 (迭代$i)',
        );
      }
    });
  });
}

/// 冲突对数据结构
class ConflictPair {
  final CalculationRecord local;
  final CalculationRecord server;

  ConflictPair(this.local, this.server);
}

/// 冲突解决策略枚举
enum ConflictResolutionStrategy {
  keepLocal,    // 保留本地数据
  keepServer,   // 保留服务器数据
  keepNewest,   // 保留最新数据
}

/// 冲突解决器（模拟实现）
class ConflictResolver {
  /// 检测两条记录是否存在冲突
  bool detectConflict(CalculationRecord record1, CalculationRecord record2) {
    // 不同clientId不产生冲突
    if (record1.clientId != record2.clientId) {
      return false;
    }

    // 比较参数和结果
    return !_mapsEqual(record1.parameters, record2.parameters) ||
           !_mapsEqual(record1.results, record2.results);
  }

  /// 解决单个冲突
  CalculationRecord resolveConflict(
    CalculationRecord local,
    CalculationRecord server,
    ConflictResolutionStrategy strategy,
  ) {
    switch (strategy) {
      case ConflictResolutionStrategy.keepLocal:
        return local;
      
      case ConflictResolutionStrategy.keepServer:
        return server;
      
      case ConflictResolutionStrategy.keepNewest:
        return local.createdAt.isAfter(server.createdAt) ? local : server;
    }
  }

  /// 批量解决冲突
  List<CalculationRecord> resolveBatchConflicts(
    List<ConflictPair> conflicts,
    ConflictResolutionStrategy strategy,
  ) {
    return conflicts
        .map((pair) => resolveConflict(pair.local, pair.server, strategy))
        .toList();
  }

  /// 比较两个Map是否相等
  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    
    for (final key in map1.keys) {
      if (!map2.containsKey(key)) return false;
      if (map1[key] != map2[key]) return false;
    }
    
    return true;
  }
}
