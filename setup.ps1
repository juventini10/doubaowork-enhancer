# ============================================================
# 豆包办公加强包 — 接入脚本 v1.0 (Windows PowerShell)
# 前提:已装布洛陀五层记忆系统(记忆中心已就位) + 已装豆包办公桌面端
# 功能:指纹检测 → 占位符替换 → 五系统文件部署 → Skill软链 → 脚本部署 → 白名单补充 → 自验证
# 用法: powershell -ExecutionPolicy Bypass -File setup.ps1
#       沙盒测试: $env:MEMORY_CENTER="C:\tmp\test\mc"; powershell -File setup.ps1
# 设计:fail-loud + 幂等(可重跑) + 自验证 + 增量不覆盖 + 全包脱敏
# 注意:本文件必须 UTF-8 with BOM(PS5.1 中文兼容·无 BOM 按 cp1252 读乱码)
# 作者: 皮叔
# ============================================================
$ErrorActionPreference = "Stop"
$PKG_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── 颜色常量 ──
$RED="Red"; $GREEN="Green"; $YELLOW="Yellow"; $CYAN="Cyan"
function Write-Step($m){ Write-Host $m -ForegroundColor $CYAN }
function Write-Ok($m){ Write-Host "  [OK] $m" -ForegroundColor $GREEN }
function Write-Bad($m){ Write-Host "  [X] $m" -ForegroundColor $RED }
function Write-Warn($m){ Write-Host "  [⚠] $m" -ForegroundColor $YELLOW }
function Write-Keep($m){ Write-Host "  [keep] $m" -ForegroundColor $YELLOW }

# ── 记忆中心探测 ──
$MC_CANDIDATES = @(
  (Join-Path $HOME "个人AI档案"),
  (Join-Path $HOME "共享中心"),
  (Join-Path $HOME "记忆中心"),
  (Join-Path $HOME "布洛陀")
)
if ($env:MEMORY_CENTER) { $MC = $env:MEMORY_CENTER }
else {
  $MC = $null
  foreach ($c in $MC_CANDIDATES) {
    if ((Test-Path (Join-Path $c "核心层\CORE.md")) -and (Test-Path (Join-Path $c "记忆规则\用户基本规则-铁律版.md"))) {
      $MC = $c; break
    }
  }
  if (-not $MC) { $MC = (Join-Path $HOME "个人AI档案") }
}

# ── 沙盒模式检测(临时路径跳过cron写入) ──
$SANDBOX = "no"
if ($MC -match "[/\\]tmp[/\\]" -or $MC -match [regex]::Escape($env:TEMP)) { $SANDBOX = "yes" }

# ── 豆包办公路径(Windows) ──
# 同构推:macOS=~/Library/Application Support/DoubaoWork/Default/.doubaowork/agent_mode/workspace
# Windows=%APPDATA%\DoubaoWork\Default\.doubaowork\agent_mode\workspace
if ($env:DOUBAO_HOME) { $DOUBAO_HOME = $env:DOUBAO_HOME }
else { $DOUBAO_HOME = Join-Path $env:APPDATA "DoubaoWork\Default\.doubaowork\agent_mode\workspace" }
$USER_SKILLS = Join-Path $DOUBAO_HOME ".user_skills"
$SYSTEM_FILES_DIR = Join-Path $MC "豆包办公系统文件"
$SCRIPTS_DIR = Join-Path $MC "开发工具\doubaowork-enhancer"

Write-Step "=== 豆包办公加强包 接入 v1.0 (PowerShell) ==="
Write-Warn "    前提:需已装布洛陀五层记忆系统 + 已装豆包办公桌面端"
Write-Step "    记忆中心: $MC | 沙盒: $SANDBOX"

# ── [1/8] 指纹级检测布洛陀 ──
Write-Step "[1/8] 检测布洛陀记忆中心(指纹级)..."
if (-not (Test-Path $MC)) {
  Write-Bad "记忆中心目录不存在: $MC"
  Write-Host "    请先完成布洛陀五层记忆系统安装"; exit 1
}
$FP_FAIL = 0
function Test-FPFile($rel, $label, $kw) {
  $f = Join-Path $MC $rel
  if (-not (Test-Path $f) -or (Get-Item $f).Length -eq 0) {
    Write-Bad "${label}: $rel (不存在或为空)"; $script:FP_FAIL++; return
  }
  if ($kw -and -not (Select-String -Quiet -Pattern ([regex]::Escape($kw)) -Path $f)) {
    Write-Bad "${label}: $rel 无'$kw'关键词"; $script:FP_FAIL++; return
  }
  Write-Ok "${label}: $rel"
}
Test-FPFile "核心层\CORE.md" "L1核心层" ""
Test-FPFile "情境层\动态状态快照.md" "L4情境层" ""
Test-FPFile "潜意识层\SHADOW.md" "L5潜意识层" ""
Test-FPFile "记忆规则\用户基本规则-铁律版.md" "行为规则" "铁律"
# 记忆琥珀检测(基础安装包自带)
if ((Test-Path (Join-Path $MC "记忆琥珀\engine")) -and (Test-Path (Join-Path $MC "记忆琥珀\engine\amber-whitelist.txt"))) {
  Write-Ok "记忆琥珀: 已安装(基础安装包自带)"
} else {
  Write-Warn "记忆琥珀: 未检测到完整安装,跳过白名单补充"
}
# Skill检测
$FP_SKILLS = @("awaken-memory-system","clock-loop","daily-buddy","growth-box","meta-aletheia","shall-we-talk","system-logger","triwich","sucair")
$FP_SK = 0
foreach ($s in $FP_SKILLS) { if (Test-Path (Join-Path $MC "技能配置\$s\SKILL.md")) { $FP_SK++ } }
if ($FP_SK -ge 8) { Write-Ok "记忆Skill: $FP_SK/9" }
else { Write-Bad "记忆Skill仅 $FP_SK/9"; $FP_FAIL++ }
if ($FP_FAIL -gt 0) { Write-Bad "不是完整布洛陀(${FP_FAIL}项指纹缺失)"; exit 1 }
Write-Ok "布洛陀指纹验证通过"

# ── [2/8] 检测豆包办公配置 ──
Write-Step "[2/8] 检测豆包办公配置根..."
if (-not (Test-Path $DOUBAO_HOME)) {
  Write-Bad "未探测到豆包办公配置根: $DOUBAO_HOME"
  Write-Host "    请先安装并至少启动一次豆包办公桌面端"; exit 1
}
New-Item -ItemType Directory -Path $USER_SKILLS -Force | Out-Null
Write-Ok "豆包办公配置根: $DOUBAO_HOME"

# ── [3/8] 部署五系统文件模板(增量不覆盖) ──
Write-Step "[3/8] 部署五系统文件模板(增量不覆盖)..."
New-Item -ItemType Directory -Path $SYSTEM_FILES_DIR -Force | Out-Null
$TEMPLATE_DIR = Join-Path $PKG_DIR "templates\doubaowork"
$DEPLOYED=0; $SKIPPED=0
Get-ChildItem (Join-Path $TEMPLATE_DIR "*.md") | ForEach-Object {
  $fname = $_.Name
  $target = Join-Path $SYSTEM_FILES_DIR $fname
  if (Test-Path $target) {
    Write-Keep "$fname (已存在,不覆盖)"
    $SKIPPED++
  } else {
    $content = Get-Content $_.FullName -Raw
    $content = $content.Replace("§§MC§§", $MC)
    Set-Content -Path $target -Value $content -NoNewline -Encoding UTF8
    Write-Ok "部署: $fname"
    $DEPLOYED++
  }
}
Write-Ok "五系统文件: 新部署$DEPLOYED / 已存在跳过$SKIPPED"

# ── [4/8] Skill软链接(Junction·增量安全·不覆盖用户实体文件) ──
Write-Step "[4/8] 建立Skill软链接(记忆中心→豆包办公.user_skills)..."
$LINKED=0; $KEPT=0; $FAIL=0
Get-ChildItem (Join-Path $MC "技能配置") -Directory | ForEach-Object {
  $skill_name = $_.Name
  if (-not (Test-Path (Join-Path $_.FullName "SKILL.md"))) { return }
  $link = Join-Path $USER_SKILLS $skill_name
  $item = Get-Item $link -Force -ErrorAction SilentlyContinue
  if ($item -and ($item.LinkType -eq "Junction" -or $item.LinkType -eq "SymbolicLink")) {
    Write-Keep "$skill_name (已存在软链)"
    $LINKED++
  } elseif ($item) {
    Write-Keep "$skill_name (已是实体文件,尊重用户已有,不覆盖)"
    $KEPT++
  } else {
    try {
      # Junction优先(免管理员/免开发者模式),失败回退SymbolicLink
      New-Item -ItemType Junction -Path $link -Target $_.FullName -Force -ErrorAction Stop | Out-Null
      Write-Ok "$skill_name (Junction)"
      $LINKED++
    } catch {
      try {
        New-Item -ItemType SymbolicLink -Path $link -Target $_.FullName -Force -ErrorAction Stop | Out-Null
        Write-Ok "$skill_name (SymbolicLink)"
        $LINKED++
      } catch {
        Write-Bad "$skill_name 建链失败——需开启开发者模式或管理员运行"
        $FAIL++
      }
    }
  }
}
Write-Ok "Skill软链: 新建/已存在$LINKED / 保留用户实体$KEPT / 失败$FAIL"

# ── [5/8] 部署豆包办公端特有脚本 ──
Write-Step "[5/8] 部署豆包办公端特有脚本..."
New-Item -ItemType Directory -Path (Join-Path $SCRIPTS_DIR "patrol") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $SCRIPTS_DIR "guards") -Force | Out-Null
$patrol_src = Join-Path $PKG_DIR "scripts\patrol\route_doubaowork_patrol.sh"
if (Test-Path $patrol_src) {
  $content = Get-Content $patrol_src -Raw
  $content = $content.Replace("§§MC§§", $MC)
  Set-Content -Path (Join-Path $SCRIPTS_DIR "patrol\route_doubaowork_patrol.sh") -Value $content -NoNewline -Encoding UTF8
  Write-Ok "巡逻脚本: route_doubaowork_patrol.sh"
}
$guard_src = Join-Path $PKG_DIR "scripts\guards\doubaowork_skill_health_guard.py"
if (Test-Path $guard_src) {
  Copy-Item $guard_src (Join-Path $SCRIPTS_DIR "guards\") -Force
  Write-Ok "Skill健康守卫: doubaowork_skill_health_guard.py"
}
Write-Ok "脚本部署完成: $SCRIPTS_DIR"

# ── [6/8] 补充记忆琥珀白名单(豆包办公端特有条目) ──
Write-Step "[6/8] 补充记忆琥珀白名单(豆包办公端特有条目)..."
$AMBER_WL = Join-Path $MC "记忆琥珀\engine\amber-whitelist.txt"
if (Test-Path $AMBER_WL) {
  $ADDED=0
  $existing = Get-Content $AMBER_WL
  $wl_template = Join-Path $PKG_DIR "scripts\amber\amber-whitelist.txt.template"
  Get-Content $wl_template | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith("#")) { return }
    $actual = $line.Replace("§§MC§§", $MC)
    if ($existing -notcontains $actual) {
      Add-Content -Path $AMBER_WL -Value $actual -Encoding UTF8
      $ADDED++
    }
  }
  Write-Ok "白名单补充: 新增${ADDED}条"
} else {
  Write-Warn "跳过(记忆琥珀白名单不存在)"
}

# ── [7/8] 自验证 ──
Write-Step "[7/8] 自验证..."
$VP=0; $VF=0
foreach ($f in @("SOUL.md","IDENTITY.md","USER.md","MEMORY.md","customPrompt.md")) {
  if (Test-Path (Join-Path $SYSTEM_FILES_DIR $f)) { $VP++ }
  else { Write-Bad "缺失: $f"; $VF++ }
}
foreach ($s in @("system-logger","daily-buddy","awaken-memory-system")) {
  if (Test-Path (Join-Path $USER_SKILLS $s)) { $VP++ }
  else { Write-Bad "软链缺失: $s"; $VF++ }
}
if (Test-Path (Join-Path $SCRIPTS_DIR "patrol\route_doubaowork_patrol.sh")) { $VP++ }
else { Write-Bad "巡逻脚本缺失"; $VF++ }
Write-Ok "自验证: 通过$VP / 失败$VF"

# ── [8/8] 完成报告 ──
Write-Host ""
Write-Step "=== 豆包办公加强包 接入完成 ==="
Write-Ok "五系统文件: $SYSTEM_FILES_DIR\"
Write-Ok "Skill软链: $USER_SKILLS\"
Write-Ok "特有脚本: $SCRIPTS_DIR\"
Write-Warn "下一步:"
Write-Host "  1. 新会话启动时,AI会主动Read五系统文件(SOUL/IDENTITY/USER/MEMORY/customPrompt)"
Write-Host "  2. 如需定时巡逻,在豆包办公中创建cronjob挂载巡逻脚本"
Write-Host "  3. 运行验证脚本确认安装: powershell -ExecutionPolicy Bypass -File verify.ps1"
Write-Host ""

if ($VF -gt 0) {
  Write-Warn "有${VF}项验证失败,请检查上方日志"
  exit 1
}
exit 0
