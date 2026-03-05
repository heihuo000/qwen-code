# 官方更新补丁融合指南

> 当 Qwen Code 官方发布新版本时，使用本指南融合更新并保留定时任务功能

---

## 📋 目录

1. [快速开始](#快速开始)
2. [方案对比](#方案对比)
3. [方案一：自动融合脚本](#方案一自动融合脚本)
4. [方案二：手动融合](#方案二手动融合)
5. [常见问题](#常见问题)

---

## 快速开始

```bash
# 拉取官方更新并自动重新应用补丁
cd /data/data/com.termux/files/home/qwen-code-0.12.0
./update-and-patch.sh
```

---

## 方案对比

| 方案 | 适用场景 | 难度 | 风险 |
|------|----------|------|------|
| 自动融合脚本 | 常规更新 | ⭐ 简单 | 低 |
| 手动融合 | 重大版本更新/冲突 | ⭐⭐⭐ 复杂 | 中 |
| 重新安装补丁 | 补丁失效 | ⭐⭐ 中等 | 低 |

---

## 方案一：自动融合脚本

### 步骤

```bash
# 1. 进入项目目录
cd /data/data/com.termux/files/home/qwen-code-0.12.0

# 2. 运行自动融合脚本
chmod +x update-and-patch.sh
./update-and-patch.sh

# 3. 验证功能
npm run build
npm start -- -p "列出所有定时任务"

# 4. 推送到 GitHub（如果需要）
git push -f origin master
```

### 脚本功能

1. ✅ 自动创建备份
2. ✅ 拉取官方更新
3. ✅ 暂存本地修改
4. ✅ 合并官方更新
5. ✅ 重新应用定时任务补丁
6. ✅ 恢复本地修改

---

## 方案二：手动融合

### 步骤 1: 拉取官方更新

```bash
cd /data/data/com.termux/files/home/qwen-code-0.12.0

# 暂存当前修改
git stash push -m "schedule-patch-backup"

# 拉取更新
git fetch origin master
git merge origin/master
```

### 步骤 2: 检查核心文件

确保以下文件存在且内容正确：

```
packages/core/src/services/schedulerService.ts    # 定时任务服务
packages/core/src/tools/scheduleTool.ts           # 定时工具
packages/core/src/tools/tool-names.ts             # 包含 SCHEDULE 定义
packages/core/src/config/config.ts                # 导入和注册
```

### 步骤 3: 修复 config.ts

确保 `packages/core/src/config/config.ts` 包含：

```typescript
// 导入部分（约第 40-60 行）
import { SchedulerService } from '../services/schedulerService.js';
import { ScheduleTool } from '../tools/scheduleTool.js';

// 类属性声明（约第 200 行）
private schedulerService?: SchedulerService;

// 初始化（约第 300 行）
this.schedulerService = new SchedulerService();

// 工具注册（约第 400 行）
registerCoreTool(ScheduleTool, this);
```

### 步骤 4: 修复 tool-names.ts

确保 `packages/core/src/tools/tool-names.ts` 包含：

```typescript
export const ToolNames = {
  // ... 其他工具
  SCHEDULE: 'schedule',
} as const;

export const ToolDisplayNames = {
  // ... 其他工具
  SCHEDULE: 'Schedule',
} as const;
```

### 步骤 5: 恢复本地修改

```bash
# 恢复之前暂存的修改
git stash pop

# 解决可能的冲突
git mergetool  # 或使用你喜欢的合并工具
```

### 步骤 6: 构建和测试

```bash
# 重新构建
npm run build

# 测试功能
npm start -- -p "列出所有定时任务"
```

---

## 方案三：使用补丁文件

如果有保存的补丁文件：

```bash
# 应用补丁
git apply schedule-tool-fix.patch

# 或者使用我们的补丁脚本
./apply-schedule-patch.sh
```

---

## 常见问题

### Q1: 合并冲突如何解决？

```bash
# 查看冲突文件
git status

# 编辑冲突文件，解决 <<<<<<< 和 >>>>>>> 标记

# 标记为解决
git add <文件名>

# 完成合并
git commit
```

### Q2: 官方更新后定时任务功能失效？

检查以下几点：

1. **SchedulerService 是否被移除**
   ```bash
   grep -r "SchedulerService" packages/core/src/
   ```

2. **ScheduleTool 是否被注册**
   ```bash
   grep "registerCoreTool(ScheduleTool" packages/core/src/config/config.ts
   ```

3. **ToolNames 是否包含 SCHEDULE**
   ```bash
   grep "SCHEDULE:" packages/core/src/tools/tool-names.ts
   ```

### Q3: 如何回滚到更新前？

```bash
# 如果刚合并，还没提交
git merge --abort

# 如果已提交，回退一个版本
git reset --hard HEAD~1

# 恢复备份
git stash pop  # 如果用了 stash
```

### Q4: 官方版本已经包含了定时任务功能？

如果官方后续版本自带了定时任务功能：

1. 比较官方实现和本地补丁
2. 优先使用官方实现（更稳定）
3. 迁移任务数据（如果需要）

```bash
# 检查官方是否已有
grep -r "SchedulerService" packages/core/src/

# 如果官方有，删除本地补丁文件
rm packages/core/src/services/schedulerService.ts
rm packages/core/src/tools/scheduleTool.ts
```

---

## 版本兼容性

| 补丁版本 | 兼容的 Qwen Code 版本 | 备注 |
|----------|----------------------|------|
| v1.0 | 0.11.x - 0.12.x | 初始版本 |
| v1.1 | 0.12.x+ | 优化 Cron 解析 |

---

## 附录：完整融合命令

```bash
# 一键融合（推荐使用脚本）
cd /data/data/com.termux/files/home/qwen-code-0.12.0
./update-and-patch.sh

# 手动融合（完整流程）
cd /data/data/com.termux/files/home/qwen-code-0.12.0

# 1. 备份
git stash push -m "pre-update-backup"

# 2. 拉取更新
git fetch origin master
git merge origin/master

# 3. 恢复补丁文件
git checkout stash -- packages/core/src/services/schedulerService.ts
git checkout stash -- packages/core/src/tools/scheduleTool.ts

# 4. 手动修复冲突
# 编辑 packages/core/src/config/config.ts
# 编辑 packages/core/src/tools/tool-names.ts

# 5. 构建测试
npm run build
npm start -- -p "列出所有定时任务"

# 6. 提交
git add -A
git commit -m "chore: 融合官方更新并保留定时任务补丁"

# 7. 推送
git push -f origin master
```

---

## 参考链接

- [Qwen Code 官方仓库](https://github.com/QwenLM/qwen-code)
- [本仓库地址](https://github.com/heihuo000/qwen-code)
- [NPM 安装指南](./NPM_INSTALL_GUIDE.md)
- [补丁修改指南](./SCHEDULE_PATCH_GUIDE.md)
