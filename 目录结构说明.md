# 项目目录结构说明

## 当前结构

```
qwen-code/                    # GitHub 仓库根目录
└── qwen-code-0.12.0/         # 源码子目录
    ├── .git/                 # Git 仓库
    ├── .github/              # GitHub 配置
    ├── packages/             # 核心代码包
    │   ├── cli/              # CLI 前端
    │   ├── core/             # 核心模块
    │   └── ...
    ├── docs/                 # 项目文档
    ├── NPM_INSTALL_GUIDE.md  # 安装指南
    ├── SCHEDULE_PATCH_GUIDE.md  # 补丁指南
    ├── README_SIMPLE.md      # 简化版 README
    └── ...
```

## 说明

当前仓库是将 `qwen-code-0.12.0` 子目录作为 git 仓库推送的，所以 GitHub 上所有文件都在 `qwen-code-0.12.0/` 子目录中。

## 整理方案

如需将文件移到仓库根目录，可以执行以下操作：

```bash
# 1. 进入源码目录
cd /data/data/com.termux/files/home/qwen-code-0.12.0

# 2. 移动所有文件到父目录的 git 仓库
git mv qwen-code-0.12.0/* ../
cd ../
rm -rf qwen-code-0.12.0/.git

# 3. 重新初始化 git
cd qwen-code-0.12.0
git init
git add .
git commit -m "initial commit"

# 4. 更新远程仓库
git remote add origin git@github.com:heihuo000/qwen-code.git
git push -f -u origin master
```

或者删除 GitHub 仓库后重新创建推送。
