# NPM 源码安装指南 - 定时任务功能

## 概述

本文档说明如何通过修改源码并重新安装的方式来使用定时任务功能。

> **注意**: Qwen Code 源码已经完整集成了定时任务功能 (`SchedulerService` 和 `ScheduleTool`)，只需要正确编译安装即可使用。

---

## 方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| 源码修改后安装 | 永久保留功能，更新可控 | 需要编译时间 | ⭐⭐⭐⭐⭐ |
| 直接修改 npm 包 | 快速见效 | 更新后丢失 | ⭐⭐⭐ |
| Termux 打包版 | 无需操作 | 无法注入补丁 | ❌ |

---

## 方案一：本地源码编译安装（推荐）

### 步骤 1: 确认源码状态

定时任务功能已经集成在以下文件中：

```
packages/core/src/services/schedulerService.ts    # 定时任务服务
packages/core/src/tools/scheduleTool.ts           # 定时工具
packages/core/src/tools/tool-names.ts             # 工具名称定义
packages/core/src/config/config.ts                # 工具注册
```

### 步骤 2: 编译项目

```bash
cd /data/data/com.termux/files/home/qwen-code-0.12.0

# 安装依赖（如果还没安装）
npm install

# 构建项目
npm run build

# 或者构建全部（包含沙盒和 VSCode）
npm run build:all
```

### 步骤 3: 全局安装

```bash
# 使用 npm link 进行本地链接（开发模式）- 推荐
npm link

# 或者全局安装当前目录（不推荐，会触发 prepare 脚本）
# npm install -g .
```

### 步骤 4: 验证安装

```bash
# 检查版本
qwen --version

# 测试定时任务功能
qwen -p "列出所有定时任务"

# 添加测试任务
qwen -p "添加一个定时任务，每 30 秒执行 echo hello，名字叫 test"
```

### 验证结果示例

```
$ qwen -p "列出所有定时任务"
当前系统中有 **1 个定时任务**：

| 任务名称 | ID | 周期 | 状态 | 已执行次数 | 下次执行时间 |
|---------|-----|------|------|-----------|-------------|
| 喝水提醒 | `b10e8ca4-5bc0-4f3f-8e26-eeb991d70a4f` | 1 分钟 | ❌ 已禁用 | 1 次 | 2026/3/5 21:22:42 |

$ qwen -p "添加一个定时任务，每 30 秒执行 echo hello，名字叫 test30"
定时任务已创建成功：
- **名称**: test30
- **频率**: 每 30 秒
- **命令**: echo hello
- **任务 ID**: 4d8ce60f-e6df-46c9-8dee-94d7a3198496
```

---

## 方案二：直接修改已安装的 npm 包

如果不想重新编译，可以直接修改已安装的 npm 包。

### 步骤 1: 找到 npm 包路径

```bash
# 查找全局 npm 根目录
NPM_ROOT=$(npm root -g)
echo $NPM_ROOT

# cli.js 路径
CLI_PATH="$NPM_ROOT/@qwen-code/qwen-code/cli.js"
echo $CLI_PATH
```

### 步骤 2: 备份原始文件

```bash
cp "$CLI_PATH" "$CLI_PATH.backup.$(date +%Y%m%d_%H%M%S)"
```

### 步骤 3: 应用补丁

由于 npm 包的 cli.js 是构建后的文件，你需要：

1. 在源码中修改功能
2. 重新运行 `npm run build`
3. 复制构建产物到 npm 包目录

或者直接使用我们已经创建的补丁脚本：

```bash
# 如果补丁脚本存在
./apply-schedule-patch.sh
```

### 步骤 4: 覆盖 Termux 的 qwen 命令（如果需要）

Termux 的 `qwen` 命令可能指向独立的打包版本：

```bash
# 备份 Termux 原版
cp /data/data/com.termux/files/usr/bin/qwen /data/data/com.termux/files/usr/bin/qwen.termux.backup

# 复制 npm 版 cli.js 覆盖
cp "$CLI_PATH" /data/data/com.termux/files/usr/bin/qwen
chmod +x /data/data/com.termux/files/usr/bin/qwen
```

---

## 定时任务使用指南

### 基本用法

```bash
# 列出所有任务
qwen -p "列出所有定时任务"

# 添加任务 - Shell 命令
qwen -p "添加定时任务：每 5 秒执行 echo hello，名字叫 test"

# 添加任务 - Qwen AI
qwen -p "添加定时任务：每分钟询问当前时间，名字叫时间提醒"

# 禁用任务
qwen -p "禁用任务 test"

# 启用任务
qwen -p "启用任务 test"

# 删除任务
qwen -p "删除任务 test"
```

### Cron 表达式格式

支持的格式：

| 格式 | 示例 | 含义 |
|------|------|------|
| 间隔表达式 | `*/30s` | 每 30 秒 |
| 间隔表达式 | `*/5m` | 每 5 分钟 |
| 间隔表达式 | `*/1h` | 每小时 |
| 简单间隔 | `30s` | 每 30 秒 |
| 简单间隔 | `5m` | 每 5 分钟 |
| 简单间隔 | `1h` | 每小时 |
| 简单间隔 | `1d` | 每天 |
| Cron 格式 | `30 8 * * *` | 每天 8:30 |
| Cron 格式 | `0 * * * *` | 每小时整点 |

### 任务文件存储

定时任务数据存储在：

```
~/.qwen/schedules.json
```

---

## 常见问题

### Q1: 为什么 `qwen` 命令不识别定时任务？

**原因**: Termux 的 `qwen` 命令可能是独立打包的版本，不是 npm 版。

**解决**:
```bash
# 检查 qwen 命令来源
which qwen
ls -la $(which qwen)

# 如果是 Termux 打包版，需要覆盖
cp "$(npm root -g)/@qwen-code/qwen-code/cli.js" /data/data/com.termux/files/usr/bin/qwen
```

### Q2: 交互式界面不显示 Schedule 工具？

**原因**: AI 模型可能不知道如何关联用户输入和 ScheduleTool。

**解决**: 直接使用明确的命令：
```bash
qwen -p "使用 Schedule 工具列出任务"
```

### Q3: 更新 Qwen Code 后功能丢失？

**原因**: `npm update` 或 `npm install -g` 会覆盖修改。

**解决**:
1. 保留源码修改
2. 更新后重新运行 `npm run build && npm link`

---

## 卸载/恢复

### 恢复 npm 包原版

```bash
# 重新安装原版
npm install -g @qwen-code/qwen-code --force
```

### 恢复 Termux 原版

```bash
# 恢复备份
cp /data/data/com.termux/files/usr/bin/qwen.termux.backup /data/data/com.termux/files/usr/bin/qwen
```

---

## 技术细节

### 核心组件

1. **SchedulerService** (`packages/core/src/services/schedulerService.ts`)
   - 任务管理（增删改查）
   - 定时器调度
   - Cron 表达式解析
   - 任务持久化

2. **ScheduleTool** (`packages/core/src/tools/scheduleTool.ts`)
   - 工具定义和参数验证
   - 执行调度操作

3. **工具注册** (`packages/core/src/config/config.ts`)
   ```typescript
   import { SchedulerService } from '../services/schedulerService.js';
   import { ScheduleTool } from '../tools/scheduleTool.js';

   // 初始化
   this.schedulerService = new SchedulerService();

   // 注册工具
   registerCoreTool(ScheduleTool, this);
   ```

### 构建产物

构建后的文件位于：
```
dist/cli.js              # 主 CLI 入口
packages/core/dist/      # 核心模块
```

---

## 参考文件

- [SCHEDULE_PATCH_GUIDE.md](./SCHEDULE_PATCH_GUIDE.md) - 补丁修改详细指南
- [schedule-agent/](./schedule-agent/) - 补丁工具源码
