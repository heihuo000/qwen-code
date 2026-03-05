#!/bin/bash
# Qwen Code 定时任务补丁 - 官方更新融合脚本
# 使用方法：./update-and-patch.sh

set -e

echo "╔══════════════════════════════════════════════════════╗"
echo "║   Qwen Code 定时任务补丁 - 官方更新融合工具         ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
QWEN_DIR="/data/data/com.termux/files/home/qwen-code-0.12.0"
PATCH_DIR="$QWEN_DIR/schedule-agent"
BACKUP_DIR="$QWEN_DIR/.patch-backup"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查是否在正确的目录
if [ ! -d "$QWEN_DIR" ]; then
    log_error "Qwen Code 目录不存在：$QWEN_DIR"
    exit 1
fi

cd "$QWEN_DIR"

# 步骤 1: 创建备份
log_info "步骤 1/6: 创建备份..."
mkdir -p "$BACKUP_DIR/$(date +%Y%m%d_%H%M%S)"
cp -r packages/core/src/tools/scheduleTool.ts "$BACKUP_DIR/$(date +%Y%m%d_%H%M%S)/" 2>/dev/null || true
cp -r packages/core/src/services/schedulerService.ts "$BACKUP_DIR/$(date +%Y%m%d_%H%M%S)/" 2>/dev/null || true
log_info "备份完成"

# 步骤 2: 拉取官方更新
log_info "步骤 2/6: 拉取官方更新..."
git fetch origin master

# 检查是否有更新
if git diff HEAD origin/master --quiet; then
    log_warn "没有新的更新，已经是最新版本"
    # 检查补丁是否已应用
    if grep -q "SchedulerService" packages/core/src/config/config.ts 2>/dev/null; then
        log_info "定时任务补丁已应用"
        exit 0
    else
        log_info "继续应用补丁..."
    fi
fi

# 步骤 3: 暂存本地修改（如果有）
log_info "步骤 3/6: 暂存本地修改..."
git stash push -m "pre-patch-local-changes" 2>/dev/null || true

# 步骤 4: 合并官方更新
log_info "步骤 4/6: 合并官方更新..."
git merge origin/master --no-commit || true

# 步骤 5: 重新应用补丁
log_info "步骤 5/6: 重新应用定时任务补丁..."

# 检查核心文件是否存在
SCHEDULE_TOOL="packages/core/src/tools/scheduleTool.ts"
SCHEDULER_SERVICE="packages/core/src/services/schedulerService.ts"
CONFIG_FILE="packages/core/src/config/config.ts"
TOOL_NAMES="packages/core/src/tools/tool-names.ts"

# 如果补丁文件被覆盖，重新创建
if [ ! -f "$SCHEDULE_TOOL" ]; then
    log_warn "scheduleTool.ts 被官方更新覆盖，正在恢复..."
    git checkout stash -- "$SCHEDULE_TOOL" 2>/dev/null || true
fi

if [ ! -f "$SCHEDULER_SERVICE" ]; then
    log_warn "schedulerService.ts 被官方更新覆盖，正在恢复..."
    git checkout stash -- "$SCHEDULER_SERVICE" 2>/dev/null || true
fi

# 检查并修复 config.ts 中的导入和注册
if ! grep -q "SchedulerService" "$CONFIG_FILE" 2>/dev/null; then
    log_warn "config.ts 中缺少 SchedulerService 导入，正在添加..."

    # 添加工具导入（在 WriteFileTool 之后）
    if grep -q "WriteFileTool" "$CONFIG_FILE"; then
        sed -i '/import { WriteFileTool }/a import { SchedulerService } from '\''../services/schedulerService.js'\'';
import { ScheduleTool } from '\''../tools/scheduleTool.js'\'';
' "$CONFIG_FILE"
    fi

    # 添加服务初始化
    if grep -q "chatRecordingService = new" "$CONFIG_FILE"; then
        sed -i '/this.chatRecordingService = new/a\        this.schedulerService = new SchedulerService();' "$CONFIG_FILE"
    fi

    # 添加工具注册
    if grep -q "registerCoreTool(WriteFileTool" "$CONFIG_FILE"; then
        sed -i '/registerCoreTool(WriteFileTool/a\        registerCoreTool(ScheduleTool, this);' "$CONFIG_FILE"
    fi
fi

# 检查 tool-names.ts
if ! grep -q "SCHEDULE:" "$TOOL_NAMES" 2>/dev/null; then
    log_warn "tool-names.ts 中缺少 SCHEDULE 定义，正在添加..."

    # 添加到 ToolNames
    if grep -q "SHELL:" "$TOOL_NAMES"; then
        sed -i '/SHELL: .*run_shell_command/a\  SCHEDULE: '\''schedule'\'',' "$TOOL_NAMES"
    fi

    # 添加到 ToolDisplayNames
    if grep -q "SHELL: .*Shell" "$TOOL_NAMES"; then
        sed -i '/SHELL: .*Shell/a\  SCHEDULE: '\''Schedule'\'',' "$TOOL_NAMES"
    fi
fi

# 恢复本地修改
log_info "步骤 6/6: 恢复本地修改..."
git stash pop 2>/dev/null || true

# 提交补丁
git add -A
git commit -m "chore: 重新应用定时任务补丁 (融合官方更新)" || true

# 验证
echo ""
log_info "=== 验证补丁状态 ==="
if grep -q "SchedulerService" "$CONFIG_FILE" 2>/dev/null && \
   grep -q "ScheduleTool" "$CONFIG_FILE" 2>/dev/null && \
   grep -q "SCHEDULE:" "$TOOL_NAMES" 2>/dev/null; then
    log_info "✅ 定时任务补丁已成功应用！"
    echo ""
    echo "下一步："
    echo "  1. 测试功能：git push -f origin master"
    echo "  2. 或者回滚：git reset --hard HEAD~1"
else
    log_error "❌ 补丁应用不完整，请手动检查"
    echo ""
    echo "需要手动添加的文件："
    echo "  - packages/core/src/services/schedulerService.ts"
    echo "  - packages/core/src/tools/scheduleTool.ts"
    echo ""
    echo "需要修改的文件："
    echo "  - packages/core/src/config/config.ts"
    echo "  - packages/core/src/tools/tool-names.ts"
fi

echo ""
log_info "完成！"
