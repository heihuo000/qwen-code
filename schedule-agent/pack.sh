#!/bin/bash
# Schedule Agent 打包发布脚本

set -e

echo "🔧 Schedule Agent - 打包发布脚本"
echo "================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 1. 清理旧的 dist
echo "📦 清理旧文件..."
rm -rf dist
rm -f *.tgz
rm -f package-lock.json

# 2. 安装依赖并编译
echo "🔨 编译 TypeScript..."
npm install --no-save typescript 2>/dev/null || true
npm run build

# 3. 添加 shebang 到 dist/agent.js
echo "📝 添加 shebang..."
if ! head -1 dist/agent.js | grep -q "#!/usr/bin/env node"; then
  echo '#!/usr/bin/env node' > temp.js
  cat dist/agent.js >> temp.js
  mv temp.js dist/agent.js
  chmod +x dist/agent.js
fi

# 4. 检查打包文件
echo "📋 检查打包内容..."
echo ""
echo "包内容预览:"
tar -tzf <(npm pack 2>/dev/null) | head -20 || true
echo ""

# 5. 创建 tarball
echo "📦 创建 npm 包..."
npm pack

# 6. 显示结果
echo ""
echo "✅ 打包完成！"
echo ""
echo "生成的文件:"
ls -lh *.tgz 2>/dev/null || echo "未生成 tarball"
echo ""
echo "测试安装:"
echo "  npm install -g ./qwen-code-schedule-agent-*.tgz"
echo "  schedule-agent check"
echo ""
echo "发布到 npm:"
echo "  npm publish --access public"
