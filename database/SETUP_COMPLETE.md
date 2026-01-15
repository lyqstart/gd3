# 数据库设置完成指南

## 🎉 恭喜！数据库基础设施已就绪

您已成功完成MySQL数据库的创建和配置。本文档将指导您完成后续步骤。

## ✅ 已完成的工作

### 1. 数据库创建 (E1)
- ✅ pipeline_calc 数据库已创建
- ✅ utf8mb4 字符集配置完成
- ✅ 应用用户权限已配置
- ✅ 环境变量配置模板已创建

### 2. 表结构设计 (E2)
- ✅ Users 表（用户管理）
- ✅ CalculationRecords 表（计算记录）
- ✅ ParameterSets 表（参数组）
- ✅ SyncLogs 表（同步日志）
- ✅ SchemaVersions 表（版本管理）
- ✅ 15+ 个索引优化
- ✅ 3 个外键约束
- ✅ 2 个统计视图

### 3. 初始化与迁移 (E3)
- ✅ 完整初始化脚本 (mysql_init.sql)
- ✅ 迁移脚本模板
- ✅ 备份脚本 (backup_database.sh)
- ✅ 恢复脚本 (restore_database.sh)
- ✅ 回滚脚本 (rollback_migration.sh)
- ✅ 版本管理机制

## 📁 可用的脚本和工具

### 数据库管理脚本

| 脚本名称 | 用途 | 使用方法 |
|---------|------|---------|
| `setup_database.bat/sh` | 自动化数据库设置 | Windows: `setup_database.bat`<br>Linux/Mac: `./setup_database.sh` |
| `mysql_init.sql` | 完整初始化 | `mysql -u root -p < mysql_init.sql` |
| `backup_database.sh` | 数据库备份 | `./backup_database.sh` |
| `restore_database.sh` | 数据库恢复 | `./restore_database.sh <backup_file>` |
| `rollback_migration.sh` | 迁移回滚 | `./rollback_migration.sh <version>` |
| `verify_database.sql` | 验证数据库 | `mysql -u root -p pipeline_calc < verify_database.sql` |
| `test_schema.sql` | 测试表结构 | `mysql -u root -p pipeline_calc < test_schema.sql` |

### 文档资源

| 文档名称 | 内容 |
|---------|------|
| `README.md` | 完整配置指南 |
| `QUICK_START.md` | 5分钟快速开始 |
| `SCHEMA_DOCUMENTATION.md` | 表结构详细文档 |
| `INSTALL_MYSQL.md` | MySQL安装指南 |
| `.env.example` | 环境变量模板 |

## 🔧 后续配置步骤

### 步骤1: 配置环境变量

如果还没有配置，请执行:

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置文件
# Windows: notepad .env
# Linux/Mac: nano .env
```

填入实际配置:
```bash
DB_HOST=localhost
DB_PORT=3306
DB_NAME=pipeline_calc
DB_USERNAME=pipeline_app_user
DB_PASSWORD=your_secure_password_here
DB_ROOT_PASSWORD=your_root_password_here
JWT_SECRET=your_jwt_secret_key_here
```

### 步骤2: 验证数据库连接

```bash
# 测试应用用户连接
mysql -h localhost -u pipeline_app_user -p pipeline_calc

# 在MySQL中执行
SHOW TABLES;
SELECT * FROM SchemaVersions;
```

### 步骤3: 运行验证测试

```bash
# 运行完整验证
mysql -u pipeline_app_user -p pipeline_calc < verify_database.sql

# 运行功能测试
mysql -u pipeline_app_user -p pipeline_calc < test_schema.sql
```

预期结果: 所有测试显示 `PASS`

### 步骤4: 设置定期备份

**Linux/Mac (使用cron):**

```bash
# 编辑crontab
crontab -e

# 添加每天凌晨2点备份
0 2 * * * cd /path/to/database && ./backup_database.sh >> backup.log 2>&1
```

**Windows (使用任务计划程序):**

1. 打开"任务计划程序"
2. 创建基本任务
3. 触发器: 每天凌晨2点
4. 操作: 启动程序 `backup_database.bat`

## 🚀 开始开发后端API

数据库已就绪，现在可以开始开发后端API:

### F1. 身份验证API开发

**前置条件**: ✅ E2 完成

**开发内容**:
- 用户注册API
- 用户登录API
- JWT Token管理
- 密码哈希和验证

**数据库表**: Users

**开发指南**:
```csharp
// Entity Framework Core 连接配置
services.AddDbContext<ApplicationDbContext>(options =>
    options.UseMySql(
        Environment.GetEnvironmentVariable("DB_CONNECTION_STRING"),
        ServerVersion.AutoDetect(connectionString)
    )
);
```

### F2. 数据同步API开发

**前置条件**: ✅ E2 完成, F1 完成

**开发内容**:
- 计算记录同步API
- 参数组同步API
- 冲突检测API
- 同步日志API

**数据库表**: CalculationRecords, ParameterSets, SyncLogs

## 📊 数据库监控

### 查看数据库状态

```sql
-- 查看表大小
SELECT 
    TABLE_NAME,
    ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'pipeline_calc'
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;

-- 查看索引使用情况
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    CARDINALITY
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'pipeline_calc'
ORDER BY TABLE_NAME, INDEX_NAME;

-- 查看当前连接数
SHOW PROCESSLIST;

-- 查看数据库版本历史
SELECT * FROM SchemaVersions ORDER BY AppliedAt DESC;
```

### 性能监控

```sql
-- 慢查询日志
SHOW VARIABLES LIKE 'slow_query_log%';

-- 查询缓存状态
SHOW STATUS LIKE 'Qcache%';

-- InnoDB缓冲池状态
SHOW STATUS LIKE 'Innodb_buffer_pool%';
```

## 🔒 安全检查清单

- [ ] 数据库密码使用强密码（12+字符）
- [ ] .env 文件已添加到 .gitignore
- [ ] 应用用户仅有必要权限（SELECT, INSERT, UPDATE, DELETE）
- [ ] 生产环境限制远程访问IP
- [ ] 启用SSL连接（生产环境）
- [ ] 定期备份已配置
- [ ] 防火墙规则已配置
- [ ] MySQL版本保持更新

## 📝 维护任务

### 每日任务
- [ ] 检查备份是否成功
- [ ] 监控数据库大小增长
- [ ] 检查错误日志

### 每周任务
- [ ] 优化表结构: `OPTIMIZE TABLE table_name;`
- [ ] 更新统计信息: `ANALYZE TABLE table_name;`
- [ ] 检查慢查询日志

### 每月任务
- [ ] 清理过期同步日志
- [ ] 归档历史计算记录
- [ ] 验证备份可恢复性
- [ ] 检查MySQL安全更新

## 🆘 故障排除

### 问题: 连接被拒绝

**解决方案**:
```bash
# 检查MySQL服务状态
sudo systemctl status mysql

# 检查端口监听
netstat -an | grep 3306

# 检查用户权限
mysql -u root -p -e "SELECT User, Host FROM mysql.user WHERE User = 'pipeline_app_user';"
```

### 问题: 表不存在

**解决方案**:
```bash
# 重新运行初始化脚本
mysql -u root -p < mysql_init.sql

# 或运行表结构脚本
mysql -u root -p pipeline_calc < create_tables.sql
```

### 问题: 字符集问题

**解决方案**:
```sql
-- 检查字符集
SHOW VARIABLES LIKE 'character_set%';

-- 修改表字符集
ALTER TABLE table_name CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

## 📞 获取帮助

如遇到问题，请检查:

1. **日志文件**
   - MySQL错误日志: `/var/log/mysql/error.log`
   - 备份日志: `database/backup.log`

2. **文档资源**
   - [数据库配置指南](README.md)
   - [表结构文档](SCHEMA_DOCUMENTATION.md)
   - [MySQL官方文档](https://dev.mysql.com/doc/)

3. **验证脚本**
   ```bash
   mysql -u pipeline_app_user -p pipeline_calc < verify_database.sql
   ```

## 🎯 下一步行动

1. ✅ 数据库基础设施完成
2. 🔄 开始开发 F1. 身份验证API
3. 🔄 开始开发 F2. 数据同步API
4. 🔄 配置生产环境部署

---

**数据库版本**: 1.0.0  
**完成时间**: 当前  
**状态**: ✅ 生产就绪

祝开发顺利！🚀
