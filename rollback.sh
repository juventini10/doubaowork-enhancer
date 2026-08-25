#!/bin/bash
# ============================================================
# 豆包办公加强包 — 回滚脚本 v1.0.0 (macOS/Linux)
# 功能: 卸载豆包办公加强包(删除软链/脚本/五系统文件模板),不碰布洛陀基础安装
# 用法: bash rollback.sh
# 设计: 只删加强包创建的东西,绝不碰用户已有文件/布洛陀基础安装
# 作者: 皮叔
# ============================================================
set -uo pipefail
RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'; NC='\033[0m'

# 记忆中心探测
detect_mc() {
  for c in "$HOME/个人AI档案" "$HOME/共享中心" "$HOME/记忆中心" "$HOME/布洛陀"; do
    [ -s "$c/核心层/CORE.md" ] && { echo "$c"; return 0; }
  done
  echo "$HOME/个人AI档案"
}
MC="${MEMORY_CENTER:-$(detect_mc)}"
DOUBAO_HOME="$HOME/Library/Application Support/DoubaoWork/Default/.doubaowork/agent_mode/workspace"
USER_SKILLS="$DOUBAO_HOME/.user_skills"
SYSTEM_FILES_DIR="$MC/豆包办公系统文件"
SCRIPTS_DIR="$MC/开发工具/doubaowork-enhancer"

echo "=== 豆包办公加强包 回滚 v1.0.0 ==="
echo "记忆中心: $MC"
echo ""
echo -e "${YEL}⚠️  将删除以下内容(只删加强包创建的,不碰布洛陀基础安装):${NC}"
echo "  1. Skill软链接: $USER_SKILLS/ (仅删除指向记忆中心的软链)"
echo "  2. 五系统文件模板: $SYSTEM_FILES_DIR/"
echo "  3. 特有脚本: $SCRIPTS_DIR/"
echo ""
read -p "确认回滚? (y/N): " CONFIRM
[ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ] && { echo "已取消"; exit 0; }

echo ""
echo "[1/3] 删除Skill软链接(仅指向记忆中心的软链)..."
DEL=0; SKIP=0
for link in "$USER_SKILLS"/*/; do
  [ -L "$link" ] || continue
  target=$(readlink "$link" 2>/dev/null)
  if [[ "$target" == "$MC/技能配置/"* ]]; then
    rm "$link" && echo "  ✅ 删除: $(basename "$link")" && DEL=$((DEL+1))
  else
    echo "  ⏭️ 跳过(非记忆中心软链): $(basename "$link")" && SKIP=$((SKIP+1))
  fi
done
echo "  结果: 删除$DEL / 跳过$SKIP"

echo ""
echo "[2/3] 删除五系统文件模板目录..."
if [ -d "$SYSTEM_FILES_DIR" ]; then
  rm -rf "$SYSTEM_FILES_DIR" && echo "  ✅ 已删除: $SYSTEM_FILES_DIR"
else
  echo "  ⏭️ 目录不存在,跳过"
fi

echo ""
echo "[3/3] 删除特有脚本目录..."
if [ -d "$SCRIPTS_DIR" ]; then
  rm -rf "$SCRIPTS_DIR" && echo "  ✅ 已删除: $SCRIPTS_DIR"
else
  echo "  ⏭️ 目录不存在,跳过"
fi

echo ""
echo -e "${GRN}✅ 回滚完成${NC}"
echo "  布洛陀基础安装(记忆琥珀/Skill/核心层等)未受影响"
echo "  如需重新安装: bash setup.sh"
exit 0
