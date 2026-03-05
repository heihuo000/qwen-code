# Qwen Code Schedule Tool - NPM 版本补丁方案

## 概述

本方案用于在已安装的 npm 版本 Qwen Code (v0.10.6) 中添加 Schedule Tool 定时任务功能。

由于 npm 版本的 `cli.js` 是使用 esbuild 打包的单一文件，我们需要通过代码注入的方式添加功能。

## 检测当前环境

```bash
# 检查已安装的版本
npm list -g @qwen-code/qwen-code

# 检查是否已有 ScheduleTool
grep -c "ScheduleTool" /path/to/node_modules/@qwen-code/qwen-code/cli.js
# 返回 0 表示没有此功能
```

## 方案对比

### 方案 A: 直接修改 cli.js (推荐)

**优点**:
- 无需重新编译
- 快速生效
- 代码量可控

**缺点**:
- 需要找到正确的注入点
- npm 包更新后会丢失

### 方案 B: 外部模块注入

**优点**:
- 代码分离，易维护

**缺点**:
- 需要修改入口文件
- 可能破坏打包结构

### 方案 C: 等待官方发布

**优点**:
- 最稳定

**缺点**:
- 需要等待
- 不确定发布时间

## 实现步骤

### 1. 需要注入的代码

#### 1.1 SchedulerService 类

```javascript
var SchedulerService;
var init_scheduler_service = __esm({
  "scheduler-service"() {
    SchedulerService = class {
      tasks = new Map();
      timers = new Map();
      isRunning = false;
      schedulesPath = null;

      setSchedulesPath(p) { this.schedulesPath = p; this.loadTasks(); }
      start() { if (this.isRunning) return; this.isRunning = true; this.scheduleAllTasks(); }
      stop() { this.isRunning = false; this.timers.forEach(t => clearTimeout(t)); this.timers.clear(); }
      addTask(params) { /* 添加任务 */ }
      removeTask(id) { /* 删除任务 */ }
      getTask(id) { return this.tasks.get(id); }
      getAllTasks() { return Array.from(this.tasks.values()); }
      updateTask(id, updates) { /* 更新任务 */ }
      enableTask(id) { /* 启用任务 */ }
      disableTask(id) { /* 禁用任务 */ }
      scheduleAllTasks() { /* 调度所有任务 */ }
      scheduleTask(task) { /* 调度单个任务 */ }
      parseCronExpression(expr) { /* 解析 cron 表达式 */ }
      executeTask(task) { /* 执行任务 */ }
      saveTasks() { /* 保存到文件 */ }
      loadTasks() { /* 从文件加载 */ }
    };
  }
});
```

#### 1.2 ScheduleTool 类

```javascript
var ScheduleToolInvocation, ScheduleTool;
var init_schedule_tool = __esm({
  "schedule-tool"() {
    ScheduleToolInvocation = class extends BaseToolInvocation {
      async execute(_signal) { /* 执行工具调用 */ }
      handleAdd(scheduler) { /* 添加任务处理 */ }
      handleRemove(scheduler) { /* 删除任务处理 */ }
      handleList(scheduler) { /* 列表处理 */ }
      // ...
    };
    ScheduleTool = class extends BaseDeclarativeTool {
      static Name = ToolNames.SCHEDULE;
      createInvocation(params) { return new ScheduleToolInvocation(this.config, params); }
    };
  }
});
```

### 2. 需要修改的位置

#### 2.1 ToolNames 添加 SCHEDULE

```javascript
// 查找并修改
ToolNames = {
  // ...existing...
  SHELL: 'run_shell_command',
  SCHEDULE: 'schedule'  // 新增
};
```

#### 2.2 ToolDisplayNames 添加 SCHEDULE

```javascript
ToolDisplayNames = {
  // ...existing...
  SHELL: 'Shell',
  SCHEDULE: 'Schedule'  // 新增
};
```

#### 2.3 Config 类添加 schedulerService 字段

```javascript
class Config {
  // ...existing...
  schedulerService = void 0;  // 新增
}
```

#### 2.4 Config 构造函数初始化 schedulerService

```javascript
this.schedulerService = new SchedulerService();  // 新增
```

#### 2.5 Config.initialize() 启动服务

```javascript
this.schedulerService.setSchedulesPath(this.storage.getProjectSchedulesPath());
this.schedulerService.start();
```

#### 2.6 Config 添加 getSchedulerService 方法

```javascript
getSchedulerService() { return this.schedulerService; }
```

#### 2.7 createToolRegistry 注册 ScheduleTool

```javascript
registerCoreTool(ScheduleTool, this);  // 新增
```

## 自动化安装脚本

使用提供的 `patch-npm-version.sh` 脚本：

```bash
cd /path/to/qwen-code-patch
./patch-npm-version.sh
```

脚本会：
1. 自动找到 npm 包的安装位置
2. 备份原始 `cli.js`
3. 注入 SchedulerService 和 ScheduleTool 代码
4. 修改 Config 类添加必要的方法
5. 注册 ScheduleTool

## 验证安装

```bash
# 检查是否注入了代码
grep -c "SchedulerService" /path/to/node_modules/@qwen-code/qwen-code/cli.js
# 应该返回大于 0 的数字

grep -c "ScheduleTool" /path/to/node_modules/@qwen-code/qwen-code/cli.js
# 应该返回大于 0 的数字

# 测试功能
qwen -p "列出所有定时任务"
```

## 卸载/恢复

```bash
# 使用备份恢复
cp /path/to/cli.js.backup.YYYYMMDDHHMMSS /path/to/cli.js
```

## 注意事项

1. **npm 包更新**: 每次 npm 包更新后需要重新安装补丁
2. **备份文件**: 安装脚本会自动创建备份，请妥善保管
3. **兼容性**: 此补丁仅针对 v0.10.6 版本测试，其他版本可能需要调整

## 故障排除

### 问题 1: "Scheduler service not available"

**原因**: schedulerService 未正确初始化

**解决**: 检查 Config 类中是否有 `schedulerService` 字段和初始化代码

### 问题 2: "ScheduleTool 未注册"

**原因**: createToolRegistry 中没有注册 ScheduleTool

**解决**: 检查是否有 `registerCoreTool(ScheduleTool, this);` 这行代码

### 问题 3: 任务无法执行

**原因**: cron 表达式解析失败

**解决**: 使用支持的格式：
- `*/5s` - 每 5 秒
- `*/1m` - 每 1 分钟
- `30 14 * * *` - 每天 14:30

## 支持的 Cron 表达式

| 格式 | 示例 | 说明 |
|------|------|------|
| `*/Ns` | `*/30s` | 每 N 秒 |
| `*/Nm` | `*/5m` | 每 N 分钟 |
| `*/Nh` | `*/1h` | 每 N 小时 |
| `MM HH * * *` | `30 14 * * *` | 每天 HH:MM |

## 相关文件

- `patch-npm-version.sh` - 自动化安装脚本
- `schedule-tool-fix.patch` - 源码版本补丁
- `install-schedule-fix.sh` - 源码版本安装脚本
- `install-schedule-fix-npm.sh` - npm 版本简化安装脚本

## 贡献

如果你想将此功能集成到官方版本，请提交 PR 到 https://github.com/QwenLM/qwen-code
