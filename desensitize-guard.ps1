# ============================================================
# 豆包办公加强包 — 脱敏门禁 v1.0.0 (维护者发布前跑·非终端用户)
# 第一性原理: 脱敏问题的本质是"模板-实例分离机制缺失"
#   根治 = 源头不产生个人态(设计层·机械门禁),而非事后扫描(检测层·概率路径)
# 机制: 扫描包内所有文件,检测个人态字面量残留(真实路径/用户名/邮箱)
#   白名单: 允许 $HOME/$env:USERNAME 等动态表达式(运行时可移植·不产生个人态)
#           禁止硬编码字面量(如 /Users/{用户名}、{用户名}、{邮箱}@example.com)
#   门禁自身豁免: 本工具是"元层"(检查模板的),只含动态表达式,不属于模板层
# 用法: powershell -ExecutionPolicy Bypass -File desensitize-guard.ps1 [包目录] [--fix]
#       退出码 0=全绿可发布; 1=有残留(发布阻断)
# 注意: 本文件必须 UTF-8 with BOM(PS5.1 中文兼容)
# 作者: 皮叔
# ============================================================
$ErrorActionPreference = "Stop"
$PKG = if ($args.Count -ge 1 -and $args[0] -ne "--fix") { $args[0] } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$FIX = $args -contains "--fix"
$leak = 0

# 个人态动态获取(不硬编码·运行时可移植·跨平台 fallback)
$USER_NAME = if ($env:USERNAME) { $env:USERNAME } elseif ($env:USER) { $env:USER } else { "" }
$EMAIL_RE = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'

Write-Host "=== 豆包办公加强包 脱敏门禁 v1.0.0 ==="
Write-Host "  扫描目录: $PKG"
Write-Host "  检测: 真实路径 / 用户名($USER_NAME) / 邮箱 字面量残留"
Write-Host ""

# ── [B] 分发禁止文件(根治项·.git/.DS_Store/.github等) ──
Write-Host "[B] 分发禁止文件扫描..."
$BANNED = @(".git",".DS_Store",".github",".gitignore",".gitmodules",".svn",".hg","__pycache__","*.pyc")
$bfound = @()
foreach ($b in $BANNED) {
  $matches = Get-ChildItem -Path $PKG -Filter $b -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\\.git\\' }
  if ($matches) { $bfound += $matches.FullName }
}
if ($bfound.Count -gt 0) {
  Write-Host "[FAIL] 发现分发禁止文件(必须删除后再发布):" -ForegroundColor Red
  $bfound | ForEach-Object { Write-Host "  $_" }
  if ($FIX) {
    $bfound | ForEach-Object { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue; Write-Host "  已删除: $_" }
    Write-Host "  --fix 已执行,请重新跑门禁确认"
  }
  $leak++
} else {
  Write-Host "[OK] 无 .git/.DS_Store/.github 等仓库/系统垃圾" -ForegroundColor Green
}

# ── [A] 个人信息/真实路径残留(全包含隐藏扫描) ──
Write-Host ""
Write-Host "[A] 个人信息扫描(全包含隐藏文件)..."

# 待扫描文件(排除 .git;门禁自身豁免——元层工具只含动态表达式)
$exts = @("*.sh","*.ps1","*.md","*.yml","*.yaml","*.py","*.ts","*.js","*.json","*.svg","*.plist","*.txt","*.xml","*.template")
$FILES = Get-ChildItem -Path $PKG -Recurse -File -Force -ErrorAction SilentlyContinue |
  Where-Object {
    $_.FullName -notmatch '\\\.git\\' -and
    $_.Name -ne "desensitize-guard.sh" -and
    $_.Name -ne "desensitize-guard.ps1" -and
    $_.Name -ne "_sync-check.sh" -and
    $_.Name -ne "LICENSE" -and
    ($exts | Where-Object { $_.Name -like $_ }).Count -gt 0
  }

foreach ($f in $FILES) {
  $rel = $f.FullName.Substring($PKG.Length).TrimStart('\')
  $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
  if (-not $content) { continue }

  # ① 真实路径字面量(/Users/ /home/ C:\Users\ 开头)
  $HIT = $content | Select-String -Pattern "(/Users/|/home/|C:\\Users\\)" -AllMatches |
    ForEach-Object { $_.Matches } | ForEach-Object { $_.Value } |
    Where-Object { $_ -notmatch '你的名字|示例|/Users/\{|\{用户|§§MC§§|MC_CANDIDATES|Join-Path|HOME|detect_mc' } |
    Select-Object -First 3

  # ② 当前用户名字面量(动态获取后比对·排除变量定义行)
  $HIT2 = @()
  if ($USER_NAME -and $USER_NAME -ne "root" -and $USER_NAME.Length -ge 3) {
    $HIT2 = $content | Select-String -Pattern $USER_NAME -AllMatches |
      Where-Object { $_.Line -notmatch 'USER_NAME|USER:-|id -un|\$USER|your.*name|示例' } |
      Select-Object -First 3
  }

  # ③ 邮箱字面量(排除正则定义行和示例邮箱)
  $HIT3 = $content | Select-String -Pattern $EMAIL_RE -AllMatches |
    Where-Object { $_.Line -notmatch 'EMAIL_RE|@example|@your|@domain|@email|正则' } |
    Select-Object -First 3

  if ($HIT -or $HIT2 -or $HIT3) {
    Write-Host "  [残留] $rel" -ForegroundColor Red
    if ($HIT)  { $HIT  | ForEach-Object { Write-Host "        路径: $_" } }
    if ($HIT2) { $HIT2 | ForEach-Object { Write-Host "        用户名: $($_.Line)" } }
    if ($HIT3) { $HIT3 | ForEach-Object { Write-Host "        邮箱: $($_.Line)" } }
    $leak++
  }
}

# ── [C] 占位符完整性(模板内须有 §§MC§§ 待替换) ──
Write-Host ""
Write-Host "[C] 占位符完整性检查..."
$tmplDir = Join-Path $PKG "templates"
$MISSING_TMPL = @()
if (Test-Path $tmplDir) {
  $MISSING_TMPL = Get-ChildItem -Path $tmplDir -Filter "*.md" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { -not (Select-String -Path $_.FullName -Pattern "§§MC§§" -Quiet) }
}
if ($MISSING_TMPL.Count -gt 0) {
  Write-Host "[WARN] 以下模板无 §§MC§§ 占位符(可能不需要路径替换,确认即可):" -ForegroundColor Yellow
  $MISSING_TMPL | ForEach-Object { Write-Host "        $($_.FullName)" }
} else {
  Write-Host "[OK] 模板占位符就位(安装时替换)" -ForegroundColor Green
}

# ── 结果 ──
Write-Host ""
if ($leak -eq 0) {
  Write-Host "✅ 脱敏门禁全绿——模板层零个人态残留,可发布" -ForegroundColor Green
  exit 0
} else {
  Write-Host "❌ $leak 个问题——⛔发布阻断" -ForegroundColor Red
  Write-Host "  修复指引: 真实路径→§§MC§§占位符;用户名→`$HOME/`$USER动态获取;邮箱→{邮箱占位符}" -ForegroundColor Yellow
  Write-Host "  自动修复: powershell -File desensitize-guard.ps1 --fix" -ForegroundColor Yellow
  exit 1
}
