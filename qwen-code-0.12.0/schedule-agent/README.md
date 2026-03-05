# @qwen-code/schedule-agent

Qwen Code 智能定时任务补丁工具 - 自动检测代码结构，自适应注入定时任务功能

## 特性

- 🔍 **智能检测** - 自动分析 Qwen Code 代码结构
- 🎯 **自适应注入** - 根据代码变化动态调整注入点
- 🔄 **安全备份** - 自动创建备份，支持一键恢复
- 📦 **独立运行** - 无需源码，直接修改 npm 包

## 安装

```bash
# 安装到全局
npm install -g @qwen-code/schedule-agent

# 或者从源码安装
cd schedule-agent
npm install
npm run build
npm link
```

## 用法

### 安装补丁

```bash
schedule-agent install
```

### 检查状态

```bash
schedule-agent check
```

### 卸载补丁

```bash
schedule-agent uninstall
```

### 使用定时任务

```bash
# 列出所有任务
qwen -p "列出所有定时任务"

# 添加任务
qwen -p "添加定时任务，每 5 秒执行 echo hello，名字叫 test"

# 删除任务
qwen -p "删除定时任务 test"
```

## 支持的 Cron 格式

| 格式 | 示例 | 说明 |
|------|------|------|
| 间隔 (秒) | `*/30s` | 每 30 秒 |
| 间隔 (分) | `*/5m` | 每 5 分钟 |
| 间隔 (时) | `*/1h` | 每小时 |
| Cron | `30 14 * * *` | 每天 14:30 |

## 兼容性

| Qwen Code 版本 | 状态 |
|---------------|------|
| v0.10.x | ✅ 支持 |
| v0.11.x | ✅ 支持 |
| v0.12.x+ | ⚠️ 可能需要调整 |

## 工作原理

1. **代码分析**: 扫描 `cli.js` 查找关键注入点
2. **智能注入**: 根据分析结果动态插入代码
3. **验证**: 检查所有组件是否正确安装
4. **备份**: 自动创建备份文件以便恢复

### 注入位置

- `ToolNames` - 添加 `SCHEDULE: 'schedule'`
- `ToolDisplayNames` - 添加 `SCHEDULE: 'Schedule'`
- `Config` 类 - 添加 `schedulerService` 字段
- `Config.initialize()` - 初始化 `SchedulerService`
- `createToolRegistry()` - 注册 `ScheduleTool`
- 模块定义区 - 注入 `SchedulerService` 和 `ScheduleTool` 类

## 故障排除

### 问题 1: 未找到 Qwen Code

```bash
# 确保已安装 Qwen Code
npm install -g @qwen-code/qwen-code
```

### 问题 2: 补丁安装失败

```bash
# 检查 Node.js 版本 (需要 >= 20)
node --version

# 检查 npm 包权限
npm config get prefix
```

### 问题 3: 任务不执行

```bash
# 检查任务列表
qwen -p "列出所有定时任务"

# 检查 cron 表达式格式
# 正确：*/5s, */1m, 30 14 * * *
# 错误：every 5 seconds, 0 * * *
```

## 卸载

```bash
# 使用工具卸载
schedule-agent uninstall

# 或者手动恢复备份
cp /path/to/cli.js.backup.* /path/to/cli.js
```

## 开发

```bash
# 克隆仓库
git clone <repo-url>
cd schedule-agent

# 安装依赖
npm install

# 编译
npm run build

# 运行
npm start install
```

## 许可证

Apache-2.0

## 贡献

欢迎提交 Issue 和 Pull Request！

## 相关链接

- [Qwen Code](https://github.com/QwenLM/qwen-code)
- [Schedule Tool 源码](../packages/core/src/tools/scheduleTool.ts)
- [使用文档](../SCHEDULE_TOOL_FIX.md)
