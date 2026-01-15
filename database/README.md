# 油气管道开孔封堵计算系统 - 数据库配置指南

## 概述

本文档提供了 MySQL 数据库的完整配置指南，包括数据库创建、用户权限配置和环境变量管理。

## 环境要求

- MySQL 5.7+ 或 MySQL 8.0+
- 支持 utf8mb4 字符集
- 具有管理员权限的 MySQL 用户

## 快速开始

### 1. 环境变量配置

复制根目录下的 `.env.example` 文件为 `.env`：

```bash
cp .env.example .env
```

编辑 `.env` 文件，填入实际的配置值：

```bash
# 数据库基本配置
DB_HOST=localhost
DB_PORT=3306
DB_NAME=pipeline_calc
DB_USERNAME=pipeline_app_user
DB_PASSWORD=your_secure_password_123
DB_ROOT_PASSWORD=your_root_password_456

# JWT 配置
JWT_SECRET=your_random_jwt_secret_key_here
JWT_EXPIRATION_HOURS=24
```

### 2. 数据库初始化

#### 方法一：使用提供的脚本（推荐）

**Windows 用户：**
```cmd
cd database
setup_database.bat
```

**Linux/Mac 用户：**
```bash
cd database
chmod +x setup_database.sh
./setup_database.sh
```

#### 方法二：手动执行 SQL 脚本

1. 连接到 MySQL 服务器：
```bash
mysql -u root -p
```

2. 执行数据库创建脚本：
```sql
source create_database.sql;
```

3. 创建应用用户（替换环境变量）：
```sql
-- 使用实际的用户名和密码替换下面的占位符
CREATE USER IF NOT EXISTS 'pipeline_app_user'@'%' IDENTIFIED BY 'your_secure_password_123';
GRANT SELECT, INSERT, UPDATE, DELETE ON pipeline_calc.* TO 'pipeline_app_user'@'%';
FLUSH PRIVILEGES;
```

4. 执行表结构创建脚本：
```sql
source create_tables.sql;
```

### 3. 验证安装

执行验证脚本：
```sql
source verify_database.sql;
```

预期输出应包含：
- 数据库 `pipeline_calc` 存在
- 4个主要数据表已创建
- 用户权限配置正确
- 字符集为 utf8mb4

## 详细配置说明

### 数据库结构

系统包含以下核心表：

1. **Users** - 用户信息表
   - 存储用户账户信息
   - 支持用户认证和授权

2. **CalculationRecords** - 计算记录表
   - 存储用户的计算历史
   - 支持多种计算类型

3. **ParameterSets** - 参数组表
   - 存储用户保存的参数组合
   - 支持预设参数管理

4. **SyncLogs** - 同步日志表
   - 记录数据同步操作
   - 支持多设备同步追踪

### 用户权限配置

应用程序使用专用的数据库用户，具有最小必要权限：

```sql
-- 应用用户权限（仅数据操作）
GRANT SELECT, INSERT, UPDATE, DELETE ON pipeline_calc.* TO 'pipeline_app_user'@'%';

-- 不授予以下权限（安全考虑）：
-- CREATE, DROP, ALTER, INDEX, REFERENCES
```

### 连接字符串格式

应用程序使用以下连接字符串格式：

**C# Entity Framework Core:**
```csharp
"Server={DB_HOST};Port={DB_PORT};Database={DB_NAME};Uid={DB_USERNAME};Pwd={DB_PASSWORD};CharSet=utf8mb4;"
```

**Flutter MySQL 连接:**
```dart
MySqlConnection.createConnection(
  host: Environment.get('DB_HOST'),
  port: int.parse(Environment.get('DB_PORT')),
  userName: Environment.get('DB_USERNAME'),
  password: Environment.get('DB_PASSWORD'),
  databaseName: Environment.get('DB_NAME'),
);
```

## 安全配置

### 1. 密码安全

- 使用强密码（至少12位，包含大小写字母、数字、特殊字符）
- 定期更换密码
- 不要在代码中硬编码密码

### 2. 网络安全

```sql
-- 限制用户连接来源（生产环境建议）
CREATE USER 'pipeline_app_user'@'192.168.1.%' IDENTIFIED BY 'password';

-- 或限制为本地连接
CREATE USER 'pipeline_app_user'@'localhost' IDENTIFIED BY 'password';
```

### 3. SSL 连接（可选）

如果启用 SSL，在 `.env` 文件中配置：

```bash
DB_USE_SSL=true
DB_SSL_CA_PATH=/path/to/ca-cert.pem
DB_SSL_CERT_PATH=/path/to/client-cert.pem
DB_SSL_KEY_PATH=/path/to/client-key.pem
```

## 环境变量详细说明

| 变量名 | 必需 | 默认值 | 说明 |
|--------|------|--------|------|
| DB_HOST | 是 | localhost | MySQL 服务器地址 |
| DB_PORT | 是 | 3306 | MySQL 服务器端口 |
| DB_NAME | 是 | pipeline_calc | 数据库名称 |
| DB_USERNAME | 是 | - | 应用程序数据库用户名 |
| DB_PASSWORD | 是 | - | 应用程序数据库密码 |
| DB_ROOT_PASSWORD | 否 | - | Root 用户密码（仅初始化时使用） |
| JWT_SECRET | 是 | - | JWT 签名密钥 |
| JWT_EXPIRATION_HOURS | 否 | 24 | JWT Token 过期时间 |
| DB_MIN_POOL_SIZE | 否 | 5 | 连接池最小连接数 |
| DB_MAX_POOL_SIZE | 否 | 20 | 连接池最大连接数 |
| DB_CONNECTION_TIMEOUT | 否 | 30 | 连接超时时间（秒） |

## 故障排除

### 常见问题

1. **连接被拒绝**
   ```
   错误: Access denied for user 'pipeline_app_user'@'localhost'
   解决: 检查用户名、密码和权限配置
   ```

2. **字符集问题**
   ```
   错误: Incorrect string value
   解决: 确保数据库和表使用 utf8mb4 字符集
   ```

3. **连接超时**
   ```
   错误: Connection timeout
   解决: 检查网络连接和防火墙设置
   ```

### 调试步骤

1. 验证 MySQL 服务状态：
   ```bash
   systemctl status mysql  # Linux
   net start mysql         # Windows
   ```

2. 测试数据库连接：
   ```bash
   mysql -h {DB_HOST} -P {DB_PORT} -u {DB_USERNAME} -p {DB_NAME}
   ```

3. 检查用户权限：
   ```sql
   SHOW GRANTS FOR 'pipeline_app_user'@'%';
   ```

4. 验证表结构：
   ```sql
   USE pipeline_calc;
   SHOW TABLES;
   DESCRIBE Users;
   ```

## 备份和恢复

### 数据备份

```bash
# 完整备份
mysqldump -u root -p --single-transaction --routines --triggers pipeline_calc > backup_$(date +%Y%m%d_%H%M%S).sql

# 仅结构备份
mysqldump -u root -p --no-data pipeline_calc > schema_backup.sql

# 仅数据备份
mysqldump -u root -p --no-create-info pipeline_calc > data_backup.sql
```

### 数据恢复

```bash
# 恢复完整备份
mysql -u root -p pipeline_calc < backup_20240101_120000.sql

# 恢复到新数据库
mysql -u root -p -e "CREATE DATABASE pipeline_calc_restore;"
mysql -u root -p pipeline_calc_restore < backup_20240101_120000.sql
```

## 性能优化

### 索引优化

系统已创建必要的索引，如需额外优化：

```sql
-- 查看索引使用情况
SHOW INDEX FROM CalculationRecords;

-- 分析查询性能
EXPLAIN SELECT * FROM CalculationRecords WHERE UserId = 'user-id';
```

### 连接池配置

根据应用负载调整连接池参数：

```bash
# 高并发环境
DB_MIN_POOL_SIZE=10
DB_MAX_POOL_SIZE=50

# 低并发环境
DB_MIN_POOL_SIZE=2
DB_MAX_POOL_SIZE=10
```

## 监控和维护

### 定期维护任务

1. **清理过期数据**（可选）
2. **优化表结构**
3. **更新统计信息**
4. **检查索引效率**

### 监控指标

- 连接数使用情况
- 查询响应时间
- 磁盘空间使用
- 错误日志监控

## 联系支持

如遇到配置问题，请检查：
1. 环境变量配置是否正确
2. MySQL 服务是否正常运行
3. 网络连接是否畅通
4. 用户权限是否正确配置

更多技术支持，请参考项目文档或联系开发团队。