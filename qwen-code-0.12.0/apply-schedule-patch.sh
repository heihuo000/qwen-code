#!/bin/bash
# 手工应用定时任务补丁到 npm 版 Qwen Code

CLI_PATH="/data/data/com.termux/files/usr/lib/node_modules/@qwen-code/qwen-code/cli.js"

if [ ! -f "$CLI_PATH" ]; then
    echo "❌ 找不到 cli.js: $CLI_PATH"
    exit 1
fi

echo "正在应用定时任务补丁..."

# 1. 添加 SCHEDULE 到 ToolNames (在第 72911 行 SHELL 之后)
if ! grep -q 'SCHEDULE: "schedule"' "$CLI_PATH"; then
    sed -i 's/SHELL: "run_shell_command",/SHELL: "run_shell_command",\n      SCHEDULE: "schedule",/' "$CLI_PATH"
    echo "✅ 添加 SCHEDULE 到 ToolNames"
fi

# 2. 添加 SCHEDULE 到 ToolDisplayNames (在第 72929 行 SHELL 之后)
if ! grep -q 'SCHEDULE: "Schedule"' "$CLI_PATH"; then
    sed -i 's/SHELL: "Shell",/SHELL: "Shell",\n      SCHEDULE: "Schedule",/' "$CLI_PATH"
    echo "✅ 添加 SCHEDULE 到 ToolDisplayNames"
fi

# 3. 添加 schedulerService 字段
if ! grep -q 'schedulerService = void 0' "$CLI_PATH"; then
    sed -i 's/chatRecordingService = void 0;/chatRecordingService = void 0;\n      schedulerService = void 0;/' "$CLI_PATH"
    echo "✅ 添加 schedulerService 字段"
fi

# 4. 添加 schedulerService 初始化
if ! grep -q 'this.schedulerService = new SchedulerService' "$CLI_PATH"; then
    sed -i 's/this.chatRecordingService = this.chatRecordingEnabled ? new ChatRecordingService(this) : void 0;/this.chatRecordingService = this.chatRecordingEnabled ? new ChatRecordingService(this) : void 0;\n        this.schedulerService = new SchedulerService();/' "$CLI_PATH"
    echo "✅ 添加 schedulerService 初始化"
fi

# 5. 添加 getSchedulerService 方法 - 在 getChatRecordingService 之后
if ! grep -q 'getSchedulerService()' "$CLI_PATH"; then
    sed -i 's/getChatRecordingService() { return this.chatRecordingService; }/getChatRecordingService() { return this.chatRecordingService; }\n      getSchedulerService() { return this.schedulerService; }/' "$CLI_PATH"
    echo "✅ 添加 getSchedulerService 方法"
fi

# 6. 注册 ScheduleTool - 在 TodoWriteTool 之后
if ! grep -q 'registerCoreTool(ScheduleTool' "$CLI_PATH"; then
    sed -i 's/registerCoreTool(TodoWriteTool, this);/registerCoreTool(TodoWriteTool, this);\n        registerCoreTool(ScheduleTool, this);/' "$CLI_PATH"
    echo "✅ 注册 ScheduleTool"
fi

# 7 & 8. 注入 SchedulerService 和 ScheduleTool 类 - 在 BaseDeclarativeTool 定义之后 (72513 行 init_tools 结束括号后)
if ! grep -q 'var SchedulerService=' "$CLI_PATH"; then
    # 在 init_tools 结束行之后注入
    sed -i '/^});$/a\
\
// === SCHEDULER SERVICE (SCHEDULE-AGENT) ===\
var SchedulerService=class{static{__name(this,"SchedulerService")}tasks=new Map();timers=new Map();isRunning=false;schedulesPath=null;querySubmitCallback=null;setQuerySubmitCallback(cb){this.querySubmitCallback=cb;}setSchedulesPath(p){this.schedulesPath=p;this.loadTasks();}start(){if(this.isRunning)return;this.isRunning=true;this.scheduleAllTasks();}stop(){this.isRunning=false;this.timers.forEach(t=>clearTimeout(t));this.timers.clear();}addTask(params){const id=crypto.randomUUID();const task={id,name:params.name,description:params.description||'"'"''"'"',cronExpression:params.cronExpression,command:params.command,prompt:params.prompt,taskType:params.taskType||(params.command?'"'"'shell'"'"':'"'"'qwen'"'"'),enabled:true,runCount:0,maxRuns:params.maxRuns};this.tasks.set(id,task);this.saveTasks();if(this.isRunning)this.scheduleTask(task);return task;}removeTask(id){const task=this.tasks.get(id);if(!task)return false;const timer=this.timers.get(id);if(timer){clearTimeout(timer);this.timers.delete(id);}this.tasks.delete(id);this.saveTasks();return true;}getTask(id){return this.tasks.get(id);}getAllTasks(){return Array.from(this.tasks.values());}updateTask(id,updates){const task=this.tasks.get(id);if(!task)return undefined;const timer=this.timers.get(id);if(timer){clearTimeout(timer);this.timers.delete(id);}Object.assign(task,updates);this.saveTasks();if(this.isRunning\&\&task.enabled)this.scheduleTask(task);return task;}enableTask(id){const task=this.tasks.get(id);if(!task)return false;task.enabled=true;this.saveTasks();if(this.isRunning)this.scheduleTask(task);return true;}disableTask(id){const task=this.tasks.get(id);if(!task)return false;task.enabled=false;const timer=this.timers.get(id);if(timer){clearTimeout(timer);this.timers.delete(id);}this.saveTasks();return true;}scheduleAllTasks(){this.tasks.forEach(task=>{if(task.enabled)this.scheduleTask(task);});}scheduleTask(task){const delay=this.parseCronExpression(task.cronExpression);if(delay===null){console.error('"'"'Invalid cron for "'"'"'+task.name+'"'"': '"'"'+task.cronExpression);return;}task.nextRun=Date.now()+delay;const timer=setTimeout(async()=>{await this.executeTask(task);if(task.enabled\&\&this.isRunning)this.scheduleTask(task);},delay);this.timers.set(task.id,timer);}parseCronExpression(expr){const e=expr.trim().toLowerCase();let m;if(m=e.match(/^\\/\\*(\\d+)(s|m|h)?$/)){return this.toMs(parseInt(m[1]),m[2]||'"'"'m'"'"');}if(m=e.match(/^(\\d+)(s|m|h|d)$/)){return this.toMs(parseInt(m[1]),m[2]);}if(m=e.match(/^(\\d+)\\s+(\\d+)\\s+\\*\\s+\\*\\s+\\*$/)){return this.nextCron(parseInt(m[1]),parseInt(m[2]));}return null;}toMs(v,u){switch(u){case'"'"'s'"'"':return v*1e3;case'"'"'m'"'"':return v*60*1e3;case'"'"'h'"'"':return v*36e5;case'"'"'d'"'"':return v*864e5;default:return v*6e4;}}nextCron(min,h){const now=new Date(),t=new Date();t.setHours(h,min,0,0);if(t<=now)t.setDate(t.getDate()+1);return t.getTime()-now.getTime();}async executeTask(task){try{task.lastRun=Date.now();task.runCount++;this.saveTasks();if(task.taskType==='"'"'qwen'"'"'\&\&task.prompt\&\&this.querySubmitCallback){console.log('"'"'🤖 Qwen task: '"'"'+task.name);await this.querySubmitCallback(task.prompt);}else if(task.taskType==='"'"'shell'"'"'\&\&task.command){console.log('"'"'🔧 Shell task: '"'"'+task.name);const{execSync}=await import('"'"'node:child_process'"'"');try{console.log(execSync(task.command,{encoding:'"'"'utf8'"'"'}));}catch(e){console.error('"'"'Task failed:'"'"',e.message);}}if(task.maxRuns\&\&task.runCount>=task.maxRuns){console.log('"'"'Task "'"'"'+task.name+'"'"' reached max runs, disabling...'"'"');this.disableTask(task.id);}}catch(e){console.error('"'"'Task error "'"'"'+task.name+'"'"':',e);}}saveTasks(){if(!this.schedulesPath)return;try{const dir=dirname(this.schedulesPath);if(!existsSync(dir))mkdirSync(dir,{recursive:true});writeFileSync(this.schedulesPath,JSON.stringify(Array.from(this.tasks.values()),null,2));}catch(e){console.error('"'"'Save failed:'"'"',e);}}loadTasks(){if(!this.schedulesPath||!existsSync(this.schedulesPath))return;try{const data=JSON.parse(readFileSync(this.schedulesPath,'"'"'utf8'"'"'));this.tasks.clear();data.forEach(t=>this.tasks.set(t.id,t));}catch(e){console.error('"'"'Load failed:'"'"',e);}}};' "$CLI_PATH"
    echo "✅ 注入 SchedulerService 类"
fi

if ! grep -q 'var ScheduleTool=' "$CLI_PATH"; then
    # 在 SchedulerService 之后注入 ScheduleTool
    sed -i '/var SchedulerService=/a\
var ScheduleTool=class extends BaseDeclarativeTool{static{__name(this,"ScheduleTool");}static Name;static{this.Name=ToolNames.SCHEDULE;}config;constructor(config){const schema={type:'"'"'object'"'"',properties:{action:{type:'"'"'string'"'"',enum:['"'"'add'"'"','"'"'remove'"'"','"'"'list'"'"','"'"'enable'"'"','"'"'disable'"'"','"'"'update'"'"']},task_id:{type:'"'"'string'"'"'},name:{type:'"'"'string'"'"'},description:{type:'"'"'string'"'"'},cron_expression:{type:'"'"'string'"'"'},command:{type:'"'"'string'"'"'},prompt:{type:'"'"'string'"'"'},task_type:{type:'"'"'string'"'"',enum:['"'"'shell'"'"','"'"'qwen'"'"']},max_runs:{type:'"'"'number'"'"'}},required:['"'"'action'"'"']};super(ScheduleTool.Name,ToolDisplayNames.SCHEDULE,'"'"'Manage scheduled tasks'"'"',4,schema);this.config=config;}createInvocation(p){return new ScheduleToolInvocation(this.config,p)}};var ScheduleToolInvocation=class extends BaseToolInvocation{config;constructor(config,p){super(p);this.config=config;}getDescription(){return'"'"'Schedule: '"'"'+this.params.action;}async execute(_s){const{action}=this.params,sched=this.config.getSchedulerService();if(!sched)return{llmContent:'"'"'Scheduler unavailable'"'"',returnDisplay:'"'"'❌ Scheduler unavailable'"'"'};let r='"'"''"'"';switch(action){case'"'"'add'"'"':r=this.handleAdd(sched);break;case'"'"'remove'"'"':r=this.handleRemove(sched);break;case'"'"'list'"'"':r=this.handleList(sched);break;case'"'"'enable'"'"':r=this.handleEnable(sched);break;case'"'"'disable'"'"':r=this.handleDisable(sched);break;case'"'"'update'"'"':r=this.handleUpdate(sched);break;default:r='"'"'❌ Unknown action'"'"';}return{llmContent:r,returnDisplay:r};}handleAdd(s){const p=this.params;if(!p.name)return'"'"'❌ Name required'"'"';if(!p.cron_expression)return'"'"'❌ Cron required'"'"';if(!p.command\&\&!p.prompt)return'"'"'❌ Command or prompt required'"'"';const t=s.addTask({name:p.name,description:p.description||'"'"''"'"',cronExpression:p.cron_expression,command:p.command,prompt:p.prompt,taskType:p.task_type||(p.command?'"'"'shell'"'"':'"'"'qwen'"'"'),maxRuns:p.max_runs});return'"'"'✅ Task added: '"'"'+t.name+'"'"' (ID: '"'"'+t.id+'"'"')'"'"';}handleRemove(s){const t=s.getTask(this.params.task_id);if(!t)return'"'"'❌ Not found'"'"';s.removeTask(this.params.task_id);return'"'"'✅ Removed: '"'"'+t.name;}handleList(s){const ts=s.getAllTasks();if(!ts.length)return'"'"'📋 No tasks'"'"';return'"'"'📋 Tasks ('"'"'+ts.length+'"'"'):\\n'"'"'+ts.map((t,i)=>(i+1)+'"'"'. '"'"'+t.name+'"'"' ['"'"'+t.cronExpression+'"'"'] '"'"'+(t.enabled?'"'"'✅'"'"':'"'"'❌'"'"')).join('"'"'\\n'"'"');}handleEnable(s){return s.enableTask(this.params.task_id)?'"'"'✅ Enabled'"'"':'"'"'❌ Not found'"'"';}handleDisable(s){return s.disableTask(this.params.task_id)?'"'"'✅ Disabled'"'"':'"'"'❌ Not found'"'"';}handleUpdate(s){const t=s.getTask(this.params.task_id);if(!t)return'"'"'❌ Not found'"'"';s.updateTask(this.params.task_id,{cronExpression:this.params.cron_expression});return'"'"'✅ Updated'"'"';}};' "$CLI_PATH"
    echo "✅ 注入 ScheduleTool 类"
fi

echo ""
echo "补丁应用完成！"
echo ""
echo "验证安装:"
echo "  qwen -p \"列出所有定时任务\""
