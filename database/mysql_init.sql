-- 油气管道开孔封堵计算系统 - MySQL 完整初始化脚本
-- 版本: 1.0.0
-- 用途: 一键初始化数据库、表结构和初始数据
-- 
-- 使用方法:
--   mysql -u root -p < mysql_init.sql
-- 
-- 注意: 此脚本会创建数据库、用户、表结构和初始数据

-- ============================================
-- 步骤 1: 创建数据库
-- ============================================

CREATE DATABASE IF NOT EXISTS pipeline_calc
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci
  COMMENT '油气管道开孔封堵计算系统数据库';

USE pipeline_calc;

SELECT 'Step 1: Database created successfully' as status;

-- ============================================
-- 步骤 2: 创建表结构
-- ============================================

-- 用户表
CREATE TABLE IF NOT EXISTS Users (
    Id VARCHAR(36) PRIMARY KEY COMMENT '用户唯一标识符（UUID）',
    Username VARCHAR(50) UNIQUE NOT NULL COMMENT '用户名',
    PasswordHash VARCHAR(255) NOT NULL COMMENT '密码哈希值',
    Email VARCHAR(100) COMMENT '邮箱地址',
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UpdatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    IsActive BOOLEAN DEFAULT TRUE COMMENT '是否激活',
    
    INDEX idx_username (Username),
    INDEX idx_email (Email),
    INDEX idx_created_at (CreatedAt)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci 
  COMMENT='用户信息表';

-- 计算记录表
CREATE TABLE IF NOT EXISTS CalculationRecords (
    Id VARCHAR(36) PRIMARY KEY COMMENT '计算记录唯一标识符（UUID）',
    UserId VARCHAR(36) NOT NULL COMMENT '用户ID',
    CalculationType VARCHAR(50) NOT NULL COMMENT '计算类型（hole/manualHole/sealing/plug/stem）',
    Parameters JSON NOT NULL COMMENT '计算参数（JSON格式存储）',
    Results JSON NOT NULL COMMENT '计算结果（JSON格式存储）',
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UpdatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    DeviceId VARCHAR(100) COMMENT '设备标识符',
    
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    INDEX idx_user_type (UserId, CalculationType),
    INDEX idx_created_at (CreatedAt),
    INDEX idx_device_id (DeviceId),
    INDEX idx_calculation_type (CalculationType)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci 
  COMMENT='计算记录表，存储用户的计算历史';

-- 参数组表
CREATE TABLE IF NOT EXISTS ParameterSets (
    Id VARCHAR(36) PRIMARY KEY COMMENT '参数组唯一标识符（UUID）',
    UserId VARCHAR(36) NOT NULL COMMENT '用户ID',
    Name VARCHAR(100) NOT NULL COMMENT '参数组名称',
    CalculationType VARCHAR(50) NOT NULL COMMENT '计算类型',
    Parameters JSON NOT NULL COMMENT '参数值（JSON格式存储）',
    IsPreset BOOLEAN DEFAULT FALSE COMMENT '是否为预设参数组',
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UpdatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    INDEX idx_user_type (UserId, CalculationType),
    INDEX idx_name (Name),
    INDEX idx_is_preset (IsPreset),
    INDEX idx_created_at (CreatedAt)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci 
  COMMENT='参数组表，存储用户保存的参数组合';

-- 同步日志表
CREATE TABLE IF NOT EXISTS SyncLogs (
    Id VARCHAR(36) PRIMARY KEY COMMENT '同步日志唯一标识符（UUID）',
    UserId VARCHAR(36) NOT NULL COMMENT '用户ID',
    DeviceId VARCHAR(100) NOT NULL COMMENT '设备标识符',
    SyncType VARCHAR(20) NOT NULL COMMENT '同步类型（upload/download）',
    RecordCount INT NOT NULL DEFAULT 0 COMMENT '同步记录数量',
    SyncTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '同步时间',
    Status VARCHAR(20) NOT NULL COMMENT '同步状态（success/failed）',
    ErrorMessage TEXT COMMENT '错误信息（如果同步失败）',
    
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    INDEX idx_user_device (UserId, DeviceId),
    INDEX idx_sync_time (SyncTime),
    INDEX idx_status (Status),
    INDEX idx_sync_type (SyncType)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci 
  COMMENT='数据同步日志表，记录同步操作历史';

-- 数据库版本管理表
CREATE TABLE IF NOT EXISTS SchemaVersions (
    Id INT AUTO_INCREMENT PRIMARY KEY COMMENT '版本记录ID',
    Version VARCHAR(20) NOT NULL COMMENT '版本号（如 1.0.0）',
    Description TEXT COMMENT '版本描述',
    AppliedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '应用时间',
    AppliedBy VARCHAR(100) COMMENT '应用者',
    
    INDEX idx_version (Version),
    INDEX idx_applied_at (AppliedAt)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci 
  COMMENT='数据库版本管理表';

SELECT 'Step 2: Tables created successfully' as status;

-- ============================================
-- 步骤 3: 创建视图
-- ============================================

-- 用户统计视图
CREATE OR REPLACE VIEW UserStats AS
SELECT 
    u.Id as UserId,
    u.Username,
    u.CreatedAt as UserCreatedAt,
    COUNT(DISTINCT cr.Id) as TotalCalculations,
    COUNT(DISTINCT ps.Id) as TotalParameterSets,
    COUNT(DISTINCT sl.Id) as TotalSyncOperations,
    MAX(cr.CreatedAt) as LastCalculationTime,
    MAX(sl.SyncTime) as LastSyncTime
FROM Users u
LEFT JOIN CalculationRecords cr ON u.Id = cr.UserId
LEFT JOIN ParameterSets ps ON u.Id = ps.UserId
LEFT JOIN SyncLogs sl ON u.Id = sl.UserId
WHERE u.IsActive = TRUE
GROUP BY u.Id, u.Username, u.CreatedAt;

-- 计算类型统计视图
CREATE OR REPLACE VIEW CalculationTypeStats AS
SELECT 
    CalculationType,
    COUNT(*) as TotalCount,
    COUNT(DISTINCT UserId) as UniqueUsers,
    MIN(CreatedAt) as FirstCalculation,
    MAX(CreatedAt) as LastCalculation,
    AVG(TIMESTAMPDIFF(SECOND, CreatedAt, UpdatedAt)) as AvgProcessingTime
FROM CalculationRecords
GROUP BY CalculationType
ORDER BY TotalCount DESC;

SELECT 'Step 3: Views created successfully' as status;

-- ============================================
-- 步骤 4: 插入初始数据
-- ============================================

-- 记录初始版本
INSERT INTO SchemaVersions (Version, Description, AppliedBy) 
VALUES ('1.0.0', '初始数据库结构', 'system')
ON DUPLICATE KEY UPDATE Version = Version;

SELECT 'Step 4: Initial data inserted successfully' as status;

-- ============================================
-- 步骤 5: 验证安装
-- ============================================

-- 验证表数量
SELECT 
    'Table Count Check' as check_type,
    COUNT(*) as table_count,
    CASE 
        WHEN COUNT(*) = 5 THEN 'PASS'
        ELSE 'FAIL'
    END as status
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'pipeline_calc' 
  AND TABLE_TYPE = 'BASE TABLE';

-- 验证视图数量
SELECT 
    'View Count Check' as check_type,
    COUNT(*) as view_count,
    CASE 
        WHEN COUNT(*) = 2 THEN 'PASS'
        ELSE 'FAIL'
    END as status
FROM information_schema.VIEWS 
WHERE TABLE_SCHEMA = 'pipeline_calc';

-- 验证外键数量
SELECT 
    'Foreign Key Check' as check_type,
    COUNT(DISTINCT CONSTRAINT_NAME) as fk_count,
    CASE 
        WHEN COUNT(DISTINCT CONSTRAINT_NAME) = 3 THEN 'PASS'
        ELSE 'FAIL'
    END as status
FROM information_schema.KEY_COLUMN_USAGE 
WHERE TABLE_SCHEMA = 'pipeline_calc' 
  AND REFERENCED_TABLE_NAME IS NOT NULL;

-- 验证字符集
SELECT 
    'Character Set Check' as check_type,
    DEFAULT_CHARACTER_SET_NAME as charset,
    CASE 
        WHEN DEFAULT_CHARACTER_SET_NAME = 'utf8mb4' THEN 'PASS'
        ELSE 'FAIL'
    END as status
FROM information_schema.SCHEMATA 
WHERE SCHEMA_NAME = 'pipeline_calc';

-- ============================================
-- 完成信息
-- ============================================

SELECT 
    '========================================' as '';

SELECT 
    'Database Initialization Complete!' as status,
    NOW() as completed_at,
    '1.0.0' as version;

SELECT 
    '========================================' as '';

SELECT 
    'Next Steps:' as info,
    '1. Create application user with environment variables' as step_1,
    '2. Configure application connection string' as step_2,
    '3. Run application tests' as step_3;
