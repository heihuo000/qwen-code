# Qwen Code Schedule Agent - 完整方案总览

## 项目结构

```
schedule-agent/           # 智能补丁包 (推荐)
├── src/
│   ├── agent.ts          # 主程序 - 智能分析和注入
│   └── utils.ts          # 工具函数
├── package.json
├── tsconfig.json
└── README.md

patch-npm-version.sh      # Shell 脚本版本 (备选)
install-schedule-fix.sh   # 源码版安装脚本
SCHEDULE_TOOL_FIX.md      # 源码版修复说明
NPM_PATCH_GUIDE.md        # npm 版详细指南
```

## 方案对比

| 方案 | 适用场景 | 优点 | 缺点 |
|------|---------|------|------|
| **Schedule Agent** | npm 版本用户 | 智能检测、自适应、易维护 | 需要编译 |
| **patch-npm-version.sh** | npm 版本 (无 Node 环境) | 直接运行 | 代码复杂、难调试 |
| **源码修改** | 开发/贡献者 | 完整控制、易测试 | 需要完整源码 |

## 推荐使用方式

### 方案 1: Schedule Agent (推荐)

```bash
# 安装 Agent
cd schedule-agent
npm install
npm run build
npm link

# 使用
schedule-agent install    # 安装补丁
schedule-agent check      # 检查状态
schedule-agent uninstall  # 卸载
```

### 方案 2: 直接运行脚本

```bash
# npm 版本补丁
./patch-npm-version.sh

# 源码版本补丁
./install-schedule-fix.sh
```

## 功能使用

安装后可使用定时任务功能：

```bash
# 列出任务
qwen -p "列出所有定时任务"

# 添加任务
qwen -p "添加定时任务，每 5 秒执行 echo hello，名字叫 test"

# 管理任务
qwen -p "禁用任务 test"
qwen -p "启用任务 test"
qwen -p "删除任务 test"
```

## 智能特性

### 1. 自动检测代码结构

```typescript
function analyzeCode(content: string) {
  // 查找 ToolNames 位置
  // 查找 ToolDisplayNames 位置
  // 查找 Config 类字段
  // 查找初始化代码
  // 查找工具注册位置
}
```

### 2. 自适应注入

```typescript
// 根据检测结果动态调整
if (struct.toolNamesLine !== undefined) {
  // 注入到 ToolNames
}
if (struct.configFieldLine !== undefined) {
  // 注入 Config 字段
}
```

### 3. 版本兼容

```typescript
function checkVersionCompatibility(version: string) {
  // 检查版本是否支持
  // 提供兼容性建议
}
```

### 4. 安全检查

```typescript
function checkInstallation(pkgPath: string) {
  // 检查所有组件是否正确安装
  // 提供详细的问题报告
}
```

## 官方更新应对策略

当 Qwen Code 官方更新时：

### 自动适配（小改动）

如果只是代码位置变化，Agent 会自动找到新的注入点。

### 手动调整（大改动）

1. 运行 `schedule-agent check` 检查
2. 查看失败的具体组件
3. 更新 `src/agent.ts` 中的分析逻辑
4. 重新编译 `npm run build`

### 代码结构变化的检测

```typescript
// 检测关键代码模式
const patterns = {
  toolNames: /ToolNames\s*=\s*\{/,
  configClass: /class\s+Config/,
  toolRegistry: /createToolRegistry/,
  chatRecInit: /new\s+ChatRecordingService/,
};

// 如果模式变化，更新正则表达式即可
```

## 支持的 Cron 格式

```
*/Ns     - 每 N 秒   (如 */30s)
*/Nm     - 每 N 分钟 (如 */5m)
*/Nh     - 每 N 小时 (如 */1h)
MM HH * * * - 每天指定时间 (如 30 14 * * * = 14:30)
```

## 文件持久化

任务保存在 `~/.qwen/schedules.json`

```json
[
  {
    "id": "abc-123",
    "name": "test-task",
    "cronExpression": "*/5s",
    "command": "echo hello",
    "taskType": "shell",
    "enabled": true,
    "runCount": 10
  }
]
```

## 卸载/恢复

```bash
# 使用 Agent 卸载
schedule-agent uninstall

# 或手动恢复
cp cli.js.backup.* cli.js
```

## 技术栈

- **TypeScript** - 类型安全
- **esbuild** (可选) - 快速打包
- **Node.js >= 20** - 运行环境

## 开发计划

- [ ] MCP 服务器支持
- [ ] Web UI 管理界面
- [ ] 任务模板库
- [ ] 远程任务同步
- [ ] 任务执行日志
- [ ] 更多 Cron 格式支持

## 贡献

欢迎提交 PR 到 https://github.com/QwenLM/qwen-code

## 许可证

Apache-2.0
