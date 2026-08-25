# setup-mc-env.ps1 — CI用: 创建最小布洛陀记忆中心模拟环境
$ErrorActionPreference = "Stop"
$MC = Join-Path $env:RUNNER_TEMP "buluotuo-mc"

New-Item -ItemType Directory -Path (Join-Path $MC "核心层") -Force | Out-Null
Set-Content -Path (Join-Path $MC "核心层\CORE.md") -Value "# CORE`n布洛陀核心层" -Encoding UTF8

New-Item -ItemType Directory -Path (Join-Path $MC "情境层") -Force | Out-Null
Set-Content -Path (Join-Path $MC "情境层\动态状态快照.md") -Value "# 动态状态快照" -Encoding UTF8

New-Item -ItemType Directory -Path (Join-Path $MC "潜意识层") -Force | Out-Null
Set-Content -Path (Join-Path $MC "潜意识层\SHADOW.md") -Value "# SHADOW" -Encoding UTF8

New-Item -ItemType Directory -Path (Join-Path $MC "记忆规则") -Force | Out-Null
Set-Content -Path (Join-Path $MC "记忆规则\用户基本规则-铁律版.md") -Value "# 铁律`n这是铁律版本" -Encoding UTF8

New-Item -ItemType Directory -Path (Join-Path $MC "记忆琥珀\engine") -Force | Out-Null
Set-Content -Path (Join-Path $MC "记忆琥珀\engine\amber-whitelist.txt") -Value "# whitelist" -Encoding UTF8

$skills = @("awaken-memory-system","clock-loop","daily-buddy","growth-box","meta-aletheia","shall-we-talk","system-logger","triwich","sucair")
foreach ($s in $skills) {
  $skillDir = Join-Path $MC "技能配置\$s"
  New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
  $skillMd = Join-Path $skillDir "SKILL.md"
  Set-Content -Path $skillMd -Value "---`nname: $s`n---`n# $s" -Encoding UTF8
}

Write-Host "MEMORY_CENTER=$MC"
Write-Host "模拟布洛陀环境创建完成"
