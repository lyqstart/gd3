#!/bin/bash

# 油气管道开孔封堵计算系统 - 迁移回滚脚本
# 版本: 1.0.0
# 用途: 回滚数据库迁移到指定版本

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
    echo "用法: $0 <target_version>"
    echo ""
    echo "示例:"
    echo "  $0 1.0.0"
    echo ""
    echo "当前数据库版本历史:"
    mysql -h "$DB_HOST" -P "$DB_PORT" -u root -p"$DB_ROOT_PASSWORD" "$DB_NAME" \
        -e "SELECT Version, Description, AppliedAt FROM SchemaVersions ORDER BY AppliedAt DESC LIMIT 10;" 2>/dev/null || echo "  (无法查询版本信息)"
    exit 1
fi

TARGET_VERSION="$1"

# ============================================
# 获取当前版本
# ============================================

CURRENT_VERSION=$(mysql \
    -h "$DB_HOST" \
    -P "$DB_PORT" \
    -u root \
    -p"$DB_ROOT_PASSWORD" \
    -N \
    "$DB_NAME" \
    -e "SELECT Version FROM SchemaVersions ORDER BY AppliedAt DESC LIMIT 1;")

echo "========================================="
echo "数据库迁移回滚"
echo "========================================="
echo "当前版本: $CURRENT_VERSION"
echo "目标版本: $TARGET_VERSION"
echo ""

# 检查版本
if [ "$CURRENT_VERSION" == "$TARGET_VERSION" ]; then
    echo "当前版本已经是目标版本，无需回滚"
    exit 0
fi

# ============================================
# 确认回滚操作
# ============================================

echo "⚠️  警告: 回滚操作可能导致数据丢失！"
echo ""
echo "建议操作:"
echo "  1. 在回滚前创建数据库备份"
echo "  2. 确认回滚脚本存在且正确"
echo "  3. 在测试环境先验证回滚过程"
echo ""
read -p "确认要回滚数据库吗？(yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "操作已取消"
    exit 0
fi

# ============================================
# 创建回滚前备份
# ============================================

echo ""
echo "正在创建回滚前备份..."

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/pre_rollback_${TIMESTAMP}.sql"

mkdir -p "$BACKUP_DIR"

mysqldump \
    -h "$DB_HOST" \
    -P "$DB_PORT" \
    -u root \
    -p"$DB_ROOT_PASSWORD" \
    --single-transaction \
    --databases "$DB_NAME" \
    > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✓ 回滚前备份创建成功: $BACKUP_FILE"
    gzip "$BACKUP_FILE"
    echo "✓ 备份文件已压缩: ${BACKUP_FILE}.gz"
else
    echo "✗ 回滚前备份创建失败"
    exit 1
fi

# ============================================
# 执行回滚
# ============================================

echo ""
echo "正在执行回滚..."

# 注意: 实际的回滚逻辑需要根据具体的迁移脚本实现
# 这里提供一个通用的框架

# 示例: 如果有对应的回滚脚本
ROLLBACK_SCRIPT="migrations/rollback_to_${TARGET_VERSION}.sql"

if [ -f "$ROLLBACK_SCRIPT" ]; then
    echo "找到回滚脚本: $ROLLBACK_SCRIPT"
    
    mysql \
        -h "$DB_HOST" \
        -P "$DB_PORT" \
        -u root \
        -p"$DB_ROOT_PASSWORD" \
        "$DB_NAME" \
        < "$ROLLBACK_SCRIPT"
    
    if [ $? -eq 0 ]; then
        echo "✓ 回滚脚本执行成功"
    else
        echo "✗ 回滚脚本执行失败"
        echo ""
        echo "可以使用以下命令恢复备份:"
        echo "  gunzip ${BACKUP_FILE}.gz"
        echo "  mysql -h $DB_HOST -P $DB_PORT -u root -p < $BACKUP_FILE"
        exit 1
    fi
else
    echo "⚠️  警告: 未找到回滚脚本: $ROLLBACK_SCRIPT"
    echo ""
    echo "回滚选项:"
    echo "  1. 从备份恢复到目标版本"
    echo "  2. 手动执行回滚SQL语句"
    echo "  3. 取消回滚操作"
    echo ""
    read -p "请选择 (1/2/3): " OPTION
    
    case $OPTION in
        1)
            echo "请手动选择要恢复的备份文件"
            ls -lh backups/*.sql* 2>/dev/null || echo "  (无备份文件)"
            ;;
        2)
            echo "请手动执行回滚SQL语句"
            ;;
        3)
            echo "操作已取消"
            exit 0
            ;;
        *)
            echo "无效选项"
            exit 1
            ;;
    esac
fi

# ============================================
# 验证回滚
# ============================================

echo ""
echo "正在验证回滚..."

NEW_VERSION=$(mysql \
    -h "$DB_HOST" \
    -P "$DB_PORT" \
    -u root \
    -p"$DB_ROOT_PASSWORD" \
    -N \
    "$DB_NAME" \
    -e "SELECT Version FROM SchemaVersions ORDER BY AppliedAt DESC LIMIT 1;")

if [ "$NEW_VERSION" == "$TARGET_VERSION" ]; then
    echo "✓ 回滚验证成功"
else
    echo "✗ 回滚验证失败（当前版本: $NEW_VERSION，期望: $TARGET_VERSION）"
    exit 1
fi

# ============================================
# 回滚完成
# ============================================

echo ""
echo "========================================="
echo "数据库回滚完成"
echo "========================================="
echo "原版本: $CURRENT_VERSION"
echo "新版本: $NEW_VERSION"
echo "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "回滚前备份: ${BACKUP_FILE}.gz"
echo ""
echo "注意事项:"
echo "  1. 请验证应用程序功能是否正常"
echo "  2. 请检查数据完整性"
echo "  3. 建议重启应用程序服务"
echo "  4. 保留回滚前备份以备不时之需"
