#!/bin/bash
# ============================================================
# 豆包办公加强包 — 脱敏门禁 v1.0.0 (维护者发布前跑·非终端用户)
# 第一性原理: 脱敏问题的本质是"模板-实例分离机制缺失"
#   根治 = 源头不产生个人态(设计层·机械门禁),而非事后扫描(检测层·概率路径)
# 机制: 扫描包内所有文件,检测个人态字面量残留(真实路径/用户名/邮箱)
#   白名单: 允许 $HOME/$(id -u)/$USER 等动态表达式(运行时可移植·不产生个人态)
#           禁止硬编码字面量(如 /Users/{用户名}、{用户名}、{邮箱}@example.com)
#   门禁自身豁免: 本工具是"元层"(检查模板的),只含动态表达式,不属于模板层
# 用法: bash desensitize-guard.sh [包目录] [--fix]
#       退出码 0=全绿可发布; 1=有残留(发布阻断)
# 作者: 皮叔
# ============================================================
set -uo pipefail
PKG="${1:-$(cd "$(dirname "$0")" && pwd)}"
FIX=false; [ "${2:-}" = "--fix" ] && FIX=true
RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'; NC='\033[0m'
leak=0

# 个人态动态获取(不硬编码·运行时可移植)
USER_NAME="${USER:-$(id -un 2>/dev/null || echo '')}"
HOME_PATH="$HOME"
EMAIL_RE='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'

echo "=== 豆包办公加强包 脱敏门禁 v1.0.0 ==="
echo "  扫描目录: $PKG"
echo "  检测: 真实路径 / 用户名($USER_NAME) / 邮箱 字面量残留"
echo ""

# ── [B] 分发禁止文件(根治项·.git/.DS_Store/.github等) ──
echo "[B] 分发禁止文件扫描..."
BANNED=(.git .DS_Store .github .gitignore .gitmodules .svn .hg __pycache__ *.pyc)
bfound=""
for b in "${BANNED[@]}"; do
  m=$(find "$PKG" -name "$b" -not -path "*/.git/*" 2>/dev/null | head)
  [ -n "$m" ] && bfound+=$'\n'"$m"
done
if [ -n "$bfound" ]; then
  echo -e "${RED}[FAIL] 发现分发禁止文件(必须删除后再发布):${NC}"
  echo "$bfound"
  if [ "$FIX" = true ]; then
    echo "$bfound" | while read -r f; do
      [ -n "$f" ] && rm -rf "$f" && echo "  已删除: $f"
    done
    echo "  --fix 已执行,请重新跑门禁确认"
  fi
  leak=$((leak+1))
else
  echo -e "${GRN}[OK] 无 .git/.DS_Store/.github 等仓库/系统垃圾${NC}"
fi

# ── [A] 个人信息/真实路径残留(全包含隐藏扫描) ──
echo ""
echo "[A] 个人信息扫描(全包含隐藏文件)..."

# 待扫描文件(排除 .git;门禁自身豁免——元层工具只含动态表达式)
FILES=$(find "$PKG" -type f \
  \( -name "*.sh" -o -name "*.ps1" -o -name "*.md" -o -name "*.yml" -o -name "*.yaml" \
     -o -name "*.py" -o -name "*.ts" -o -name "*.js" -o -name "*.json" -o -name "*.svg" \
     -o -name "*.plist" -o -name "*.txt" -o -name "*.xml" -o -name "*.template" \) \
  -not -path "*/.git/*" -not -name "desensitize-guard.sh" -not -name "desensitize-guard.ps1" -not -name "_sync-check.sh" -not -name "LICENSE" 2>/dev/null)

while IFS= read -r f; do
  [ -z "$f" ] && continue
  rel="${f#"$PKG"/}"

  # ① 真实路径字面量(/Users/ /home/ C:\Users\ 开头)
  HIT=$(grep -nE "(/Users/|/home/|C:\\\\Users\\\\)" "$f" 2>/dev/null | \
    grep -vE "你的名字|示例|/Users/\{|\{用户|§§MC§§|MC_CANDIDATES|Join-Path|HOME|detect_mc" | head -3)

  # ② 当前用户名字面量(动态获取后比对·排除变量定义行)
  HIT2=""
  if [ -n "$USER_NAME" ] && [ "$USER_NAME" != "root" ] && [ ${#USER_NAME} -ge 3 ]; then
    HIT2=$(grep -n "$USER_NAME" "$f" 2>/dev/null | \
      grep -vE "USER_NAME|USER:-|id -un|\\\$USER|your.*name|示例" | head -3)
  fi

  # ③ 邮箱字面量(排除正则定义行和示例邮箱)
  HIT3=$(grep -nE "$EMAIL_RE" "$f" 2>/dev/null | \
    grep -vE "EMAIL_RE|@example|@your|@domain|@email|正则" | head -3)

  if [ -n "$HIT" ] || [ -n "$HIT2" ] || [ -n "$HIT3" ]; then
    echo -e "${RED}  [残留] $rel${NC}"
    [ -n "$HIT" ]  && echo "$HIT"  | sed 's/^/        路径: /'
    [ -n "$HIT2" ] && echo "$HIT2" | sed 's/^/        用户名: /'
    [ -n "$HIT3" ] && echo "$HIT3" | sed 's/^/        邮箱: /'
    leak=$((leak+1))
  fi
done <<< "$FILES"

# ── [C] 占位符完整性(模板内须有 §§MC§§ 待替换) ──
echo ""
echo "[C] 占位符完整性检查..."
MISSING_TMPL=$(find "$PKG/templates" -name "*.md" -exec grep -L "§§MC§§" {} \; 2>/dev/null)
if [ -n "$MISSING_TMPL" ]; then
  echo -e "${YEL}[WARN] 以下模板无 §§MC§§ 占位符(可能不需要路径替换,确认即可):${NC}"
  echo "$MISSING_TMPL" | sed 's/^/        /'
else
  echo -e "${GRN}[OK] 模板占位符就位(安装时替换)${NC}"
fi

# ── 结果 ──
echo ""
if [ "$leak" -eq 0 ]; then
  echo -e "${GRN}✅ 脱敏门禁全绿——模板层零个人态残留,可发布${NC}"
  exit 0
else
  echo -e "${RED}❌ $leak 个问题——⛔发布阻断${NC}"
  echo -e "${YEL}  修复指引: 真实路径→§§MC§§占位符;用户名→\$HOME/\$USER动态获取;邮箱→{邮箱占位符}${NC}"
  echo -e "${YEL}  自动修复: bash desensitize-guard.sh --fix${NC}"
  exit 1
fi
