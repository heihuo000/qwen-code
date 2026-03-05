/**
 * @license
 * Copyright 2025 Qwen
 * SPDX-License-Identifier: Apache-2.0
 */

/**
 * Qwen Code Schedule Agent - 智能定时任务补丁
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';
import {
  info,
  success,
  warn,
  error,
  findQwenPackage,
  detectVersion,
  checkInstallation,
  uninstall as restoreBackup,
  checkVersionCompatibility,
} from './utils.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * 补丁模板集合
 */
const patches = {
  toolNames: "\n    SCHEDULE: 'schedule',",
  toolDisplayNames: "\n    SCHEDULE: 'Schedule',",

  schedulerServiceField: (line: string) =>
    line.replace(
      /(chatRecordingService\s*=\s*void 0,?)/,
      '$1\n      schedulerService = void 0,'
    ),

  schedulerServiceInit: (line: string) =>
    line.replace(
      /(this\.chatRecordingService\s*=\s*this\.chatRecordingEnabled\s*\?\s*new ChatRecordingService\(this\)\s*:\s*void 0,?)/,
      '$1\n        this.schedulerService = new SchedulerService();'
    ),

  getSchedulerService: "}\\n      getSchedulerService\\(\\) \\{ return this\\.schedulerService; \\}",
  getSchedulerServiceAdd: `}
      getSchedulerService() { return this.schedulerService; }`,

  registerScheduleTool:
    /(registerCoreTool\(TodoWriteTool,\s*this\);)/,
  registerScheduleToolAdd:
    '$1\n        registerCoreTool(ScheduleTool, this);',

  schedulerServiceClass: `
// === SCHEDULER SERVICE (SCHEDULE-AGENT) ===
var SchedulerService=class{static{__name(this,"SchedulerService")}tasks=new Map();timers=new Map();isRunning=false;schedulesPath=null;querySubmitCallback=null;setQuerySubmitCallback(cb){this.querySubmitCallback=cb;}setSchedulesPath(p){this.schedulesPath=p;this.loadTasks();}start(){if(this.isRunning)return;this.isRunning=true;this.scheduleAllTasks();}stop(){this.isRunning=false;this.timers.forEach(t=>clearTimeout(t));this.timers.clear();}addTask(params){const id=crypto.randomUUID();const task={id,name:params.name,description:params.description||'',cronExpression:params.cronExpression,command:params.command,prompt:params.prompt,taskType:params.taskType||(params.command?'shell':'qwen'),enabled:true,runCount:0,maxRuns:params.maxRuns};this.tasks.set(id,task);this.saveTasks();if(this.isRunning)this.scheduleTask(task);return task;}removeTask(id){const task=this.tasks.get(id);if(!task)return false;const timer=this.timers.get(id);if(timer){clearTimeout(timer);this.timers.delete(id);}this.tasks.delete(id);this.saveTasks();return true;}getTask(id){return this.tasks.get(id);}getAllTasks(){return Array.from(this.tasks.values());}updateTask(id,updates){const task=this.tasks.get(id);if(!task)return undefined;const timer=this.timers.get(id);if(timer){clearTimeout(timer);this.timers.delete(id);}Object.assign(task,updates);this.saveTasks();if(this.isRunning&&task.enabled)this.scheduleTask(task);return task;}enableTask(id){const task=this.tasks.get(id);if(!task)return false;task.enabled=true;this.saveTasks();if(this.isRunning)this.scheduleTask(task);return true;}disableTask(id){const task=this.tasks.get(id);if(!task)return false;task.enabled=false;const timer=this.timers.get(id);if(timer){clearTimeout(timer);this.timers.delete(id);}this.saveTasks();return true;}scheduleAllTasks(){this.tasks.forEach(task=>{if(task.enabled)this.scheduleTask(task);});}scheduleTask(task){const delay=this.parseCronExpression(task.cronExpression);if(delay===null){console.error('Invalid cron for "'+task.name+'": '+task.cronExpression);return;}task.nextRun=Date.now()+delay;const timer=setTimeout(async()=>{await this.executeTask(task);if(task.enabled&&this.isRunning)this.scheduleTask(task);},delay);this.timers.set(task.id,timer);}parseCronExpression(expr){const e=expr.trim().toLowerCase();let m;if(m=e.match(/^\\/\\*(\\d+)(s|m|h)?$/)){return this.toMs(parseInt(m[1]),m[2]||'m');}if(m=e.match(/^(\\d+)(s|m|h|d)$/)){return this.toMs(parseInt(m[1]),m[2]);}if(m=e.match(/^(\\d+)\\s+(\\d+)\\s+\\*\\s+\\*\\s+\\*$/)){return this.nextCron(parseInt(m[1]),parseInt(m[2]));}return null;}toMs(v,u){switch(u){case's':return v*1e3;case'm':return v*60*1e3;case'h':return v*36e5;case'd':return v*864e5;default:return v*6e4;}}nextCron(min,h){const now=new Date(),t=new Date();t.setHours(h,min,0,0);if(t<=now)t.setDate(t.getDate()+1);return t.getTime()-now.getTime();}async executeTask(task){try{task.lastRun=Date.now();task.runCount++;this.saveTasks();if(task.taskType==='qwen'&&task.prompt&&this.querySubmitCallback){console.log('🤖 Qwen task: '+task.name);await this.querySubmitCallback(task.prompt);}else if(task.taskType==='shell'&&task.command){console.log('🔧 Shell task: '+task.name);const{execSync}=await import('node:child_process');try{console.log(execSync(task.command,{encoding:'utf8'}));}catch(e){console.error('Task failed:',e.message);}}if(task.maxRuns&&task.runCount>=task.maxRuns){console.log('Task "'+task.name+'" reached max runs, disabling...');this.disableTask(task.id);}}catch(e){console.error('Task error "'+task.name+'":',e);}}saveTasks(){if(!this.schedulesPath)return;try{const dir=dirname(this.schedulesPath);if(!existsSync(dir))mkdirSync(dir,{recursive:true});writeFileSync(this.schedulesPath,JSON.stringify(Array.from(this.tasks.values()),null,2));}catch(e){console.error('Save failed:',e);}}loadTasks(){if(!this.schedulesPath||!existsSync(this.schedulesPath))return;try{const data=JSON.parse(readFileSync(this.schedulesPath,'utf8'));this.tasks.clear();data.forEach(t=>this.tasks.set(t.id,t));}catch(e){console.error('Load failed:',e);}}};
`,

  scheduleTool: `
// === SCHEDULE TOOL (SCHEDULE-AGENT) ===
var ScheduleTool=class extends BaseDeclarativeTool{static{Name;static Name=ToolNames.SCHEDULE;config;constructor(config){const schema={type:'object',properties:{action:{type:'string',enum:['add','remove','list','enable','disable','update']},task_id:{type:'string'},name:{type:'string'},description:{type:'string'},cron_expression:{type:'string'},command:{type:'string'},prompt:{type:'string'},task_type:{type:'string',enum:['shell','qwen']},max_runs:{type:'number'}},required:['action']};super(ScheduleTool.Name,ToolDisplayNames.SCHEDULE,'Manage scheduled tasks',4,schema);this.config=config;}createInvocation(p){return new ScheduleToolInvocation(this.config,p)}};var ScheduleToolInvocation=class extends BaseToolInvocation{config;constructor(config,p){super(p);this.config=config;}getDescription(){return'Schedule: '+this.params.action;}async execute(_s){const{action}=this.params,sched=this.config.getSchedulerService();if(!sched)return{llmContent:'Scheduler unavailable',returnDisplay:'❌ Scheduler unavailable'};let r='';switch(action){case'add':r=this.handleAdd(sched);break;case'remove':r=this.handleRemove(sched);break;case'list':r=this.handleList(sched);break;case'enable':r=this.handleEnable(sched);break;case'disable':r=this.handleDisable(sched);break;case'update':r=this.handleUpdate(sched);break;default:r='❌ Unknown action';}return{llmContent:r,returnDisplay:r};}handleAdd(s){const p=this.params;if(!p.name)return'❌ Name required';if(!p.cron_expression)return'❌ Cron required';if(!p.command&&!p.prompt)return'❌ Command or prompt required';const t=s.addTask({name:p.name,description:p.description||'',cronExpression:p.cron_expression,command:p.command,prompt:p.prompt,taskType:p.task_type||(p.command?'shell':'qwen'),maxRuns:p.max_runs});return'✅ Task added: '+t.name+' (ID: '+t.id+')';}handleRemove(s){const t=s.getTask(this.params.task_id);if(!t)return'❌ Not found';s.removeTask(this.params.task_id);return'✅ Removed: '+t.name;}handleList(s){const ts=s.getAllTasks();if(!ts.length)return'📋 No tasks';return'📋 Tasks ('+ts.length+'):\\n'+ts.map((t,i)=>(i+1)+'. '+t.name+' ['+t.cronExpression+'] '+(t.enabled?'✅':'❌')).join('\\n');}handleEnable(s){return s.enableTask(this.params.task_id)?'✅ Enabled':'❌ Not found';}handleDisable(s){return s.disableTask(this.params.task_id)?'✅ Disabled':'❌ Not found';}handleUpdate(s){const t=s.getTask(this.params.task_id);if(!t)return'❌ Not found';s.updateTask(this.params.task_id,{cronExpression:this.params.cron_expression});return'✅ Updated';}};
`,
};

/**
 * 智能分析代码结构
 */
function analyzeCode(content: string) {
  const lines = content.split('\n');
  const result: Record<string, any> = {};

  // 查找关键位置
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // ToolNames
    if (line.includes("SHELL: 'run_shell_command'")) {
      result.toolNamesLine = i;
    }

    // ToolDisplayNames
    if (line.includes("SHELL: 'Shell'")) {
      result.toolDisplayNamesLine = i;
    }

    // chatRecordingService 字段
    if (line.includes('chatRecordingService') && line.includes('void 0')) {
      result.configFieldLine = i;
    }

    // ChatRecordingService 初始化
    if (line.includes('new ChatRecordingService(this)')) {
      result.configInitLine = i;
    }

    // TodoWriteTool 注册
    if (line.includes('registerCoreTool(TodoWriteTool')) {
      result.toolRegistryLine = i;
    }

    // getChatRecordingService 方法
    if (line.includes('getChatRecordingService()')) {
      result.getMethodLine = i;
    }
  }

  // 查找注入 SchedulerService 类的位置（在 __esm 定义之后）
  const lastEsmIndex = content.lastIndexOf('var init_');
  if (lastEsmIndex !== -1) {
    result.injectLine = content.substring(0, lastEsmIndex).split('\n').length;
  }

  return result;
}

/**
 * 应用补丁
 */
function applyPatch(content: string): string {
  const lines = content.split('\n');
  const struct = analyzeCode(content);
  let modified = 0;

  // 1. 添加 SCHEDULE 到 ToolNames
  if (struct.toolNamesLine !== undefined) {
    const i = struct.toolNamesLine;
    if (!lines[i].includes("SCHEDULE:")) {
      lines[i] = lines[i].replace(/(SHELL:\s*'run_shell_command')/, "$1," + patches.toolNames);
      modified++;
      success('Added SCHEDULE to ToolNames');
    }
  }

  // 2. 添加 SCHEDULE 到 ToolDisplayNames
  if (struct.toolDisplayNamesLine !== undefined) {
    const i = struct.toolDisplayNamesLine;
    if (!lines[i].includes("SCHEDULE:")) {
      lines[i] = lines[i].replace(/(SHELL:\s*'Shell')/, "$1," + patches.toolDisplayNames);
      modified++;
      success('Added SCHEDULE to ToolDisplayNames');
    }
  }

  // 3. 添加 schedulerService 字段
  if (struct.configFieldLine !== undefined) {
    const i = struct.configFieldLine;
    if (!lines[i].includes('schedulerService')) {
      lines[i] = patches.schedulerServiceField(lines[i]);
      modified++;
      success('Added schedulerService field');
    }
  }

  // 4. 添加 schedulerService 初始化
  if (struct.configInitLine !== undefined) {
    const i = struct.configInitLine;
    if (!lines[i].includes('schedulerService')) {
      lines[i] = patches.schedulerServiceInit(lines[i]);
      modified++;
      success('Added schedulerService initialization');
    }
  }

  // 5. 添加 getSchedulerService 方法
  if (struct.getMethodLine !== undefined) {
    const i = struct.getMethodLine;
    const methodExists = content.includes('getSchedulerService()');
    if (!methodExists) {
      lines[i] = lines[i].replace('}', patches.getSchedulerServiceAdd);
      modified++;
      success('Added getSchedulerService method');
    }
  }

  // 6. 注册 ScheduleTool
  if (struct.toolRegistryLine !== undefined) {
    const i = struct.toolRegistryLine;
    if (!content.includes('registerCoreTool(ScheduleTool')) {
      lines[i] = lines[i].replace(patches.registerScheduleTool, patches.registerScheduleToolAdd);
      modified++;
      success('Registered ScheduleTool');
    }
  }

  // 7. 注入 SchedulerService 类
  if (!content.includes('var SchedulerService')) {
    if (struct.injectLine !== undefined) {
      lines.splice(struct.injectLine, 0, patches.schedulerServiceClass);
      modified++;
      success('Injected SchedulerService class');
    }
  }

  // 8. 注入 ScheduleTool 类
  if (!content.includes('var ScheduleTool=')) {
    if (struct.injectLine !== undefined) {
      lines.splice(struct.injectLine, 0, patches.scheduleTool);
      modified++;
      success('Injected ScheduleTool class');
    }
  }

  return lines.join('\n');
}

/**
 * 安装命令
 */
function cmdInstall() {
  info('╔════════════════════════════════════════════╗');
  info('║  Schedule Agent - 安装补丁                 ║');
  info('╚════════════════════════════════════════════╝\n');

  const pkgPath = findQwenPackage();
  if (!pkgPath) {
    error('未找到 Qwen Code，请运行：npm install -g @qwen-code/qwen-code');
    process.exit(1);
  }

  const version = detectVersion(pkgPath);
  info(`Qwen Code 路径：${pkgPath}`);
  info(`版本：${version}`);

  // 版本兼容性检查
  const compat = checkVersionCompatibility(version);
  compat.warnings.forEach(w => warn(w));

  const cliPath = join(pkgPath, 'cli.js');
  const content = readFileSync(cliPath, 'utf8');

  // 检查是否已安装
  const check = checkInstallation(pkgPath);
  if (check.installed) {
    warn('Schedule Tool 已经安装！');
    return;
  }

  info(`发现 ${check.issues.length} 个缺失的组件`);

  // 创建备份
  const backupPath = `${cliPath}.backup.${Date.now()}`;
  writeFileSync(backupPath, content);
  success(`备份：${backupPath}`);

  // 应用补丁
  info('应用补丁...');
  try {
    const patched = applyPatch(content);
    writeFileSync(cliPath, patched);
    success('补丁应用成功！');
  } catch (err: any) {
    error('补丁失败：' + err.message);
    writeFileSync(cliPath, content);
    process.exit(1);
  }

  // 验证
  const newCheck = checkInstallation(pkgPath);
  if (newCheck.installed) {
    success('\n✅ Schedule Tool 安装成功！');
    console.log('\n使用方法:');
    console.log('  qwen -p "列出所有定时任务"');
    console.log('  qwen -p "添加定时任务，每 5 秒执行 echo hello，名字叫 test"');
  } else {
    warn('\n⚠️  安装可能不完整，缺失:');
    newCheck.issues.forEach(i => console.log('  - ' + i));
  }
}

/**
 * 卸载命令
 */
function cmdUninstall() {
  info('╔════════════════════════════════════════════╗');
  info('║  Schedule Agent - 卸载补丁                 ║');
  info('╚════════════════════════════════════════════╝\n');

  const pkgPath = findQwenPackage();
  if (!pkgPath) {
    error('未找到 Qwen Code');
    process.exit(1);
  }

  const cliPath = join(pkgPath, 'cli.js');
  const backupDir = dirname(cliPath);

  // 查找最新备份
  try {
    const backups = execSync(`ls -t ${backupDir}/cli.js.backup.* 2>/dev/null | head -1`, { encoding: 'utf8' }).trim();
    if (!backups || !existsSync(backups)) {
      error('未找到备份文件');
      process.exit(1);
    }

    info(`恢复备份：${backups}`);
    writeFileSync(cliPath, readFileSync(backups));
    success('卸载成功！');
  } catch {
    error('未找到备份文件，无法卸载');
    process.exit(1);
  }
}

/**
 * 检查命令
 */
function cmdCheck() {
  info('╔════════════════════════════════════════════╗');
  info('║  Schedule Agent - 检查状态                 ║');
  info('╚════════════════════════════════════════════╝\n');

  const pkgPath = findQwenPackage();
  if (!pkgPath) {
    error('未找到 Qwen Code');
    process.exit(1);
  }

  const version = detectVersion(pkgPath);
  const check = checkInstallation(pkgPath);

  info(`Qwen Code: ${pkgPath}`);
  info(`版本：${version}`);
  console.log();

  if (check.installed) {
    success('✅ Schedule Tool 已安装');
  } else {
    warn('❌ Schedule Tool 未安装');
    console.log('\n缺失组件:');
    check.issues.forEach(i => console.log('  - ' + i));
    console.log('\n运行以下命令安装:');
    console.log('  schedule-agent install');
  }
}

/**
 * 主函数
 */
function main() {
  const args = process.argv.slice(2);
  const cmd = args[0] || 'help';

  switch (cmd) {
    case 'install':
      cmdInstall();
      break;
    case 'uninstall':
      cmdUninstall();
      break;
    case 'check':
      cmdCheck();
      break;
    case 'help':
    default:
      console.log(`
Qwen Code Schedule Agent - 智能定时任务补丁

用法：schedule-agent <command>

命令:
  install    安装 Schedule Tool 补丁
  uninstall  卸载补丁 (恢复备份)
  check      检查安装状态
  help       显示帮助

示例:
  schedule-agent install
  schedule-agent check
  qwen -p "列出所有定时任务"
`);
  }
}

main();
