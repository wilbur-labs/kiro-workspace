#!/usr/bin/env pwsh
# codex-review.ps1 — Windows launcher for codex-review.sh.
#
# Why this exists: on Windows, kiro-cli's execute_bash runs commands through
# PowerShell (verified: PowerShell 7), and bare `bash` resolves to a broken WSL
# bash (a WSL install error, not Git Bash). So `bash scripts/codex-review.sh`
# fails when a kiro agent runs it. This launcher locates the real Git Bash and
# runs the cross-platform codex-review.sh through it.
#
# On Linux/macOS you do NOT need this — call `bash scripts/codex-review.sh`
# directly. Core review logic lives in the .sh; this is only the Windows shell
# shim (core-in-bash, thin platform launcher — see
# .kiro/adr/0002-review-outsourced-to-codex.md).
#
# Usage (from kiro's PowerShell-based execute_bash):
#   pwsh -ExecutionPolicy Bypass -File scripts/codex-review.ps1 <repo_dir> [codex review args...]

[CmdletBinding()]
param([Parameter(ValueFromRemainingArguments = $true)] [string[]] $Passthru)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sh = (Join-Path $scriptDir 'codex-review.sh') -replace '\\', '/'

# Locate Git Bash — explicitly NOT the WSL shim on System32 / WindowsApps.
$gitbash = @(
  'C:\Program Files\Git\bin\bash.exe',
  'C:\Program Files (x86)\Git\bin\bash.exe',
  (Join-Path $env:LOCALAPPDATA 'Programs\Git\bin\bash.exe')
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $gitbash) {
  # Fallback: a bash on PATH that is NOT the WSL shim.
  $gitbash = Get-Command bash -All -ErrorAction SilentlyContinue |
    Where-Object { $_.Source -notmatch 'System32|WindowsApps' } |
    Select-Object -First 1 -ExpandProperty Source
}

if (-not $gitbash) {
  Write-Error "Git Bash not found. Install Git for Windows — bare 'bash' here is a broken WSL, not usable for scripts."
  exit 3
}

& $gitbash $sh @Passthru
exit $LASTEXITCODE
