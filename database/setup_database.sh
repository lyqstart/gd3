#!/bin/bash

# 油气管道开孔封堵计算系统 - Linux/Mac 数据库设置脚本
# 版本: 1.0.0

set -e  # 遇到错误立即退出

echo "========================================"
echo "油气管道开孔封堵计算系统数据库设置"
echo "========================================"
echo

# 检查是否存在 .env 文件
if [ ! -f "../.env" ]; then
    echo "错误: 未找到 .env 配置文件"
    echo "请先复制 .env.example 为 .env 并配置相应的环境变量"
    echo
    echo "执行以下命令:"
    echo "  cp .env.example .env"
    echo "  然后编辑 .env 文件填入实际配置"
    exit 1
fi

echo "正在读取环境变量配置..."

# 读取 .env 文件
source ../.env

# 设置默认值
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-pipeline_calc}

echo "配置信息:"
echo "  数据库主机: $DB_HOST"
echo "  数据库端口: $DB_PORT"
echo "  数据库名称: $DB_NAME"
echo "  应用用户名: $DB_USERNAME"
echo

# 检查必需的环境变量
if [ -z "$DB_USERNAME" ]; then
    echo "错误: DB_USERNAME 未配置"
    echo "请在 .env 文件中设置 DB_USERNAME"
    exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
    echo "错误: DB_PASSWORD 未配置"
    echo "请在 .env 文件中设置 DB_PASSWORD"
    exit 1
fi

if [ -z "$DB_ROOT_PASSWORD" ]; then
    echo "错误: DB_ROOT_PASSWORD 未配置"
    echo "请在 .env 文件中设置 DB_ROOT_PASSWORD"
    exit 1
fi

# 检查 MySQL 客户端是否可用
if ! command -v mysql &> /dev/null; then
    echo "错误: 未找到 mysql 客户端"
    echo "请安装 MySQL 客户端工具"
    exit 1
fi

echo "步骤 1: 创建数据库和基本配置..."
if ! mysql -h "$DB_HOST" -P "$DB_PORT" -u root -p"$DB_ROOT_PASSWORD" < create_database.sql; then
    echo "错误: 数据库创建失败"
    echo "请检查 MySQL 服务是否运行，root 密码是否正确"
    exit 1
fi

echo "步骤 2: 创建应用用户..."
if ! mysql -h "$DB_HOST" -P "$DB_PORT" -u root -p"$DB_ROOT_PASSWORD" -e "CREATE USER IF NOT EXISTS '$DB_USERNAME'@'%' IDENTIFIED BY '$DB_PASSWORD';"; then
    echo "错误: 用户创建失败"
    exit 1
fi

echo "步骤 3: 配置用户权限..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u root -p"$DB_ROOT_PASSWORD" -e "GRANT SELECT, INSERT, UPDATE, DELETE ON $DB_NAME.* TO '$DB_USERNAME'@'%';"
mysql -h "$DB_HOST" -P "$DB_PORT" -u root -p"$DB_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

if [ $? -ne 0 ]; then
    echo "错误: 权限配置失败"
    exit 1
fi

echo "步骤 4: 创建数据表结构..."
if ! mysql -h "$DB_HOST" -P "$DB_PORT" -u root -p"$DB_ROOT_PASSWORD" "$DB_NAME" < create_tables.sql; then
    echo "错误: 表结构创建失败"
    exit 1
fi

echo "步骤 5: 验证数据库配置..."
if ! mysql -h "$DB_HOST" -P "$DB_PORT" -u root -p"$DB_ROOT_PASSWORD" "$DB_NAME" < verify_database.sql; then
    echo "警告: 数据库验证出现问题，但设置可能已完成"
fi

echo
echo "========================================"
echo "数据库设置完成！"
echo "========================================"
echo
echo "配置摘要:"
echo "  数据库名称: $DB_NAME"
echo "  应用用户: $DB_USERNAME"
echo "  主机地址: $DB_HOST:$DB_PORT"
echo
echo "测试连接:"
echo "  mysql -h $DB_HOST -P $DB_PORT -u $DB_USERNAME -p $DB_NAME"
echo
echo "注意事项:"
echo "  1. 请妥善保管 .env 文件中的密码信息"
echo "  2. 不要将 .env 文件提交到版本控制系统"
echo "  3. 生产环境建议使用更强的密码"
echo "  4. 定期备份数据库数据"
echo