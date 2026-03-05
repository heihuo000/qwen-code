#!/bin/bash
# Qwen Code Schedule Tool 修复 - npm 安装版本
#
# 用于直接修改已安装的 npm 包，无需重新编译
# 适用于无法访问源码的 npm 安装用户

set -e

echo "🔧 Qwen Code Schedule Tool 修复 - npm 版本"
echo "=========================================="

# 找到 npm 包的安装位置
NPM_ROOT=$(npm root -g 2>/dev/null || echo "./node_modules")
QWEN_CORE="${NPM_ROOT}/@qwen-code/qwen-code-core"

if [ ! -d "$QWEN_CORE" ]; then
    # 尝试本地 node_modules
    QWEN_CORE="./node_modules/@qwen-code/qwen-code-core"
fi

if [ ! -d "$QWEN_CORE" ]; then
    echo "❌ 错误：找不到 @qwen-code/qwen-code-core 包"
    echo "请确认已安装 Qwen Code: npm install -g @qwen-code/qwen-code"
    exit 1
fi

echo "📍 找到包目录：$QWEN_CORE"

TOOLS_DIR="${QWEN_CORE}/dist/src/tools"
if [ ! -d "$TOOLS_DIR" ]; then
    echo "❌ 错误：找不到 tools 目录：$TOOLS_DIR"
    exit 1
fi

# 备份原文件
BACKUP="${TOOLS_DIR}/scheduleTool.js.backup.$(date +%Y%m%d%H%M%S)"
echo "📦 备份原文件：$BACKUP"
cp "${TOOLS_DIR}/scheduleTool.js" "$BACKUP"

# 读取并写入修复后的 JavaScript 代码
# 这是编译后可以直接运行的版本
cat > "${TOOLS_DIR}/scheduleTool.js" << 'ENDOFFILE'
/**
 * @license
 * Copyright 2025 Qwen
 * SPDX-License-Identifier: Apache-2.0
 */

import { BaseDeclarativeTool, BaseToolInvocation, Kind } from './tools.js';
import { ToolNames, ToolDisplayNames } from './tool-names.js';

export class ScheduleToolInvocation extends BaseToolInvocation {
    constructor(config, params) {
        super(params);
        this.config = config;
        this.params = params;
    }
    getDescription() {
        return `Schedule action: ${this.params.action}`;
    }
    async execute(_signal) {
        const { action } = this.params;
        const scheduler = this.config.getSchedulerService();
        if (!scheduler) {
            return {
                llmContent: 'Scheduler service not available',
                returnDisplay: '❌ Scheduler service not available',
            };
        }
        let resultText = '';
        switch (action) {
            case 'add':
                resultText = this.handleAdd(scheduler);
                break;
            case 'remove':
                resultText = this.handleRemove(scheduler);
                break;
            case 'list':
                resultText = this.handleList(scheduler);
                break;
            case 'enable':
                resultText = this.handleEnable(scheduler);
                break;
            case 'disable':
                resultText = this.handleDisable(scheduler);
                break;
            case 'update':
                resultText = this.handleUpdate(scheduler);
                break;
            default:
                resultText = `❌ Unknown action: ${action}`;
        }
        return {
            llmContent: resultText,
            returnDisplay: resultText,
        };
    }
    handleAdd(scheduler) {
        if (!this.params.name) {
            return '❌ Task name is required for add action.';
        }
        if (!this.params.cron_expression) {
            return '❌ Cron expression is required for add action.';
        }
        if (!this.params.command && !this.params.prompt) {
            return '❌ Either command or prompt is required for add action.';
        }
        const task = scheduler.addTask({
            name: this.params.name,
            description: this.params.description || '',
            cronExpression: this.params.cron_expression,
            command: this.params.command,
            prompt: this.params.prompt,
            taskType: this.params.task_type || (this.params.command ? 'shell' : 'qwen'),
            maxRuns: this.params.max_runs,
        });
        return `✅ Scheduled task added successfully!\n\n` +
            `**Task ID**: \`${task.id}\`\n` +
            `**Name**: ${task.name}\n` +
            `**Description**: ${task.description || 'No description'}\n` +
            `**Schedule**: ${task.cronExpression}\n` +
            `**Command**: \`${task.command || 'N/A'}\`\n` +
            `**Prompt**: ${task.prompt || 'N/A'}\n` +
            `**Type**: ${task.taskType}\n` +
            `**Max Runs**: ${task.maxRuns || 'Unlimited'}\n` +
            `**Status**: Enabled`;
    }
    handleRemove(scheduler) {
        const task = scheduler.getTask(this.params.task_id);
        if (!task) {
            return `❌ Task with ID "${this.params.task_id}" not found.`;
        }
        scheduler.removeTask(this.params.task_id);
        return `✅ Scheduled task removed successfully!\n\n` +
            `**Task ID**: ${this.params.task_id}\n` +
            `**Name**: ${task.name}`;
    }
    handleList(scheduler) {
        const tasks = scheduler.getAllTasks();
        if (tasks.length === 0) {
            return '📋 No scheduled tasks found.';
        }
        let output = `📋 Scheduled Tasks (${tasks.length}):\n\n`;
        tasks.forEach((task, index) => {
            output += `${index + 1}. **${task.name}**\n`;
            output += `   - ID: \`${task.id}\`\n`;
            output += `   - Description: ${task.description || 'No description'}\n`;
            output += `   - Schedule: ${task.cronExpression}\n`;
            output += `   - Type: ${task.taskType}\n`;
            output += `   - Status: ${task.enabled ? '✅ Enabled' : '❌ Disabled'}\n`;
            output += `   - Run Count: ${task.runCount}\n`;
            if (task.lastRun) {
                output += `   - Last Run: ${new Date(task.lastRun).toLocaleString()}\n`;
            }
            if (task.nextRun) {
                output += `   - Next Run: ${new Date(task.nextRun).toLocaleString()}\n`;
            }
            output += '\n';
        });
        return output;
    }
    handleEnable(scheduler) {
        const success = scheduler.enableTask(this.params.task_id);
        if (!success) {
            return `❌ Task with ID "${this.params.task_id}" not found.`;
        }
        return `✅ Scheduled task enabled successfully!\n\n` +
            `**Task ID**: ${this.params.task_id}`;
    }
    handleDisable(scheduler) {
        const success = scheduler.disableTask(this.params.task_id);
        if (!success) {
            return `❌ Task with ID "${this.params.task_id}" not found.`;
        }
        return `✅ Scheduled task disabled successfully!\n\n` +
            `**Task ID**: ${this.params.task_id}`;
    }
    handleUpdate(scheduler) {
        const task = scheduler.getTask(this.params.task_id);
        if (!task) {
            return `❌ Task with ID "${this.params.task_id}" not found.`;
        }
        const updatedTask = scheduler.updateTask(this.params.task_id, {
            name: this.params.name,
            description: this.params.description,
            cronExpression: this.params.cron_expression,
            command: this.params.command,
            prompt: this.params.prompt,
            taskType: this.params.task_type,
        });
        if (!updatedTask) {
            return `❌ Failed to update task.`;
        }
        return `✅ Scheduled task updated successfully!\n\n` +
            `**Task ID**: ${this.params.task_id}\n` +
            `**Name**: ${updatedTask.name}\n` +
            `**Schedule**: ${updatedTask.cronExpression}\n` +
            `**Status**: ${updatedTask.enabled ? '✅ Enabled' : '❌ Disabled'}`;
    }
}
/**
 * Schedule tool for managing timed/scheduled tasks
 */
export class ScheduleTool extends BaseDeclarativeTool {
    static Name = ToolNames.SCHEDULE;
    constructor(config) {
        const schema = {
            type: 'object',
            properties: {
                action: {
                    type: 'string',
                    enum: ['add', 'remove', 'list', 'enable', 'disable', 'update'],
                },
                task_id: {
                    type: 'string',
                },
                name: {
                    type: 'string',
                },
                description: {
                    type: 'string',
                },
                cron_expression: {
                    type: 'string',
                },
                command: {
                    type: 'string',
                },
                prompt: {
                    type: 'string',
                },
                task_type: {
                    type: 'string',
                    enum: ['shell', 'qwen'],
                },
                max_runs: {
                    type: 'number',
                },
            },
            required: ['action'],
        };
        super(ScheduleTool.Name, ToolDisplayNames.SCHEDULE, `Manage timed/scheduled tasks that can execute shell commands or trigger Qwen AI responses.

Available actions:
- add: Create a new scheduled task
- remove: Delete a task by ID
- list: List all scheduled tasks
- enable: Enable a disabled task
- disable: Disable a task
- update: Update task parameters

Parameters:
- cron_expression: Time expression (e.g., "30s", "1m", "*/5m", "0 * * * *")
- max_runs: Maximum number of executions (optional, unlimited if not specified)
- task_type: "shell" for commands, "qwen" for AI responses`, Kind.Other, schema);
        this.config = config;
    }
    createInvocation(params) {
        return new ScheduleToolInvocation(this.config, params);
    }
}
ENDOFFILE

echo "✅ 已修复 scheduleTool.js"
echo ""
echo "验证修复："
echo "  qwen -p '列出所有定时任务'"
echo ""
echo "备份文件：$BACKUP"
