#!/usr/bin/env pwsh
#
# install.ps1 — 將本 repo 內容以 symlink 連回使用者家目錄(原生 PowerShell 版)。
#
# 對應關係(與 install.sh 一致):
#   skills/<name>/   ->  ~/.agents/skills/<name>   且   ~/.claude/skills/<name>
#   hooks/           ->  ~/.claude/hooks
#   settings.json    ->  ~/.claude/settings.json
#   CLAUDE.md        ->  ~/.claude/CLAUDE.md
#
# 平台:
#   - Windows PowerShell 5.1 或 PowerShell 7+(pwsh)皆可。
#   - 建立 symlink 需『開發人員模式』或以系統管理員身分執行。
#
# 特性:
#   - 可重複執行(idempotent):既有 symlink 直接覆蓋更新。
#   - 既有「實體」檔案/資料夾會先備份為 <path>.backup-<timestamp>,不會被刪除。

#   - 權限不足時:預設自動跳 UAC 以系統管理員身分重跑;加 -NoElevate 則改開「開發人員模式」設定頁。
#
# 參數:
#   -NoElevate   不要自動提權;若權限不足,改引導開啟開發人員模式。

param([switch]$NoElevate)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── 解析 repo 根目錄(本 script 所在目錄,可從任意路徑呼叫)─────────────
$Repo       = $PSScriptRoot
$ClaudeDir  = Join-Path $HOME '.claude'
$AgentsDir  = Join-Path $HOME '.agents'
$Stamp      = Get-Date -Format 'yyyyMMdd-HHmmss'

# ── 權限檢查:Windows 建立 symlink 需「開發人員模式」或「系統管理員」 ──────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltinRole]::Administrator)

# 讀取登錄檔判斷是否已開啟開發人員模式
$devMode = $false
try {
  $key = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' `
                          -Name 'AllowDevelopmentWithoutDevLicense' -ErrorAction Stop
  $devMode = [bool]$key.AllowDevelopmentWithoutDevLicense
} catch { $devMode = $false }

if (-not $isAdmin -and -not $devMode) {
  if ($NoElevate) {
    # 退路:引導使用者開啟開發人員模式(直接帶到設定頁)
    Write-Host "⚠️  未開啟開發人員模式,且非系統管理員 → 無法建立 symlink。"
    Write-Host "→ 即將開啟『開發人員模式』設定頁,請把開關打開後重新執行本腳本。"
    Start-Process 'ms-settings:developers'
    exit 1
  }
  # 預設:自動以系統管理員身分重新啟動(跳出 UAC 視窗)
  Write-Host "⚠️  權限不足(未開發人員模式、非管理員)。將跳出 UAC 以系統管理員身分重跑..."
  $hostExe = (Get-Process -Id $PID).Path   # 沿用目前的 PowerShell 主機(powershell.exe 或 pwsh.exe)
  if (-not $hostExe) { $hostExe = 'powershell.exe' }
  # 提權後 $isAdmin=true,本區塊自然跳過,不會無限提權,故不需再傳 -NoElevate
  $argLine = "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`""
  try {
    Start-Process -FilePath $hostExe -Verb RunAs -ArgumentList $argLine
    Write-Host "→ 已在新的系統管理員視窗中繼續安裝;此視窗可關閉。"
  } catch {
    Write-Host "✗ 提權被取消或失敗。請改開『開發人員模式』(設定 → 隱私權與安全性 → 開發人員選項)後重試,"
    Write-Host "  或手動以系統管理員身分執行。也可加 -NoElevate 直接跳到設定頁。"
  }
  exit
}

# make_link <來源(repo 內絕對路徑)> <目標(家目錄路徑)>
function Make-Link {
  param([string]$Src, [string]$Dest)

  if (-not (Test-Path -LiteralPath $Src)) {
    Write-Host "  ⤬ 跳過(來源不存在):$Src"
    return
  }

  $parent = Split-Path -Parent $Dest
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }

  $existing = Get-Item -LiteralPath $Dest -Force -ErrorAction SilentlyContinue
  if ($existing) {
    if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) {
      # 既有 symlink / junction(含失效的 dangling):只刪連結本身,不動目標內容
      $existing.Delete()
    } else {
      # 既有實體檔案/資料夾:備份保留,不刪除
      $backup = "$Dest.backup-$Stamp"
      Move-Item -LiteralPath $Dest -Destination $backup
      Write-Host "  ⚑ 已備份既有檔案:$Dest -> $backup"
    }
  }

  New-Item -ItemType SymbolicLink -Path $Dest -Target $Src | Out-Null
  Write-Host "  ✓ $Dest  ->  $Src"
}

Write-Host "Repo : $Repo"
Write-Host "家目錄: $HOME"
Write-Host ""

Write-Host "[1/4] settings.json"
Make-Link (Join-Path $Repo 'settings.json') (Join-Path $ClaudeDir 'settings.json')

Write-Host "[2/4] CLAUDE.md"
Make-Link (Join-Path $Repo 'CLAUDE.md') (Join-Path $ClaudeDir 'CLAUDE.md')

Write-Host "[3/4] hooks(整個資料夾)"
Make-Link (Join-Path $Repo 'hooks') (Join-Path $ClaudeDir 'hooks')

Write-Host "[4/4] skills(每個同時連到 .agents 與 .claude)"
New-Item -ItemType Directory -Force -Path (Join-Path $AgentsDir 'skills') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $ClaudeDir 'skills') | Out-Null
$foundSkill = $false
$skillsRoot = Join-Path $Repo 'skills'
if (Test-Path -LiteralPath $skillsRoot) {
  foreach ($skill in Get-ChildItem -LiteralPath $skillsRoot -Directory) {
    $foundSkill = $true
    $name = $skill.Name
    Make-Link $skill.FullName (Join-Path $AgentsDir "skills\$name")
    Make-Link $skill.FullName (Join-Path $ClaudeDir "skills\$name")
  }
}
if (-not $foundSkill) { Write-Host "  ⤬ skills/ 目錄內沒有任何 skill 子資料夾" }

Write-Host ""
Write-Host "✅ 完成。可重複執行本腳本以同步更新連結。"
