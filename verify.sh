#!/bin/bash
# ============================================================
# 豆包办公加强包 — 验证脚本 v1.0.0 (macOS/Linux)
# 功能: 只读验证加强包安装状态，不修改任何文件
# 用法: bash verify.sh
# 作者: 皮叔
# ============================================================
set -uo pipefail
PKG_DIR="$(cd "$(dirname "$0")" && pwd)"

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

echo "=== 豆包办公加强包 验证 v1.0.0 ==="
echo "记忆中心: $MC"
echo ""

PASS=0; FAIL=0; WARN=0
check() {
  local name="$1" cond="$2" level="${3:-fail}"
  if eval "$cond"; then
    echo "  ✅ $name"; PASS=$((PASS+1))
  else
    if [ "$level" = "warn" ]; then
      echo "  ⚠️ $name"; WARN=$((WARN+1))
    else
      echo "  ❌ $name"; FAIL=$((FAIL+1))
    fi
  fi
}

echo "[1/5] 布洛陀基础检测"
check "记忆中心存在" "[ -d '$MC' ]"
check "核心层CORE.md" "[ -s '$MC/核心层/CORE.md' ]"
check "记忆琥珀已安装" "[ -d '$MC/记忆琥珀/engine' ]" warn
check "记忆Skill≥8" "[ \$(ls -d '$MC'/技能配置/*/SKILL.md 2>/dev/null | wc -l) -ge 8 ]"

echo ""
echo "[2/5] 豆包办公配置检测"
check "豆包办公配置根" "[ -d '$DOUBAO_HOME' ]"
check ".user_skills目录" "[ -d '$USER_SKILLS' ]" warn

echo ""
echo "[3/5] 五系统文件检测"
for f in SOUL.md IDENTITY.md USER.md MEMORY.md customPrompt.md; do
  check "$f" "[ -s '$SYSTEM_FILES_DIR/$f' ]"
done
check "豆包办公宪法.md" "[ -s '$MC/核心层/豆包办公宪法.md' ]"

echo ""
echo "[4/5] Skill软链接检测(抽样)"
for s in system-logger daily-buddy awaken-memory-system growth-box clock-loop; do
  check "$s 软链" "[ -L '$USER_SKILLS/$s' ]" warn
done
check "布洛陀-豆包办公规则 Skill" "[ -d '$USER_SKILLS/布洛陀-豆包办公规则' ]"

echo ""
echo "[5/5] 特有脚本检测"
check "巡逻脚本" "[ -f '$SCRIPTS_DIR/patrol/route_doubaowork_patrol.sh' ]"
check "Skill健康守卫" "[ -f '$SCRIPTS_DIR/guards/doubaowork_skill_health_guard.py' ]" warn

echo ""
echo "=== 验证结果 ==="
echo "通过: $PASS | 失败: $FAIL | 警告: $WARN"

echo ""
echo "=== 手动验证（必做·脚本无法自动检测） ==="
echo "  本脚本只能验证本地文件，无法验证云端的「工作任务偏好指令」。"
echo "  请开一个新对话，问AI「你的第一目的是什么」："
echo "  - 能答出「让这套系统成为自主进化的活系统」→ ✅ 配置成功，跨会话记忆生效"
echo "  - 答不出来 → ❌ 还没配置工作任务偏好指令，运行 setup.sh 后按提示粘贴（30秒搞定）"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "❌ 验证失败，请运行 setup.sh 重新安装"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo "⚠️ 验证通过(有警告)，警告项为可选增强"
  exit 0
else
  echo "✅ 全部通过"
  exit 0
fi
