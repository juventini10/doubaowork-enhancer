#!/bin/bash
# setup-mc-env.sh — CI用: 创建最小布洛陀记忆中心模拟环境
set -euo pipefail
MC="$RUNNER_TEMP/buluotuo-mc"

mkdir -p "$MC/核心层" "$MC/情境层" "$MC/潜意识层" "$MC/记忆规则" "$MC/记忆琥珀/engine"
echo "# CORE" > "$MC/核心层/CORE.md"
echo "# 快照" > "$MC/情境层/动态状态快照.md"
echo "# SHADOW" > "$MC/潜意识层/SHADOW.md"
printf "# 铁律\n铁律版本\n" > "$MC/记忆规则/用户基本规则-铁律版.md"
echo "# whitelist" > "$MC/记忆琥珀/engine/amber-whitelist.txt"

for s in awaken-memory-system clock-loop daily-buddy growth-box meta-aletheia shall-we-talk system-logger triwich sucair; do
  mkdir -p "$MC/技能配置/$s"
  printf -- "---\nname: %s\n---\n# %s\n" "$s" "$s" > "$MC/技能配置/$s/SKILL.md"
done

echo "MEMORY_CENTER=$MC"
echo "模拟布洛陀环境创建完成"
