#!/bin/bash
# ============================================================
# 豆包办公端脚本巡逻脚本 v0.2
# 功能: 执行3个文件级机械守卫 + 心跳更新 + 审计产物
# 守卫: rule_three_layer_guard + card_id_guard + doubaowork_skill_health_guard
# 用法: bash route_doubaowork_patrol.sh
# 设计: 并发锁 + 幂等 + 失败不阻塞 + 心跳落盘
# 作者: 皮叔
# ============================================================
set -uo pipefail

# 记忆中心: 自动探测或环境变量覆盖
if [ -n "${MEMORY_CENTER:-}" ]; then
  MC="$MEMORY_CENTER"
else
  # 自动探测常见命名
  for c in "$HOME/个人AI档案" "$HOME/共享中心" "$HOME/记忆中心" "$HOME/布洛陀"; do
    if [ -d "$c/核心层" ] && [ -d "$c/技能配置" ]; then
      MC="$c"; break
    fi
  done
  [ -z "${MC:-}" ] && MC="$HOME/个人AI档案"
fi

PATROL_DIR="$MC/自定义层/待完成工作/路由家族/.patrol"
HEARTBEAT="$PATROL_DIR/last_run_doubaowork.ts"
AUDIT_LOG="$PATROL_DIR/audit_doubaowork.log"
LOCK_FILE="$PATROL_DIR/.patrol.lock"
GUARD_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$PATROL_DIR"

# 并发锁
if [ -f "$LOCK_FILE" ]; then
  LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
  if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
    echo "⚠️ 巡逻脚本已在运行(PID=$LOCK_PID)，跳过本次"
    exit 0
  fi
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
echo "=== 豆包办公端巡逻 $TIMESTAMP ===" | tee -a "$AUDIT_LOG"

GUARD_PASS=0
GUARD_FAIL=0
GUARD_SKIP=0

# ── 守卫1: rule_three_layer_guard ──
echo "[1/3] rule_three_layer_guard..." | tee -a "$AUDIT_LOG"
if [ -f "$GUARD_DIR/rule_three_layer_guard.py" ]; then
  python3 "$GUARD_DIR/rule_three_layer_guard.py" --mc "$MC" >> "$AUDIT_LOG" 2>&1
  RC=$?
  if [ $RC -eq 0 ]; then
    echo "  ✅ 通过" | tee -a "$AUDIT_LOG"; GUARD_PASS=$((GUARD_PASS+1))
  else
    echo "  ❌ 失败(exit=$RC)" | tee -a "$AUDIT_LOG"; GUARD_FAIL=$((GUARD_FAIL+1))
  fi
else
  echo "  ⏭️ 跳过(脚本不存在)" | tee -a "$AUDIT_LOG"; GUARD_SKIP=$((GUARD_SKIP+1))
fi

# ── 守卫2: card_id_guard ──
echo "[2/3] card_id_guard..." | tee -a "$AUDIT_LOG"
if [ -f "$GUARD_DIR/card_id_guard.py" ]; then
  python3 "$GUARD_DIR/card_id_guard.py" --mc "$MC" >> "$AUDIT_LOG" 2>&1
  RC=$?
  if [ $RC -eq 0 ]; then
    echo "  ✅ 通过" | tee -a "$AUDIT_LOG"; GUARD_PASS=$((GUARD_PASS+1))
  else
    echo "  ❌ 失败(exit=$RC)" | tee -a "$AUDIT_LOG"; GUARD_FAIL=$((GUARD_FAIL+1))
  fi
else
  echo "  ⏭️ 跳过(脚本不存在)" | tee -a "$AUDIT_LOG"; GUARD_SKIP=$((GUARD_SKIP+1))
fi

# ── 守卫3: doubaowork_skill_health_guard ──
echo "[3/3] doubaowork_skill_health_guard..." | tee -a "$AUDIT_LOG"
if [ -f "$GUARD_DIR/doubaowork_skill_health_guard.py" ]; then
  python3 "$GUARD_DIR/doubaowork_skill_health_guard.py" --mc "$MC" >> "$AUDIT_LOG" 2>&1
  RC=$?
  if [ $RC -eq 0 ]; then
    echo "  ✅ 通过" | tee -a "$AUDIT_LOG"; GUARD_PASS=$((GUARD_PASS+1))
  elif [ $RC -eq 1 ]; then
    echo "  ⚠️ 警告(有异常)" | tee -a "$AUDIT_LOG"; GUARD_FAIL=$((GUARD_FAIL+1))
  else
    echo "  ❌ 失败(exit=$RC)" | tee -a "$AUDIT_LOG"; GUARD_FAIL=$((GUARD_FAIL+1))
  fi
else
  echo "  ⏭️ 跳过(脚本不存在)" | tee -a "$AUDIT_LOG"; GUARD_SKIP=$((GUARD_SKIP+1))
fi

# ── 心跳更新 ──
echo "$TIMESTAMP|pass=$GUARD_PASS|fail=$GUARD_FAIL|skip=$GUARD_SKIP" > "$HEARTBEAT"
echo "心跳已更新: $HEARTBEAT" | tee -a "$AUDIT_LOG"
echo "巡逻完成: 通过=$GUARD_PASS 失败=$GUARD_FAIL 跳过=$GUARD_SKIP" | tee -a "$AUDIT_LOG"
echo "" | tee -a "$AUDIT_LOG"

exit 0
