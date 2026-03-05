# Qwen Code - 定时任务功能扩展

> 🤖 基于 Qwen Code 的定时任务功能扩展，支持自动执行 shell 命令和 AI 任务

[![npm version](https://img.shields.io/npm/v/@qwen-code/qwen-code.svg)](https://www.npmjs.com/package/@qwen-code/qwen-code)
[![License](https://img.shields.io/github/license/QwenLM/qwen-code.svg)](./LICENSE)

---

## 📋 功能特性

- ⏰ **定时任务调度** - 支持 cron 表达式和简单间隔时间
- 🤖 **AI 任务触发** - 定时向 AI 提问获取信息
- 🔧 **Shell 命令执行** - 定时执行任意 shell 命令
- 📊 **任务管理** - 添加、删除、启用、禁用任务
- 💾 **持久化存储** - 任务数据自动保存到本地

---

## 🚀 快速开始

### 安装

```bash
# 方式 1: 使用 npm link 安装本地源码
git clone https://github.com/heihuo000/qwen-code.git
cd qwen-code
npm install
npm run build
npm link

# 方式 2: 直接使用源码运行
npm start
```

### 使用示例

```bash
# 列出所有定时任务
qwen -p "列出所有定时任务"

# 添加定时任务 - 每 30 秒执行 shell 命令
qwen -p "添加定时任务：每 30 秒执行 echo hello，名字叫 test"

# 添加定时任务 - 每分钟 AI 提醒
qwen -p "添加定时任务：每分钟提醒我喝水，名字叫喝水提醒"

# 禁用任务
qwen -p "禁用任务 test"

# 启用任务
qwen -p "启用任务 test"

# 删除任务
qwen -p "删除任务 test"
```

---

## 📖 文档

| 文档 | 说明 |
|------|------|
| [NPM_INSTALL_GUIDE.md](./NPM_INSTALL_GUIDE.md) | npm 源码安装完整指南 |
| [SCHEDULE_PATCH_GUIDE.md](./SCHEDULE_PATCH_GUIDE.md) | 定时任务补丁修改指南 |

---

## 📝 Cron 表达式格式

| 格式 | 示例 | 含义 |
|------|------|------|
| 间隔表达式 | `*/30s` | 每 30 秒 |
| 间隔表达式 | `*/5m` | 每 5 分钟 |
| 简单间隔 | `30s` | 每 30 秒 |
| 简单间隔 | `1h` | 每小时 |
| Cron 格式 | `30 8 * * *` | 每天 8:30 |
| Cron 格式 | `0 * * * *` | 每小时整点 |

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

## 📦 项目结构

```
qwen-code/
├── packages/
│   ├── core/                    # 核心模块
│   │   ├── src/
│   │   │   ├── services/
│   │   │   │   └── schedulerService.ts    # 定时任务服务
│   │   │   └── tools/
│   │   │       └── scheduleTool.ts        # 定时工具
│   │   └── ...
│   └── cli/                     # CLI 前端
├── docs/                        # 项目文档
├── NPM_INSTALL_GUIDE.md         # 安装指南
├── SCHEDULE_PATCH_GUIDE.md      # 补丁指南
└── README.md                    # 本文件
```

---

## 📄 许可证

[Apache License 2.0](./LICENSE)

---

## 🔗 相关链接

- [Qwen Code 官方仓库](https://github.com/QwenLM/qwen-code)
- [Qwen Code 官方文档](https://qwenlm.github.io/qwen-code-docs/zh/users/overview)
