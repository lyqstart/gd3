# MySQL 安装指南

## 概述

本文档提供在不同操作系统上安装MySQL的详细步骤。

## Windows 安装

### 方法1: 使用MySQL Installer（推荐）

1. **下载MySQL Installer**
   - 访问: https://dev.mysql.com/downloads/installer/
   - 下载: mysql-installer-community-8.0.x.msi

2. **运行安装程序**
   ```
   双击 mysql-installer-community-8.0.x.msi
   ```

3. **选择安装类型**
   - Developer Default（开发者默认）- 推荐
   - Server only（仅服务器）- 最小安装

4. **配置MySQL Server**
   - 端口: 3306（默认）
   - Root密码: 设置强密码
   - Windows Service: 勾选"Start MySQL Server at System Startup"

5. **验证安装**
   ```cmd
   mysql --version
   mysql -u root -p
   ```

### 方法2: 使用Chocolatey

```powershell
# 安装Chocolatey（如果未安装）
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 安装MySQL
choco install mysql

# 启动MySQL服务
net start MySQL80
```

## Linux 安装

### Ubuntu/Debian

```bash
# 更新包索引
sudo apt update

# 安装MySQL Server
sudo apt install mysql-server

# 启动MySQL服务
sudo systemctl start mysql
sudo systemctl enable mysql

# 安全配置
sudo mysql_secure_installation

# 验证安装
mysql --version
sudo mysql -u root -p
```

### CentOS/RHEL

```bash
# 添加MySQL Yum Repository
sudo yum install https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm

# 安装MySQL Server
sudo yum install mysql-community-server

# 启动MySQL服务
sudo systemctl start mysqld
sudo systemctl enable mysqld

# 获取临时root密码
sudo grep 'temporary password' /var/log/mysqld.log

# 安全配置
sudo mysql_secure_installation

# 验证安装
mysql --version
mysql -u root -p
```

### Fedora

```bash
# 安装MySQL Server
sudo dnf install mysql-server

# 启动MySQL服务
sudo systemctl start mysqld
sudo systemctl enable mysqld

# 安全配置
sudo mysql_secure_installation
```

## macOS 安装

### 方法1: 使用Homebrew（推荐）

```bash
# 安装Homebrew（如果未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装MySQL
brew install mysql

# 启动MySQL服务
brew services start mysql

# 安全配置
mysql_secure_installation

# 验证安装
mysql --version
mysql -u root -p
```

### 方法2: 使用DMG安装包

1. 下载MySQL DMG: https://dev.mysql.com/downloads/mysql/
2. 双击DMG文件安装
3. 按照安装向导完成安装
4. 在系统偏好设置中启动MySQL

## Docker 安装（跨平台）

```bash
# 拉取MySQL镜像
docker pull mysql:8.0

# 运行MySQL容器
docker run --name pipeline-mysql \
  -e MYSQL_ROOT_PASSWORD=your_root_password \
  -e MYSQL_DATABASE=pipeline_calc \
  -e MYSQL_USER=pipeline_app_user \
  -e MYSQL_PASSWORD=your_app_password \
  -p 3306:3306 \
  -v mysql-data:/var/lib/mysql \
  -d mysql:8.0

# 验证容器运行
docker ps

# 连接到MySQL
docker exec -it pipeline-mysql mysql -u root -p
```

## 安装后配置

### 1. 创建应用数据库和用户

```sql
-- 连接到MySQL
mysql -u root -p

-- 创建数据库
CREATE DATABASE pipeline_calc CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 创建应用用户
CREATE USER 'pipeline_app_user'@'%' IDENTIFIED BY 'your_secure_password';

-- 授予权限
GRANT SELECT, INSERT, UPDATE, DELETE ON pipeline_calc.* TO 'pipeline_app_user'@'%';
FLUSH PRIVILEGES;

-- 验证
SHOW DATABASES;
SELECT User, Host FROM mysql.user WHERE User = 'pipeline_app_user';
```

### 2. 配置远程访问（可选）

**编辑MySQL配置文件:**

Linux: `/etc/mysql/mysql.conf.d/mysqld.cnf`
Windows: `C:\ProgramData\MySQL\MySQL Server 8.0\my.ini`
macOS: `/usr/local/etc/my.cnf`

```ini
[mysqld]
bind-address = 0.0.0.0
```

**重启MySQL服务:**

```bash
# Linux
sudo systemctl restart mysql

# Windows
net stop MySQL80
net start MySQL80

# macOS
brew services restart mysql
```

### 3. 配置防火墙

**Linux (UFW):**
```bash
sudo ufw allow 3306/tcp
```

**Windows:**
```powershell
New-NetFirewallRule -DisplayName "MySQL" -Direction Inbound -Protocol TCP -LocalPort 3306 -Action Allow
```

## 验证安装

### 1. 检查MySQL版本

```bash
mysql --version
```

预期输出: `mysql  Ver 8.0.x for ...`

### 2. 检查MySQL服务状态

```bash
# Linux
sudo systemctl status mysql

# Windows
sc query MySQL80

# macOS
brew services list | grep mysql
```

### 3. 测试连接

```bash
mysql -h localhost -u root -p
```

成功连接后执行:
```sql
SELECT VERSION();
SHOW DATABASES;
```

### 4. 测试应用用户连接

```bash
mysql -h localhost -u pipeline_app_user -p pipeline_calc
```

## 常见问题

### 问题1: 无法连接到MySQL

**解决方案:**
1. 检查MySQL服务是否运行
2. 检查防火墙设置
3. 验证用户名和密码
4. 检查bind-address配置

### 问题2: Access denied for user

**解决方案:**
```sql
-- 重置用户权限
GRANT ALL PRIVILEGES ON pipeline_calc.* TO 'pipeline_app_user'@'%';
FLUSH PRIVILEGES;
```

### 问题3: Can't connect to MySQL server on 'localhost'

**解决方案:**
1. 确认MySQL服务正在运行
2. 检查端口3306是否被占用
3. 尝试使用127.0.0.1代替localhost

### 问题4: 密码策略太严格

**解决方案:**
```sql
-- 查看当前密码策略
SHOW VARIABLES LIKE 'validate_password%';

-- 临时降低密码策略（仅开发环境）
SET GLOBAL validate_password.policy = LOW;
SET GLOBAL validate_password.length = 6;
```

## 性能优化建议

### 1. 调整缓冲池大小

```ini
[mysqld]
innodb_buffer_pool_size = 1G  # 设置为系统内存的50-70%
```

### 2. 启用查询缓存

```ini
[mysqld]
query_cache_type = 1
query_cache_size = 64M
```

### 3. 优化连接数

```ini
[mysqld]
max_connections = 200
```

## 安全建议

1. **使用强密码**
   - 至少12位字符
   - 包含大小写字母、数字和特殊字符

2. **限制远程访问**
   ```sql
   CREATE USER 'pipeline_app_user'@'192.168.1.%' IDENTIFIED BY 'password';
   ```

3. **定期更新MySQL**
   ```bash
   # Ubuntu
   sudo apt update && sudo apt upgrade mysql-server
   
   # CentOS
   sudo yum update mysql-community-server
   ```

4. **启用SSL连接**
   ```ini
   [mysqld]
   require_secure_transport = ON
   ```

5. **定期备份**
   - 使用本项目提供的备份脚本
   - 设置自动备份计划任务

## 下一步

安装完成后，请参考以下文档继续配置:

1. [快速开始指南](QUICK_START.md) - 5分钟快速设置
2. [数据库配置指南](README.md) - 详细配置说明
3. [表结构文档](SCHEMA_DOCUMENTATION.md) - 数据库设计详情

## 参考资源

- MySQL官方文档: https://dev.mysql.com/doc/
- MySQL下载: https://dev.mysql.com/downloads/
- MySQL社区: https://forums.mysql.com/
