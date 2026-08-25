# ============================================================
# 豆包办公加强包 — 同步自检哨兵 v1.0.0 (PowerShell)
# 功能: 检查包内部一致性(版本/文件/编码/脱敏/双平台配对)
# 用法: powershell -ExecutionPolicy Bypass -File _sync-check.ps1
# 设计: 只读不写, 0 FAIL = 同步健康
# 作者: 皮叔
# ============================================================
$ErrorActionPreference = "Stop"
$PKG_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$FAIL = 0; $PASS = 0; $WARN = 0

function Check($name, $cond, $level = "fail") {
    if ($cond) {
        Write-Host "  ✅ $name"; $script:PASS++
    } else {
        if ($level -eq "warn") {
            Write-Host "  ⚠️ $name"; $script:WARN++
        } else {
            Write-Host "  ❌ $name"; $script:FAIL++
        }
    }
}

Write-Host "=== 豆包办公加强包 同步自检 ==="
Write-Host "包目录: $PKG_DIR"
Write-Host ""

# [1/6] 版本一致性
Write-Host "[1/6] 版本一致性"
$VERSION_MD = (Select-String -Path "$PKG_DIR\version.md" -Pattern '^version:' | Select-Object -First 1).Line -replace '^version:\s*', ''
$VERSION_README = (Select-String -Path "$PKG_DIR\README.md" -Pattern '版本：v[0-9.]+' | Select-Object -First 1).Matches.Value -replace '版本：v', ''
Check "version.md存在" (Test-Path "$PKG_DIR\version.md")
Check "version.md版本非空" ($null -ne $VERSION_MD -and $VERSION_MD -ne "")
Check "README版本与version.md一致" ($VERSION_MD -eq $VERSION_README) "warn"

# [2/6] 必含文件
Write-Host ""
Write-Host "[2/6] 必含文件存在性"
foreach ($f in @("setup.sh","setup.ps1","verify.sh","verify.ps1","rollback.sh","rollback.ps1","README.md","LICENSE","version.md","desensitize-guard.sh","desensitize-guard.ps1","_sync-check.sh","_sync-check.ps1")) {
    Check $f (Test-Path "$PKG_DIR\$f")
}
foreach ($d in @("scripts","templates")) {
    Check "$d\目录" (Test-Path "$PKG_DIR\$d")
}

# [3/6] 双平台脚本配对
Write-Host ""
Write-Host "[3/6] 双平台脚本配对"
foreach ($base in @("setup","verify","rollback","desensitize-guard")) {
    Check "$base.sh存在" (Test-Path "$PKG_DIR\$base.sh")
    Check "$base.ps1存在" (Test-Path "$PKG_DIR\$base.ps1")
}

# [4/6] PS1编码(BOM)
Write-Host ""
Write-Host "[4/6] PS1编码合规(UTF-8 BOM)"
foreach ($f in @("setup.ps1","verify.ps1","rollback.ps1","desensitize-guard.ps1","_sync-check.ps1")) {
    $bytes = [System.IO.File]::ReadAllBytes("$PKG_DIR\$f")[0..2]
    $hasBom = ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    Check "$f BOM" $hasBom
}

# [5/6] 脱敏完整性
Write-Host ""
Write-Host "[5/6] 脱敏完整性(零绝对路径残留)"
$absFiles = Get-ChildItem -Path $PKG_DIR -Include *.sh,*.ps1,*.md -Recurse | Where-Object { $_.Name -notin @("_sync-check.sh","_sync-check.ps1","desensitize-guard.sh","desensitize-guard.ps1") } | Select-String -Pattern '/Users/' -List
Check "零/Users/绝对路径" ($absFiles.Count -eq 0)
$absWinFiles = Get-ChildItem -Path $PKG_DIR -Include *.sh,*.ps1,*.md -Recurse | Where-Object { $_.Name -notin @("_sync-check.sh","_sync-check.ps1","desensitize-guard.sh","desensitize-guard.ps1") } | Select-String -Pattern 'C:\\Users' -List
Check "零C:\Users绝对路径" ($absWinFiles.Count -eq 0)
$mcFiles = Get-ChildItem -Path $PKG_DIR -Include *.sh,*.ps1,*.template -Recurse | Select-String -Pattern '§§MC§§' -List
Check "脱敏占位符已使用(≥3文件)" ($mcFiles.Count -ge 3) "warn"

# [6/6] 无CRLF + 无分发禁止文件
Write-Host ""
Write-Host "[6/6] 卫生检查"
$crlfFiles = Get-ChildItem -Path $PKG_DIR -Include *.sh,*.ps1,*.md -Recurse | Where-Object { (Get-Content $_.FullName -Raw) -match "`r" }
Check "零CRLF行尾" ($crlfFiles.Count -eq 0)
foreach ($f in @(".git",".DS_Store",".github",".gitignore")) {
    Check "无分发禁止文件: $f" (-not (Test-Path "$PKG_DIR\$f")) "warn"
}

Write-Host ""
Write-Host "=== 自检结果 ==="
Write-Host "通过: $PASS | 失败: $FAIL | 警告: $WARN"
if ($FAIL -gt 0) {
    Write-Host "❌ 自检失败 ($FAIL项), 请修复后重跑"
    exit 1
} elseif ($WARN -gt 0) {
    Write-Host "⚠️ 自检通过(有警告 $WARN项)"
    exit 0
} else {
    Write-Host "✅ 全部通过"
    exit 0
}
