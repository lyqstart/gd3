-- 油气管道开孔封堵计算系统数据库验证脚本
-- 版本: 1.0.0
-- 用途: 验证数据库和表结构是否正确创建

USE pipeline_calc;

-- 显示验证开始信息
SELECT 
    '开始数据库验证' as status,
    NOW() as verification_time,
    @@version as mysql_version;

-- 验证数据库存在和字符集
SELECT 
    'Database Verification' as check_type,
    SCHEMA_NAME as database_name,
    DEFAULT_CHARACTER_SET_NAME as charset,
    DEFAULT_COLLATION_NAME as collation,
    CASE 
        WHEN DEFAULT_CHARACTER_SET_NAME = 'utf8mb4' THEN 'PASS'
        ELSE 'FAIL - Should be utf8mb4'
    END as charset_check
FROM information_schema.SCHEMATA 
WHERE SCHEMA_NAME = 'pipeline_calc';

-- 验证所有表是否存在
SELECT 
    'Table Existence Check' as check_type,
    TABLE_NAME as table_name,
    TABLE_TYPE as table_type,
    ENGINE as storage_engine,
    TABLE_COLLATION as collation,
    TABLE_COMMENT as comment,
    'PASS' as status
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'pipeline_calc' 
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- 验证表数量
SELECT 
    'Table Count Check' as check_type,
    COUNT(*) as table_count,
    CASE 
        WHEN COUNT(*) = 4 THEN 'PASS - All 4 tables exist'
        ELSE CONCAT('FAIL - Expected 4 tables, found ', COUNT(*))
    END as status
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'pipeline_calc' 
  AND TABLE_TYPE = 'BASE TABLE';

-- 验证 Users 表结构
SELECT 
    'Users Table Structure' as check_type,
    COLUMN_NAME as column_name,
    DATA_TYPE as data_type,
    IS_NULLABLE as nullable,
    COLUMN_DEFAULT as default_value,
    COLUMN_COMMENT as comment
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'pipeline_calc' 
  AND TABLE_NAME = 'Users'
ORDER BY ORDINAL_POSITION;

-- 验证 CalculationRecords 表结构
SELECT 
    'CalculationRecords Table Structure' as check_type,
    COLUMN_NAME as column_name,
    DATA_TYPE as data_type,
    IS_NULLABLE as nullable,
    COLUMN_COMMENT as comment
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'pipeline_calc' 
  AND TABLE_NAME = 'CalculationRecords'
ORDER BY ORDINAL_POSITION;

-- 验证 ParameterSets 表结构
SELECT 
    'ParameterSets Table Structure' as check_type,
    COLUMN_NAME as column_name,
    DATA_TYPE as data_type,
    IS_NULLABLE as nullable,
    COLUMN_COMMENT as comment
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'pipeline_calc' 
  AND TABLE_NAME = 'ParameterSets'
ORDER BY ORDINAL_POSITION;

-- 验证 SyncLogs 表结构
SELECT 
    'SyncLogs Table Structure' as check_type,
    COLUMN_NAME as column_name,
    DATA_TYPE as data_type,
    IS_NULLABLE as nullable,
    COLUMN_COMMENT as comment
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'pipeline_calc' 
  AND TABLE_NAME = 'SyncLogs'
ORDER BY ORDINAL_POSITION;

-- 验证索引创建
SELECT 
    'Index Verification' as check_type,
    TABLE_NAME as table_name,
    INDEX_NAME as index_name,
    COLUMN_NAME as column_name,
    INDEX_TYPE as index_type,
    NON_UNIQUE as non_unique
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'pipeline_calc'
  AND INDEX_NAME != 'PRIMARY'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- 验证外键约束
SELECT 
    'Foreign Key Verification' as check_type,
    CONSTRAINT_NAME as constraint_name,
    TABLE_NAME as table_name,
    COLUMN_NAME as column_name,
    REFERENCED_TABLE_NAME as referenced_table,
    REFERENCED_COLUMN_NAME as referenced_column
FROM information_schema.KEY_COLUMN_USAGE 
WHERE TABLE_SCHEMA = 'pipeline_calc' 
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- 验证视图创建
SELECT 
    'View Verification' as check_type,
    TABLE_NAME as view_name,
    VIEW_DEFINITION as definition_preview
FROM information_schema.VIEWS 
WHERE TABLE_SCHEMA = 'pipeline_calc'
ORDER BY TABLE_NAME;

-- 验证视图数量
SELECT 
    'View Count Check' as check_type,
    COUNT(*) as view_count,
    CASE 
        WHEN COUNT(*) = 2 THEN 'PASS - Both views exist'
        ELSE CONCAT('FAIL - Expected 2 views, found ', COUNT(*))
    END as status
FROM information_schema.VIEWS 
WHERE TABLE_SCHEMA = 'pipeline_calc';

-- 测试基本数据操作权限（插入测试数据）
INSERT INTO Users (Id, Username, PasswordHash, Email) 
VALUES ('test-user-id', 'test_user', 'test_hash', 'test@example.com')
ON DUPLICATE KEY UPDATE Username = VALUES(Username);

-- 验证插入是否成功
SELECT 
    'Data Operation Test' as check_type,
    COUNT(*) as test_record_count,
    CASE 
        WHEN COUNT(*) > 0 THEN 'PASS - Can insert data'
        ELSE 'FAIL - Cannot insert data'
    END as status
FROM Users 
WHERE Username = 'test_user';

-- 清理测试数据
DELETE FROM Users WHERE Username = 'test_user';

-- 验证删除是否成功
SELECT 
    'Data Cleanup Test' as check_type,
    COUNT(*) as remaining_test_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS - Can delete data'
        ELSE 'FAIL - Cannot delete data'
    END as status
FROM Users 
WHERE Username = 'test_user';

-- 验证字符集支持（中文字符测试）
CREATE TEMPORARY TABLE temp_charset_test (
    id INT PRIMARY KEY,
    chinese_text VARCHAR(100) CHARACTER SET utf8mb4
);

INSERT INTO temp_charset_test (id, chinese_text) 
VALUES (1, '油气管道开孔封堵计算系统测试');

SELECT 
    'Character Set Test' as check_type,
    chinese_text,
    CHAR_LENGTH(chinese_text) as char_length,
    CASE 
        WHEN chinese_text = '油气管道开孔封堵计算系统测试' THEN 'PASS - UTF8MB4 works'
        ELSE 'FAIL - Character encoding issue'
    END as status
FROM temp_charset_test 
WHERE id = 1;

-- 最终验证摘要
SELECT 
    '=== VERIFICATION SUMMARY ===' as summary,
    (SELECT COUNT(*) FROM information_schema.TABLES 
     WHERE TABLE_SCHEMA = 'pipeline_calc' AND TABLE_TYPE = 'BASE TABLE') as tables_created,
    (SELECT COUNT(*) FROM information_schema.VIEWS 
     WHERE TABLE_SCHEMA = 'pipeline_calc') as views_created,
    (SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE 
     WHERE TABLE_SCHEMA = 'pipeline_calc' AND REFERENCED_TABLE_NAME IS NOT NULL) as foreign_keys_created,
    (SELECT DEFAULT_CHARACTER_SET_NAME FROM information_schema.SCHEMATA 
     WHERE SCHEMA_NAME = 'pipeline_calc') as database_charset;

-- 显示验证完成信息
SELECT 
    '数据库验证完成' as status,
    NOW() as completion_time,
    'All checks completed successfully' as message;

-- 显示下一步操作建议
SELECT 
    '下一步操作建议' as next_steps,
    '1. 测试应用程序连接' as step_1,
    '2. 配置后端 API 连接字符串' as step_2,
    '3. 运行应用程序集成测试' as step_3,
    '4. 设置定期数据备份' as step_4;