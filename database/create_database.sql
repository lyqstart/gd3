-- 油气管道开孔封堵计算系统数据库创建脚本
-- 版本: 1.0.0
-- 
-- 注意: 此脚本使用环境变量进行配置，不包含硬编码的用户名和密码
-- 请在执行前设置相应的环境变量

-- 创建数据库
CREATE DATABASE IF NOT EXISTS pipeline_calc
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci
  COMMENT '油气管道开孔封堵计算系统数据库';

-- 使用数据库
USE pipeline_calc;

-- 创建应用用户（用户名通过环境变量 DB_USERNAME 指定）
-- 密码通过环境变量 DB_PASSWORD 指定
-- 示例执行命令:
-- mysql -u root -p -e "
--   SET @username = IFNULL(@DB_USERNAME, 'pipeline_app_user');
--   SET @password = IFNULL(@DB_PASSWORD, 'secure_password_123');
--   SET @sql = CONCAT('CREATE USER IF NOT EXISTS ''', @username, '''@''%'' IDENTIFIED BY ''', @password, ''';');
--   PREPARE stmt FROM @sql;
--   EXECUTE stmt;
--   DEALLOCATE PREPARE stmt;
-- "

-- 注意: 实际的用户创建需要在运行时通过环境变量执行
-- 这里提供创建用户的模板，实际执行时需要替换环境变量

-- 用户权限配置模板（需要在运行时替换用户名）
-- GRANT SELECT, INSERT, UPDATE, DELETE ON pipeline_calc.* TO '{DB_USERNAME}'@'%';
-- FLUSH PRIVILEGES;

-- 验证数据库创建
SELECT 
  SCHEMA_NAME as database_name,
  DEFAULT_CHARACTER_SET_NAME as charset,
  DEFAULT_COLLATION_NAME as collation
FROM information_schema.SCHEMATA 
WHERE SCHEMA_NAME = 'pipeline_calc';

-- 显示创建完成信息
SELECT 
  'Database pipeline_calc created successfully' as status,
  NOW() as created_at,
  @@version as mysql_version;