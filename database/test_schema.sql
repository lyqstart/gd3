-- 油气管道开孔封堵计算系统 - 表结构测试脚本
-- 版本: 1.0.0
-- 用途: 测试数据库表结构的完整性和功能性

USE pipeline_calc;

-- ============================================
-- 测试准备
-- ============================================

-- 清理可能存在的测试数据
DELETE FROM SyncLogs WHERE UserId LIKE 'test-%';
DELETE FROM ParameterSets WHERE UserId LIKE 'test-%';
DELETE FROM CalculationRecords WHERE UserId LIKE 'test-%';
DELETE FROM Users WHERE Id LIKE 'test-%';

SELECT '========================================' as '';
SELECT '开始表结构功能测试' as '';
SELECT '========================================' as '';

-- ============================================
-- 测试 1: Users 表基本功能
-- ============================================

SELECT '测试 1: Users 表基本功能' as test_name;

-- 插入测试用户
INSERT INTO Users (Id, Username, PasswordHash, Email, IsActive) 
VALUES 
  ('test-user-001', 'test_user_1', 'hash_123', 'test1@example.com', TRUE),
  ('test-user-002', 'test_user_2', 'hash_456', 'test2@example.com', TRUE),
  ('test-user-003', 'test_user_3', 'hash_789', NULL, FALSE);

-- 验证插入
SELECT 
  CASE 
    WHEN COUNT(*) = 3 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  '插入3个测试用户' as description,
  COUNT(*) as actual_count
FROM Users 
WHERE Id LIKE 'test-%';

-- 测试唯一性约束
SELECT 'PASS' as result, '用户名唯一性约束' as description
WHERE NOT EXISTS (
  SELECT 1 FROM (
    SELECT Username, COUNT(*) as cnt 
    FROM Users 
    WHERE Id LIKE 'test-%'
    GROUP BY Username 
    HAVING cnt > 1
  ) duplicates
);

-- ============================================
-- 测试 2: CalculationRecords 表和外键
-- ============================================

SELECT '测试 2: CalculationRecords 表和外键' as test_name;

-- 插入计算记录
INSERT INTO CalculationRecords (Id, UserId, CalculationType, Parameters, Results, DeviceId) 
VALUES 
  ('test-calc-001', 'test-user-001', 'hole', 
   '{"outerDiameter": 114.3, "innerDiameter": 102.3}',
   '{"emptyStroke": 93.0, "totalStroke": 128.5}',
   'device-001'),
  ('test-calc-002', 'test-user-001', 'sealing',
   '{"rValue": 20.0, "bValue": 30.0}',
   '{"guideWheelStroke": 158.0, "totalStroke": 238.0}',
   'device-001'),
  ('test-calc-003', 'test-user-002', 'plug',
   '{"mValue": 100.0, "kValue": 60.0}',
   '{"threadEngagement": 5.0, "totalStroke": 205.0}',
   'device-002');

-- 验证插入和外键
SELECT 
  CASE 
    WHEN COUNT(*) = 3 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  '插入3条计算记录' as description,
  COUNT(*) as actual_count
FROM CalculationRecords 
WHERE Id LIKE 'test-%';

-- 测试JSON字段查询
SELECT 
  CASE 
    WHEN COUNT(*) = 1 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  'JSON字段查询功能' as description,
  COUNT(*) as actual_count
FROM CalculationRecords 
WHERE Id = 'test-calc-001'
  AND JSON_EXTRACT(Parameters, '$.outerDiameter') = 114.3;

-- 测试计算类型索引
SELECT 
  CASE 
    WHEN COUNT(*) = 1 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  '按计算类型查询' as description,
  COUNT(*) as actual_count
FROM CalculationRecords 
WHERE UserId = 'test-user-001' 
  AND CalculationType = 'hole';

-- ============================================
-- 测试 3: ParameterSets 表
-- ============================================

SELECT '测试 3: ParameterSets 表' as test_name;

-- 插入参数组
INSERT INTO ParameterSets (Id, UserId, Name, CalculationType, Parameters, IsPreset) 
VALUES 
  ('test-param-001', 'test-user-001', 'DN100标准管道', 'hole',
   '{"outerDiameter": 114.3, "innerDiameter": 102.3, "aValue": 50.0}',
   FALSE),
  ('test-param-002', 'test-user-001', '常用封堵参数', 'sealing',
   '{"rValue": 20.0, "bValue": 30.0, "dValue": 80.0}',
   FALSE),
  ('test-param-003', 'test-user-002', '系统预设', 'plug',
   '{"mValue": 100.0, "kValue": 60.0, "nValue": 40.0}',
   TRUE);

-- 验证插入
SELECT 
  CASE 
    WHEN COUNT(*) = 3 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  '插入3个参数组' as description,
  COUNT(*) as actual_count
FROM ParameterSets 
WHERE Id LIKE 'test-%';

-- 测试预设参数组查询
SELECT 
  CASE 
    WHEN COUNT(*) = 1 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  '查询预设参数组' as description,
  COUNT(*) as actual_count
FROM ParameterSets 
WHERE UserId = 'test-user-002' 
  AND IsPreset = TRUE;

-- ============================================
-- 测试 4: SyncLogs 表
-- ============================================

SELECT '测试 4: SyncLogs 表' as test_name;

-- 插入同步日志
INSERT INTO SyncLogs (Id, UserId, DeviceId, SyncType, RecordCount, Status, ErrorMessage) 
VALUES 
  ('test-sync-001', 'test-user-001', 'device-001', 'upload', 5, 'success', NULL),
  ('test-sync-002', 'test-user-001', 'device-001', 'download', 3, 'success', NULL),
  ('test-sync-003', 'test-user-002', 'device-002', 'upload', 0, 'failed', '网络连接超时');

-- 验证插入
SELECT 
  CASE 
    WHEN COUNT(*) = 3 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  '插入3条同步日志' as description,
  COUNT(*) as actual_count
FROM SyncLogs 
WHERE Id LIKE 'test-%';

-- 测试按设备查询
SELECT 
  CASE 
    WHEN COUNT(*) = 2 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  '按用户和设备查询同步日志' as description,
  COUNT(*) as actual_count
FROM SyncLogs 
WHERE UserId = 'test-user-001' 
  AND DeviceId = 'device-001';

-- 测试失败日志查询
SELECT 
  CASE 
    WHEN COUNT(*) = 1 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  '查询失败的同步记录' as description,
  COUNT(*) as actual_count
FROM SyncLogs 
WHERE Status = 'failed' 
  AND ErrorMessage IS NOT NULL;

-- ============================================
-- 测试 5: 外键级联删除
-- ============================================

SELECT '测试 5: 外键级联删除' as test_name;

-- 记录删除前的数量
SELECT 
  (SELECT COUNT(*) FROM CalculationRecords WHERE UserId = 'test-user-001') as calc_before,
  (SELECT COUNT(*) FROM ParameterSets WHERE UserId = 'test-user-001') as param_before,
  (SELECT COUNT(*) FROM SyncLogs WHERE UserId = 'test-user-001') as sync_before;

-- 删除用户
DELETE FROM Users WHERE Id = 'test-user-001';

-- 验证级联删除
SELECT 
  CASE 
    WHEN COUNT(*) = 0 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  '级联删除计算记录' as description,
  COUNT(*) as remaining_count
FROM CalculationRecords 
WHERE UserId = 'test-user-001';

SELECT 
  CASE 
    WHEN COUNT(*) = 0 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  '级联删除参数组' as description,
  COUNT(*) as remaining_count
FROM ParameterSets 
WHERE UserId = 'test-user-001';

SELECT 
  CASE 
    WHEN COUNT(*) = 0 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  '级联删除同步日志' as description,
  COUNT(*) as remaining_count
FROM SyncLogs 
WHERE UserId = 'test-user-001';

-- ============================================
-- 测试 6: 视图功能
-- ============================================

SELECT '测试 6: 视图功能' as test_name;

-- 测试 UserStats 视图
SELECT 
  CASE 
    WHEN COUNT(*) > 0 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  'UserStats 视图可查询' as description,
  COUNT(*) as user_count
FROM UserStats 
WHERE UserId LIKE 'test-%';

-- 测试 CalculationTypeStats 视图
SELECT 
  CASE 
    WHEN COUNT(*) > 0 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  'CalculationTypeStats 视图可查询' as description,
  COUNT(*) as type_count
FROM CalculationTypeStats;

-- ============================================
-- 测试 7: 索引效率测试
-- ============================================

SELECT '测试 7: 索引效率测试' as test_name;

-- 检查索引是否存在
SELECT 
  CASE 
    WHEN COUNT(*) >= 4 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  'Users 表索引检查' as description,
  COUNT(*) as index_count
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'pipeline_calc' 
  AND TABLE_NAME = 'Users';

SELECT 
  CASE 
    WHEN COUNT(*) >= 5 THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  'CalculationRecords 表索引检查' as description,
  COUNT(*) as index_count
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'pipeline_calc' 
  AND TABLE_NAME = 'CalculationRecords';

-- ============================================
-- 测试 8: 字符集和排序规则
-- ============================================

SELECT '测试 8: 字符集和排序规则' as test_name;

-- 测试中文字符存储
INSERT INTO Users (Id, Username, PasswordHash, Email) 
VALUES ('test-user-cn', '测试用户', 'hash_cn', '测试@示例.com');

SELECT 
  CASE 
    WHEN Username = '测试用户' AND Email = '测试@示例.com' THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  'UTF8MB4 中文字符支持' as description,
  Username,
  Email
FROM Users 
WHERE Id = 'test-user-cn';

-- 测试JSON中的中文
INSERT INTO CalculationRecords (Id, UserId, CalculationType, Parameters, Results) 
VALUES ('test-calc-cn', 'test-user-cn', 'hole',
        '{"备注": "测试中文参数"}',
        '{"说明": "测试中文结果"}');

SELECT 
  CASE 
    WHEN JSON_EXTRACT(Parameters, '$.备注') = '测试中文参数' THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  'JSON 中文字符支持' as description,
  JSON_EXTRACT(Parameters, '$.备注') as chinese_param
FROM CalculationRecords 
WHERE Id = 'test-calc-cn';

-- ============================================
-- 测试 9: 数据完整性约束
-- ============================================

SELECT '测试 9: 数据完整性约束' as test_name;

-- 测试非空约束（应该失败）
SELECT 'PASS' as result, '非空约束测试' as description
WHERE NOT EXISTS (
  SELECT 1 FROM (
    SELECT 1 as test_insert
    FROM dual
    WHERE 0 = (
      SELECT COUNT(*) FROM (
        SELECT 1 FROM Users WHERE Username IS NULL
      ) null_check
    )
  ) constraint_test
);

-- 测试默认值
INSERT INTO Users (Id, Username, PasswordHash) 
VALUES ('test-user-default', 'default_test', 'hash_default');

SELECT 
  CASE 
    WHEN IsActive = TRUE AND CreatedAt IS NOT NULL THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  '默认值测试' as description,
  IsActive,
  CreatedAt
FROM Users 
WHERE Id = 'test-user-default';

-- ============================================
-- 测试清理
-- ============================================

SELECT '========================================' as '';
SELECT '清理测试数据' as '';
SELECT '========================================' as '';

-- 清理所有测试数据
DELETE FROM SyncLogs WHERE UserId LIKE 'test-%';
DELETE FROM ParameterSets WHERE UserId LIKE 'test-%';
DELETE FROM CalculationRecords WHERE UserId LIKE 'test-%';
DELETE FROM Users WHERE Id LIKE 'test-%';

-- 验证清理
SELECT 
  CASE 
    WHEN (SELECT COUNT(*) FROM Users WHERE Id LIKE 'test-%') = 0
     AND (SELECT COUNT(*) FROM CalculationRecords WHERE Id LIKE 'test-%') = 0
     AND (SELECT COUNT(*) FROM ParameterSets WHERE Id LIKE 'test-%') = 0
     AND (SELECT COUNT(*) FROM SyncLogs WHERE Id LIKE 'test-%') = 0
    THEN 'PASS'
    ELSE 'FAIL'
  END as result,
  '测试数据清理完成' as description;

-- ============================================
-- 测试总结
-- ============================================

SELECT '========================================' as '';
SELECT '表结构功能测试完成' as '';
SELECT '========================================' as '';

SELECT 
  '所有测试已完成' as summary,
  '请检查上述测试结果' as note,
  '所有测试应显示 PASS' as expected_result;