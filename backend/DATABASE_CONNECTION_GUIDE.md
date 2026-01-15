# 数据库连接配置指南

## 概述

本文档说明如何配置油气管道开孔封堵计算系统后端API的数据库连接。所有敏感信息（如数据库凭据、JWT密钥）均通过环境变量管理,确保安全性和灵活性。

---

## 环境变量配置

### 必需的环境变量

| 变量名 | 说明 | 示例值 | 是否必需 |
|--------|------|--------|----------|
| `DB_HOST` | MySQL数据库主机地址 | `localhost` 或 `db.example.com` | ✅ 是 |
| `DB_PORT` | MySQL数据库端口 | `3306` | ✅ 是 |
| `DB_NAME` | 数据库名称 | `pipeline_calc` | ✅ 是 |
| `DB_USER` | 数据库用户名 | `pipeline_app_user` | ✅ 是 |
| `DB_PASSWORD` | 数据库密码 | `your_secure_password` | ✅ 是 |
| `JWT_SECRET_KEY` | JWT签名密钥 | 至少32字符的随机字符串 | ✅ 是 |

### 可选的环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `DB_MIN_POOL_SIZE` | 连接池最小连接数 | `5` |
| `DB_MAX_POOL_SIZE` | 连接池最大连接数 | `20` |
| `DB_CONNECTION_TIMEOUT` | 连接超时时间(秒) | `30` |
| `JWT_ISSUER` | JWT发行者 | `PipelineCalculationAPI` |
| `JWT_AUDIENCE` | JWT受众 | `PipelineCalculationApp` |
| `JWT_EXPIRY_MINUTES` | Token过期时间(分钟) | `60` |

---

## Windows Server (IIS) 配置

### 方法1: 通过web.config配置

在应用程序根目录的`web.config`文件中添加环境变量:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath="dotnet" 
                  arguments=".\PipelineCalculationAPI.dll" 
                  stdoutLogEnabled="true" 
                  stdoutLogFile=".\logs\stdout" 
                  hostingModel="inprocess">
        <environmentVariables>
          <!-- 数据库配置 -->
          <environmentVariable name="DB_HOST" value="localhost" />
          <environmentVariable name="DB_PORT" value="3306" />
          <environmentVariable name="DB_NAME" value="pipeline_calc" />
          <environmentVariable name="DB_USER" value="pipeline_app_user" />
          <environmentVariable name="DB_PASSWORD" value="your_secure_password" />
          
          <!-- JWT配置 -->
          <environmentVariable name="JWT_SECRET_KEY" value="your_jwt_secret_key_minimum_32_characters_long" />
          <environmentVariable name="JWT_ISSUER" value="PipelineCalculationAPI" />
          <environmentVariable name="JWT_AUDIENCE" value="PipelineCalculationApp" />
          <environmentVariable name="JWT_EXPIRY_MINUTES" value="60" />
          
          <!-- 连接池配置(可选) -->
          <environmentVariable name="DB_MIN_POOL_SIZE" value="5" />
          <environmentVariable name="DB_MAX_POOL_SIZE" value="20" />
          <environmentVariable name="DB_CONNECTION_TIMEOUT" value="30" />
          
          <!-- 运行环境 -->
          <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
        </environmentVariables>
      </aspNetCore>
    </system.webServer>
  </location>
</configuration>
```

### 方法2: 通过IIS应用程序池配置

1. 打开IIS管理器
2. 选择应用程序池 → `PipelineCalculationAPI`
3. 右键 → 高级设置 → 环境变量
4. 添加上述环境变量

### 方法3: 通过系统环境变量

```powershell
# 设置系统环境变量(需要管理员权限)
[System.Environment]::SetEnvironmentVariable("DB_HOST", "localhost", "Machine")
[System.Environment]::SetEnvironmentVariable("DB_PORT", "3306", "Machine")
[System.Environment]::SetEnvironmentVariable("DB_NAME", "pipeline_calc", "Machine")
[System.Environment]::SetEnvironmentVariable("DB_USER", "pipeline_app_user", "Machine")
[System.Environment]::SetEnvironmentVariable("DB_PASSWORD", "your_secure_password", "Machine")
[System.Environment]::SetEnvironmentVariable("JWT_SECRET_KEY", "your_jwt_secret_key", "Machine")

# 重启IIS使环境变量生效
iisreset
```

---

## Linux (systemd) 配置

### 方法1: 在systemd服务文件中配置

编辑服务文件:

```bash
sudo nano /etc/systemd/system/pipelinecalcapi.service
```

添加环境变量:

```ini
[Unit]
Description=Pipeline Calculation API
After=network.target

[Service]
Type=notify
WorkingDirectory=/var/www/PipelineCalculationAPI
ExecStart=/usr/bin/dotnet /var/www/PipelineCalculationAPI/PipelineCalculationAPI.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=pipelinecalcapi
User=www-data

# 运行环境
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

# 数据库配置
Environment=DB_HOST=localhost
Environment=DB_PORT=3306
Environment=DB_NAME=pipeline_calc
Environment=DB_USER=pipeline_app_user
Environment=DB_PASSWORD=your_secure_password

# JWT配置
Environment=JWT_SECRET_KEY=your_jwt_secret_key_minimum_32_characters_long
Environment=JWT_ISSUER=PipelineCalculationAPI
Environment=JWT_AUDIENCE=PipelineCalculationApp
Environment=JWT_EXPIRY_MINUTES=60

# 连接池配置(可选)
Environment=DB_MIN_POOL_SIZE=5
Environment=DB_MAX_POOL_SIZE=20
Environment=DB_CONNECTION_TIMEOUT=30

[Install]
WantedBy=multi-user.target
```

重新加载并重启服务:

```bash
sudo systemctl daemon-reload
sudo systemctl restart pipelinecalcapi.service
```

### 方法2: 使用环境变量文件

创建环境变量文件:

```bash
sudo nano /etc/pipelinecalcapi.env
```

添加内容:

```bash
# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_NAME=pipeline_calc
DB_USER=pipeline_app_user
DB_PASSWORD=your_secure_password

# JWT配置
JWT_SECRET_KEY=your_jwt_secret_key_minimum_32_characters_long
JWT_ISSUER=PipelineCalculationAPI
JWT_AUDIENCE=PipelineCalculationApp
JWT_EXPIRY_MINUTES=60

# 连接池配置
DB_MIN_POOL_SIZE=5
DB_MAX_POOL_SIZE=20
DB_CONNECTION_TIMEOUT=30

# 运行环境
ASPNETCORE_ENVIRONMENT=Production
```

设置文件权限:

```bash
sudo chmod 600 /etc/pipelinecalcapi.env
sudo chown www-data:www-data /etc/pipelinecalcapi.env
```

修改systemd服务文件引用环境变量文件:

```ini
[Service]
EnvironmentFile=/etc/pipelinecalcapi.env
```

---

## Docker容器配置

### 使用docker-compose.yml

```yaml
version: '3.8'

services:
  api:
    image: pipelinecalcapi:latest
    container_name: pipelinecalcapi
    ports:
      - "5000:5000"
    environment:
      # 数据库配置
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_NAME=pipeline_calc
      - DB_USER=pipeline_app_user
      - DB_PASSWORD=${DB_PASSWORD}
      
      # JWT配置
      - JWT_SECRET_KEY=${JWT_SECRET_KEY}
      - JWT_ISSUER=PipelineCalculationAPI
      - JWT_AUDIENCE=PipelineCalculationApp
      - JWT_EXPIRY_MINUTES=60
      
      # 连接池配置
      - DB_MIN_POOL_SIZE=5
      - DB_MAX_POOL_SIZE=20
      - DB_CONNECTION_TIMEOUT=30
      
      # 运行环境
      - ASPNETCORE_ENVIRONMENT=Production
    depends_on:
      - mysql
    restart: unless-stopped

  mysql:
    image: mysql:8.0
    container_name: pipelinecalc_mysql
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      - MYSQL_DATABASE=pipeline_calc
      - MYSQL_USER=pipeline_app_user
      - MYSQL_PASSWORD=${DB_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./database/mysql_init.sql:/docker-entrypoint-initdb.d/01-init.sql
      - ./database/create_tables.sql:/docker-entrypoint-initdb.d/02-tables.sql
    ports:
      - "3306:3306"
    restart: unless-stopped

volumes:
  mysql_data:
```

创建`.env`文件(不要提交到版本控制):

```bash
DB_PASSWORD=your_secure_password
DB_ROOT_PASSWORD=your_root_password
JWT_SECRET_KEY=your_jwt_secret_key_minimum_32_characters_long
```

启动容器:

```bash
docker-compose up -d
```

---

## 连接字符串格式

### 标准连接字符串

```
Server=${DB_HOST};Port=${DB_PORT};Database=${DB_NAME};User=${DB_USER};Password=${DB_PASSWORD};CharSet=utf8mb4;
```

### 生产环境连接字符串(带连接池和SSL)

```
Server=${DB_HOST};Port=${DB_PORT};Database=${DB_NAME};User=${DB_USER};Password=${DB_PASSWORD};CharSet=utf8mb4;SslMode=Preferred;MinimumPoolSize=${DB_MIN_POOL_SIZE:5};MaximumPoolSize=${DB_MAX_POOL_SIZE:20};ConnectionTimeout=${DB_CONNECTION_TIMEOUT:30};ConnectionLifeTime=300;ConnectionReset=true;AllowUserVariables=true;
```

### 连接字符串参数说明

| 参数 | 说明 | 推荐值 |
|------|------|--------|
| `Server` | 数据库服务器地址 | `localhost` 或 IP地址 |
| `Port` | 数据库端口 | `3306` |
| `Database` | 数据库名称 | `pipeline_calc` |
| `User` | 数据库用户 | `pipeline_app_user` |
| `Password` | 数据库密码 | 强密码 |
| `CharSet` | 字符集 | `utf8mb4` |
| `SslMode` | SSL模式 | `Preferred` 或 `Required` |
| `MinimumPoolSize` | 最小连接数 | `5` |
| `MaximumPoolSize` | 最大连接数 | `20` |
| `ConnectionTimeout` | 连接超时(秒) | `30` |
| `ConnectionLifeTime` | 连接生命周期(秒) | `300` |
| `ConnectionReset` | 连接重置 | `true` |

---

## 数据库健康检查

### 验证数据库连接

```bash
# 使用curl测试健康检查端点
curl http://localhost:5000/health/database

# 预期响应
{
  "status": "healthy",
  "database": "connected",
  "timestamp": "2026-01-14T10:30:00Z"
}
```

### 使用MySQL客户端测试

```bash
# 测试数据库连接
mysql -h localhost -P 3306 -u pipeline_app_user -p pipeline_calc

# 输入密码后,执行测试查询
mysql> SELECT 1;
mysql> SHOW TABLES;
mysql> SELECT VERSION();
```

---

## 连接池配置优化

### 推荐配置

**小型应用(并发用户 < 50):**
```
MinimumPoolSize=5
MaximumPoolSize=20
ConnectionTimeout=30
```

**中型应用(并发用户 50-200):**
```
MinimumPoolSize=10
MaximumPoolSize=50
ConnectionTimeout=30
```

**大型应用(并发用户 > 200):**
```
MinimumPoolSize=20
MaximumPoolSize=100
ConnectionTimeout=60
```

### 监控连接池

在应用程序中添加连接池监控:

```csharp
// 在Startup或Program.cs中添加
builder.Services.AddHealthChecks()
    .AddDbContextCheck<ApplicationDbContext>("database");
```

---

## 安全最佳实践

### 1. 密码强度要求

- 最少16个字符
- 包含大小写字母、数字和特殊字符
- 不使用字典单词或常见密码
- 定期更换(建议每90天)

### 2. JWT密钥要求

- 最少32个字符
- 使用随机生成的字符串
- 不要使用可预测的值
- 生产环境和开发环境使用不同的密钥

### 3. 生成安全密钥

**PowerShell (Windows):**
```powershell
# 生成32字节随机密钥(Base64编码)
$bytes = New-Object byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($bytes)
[Convert]::ToBase64String($bytes)
```

**Bash (Linux):**
```bash
# 生成32字节随机密钥(Base64编码)
openssl rand -base64 32
```

### 4. 环境变量文件权限

```bash
# Linux: 限制环境变量文件权限
chmod 600 /etc/pipelinecalcapi.env
chown www-data:www-data /etc/pipelinecalcapi.env

# 确保.env文件不被提交到版本控制
echo ".env" >> .gitignore
```

### 5. SSL/TLS连接

生产环境建议启用SSL连接:

```
SslMode=Required;
SslCa=/path/to/ca-cert.pem;
SslCert=/path/to/client-cert.pem;
SslKey=/path/to/client-key.pem;
```

---

## 故障排除

### 常见错误及解决方案

#### 1. 连接被拒绝

**错误信息:**
```
Unable to connect to any of the specified MySQL hosts
```

**解决方案:**
- 检查MySQL服务是否运行: `sudo systemctl status mysql`
- 验证防火墙规则: `sudo ufw status`
- 检查MySQL绑定地址: `sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf`

#### 2. 认证失败

**错误信息:**
```
Access denied for user 'pipeline_app_user'@'localhost'
```

**解决方案:**
```sql
-- 验证用户存在
SELECT User, Host FROM mysql.user WHERE User='pipeline_app_user';

-- 重新授权
GRANT SELECT, INSERT, UPDATE, DELETE ON pipeline_calc.* TO 'pipeline_app_user'@'%';
FLUSH PRIVILEGES;
```

#### 3. 连接池耗尽

**错误信息:**
```
Timeout expired. The timeout period elapsed prior to obtaining a connection from the pool
```

**解决方案:**
- 增加`MaximumPoolSize`值
- 检查是否有连接泄漏(未正确释放)
- 优化数据库查询性能

#### 4. 环境变量未生效

**检查步骤:**
```bash
# Linux: 检查环境变量
sudo systemctl show pipelinecalcapi.service | grep Environment

# Windows: 检查IIS应用程序池环境变量
# 使用IIS管理器查看应用程序池高级设置
```

---

## 配置验证清单

部署前请确认以下项目:

- [ ] 所有必需的环境变量已配置
- [ ] 数据库连接字符串正确
- [ ] JWT密钥已设置且足够强
- [ ] 连接池参数适合应用规模
- [ ] 数据库用户权限正确配置
- [ ] 防火墙规则允许数据库连接
- [ ] SSL/TLS配置(如需要)
- [ ] 健康检查端点正常响应
- [ ] 日志记录正常工作
- [ ] 环境变量文件权限正确
- [ ] .env文件已添加到.gitignore
- [ ] 备份了配置文件

---

## 参考资源

- [MySQL Connector/NET文档](https://dev.mysql.com/doc/connector-net/en/)
- [ASP.NET Core配置文档](https://docs.microsoft.com/aspnet/core/fundamentals/configuration/)
- [Entity Framework Core文档](https://docs.microsoft.com/ef/core/)
- [MySQL安全最佳实践](https://dev.mysql.com/doc/refman/8.0/en/security-guidelines.html)

---

## 技术支持

如遇配置问题,请联系:
- 技术支持邮箱: support@example.com
- 文档更新日期: 2026-01-14
