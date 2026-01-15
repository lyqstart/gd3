# 油气管道开孔封堵计算系统 - 后端API

## 概述

本项目是油气管道开孔封堵计算系统的后端API服务，基于ASP.NET Core 8.0开发，提供用户认证和数据同步功能。

**重要说明**：
- ✅ 后端仅负责用户认证和数据同步，不包含任何计算逻辑
- ✅ 所有计算功能均在Flutter客户端完成
- ✅ 数据库仅存储用户数据和同步记录

## 技术栈

- **框架**: ASP.NET Core 8.0
- **数据库**: MySQL 8.0+
- **ORM**: Entity Framework Core
- **认证**: JWT (JSON Web Token)
- **API文档**: Swagger/OpenAPI

## 项目结构

```
PipelineCalculationAPI/
├── Controllers/          # API控制器
│   └── AuthController.cs
├── Data/                # 数据访问层
│   └── ApplicationDbContext.cs
├── DTOs/                # 数据传输对象
│   └── AuthDTOs.cs
├── Models/              # 数据模型
│   ├── User.cs
│   ├── CalculationRecord.cs
│   └── ParameterSet.cs
├── Services/            # 业务逻辑服务
│   ├── IAuthService.cs
│   └── AuthService.cs
├── Program.cs           # 应用程序入口
├── appsettings.json     # 配置文件模板
└── .env.example         # 环境变量示例
```

## 环境配置

### 1. 配置环境变量

复制 `.env.example` 文件为 `.env`：

```bash
cp .env.example .env
```

编辑 `.env` 文件，配置实际的数据库连接和JWT密钥：

```env
# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_NAME=pipeline_calc
DB_USER=api_user
DB_PASSWORD=your_secure_password

# JWT配置（至少32字符）
JWT_SECRET_KEY=your_jwt_secret_key_at_least_32_characters_long
```

### 2. 配置appsettings.json

`appsettings.json` 使用环境变量占位符，运行时会自动替换：

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=${DB_HOST};Port=${DB_PORT};Database=${DB_NAME};User=${DB_USER};Password=${DB_PASSWORD};CharSet=utf8mb4;"
  },
  "JwtSettings": {
    "SecretKey": "${JWT_SECRET_KEY}",
    "Issuer": "PipelineCalculationAPI",
    "Audience": "PipelineCalculationApp",
    "ExpiryMinutes": 60
  }
}
```

## 数据库准备

### 1. 创建数据库

确保MySQL数据库已创建（参考 `database/` 目录下的脚本）：

```bash
# 在项目根目录执行
cd database
./setup_database.sh  # Linux/Mac
# 或
setup_database.bat   # Windows
```

### 2. 运行数据库迁移

```bash
cd backend/PipelineCalculationAPI

# 创建迁移
dotnet ef migrations add InitialCreate

# 应用迁移
dotnet ef database update
```

## 运行项目

### 开发环境

```bash
cd backend/PipelineCalculationAPI

# 恢复依赖
dotnet restore

# 运行项目
dotnet run
```

API将在以下地址启动：
- HTTP: http://localhost:5000
- HTTPS: https://localhost:5001
- Swagger UI: http://localhost:5000 或 https://localhost:5001

### 生产环境

```bash
# 发布项目
dotnet publish -c Release -o ./publish

# 运行发布版本
cd publish
dotnet PipelineCalculationAPI.dll
```

## API端点

### 身份验证 API

#### 1. 用户注册
```http
POST /api/auth/register
Content-Type: application/json

{
  "username": "testuser",
  "password": "password123",
  "email": "test@example.com"
}
```

#### 2. 用户登录
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "testuser",
  "password": "password123"
}
```

响应示例：
```json
{
  "success": true,
  "message": "登录成功",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": "2024-01-15T10:30:00Z",
  "user": {
    "id": "user-id",
    "username": "testuser",
    "email": "test@example.com",
    "createdAt": "2024-01-14T10:30:00Z",
    "isActive": true
  }
}
```

#### 3. 获取用户资料
```http
GET /api/auth/profile
Authorization: Bearer {token}
```

#### 4. 修改密码
```http
POST /api/auth/change-password
Authorization: Bearer {token}
Content-Type: application/json

{
  "currentPassword": "oldpassword",
  "newPassword": "newpassword123"
}
```

#### 5. 登出
```http
POST /api/auth/logout
Authorization: Bearer {token}
```

#### 6. 验证令牌
```http
GET /api/auth/validate
Authorization: Bearer {token}
```

### 健康检查

```http
GET /health
GET /health/database
```

## 安全性

### 密码安全
- 使用PBKDF2算法进行密码哈希
- 每个密码使用唯一的盐值
- 迭代次数：10,000次
- 哈希算法：SHA256

### JWT令牌
- 使用HS256算法签名
- 默认有效期：60分钟
- 包含用户ID和用户名声明
- 支持令牌验证和刷新

### 数据库安全
- 所有敏感配置通过环境变量管理
- 不在代码中硬编码任何凭据
- 使用参数化查询防止SQL注入
- 实施最小权限原则

## 部署

### Windows Server (IIS)

1. 安装IIS和ASP.NET Core托管包
2. 发布项目到目标目录
3. 在IIS中创建应用程序池
4. 配置环境变量
5. 创建网站并绑定到应用程序池

### Linux (Nginx)

1. 安装.NET 8.0 Runtime
2. 发布项目到服务器
3. 创建systemd服务
4. 配置Nginx反向代理
5. 设置环境变量

详细部署文档请参考 `docs/deployment.md`

## 开发指南

### 添加新的API端点

1. 在 `Controllers/` 目录创建控制器
2. 在 `Services/` 目录创建服务接口和实现
3. 在 `DTOs/` 目录创建数据传输对象
4. 在 `Program.cs` 中注册服务
5. 添加XML注释以生成API文档

### 数据库迁移

```bash
# 添加新迁移
dotnet ef migrations add MigrationName

# 应用迁移
dotnet ef database update

# 回滚迁移
dotnet ef database update PreviousMigrationName

# 删除最后一个迁移
dotnet ef migrations remove
```

## 测试

```bash
# 运行单元测试
dotnet test

# 运行集成测试
dotnet test --filter Category=Integration
```

## 日志

日志配置在 `appsettings.json` 中：

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

日志级别：
- `Trace`: 最详细的日志
- `Debug`: 调试信息
- `Information`: 一般信息
- `Warning`: 警告信息
- `Error`: 错误信息
- `Critical`: 严重错误

## 故障排查

### 数据库连接失败

1. 检查MySQL服务是否运行
2. 验证环境变量配置
3. 确认数据库用户权限
4. 检查防火墙设置

### JWT令牌验证失败

1. 确认JWT密钥配置正确
2. 检查令牌是否过期
3. 验证Issuer和Audience配置

### API返回500错误

1. 查看应用程序日志
2. 检查数据库连接
3. 验证请求数据格式

## 许可证

本项目为企业内部使用，未开源。

## 联系方式

如有问题，请联系开发团队。
