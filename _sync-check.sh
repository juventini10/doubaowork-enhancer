#!/bin/bash
# ============================================================
# 豆包办公加强包 — 同步自检哨兵 v1.0.0
# 功能: 检查包内部一致性(版本/文件/编码/脱敏/双平台配对)
# 用法: bash _sync-check.sh --check
# 设计: 只读不写, 0 FAIL = 同步健康
# 作者: 皮叔
# ============================================================
set -uo pipefail
PKG_DIR="$(cd "$(dirname "$0")" && pwd)"
FAIL=0; PASS=0; WARN=0

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

echo "=== 豆包办公加强包 同步自检 ==="
echo "包目录: $PKG_DIR"
echo ""

# [1/6] 版本一致性
echo "[1/6] 版本一致性"
VERSION_MD=$(grep '^version:' "$PKG_DIR/version.md" 2>/dev/null | head -1 | awk '{print $2}')
VERSION_README=$(grep -oP '版本：v\K[0-9.]+' "$PKG_DIR/README.md" 2>/dev/null | head -1)
check "version.md存在" "[ -f '$PKG_DIR/version.md' ]"
check "version.md版本非空" "[ -n '$VERSION_MD' ]"
check "README版本与version.md一致" "[ '$VERSION_MD' = '$VERSION_README' ]" warn

# [2/6] 必含文件
echo ""
echo "[2/6] 必含文件存在性"
for f in setup.sh setup.ps1 verify.sh verify.ps1 rollback.sh rollback.ps1 README.md LICENSE version.md desensitize-guard.sh; do
  check "$f" "[ -f '$PKG_DIR/$f' ]"
done
for d in scripts templates; do
  check "$d/目录" "[ -d '$PKG_DIR/$d' ]"
done

# [3/6] 双平台脚本配对
echo ""
echo "[3/6] 双平台脚本配对"
for base in setup verify rollback; do
  check "$base.sh存在" "[ -f '$PKG_DIR/$base.sh' ]"
  check "$base.ps1存在" "[ -f '$PKG_DIR/$base.ps1' ]"
done

# [4/6] PS1编码(BOM)
echo ""
echo "[4/6] PS1编码合规(UTF-8 BOM)"
for f in setup.ps1 verify.ps1 rollback.ps1; do
  bom=$(xxd -l 3 "$PKG_DIR/$f" 2>/dev/null | head -1 | grep -c 'efbb bf')
  check "$f BOM" "[ '$bom' = '1' ]"
done

# [5/6] 脱敏完整性
echo ""
echo "[5/6] 脱敏完整性(零绝对路径残留)"
abs_sh=$(grep -rc '/Users/' "$PKG_DIR" --include="*.sh" --include="*.ps1" --include="*.md" --include="*.template" --exclude="_sync-check.sh" --exclude="desensitize-guard.sh" 2>/dev/null | grep -v ':0$' | wc -l)
abs_win=$(grep -rc 'C:\\\\Users' "$PKG_DIR" --include="*.sh" --include="*.ps1" --include="*.md" --exclude="_sync-check.sh" --exclude="desensitize-guard.sh" 2>/dev/null | grep -v ':0$' | wc -l)
check "零/Users/绝对路径" "[ '$abs_sh' -eq 0 ]"
check "零C:\\Users绝对路径" "[ '$abs_win' -eq 0 ]"
mc_placeholder=$(grep -rl '§§MC§§' "$PKG_DIR" --include="*.sh" --include="*.ps1" --include="*.template" 2>/dev/null | wc -l)
check "脱敏占位符已使用(≥3文件)" "[ '$mc_placeholder' -ge 3 ]" warn

# [6/6] 无CRLF + 无分发禁止文件
echo ""
echo "[6/6] 卫生检查"
crlf_count=$(grep -rl $'\r' "$PKG_DIR" --include="*.sh" --include="*.ps1" --include="*.md" 2>/dev/null | wc -l)
check "零CRLF行尾" "[ '$crlf_count' -eq 0 ]"
for f in .git .DS_Store .github .gitignore; do
  check "无分发禁止文件: $f" "[ ! -e '$PKG_DIR/$f' ]" warn
done

echo ""
echo "=== 自检结果 ==="
echo "通过: $PASS | 失败: $FAIL | 警告: $WARN"
if [ "$FAIL" -gt 0 ]; then
  echo "❌ 自检失败 (${FAIL}项), 请修复后重跑"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo "⚠️ 自检通过(有警告 ${WARN}项)"
  exit 0
else
  echo "✅ 全部通过"
  exit 0
fi
