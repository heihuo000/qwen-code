# 🔄 定时任务补丁 - 官方更新融合速查表

## 一键融合（推荐）

```bash
cd /data/data/com.termux/files/home/qwen-code-0.12.0
./update-and-patch.sh
```

---

## 手动融合流程

```bash
# 1. 暂存修改
git stash push -m "schedule-patch-backup"

# 2. 拉取官方更新
git fetch origin master
git merge origin/master

# 3. 恢复补丁文件
git checkout stash -- packages/core/src/services/schedulerService.ts
git checkout stash -- packages/core/src/tools/scheduleTool.ts

# 4. 手动修复冲突（如果有）
git mergetool

# 5. 构建测试
npm run build
npm start -- -p "列出所有定时任务"

# 6. 提交推送
git add -A
git commit -m "chore: 融合官方更新并保留定时任务补丁"
git push -f origin master
```

---

## 验证补丁状态

```bash
# 检查核心文件是否存在
ls -la packages/core/src/services/schedulerService.ts
ls -la packages/core/src/tools/scheduleTool.ts

# 检查导入和注册
grep "SchedulerService" packages/core/src/config/config.ts
grep "ScheduleTool" packages/core/src/config/config.ts
grep "SCHEDULE:" packages/core/src/tools/tool-names.ts

# 测试功能
npm start -- -p "列出所有定时任务"
```

---

## 回滚操作

```bash
# 合并中，想取消
git merge --abort

# 已提交，想回退
git reset --hard HEAD~1

# 恢复暂存的修改
git stash pop
```

---

## 文件清单

| 文件 | 作用 |
|------|------|
| `update-and-patch.sh` | 自动融合脚本 |
| `UPDATE_PATCH_GUIDE.md` | 详细融合指南 |
| `NPM_INSTALL_GUIDE.md` | npm 安装指南 |
| `SCHEDULE_PATCH_GUIDE.md` | 补丁修改指南 |
| `README_SIMPLE.md` | 简化版 README |

---

## 命令速查

| 命令 | 作用 |
|------|------|
| `./update-and-patch.sh` | 一键融合更新 |
| `npm run build` | 构建项目 |
| `npm start -- -p "..."` | 运行并执行命令 |
| `git stash push` | 暂存修改 |
| `git stash pop` | 恢复暂存 |
| `git merge --abort` | 取消合并 |

---

**仓库地址**: https://github.com/heihuo000/qwen-code
