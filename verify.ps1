# ============================================================
# 豆包办公加强包 — 验证脚本 v1.0.0 (Windows PowerShell)
# 功能: 只读验证加强包安装状态
# 用法: powershell -ExecutionPolicy Bypass -File verify.ps1
# 作者: 皮叔
# ============================================================
$PKG_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
function Detect-MC {
    foreach ($c in @("$env:USERPROFILE\个人AI档案","$env:USERPROFILE\共享中心","$env:USERPROFILE\记忆中心","$env:USERPROFILE\布洛陀")) {
        if (Test-Path "$c\核心层\CORE.md") { return $c }
    }
    return "$env:USERPROFILE\个人AI档案"
}
$MC = if ($env:MEMORY_CENTER) { $env:MEMORY_CENTER } else { Detect-MC }
$DOUBAO_HOME = "$env:APPDATA\DoubaoWork\Default\.doubaowork\agent_mode\workspace"
$USER_SKILLS = "$DOUBAO_HOME\.user_skills"
$SYSTEM_FILES_DIR = "$MC\豆包办公系统文件"
$SCRIPTS_DIR = "$MC\开发工具\doubaowork-enhancer"

Write-Host "=== 豆包办公加强包 验证 v1.0.0 ==="
Write-Host "记忆中心: $MC`n"
$PASS=0; $FAIL=0; $WARN=0
function Check($name, $cond, $level="fail") {
    if ($cond) { Write-Host "  ✅ $name"; $script:PASS++ }
    elseif ($level -eq "warn") { Write-Host "  ⚠️ $name"; $script:WARN++ }
    else { Write-Host "  ❌ $name"; $script:FAIL++ }
}

Write-Host "[1/5] 布洛陀基础检测"
Check "记忆中心存在" (Test-Path $MC)
Check "核心层CORE.md" (Test-Path "$MC\核心层\CORE.md")
Check "记忆琥珀已安装" (Test-Path "$MC\记忆琥珀\engine") "warn"
$skillCount = (Get-ChildItem "$MC\技能配置" -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path "$($_.FullName)\SKILL.md" }).Count
Check "记忆Skill≥8" ($skillCount -ge 8)

Write-Host "`n[2/5] 豆包办公配置检测"
Check "豆包办公配置根" (Test-Path $DOUBAO_HOME)
Check ".user_skills目录" (Test-Path $USER_SKILLS) "warn"

Write-Host "`n[3/5] 五系统文件检测"
foreach ($f in @("SOUL.md","IDENTITY.md","USER.md","MEMORY.md","customPrompt.md")) {
    Check $f (Test-Path "$SYSTEM_FILES_DIR\$f")
}

Write-Host "`n[4/5] Skill软链接检测(抽样)"
foreach ($s in @("system-logger","daily-buddy","awaken-memory-system","growth-box","clock-loop")) {
    $item = Get-Item "$USER_SKILLS\$s" -Force -ErrorAction SilentlyContinue
    $isLink = ($item -and ($item.LinkType -eq "Junction" -or $item.LinkType -eq "SymbolicLink"))
    Check "$s 软链" $isLink "warn"
}

Write-Host "`n[5/5] 特有脚本检测"
Check "巡逻脚本" (Test-Path "$SCRIPTS_DIR\patrol\route_doubaowork_patrol.sh")
Check "Skill健康守卫" (Test-Path "$SCRIPTS_DIR\guards\doubaowork_skill_health_guard.py") "warn"

Write-Host "`n=== 验证结果 ==="
Write-Host "通过: $PASS | 失败: $FAIL | 警告: $WARN"
if ($FAIL -gt 0) { Write-Host "❌ 验证失败，请运行 setup.ps1 重新安装"; exit 1 }
elseif ($WARN -gt 0) { Write-Host "⚠️ 验证通过(有警告)，警告项为可选增强"; exit 0 }
else { Write-Host "✅ 全部通过"; exit 0 }
