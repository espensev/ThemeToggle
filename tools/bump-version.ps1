# ============================================================================
# ThemeToggle Version Bump
# ============================================================================
# Updates VERSION and aligns all version references across the project.
# Usage: .\tools\bump-version.ps1 -Version 1.5.2
# ============================================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Error "Version must be in x.y.z format."
    exit 1
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

# Parse version components
$versionParts = $Version -split '\.'
$major = $versionParts[0]
$minor = $versionParts[1]
$patch = $versionParts[2]
$versionComma = "$major,$minor,$patch,0"
$versionDotZero = "$Version.0"

Write-Host "Updating version to $Version..."

# VERSION file
Set-Content -Path (Join-Path $repoRoot "VERSION") -Value $Version -NoNewline -Encoding UTF8
Write-Host "  Updated: VERSION"

# ThemeToggle.rc (embedded exe version)
$rcPath = Join-Path $repoRoot "ThemeToggle.rc"
if (Test-Path $rcPath) {
    $rc = Get-Content $rcPath -Raw
    $rc = $rc -replace 'FILEVERSION\s+\d+,\d+,\d+,\d+', "FILEVERSION     $versionComma"
    $rc = $rc -replace 'PRODUCTVERSION\s+\d+,\d+,\d+,\d+', "PRODUCTVERSION  $versionComma"
    $rc = $rc -replace 'VALUE "FileVersion",\s*"[^"]*"', "VALUE `"FileVersion`",      `"$versionDotZero`""
    $rc = $rc -replace 'VALUE "ProductVersion",\s*"[^"]*"', "VALUE `"ProductVersion`",   `"$versionDotZero`""
    $rc | Set-Content $rcPath -NoNewline -Encoding UTF8
    Write-Host "  Updated: ThemeToggle.rc"
}

# Manifest - update version in assemblyIdentity
$manifestPath = Join-Path $repoRoot "Resources/ThemeToggle.manifest"
if (Test-Path $manifestPath) {
    $manifest = Get-Content $manifestPath -Raw
    # Simple replacement - version="x.x.x.x" pattern
    $manifest = $manifest -replace 'version="\d+\.\d+\.\d+\.\d+"', "version=`"$versionDotZero`""
    $manifest | Set-Content $manifestPath -NoNewline -Encoding UTF8
    Write-Host "  Updated: Resources/ThemeToggle.manifest"
}

# setup.nsi
$nsiPath = Join-Path $repoRoot "setup.nsi"
if (Test-Path $nsiPath) {
    $nsi = Get-Content $nsiPath -Raw
    $nsi = $nsi -replace '!define PRODUCT_VERSION "[^"]*"', "!define PRODUCT_VERSION `"$Version`""
    $nsi | Set-Content $nsiPath -NoNewline -Encoding UTF8
    Write-Host "  Updated: setup.nsi"
}

# winget manifests - simple version replacement
$wingetFiles = @(
    "winget/SevIQ.ThemeToggle.yaml",
    "winget/SevIQ.ThemeToggle.locale.en-US.yaml"
)
foreach ($file in $wingetFiles) {
    $fullPath = Join-Path $repoRoot $file
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        $content = $content -replace '(?m)^PackageVersion:\s*[\d.]+', "PackageVersion: $Version"
        $content | Set-Content $fullPath -NoNewline -Encoding UTF8
        Write-Host "  Updated: $file"
    }
}

# winget installer manifest (more fields)
$installerYaml = Join-Path $repoRoot "winget/SevIQ.ThemeToggle.installer.yaml"
if (Test-Path $installerYaml) {
    $content = Get-Content $installerYaml -Raw
    $content = $content -replace '(?m)^PackageVersion:\s*[\d.]+', "PackageVersion: $Version"
    $content = $content -replace 'releases/download/v[\d.]+/ThemeToggle-Setup-[\d.]+\.exe', "releases/download/v$Version/ThemeToggle-Setup-$Version.exe"
    $content = $content -replace 'InstallerSha256:\s*[A-Fa-f0-9]{64}', 'InstallerSha256: REPLACE_WITH_ACTUAL_SHA256_HASH'
    $content | Set-Content $installerYaml -NoNewline -Encoding UTF8
    Write-Host "  Updated: winget/SevIQ.ThemeToggle.installer.yaml"
}

# signing docs (keep version examples aligned if present)
$signReadme = Join-Path $repoRoot "tools/signing/README.md"
if (Test-Path $signReadme) {
    $content = Get-Content $signReadme -Raw
    $content = $content -replace 'ThemeToggle-Setup-\d+\.\d+\.\d+\.exe', "ThemeToggle-Setup-$Version.exe"
    $content | Set-Content $signReadme -NoNewline -Encoding UTF8
    Write-Host "  Updated: tools/signing/README.md"
}

Write-Host ""
Write-Host "Version updated to $Version. Rebuild to apply."
