-- 数据库迁移脚本: v1.0.0 -> v1.1.0
-- 描述: 示例迁移脚本模板
-- 创建时间: 2024
-- 
-- 使用方法:
--   mysql -u root -p pipeline_calc < migrations/v1.0.0_to_v1.1.0.sql

USE pipeline_calc;

-- ============================================
-- 迁移前检查
-- ============================================

-- 检查当前版本
SELECT 
    CASE 
        WHEN MAX(Version) = '1.0.0' THEN 'Ready to migrate'
        ELSE CONCAT('ERROR: Current version is ', MAX(Version), ', expected 1.0.0')
    END as migration_check
FROM SchemaVersions;

-- ============================================
-- 迁移操作（示例）
-- ============================================

-- 示例：添加新字段
-- ALTER TABLE Users ADD COLUMN PhoneNumber VARCHAR(20) AFTER Email;

-- 示例：创建新索引
-- CREATE INDEX idx_phone_number ON Users(PhoneNumber);

-- 示例：修改字段类型
-- ALTER TABLE CalculationRecords MODIFY COLUMN DeviceId VARCHAR(150);

-- 示例：添加新表
-- CREATE TABLE IF NOT EXISTS UserPreferences (
--     Id VARCHAR(36) PRIMARY KEY,
--     UserId VARCHAR(36) NOT NULL,
--     PreferenceKey VARCHAR(50) NOT NULL,
--     PreferenceValue TEXT,
--     FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
--     UNIQUE KEY unique_user_preference (UserId, PreferenceKey)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 记录迁移版本
-- ============================================

INSERT INTO SchemaVersions (Version, Description, AppliedBy) 
VALUES ('1.1.0', '示例迁移：添加新功能', 'migration_script');

-- ============================================
-- 迁移验证
-- ============================================

SELECT 
    'Migration Complete' as status,
    Version,
    AppliedAt
FROM SchemaVersions 
WHERE Version = '1.1.0';
