# Qwen Code 定时任务功能补丁指南

本指南说明如何手工为 npm 版 Qwen Code 添加定时任务功能。适用于官方更新后快速恢复定时任务功能。

---

## 目录

1. [概述](#概述)
2. [修改大纲](#修改大纲)
3. [详细步骤](#详细步骤)
4. [补丁代码模板](#补丁代码模板)
5. [不同版本适配方案](#不同版本适配方案)
6. [验证与测试](#验证与测试)
7. [故障排除](#故障排除)

---

## 概述

### 目标
为 npm 安装的 Qwen Code (`@qwen-code/qwen-code`) 添加定时任务功能，无需修改源码重新构建。

### 适用范围
- npm 版 Qwen Code v0.10.x 及以上
- 已打包为单文件 `cli.js` 的版本
- esbuild 打包的项目结构

### 注意事项
**Termux 用户注意：** Termux 的 `/data/data/com.termux/files/usr/bin/qwen` 是特殊打包版本，不能直接修改。建议使用以下方式：
1. 使用 source code 版本：`cd /path/to/qwen-code && npm start`
2. 或者修改 npm 包中的 cli.js：`/data/data/com.termux/files/usr/lib/node_modules/@qwen-code/qwen-code/cli.js`

### 核心修改
共 8 处修改，分为两类：
1. **声明类修改**（4 处）：工具名称、显示名称、字段声明、方法声明
2. **注入类修改**（4 处）：服务初始化、工具注册、类定义注入

---

## 修改大纲

| 序号 | 修改内容 | 位置特征 | 修改类型 |
|------|----------|----------|----------|
| 1 | SCHEDULE 添加到 ToolNames | `SHELL: "run_shell_command"` 之后 | 声明 |
| 2 | SCHEDULE 添加到 ToolDisplayNames | `SHELL: "Shell"` 之后 | 声明 |
| 3 | schedulerService 字段 | `chatRecordingService = void 0` 之后 | 声明 |
| 4 | schedulerService 初始化 | `this.chatRecordingService = ...` 之后 | 初始化 |
| 5 | getSchedulerService 方法 | `getChatRecordingService()` 方法之后 | 方法 |
| 6 | ScheduleTool 注册 | `registerCoreTool(TodoWriteTool, this)` 之后 | 注册 |
| 7 | SchedulerService 类注入 | `init_tools` 模块结束后 | 类定义 |
| 8 | ScheduleTool 类注入 | SchedulerService 之后 | 类定义 |

---

## 详细步骤

### 准备工作

```bash
# 1. 找到 Qwen 安装路径
which qwen
# 输出示例：/data/data/com.termux/files/usr/bin/qwen

# 2. 找到 cli.js 位置
# 通常位于：/data/data/com.termux/files/usr/lib/node_modules/@qwen-code/qwen-code/cli.js

# 3. 备份原始文件（重要！）
cp cli.js cli.js.backup.$(date +%s)
```

### 步骤 1：添加 SCHEDULE 到 ToolNames

**查找特征：**
```javascript
SHELL: "run_shell_command",
```

**修改前：**
```javascript
var ToolNames = {
  EDIT: "edit",
  SHELL: "run_shell_command",
  TODO_WRITE: "todo_write",
  // ...
};
```

**修改后：**
```javascript
var ToolNames = {
  EDIT: "edit",
  SHELL: "run_shell_command",
  SCHEDULE: "schedule",    // ← 添加此行
  TODO_WRITE: "todo_write",
  // ...
};
```

### 步骤 2：添加 SCHEDULE 到 ToolDisplayNames

**查找特征：**
```javascript
SHELL: "Shell",
```

**修改前：**
```javascript
var ToolDisplayNames = {
  EDIT: "Edit",
  SHELL: "Shell",
  TODO_WRITE: "TodoWrite",
  // ...
};
```

**修改后：**
```javascript
var ToolDisplayNames = {
  EDIT: "Edit",
  SHELL: "Shell",
  SCHEDULE: "Schedule",    // ← 添加此行
  TODO_WRITE: "TodoWrite",
  // ...
};
```

### 步骤 3：添加 schedulerService 字段

**查找特征：**
```javascript
chatRecordingService = void 0;
```

**修改位置：** Config 类字段声明区域

**修改前：**
```javascript
var Config = class {
  // ...
  chatRecordingService = void 0;
  checkpointing;
  // ...
};
```

**修改后：**
```javascript
var Config = class {
  // ...
  chatRecordingService = void 0;
  schedulerService = void 0;    // ← 添加此行
  checkpointing;
  // ...
};
```

### 步骤 4：添加 schedulerService 初始化

**查找特征：**
```javascript
this.chatRecordingService = this.chatRecordingEnabled ? new ChatRecordingService(this) : void 0;
```

**修改位置：** Config 构造函数内

**修改前：**
```javascript
this.geminiClient = new GeminiClient(this);
this.chatRecordingService = this.chatRecordingEnabled ? new ChatRecordingService(this) : void 0;
this.extensionManager = new ExtensionManager({...});
```

**修改后：**
```javascript
this.geminiClient = new GeminiClient(this);
this.chatRecordingService = this.chatRecordingEnabled ? new ChatRecordingService(this) : void 0;
this.schedulerService = new SchedulerService();    // ← 添加此行
this.extensionManager = new ExtensionManager({...});
```

**注意：** 不要调用 `setSchedulesPath()` 和 `start()` 方法，它们可能导致初始化阻塞。任务数据会在首次添加任务时自动保存。

### 步骤 5：添加 getSchedulerService 方法

**查找特征：**
```javascript
getChatRecordingService() {
```

**修改位置：** Config 类方法区域

**修改前：**
```javascript
getChatRecordingService() {
  if (!this.chatRecordingEnabled) {
    return void 0;
  }
  if (!this.chatRecordingService) {
    this.chatRecordingService = new ChatRecordingService(this);
  }
  return this.chatRecordingService;
}
/**
 * Gets or creates a SessionService...
 */
getSessionService() {
```

**修改后：**
```javascript
getChatRecordingService() {
  if (!this.chatRecordingEnabled) {
    return void 0;
  }
  if (!this.chatRecordingService) {
    this.chatRecordingService = new ChatRecordingService(this);
  }
  return this.chatRecordingService;
}
getSchedulerService() { return this.schedulerService; }    // ← 添加此行
/**
 * Gets or creates a SessionService...
 */
getSessionService() {
```

### 步骤 6：注册 ScheduleTool

**查找特征：**
```javascript
registerCoreTool(TodoWriteTool, this);
```

**修改位置：** `createToolRegistry` 函数内

**修改前：**
```javascript
registerCoreTool(TodoWriteTool, this);
!this.sdkMode && registerCoreTool(ExitPlanModeTool, this);
```

**修改后：**
```javascript
registerCoreTool(TodoWriteTool, this);
registerCoreTool(ScheduleTool, this);    // ← 添加此行
!this.sdkMode && registerCoreTool(ExitPlanModeTool, this);
```

### 步骤 7-8：注入 SchedulerService 和 ScheduleTool 类

**查找特征：**
```javascript
});

// packages/core/dist/src/tools/mcp-tool.js
```

找到 `init_tools` 模块的结束位置（`});`）

**修改位置：** `init_tools` 模块结束后，`mcp-tool.js` 引入前

**添加代码：**
```javascript
});

// === SCHEDULER SERVICE (SCHEDULE-AGENT) ===
var SchedulerService=class{static{__name(this,"SchedulerService")}tasks=new Map();timers=new Map();isRunning=false;schedulesPath=null;querySubmitCallback=null;setQuerySubmitCallback(cb){this.querySubmitCallback=cb;}setSchedulesPath(p){this.schedulesPath=p;this.loadTasks();}start(){if(this.isRunning)return;this.isRunning=true;this.scheduleAllTasks();}stop(){this.isRunning=false;this.timers.forEach(t=>clearTimeout(t));this.timers.clear();}addTask(params){const id=crypto.randomUUID();const task={id,name:params.name,description:params.description||'',cronExpression:params.cronExpression,command:params.command,prompt:params.prompt,taskType:params.taskType||(params.command?'shell':'qwen'),enabled:true,runCount:0,maxRuns:params.maxRuns};this.tasks.set(id,task);this.saveTasks();if(this.isRunning)this.scheduleTask(task);return task;}removeTask(id){const task=this.tasks.get(id);if(!task)return false;const timer=this.timers.get(id);if(timer){clearTimeout(timer);this.timers.delete(id);}this.tasks.delete(id);this.saveTasks();return true;}getTask(id){return this.tasks.get(id);}getAllTasks(){return Array.from(this.tasks.values());}updateTask(id,updates){const task=this.tasks.get(id);if(!task)return undefined;const timer=this.timers.get(id);if(timer){clearTimeout(timer);this.timers.delete(id);}Object.assign(task,updates);this.saveTasks();if(this.isRunning&&task.enabled)this.scheduleTask(task);return task;}enableTask(id){const task=this.tasks.get(id);if(!task)return false;task.enabled=true;this.saveTasks();if(this.isRunning)this.scheduleTask(task);return true;}disableTask(id){const task=this.tasks.get(id);if(!task)return false;task.enabled=false;const timer=this.timers.get(id);if(timer){clearTimeout(timer);this.timers.delete(id);}this.saveTasks();return true;}scheduleAllTasks(){this.tasks.forEach(task=>{if(task.enabled)this.scheduleTask(task);});}scheduleTask(task){const delay=this.parseCronExpression(task.cronExpression);if(delay===null){console.error('Invalid cron for "'+task.name+'": '+task.cronExpression);return;}task.nextRun=Date.now()+delay;const timer=setTimeout(async()=>{await this.executeTask(task);if(task.enabled&&this.isRunning)this.scheduleTask(task);},delay);this.timers.set(task.id,timer);}parseCronExpression(expr){const e=expr.trim().toLowerCase();let m;if(m=e.match(/^\/\*(\d+)(s|m|h)?$/)){return this.toMs(parseInt(m[1]),m[2]||'m');}if(m=e.match(/^(\d+)(s|m|h|d)$/)){return this.toMs(parseInt(m[1]),m[2]);}if(m=e.match(/^(\d+)\s+(\d+)\s+\*\s+\*\s+\*$/)){return this.nextCron(parseInt(m[1]),parseInt(m[2]));}return null;}toMs(v,u){switch(u){case's':return v*1e3;case'm':return v*60*1e3;case'h':return v*36e5;case'd':return v*864e5;default:return v*6e4;}}nextCron(min,h){const now=new Date(),t=new Date();t.setHours(h,min,0,0);if(t<=now)t.setDate(t.getDate()+1);return t.getTime()-now.getTime();}async executeTask(task){try{task.lastRun=Date.now();task.runCount++;this.saveTasks();if(task.taskType==='qwen'&&task.prompt&&this.querySubmitCallback){console.log('🤖 Qwen task: '+task.name);await this.querySubmitCallback(task.prompt);}else if(task.taskType==='shell'&&task.command){console.log('🔧 Shell task: '+task.name);const{execSync}=await import('node:child_process');try{console.log(execSync(task.command,{encoding:'utf8'}));}catch(e){console.error('Task failed:',e.message);}}if(task.maxRuns&&task.runCount>=task.maxRuns){console.log('Task "'+task.name+'" reached max runs, disabling...');this.disableTask(task.id);}}catch(e){console.error('Task error "'+task.name+'":',e);}}saveTasks(){if(!this.schedulesPath)return;try{const dir=dirname(this.schedulesPath);if(!existsSync(dir))mkdirSync(dir,{recursive:true});writeFileSync(this.schedulesPath,JSON.stringify(Array.from(this.tasks.values()),null,2));}catch(e){console.error('Save failed:',e);}}loadTasks(){if(!this.schedulesPath||!existsSync(this.schedulesPath))return;try{const data=JSON.parse(readFileSync(this.schedulesPath,'utf8'));this.tasks.clear();data.forEach(t=>this.tasks.set(t.id,t));}catch(e){console.error('Load failed:',e);}}};
var ScheduleTool=class extends BaseDeclarativeTool{static{__name(this,"ScheduleTool");}static Name;static{this.Name=ToolNames.SCHEDULE;}config;constructor(config){const schema={type:'object',properties:{action:{type:'string',enum:['add','remove','list','enable','disable','update']},task_id:{type:'string'},name:{type:'string'},description:{type:'string'},cron_expression:{type:'string'},command:{type:'string'},prompt:{type:'string'},task_type:{type:'string',enum:['shell','qwen']},max_runs:{type:'number'}},required:['action']};super(ScheduleTool.Name,ToolDisplayNames.SCHEDULE,'Manage scheduled tasks',4,schema);this.config=config;}createInvocation(p){return new ScheduleToolInvocation(this.config,p)}};var ScheduleToolInvocation=class extends BaseToolInvocation{config;constructor(config,p){super(p);this.config=config;}getDescription(){return'Schedule: '+this.params.action;}async execute(_s){const{action}=this.params,sched=this.config.getSchedulerService();if(!sched)return{llmContent:'Scheduler unavailable',returnDisplay:'❌ Scheduler unavailable'};let r='';switch(action){case'add':r=this.handleAdd(sched);break;case'remove':r=this.handleRemove(sched);break;case'list':r=this.handleList(sched);break;case'enable':r=this.handleEnable(sched);break;case'disable':r=this.handleDisable(sched);break;case'update':r=this.handleUpdate(sched);break;default:r='❌ Unknown action';}return{llmContent:r,returnDisplay:r};}handleAdd(s){const p=this.params;if(!p.name)return'❌ Name required';if(!p.cron_expression)return'❌ Cron required';if(!p.command&&!p.prompt)return'❌ Command or prompt required';const t=s.addTask({name:p.name,description:p.description||'',cronExpression:p.cron_expression,command:p.command,prompt:p.prompt,taskType:p.task_type||(p.command?'shell':'qwen'),maxRuns:p.max_runs});return'✅ Task added: '+t.name+' (ID: '+t.id+')';}handleRemove(s){const t=s.getTask(this.params.task_id);if(!t)return'❌ Not found';s.removeTask(this.params.task_id);return'✅ Removed: '+t.name;}handleList(s){const ts=s.getAllTasks();if(!ts.length)return'📋 No tasks';return'📋 Tasks ('+ts.length+'):\n'+ts.map((t,i)=>(i+1)+'. '+t.name+' ['+t.cronExpression+'] '+(t.enabled?'✅':'❌')).join('\n');}handleEnable(s){return s.enableTask(this.params.task_id)?'✅ Enabled':'❌ Not found';}handleDisable(s){return s.disableTask(this.params.task_id)?'✅ Disabled':'❌ Not found';}handleUpdate(s){const t=s.getTask(this.params.task_id);if(!t)return'❌ Not found';s.updateTask(this.params.task_id,{cronExpression:this.params.cron_expression});return'✅ Updated';}};

// packages/core/dist/src/tools/mcp-tool.js
```

---

## 补丁代码模板

### SchedulerService 类（压缩版）

```javascript
// === SCHEDULER SERVICE (SCHEDULE-AGENT) ===
var SchedulerService=class{static{__name(this,"SchedulerService")}tasks=new Map();timers=new Map();isRunning=false;schedulesPath=null;setQuerySubmitCallback(cb){}setSchedulesPath(p){this.schedulesPath=p;this.loadTasks();}start(){if(this.isRunning)return;this.isRunning=true;this.scheduleAllTasks();}stop(){this.isRunning=false;this.timers.forEach(t=>clearTimeout(t));this.timers.clear();}addTask(params){const id=crypto.randomUUID();const task={id,name:params.name,description:params.description||'',cronExpression:params.cronExpression,command:params.command,prompt:params.prompt,taskType:params.taskType||(params.command?'shell':'qwen'),enabled:true,runCount:0,maxRuns:params.maxRuns};this.tasks.set(id,task);this.saveTasks();if(this.isRunning)this.scheduleTask(task);return task;}removeTask(id){const task=this.tasks.get(id);if(!task)return false;const timer=this.timers.get(id);if(timer){clearTimeout(timer);this.timers.delete(id);}this.tasks.delete(id);this.saveTasks();return true;}getTask(id){return this.tasks.get(id);}getAllTasks(){return Array.from(this.tasks.values());}updateTask(id,updates){const task=this.tasks.get(id);if(!task)return undefined;const timer=this.timers.get(id);if(timer){clearTimeout(timer);this.timers.delete(id);}Object.assign(task,updates);this.saveTasks();if(this.isRunning&&task.enabled)this.scheduleTask(task);return task;}enableTask(id){const task=this.tasks.get(id);if(!task)return false;task.enabled=true;this.saveTasks();if(this.isRunning)this.scheduleTask(task);return true;}disableTask(id){const task=this.tasks.get(id);if(!task)return false;task.enabled=false;const timer=this.timers.get(id);if(timer){clearTimeout(timer);this.timers.delete(id);}this.saveTasks();return true;}scheduleAllTasks(){this.tasks.forEach(task=>{if(task.enabled)this.scheduleTask(task);});}scheduleTask(task){const delay=this.parseCronExpression(task.cronExpression);if(delay===null){console.error('Invalid cron for "'+task.name+'": '+task.cronExpression);return;}task.nextRun=Date.now()+delay;const timer=setTimeout(async()=>{await this.executeTask(task);if(task.enabled&&this.isRunning)this.scheduleTask(task);},delay);this.timers.set(task.id,timer);}parseCronExpression(expr){const e=expr.trim().toLowerCase();let m;if(m=e.match(/^\/\*(\d+)(s|m|h)?$/)){return this.toMs(parseInt(m[1]),m[2]||'m');}if(m=e.match(/^(\d+)(s|m|h|d)$/)){return this.toMs(parseInt(m[1]),m[2]);}if(m=e.match(/^(\d+)\s+(\d+)\s+\*\s+\*\s+\*$/)){return this.nextCron(parseInt(m[1]),parseInt(m[2]));}return null;}toMs(v,u){switch(u){case's':return v*1e3;case'm':return v*60*1e3;case'h':return v*36e5;case'd':return v*864e5;default:return v*6e4;}}nextCron(min,h){const now=new Date(),t=new Date();t.setHours(h,min,0,0);if(t<=now)t.setDate(t.getDate()+1);return t.getTime()-now.getTime();}async executeTask(task){try{task.lastRun=Date.now();task.runCount++;this.saveTasks();if(task.taskType==='qwen'&&task.prompt){console.log('🤖 Qwen task: '+task.name);const{execSync}=await import('node:child_process');try{execSync('qwen -y "'+task.prompt.replace(/"/g,'\\"')+'"',{encoding:'utf8',stdio:'ignore'});}catch(e){console.error('Task failed:',e.message);}}else if(task.taskType==='shell'&&task.command){console.log('🔧 Shell task: '+task.name);const{execSync}=await import('node:child_process');try{console.log(execSync(task.command,{encoding:'utf8'}));}catch(e){console.error('Task failed:',e.message);}}if(task.maxRuns&&task.runCount>=task.maxRuns){console.log('Task "'+task.name+'" reached max runs, disabling...');this.disableTask(task.id);}}catch(e){console.error('Task error "'+task.name+'":',e);}}saveTasks(){if(!this.schedulesPath)return;try{const dir=dirname(this.schedulesPath);if(!existsSync(dir))mkdirSync(dir,{recursive:true});writeFileSync(this.schedulesPath,JSON.stringify(Array.from(this.tasks.values()),null,2));}catch(e){console.error('Save failed:',e);}}loadTasks(){if(!this.schedulesPath||!existsSync(this.schedulesPath))return;try{const data=JSON.parse(readFileSync(this.schedulesPath,'utf8'));this.tasks.clear();data.forEach(t=>this.tasks.set(t.id,t));}catch(e){console.error('Load failed:',e);}}};
```

### ScheduleTool 类（压缩版）

```javascript
var ScheduleTool=class extends BaseDeclarativeTool{static{__name(this,"ScheduleTool");}static Name;static{this.Name=ToolNames.SCHEDULE;}config;constructor(config){const schema={type:'object',properties:{action:{type:'string',enum:['add','remove','list','enable','disable','update']},task_id:{type:'string'},name:{type:'string'},description:{type:'string'},cron_expression:{type:'string'},command:{type:'string'},prompt:{type:'string'},task_type:{type:'string',enum:['shell','qwen']},max_runs:{type:'number'}},required:['action']};super(ScheduleTool.Name,ToolDisplayNames.SCHEDULE,'Manage scheduled tasks',4,schema);this.config=config;}createInvocation(p){return new ScheduleToolInvocation(this.config,p)}};var ScheduleToolInvocation=class extends BaseToolInvocation{config;constructor(config,p){super(p);this.config=config;}getDescription(){return'Schedule: '+this.params.action;}async execute(_s){const{action}=this.params,sched=this.config.getSchedulerService();if(!sched)return{llmContent:'Scheduler unavailable',returnDisplay:'❌ Scheduler unavailable'};let r='';switch(action){case'add':r=this.handleAdd(sched);break;case'remove':r=this.handleRemove(sched);break;case'list':r=this.handleList(sched);break;case'enable':r=this.handleEnable(sched);break;case'disable':r=this.handleDisable(sched);break;case'update':r=this.handleUpdate(sched);break;default:r='❌ Unknown action';}return{llmContent:r,returnDisplay:r};}handleAdd(s){const p=this.params;if(!p.name)return'❌ Name required';if(!p.cron_expression)return'❌ Cron required';if(!p.command&&!p.prompt)return'❌ Command or prompt required';const t=s.addTask({name:p.name,description:p.description||'',cronExpression:p.cron_expression,command:p.command,prompt:p.prompt,taskType:p.task_type||(p.command?'shell':'qwen'),maxRuns:p.max_runs});return'✅ Task added: '+t.name+' (ID: '+t.id+')';}handleRemove(s){const t=s.getTask(this.params.task_id);if(!t)return'❌ Not found';s.removeTask(this.params.task_id);return'✅ Removed: '+t.name;}handleList(s){const ts=s.getAllTasks();if(!ts.length)return'📋 No tasks';return'📋 Tasks ('+ts.length+'):\n'+ts.map((t,i)=>(i+1)+'. '+t.name+' ['+t.cronExpression+'] '+(t.enabled?'✅':'❌')).join('\n');}handleEnable(s){return s.enableTask(this.params.task_id)?'✅ Enabled':'❌ Not found';}handleDisable(s){return s.disableTask(this.params.task_id)?'✅ Disabled':'❌ Not found';}handleUpdate(s){const t=s.getTask(this.params.task_id);if(!t)return'❌ Not found';s.updateTask(this.params.task_id,{cronExpression:this.params.cron_expression});return'✅ Updated';}};
```

---

## 不同版本适配方案

### 情况 A：引号格式不同

**问题：** 某些版本使用单引号而非双引号

**适配方案：**
```javascript
// 如果是单引号格式
SHELL: 'run_shell_command',
// 则添加：
SCHEDULE: 'schedule',

// 如果是双引号格式
SHELL: "run_shell_command",
// 则添加：
SCHEDULE: "schedule",
```

### 情况 B：字段声明顺序不同

**问题：** `chatRecordingService` 字段位置可能变化

**适配方案：** 查找任意服务字段声明，在其后添加
```javascript
// 查找任意 = void 0 或 = null 的字段
xxxService = void 0;
// 在其后添加：
schedulerService = void 0;
```

### 情况 C：初始化位置不同

**问题：** `ChatRecordingService` 初始化可能在多处

**适配方案：** 在主构造函数的第一个服务初始化后添加
```javascript
// 通常在 geminiClient 初始化之后
this.geminiClient = new GeminiClient(this);
this.chatRecordingService = ...;
this.schedulerService = new SchedulerService();    // ← 紧接其后
```

### 情况 D：工具注册函数名不同

**问题：** 可能不是 `registerCoreTool`

**适配方案：** 查找实际的工具注册函数名
```javascript
// 如果注册函数是 addTool
addTool(TodoWriteTool, this);
// 则添加：
addTool(ScheduleTool, this);
```

### 情况 E：模块结构不同

**问题：** `init_tools` 模块名称或位置不同

**适配方案：**
1. 查找 `BaseDeclarativeTool = class` 定义
2. 找到包含它的 `__esm` 或 `var init_xxx` 模块
3. 在该模块结束后注入类定义

```bash
# 查找 BaseDeclarativeTool 定义
grep -n "BaseDeclarativeTool = class" cli.js

# 查找所在模块的结束位置
# 向上找到 var init_xxx = __esm({
# 向下找到对应的 });
```

### 情况 F：类定义需要展开版

**问题：** 压缩版代码难以阅读和调试

**解决：** 使用展开版类定义（见附录）

---

## 验证与测试

### 验证注入

```bash
# 检查所有补丁是否注入
echo "=== 验证补丁 ==="
grep -c 'SCHEDULE: "schedule"' cli.js           # 应返回 1
grep -c 'SCHEDULE: "Schedule"' cli.js           # 应返回 1
grep -c 'schedulerService = void 0' cli.js      # 应返回 1
grep -c 'this.schedulerService = new SchedulerService' cli.js  # 应返回 1
grep -c 'getSchedulerService()' cli.js          # 应返回 ≥1
grep -c 'registerCoreTool(ScheduleTool' cli.js  # 应返回 1
grep -c 'var SchedulerService=' cli.js          # 应返回 1
grep -c 'var ScheduleTool=' cli.js              # 应返回 1
```

### 功能测试

```bash
# 测试 1：列出所有任务
qwen -p "列出所有定时任务"

# 测试 2：添加定时任务
qwen -p "添加一个定时任务，名称叫'测试'，每分钟执行一次，执行命令 echo hello"

# 测试 3：查看任务列表
qwen -p "查看我的定时任务列表"
```

---

## 故障排除

### 问题 1：启动时报语法错误

**原因：** 补丁代码格式错误或注入位置不对

**解决：**
1. 恢复备份：`cp cli.js.backup.xxx cli.js`
2. 检查注入位置前后的代码结构
3. 确保 `});` 和注释的格式完全匹配

### 问题 2：提示 "ScheduleTool 未定义"

**原因：** 类定义注入在引用之前

**解决：** 确保 `SchedulerService` 和 `ScheduleTool` 类定义在 `BaseDeclarativeTool` 和 `BaseToolInvocation` 定义之后

### 问题 3：提示 "getSchedulerService 不是函数"

**原因：** getSchedulerService 方法未正确添加或 Config 类结构不同

**解决：** 检查 Config 类中方法定义的位置，确保方法添加在类体内

### 问题 4：补丁已注入但功能不可用

**原因：** 可能使用了缓存的旧版本

**解决：**
```bash
# 清除 Node.js 缓存
rm -rf ~/.node-gyp
rm -rf ~/.npm/_cacache

# 重新安装 Qwen
npm uninstall -g @qwen-code/qwen-code
npm install -g @qwen-code/qwen-code

# 重新应用补丁
```

---

## 附录：展开版类定义（调试用）

### SchedulerService（展开版）

```javascript
// === SCHEDULER SERVICE (SCHEDULE-AGENT) ===
var SchedulerService = class {
  static { __name(this, "SchedulerService"); }

  tasks = new Map();
  timers = new Map();
  isRunning = false;
  schedulesPath = null;
  querySubmitCallback = null;

  setQuerySubmitCallback(cb) {
    this.querySubmitCallback = cb;
  }

  setSchedulesPath(p) {
    this.schedulesPath = p;
    this.loadTasks();
  }

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
    const id = crypto.randomUUID();
    const task = {
      id,
      name: params.name,
      description: params.description || '',
      cronExpression: params.cronExpression,
      command: params.command,
      prompt: params.prompt,
      taskType: params.taskType || (params.command ? 'shell' : 'qwen'),
      enabled: true,
      runCount: 0,
      maxRuns: params.maxRuns
    };
    this.tasks.set(id, task);
    this.saveTasks();
    if (this.isRunning) this.scheduleTask(task);
    return task;
  }

  // ... 更多方法见压缩版
};
```

---

## 快速参考卡片

```
修改位置速查：
1. ToolNames        → 找 SHELL: "run_shell_command"
2. ToolDisplayNames → 找 SHELL: "Shell"
3. 字段声明         → 找 chatRecordingService = void 0
4. 初始化           → 找 this.chatRecordingService = ...
5. get 方法         → 找 getChatRecordingService()
6. 工具注册         → 找 registerCoreTool(TodoWriteTool
7-8. 类注入         → 找 init_tools 的 }); 结束位置
```

---

## 更新历史

| 日期 | Qwen 版本 | 适配说明 |
|------|-----------|----------|
| 2026-03-06 | v0.10.6 | 初始版本，双引号格式，移除 querySubmitCallback 依赖 |
| TBD | v0.11.x | 待补充 |

**重要说明：**
- 不要调用 `setSchedulesPath()` 和 `start()` 方法，它们可能导致初始化阻塞
- Qwen 类型任务通过 `qwen -y "prompt"` 命令执行
- 任务数据在首次添加任务时自动保存到 `~/.qwen/schedules.json`

---

**注意：** 每次 Qwen Code 更新后，需要重新应用此补丁。建议保留 `cli.js.backup` 文件以便快速恢复。
