# ============================================================================
# ThemeToggle - Refresh Portable Package
# ============================================================================
# Rebuilds ThemeToggle-Portable.zip around the current ThemeToggle.exe and
# updates the corresponding WinGet portable ZIP hash in the installer manifest.
# This is used after post-build signing steps that mutate ThemeToggle.exe.
# ============================================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [string]$RepoSlug = "espensev/ThemeToggle"
)

$ErrorActionPreference = "Stop"

function Fail {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    exit 1
}

function Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repoRoot

$exePath = Join-Path $repoRoot "ThemeToggle.exe"
$deployDir = Join-Path $repoRoot "deploy\ThemeToggle"
$deployExePath = Join-Path $deployDir "ThemeToggle.exe"
$zipPath = Join-Path $repoRoot "ThemeToggle-Portable.zip"
$manifestPath = Join-Path $repoRoot "winget\SevIQ.ThemeToggle.installer.yaml"
$portableUrl = "https://github.com/$RepoSlug/releases/download/v$Version/ThemeToggle-Portable.zip"

foreach ($path in @($exePath, $deployDir, $manifestPath)) {
    if (-not (Test-Path $path)) {
        Fail "Required path not found: $path"
    }
}

Copy-Item $exePath $deployExePath -Force
Ok "Updated deploy\\ThemeToggle\\ThemeToggle.exe"

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Compress-Archive -Path "$deployDir\*" -DestinationPath $zipPath -Force
Ok "Rebuilt ThemeToggle-Portable.zip"

$portableSha256 = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash
$lines = Get-Content $manifestPath
$updatedSha = $false
$currentUrlMatchesPortable = $false

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*InstallerUrl:\s*(\S+)\s*$') {
        $currentUrlMatchesPortable = ($Matches[1] -eq $portableUrl)
        continue
    }

    if ($currentUrlMatchesPortable -and $lines[$i] -match '^(\s*InstallerSha256:\s*)\S+\s*$') {
        $lines[$i] = $Matches[1] + $portableSha256
        $updatedSha = $true
        $currentUrlMatchesPortable = $false
    }
}

if (-not $updatedSha) {
    Fail "Could not find the portable InstallerSha256 entry for $portableUrl"
}

(($lines -join "`n") + "`n") | Set-Content $manifestPath -NoNewline -Encoding UTF8
Ok "Updated portable InstallerSha256 in SevIQ.ThemeToggle.installer.yaml"

Write-Host ""
Write-Host "Portable URL   : $portableUrl"
Write-Host "Portable SHA256: $portableSha256"
