# ============================================================================
# WinGet Manifest Validator
# ============================================================================
# Validates local winget manifests for:
#   - file presence
#   - PackageVersion consistency across manifests
#   - expected release URLs for installer + portable zip
#   - SHA256 shape and placeholder absence
#   - winget schema validation (winget validate winget)
#
# Usage:
#   .\tools\validate-winget.ps1
#   .\tools\validate-winget.ps1 -Version 1.6.0
#   .\tools\validate-winget.ps1 -Version 1.6.0 -RepoSlug espensev/ThemeToggle
# ============================================================================

param(
    [string]$Version = "",
    [string]$RepoSlug = "",
    [switch]$SkipWingetCli
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

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

if (-not $Version) {
    $versionPath = Join-Path $repoRoot "VERSION"
    if (-not (Test-Path $versionPath)) {
        Fail "VERSION file not found. Pass -Version explicitly."
    }
    $Version = (Get-Content $versionPath -Raw).Trim()
}

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Fail "Version must be in x.y.z format. Got: '$Version'"
}

if (-not $RepoSlug) {
    if ($env:GITHUB_REPOSITORY) {
        $RepoSlug = $env:GITHUB_REPOSITORY
    } else {
        $originUrl = (& git remote get-url origin 2>$null)
        if ($LASTEXITCODE -eq 0 -and $originUrl) {
            if ($originUrl -match 'github\.com[:/](?<slug>[^/]+/[^/.]+)(?:\.git)?$') {
                $RepoSlug = $Matches["slug"]
            }
        }
    }
}

if (-not $RepoSlug) {
    Fail "Could not determine repository slug. Pass -RepoSlug (e.g., espensev/ThemeToggle)."
}

if ($RepoSlug -notmatch '^[^/\s]+/[^/\s]+$') {
    Fail "Invalid RepoSlug format: '$RepoSlug'. Expected owner/repo."
}

$versionYamlPath = Join-Path $repoRoot "winget\SevIQ.ThemeToggle.yaml"
$installerYamlPath = Join-Path $repoRoot "winget\SevIQ.ThemeToggle.installer.yaml"
$localeYamlPath = Join-Path $repoRoot "winget\SevIQ.ThemeToggle.locale.en-US.yaml"

foreach ($path in @($versionYamlPath, $installerYamlPath, $localeYamlPath)) {
    if (-not (Test-Path $path)) {
        Fail "Missing manifest file: $path"
    }
}
Ok "Manifest files found"

$versionYaml = Get-Content $versionYamlPath -Raw
$installerYaml = Get-Content $installerYamlPath -Raw
$localeYaml = Get-Content $localeYamlPath -Raw

foreach ($manifest in @(
    @{ Name = "SevIQ.ThemeToggle.yaml"; Content = $versionYaml },
    @{ Name = "SevIQ.ThemeToggle.installer.yaml"; Content = $installerYaml },
    @{ Name = "SevIQ.ThemeToggle.locale.en-US.yaml"; Content = $localeYaml }
)) {
    if ($manifest.Content -notmatch "(?m)^PackageVersion:\s*$([regex]::Escape($Version))\s*$") {
        Fail "PackageVersion mismatch in $($manifest.Name). Expected: $Version"
    }
}
Ok "PackageVersion is consistent across manifests ($Version)"

if ($installerYaml -match 'REPLACE_WITH_') {
    Fail "Installer manifest still contains placeholder values."
}
Ok "No placeholder values found in installer manifest"

$releaseBase = "https://github.com/$RepoSlug/releases/download/v$Version"
$expectedInstallerUrl = "$releaseBase/ThemeToggle-Setup-$Version.exe"
$expectedPortableUrl = "$releaseBase/ThemeToggle-Portable.zip"

if ($installerYaml -notmatch [regex]::Escape($expectedInstallerUrl)) {
    Fail "Missing expected installer URL: $expectedInstallerUrl"
}
if ($installerYaml -notmatch [regex]::Escape($expectedPortableUrl)) {
    Fail "Missing expected portable URL: $expectedPortableUrl"
}
Ok "Installer and portable URLs match version/repo"

if ($installerYaml -notmatch "(?m)^\s*InstallerType:\s*zip\s*$") {
    Fail "Portable installer entry is missing (InstallerType: zip)."
}

if ($installerYaml -notmatch "(?m)^\s*PortableCommandAlias:\s*ThemeToggle\s*$") {
    Fail "Portable command alias is missing or incorrect (expected ThemeToggle)."
}
Ok "Portable installer shape is present"

$shaLines = [regex]::Matches($installerYaml, '(?m)^\s*InstallerSha256:\s*(\S+)\s*$')
if ($shaLines.Count -lt 2) {
    Fail "Expected at least 2 InstallerSha256 entries (installer + portable). Found: $($shaLines.Count)"
}

foreach ($shaLine in $shaLines) {
    $hash = $shaLine.Groups[1].Value
    if ($hash -notmatch '^[A-Fa-f0-9]{64}$') {
        Fail "Invalid InstallerSha256 value: $hash"
    }
}
Ok "InstallerSha256 values are valid"

if (-not $SkipWingetCli) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Fail "winget CLI is not available on PATH."
    }

    & winget validate winget
    if ($LASTEXITCODE -ne 0) {
        Fail "winget validate winget failed with exit code $LASTEXITCODE."
    }
    Ok "winget validate succeeded"
}

Write-Host "[PASS] WinGet manifests validated successfully." -ForegroundColor Green
