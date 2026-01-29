# ============================================================================
# WinGet Manifest Updater
# ============================================================================
# Automatically updates WinGet manifests with real SHA256 hashes and GUID
# Usage: .\update-winget.ps1 [-Version "1.5.1"] [-DryRun]
# If Version is omitted, reads from VERSION file at repo root.
# Note: run after signing the installer so the SHA256 matches the signed binary.
# ============================================================================

param(
    [string]$Version = "",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Get repository root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
Set-Location $repoRoot

function Get-RepoVersion {
    param([string]$Root)
    $versionPath = Join-Path $Root "VERSION"
    if (Test-Path $versionPath) {
        $raw = Get-Content $versionPath -Raw
        $v = $raw.Trim()
        if ($v) { return $v }
    }
    return $null
}

if (-not $Version) {
    $Version = Get-RepoVersion -Root $repoRoot
}
if (-not $Version) {
    Write-Host "[ERROR] Version not provided and VERSION file not found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  WinGet Manifest Updater" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ==================================================
# Step 1: Locate installer file
# ==================================================
Write-Host "[1/5] Locating installer..." -ForegroundColor Yellow

$installerPath = Get-ChildItem -Path $repoRoot -Filter "ThemeToggle-Setup-$Version.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $installerPath) {
    Write-Host "[ERROR] Installer not found: ThemeToggle-Setup-$Version.exe" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run dist\build-release.bat first to create the installer." -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Found: $($installerPath.Name)" -ForegroundColor Green
Write-Host ""

# ==================================================
# Step 2: Calculate SHA256 hash
# ==================================================
Write-Host "[2/5] Calculating SHA256 hash..." -ForegroundColor Yellow

try {
    $hash = Get-FileHash -Path $installerPath.FullName -Algorithm SHA256
    $sha256 = $hash.Hash
    Write-Host "[OK] SHA256: $sha256" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Failed to calculate hash: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# ==================================================
# Step 3: Generate or retrieve GUID
# ==================================================
Write-Host "[3/5] Handling ProductCode GUID..." -ForegroundColor Yellow

$manifestPath = Join-Path $repoRoot "winget\SevIQ.ThemeToggle.installer.yaml"

# Check if manifest already has a real GUID
$currentContent = Get-Content $manifestPath -Raw
if ($currentContent -match "ProductCode:\s*'(\{[A-F0-9\-]{36}\})'") {
    $productGuid = $Matches[1]
    Write-Host "[OK] Using existing GUID: $productGuid" -ForegroundColor Green
}
elseif ($currentContent -match "ProductCode:\s*'\{REPLACE_WITH_PRODUCT_GUID\}'") {
    # Generate new GUID
    $productGuid = "{$([guid]::NewGuid().ToString().ToUpper())}"
    Write-Host "[OK] Generated new GUID: $productGuid" -ForegroundColor Green
}
else {
    # No ProductCode found, generate one
    $productGuid = "{$([guid]::NewGuid().ToString().ToUpper())}"
    Write-Host "[OK] Generated new GUID: $productGuid" -ForegroundColor Green
}
Write-Host ""

# ==================================================
# Step 4: Update manifests
# ==================================================
Write-Host "[4/5] Updating WinGet manifests..." -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "[DRY RUN] Would update manifests with:" -ForegroundColor Cyan
    Write-Host "  • SHA256: $sha256" -ForegroundColor Cyan
    Write-Host "  • ProductCode: $productGuid" -ForegroundColor Cyan
    Write-Host "  • Version: $Version" -ForegroundColor Cyan
    Write-Host "  • ReleaseDate: $(Get-Date -Format 'yyyy-MM-dd')" -ForegroundColor Cyan
    Write-Host ""
}
else {
    # Update installer manifest
    $installerManifest = Get-Content $manifestPath -Raw
    
# Replace SHA256
$installerManifest = $installerManifest -replace '(?m)^(\\s*InstallerSha256:\\s*).+$', "`$1$sha256"

# Update installer URL
$existingUrlMatch = [regex]::Match($installerManifest, '(?m)^\\s*InstallerUrl:\\s*(\\S+)$')
$installerUrl = "https://github.com/espensev/ThemeToggle/releases/download/v$Version/ThemeToggle-Setup-$Version.exe"
if ($existingUrlMatch.Success) {
    $existingUrl = $existingUrlMatch.Groups[1].Value
    $candidate = $existingUrl -replace 'v\\d+\\.\\d+\\.\\d+/ThemeToggle-Setup-\\d+\\.\\d+\\.\\d+\\.exe', "v$Version/ThemeToggle-Setup-$Version.exe"
    if ($candidate -ne $existingUrl) {
        $installerUrl = $candidate
    }
}
$installerManifest = $installerManifest -replace '(?m)^(\\s*InstallerUrl:\\s*).+$', "`$1$installerUrl"
    
    # Replace ProductCode
    $installerManifest = $installerManifest -replace "ProductCode:\s*'\{REPLACE_WITH_PRODUCT_GUID\}'", "ProductCode: '$productGuid'"
    
# Update version
$installerManifest = $installerManifest -replace '(?m)^(\\s*PackageVersion:\\s*).+$', "`$1$Version"
    
# Update release date
$today = Get-Date -Format 'yyyy-MM-dd'
$installerManifest = $installerManifest -replace '(?m)^(\\s*ReleaseDate:\\s*).+$', "`$1$today"
    
    # Save
    $installerManifest | Set-Content $manifestPath -NoNewline -Encoding UTF8
    Write-Host "[OK] Updated: SevIQ.ThemeToggle.installer.yaml" -ForegroundColor Green
    
    # Update version manifest
    $versionManifestPath = Join-Path $repoRoot "winget\SevIQ.ThemeToggle.yaml"
    $versionManifest = Get-Content $versionManifestPath -Raw
    $versionManifest = $versionManifest -replace 'PackageVersion:\s*[\d\.]+', "PackageVersion: $Version"
    $versionManifest | Set-Content $versionManifestPath -NoNewline -Encoding UTF8
    Write-Host "[OK] Updated: SevIQ.ThemeToggle.yaml" -ForegroundColor Green
    
    # Update locale manifest
    $localeManifestPath = Join-Path $repoRoot "winget\SevIQ.ThemeToggle.locale.en-US.yaml"
    $localeManifest = Get-Content $localeManifestPath -Raw
    $localeManifest = $localeManifest -replace 'PackageVersion:\s*[\d\.]+', "PackageVersion: $Version"
    $localeManifest | Set-Content $localeManifestPath -NoNewline -Encoding UTF8
    Write-Host "[OK] Updated: SevIQ.ThemeToggle.locale.en-US.yaml" -ForegroundColor Green
}
Write-Host ""

# ==================================================
# Step 5: Validation
# ==================================================
Write-Host "[5/5] Validating manifests..." -ForegroundColor Yellow

# Check for placeholders
$allManifests = Get-ChildItem -Path (Join-Path $repoRoot "winget") -Filter "*.yaml"
$hasPlaceholders = $false

foreach ($manifest in $allManifests) {
    $content = Get-Content $manifest.FullName -Raw
    
    if ($content -match 'REPLACE_WITH_') {
        Write-Host "[WARNING] Placeholders still exist in: $($manifest.Name)" -ForegroundColor Yellow
        $hasPlaceholders = $true
    }
}

if (-not $hasPlaceholders) {
    Write-Host "[OK] No placeholders found" -ForegroundColor Green
}

Write-Host ""

# ==================================================
# Summary
# ==================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Update Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Manifest details:" -ForegroundColor White
Write-Host "  • Package: SevIQ.ThemeToggle" -ForegroundColor White
Write-Host "  • Version: $Version" -ForegroundColor White
Write-Host "  • SHA256: $($sha256.Substring(0,16))..." -ForegroundColor White
Write-Host "  • ProductCode: $productGuid" -ForegroundColor White
Write-Host "  • Release Date: $(Get-Date -Format 'yyyy-MM-dd')" -ForegroundColor White
Write-Host ""

if (-not $DryRun) {
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Review changes: git diff winget/" -ForegroundColor White
    Write-Host "  2. Commit manifests: git add winget/ && git commit -m 'Update WinGet manifests v$Version'" -ForegroundColor White
    Write-Host "  3. Create GitHub release with installer" -ForegroundColor White
    Write-Host "  4. Submit to WinGet: https://github.com/microsoft/winget-pkgs/pulls" -ForegroundColor White
    Write-Host ""
    Write-Host "WinGet submission guide:" -ForegroundColor Cyan
    Write-Host "  • Fork microsoft/winget-pkgs" -ForegroundColor White
    Write-Host "  • Copy manifests to: manifests/s/SevIQ/ThemeToggle/$Version/" -ForegroundColor White
    Write-Host "  • Create pull request" -ForegroundColor White
}

Write-Host ""
