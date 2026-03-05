# Qwen Code - 定时任务补丁版

> 🤖 基于 Qwen Code 的定时任务功能扩展
> 📦 支持自动执行 shell 命令和 AI 任务

[![npm version](https://img.shields.io/npm/v/@qwen-code/qwen-code.svg)](https://www.npmjs.com/package/@qwen-code/qwen-code)
[![License](https://img.shields.io/github/license/QwenLM/qwen-code.svg)](./LICENSE)

---

## 📌 关于本项目

本仓库是 [Qwen Code](https://github.com/QwenLM/qwen-code) 的复刻版本，主要添加了**定时任务功能**。

- **官方仓库**: https://github.com/QwenLM/qwen-code
- **官方文档**: https://qwenlm.github.io/qwen-code-docs/zh/users/overview/
- **本仓库**: https://github.com/heihuo000/qwen-code

> 💡 **提示**: 基础使用方法请参阅 [官方文档](https://qwenlm.github.io/qwen-code-docs/zh/users/overview/)，本文档仅介绍定时任务补丁相关内容。

---

## ✨ 定时任务功能

### 功能特性

- ⏰ **定时调度** - 支持 cron 表达式和简单间隔时间
- 🤖 **AI 任务** - 定时向 AI 提问获取信息
- 🔧 **Shell 命令** - 定时执行任意 shell 命令
- 📊 **任务管理** - 添加、删除、启用、禁用任务
- 💾 **持久化存储** - 任务数据自动保存

### 使用示例

```bash
# 列出所有定时任务
qwen -p "列出所有定时任务"

# 添加定时任务 - 每 30 秒执行 shell 命令
qwen -p "添加定时任务：每 30 秒执行 echo hello，名字叫 test"

# 添加定时任务 - 每分钟 AI 提醒
qwen -p "添加定时任务：每分钟提醒我喝水，名字叫喝水提醒"

# 禁用/启用任务
qwen -p "禁用任务 test"
qwen -p "启用任务 test"

# 删除任务
qwen -p "删除任务 test"
```

### Cron 表达式格式

| 格式 | 示例 | 含义 |
|------|------|------|
| 间隔表达式 | `*/30s` | 每 30 秒 |
| 间隔表达式 | `*/5m` | 每 5 分钟 |
| 简单间隔 | `30s` | 每 30 秒 |
| 简单间隔 | `1h` | 每小时 |
| Cron 格式 | `30 8 * * *` | 每天 8:30 |
| Cron 格式 | `0 * * * *` | 每小时整点 |

---

## 📖 文档索引

### 补丁相关文档

| 文档 | 说明 |
|------|------|
| [官方更新融合指南.md](./官方更新融合指南.md) | 🔄 官方更新融合指南（推荐优先阅读） |
| [补丁速查表.md](./补丁速查表.md) | 📋 补丁融合速查表 |
| [NPM 安装指南.md](./NPM 安装指南.md) | 📦 npm 源码安装指南 |
| [定时任务补丁指南.md](./定时任务补丁指南.md) | 🔧 补丁修改详细指南 |
| [定时任务 Agent 说明.md](./定时任务 Agent 说明.md) | 🤖 Schedule Agent 说明 |

### 官方文档

| 文档 | 说明 |
|------|------|
| [官方使用指南](https://qwenlm.github.io/qwen-code-docs/zh/users/overview/) | 基础使用方法 |
| [官方配置说明](https://qwenlm.github.io/qwen-code-docs/zh/users/configuration/) | 配置模型和 API |
| [官方命令参考](https://qwenlm.github.io/qwen-code-docs/zh/users/features/commands/) | 命令和快捷键 |

---

## 🚀 快速开始

### 方式一：使用 npm link（推荐）

```bash
# 克隆本仓库
git clone https://github.com/heihuo000/qwen-code.git
cd qwen-code

# 安装依赖并构建
npm install
npm run build

# 链接到全局
npm link

# 测试定时任务功能
qwen -p "列出所有定时任务"
```

### 方式二：直接运行源码

```bash
cd qwen-code
npm start -- -p "列出所有定时任务"
```

---

## 🔄 官方更新融合

当官方发布新版本时，使用以下方法融合更新：

```bash
cd /data/data/com.termux/files/home/qwen-code-0.12.0

# 运行自动融合脚本
./update-and-patch.sh
```

详细步骤请参阅 [官方更新融合指南.md](./官方更新融合指南.md)

---

## 📁 项目文件结构

```
qwen-code/
├── packages/
│   └── core/
│       └── src/
│           ├── services/
│           │   └── schedulerService.ts    # ⏰ 定时任务服务（新增）
│           └── tools/
│               └── scheduleTool.ts        # ⏰ 定时工具（新增）
│
├── schedule-agent/                        # 🤖 补丁工具目录
│   └── src/
│       ├── agent.ts                       # 补丁主程序
│       └── utils.ts                       # 工具函数
│
├── README.md                              # 📖 本文件
├── 官方更新融合指南.md                  # 🔄 官方更新融合指南
├── 补丁速查表.md                     # 📋 速查表
├── NPM 安装指南.md                   # 📦 安装指南
├── 定时任务补丁指南.md                # 🔧 补丁修改指南
├── 定时任务 Agent 说明.md               # 🤖 Agent 说明
└── update-and-patch.sh                    # 🔄 自动融合脚本
```

---

## 🛠️ 开发

```bash
# 安装依赖
npm install

# 构建项目
npm run build

# 运行测试
npm test

# 开发模式
npm run dev
```

---

## 📄 许可证

[Apache License 2.0](./LICENSE)

---

## 🔗 相关链接

- [Qwen Code 官方仓库](https://github.com/QwenLM/qwen-code)
- [Qwen Code 官方文档](https://qwenlm.github.io/qwen-code-docs/zh/users/overview/)
- [本仓库地址](https://github.com/heihuo000/qwen-code)
