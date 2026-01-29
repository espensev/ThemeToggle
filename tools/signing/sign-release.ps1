# ============================================================================
# ThemeToggle Release Signing
# ============================================================================
# Signs ThemeToggle.exe and ThemeToggle-Setup-<version>.exe.
#
# Env vars (choose one path):
#   THEMETOGGLE_SIGN_CERT_THUMBPRINT   - cert thumbprint in Windows cert store
#   THEMETOGGLE_SIGN_STORE             - cert store name (default: My)
#   THEMETOGGLE_SIGN_STORE_LOCATION    - currentuser|localmachine (default: currentuser)
#
#   THEMETOGGLE_SIGN_PFX_PATH          - path to PFX file
#   THEMETOGGLE_SIGN_PFX_PASSWORD      - PFX password (optional; will prompt if missing)
#
# Optional:
#   THEMETOGGLE_SIGN_TIMESTAMP_URL     - timestamp URL (default: http://timestamp.digicert.com)
#   THEMETOGGLE_SIGN_DESCRIPTION       - file description (default: ThemeToggle)
#
# Usage:
#   .\sign-release.ps1 -Version 1.5.1
#   .\sign-release.ps1 -Target exe
#   .\sign-release.ps1 -Target installer -Version 1.5.1
#   (If Version is omitted, reads from VERSION file.)
# ============================================================================

param(
    [string]$Version = "",
    [ValidateSet("all", "exe", "installer")]
    [string]$Target = "all"
)

$ErrorActionPreference = "Stop"

function Get-PlainTextFromSecureString {
    param([securestring]$Secure)
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Find-SignTool {
    $cmd = Get-Command signtool.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Path
    }

    $programFilesX86 = ${env:ProgramFiles(x86)}
    if (-not $programFilesX86) {
        return $null
    }

    $sdkRoot = Join-Path $programFilesX86 "Windows Kits\\10\\bin"
    if (-not (Test-Path $sdkRoot)) {
        return $null
    }

    $versions = Get-ChildItem -Path $sdkRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    foreach ($version in $versions) {
        $candidate = Join-Path $version.FullName "x64\\signtool.exe"
        if (Test-Path $candidate) {
            return $candidate
        }
        $candidate = Join-Path $version.FullName "x86\\signtool.exe"
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

$signtool = Find-SignTool
if (-not $signtool) {
    Write-Error "signtool.exe not found. Install the Windows SDK or add signtool.exe to PATH."
    exit 1
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\\..")
$exePath = Join-Path $repoRoot "ThemeToggle.exe"
$versionFile = Join-Path $repoRoot "VERSION"

if (-not $Version -and (Test-Path $versionFile)) {
    $Version = (Get-Content $versionFile -Raw).Trim()
}

if (-not $Version -and $Target.ToLowerInvariant() -ne "exe") {
    Write-Error "Version not provided and VERSION file not found."
    exit 1
}

$installerPath = Join-Path $repoRoot "ThemeToggle-Setup-$Version.exe"

# Validate exe version matches VERSION file
if (Test-Path $exePath) {
    $exeVersionInfo = (Get-Item $exePath).VersionInfo
    $exeVersion = "$($exeVersionInfo.FileMajorPart).$($exeVersionInfo.FileMinorPart).$($exeVersionInfo.FileBuildPart)"
    if ($Version -and $exeVersion -ne $Version) {
        Write-Error "Version mismatch: exe has $exeVersion, VERSION file has $Version. Run bump-version.ps1 and rebuild."
        exit 1
    }
}

$targets = $Target.ToLowerInvariant()
$missing = @()
$files = @()

if ($targets -in @("all", "exe")) {
    if (-not (Test-Path $exePath)) {
        $missing += $exePath
    } else {
        $files += $exePath
    }
}

if ($targets -in @("all", "installer")) {
    if (-not (Test-Path $installerPath)) {
        $missing += $installerPath
    } else {
        $files += $installerPath
    }
}

if ($missing.Count -gt 0) {
    Write-Error ("Missing artifacts:`n" + ($missing -join "`n"))
    exit 1
}

$timestampUrl = $env:THEMETOGGLE_SIGN_TIMESTAMP_URL
if (-not $timestampUrl) {
    $timestampUrl = "http://timestamp.digicert.com"
}

$description = $env:THEMETOGGLE_SIGN_DESCRIPTION
if (-not $description) {
    $description = "ThemeToggle"
}

$thumbprint = $env:THEMETOGGLE_SIGN_CERT_THUMBPRINT
if ($thumbprint) {
    $thumbprint = $thumbprint -replace "\\s", ""
}

$signArgs = @("sign", "/fd", "SHA256", "/tr", $timestampUrl, "/td", "SHA256", "/d", $description)

if ($thumbprint) {
    $store = $env:THEMETOGGLE_SIGN_STORE
    if (-not $store) {
        $store = "My"
    }

    $storeLocation = $env:THEMETOGGLE_SIGN_STORE_LOCATION
    $useMachineStore = $false
    if ($storeLocation) {
        $normalized = $storeLocation.ToLowerInvariant()
        if ($normalized -in @("localmachine", "machine", "lm")) {
            $useMachineStore = $true
        }
    }

    $signArgs += @("/sha1", $thumbprint, "/s", $store)
    if ($useMachineStore) {
        $signArgs += "/sm"
    }
}
else {
    $pfxPath = $env:THEMETOGGLE_SIGN_PFX_PATH
    if (-not $pfxPath) {
        Write-Error "Set THEMETOGGLE_SIGN_PFX_PATH or THEMETOGGLE_SIGN_CERT_THUMBPRINT."
        exit 1
    }
    if (-not (Test-Path $pfxPath)) {
        Write-Error "PFX not found: $pfxPath"
        exit 1
    }

    $password = $env:THEMETOGGLE_SIGN_PFX_PASSWORD
    if (-not $password) {
        $secure = Read-Host "Enter PFX password" -AsSecureString
        $password = Get-PlainTextFromSecureString $secure
    }

    $signArgs += @("/f", $pfxPath, "/p", $password)
}

foreach ($file in $files) {
    Write-Host "Signing $file..."
    & $signtool @signArgs $file
    if ($LASTEXITCODE -ne 0) {
        Write-Error "signtool failed for $file"
        exit $LASTEXITCODE
    }
}

Write-Host "Signing complete."
