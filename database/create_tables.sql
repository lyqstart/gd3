-- 油气管道开孔封堵计算系统表结构创建脚本
-- 版本: 1.0.0
-- 
-- 此脚本创建所有必需的数据表，仅用于数据存储和同步，不包含计算逻辑

USE pipeline_calc;

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

-- 创建视图：用户统计信息
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

-- 创建视图：计算类型统计
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

-- 验证表创建
SELECT 
    TABLE_NAME as table_name,
    TABLE_ROWS as estimated_rows,
    CREATE_TIME as created_time,
    TABLE_COMMENT as comment
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'pipeline_calc' 
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- 验证索引创建
SELECT 
    TABLE_NAME as table_name,
    INDEX_NAME as index_name,
    COLUMN_NAME as column_name,
    INDEX_TYPE as index_type
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'pipeline_calc'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- 验证外键约束
SELECT 
    CONSTRAINT_NAME as constraint_name,
    TABLE_NAME as table_name,
    COLUMN_NAME as column_name,
    REFERENCED_TABLE_NAME as referenced_table,
    REFERENCED_COLUMN_NAME as referenced_column
FROM information_schema.KEY_COLUMN_USAGE 
WHERE TABLE_SCHEMA = 'pipeline_calc' 
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- 显示创建完成信息
SELECT 
    'All tables created successfully' as status,
    COUNT(*) as total_tables,
    NOW() as created_at
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'pipeline_calc' 
  AND TABLE_TYPE = 'BASE TABLE';