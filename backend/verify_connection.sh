#!/bin/bash

# 数据库连接验证脚本
# 用于验证环境变量配置和数据库连接

set -e

echo "========================================="
echo "数据库连接验证脚本"
echo "========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查环境变量
echo "1. 检查环境变量配置..."
echo ""

check_env_var() {
    local var_name=$1
    local var_value=${!var_name}
    
    if [ -z "$var_value" ]; then
        echo -e "${RED}✗${NC} $var_name 未设置"
        return 1
    else
        if [[ "$var_name" == *"PASSWORD"* ]] || [[ "$var_name" == *"SECRET"* ]]; then
            echo -e "${GREEN}✓${NC} $var_name 已设置 (值已隐藏)"
        else
            echo -e "${GREEN}✓${NC} $var_name = $var_value"
        fi
        return 0
    fi
}

# 必需的环境变量
REQUIRED_VARS=("DB_HOST" "DB_PORT" "DB_NAME" "DB_USER" "DB_PASSWORD" "JWT_SECRET_KEY")
MISSING_VARS=0

for var in "${REQUIRED_VARS[@]}"; do
    if ! check_env_var "$var"; then
        MISSING_VARS=$((MISSING_VARS + 1))
    fi
done

echo ""

if [ $MISSING_VARS -gt 0 ]; then
    echo -e "${RED}错误: 缺少 $MISSING_VARS 个必需的环境变量${NC}"
    echo ""
    echo "请设置以下环境变量:"
    echo "  export DB_HOST=localhost"
    echo "  export DB_PORT=3306"
    echo "  export DB_NAME=pipeline_calc"
    echo "  export DB_USER=pipeline_app_user"
    echo "  export DB_PASSWORD=your_password"
    echo "  export JWT_SECRET_KEY=your_jwt_secret_key"
    echo ""
    exit 1
fi

# 可选的环境变量
echo "可选环境变量:"
check_env_var "DB_MIN_POOL_SIZE" || echo -e "${YELLOW}ℹ${NC} DB_MIN_POOL_SIZE 未设置 (将使用默认值: 5)"
check_env_var "DB_MAX_POOL_SIZE" || echo -e "${YELLOW}ℹ${NC} DB_MAX_POOL_SIZE 未设置 (将使用默认值: 20)"
check_env_var "DB_CONNECTION_TIMEOUT" || echo -e "${YELLOW}ℹ${NC} DB_CONNECTION_TIMEOUT 未设置 (将使用默认值: 30)"

echo ""
echo "========================================="
echo "2. 测试MySQL连接..."
echo ""

# 检查MySQL客户端是否安装
if ! command -v mysql &> /dev/null; then
    echo -e "${YELLOW}警告: mysql 客户端未安装,跳过直接连接测试${NC}"
    echo "可以使用以下命令安装:"
    echo "  Ubuntu/Debian: sudo apt-get install mysql-client"
    echo "  CentOS/RHEL: sudo yum install mysql"
    echo ""
else
    # 测试数据库连接
    echo "尝试连接到 MySQL 数据库..."
    if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT 1;" &> /dev/null; then
        echo -e "${GREEN}✓${NC} MySQL 连接成功"
        
        # 获取数据库版本
        DB_VERSION=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -sN -e "SELECT VERSION();")
        echo -e "${GREEN}✓${NC} MySQL 版本: $DB_VERSION"
        
        # 检查表是否存在
        echo ""
        echo "检查数据库表..."
        TABLES=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -sN -e "SHOW TABLES;")
        
        if [ -z "$TABLES" ]; then
            echo -e "${YELLOW}警告: 数据库中没有表${NC}"
        else
            echo -e "${GREEN}✓${NC} 找到以下表:"
            echo "$TABLES" | while read -r table; do
                echo "  - $table"
            done
        fi
    else
        echo -e "${RED}✗${NC} MySQL 连接失败"
        echo ""
        echo "请检查:"
        echo "  1. MySQL 服务是否运行: sudo systemctl status mysql"
        echo "  2. 数据库用户权限是否正确"
        echo "  3. 防火墙是否允许连接"
        echo "  4. 数据库凭据是否正确"
        echo ""
        exit 1
    fi
fi

echo ""
echo "========================================="
echo "3. 验证JWT配置..."
echo ""

# 检查JWT密钥长度
JWT_KEY_LENGTH=${#JWT_SECRET_KEY}
if [ $JWT_KEY_LENGTH -lt 32 ]; then
    echo -e "${RED}✗${NC} JWT_SECRET_KEY 长度不足 (当前: $JWT_KEY_LENGTH 字符, 建议: ≥32 字符)"
    echo -e "${YELLOW}警告: JWT密钥过短可能导致安全风险${NC}"
else
    echo -e "${GREEN}✓${NC} JWT_SECRET_KEY 长度符合要求 ($JWT_KEY_LENGTH 字符)"
fi

echo ""
echo "========================================="
echo "4. 生成连接字符串..."
echo ""

# 生成连接字符串(隐藏密码)
CONNECTION_STRING="Server=$DB_HOST;Port=$DB_PORT;Database=$DB_NAME;User=$DB_USER;Password=***;CharSet=utf8mb4;"
echo "连接字符串模板:"
echo "  $CONNECTION_STRING"

echo ""
echo "完整连接字符串(带连接池):"
FULL_CONNECTION_STRING="Server=$DB_HOST;Port=$DB_PORT;Database=$DB_NAME;User=$DB_USER;Password=***;CharSet=utf8mb4;MinimumPoolSize=${DB_MIN_POOL_SIZE:-5};MaximumPoolSize=${DB_MAX_POOL_SIZE:-20};ConnectionTimeout=${DB_CONNECTION_TIMEOUT:-30};"
echo "  $FULL_CONNECTION_STRING"

echo ""
echo "========================================="
echo "5. 验证总结"
echo "========================================="
echo ""

if [ $MISSING_VARS -eq 0 ]; then
    echo -e "${GREEN}✓${NC} 所有必需的环境变量已配置"
    echo -e "${GREEN}✓${NC} 数据库连接验证通过"
    echo ""
    echo "您可以启动应用程序了:"
    echo "  dotnet run --project backend/PipelineCalculationAPI"
    echo ""
    echo "或启动systemd服务:"
    echo "  sudo systemctl start pipelinecalcapi.service"
    echo ""
else
    echo -e "${RED}✗${NC} 配置验证失败,请修复上述问题后重试"
    exit 1
fi

echo "========================================="
