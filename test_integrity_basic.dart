import 'package:flutter_test/flutter_test.dart';
import 'lib/services/data_integrity_service.dart';

/// 基础数据完整性功能测试
void main() {
  group('数据完整性服务基础测试', () {
    late DataIntegrityService integrityService;
    
    setUp(() {
      integrityService = DataIntegrityService();
    });
    
    test('服务初始化测试', () async {
      // 测试服务能否正常初始化
      expect(() => integrityService.initialize(), returnsNormally);
    });
    
    test('枚举类型定义测试', () {
      // 测试完整性检查类型枚举
      expect(IntegrityCheckType.values.length, greaterThan(0));
      expect(IntegrityCheckType.structure, isNotNull);
      expect(IntegrityCheckType.content, isNotNull);
      expect(IntegrityCheckType.consistency, isNotNull);
      expect(IntegrityCheckType.corruption, isNotNull);
      expect(IntegrityCheckType.foreign_key, isNotNull);
      
      // 测试问题级别枚举
      expect(IntegrityIssueLevel.values.length, greaterThan(0));
      expect(IntegrityIssueLevel.info, isNotNull);
      expect(IntegrityIssueLevel.warning, isNotNull);
      expect(IntegrityIssueLevel.error, isNotNull);
      expect(IntegrityIssueLevel.critical, isNotNull);
    });
    
    test('数据模型创建测试', () {
      // 测试IntegrityIssue模型
      final issue = IntegrityIssue(
        id: 'test-id',
        checkType: IntegrityCheckType.content,
        level: IntegrityIssueLevel.warning,
        tableName: 'test_table',
        description: '测试问题',
        detectedAt: DateTime.now(),
      );
      
      expect(issue.id, equals('test-id'));
      expect(issue.checkType, equals(IntegrityCheckType.content));
      expect(issue.level, equals(IntegrityIssueLevel.warning));
      expect(issue.tableName, equals('test_table'));
      expect(issue.description, equals('测试问题'));
      expect(issue.isFixed, isFalse);
      
      // 测试JSON序列化
      final json = issue.toJson();
      expect(json['id'], equals('test-id'));
      expect(json['check_type'], contains('IntegrityCheckType.content'));
      expect(json['level'], contains('IntegrityIssueLevel.warning'));
      
      // 测试JSON反序列化
      final fromJson = IntegrityIssue.fromJson(json);
      expect(fromJson.id, equals(issue.id));
      expect(fromJson.checkType, equals(issue.checkType));
      expect(fromJson.level, equals(issue.level));
    });
    
    test('数据备份模型测试', () {
      final backup = DataBackup(
        id: 'backup-id',
        name: '测试备份',
        description: '测试备份描述',
        filePath: '/test/path',
        fileSize: 1024,
        checksum: 'test-checksum',
        createdAt: DateTime.now(),
        tableCounts: {'test_table': 10},
      );
      
      expect(backup.id, equals('backup-id'));
      expect(backup.name, equals('测试备份'));
      expect(backup.fileSize, equals(1024));
      expect(backup.isAutomatic, isFalse);
      
      // 测试JSON序列化
      final json = backup.toJson();
      expect(json['id'], equals('backup-id'));
      expect(json['name'], equals('测试备份'));
      expect(json['file_size'], equals(1024));
      
      // 测试JSON反序列化
      final fromJson = DataBackup.fromJson(json);
      expect(fromJson.id, equals(backup.id));
      expect(fromJson.name, equals(backup.name));
      expect(fromJson.fileSize, equals(backup.fileSize));
    });
  });
}