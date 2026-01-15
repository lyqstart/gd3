#!/bin/bash

# 油气管道开孔封堵计算系统 - 数据库恢复脚本
# 版本: 1.0.0
# 用途: 从备份文件恢复MySQL数据库

set -e

# ============================================
# 配置参数（从环境变量读取）
# ============================================

# 读取 .env 文件
if [ -f "../.env" ]; then
    source ../.env
else
    echo "错误: 未找到 .env 配置文件"
    exit 1
fi

# 设置默认值
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-pipeline_calc}
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD}

# 检查参数
if [ -z "$1" ]; then
    echo "用法: $0 <backup_file>"
    echo ""
    echo "示例:"
    echo "  $0 backups/pipeline_calc_20240101_120000.sql"
    echo "  $0 backups/pipeline_calc_20240101_120000.sql.gz"
    echo ""
    echo "可用的备份文件:"
    ls -lh backups/pipeline_calc_*.sql* 2>/dev/null || echo "  (无备份文件)"
    exit 1
fi

BACKUP_FILE="$1"

# 检查备份文件是否存在
if [ ! -f "$BACKUP_FILE" ]; then
    echo "错误: 备份文件不存在: $BACKUP_FILE"
    exit 1
fi

# ============================================
# 确认恢复操作
# ============================================

echo "========================================="
echo "数据库恢复警告"
echo "========================================="
echo "数据库: $DB_NAME"
echo "主机: $DB_HOST:$DB_PORT"
echo "备份文件: $BACKUP_FILE"
echo ""
echo "⚠️  警告: 此操作将覆盖现有数据库！"
echo ""
read -p "确认要恢复数据库吗？(yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "操作已取消"
    exit 0
fi

# ============================================
# 解压备份文件（如果需要）
# ============================================

RESTORE_FILE="$BACKUP_FILE"

if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo ""
    echo "正在解压备份文件..."
    
    RESTORE_FILE="${BACKUP_FILE%.gz}"
    gunzip -c "$BACKUP_FILE" > "$RESTORE_FILE"
    
    if [ $? -eq 0 ]; then
        echo "✓ 备份文件解压成功"
    else
        echo "✗ 备份文件解压失败"
        exit 1
    fi
fi

# ============================================
# 执行恢复
# ============================================

echo ""
echo "正在恢复数据库..."

mysql \
    -h "$DB_HOST" \
    -P "$DB_PORT" \
    -u root \
    -p"$DB_ROOT_PASSWORD" \
    < "$RESTORE_FILE"

if [ $? -eq 0 ]; then
    echo "✓ 数据库恢复成功"
else
    echo "✗ 数据库恢复失败"
    exit 1
fi

# ============================================
# 清理临时文件
# ============================================

if [[ "$BACKUP_FILE" == *.gz ]] && [ -f "$RESTORE_FILE" ]; then
    echo ""
    echo "正在清理临时文件..."
    rm -f "$RESTORE_FILE"
    echo "✓ 临时文件清理完成"
fi

# ============================================
# 验证恢复
# ============================================

echo ""
echo "正在验证数据库..."

TABLE_COUNT=$(mysql \
    -h "$DB_HOST" \
    -P "$DB_PORT" \
    -u root \
    -p"$DB_ROOT_PASSWORD" \
    -N -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = '$DB_NAME' AND TABLE_TYPE = 'BASE TABLE';")

if [ "$TABLE_COUNT" -ge 4 ]; then
    echo "✓ 数据库验证成功（表数量: $TABLE_COUNT）"
else
    echo "✗ 数据库验证失败（表数量: $TABLE_COUNT，期望: >= 4）"
    exit 1
fi

# ============================================
# 恢复完成
# ============================================

echo ""
echo "========================================="
echo "数据库恢复完成"
echo "========================================="
echo "数据库: $DB_NAME"
echo "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "注意事项:"
echo "  1. 请验证应用程序连接是否正常"
echo "  2. 请检查数据完整性"
echo "  3. 建议重启应用程序服务"
