# 服务器部署指南

## 概述

本文档提供油气管道开孔封堵计算系统后端API的完整部署指南，支持Windows Server（IIS）和Linux服务器（Nginx）两种部署方式。

## 系统要求

### 通用要求
- .NET 8.0 Runtime或更高版本
- MySQL 8.0+数据库服务器
- 至少2GB可用内存
- 至少10GB可用磁盘空间

### Windows Server要求
- Windows Server 2016或更高版本
- IIS 10.0或更高版本
- .NET Core Hosting Bundle

### Linux服务器要求
- Ubuntu 20.04 LTS / CentOS 8 / Debian 11或更高版本
- Nginx 1.18+
- systemd（用于服务管理）

---

## Windows Server部署（IIS）

### 1. 安装前置组件

#### 1.1 安装.NET Core Hosting Bundle

```powershell
# 下载并安装.NET 8.0 Hosting Bundle
# 访问: https://dotnet.microsoft.com/download/dotnet/8.0
# 下载: ASP.NET Core Runtime Hosting Bundle

# 安装后重启IIS
iisreset
```

#### 1.2 启用IIS功能

```powershell
# 使用PowerShell启用IIS
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment
Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HealthAndDiagnostics
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security
Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Performance
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerManagementTools
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole
```

### 2. 发布应用程序

```powershell
# 在开发机器上发布应用
cd backend/PipelineCalculationAPI
dotnet publish -c Release -o ./publish

# 将publish文件夹复制到服务器
# 目标路径: C:\inetpub\wwwroot\PipelineCalculationAPI
```

### 3. 配置IIS

#### 3.1 创建应用程序池

1. 打开IIS管理器
2. 右键点击"应用程序池" → "添加应用程序池"
3. 配置：
   - 名称: `PipelineCalculationAPI`
   - .NET CLR版本: `无托管代码`
   - 托管管道模式: `集成`
4. 高级设置：
   - 启用32位应用程序: `False`
   - 托管运行时版本: `无托管代码`
   - 标识: `ApplicationPoolIdentity`

#### 3.2 创建网站

1. 右键点击"网站" → "添加网站"
2. 配置：
   - 网站名称: `PipelineCalculationAPI`
   - 应用程序池: `PipelineCalculationAPI`
   - 物理路径: `C:\inetpub\wwwroot\PipelineCalculationAPI`
   - 绑定类型: `http`
   - IP地址: `全部未分配`
   - 端口: `5000`
   - 主机名: `api.yourdomain.com`（可选）

#### 3.3 配置HTTPS（推荐）

1. 获取SSL证书（Let's Encrypt或商业证书）
2. 在IIS中导入证书
3. 添加HTTPS绑定：
   - 类型: `https`
   - 端口: `443`
   - SSL证书: 选择导入的证书

### 4. 配置环境变量

在应用程序池的高级设置中配置环境变量：

```xml
<!-- 在web.config中添加 -->
<configuration>
  <system.webServer>
    <aspNetCore processPath="dotnet" 
                arguments=".\PipelineCalculationAPI.dll" 
                stdoutLogEnabled="true" 
                stdoutLogFile=".\logs\stdout">
      <environmentVariables>
        <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
        <environmentVariable name="DB_HOST" value="localhost" />
        <environmentVariable name="DB_PORT" value="3306" />
        <environmentVariable name="DB_NAME" value="pipeline_calc" />
        <environmentVariable name="DB_USER" value="pipeline_app_user" />
        <environmentVariable name="DB_PASSWORD" value="your_password" />
        <environmentVariable name="JWT_SECRET_KEY" value="your_jwt_secret_key_here" />
      </environmentVariables>
    </aspNetCore>
  </system.webServer>
</configuration>
```

### 5. 配置权限

```powershell
# 授予应用程序池标识对应用文件夹的权限
icacls "C:\inetpub\wwwroot\PipelineCalculationAPI" /grant "IIS AppPool\PipelineCalculationAPI:(OI)(CI)F" /T

# 授予日志文件夹写入权限
icacls "C:\inetpub\wwwroot\PipelineCalculationAPI\logs" /grant "IIS AppPool\PipelineCalculationAPI:(OI)(CI)M" /T
```

### 6. 启动和验证

```powershell
# 启动网站
Start-WebSite -Name "PipelineCalculationAPI"

# 验证应用程序
Invoke-WebRequest -Uri "http://localhost:5000/health" -UseBasicParsing
```

---

## Linux服务器部署（Nginx）

### 1. 安装前置组件

#### 1.1 安装.NET Runtime

```bash
# Ubuntu 20.04/22.04
wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

sudo apt-get update
sudo apt-get install -y aspnetcore-runtime-8.0

# CentOS 8/Rocky Linux 8
sudo dnf install -y aspnetcore-runtime-8.0
```

#### 1.2 安装Nginx

```bash
# Ubuntu
sudo apt-get install -y nginx

# CentOS/Rocky Linux
sudo dnf install -y nginx
```

### 2. 发布和部署应用程序

```bash
# 在开发机器上发布
cd backend/PipelineCalculationAPI
dotnet publish -c Release -o ./publish

# 将文件传输到服务器
scp -r ./publish user@server:/var/www/PipelineCalculationAPI

# 在服务器上设置权限
sudo chown -R www-data:www-data /var/www/PipelineCalculationAPI
sudo chmod -R 755 /var/www/PipelineCalculationAPI
```

### 3. 创建systemd服务

创建服务文件：

```bash
sudo nano /etc/systemd/system/pipelinecalcapi.service
```

添加以下内容：

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
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

# 环境变量
Environment=DB_HOST=localhost
Environment=DB_PORT=3306
Environment=DB_NAME=pipeline_calc
Environment=DB_USER=pipeline_app_user
Environment=DB_PASSWORD=your_password
Environment=JWT_SECRET_KEY=your_jwt_secret_key_here

[Install]
WantedBy=multi-user.target
```

启用并启动服务：

```bash
# 重新加载systemd配置
sudo systemctl daemon-reload

# 启用服务（开机自启）
sudo systemctl enable pipelinecalcapi.service

# 启动服务
sudo systemctl start pipelinecalcapi.service

# 检查状态
sudo systemctl status pipelinecalcapi.service

# 查看日志
sudo journalctl -u pipelinecalcapi.service -f
```

### 4. 配置Nginx反向代理

创建Nginx配置文件：

```bash
sudo nano /etc/nginx/sites-available/pipelinecalcapi
```

添加以下内容：

```nginx
# HTTP配置
server {
    listen 80;
    listen [::]:80;
    server_name api.yourdomain.com;

    # 重定向到HTTPS（如果配置了SSL）
    # return 301 https://$server_name$request_uri;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # 缓冲设置
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }

    # 健康检查端点
    location /health {
        proxy_pass http://localhost:5000/health;
        access_log off;
    }

    # 日志配置
    access_log /var/log/nginx/pipelinecalcapi_access.log;
    error_log /var/log/nginx/pipelinecalcapi_error.log;
}

# HTTPS配置（需要SSL证书）
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.yourdomain.com;

    # SSL证书配置
    ssl_certificate /etc/ssl/certs/your_cert.crt;
    ssl_certificate_key /etc/ssl/private/your_key.key;
    
    # SSL安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /health {
        proxy_pass http://localhost:5000/health;
        access_log off;
    }

    access_log /var/log/nginx/pipelinecalcapi_ssl_access.log;
    error_log /var/log/nginx/pipelinecalcapi_ssl_error.log;
}
```

启用配置：

```bash
# 创建符号链接
sudo ln -s /etc/nginx/sites-available/pipelinecalcapi /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重新加载Nginx
sudo systemctl reload nginx
```

### 5. 配置SSL证书（Let's Encrypt）

```bash
# 安装Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d api.yourdomain.com

# 自动续期（Certbot会自动配置）
sudo certbot renew --dry-run
```

### 6. 配置防火墙

```bash
# Ubuntu (UFW)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# CentOS/Rocky Linux (firewalld)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

---

## 环境变量配置

### 生产环境必需的环境变量

| 变量名 | 说明 | 示例值 |
|--------|------|--------|
| `ASPNETCORE_ENVIRONMENT` | 运行环境 | `Production` |
| `DB_HOST` | 数据库主机 | `localhost` 或 `db.example.com` |
| `DB_PORT` | 数据库端口 | `3306` |
| `DB_NAME` | 数据库名称 | `pipeline_calc` |
| `DB_USER` | 数据库用户 | `pipeline_app_user` |
| `DB_PASSWORD` | 数据库密码 | `your_secure_password` |
| `JWT_SECRET_KEY` | JWT密钥 | 至少32字符的随机字符串 |
| `JWT_ISSUER` | JWT发行者 | `PipelineCalculationAPI` |
| `JWT_AUDIENCE` | JWT受众 | `PipelineCalculationApp` |
| `JWT_EXPIRY_MINUTES` | Token过期时间 | `60` |

### 可选环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `ASPNETCORE_URLS` | 监听地址 | `http://localhost:5000` |
| `Logging__LogLevel__Default` | 日志级别 | `Information` |
| `DB_MIN_POOL_SIZE` | 连接池最小值 | `5` |
| `DB_MAX_POOL_SIZE` | 连接池最大值 | `20` |
| `DB_CONNECTION_TIMEOUT` | 连接超时（秒） | `30` |

---

## 健康检查和监控

### 健康检查端点

```bash
# 基本健康检查
curl http://localhost:5000/health

# 数据库连接检查
curl http://localhost:5000/health/database
```

### 日志查看

**Windows (IIS):**
```powershell
# 查看stdout日志
Get-Content C:\inetpub\wwwroot\PipelineCalculationAPI\logs\stdout_*.log -Tail 50

# 查看IIS日志
Get-Content C:\inetpub\logs\LogFiles\W3SVC1\*.log -Tail 50
```

**Linux (systemd):**
```bash
# 查看应用日志
sudo journalctl -u pipelinecalcapi.service -f

# 查看Nginx访问日志
sudo tail -f /var/log/nginx/pipelinecalcapi_access.log

# 查看Nginx错误日志
sudo tail -f /var/log/nginx/pipelinecalcapi_error.log
```

### 性能监控

建议使用以下工具进行监控：
- **Application Insights**（Azure）
- **Prometheus + Grafana**
- **ELK Stack**（Elasticsearch, Logstash, Kibana）
- **Datadog**

---

## 故障排除

### 常见问题

#### 1. 应用无法启动

**检查步骤：**
```bash
# Linux
sudo systemctl status pipelinecalcapi.service
sudo journalctl -u pipelinecalcapi.service -n 100

# Windows
# 查看事件查看器 → Windows日志 → 应用程序
```

**可能原因：**
- .NET Runtime未安装或版本不匹配
- 环境变量配置错误
- 数据库连接失败
- 端口被占用

#### 2. 数据库连接失败

**检查步骤：**
```bash
# 测试数据库连接
mysql -h localhost -u pipeline_app_user -p pipeline_calc

# 检查MySQL服务状态
sudo systemctl status mysql
```

**解决方案：**
- 验证数据库凭据
- 检查MySQL服务是否运行
- 验证防火墙规则
- 检查MySQL用户权限

#### 3. 502 Bad Gateway（Nginx）

**检查步骤：**
```bash
# 检查应用是否运行
sudo systemctl status pipelinecalcapi.service

# 检查端口监听
sudo netstat -tlnp | grep 5000

# 检查Nginx错误日志
sudo tail -f /var/log/nginx/pipelinecalcapi_error.log
```

#### 4. 性能问题

**优化建议：**
- 增加数据库连接池大小
- 启用响应压缩
- 配置Nginx缓存
- 优化数据库查询
- 增加服务器资源

---

## 安全最佳实践

1. **使用HTTPS**：生产环境必须启用SSL/TLS
2. **强密码策略**：数据库和JWT密钥使用强随机密码
3. **最小权限原则**：数据库用户仅授予必要权限
4. **定期更新**：保持.NET Runtime和依赖包最新
5. **防火墙配置**：仅开放必要端口
6. **日志审计**：启用详细日志并定期审查
7. **备份策略**：定期备份数据库和配置文件
8. **限流保护**：配置Nginx限流防止DDoS攻击

---

## 更新和维护

### 应用更新流程

1. **备份当前版本**
2. **发布新版本**
3. **停止服务**
4. **替换文件**
5. **启动服务**
6. **验证功能**

**Windows:**
```powershell
# 停止网站
Stop-WebSite -Name "PipelineCalculationAPI"

# 替换文件
Copy-Item -Path .\publish\* -Destination C:\inetpub\wwwroot\PipelineCalculationAPI -Recurse -Force

# 启动网站
Start-WebSite -Name "PipelineCalculationAPI"
```

**Linux:**
```bash
# 停止服务
sudo systemctl stop pipelinecalcapi.service

# 备份当前版本
sudo cp -r /var/www/PipelineCalculationAPI /var/www/PipelineCalculationAPI.backup

# 替换文件
sudo cp -r ./publish/* /var/www/PipelineCalculationAPI/

# 设置权限
sudo chown -R www-data:www-data /var/www/PipelineCalculationAPI

# 启动服务
sudo systemctl start pipelinecalcapi.service

# 验证
curl http://localhost:5000/health
```

---

## 支持和联系

如遇部署问题，请参考：
- [.NET部署文档](https://docs.microsoft.com/aspnet/core/host-and-deploy/)
- [Nginx文档](https://nginx.org/en/docs/)
- [IIS文档](https://docs.microsoft.com/iis/)

技术支持：support@example.com
