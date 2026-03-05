#!/bin/bash
# Qwen Code Schedule Tool Patch for npm version (v0.10.6)
# 直接修改已安装的 npm 包 cli.js 文件

set -e

echo "🔧 Qwen Code Schedule Tool 补丁安装脚本 (npm 版本)"
echo "=================================================="
echo ""

# 找到 npm 包的安装位置
NPM_ROOT=$(npm root -g 2>/dev/null || echo "/data/data/com.termux/files/usr/lib/node_modules")
QWEN_PKG="${NPM_ROOT}/@qwen-code/qwen-code"

if [ ! -d "$QWEN_PKG" ]; then
    QWEN_PKG="./node_modules/@qwen-code/qwen-code"
fi

if [ ! -f "$QWEN_PKG/cli.js" ]; then
    echo "❌ 错误：找不到 cli.js 文件"
    echo "请确认已安装 Qwen Code: npm install -g @qwen-code/qwen-code"
    exit 1
fi

echo "📍 包目录：$QWEN_PKG"
echo ""

CLI_FILE="$QWEN_PKG/cli.js"
BACKUP_FILE="${CLI_FILE}.backup.$(date +%Y%m%d%H%M%S)"

# 检查是否已打过补丁
if grep -q "ScheduleTool" "$CLI_FILE" 2>/dev/null; then
    echo "⚠️  检测到 cli.js 中已存在 ScheduleTool 相关代码"
    echo ""
    read -p "是否继续安装？(这将覆盖现有修改) [y/N]: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "已取消安装"
        exit 0
    fi
fi

# 备份原文件
echo "📦 备份原文件：$BACKUP_FILE"
cp "$CLI_FILE" "$BACKUP_FILE"

# 创建补丁脚本
PATCH_SCRIPT=$(mktemp)
cat > "$PATCH_SCRIPT" << 'PATCH_EOF'
const fs = require('fs');
const path = require('path');

const cliFile = process.argv[2];
const backupFile = process.argv[3];

console.log('📝 读取 cli.js...');
let content = fs.readFileSync(cliFile, 'utf8');

// 1. 查找 import { randomUUID } 的位置，如果没有则添加
if (!content.includes('randomUUID')) {
  console.log('添加 randomUUID 导入...');
  content = content.replace(
    /import \{ createRequire \} from "node:module";/,
    `import { createRequire } from "node:module";
import { randomUUID as cryptoRandomUUID } from "node:crypto";`
  );
}

// 2. 查找 ToolNames 定义的位置并添加 SCHEDULE
console.log('添加 SCHEDULE 到 ToolNames...');
const toolNamesPattern = /(SHELL:\s*'run_shell_command')/;
if (toolNamesPattern.test(content)) {
  content = content.replace(
    toolNamesPattern,
    `$1,\n    SCHEDULE: 'schedule'`
  );
}

// 3. 查找 ToolDisplayNames 并添加 SCHEDULE
console.log('添加 SCHEDULE 到 ToolDisplayNames...');
const toolDisplayPattern = /(SHELL:\s*'Shell')/;
if (toolDisplayPattern.test(content)) {
  content = content.replace(
    toolDisplayPattern,
    `$1,\n    SCHEDULE: 'Schedule'`
  );
}

// 4. 在 Config 类中查找 chatRecordingService 字段，在其后添加 schedulerService
console.log('添加 schedulerService 字段到 Config 类...');
const chatRecField = /(chatRecordingService\s*=\s*void 0;)/;
if (chatRecField.test(content)) {
  content = content.replace(
    chatRecField,
    `$1\n      schedulerService = void 0;`
  );
}

// 5. 在 Config 构造函数中查找 chatRecordingService 初始化，添加 schedulerService 初始化
console.log('添加 schedulerService 初始化...');
const chatRecInit = /(this\.chatRecordingService\s*=\s*this\.chatRecordingEnabled\s*\?\s*new ChatRecordingService\(this\)\s*:\s*void 0,?)/;
if (chatRecInit.test(content)) {
  content = content.replace(
    chatRecInit,
    `$1\n        this.schedulerService = new SchedulerService();`
  );
}

// 6. 在 Config.initialize() 中，查找 scheduler 相关初始化代码并添加 SchedulerService
console.log('在 initialize() 中添加 SchedulerService 启动...');
const initPattern = /(this\.debugLogger\.info\("Scheduler service started"\);)/;
if (!initPattern.test(content)) {
  // 在 toolRegistry 初始化之后添加
  const afterToolRegistry = /(this\.toolRegistry\s*=\s*await\s*this\.createToolRegistry\([^)]*\);)/;
  if (afterToolRegistry.test(content)) {
    content = content.replace(
      afterToolRegistry,
      `$1\n        this.schedulerService.setSchedulesPath(this.storage.getProjectSchedulesPath());\n        this.schedulerService.start();`
    );
  }
}

// 7. 添加 getSchedulerService 方法
console.log('添加 getSchedulerService() 方法...');
const getChatRec = /(getChatRecordingService\(\)\s*{\s*return\s*this\.chatRecordingService;\s*})/;
if (getChatRec.test(content) && !content.includes('getSchedulerService')) {
  content = content.replace(
    getChatRec,
    `$1\n      getSchedulerService() { return this.schedulerService; }`
  );
}

// 8. 在 createToolRegistry 中，查找 registerCoreTool(TodoWriteTool) 并在这行后添加 ScheduleTool
console.log('添加 ScheduleTool 注册...');
const todoWriteReg = /(registerCoreTool\(TodoWriteTool,\s*this\);)/;
if (todoWriteReg.test(content) && !content.includes('registerCoreTool(ScheduleTool')) {
  content = content.replace(
    todoWriteReg,
    `$1\n        registerCoreTool(ScheduleTool, this);`
  );
}

// 9. 查找 BaseDeclarativeTool 的导入并确认存在
console.log('检查 BaseDeclarativeTool 导入...');
if (!content.includes('BaseDeclarativeTool')) {
  console.warn('警告：未找到 BaseDeclarativeTool，可能需要手动添加');
}

// 10. 在文件末尾的 module 定义前注入 SchedulerService 和 ScheduleTool 类
console.log('注入 SchedulerService 和 ScheduleTool 类...');

const schedulerServiceCode = `
// ============== SCHEDULER SERVICE (INJECTED) ==============
var cryptoRandomUUID2;
var init_crypto_random_uuid = __esm({
  "crypto-random-uuid"() {
    cryptoRandomUUID2 = cryptoRandomUUID || function randomUUID() { return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => { const r = Math.random() * 16 | 0; const v = c === 'x' ? r : r & 0x3 | 0x8; return v.toString(16); }); };
  }
});

var SchedulerService;
var init_scheduler_service = __esm({
  "scheduler-service"() {
    init_esbuild_shims();
    init_crypto_random_uuid();
    SchedulerService = class {
      static { __name(this, "SchedulerService"); }
      tasks = new Map();
      timers = new Map();
      isRunning = false;
      schedulesPath = null;
      querySubmitCallback = null;

      setQuerySubmitCallback(cb) { this.querySubmitCallback = cb; }
      setSchedulesPath(p) { this.schedulesPath = p; this.loadTasks(); }

      start() {
        if (this.isRunning) return;
        this.isRunning = true;
        this.scheduleAllTasks();
      }

      stop() {
        this.isRunning = false;
        this.timers.forEach(t => clearTimeout(t));
        this.timers.clear();
      }

      addTask(params) {
        const id = cryptoRandomUUID2();
        const task = {
          id, name: params.name, description: params.description || '',
          cronExpression: params.cronExpression, command: params.command,
          prompt: params.prompt, taskType: params.taskType || (params.command ? 'shell' : 'qwen'),
          enabled: true, runCount: 0, maxRuns: params.maxRuns
        };
        this.tasks.set(id, task);
        this.saveTasks();
        if (this.isRunning) this.scheduleTask(task);
        return task;
      }

      removeTask(id) {
        const task = this.tasks.get(id);
        if (!task) return false;
        const timer = this.timers.get(id);
        if (timer) { clearTimeout(timer); this.timers.delete(id); }
        this.tasks.delete(id);
        this.saveTasks();
        return true;
      }

      getTask(id) { return this.tasks.get(id); }
      getAllTasks() { return Array.from(this.tasks.values()); }

      updateTask(id, updates) {
        const task = this.tasks.get(id);
        if (!task) return undefined;
        const timer = this.timers.get(id);
        if (timer) { clearTimeout(timer); this.timers.delete(id); }
        Object.assign(task, updates);
        this.saveTasks();
        if (this.isRunning && task.enabled) this.scheduleTask(task);
        return task;
      }

      enableTask(id) {
        const task = this.tasks.get(id);
        if (!task) return false;
        task.enabled = true;
        this.saveTasks();
        if (this.isRunning) this.scheduleTask(task);
        return true;
      }

      disableTask(id) {
        const task = this.tasks.get(id);
        if (!task) return false;
        task.enabled = false;
        const timer = this.timers.get(id);
        if (timer) { clearTimeout(timer); this.timers.delete(id); }
        this.saveTasks();
        return true;
      }

      scheduleAllTasks() {
        this.tasks.forEach(task => { if (task.enabled) this.scheduleTask(task); });
      }

      scheduleTask(task) {
        const delay = this.parseCronExpression(task.cronExpression);
        if (delay === null) {
          console.error('Invalid cron expression for task "' + task.name + '": ' + task.cronExpression);
          return;
        }
        task.nextRun = Date.now() + delay;
        const timer = setTimeout(async () => {
          await this.executeTask(task);
          if (task.enabled && this.isRunning) this.scheduleTask(task);
        }, delay);
        this.timers.set(task.id, timer);
      }

      parseCronExpression(expr) {
        const expr2 = expr.trim().toLowerCase();
        const starMatch = expr2.match(/^\\/\\*(\\d+)(s|m|h)?$/);
        if (starMatch) {
          const num = parseInt(starMatch[1], 10);
          const unit = starMatch[2] || 'm';
          return this.convertToMilliseconds(num, unit);
        }
        const intervalMatch = expr2.match(/^(\\d+)(s|m|h|d)$/);
        if (intervalMatch) {
          const num = parseInt(intervalMatch[1], 10);
          const unit = intervalMatch[2];
          return this.convertToMilliseconds(num, unit);
        }
        const cronMatch = expr2.match(/^(\\d+)\\s+(\\d+)\\s+\\*\\s+\\*\\s+\\*$/);
        if (cronMatch) {
          const minute = parseInt(cronMatch[1], 10);
          const hour = parseInt(cronMatch[2], 10);
          return this.calculateNextCronExecution(minute, hour);
        }
        return null;
      }

      convertToMilliseconds(value, unit) {
        switch (unit) {
          case 's': return value * 1e3;
          case 'm': return value * 60 * 1e3;
          case 'h': return value * 60 * 60 * 1e3;
          case 'd': return value * 24 * 60 * 60 * 1e3;
          default: return value * 60 * 1e3;
        }
      }

      calculateNextCronExecution(minute, hour) {
        const now = new Date();
        const target = new Date();
        target.setHours(hour, minute, 0, 0);
        if (target <= now) target.setDate(target.getDate() + 1);
        return target.getTime() - now.getTime();
      }

      async executeTask(task) {
        try {
          task.lastRun = Date.now();
          task.runCount++;
          this.saveTasks();
          if (task.taskType === 'qwen' && task.prompt && this.querySubmitCallback) {
            await this.executeQwenTask(task);
          } else if (task.taskType === 'shell' && task.command) {
            await this.executeShellTask(task);
          }
          if (task.maxRuns !== undefined && task.runCount >= task.maxRuns) {
            console.log('Task "' + task.name + '" has reached max runs (' + task.maxRuns + '), disabling...');
            this.disableTask(task.id);
          }
        } catch (error) {
          console.error('Error executing scheduled task "' + task.name + '":', error);
        }
      }

      async executeQwenTask(task) {
        if (!this.querySubmitCallback || !task.prompt) {
          console.error('Cannot execute Qwen task "' + task.name + '": missing callback or prompt');
          return;
        }
        console.log('🤖 Executing Qwen task: ' + task.name);
        await this.querySubmitCallback(task.prompt);
        console.log('✅ Qwen task completed: ' + task.name);
      }

      async executeShellTask(task) {
        if (!task.command) {
          console.error('Cannot execute shell task "' + task.name + '": missing command');
          return;
        }
        console.log('🔧 Executing shell task: ' + task.name);
        const { execSync } = await import('node:child_process');
        try {
          const output = execSync(task.command, { encoding: 'utf-8' });
          console.log('✅ Shell task completed: ' + task.name);
          console.log('Output: ' + output);
        } catch (error) {
          console.error('Shell task failed: ' + task.name, error.message);
        }
      }

      saveTasks() {
        if (!this.schedulesPath) return;
        try {
          const dir = path.dirname(this.schedulesPath);
          if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
          const tasks = Array.from(this.tasks.values());
          fs.writeFileSync(this.schedulesPath, JSON.stringify(tasks, null, 2));
        } catch (error) {
          console.error('Failed to save schedules:', error);
        }
      }

      loadTasks() {
        if (!this.schedulesPath || !fs.existsSync(this.schedulesPath)) return;
        try {
          const data = JSON.parse(fs.readFileSync(this.schedulesPath, 'utf8'));
          this.tasks.clear();
          data.forEach(task => this.tasks.set(task.id, task));
        } catch (error) {
          console.error('Failed to load schedules:', error);
        }
      }
    };
  }
});

`;

const scheduleToolCode = `
// ============== SCHEDULE TOOL (INJECTED) ==============
var ScheduleToolInvocation;
var ScheduleTool;
var init_schedule_tool = __esm({
  "schedule-tool"() {
    init_esbuild_shims();
    ScheduleToolInvocation = class extends BaseToolInvocation {
      static { __name(this, "ScheduleToolInvocation"); }
      config;
      constructor(config, params) {
        super(params);
        this.config = config;
      }
      getDescription() {
        return 'Schedule action: ' + this.params.action;
      }
      async execute(_signal) {
        const { action } = this.params;
        const scheduler = this.config.getSchedulerService();
        if (!scheduler) {
          return { llmContent: 'Scheduler service not available', returnDisplay: '❌ Scheduler service not available' };
        }
        let resultText = '';
        switch (action) {
          case 'add': resultText = this.handleAdd(scheduler); break;
          case 'remove': resultText = this.handleRemove(scheduler); break;
          case 'list': resultText = this.handleList(scheduler); break;
          case 'enable': resultText = this.handleEnable(scheduler); break;
          case 'disable': resultText = this.handleDisable(scheduler); break;
          case 'update': resultText = this.handleUpdate(scheduler); break;
          default: resultText = '❌ Unknown action: ' + action;
        }
        return { llmContent: resultText, returnDisplay: resultText };
      }
      handleAdd(scheduler) {
        if (!this.params.name) return '❌ Task name is required for add action.';
        if (!this.params.cron_expression) return '❌ Cron expression is required for add action.';
        if (!this.params.command && !this.params.prompt) return '❌ Either command or prompt is required for add action.';
        const task = scheduler.addTask({
          name: this.params.name, description: this.params.description || '',
          cronExpression: this.params.cron_expression, command: this.params.command,
          prompt: this.params.prompt, taskType: this.params.task_type || (this.params.command ? 'shell' : 'qwen'),
          maxRuns: this.params.max_runs
        });
        return '✅ Scheduled task added successfully!\\n\\n**Task ID**: \\`' + task.id + '\\`\\n**Name**: ' + task.name + '\\n**Description**: ' + (task.description || 'No description') + '\\n**Schedule**: ' + task.cronExpression + '\\n**Command**: \\`' + (task.command || 'N/A') + '\\`\\n**Prompt**: ' + (task.prompt || 'N/A') + '\\n**Type**: ' + task.taskType + '\\n**Max Runs**: ' + (task.maxRuns || 'Unlimited') + '\\n**Status**: Enabled';
      }
      handleRemove(scheduler) {
        const task = scheduler.getTask(this.params.task_id);
        if (!task) return '❌ Task with ID "' + this.params.task_id + '" not found.';
        scheduler.removeTask(this.params.task_id);
        return '✅ Scheduled task removed successfully!\\n\\n**Task ID**: ' + this.params.task_id + '\\n**Name**: ' + task.name;
      }
      handleList(scheduler) {
        const tasks = scheduler.getAllTasks();
        if (tasks.length === 0) return '📋 No scheduled tasks found.';
        let output = '📋 Scheduled Tasks (' + tasks.length + '):\\n\\n';
        tasks.forEach((task, index) => {
          output += (index + 1) + '. **' + task.name + '**\\n';
          output += '   - ID: \\`' + task.id + '\\`\\n';
          output += '   - Description: ' + (task.description || 'No description') + '\\n';
          output += '   - Schedule: ' + task.cronExpression + '\\n';
          output += '   - Type: ' + task.taskType + '\\n';
          output += '   - Status: ' + (task.enabled ? '✅ Enabled' : '❌ Disabled') + '\\n';
          output += '   - Run Count: ' + task.runCount + '\\n';
          if (task.lastRun) output += '   - Last Run: ' + new Date(task.lastRun).toLocaleString() + '\\n';
          if (task.nextRun) output += '   - Next Run: ' + new Date(task.nextRun).toLocaleString() + '\\n';
          output += '\\n';
        });
        return output;
      }
      handleEnable(scheduler) {
        const success = scheduler.enableTask(this.params.task_id);
        if (!success) return '❌ Task with ID "' + this.params.task_id + '" not found.';
        return '✅ Scheduled task enabled successfully!\\n\\n**Task ID**: ' + this.params.task_id;
      }
      handleDisable(scheduler) {
        const success = scheduler.disableTask(this.params.task_id);
        if (!success) return '❌ Task with ID "' + this.params.task_id + '" not found.';
        return '✅ Scheduled task disabled successfully!\\n\\n**Task ID**: ' + this.params.task_id;
      }
      handleUpdate(scheduler) {
        const task = scheduler.getTask(this.params.task_id);
        if (!task) return '❌ Task with ID "' + this.params.task_id + '" not found.';
        const updatedTask = scheduler.updateTask(this.params.task_id, {
          name: this.params.name, description: this.params.description,
          cronExpression: this.params.cron_expression, command: this.params.command,
          prompt: this.params.prompt, taskType: this.params.task_type
        });
        if (!updatedTask) return '❌ Failed to update task.';
        return '✅ Scheduled task updated successfully!\\n\\n**Task ID**: ' + this.params.task_id + '\\n**Name**: ' + updatedTask.name + '\\n**Schedule**: ' + updatedTask.cronExpression + '\\n**Status**: ' + (updatedTask.enabled ? '✅ Enabled' : '❌ Disabled');
      }
    };
    ScheduleTool = class extends BaseDeclarativeTool {
      static { __name(this, "ScheduleTool"); }
      config;
      static Name = ToolNames.SCHEDULE;
      constructor(config) {
        const schema = {
          type: 'object', properties: {
            action: { type: 'string', enum: ['add', 'remove', 'list', 'enable', 'disable', 'update'] },
            task_id: { type: 'string' }, name: { type: 'string' }, description: { type: 'string' },
            cron_expression: { type: 'string' }, command: { type: 'string' }, prompt: { type: 'string' },
            task_type: { type: 'string', enum: ['shell', 'qwen'] }, max_runs: { type: 'number' }
          }, required: ['action']
        };
        super(ScheduleTool.Name, ToolDisplayNames.SCHEDULE, 'Manage timed/scheduled tasks that can execute shell commands or trigger Qwen AI responses.\\n\\nAvailable actions:\\n- add: Create a new scheduled task\\n- remove: Delete a task by ID\\n- list: List all scheduled tasks\\n- enable: Enable a disabled task\\n- disable: Disable a task\\n- update: Update task parameters\\n\\nParameters:\\n- cron_expression: Time expression (e.g., "30s", "1m", "*/5m", "0 * * * *")\\n- max_runs: Maximum number of executions (optional, unlimited if not specified)\\n- task_type: "shell" for commands, "qwen" for AI responses', Kind.Other, schema);
        this.config = config;
      }
      createInvocation(params) {
        return new ScheduleToolInvocation(this.config, params);
      }
    };
  }
});
`;

// 查找合适的位置注入代码
// 在 ChatRecordingService 初始化之后注入 SchedulerService
const chatRecInitPos = content.indexOf('new ChatRecordingService(this)');
if (chatRecInitPos !== -1) {
  const insertPos = content.indexOf('};', chatRecInitPos);
  if (insertPos !== -1) {
    content = content.slice(0, insertPos) + schedulerServiceCode + content.slice(insertPos);
  }
}

// 在 ToolNames 定义之后注入 ScheduleTool
const toolNamesPos = content.indexOf('ToolNames = {');
if (toolNamesPos !== -1) {
  const insertAfter = content.indexOf('};', toolNamesPos);
  if (insertAfter !== -1) {
    content = content.slice(0, insertAfter + 2) + '\n' + scheduleToolCode + content.slice(insertAfter + 2);
  }
}

fs.writeFileSync(cliFile, content, 'utf8');
console.log('✅ 补丁安装完成！');
console.log('');
console.log('备份文件：' + backupFile);
console.log('');
console.log('测试命令:');
console.log('  qwen -p "列出所有定时任务"');
PATCH_EOF

# 运行 Node.js 补丁脚本
echo "🔧 应用补丁..."
node "$PATCH_SCRIPT" "$CLI_FILE" "$BACKUP_FILE"

# 清理临时文件
rm -f "$PATCH_SCRIPT"

echo ""
echo "✅ 补丁安装完成！"
echo ""
echo "备份文件：$BACKUP_FILE"
echo ""
echo "测试命令:"
echo "  qwen -p \"列出所有定时任务\""
echo ""
echo "如需卸载/恢复:"
echo "  cp $BACKUP_FILE $CLI_FILE"
