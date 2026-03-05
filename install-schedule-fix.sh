#!/bin/bash
# Qwen Code Schedule Tool Fix - Quick Install Script
# 用于快速修复 Qwen Code 的 schedule 工具错误
#
# 使用方法：
#   ./install-schedule-fix.sh [qwen-code 安装目录]

set -e

TARGET_DIR="${1:-./packages/core}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔧 Qwen Code Schedule Tool 快速修复安装脚本"
echo "=============================================="

# 检查目标目录
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ 错误：目标目录不存在：$TARGET_DIR"
    exit 1
fi

# 备份原文件
BACKUP_FILE="${TARGET_DIR}/src/tools/scheduleTool.ts.backup.$(date +%Y%m%d%H%M%S)"
if [ -f "${TARGET_DIR}/src/tools/scheduleTool.ts" ]; then
    echo "📦 备份原文件：$BACKUP_FILE"
    cp "${TARGET_DIR}/src/tools/scheduleTool.ts" "$BACKUP_FILE"
fi

# 复制修复文件
echo "📝 复制修复文件..."
cp "${SCRIPT_DIR}/packages/core/src/tools/scheduleTool.ts" "${TARGET_DIR}/src/tools/scheduleTool.ts"

# 检查并修复 config.ts 中的重复函数
CONFIG_FILE="${TARGET_DIR}/src/config/config.ts"
if [ -f "$CONFIG_FILE" ]; then
    echo "🔍 检查 config.ts 中的重复函数..."
    # 检查是否存在重复的 getSchedulerService
    if grep -q "getSchedulerService(): SchedulerService {" "$CONFIG_FILE"; then
        COUNT=$(grep -c "getSchedulerService(): SchedulerService {" "$CONFIG_FILE" || true)
        if [ "$COUNT" -gt 1 ]; then
            echo "⚠️  发现 $COUNT 个重复的 getSchedulerService() 函数，正在修复..."
            # 使用 sed 删除第二个重复函数（大约在第 1655 行）
            sed -i '1654,1657d' "$CONFIG_FILE"
            echo "✅ 已删除重复函数"
        else
            echo "✅ 未发现重复函数"
        fi
    fi
fi

# 重新构建
echo "🔨 重新构建项目..."
cd "${SCRIPT_DIR}"
npm run build --workspace=packages/core

echo ""
echo "✅ 修复安装完成！"
echo ""
echo "如果有备份文件，可以在需要时恢复："
echo "  $BACKUP_FILE"
echo ""
echo "运行以下命令测试："
echo "  npm start -- -p '列出所有定时任务'"
