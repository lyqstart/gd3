#!/bin/bash

# 油气管道开孔封堵计算系统 - 数据库备份脚本
# 版本: 1.0.0
# 用途: 自动备份MySQL数据库

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
DB_USERNAME=${DB_USERNAME:-pipeline_app_user}
DB_PASSWORD=${DB_PASSWORD}

# 备份目录
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/pipeline_calc_${TIMESTAMP}.sql"

# ============================================
# 创建备份目录
# ============================================

mkdir -p "$BACKUP_DIR"

echo "========================================="
echo "数据库备份开始"
echo "========================================="
echo "数据库: $DB_NAME"
echo "主机: $DB_HOST:$DB_PORT"
echo "备份文件: $BACKUP_FILE"
echo ""

# ============================================
# 执行备份
# ============================================

echo "正在备份数据库..."

mysqldump \
    -h "$DB_HOST" \
    -P "$DB_PORT" \
    -u "$DB_USERNAME" \
    -p"$DB_PASSWORD" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --add-drop-database \
    --databases "$DB_NAME" \
    > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✓ 数据库备份成功"
    
    # 压缩备份文件
    echo "正在压缩备份文件..."
    gzip "$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "✓ 备份文件压缩成功: ${BACKUP_FILE}.gz"
        
        # 显示文件大小
        FILESIZE=$(du -h "${BACKUP_FILE}.gz" | cut -f1)
        echo "备份文件大小: $FILESIZE"
    else
        echo "✗ 备份文件压缩失败"
    fi
else
    echo "✗ 数据库备份失败"
    exit 1
fi

# ============================================
# 清理旧备份（保留最近7天）
# ============================================

echo ""
echo "正在清理旧备份文件（保留最近7天）..."

find "$BACKUP_DIR" -name "pipeline_calc_*.sql.gz" -type f -mtime +7 -delete

if [ $? -eq 0 ]; then
    echo "✓ 旧备份文件清理完成"
else
    echo "✗ 旧备份文件清理失败"
fi

# ============================================
# 备份完成
# ============================================

echo ""
echo "========================================="
echo "数据库备份完成"
echo "========================================="
echo "备份文件: ${BACKUP_FILE}.gz"
echo "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "恢复命令:"
echo "  gunzip ${BACKUP_FILE}.gz"
echo "  mysql -h $DB_HOST -P $DB_PORT -u $DB_USERNAME -p < $BACKUP_FILE"
