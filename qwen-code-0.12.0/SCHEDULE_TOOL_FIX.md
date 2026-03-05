# Qwen Code Schedule Tool 修复补丁

## 问题描述

原始 `scheduleTool.ts` 文件存在以下问题：

1. **构造函数参数顺序错误**: `super()` 调用时参数顺序为 `(name, displayName, schema, description)`，但正确的顺序应该是 `(name, displayName, description, kind, schema)`

2. **缺少 `kind` 参数**: 导致 API 报错：
   ```
   API Error: <400> InternalError.Algo.InvalidParameter:
   Input should be a valid string: parameters.tools.11.function.description
   ```

3. **实现模式错误**: 没有正确继承 `BaseDeclarativeTool`，缺少 `createInvocation` 方法

4. **重复函数**: `config.ts` 中 `getSchedulerService()` 被定义了两次

## 快速安装（推荐）

### 方法一：使用安装脚本

```bash
# 进入 qwen-code 源码目录
cd /path/to/qwen-code

# 运行安装脚本
./install-schedule-fix.sh

# 或者指定目标目录
./install-schedule-fix.sh /path/to/qwen-code/packages/core
```

### 方法二：手动复制文件

```bash
# 1. 复制修复后的 scheduleTool.ts
cp /path/to/patch/packages/core/src/tools/scheduleTool.ts \
   /path/to/qwen-code/packages/core/src/tools/scheduleTool.ts

# 2. 删除 config.ts 中的重复函数（第 1655-1657 行）
# 使用编辑器手动删除，或运行：
sed -i '1654,1657d' /path/to/qwen-code/packages/core/src/config/config.ts

# 3. 重新构建
npm run build --workspace=packages/core
```

### 方法三：应用补丁文件

```bash
cd /path/to/qwen-code
git apply /path/to/patch/schedule-tool-fix.patch
npm run build
```

## 验证修复

```bash
# 测试列出任务
npm start -- -p "列出所有定时任务"

# 测试添加任务
npm start -- -p "添加定时任务，每 5 秒执行 echo test，名字叫 mytask"

# 测试删除任务
npm start -- -p "删除定时任务 mytask"
```

## 对于 npm 安装的包

如果你是通过 npm 安装的 Qwen Code：

```bash
# 1. 找到安装位置
npm list -g @qwen-code/qwen-code
# 或
npm list @qwen-code/qwen-code

# 2. 直接修改 dist 文件（不推荐，更新后会丢失）
# 路径通常是：
# /path/to/node_modules/@qwen-code/qwen-code-core/dist/src/tools/scheduleTool.js

# 3. 或者 fork 仓库并安装你的版本
git clone https://github.com/YOUR_USERNAME/qwen-code.git
cd qwen-code
npm install
npm link
```

## 修改范围

| 文件 | 修改类型 | 行数变化 |
|------|---------|---------|
| `scheduleTool.ts` | 完全重写 | ~278 行 |
| `config.ts` | 删除重复 | -3 行 |

## 恢复原始版本

```bash
# 如果使用了安装脚本，会有备份文件
cp /path/to/backup/scheduleTool.ts.backup.* \
   /path/to/qwen-code/packages/core/src/tools/scheduleTool.ts

# 重新构建
npm run build --workspace=packages/core
```

## 技术说明

修复的关键点：

1. **正确的继承模式**:
   ```typescript
   // 创建 Invocation 类
   class ScheduleToolInvocation extends BaseToolInvocation<...> {
     async execute(_signal: AbortSignal): Promise<ToolResult> {
       // 执行逻辑
     }
   }

   // 工具类实现 createInvocation
   export class ScheduleTool extends BaseDeclarativeTool<...> {
     protected createInvocation(params: ...) {
       return new ScheduleToolInvocation(this.config, params);
     }
   }
   ```

2. **正确的 super() 调用**:
   ```typescript
   super(
     ScheduleTool.Name,           // name
     ToolDisplayNames.SCHEDULE,   // displayName
     description,                 // description (字符串)
     Kind.Other,                  // kind
     schema,                      // parameterSchema
   );
   ```

## 更新策略

由于官方会频繁更新，建议：

1. **订阅上游更新**: 关注 qwen-code 仓库的 release
2. **保留补丁文件**: 每次更新后重新应用补丁
3. **贡献给上游**: 提交 PR 让修复合并到主仓库

## 联系方式

如有问题，请提交 issue 或讨论。
