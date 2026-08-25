#!/bin/bash
# ============================================================
# 豆包办公加强包 — 接入脚本 v1.0
# 前提: 已装布洛陀五层记忆系统(记忆中心已就位) + 已装豆包办公桌面端
# 功能: 指纹检测 → 占位符替换 → 五系统文件部署 → Skill软链 → 脚本部署 → 白名单补充 → 自验证
# 用法: bash setup.sh   (沙盒测试: MEMORY_CENTER=/tmp/test/mc bash setup.sh)
# 设计: fail-loud + 幂等(可重跑) + 自验证 + 增量不覆盖 + 全包脱敏(§§MC§§占位符)
# 作者: 皮叔
# ============================================================
set -uo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
PKG_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── 记忆中心探测 ──
detect_mc() {
  local candidates=("$HOME/个人AI档案" "$HOME/共享中心" "$HOME/记忆中心" "$HOME/布洛陀")
  for c in "${candidates[@]}"; do
    if [ -s "$c/核心层/CORE.md" ] && [ -s "$c/记忆规则/用户基本规则-铁律版.md" ]; then
      echo "$c"; return 0
    fi
  done
  echo "$HOME/个人AI档案"; return 1
}
if [ -n "${MEMORY_CENTER:-}" ]; then
  MC_SRC="$MEMORY_CENTER"
else
  MC_SRC="$(detect_mc)"
fi

# ── 豆包办公路径(macOS) ──
DOUBAO_HOME="$HOME/Library/Application Support/DoubaoWork/Default/.doubaowork/agent_mode/workspace"
USER_SKILLS="$DOUBAO_HOME/.user_skills"
SYSTEM_FILES_DIR="$MC_SRC/豆包办公系统文件"

echo -e "${CYAN}=== 豆包办公加强包 接入 v1.0 ===${NC}"
echo -e "${YELLOW}    前提: 需已装布洛陀五层记忆系统 + 已装豆包办公桌面端${NC}"
echo -e "${CYAN}    记忆中心: $MC_SRC${NC}"

# ── [1/8] 指纹级检测布洛陀 ──
echo -e "${YELLOW}[1/8] 检测布洛陀记忆中心(指纹级)...${NC}"
if [ ! -d "$MC_SRC" ]; then
  echo -e "${RED}[X] 记忆中心目录不存在: $MC_SRC${NC}"
  echo -e "    请先完成布洛陀五层记忆系统安装,再跑本脚本。"; exit 1
fi
FP_FAIL=0
fp_file() {
  local f="$MC_SRC/$1" kw="${3:-}"
  if [ ! -s "$f" ]; then echo -e "${RED}  [缺] $2: $1${NC}"; FP_FAIL=$((FP_FAIL+1)); return; fi
  if [ -n "$kw" ] && ! grep -q "$kw" "$f"; then echo -e "${RED}  [疑] $2: $1 无\"$kw\"关键词${NC}"; FP_FAIL=$((FP_FAIL+1)); return; fi
  echo -e "${GREEN}  [OK] $2: $1${NC}"
}
fp_file "核心层/CORE.md" "L1核心层"
fp_file "情境层/动态状态快照.md" "L4情境层"
fp_file "潜意识层/SHADOW.md" "L5潜意识层"
fp_file "记忆规则/用户基本规则-铁律版.md" "行为规则" "铁律"
# 记忆琥珀检测(基础安装包自带)
if [ -d "$MC_SRC/记忆琥珀/engine" ] && [ -f "$MC_SRC/记忆琥珀/engine/amber-whitelist.txt" ]; then
  echo -e "${GREEN}  [OK] 记忆琥珀: 已安装(基础安装包自带)${NC}"
else
  echo -e "${YELLOW}  [⚠] 记忆琥珀: 未检测到完整安装,本加强包将跳过白名单补充${NC}"
fi
# Skill检测(≥8即通过)
FP_SKILLS=(awaken-memory-system clock-loop daily-buddy growth-box meta-aletheia shall-we-talk system-logger triwich sucair)
FP_SK=0
for s in "${FP_SKILLS[@]}"; do
  [ -f "$MC_SRC/技能配置/$s/SKILL.md" ] && FP_SK=$((FP_SK+1))
done
if [ "$FP_SK" -ge 8 ]; then echo -e "${GREEN}  [OK] 记忆Skill: $FP_SK/9${NC}"
else echo -e "${RED}  [缺] 记忆Skill仅 $FP_SK/9${NC}"; FP_FAIL=$((FP_FAIL+1)); fi
if [ "$FP_FAIL" -gt 0 ]; then
  echo -e "${RED}[X] $MC_SRC 存在但不是完整布洛陀(${FP_FAIL}项指纹缺失)${NC}"; exit 1
fi
echo -e "${GREEN}[OK] 布洛陀指纹验证通过${NC}"

# ── [2/8] 检测豆包办公配置 ──
echo -e "${YELLOW}[2/8] 检测豆包办公配置根...${NC}"
if [ ! -d "$DOUBAO_HOME" ]; then
  echo -e "${RED}[X] 未探测到豆包办公配置根: $DOUBAO_HOME${NC}"
  echo -e "    请先安装并至少启动一次豆包办公桌面端,再跑本脚本。"; exit 1
fi
mkdir -p "$USER_SKILLS"
echo -e "${GREEN}[OK] 豆包办公配置根: $DOUBAO_HOME${NC}"

# ── [3/8] 占位符替换 + 部署五系统文件模板 ──
echo -e "${YELLOW}[3/8] 部署五系统文件模板(增量不覆盖)...${NC}"
mkdir -p "$SYSTEM_FILES_DIR"
TEMPLATE_DIR="$PKG_DIR/templates/doubaowork"
DEPLOYED=0; SKIPPED=0
for tmpl in "$TEMPLATE_DIR"/*.md; do
  fname=$(basename "$tmpl")
  target="$SYSTEM_FILES_DIR/$fname"
  if [ -f "$target" ]; then
    echo -e "  ⏭️ 跳过(已存在): $fname"
    SKIPPED=$((SKIPPED+1))
  else
    # 替换占位符 §§MC§§ → 用户记忆中心路径
    sed "s|§§MC§§|$MC_SRC|g" "$tmpl" > "$target"
    echo -e "  ✅ 部署: $fname"
    DEPLOYED=$((DEPLOYED+1))
  fi
done
echo -e "${GREEN}[OK] 五系统文件: 新部署$DEPLOYED / 已存在跳过$SKIPPED${NC}"

# ── [4/8] Skill软链接 ──
echo -e "${YELLOW}[4/8] 建立Skill软链接(记忆中心→豆包办公.user_skills)...${NC}"
LINKED=0; LINK_FAIL=0
for skill_dir in "$MC_SRC/技能配置/"*/; do
  skill_name=$(basename "$skill_dir")
  [ "$skill_name" = "*" ] && continue
  # 跳过非Skill目录(如restore-my-skills.sh等文件)
  [ ! -f "$skill_dir/SKILL.md" ] && continue
  link_target="$USER_SKILLS/$skill_name"
  if [ -L "$link_target" ]; then
    echo -e "  ⏭️ 已存在软链: $skill_name"
  elif [ -e "$link_target" ]; then
    echo -e "  ⚠️ 目标存在但非软链(跳过): $skill_name"
    LINK_FAIL=$((LINK_FAIL+1))
  else
    ln -sf "$skill_dir" "$link_target"
    if [ -L "$link_target" ]; then
      echo -e "  ✅ 软链: $skill_name"
      LINKED=$((LINKED+1))
    else
      echo -e "  ❌ 软链失败: $skill_name"
      LINK_FAIL=$((LINK_FAIL+1))
    fi
  fi
done
echo -e "${GREEN}[OK] Skill软链: 新建$LINKED / 失败$LINK_FAIL${NC}"

# ── [5/8] 部署豆包办公端特有脚本 ──
echo -e "${YELLOW}[5/8] 部署豆包办公端特有脚本...${NC}"
SCRIPTS_DIR="$MC_SRC/开发工具/doubaowork-enhancer"
mkdir -p "$SCRIPTS_DIR/patrol" "$SCRIPTS_DIR/guards"
# 巡逻脚本
if [ -f "$PKG_DIR/scripts/patrol/route_doubaowork_patrol.sh" ]; then
  sed "s|§§MC§§|$MC_SRC|g" "$PKG_DIR/scripts/patrol/route_doubaowork_patrol.sh" > "$SCRIPTS_DIR/patrol/route_doubaowork_patrol.sh"
  chmod +x "$SCRIPTS_DIR/patrol/route_doubaowork_patrol.sh"
  echo -e "  ✅ 巡逻脚本: route_doubaowork_patrol.sh"
fi
# Skill健康守卫
if [ -f "$PKG_DIR/scripts/guards/doubaowork_skill_health_guard.py" ]; then
  cp "$PKG_DIR/scripts/guards/doubaowork_skill_health_guard.py" "$SCRIPTS_DIR/guards/"
  chmod +x "$SCRIPTS_DIR/guards/doubaowork_skill_health_guard.py"
  echo -e "  ✅ Skill健康守卫: doubaowork_skill_health_guard.py"
fi
echo -e "${GREEN}[OK] 脚本部署完成: $SCRIPTS_DIR${NC}"

# ── [6/8] 补充记忆琥珀白名单(豆包办公端特有条目) ──
echo -e "${YELLOW}[6/8] 补充记忆琥珀白名单(豆包办公端特有条目)...${NC}"
AMBER_WHITELIST="$MC_SRC/记忆琥珀/engine/amber-whitelist.txt"
if [ -f "$AMBER_WHITELIST" ]; then
  ADDED=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    [[ "$line" =~ ^# ]] && continue
    # 替换占位符
    actual_line="${line//§§MC§§/$MC_SRC}"
    if ! grep -qF "$actual_line" "$AMBER_WHITELIST"; then
      echo "$actual_line" >> "$AMBER_WHITELIST"
      ADDED=$((ADDED+1))
    fi
  done < "$PKG_DIR/scripts/amber/amber-whitelist.txt.template"
  echo -e "${GREEN}[OK] 白名单补充: 新增${ADDED}条${NC}"
else
  echo -e "${YELLOW}  ⏭️ 跳过(记忆琥珀白名单不存在)${NC}"
fi

# ── [7/8] 自验证 ──
echo -e "${YELLOW}[7/8] 自验证...${NC}"
VERIFY_PASS=0; VERIFY_FAIL=0
# 五系统文件
for f in SOUL.md IDENTITY.md USER.md MEMORY.md customPrompt.md; do
  if [ -f "$SYSTEM_FILES_DIR/$f" ]; then VERIFY_PASS=$((VERIFY_PASS+1))
  else echo -e "  ❌ 缺失: $f"; VERIFY_FAIL=$((VERIFY_FAIL+1)); fi
done
# Skill软链(抽样3个)
for s in system-logger daily-buddy awaken-memory-system; do
  if [ -L "$USER_SKILLS/$s" ]; then VERIFY_PASS=$((VERIFY_PASS+1))
  else echo -e "  ❌ 软链缺失: $s"; VERIFY_FAIL=$((VERIFY_FAIL+1)); fi
done
# 脚本
if [ -f "$SCRIPTS_DIR/patrol/route_doubaowork_patrol.sh" ]; then VERIFY_PASS=$((VERIFY_PASS+1))
else echo -e "  ❌ 巡逻脚本缺失"; VERIFY_FAIL=$((VERIFY_FAIL+1)); fi
echo -e "${GREEN}[OK] 自验证: 通过$VERIFY_PASS / 失败$VERIFY_FAIL${NC}"

# ── [8/8] 完成报告 ──
echo ""
echo -e "${CYAN}=== 豆包办公加强包 接入完成 ===${NC}"
echo -e "${GREEN}✅ 五系统文件: $SYSTEM_FILES_DIR/${NC}"
echo -e "${GREEN}✅ Skill软链: $USER_SKILLS/${NC}"
echo -e "${GREEN}✅ 特有脚本: $SCRIPTS_DIR/${NC}"
echo -e "${YELLOW}⚠️  下一步:${NC}"
echo -e "  1. 新会话启动时,AI会主动Read五系统文件(SOUL/IDENTITY/USER/MEMORY/customPrompt)"
echo -e "  2. 如需定时巡逻,在豆包办公中创建cronjob挂载: $SCRIPTS_DIR/patrol/route_doubaowork_patrol.sh"
echo -e "  3. 运行验证脚本确认安装: bash verify.sh"
echo ""

if [ "$VERIFY_FAIL" -gt 0 ]; then
  echo -e "${YELLOW}⚠️  有${VERIFY_FAIL}项验证失败,请检查上方日志${NC}"
  exit 1
fi
exit 0
