# 数据库表结构文档

## 概述

本文档详细描述了油气管道开孔封堵计算系统的MySQL数据库表结构设计。数据库仅用于存储用户数据和同步记录，不包含任何计算逻辑。

## 数据库信息

- **数据库名称**: pipeline_calc
- **字符集**: utf8mb4
- **排序规则**: utf8mb4_unicode_ci
- **存储引擎**: InnoDB

## 表结构详细说明

### 1. Users（用户信息表）

存储系统用户的基本信息和认证数据。

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| Id | VARCHAR(36) | PRIMARY KEY | 用户唯一标识符（UUID格式） |
| Username | VARCHAR(50) | UNIQUE NOT NULL | 用户名，用于登录 |
| PasswordHash | VARCHAR(255) | NOT NULL | 密码哈希值（BCrypt/Argon2） |
| Email | VARCHAR(100) | NULL | 用户邮箱地址 |
| CreatedAt | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 账户创建时间 |
| UpdatedAt | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE | 最后更新时间 |
| IsActive | BOOLEAN | DEFAULT TRUE | 账户是否激活 |

**索引：**
- PRIMARY KEY: `Id`
- INDEX: `idx_username` (Username)
- INDEX: `idx_email` (Email)
- INDEX: `idx_created_at` (CreatedAt)

**设计说明：**
- 使用UUID作为主键，避免自增ID的安全问题
- Username设置唯一约束，防止重复注册
- PasswordHash存储加密后的密码，不存储明文
- IsActive字段支持软删除和账户禁用功能

---

### 2. CalculationRecords（计算记录表）

存储用户的计算历史记录，支持多种计算类型。

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| Id | VARCHAR(36) | PRIMARY KEY | 计算记录唯一标识符（UUID） |
| UserId | VARCHAR(36) | NOT NULL, FOREIGN KEY | 所属用户ID |
| CalculationType | VARCHAR(50) | NOT NULL | 计算类型（hole/manualHole/sealing/plug/stem） |
| Parameters | JSON | NOT NULL | 计算参数（JSON格式） |
| Results | JSON | NOT NULL | 计算结果（JSON格式） |
| CreatedAt | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 计算时间 |
| UpdatedAt | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE | 最后更新时间 |
| DeviceId | VARCHAR(100) | NULL | 设备标识符（用于多设备同步） |

**索引：**
- PRIMARY KEY: `Id`
- FOREIGN KEY: `UserId` REFERENCES Users(Id) ON DELETE CASCADE
- INDEX: `idx_user_type` (UserId, CalculationType)
- INDEX: `idx_created_at` (CreatedAt)
- INDEX: `idx_device_id` (DeviceId)
- INDEX: `idx_calculation_type` (CalculationType)

**计算类型枚举值：**
- `hole` - 开孔尺寸计算
- `manualHole` - 手动开孔计算
- `sealing` - 封堵尺寸计算
- `plug` - 下塞堵计算
- `stem` - 下塞柄计算

**JSON字段结构示例：**

```json
// Parameters 示例（开孔计算）
{
  "outerDiameter": 114.3,
  "innerDiameter": 102.3,
  "cutterOuterDiameter": 25.4,
  "cutterInnerDiameter": 19.1,
  "aValue": 50.0,
  "bValue": 30.0,
  "rValue": 15.0,
  "initialValue": 10.0,
  "gasketThickness": 3.0
}

// Results 示例（开孔计算）
{
  "emptyStroke": 93.0,
  "cuttingDistance": 20.5,
  "chordHeight": 15.3,
  "cuttingSize": 35.5,
  "totalStroke": 128.5,
  "plateStroke": 159.3
}
```

**设计说明：**
- 使用JSON字段存储参数和结果，支持灵活的数据结构
- 外键级联删除，用户删除时自动清理相关记录
- DeviceId支持多设备数据同步和冲突解决
- 复合索引(UserId, CalculationType)优化按用户和类型查询

---

### 3. ParameterSets（参数组表）

存储用户保存的参数组合，支持快速调用常用参数。

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| Id | VARCHAR(36) | PRIMARY KEY | 参数组唯一标识符（UUID） |
| UserId | VARCHAR(36) | NOT NULL, FOREIGN KEY | 所属用户ID |
| Name | VARCHAR(100) | NOT NULL | 参数组名称 |
| CalculationType | VARCHAR(50) | NOT NULL | 适用的计算类型 |
| Parameters | JSON | NOT NULL | 参数值（JSON格式） |
| IsPreset | BOOLEAN | DEFAULT FALSE | 是否为系统预设参数组 |
| CreatedAt | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| UpdatedAt | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE | 最后更新时间 |

**索引：**
- PRIMARY KEY: `Id`
- FOREIGN KEY: `UserId` REFERENCES Users(Id) ON DELETE CASCADE
- INDEX: `idx_user_type` (UserId, CalculationType)
- INDEX: `idx_name` (Name)
- INDEX: `idx_is_preset` (IsPreset)
- INDEX: `idx_created_at` (CreatedAt)

**参数组示例：**

```json
{
  "name": "DN100标准管道",
  "calculationType": "hole",
  "parameters": {
    "outerDiameter": 114.3,
    "innerDiameter": 102.3,
    "cutterOuterDiameter": 25.4,
    "cutterInnerDiameter": 19.1,
    "aValue": 50.0,
    "bValue": 30.0,
    "rValue": 15.0,
    "initialValue": 10.0,
    "gasketThickness": 3.0
  },
  "isPreset": false
}
```

**设计说明：**
- Name字段支持用户自定义参数组名称
- IsPreset标识系统预设参数组，不可删除
- 支持按计算类型分类管理参数组
- 外键级联删除，用户删除时清理参数组

---

### 4. SyncLogs（同步日志表）

记录数据同步操作的历史，用于追踪和调试同步问题。

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| Id | VARCHAR(36) | PRIMARY KEY | 同步日志唯一标识符（UUID） |
| UserId | VARCHAR(36) | NOT NULL, FOREIGN KEY | 用户ID |
| DeviceId | VARCHAR(100) | NOT NULL | 设备标识符 |
| SyncType | VARCHAR(20) | NOT NULL | 同步类型（upload/download） |
| RecordCount | INT | NOT NULL, DEFAULT 0 | 同步记录数量 |
| SyncTime | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 同步时间 |
| Status | VARCHAR(20) | NOT NULL | 同步状态（success/failed） |
| ErrorMessage | TEXT | NULL | 错误信息（失败时记录） |

**索引：**
- PRIMARY KEY: `Id`
- FOREIGN KEY: `UserId` REFERENCES Users(Id) ON DELETE CASCADE
- INDEX: `idx_user_device` (UserId, DeviceId)
- INDEX: `idx_sync_time` (SyncTime)
- INDEX: `idx_status` (Status)
- INDEX: `idx_sync_type` (SyncType)

**同步类型枚举值：**
- `upload` - 上传本地数据到云端
- `download` - 从云端下载数据到本地

**同步状态枚举值：**
- `success` - 同步成功
- `failed` - 同步失败

**设计说明：**
- 记录每次同步操作的详细信息
- 支持按用户和设备查询同步历史
- ErrorMessage字段记录失败原因，便于调试
- 复合索引(UserId, DeviceId)优化多设备查询

---

## 数据库视图

### 1. UserStats（用户统计视图）

提供用户活动统计信息的汇总视图。

```sql
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
```

**字段说明：**
- `UserId` - 用户ID
- `Username` - 用户名
- `UserCreatedAt` - 用户注册时间
- `TotalCalculations` - 总计算次数
- `TotalParameterSets` - 保存的参数组数量
- `TotalSyncOperations` - 同步操作次数
- `LastCalculationTime` - 最后计算时间
- `LastSyncTime` - 最后同步时间

---

### 2. CalculationTypeStats（计算类型统计视图）

提供各计算类型的使用统计信息。

```sql
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
```

**字段说明：**
- `CalculationType` - 计算类型
- `TotalCount` - 总使用次数
- `UniqueUsers` - 使用该类型的用户数
- `FirstCalculation` - 首次使用时间
- `LastCalculation` - 最后使用时间
- `AvgProcessingTime` - 平均处理时间（秒）

---

## 外键关系图

```
Users (1) ----< (N) CalculationRecords
  |
  +----------< (N) ParameterSets
  |
  +----------< (N) SyncLogs
```

**级联删除规则：**
- 删除用户时，自动删除其所有计算记录
- 删除用户时，自动删除其所有参数组
- 删除用户时，自动删除其所有同步日志

---

## 数据完整性约束

### 1. 主键约束
- 所有表使用UUID作为主键，确保全局唯一性
- 支持分布式系统和多设备数据合并

### 2. 外键约束
- 所有外键设置ON DELETE CASCADE
- 确保数据一致性，防止孤立记录

### 3. 唯一性约束
- Users.Username - 防止用户名重复
- 其他表无唯一性约束，支持数据重复

### 4. 非空约束
- 关键字段设置NOT NULL
- 可选字段允许NULL值

### 5. 默认值约束
- 时间字段自动设置当前时间
- 布尔字段设置合理默认值

---

## 索引策略

### 1. 主键索引
- 所有表的Id字段自动创建聚簇索引

### 2. 外键索引
- 所有外键字段自动创建索引，优化JOIN查询

### 3. 查询优化索引
- 按用户查询：idx_user_type (UserId, CalculationType)
- 按时间查询：idx_created_at, idx_sync_time
- 按设备查询：idx_device_id, idx_user_device
- 按状态查询：idx_status, idx_is_preset

### 4. 复合索引
- (UserId, CalculationType) - 优化用户特定类型查询
- (UserId, DeviceId) - 优化多设备同步查询

---

## 性能优化建议

### 1. 查询优化
```sql
-- 使用索引查询
SELECT * FROM CalculationRecords 
WHERE UserId = 'user-id' AND CalculationType = 'hole'
ORDER BY CreatedAt DESC LIMIT 10;

-- 避免全表扫描
SELECT * FROM CalculationRecords WHERE JSON_EXTRACT(Parameters, '$.outerDiameter') > 100;
-- 建议：在应用层过滤JSON字段
```

### 2. 分页查询
```sql
-- 使用LIMIT和OFFSET
SELECT * FROM CalculationRecords 
WHERE UserId = 'user-id'
ORDER BY CreatedAt DESC 
LIMIT 20 OFFSET 0;
```

### 3. 批量操作
```sql
-- 批量插入
INSERT INTO CalculationRecords (Id, UserId, CalculationType, Parameters, Results) 
VALUES 
  ('id1', 'user1', 'hole', '{}', '{}'),
  ('id2', 'user1', 'sealing', '{}', '{}');
```

---

## 数据迁移和版本管理

### 版本控制
- 当前版本：1.0.0
- 迁移脚本位置：`database/migrations/`
- 版本记录表：待E3任务实现

### 迁移策略
1. 向后兼容的修改（添加字段、索引）
2. 数据迁移脚本（修改字段类型、结构调整）
3. 回滚脚本（支持版本回退）

---

## 安全考虑

### 1. 数据加密
- 密码使用BCrypt/Argon2哈希存储
- 敏感数据传输使用SSL/TLS加密

### 2. 权限控制
- 应用用户仅有数据操作权限（SELECT, INSERT, UPDATE, DELETE）
- 不授予结构修改权限（CREATE, DROP, ALTER）

### 3. SQL注入防护
- 使用参数化查询
- 避免动态SQL拼接

### 4. 数据备份
- 定期全量备份
- 增量备份策略
- 备份数据加密存储

---

## 监控和维护

### 1. 性能监控
- 慢查询日志
- 索引使用率
- 表大小增长

### 2. 定期维护
- 优化表结构：`OPTIMIZE TABLE`
- 更新统计信息：`ANALYZE TABLE`
- 检查表完整性：`CHECK TABLE`

### 3. 数据清理
- 定期清理过期同步日志
- 归档历史计算记录
- 清理无效用户数据

---

## 附录

### A. 表大小估算

假设：
- 1000个活跃用户
- 每用户每天10次计算
- 每用户5个参数组
- 保留1年历史数据

**估算结果：**
- Users: ~100KB
- CalculationRecords: ~3.65GB (1000 * 10 * 365 * 1KB)
- ParameterSets: ~5MB (1000 * 5 * 1KB)
- SyncLogs: ~365MB (1000 * 1 * 365 * 1KB)
- **总计**: ~4GB

### B. 查询性能基准

基于上述数据量：
- 按用户ID查询计算记录：< 10ms
- 按时间范围查询：< 50ms
- 统计视图查询：< 100ms
- 全文搜索（如需要）：< 200ms

---

**文档版本**: 1.0.0  
**最后更新**: 2024年  
**维护者**: 开发团队