# verify-rollback.ps1 — CI用: 验证回滚后加强包内容已清除
$ErrorActionPreference = "Stop"
$MC = Join-Path $env:RUNNER_TEMP "buluotuo-mc"
$sysDir = Join-Path $MC "豆包办公系统文件"
$scriptsDir = Join-Path $MC "开发工具\doubaowork-enhancer"
$sysExists = Test-Path $sysDir
$scriptsExists = Test-Path $scriptsDir
Write-Host "sysDir exists: $sysExists (should be False)"
Write-Host "scriptsDir exists: $scriptsExists (should be False)"
if ($sysExists -or $scriptsExists) { throw "Rollback incomplete" }
Write-Host "Rollback verification passed"
