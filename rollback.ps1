# ============================================================
# 豆包办公加强包 — 回滚脚本 v1.0.0 (Windows PowerShell)
# 功能: 卸载豆包办公加强包(删除软链/脚本/五系统文件模板),不碰布洛陀基础安装
# 用法: powershell -ExecutionPolicy Bypass -File rollback.ps1
# 设计: 只删加强包创建的东西,绝不碰用户已有文件/布洛陀基础安装
# 注意: UTF-8 with BOM(PS5.1中文兼容)
# 作者: 皮叔
# ============================================================
$ErrorActionPreference = "Stop"
$PKG_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# 记忆中心探测
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
    if (Test-Path (Join-Path $c "核心层\CORE.md")) { $MC = $c; break }
  }
  if (-not $MC) { $MC = (Join-Path $HOME "个人AI档案") }
}
$DOUBAO_HOME = Join-Path $env:APPDATA "DoubaoWork\Default\.doubaowork\agent_mode\workspace"
$USER_SKILLS = Join-Path $DOUBAO_HOME ".user_skills"
$SYSTEM_FILES_DIR = Join-Path $MC "豆包办公系统文件"
$SCRIPTS_DIR = Join-Path $MC "开发工具\doubaowork-enhancer"

Write-Host "=== 豆包办公加强包 回滚 v1.0.0 ==="
Write-Host "记忆中心: $MC"
Write-Host ""
Write-Host "⚠️  将删除以下内容(只删加强包创建的,不碰布洛陀基础安装):" -ForegroundColor Yellow
Write-Host "  1. Skill软链接: $USER_SKILLS\ (仅删除指向记忆中心的软链)"
Write-Host "  2. 五系统文件模板: $SYSTEM_FILES_DIR\"
Write-Host "  3. 特有脚本: $SCRIPTS_DIR\"
Write-Host ""
$CONFIRM = Read-Host "确认回滚? (y/N)"
if ($CONFIRM -ne "y" -and $CONFIRM -ne "Y") { Write-Host "已取消"; exit 0 }

Write-Host ""
Write-Host "[1/3] 删除Skill软链接(仅指向记忆中心的软链)..."
$DEL=0; $SKIP=0
Get-ChildItem $USER_SKILLS -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  $item = Get-Item $_.FullName -Force
  if ($item.LinkType -eq "Junction" -or $item.LinkType -eq "SymbolicLink") {
    if ($item.Target -like "$MC\技能配置\*") {
      # 用Directory.Delete删除Junction(不递归目标), 避免Remove-Item的NullReferenceException
      [System.IO.Directory]::Delete($_.FullName, $false)
      Write-Host "  ✅ 删除: $($_.Name)" -ForegroundColor Green
      $DEL++
    } else {
      Write-Host "  ⏭️ 跳过(非记忆中心软链): $($_.Name)" -ForegroundColor Yellow
      $SKIP++
    }
  }
}
Write-Host "  结果: 删除$DEL / 跳过$SKIP"

Write-Host ""
Write-Host "[2/3] 删除五系统文件模板目录..."
if (Test-Path $SYSTEM_FILES_DIR) {
  Remove-Item $SYSTEM_FILES_DIR -Recurse -Force
  Write-Host "  ✅ 已删除: $SYSTEM_FILES_DIR" -ForegroundColor Green
} else { Write-Host "  ⏭️ 目录不存在,跳过" }

Write-Host ""
Write-Host "[3/3] 删除特有脚本目录..."
if (Test-Path $SCRIPTS_DIR) {
  Remove-Item $SCRIPTS_DIR -Recurse -Force
  Write-Host "  ✅ 已删除: $SCRIPTS_DIR" -ForegroundColor Green
} else { Write-Host "  ⏭️ 目录不存在,跳过" }

Write-Host ""
Write-Host "✅ 回滚完成" -ForegroundColor Green
Write-Host "  布洛陀基础安装(记忆琥珀/Skill/核心层等)未受影响"
Write-Host "  如需重新安装: powershell -ExecutionPolicy Bypass -File setup.ps1"
exit 0
