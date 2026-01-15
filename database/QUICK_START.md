# 数据库快速开始指南

## 5分钟快速设置

### 1. 准备环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置文件
# Windows: notepad .env
# Linux/Mac: nano .env
```

### 2. 配置必需参数

在 `.env` 文件中设置：

```bash
DB_HOST=localhost
DB_PORT=3306
DB_NAME=pipeline_calc
DB_USERNAME=pipeline_app_user
DB_PASSWORD=your_secure_password_123
DB_ROOT_PASSWORD=your_root_password_456
JWT_SECRET=your_random_jwt_secret_key_here
```

### 3. 运行设置脚本

**Windows:**
```cmd
cd database
setup_database.bat
```

**Linux/Mac:**
```bash
cd database
chmod +x setup_database.sh
./setup_database.sh
```

### 4. 验证安装

```bash
mysql -h localhost -u pipeline_app_user -p pipeline_calc
```

输入密码后，执行：
```sql
SHOW TABLES;
```

应该看到4个表：
- Users
- CalculationRecords  
- ParameterSets
- SyncLogs

## 完成！

数据库现在已准备就绪，可以开始开发后端API和Flutter应用程序。

## 故障排除

**连接失败？**
- 检查MySQL服务是否运行
- 验证用户名和密码
- 确认防火墙设置

**权限错误？**
- 确认root密码正确
- 检查用户创建是否成功

更多详细信息请参考 `README.md`。