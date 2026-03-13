# ============================================================================
# ThemeToggle - Build & Publish
# ============================================================================
# Single entry point for the full release pipeline:
#   1. Read/bump version
#   2. Clean workspace
#   3. Build exe (calls build.bat)
#   4. Verify exe version matches
#   5. Sign exe
#   6. Build NSIS installer
#   7. Sign installer
#   8. Create portable ZIP
#   9. Update WinGet manifests (SHA256, version, URL)
#  10. Print summary with artifact sizes
#
# Usage:
#   .\tools\release\build-and-publish.ps1                    # Build + package (no version bump)
#   .\tools\release\build-and-publish.ps1 -Version 1.6.0    # Bump version first, then build + package
#   .\tools\release\build-and-publish.ps1 -NoInstaller       # Skip NSIS installer
#   .\tools\release\build-and-publish.ps1 -NoSign            # Skip signing
#   .\tools\release\build-and-publish.ps1 -NoWinget          # Skip WinGet manifest update
#   .\tools\release\build-and-publish.ps1 -DryRun            # Show what would be done
#
# Signing env vars:
#   THEMETOGGLE_SIGN_PFX_PATH / THEMETOGGLE_SIGN_PFX_PASSWORD
#   THEMETOGGLE_SIGN_CERT_THUMBPRINT
#   PFX_PATH / PFX_PASS (fallback)
#
# Prerequisites:
#   - Visual Studio Build Tools (for cl.exe)
#   - NSIS (for installer, optional)
#   - Windows SDK (for signtool, optional)
# ============================================================================

param(
    [string]$Version = "",
    [switch]$NoSign,
    [switch]$NoInstaller,
    [switch]$NoZip,
    [switch]$NoWinget,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repoRoot

# ============================================================================
# Helper functions
# ============================================================================

function Write-Step {
    param([string]$Step, [string]$Message)
    Write-Host ""
    Write-Host "[$Step] $Message" -ForegroundColor Cyan
    Write-Host ("-" * 50) -ForegroundColor DarkGray
}

function Write-Success { param([string]$Message) Write-Host "  [OK] $Message" -ForegroundColor Green }
function Write-Warn    { param([string]$Message) Write-Host "  [WARN] $Message" -ForegroundColor Yellow }
function Write-Err     { param([string]$Message) Write-Host "  [ERROR] $Message" -ForegroundColor Red }

function Get-CurrentVersion {
    $versionFile = Join-Path $repoRoot "VERSION"
    if (Test-Path $versionFile) {
        return (Get-Content $versionFile -Raw).Trim()
    }
    return $null
}

function Test-SigningConfigured {
    return ($env:THEMETOGGLE_SIGN_CERT_THUMBPRINT -or $env:THEMETOGGLE_SIGN_PFX_PATH -or $env:PFX_PATH)
}

# ============================================================================
# Signing functions (inlined from tools/signing/sign-release.ps1)
# ============================================================================

function Find-SignTool {
    $cmd = Get-Command signtool.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Path }

    $programFilesX86 = ${env:ProgramFiles(x86)}
    if (-not $programFilesX86) { return $null }

    $sdkRoot = Join-Path $programFilesX86 "Windows Kits\10\bin"
    if (-not (Test-Path $sdkRoot)) { return $null }

    $versions = Get-ChildItem -Path $sdkRoot -Directory -ErrorAction SilentlyContinue |
                Sort-Object Name -Descending
    foreach ($ver in $versions) {
        $candidate = Join-Path $ver.FullName "x64\signtool.exe"
        if (Test-Path $candidate) { return $candidate }
        $candidate = Join-Path $ver.FullName "x86\signtool.exe"
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

function Get-PlainTextFromSecureString {
    param([securestring]$Secure)
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try   { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Try-SignFile {
    param([string]$FilePath)

    $signtool = Find-SignTool
    if (-not $signtool) {
        Write-Warn "signtool.exe not found — skipping signature for $(Split-Path $FilePath -Leaf)"
        return $false
    }

    $timestampUrl = $env:THEMETOGGLE_SIGN_TIMESTAMP_URL
    if (-not $timestampUrl) { $timestampUrl = "http://timestamp.digicert.com" }

    $description = $env:THEMETOGGLE_SIGN_DESCRIPTION
    if (-not $description) { $description = "ThemeToggle" }

    $signArgs = @("sign", "/fd", "SHA256", "/tr", $timestampUrl, "/td", "SHA256", "/d", $description)

    $thumbprint = $env:THEMETOGGLE_SIGN_CERT_THUMBPRINT
    if ($thumbprint) {
        $thumbprint = $thumbprint -replace "\s", ""
        $store = $env:THEMETOGGLE_SIGN_STORE
        if (-not $store) { $store = "My" }

        $storeLocation = $env:THEMETOGGLE_SIGN_STORE_LOCATION
        $useMachineStore = $false
        if ($storeLocation) {
            $normalized = $storeLocation.ToLowerInvariant()
            if ($normalized -in @("localmachine", "machine", "lm")) { $useMachineStore = $true }
        }

        $signArgs += @("/sha1", $thumbprint, "/s", $store)
        if ($useMachineStore) { $signArgs += "/sm" }
    }
    else {
        $pfxPath = $env:THEMETOGGLE_SIGN_PFX_PATH
        if (-not $pfxPath) { $pfxPath = $env:PFX_PATH }
        if (-not $pfxPath) {
            Write-Warn "No signing credentials configured"
            return $false
        }
        if (-not (Test-Path $pfxPath)) {
            Write-Err "PFX not found: $pfxPath"
            return $false
        }

        $password = $env:THEMETOGGLE_SIGN_PFX_PASSWORD
        if (-not $password) { $password = $env:PFX_PASS }
        if (-not $password) {
            $secure = Read-Host "Enter PFX password" -AsSecureString
            $password = Get-PlainTextFromSecureString $secure
        }

        $signArgs += @("/f", $pfxPath, "/p", $password)
    }

    & $signtool @signArgs $FilePath
    if ($LASTEXITCODE -ne 0) {
        Write-Err "signtool failed for $(Split-Path $FilePath -Leaf)"
        return $false
    }
    return $true
}

# ============================================================================
# WinGet manifest update (inlined from dist/update-winget.ps1)
# ============================================================================

function Update-WingetManifests {
    param([string]$Ver)

    $installerFile = Get-ChildItem -Path $repoRoot -Filter "ThemeToggle-Setup-$Ver.exe" -ErrorAction SilentlyContinue |
                     Select-Object -First 1
    if (-not $installerFile) {
        Write-Warn "Installer not found — skipping WinGet manifest update"
        return
    }

    $portablePath = Join-Path $repoRoot "ThemeToggle-Portable.zip"
    if (-not (Test-Path $portablePath)) {
        Write-Warn "Portable ZIP not found — skipping WinGet manifest update"
        return
    }

    $installerSha256 = (Get-FileHash -Path $installerFile.FullName -Algorithm SHA256).Hash
    $portableSha256 = (Get-FileHash -Path $portablePath -Algorithm SHA256).Hash
    Write-Host "  Installer SHA256: $installerSha256" -ForegroundColor DarkGray
    Write-Host "  Portable SHA256 : $portableSha256" -ForegroundColor DarkGray

    # Installer manifest
    $manifestPath = Join-Path $repoRoot "winget\SevIQ.ThemeToggle.installer.yaml"
    if (-not (Test-Path $manifestPath)) {
        Write-Warn "Installer manifest not found: $manifestPath"
        return
    }

    $content = Get-Content $manifestPath -Raw

    # Determine GUID
    if ($content -match "ProductCode:\s*'\{([A-F0-9\-]{36})\}'") {
        $productGuid = "{$($Matches[1])}"
    }
    elseif ($content -match "ProductCode:\s*'\{REPLACE_WITH_PRODUCT_GUID\}'") {
        $productGuid = "{$([guid]::NewGuid().ToString().ToUpper())}"
    }
    else {
        $productGuid = "{$([guid]::NewGuid().ToString().ToUpper())}"
    }

    $repoSlug = $env:GITHUB_REPOSITORY
    if (-not $repoSlug) {
        $repoSlug = "espensev/ThemeToggle"
    }

    $releaseBase = "https://github.com/$repoSlug/releases/download/v$Ver"
    $urlValues = @(
        "$releaseBase/ThemeToggle-Setup-$Ver.exe",
        "$releaseBase/ThemeToggle-Portable.zip"
    )
    $urlIndex = 0
    $content = [regex]::Replace($content, '(?m)^(\s*InstallerUrl:\s*).+$', {
        param($match)
        if ($urlIndex -ge $urlValues.Count) {
            return $match.Value
        }

        $replacement = $match.Groups[1].Value + $urlValues[$urlIndex]
        $urlIndex++
        return $replacement
    })

    $shaValues = @($installerSha256, $portableSha256)
    $shaIndex = 0
    $content = [regex]::Replace($content, '(?m)^(\s*InstallerSha256:\s*).+$', {
        param($match)
        if ($shaIndex -ge $shaValues.Count) {
            return $match.Value
        }

        $replacement = $match.Groups[1].Value + $shaValues[$shaIndex]
        $shaIndex++
        return $replacement
    })

    if ($urlIndex -lt $urlValues.Count -or $shaIndex -lt $shaValues.Count) {
        Write-Warn "Installer manifest did not contain the expected installer and portable entries."
    }

    # Update ProductCode placeholder
    $content = $content -replace "ProductCode:\s*'\{REPLACE_WITH_PRODUCT_GUID\}'", "ProductCode: '$productGuid'"

    # Update version
    $content = $content -replace '(?m)^(\s*PackageVersion:\s*).+$', ('${1}' + $Ver)

    # Update release date
    $today = Get-Date -Format 'yyyy-MM-dd'
    $content = $content -replace '(?m)^(\s*ReleaseDate:\s*).+$', ('${1}' + $today)

    $content | Set-Content $manifestPath -NoNewline -Encoding UTF8
    Write-Success "Updated: SevIQ.ThemeToggle.installer.yaml"

    # Version manifest
    $versionManifestPath = Join-Path $repoRoot "winget\SevIQ.ThemeToggle.yaml"
    if (Test-Path $versionManifestPath) {
        $vm = Get-Content $versionManifestPath -Raw
        $vm = $vm -replace 'PackageVersion:\s*[\d\.]+', "PackageVersion: $Ver"
        $vm | Set-Content $versionManifestPath -NoNewline -Encoding UTF8
        Write-Success "Updated: SevIQ.ThemeToggle.yaml"
    }

    # Locale manifest
    $localeManifestPath = Join-Path $repoRoot "winget\SevIQ.ThemeToggle.locale.en-US.yaml"
    if (Test-Path $localeManifestPath) {
        $lm = Get-Content $localeManifestPath -Raw
        $lm = $lm -replace 'PackageVersion:\s*[\d\.]+', "PackageVersion: $Ver"
        $lm = $lm -replace 'ReleaseNotesUrl:\s*\S+', "ReleaseNotesUrl: https://github.com/$repoSlug/releases/tag/v$Ver"
        $lm | Set-Content $localeManifestPath -NoNewline -Encoding UTF8
        Write-Success "Updated: SevIQ.ThemeToggle.locale.en-US.yaml"
    }

    # Validate — check for leftover placeholders
    $allManifests = Get-ChildItem -Path (Join-Path $repoRoot "winget") -Filter "*.yaml"
    foreach ($manifest in $allManifests) {
        $mc = Get-Content $manifest.FullName -Raw
        if ($mc -match 'REPLACE_WITH_') {
            Write-Warn "Placeholders remain in: $($manifest.Name)"
        }
    }
}

# ============================================================================
# Header
# ============================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ThemeToggle - Build & Publish" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "  [DRY RUN MODE]" -ForegroundColor Yellow
}

$signingEnabled = (Test-SigningConfigured) -and (-not $NoSign)
$currentVersion = Get-CurrentVersion

Write-Host ""
Write-Host "  Current version : $currentVersion" -ForegroundColor White
if ($Version) {
    Write-Host "  Target version  : $Version" -ForegroundColor White
}
Write-Host "  Signing         : $(if ($signingEnabled) { 'Enabled' } else { 'Disabled' })" -ForegroundColor White
Write-Host "  Installer       : $(if (-not $NoInstaller) { 'Yes' } else { 'Skipped' })" -ForegroundColor White
Write-Host "  Portable ZIP    : $(if (-not $NoZip) { 'Yes' } else { 'Skipped' })" -ForegroundColor White
Write-Host "  WinGet update   : $(if (-not $NoWinget) { 'Yes' } else { 'Skipped' })" -ForegroundColor White

# ============================================================================
# Step 1 — Read / bump version
# ============================================================================
if ($Version) {
    Write-Step "1/10" "Bumping version to $Version"

    if ($Version -notmatch '^\d+\.\d+\.\d+$') {
        Write-Err "Version must be in x.y.z format"
        exit 1
    }

    if ($DryRun) {
        Write-Host "  Would run: tools\bump-version.ps1 -Version $Version"
    } else {
        & "$repoRoot\tools\bump-version.ps1" -Version $Version
        if ($LASTEXITCODE -ne 0) {
            Write-Err "bump-version.ps1 failed"
            exit 1
        }
        Write-Success "Version bumped to $Version"
    }
    $currentVersion = $Version
} else {
    Write-Step "1/10" "Using existing version: $currentVersion"

    if (-not $currentVersion) {
        Write-Err "No VERSION file found and -Version not specified"
        exit 1
    }
    Write-Success "Version: $currentVersion"
}

# ============================================================================
# Step 2 — Clean workspace
# ============================================================================
Write-Step "2/10" "Cleaning workspace"

if ($DryRun) {
    Write-Host "  Would remove: *.obj, *.res, *.aps, RC*, RD*, *.old"
} else {
    $patterns = @("*.obj", "*.res", "*.aps", "RCa*", "RDa*", "RC*", "RD*", "*.old")
    $cleaned = 0
    foreach ($pat in $patterns) {
        $files = Get-ChildItem -Path $repoRoot -Filter $pat -File -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
            $cleaned++
        }
    }

    # Clean old deploy artifacts
    $oldZips = Join-Path $repoRoot "deploy\*.zip.old"
    if (Test-Path $oldZips) {
        Remove-Item $oldZips -Force -ErrorAction SilentlyContinue
    }

    Write-Success "Workspace cleaned ($cleaned files removed)"
}

# ============================================================================
# Step 3 — Build exe
# ============================================================================
Write-Step "3/10" "Building ThemeToggle.exe"

if ($DryRun) {
    Write-Host "  Would run: build.bat"
} else {
    $buildScript = Join-Path $repoRoot "build.bat"
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$buildScript`"" `
                             -WorkingDirectory $repoRoot -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0) {
        Write-Err "build.bat failed with exit code $($process.ExitCode)"
        exit 1
    }

    $exePath = Join-Path $repoRoot "ThemeToggle.exe"
    if (-not (Test-Path $exePath)) {
        Write-Err "ThemeToggle.exe not found after build"
        exit 1
    }
    Write-Success "ThemeToggle.exe built"
}

# ============================================================================
# Step 4 — Verify exe version
# ============================================================================
Write-Step "4/10" "Verifying exe version"

if ($DryRun) {
    Write-Host "  Would verify embedded version = $currentVersion"
} else {
    $exePath = Join-Path $repoRoot "ThemeToggle.exe"
    $exeInfo = (Get-Item $exePath).VersionInfo
    $exeVersion = "$($exeInfo.FileMajorPart).$($exeInfo.FileMinorPart).$($exeInfo.FileBuildPart)"
    if ($exeVersion -ne $currentVersion) {
        Write-Err "Version mismatch: exe has $exeVersion, expected $currentVersion"
        Write-Host "  Run: .\tools\bump-version.ps1 -Version $currentVersion" -ForegroundColor Yellow
        exit 1
    }
    Write-Success "Exe version verified: $exeVersion"
}

# ============================================================================
# Step 5 — Sign exe
# ============================================================================
Write-Step "5/10" "Signing ThemeToggle.exe"

if ($NoSign -or -not (Test-SigningConfigured)) {
    Write-Warn "Signing skipped"
} elseif ($DryRun) {
    Write-Host "  Would sign: ThemeToggle.exe"
} else {
    $exePath = Join-Path $repoRoot "ThemeToggle.exe"
    $signed = Try-SignFile -FilePath $exePath
    if ($signed) {
        Write-Success "ThemeToggle.exe signed"
    } else {
        Write-Err "Signing ThemeToggle.exe failed"
        exit 1
    }
}

# ============================================================================
# Step 6 — Build NSIS installer
# ============================================================================
Write-Step "6/10" "Building NSIS installer"

$skipInstaller = $NoInstaller

if ($NoInstaller) {
    Write-Warn "Installer skipped (-NoInstaller)"
} else {
    $nsisAvailable = $null -ne (Get-Command makensis -ErrorAction SilentlyContinue)

    if (-not $nsisAvailable) {
        Write-Warn "NSIS not found — skipping installer"
        Write-Host "  Install from: https://nsis.sourceforge.io/" -ForegroundColor DarkGray
        $skipInstaller = $true
    } elseif ($DryRun) {
        Write-Host "  Would run: makensis /V2 setup.nsi"
    } else {
        $setupNsi = Join-Path $repoRoot "setup.nsi"
        & makensis /V2 $setupNsi
        if ($LASTEXITCODE -ne 0) {
            Write-Err "NSIS build failed"
            exit 1
        }

        $installerPath = Join-Path $repoRoot "ThemeToggle-Setup-$currentVersion.exe"
        if (-not (Test-Path $installerPath)) {
            Write-Err "Installer not found: $installerPath"
            exit 1
        }
        Write-Success "ThemeToggle-Setup-$currentVersion.exe created"
    }
}

# ============================================================================
# Step 7 — Sign installer
# ============================================================================
Write-Step "7/10" "Signing installer"

if ($skipInstaller) {
    Write-Warn "Skipped (no installer)"
} elseif ($NoSign -or -not (Test-SigningConfigured)) {
    Write-Warn "Signing skipped"
} elseif ($DryRun) {
    Write-Host "  Would sign: ThemeToggle-Setup-$currentVersion.exe"
} else {
    $installerPath = Join-Path $repoRoot "ThemeToggle-Setup-$currentVersion.exe"
    $signed = Try-SignFile -FilePath $installerPath
    if ($signed) {
        Write-Success "Installer signed"
    } else {
        Write-Err "Signing installer failed"
        exit 1
    }
}

# ============================================================================
# Step 8 — Create portable ZIP
# ============================================================================
Write-Step "8/10" "Creating portable ZIP"

if ($NoZip) {
    Write-Warn "Portable ZIP skipped (-NoZip)"
} elseif ($DryRun) {
    Write-Host "  Would create: ThemeToggle-Portable.zip"
} else {
    $deployDir = Join-Path $repoRoot "deploy\ThemeToggle"
    if (Test-Path $deployDir) { Remove-Item $deployDir -Recurse -Force }
    New-Item -ItemType Directory -Path $deployDir -Force | Out-Null
    New-Item -ItemType Directory -Path "$deployDir\Resources" -Force | Out-Null

    Copy-Item "$repoRoot\ThemeToggle.exe"              $deployDir
    Copy-Item "$repoRoot\LICENSE.txt"                   $deployDir
    Copy-Item "$repoRoot\README.md"                     $deployDir
    Copy-Item "$repoRoot\setup.bat"                     $deployDir
    Copy-Item "$repoRoot\uninstall.bat"                 $deployDir
    Copy-Item "$repoRoot\Resources\ThemeToggle.ico"     "$deployDir\Resources\"

    $zipPath = Join-Path $repoRoot "ThemeToggle-Portable.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Compress-Archive -Path "$deployDir\*" -DestinationPath $zipPath -Force

    Write-Success "ThemeToggle-Portable.zip created"
}

# ============================================================================
# Step 9 — Update WinGet manifests
# ============================================================================
Write-Step "9/10" "Updating WinGet manifests"

if ($NoWinget) {
    Write-Warn "WinGet update skipped (-NoWinget)"
} elseif ($NoZip) {
    Write-Warn "WinGet update skipped (no portable ZIP)"
} elseif ($skipInstaller) {
    Write-Warn "WinGet update skipped (no installer)"
} elseif ($DryRun) {
    Write-Host "  Would update winget manifests for v$currentVersion"
} else {
    Update-WingetManifests -Ver $currentVersion
}

# ============================================================================
# Step 10 — Summary
# ============================================================================
Write-Step "10/10" "Summary"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Release Complete: v$currentVersion" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Artifacts:" -ForegroundColor White

$artifacts = @(
    @{ Name = "ThemeToggle.exe";                        Desc = "Standalone executable" }
    @{ Name = "ThemeToggle-Setup-$currentVersion.exe";  Desc = "NSIS installer" }
    @{ Name = "ThemeToggle-Portable.zip";               Desc = "Portable package" }
)

foreach ($artifact in $artifacts) {
    $path = Join-Path $repoRoot $artifact.Name
    if (Test-Path $path) {
        $size = [math]::Round((Get-Item $path).Length / 1KB)
        Write-Host "  [OK] $($artifact.Name) ($size KB) - $($artifact.Desc)" -ForegroundColor Green
    } else {
        Write-Host "  [--] $($artifact.Name) (not created)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Test the artifacts" -ForegroundColor White
Write-Host "  2. git add -A && git commit -m 'Release v$currentVersion'" -ForegroundColor White
Write-Host "  3. git tag v$currentVersion && git push --tags" -ForegroundColor White
Write-Host "  4. Create GitHub release, upload artifacts" -ForegroundColor White
Write-Host ""
