# Qwen Code Schedule Agent 使用说明

## 快速开始

### 1. 安装

```bash
# 从源码安装
cd schedule-agent
npm install
npm run build
npm link

# 或者从 tarball 安装
npm install -g ./qwen-code-schedule-agent-*.tgz
```

### 2. 使用

```bash
# 检查状态
schedule-agent check

# 安装补丁
schedule-agent install

# 卸载补丁
schedule-agent uninstall
```

### 3. 测试定时任务

```bash
qwen -p "列出所有定时任务"
qwen -p "添加定时任务，每 5 秒执行 echo hello，名字叫 test"
```

## 发布流程

### 本地打包测试

```bash
./pack.sh
```

生成 `qwen-code-schedule-agent-1.0.0.tgz`

### 发布到 npm

```bash
# 登录 npm
npm login

# 发布（公开包）
npm publish --access public
```

### 版本号管理

修改 `package.json` 中的 `version` 字段：

- 补丁修复：`1.0.0` → `1.0.1`
- 新功能：`1.0.0` → `1.1.0`
- 破坏性变更：`1.0.0` → `2.0.0`

## 包内容

```
@qwen-code/schedule-agent/
├── dist/
│   ├── agent.js        # 主程序
│   ├── utils.js        # 工具函数
│   └── *.d.ts          # TypeScript 类型定义
├── package.json
├── LICENSE
└── README.md
```

## 系统要求

- Node.js >= 20.0.0
- Qwen Code v0.10.x 或更高版本

## 故障排除

### 问题：command not found: schedule-agent

```bash
# 检查 npm 全局路径
npm config get prefix

# 确保全局 bin 目录在 PATH 中
export PATH=$(npm config get prefix)/bin:$PATH
```

### 问题：补丁安装失败

```bash
# 检查 Qwen Code 是否已安装
npm list -g @qwen-code/qwen-code

# 重新安装 Qwen Code
npm install -g @qwen-code/qwen-code

# 再次尝试
schedule-agent install
```

### 问题：任务不执行

```bash
# 检查任务列表
qwen -p "列出所有定时任务"

# 检查 cron 表达式格式
# 正确：*/5s, */1m, 0 * * * *
# 错误：every 5 seconds
```

## 卸载

```bash
# 使用工具卸载
schedule-agent uninstall

# 或手动恢复
cp /path/to/cli.js.backup.* /path/to/cli.js

# 卸载 agent
npm uninstall -g @qwen-code/schedule-agent
```

## 开发

```bash
# 克隆仓库
cd schedule-agent

# 安装依赖
npm install

# 编译
npm run build

# 测试
npm run check
```

## 贡献指南

1. Fork 仓库
2. 创建特性分支
3. 提交变更
4. 推送到分支
5. 创建 Pull Request

## 许可证

Apache-2.0
