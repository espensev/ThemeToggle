# ============================================================================
# ThemeToggle Release Orchestrator
# ============================================================================
# Complete release pipeline in one command:
#   1. Bump version (optional, if -Version provided)
#   2. Build executable
#   3. Sign executable (if signing configured)
#   4. Build NSIS installer
#   5. Sign installer (if signing configured)
#   6. Create portable ZIP
#   7. Update WinGet manifests with SHA256
#
# Usage:
#   .\tools\release.ps1                      # Build release using VERSION file
#   .\tools\release.ps1 -Version 1.5.3       # Bump to 1.5.3 first, then build
#   .\tools\release.ps1 -SkipWinget          # Skip winget manifest update
#   .\tools\release.ps1 -DryRun              # Show what would be done
#
# Prerequisites:
#   - Visual Studio Build Tools (for cl.exe)
#   - NSIS (for installer, optional)
#   - Windows SDK (for signtool, optional)
#   - Signing env vars (optional): THEMETOGGLE_SIGN_CERT_THUMBPRINT or THEMETOGGLE_SIGN_PFX_PATH
# ============================================================================

param(
    [string]$Version = "",
    [switch]$SkipWinget,
    [switch]$SkipSign,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

function Write-Step {
    param([string]$Step, [string]$Message)
    Write-Host ""
    Write-Host "[$Step] $Message" -ForegroundColor Cyan
    Write-Host ("-" * 50) -ForegroundColor DarkGray
}

function Write-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Get-CurrentVersion {
    $versionFile = Join-Path $repoRoot "VERSION"
    if (Test-Path $versionFile) {
        return (Get-Content $versionFile -Raw).Trim()
    }
    return $null
}

function Test-SigningConfigured {
    return ($env:THEMETOGGLE_SIGN_CERT_THUMBPRINT -or $env:THEMETOGGLE_SIGN_PFX_PATH)
}

# ============================================================================
# Header
# ============================================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ThemeToggle Release Orchestrator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "  [DRY RUN MODE]" -ForegroundColor Yellow
}

$signingEnabled = Test-SigningConfigured
$currentVersion = Get-CurrentVersion

Write-Host ""
Write-Host "  Current version: $currentVersion" -ForegroundColor White
if ($Version) {
    Write-Host "  Target version:  $Version" -ForegroundColor White
}
Write-Host "  Signing:         $(if ($signingEnabled -and -not $SkipSign) { 'Enabled' } else { 'Disabled' })" -ForegroundColor White
Write-Host "  WinGet update:   $(if (-not $SkipWinget) { 'Yes' } else { 'Skipped' })" -ForegroundColor White

# ============================================================================
# Step 1: Bump Version (if specified)
# ============================================================================
if ($Version) {
    Write-Step "1/6" "Bumping version to $Version"

    if ($Version -notmatch '^\d+\.\d+\.\d+$') {
        Write-Err "Version must be in x.y.z format"
        exit 1
    }

    if ($DryRun) {
        Write-Host "Would run: bump-version.ps1 -Version $Version"
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
    Write-Step "1/6" "Using existing version: $currentVersion"

    if (-not $currentVersion) {
        Write-Err "No VERSION file found and -Version not specified"
        exit 1
    }
    Write-Success "Version: $currentVersion"
}

# ============================================================================
# Step 2: Build Executable
# ============================================================================
Write-Step "2/6" "Building ThemeToggle.exe"

if ($DryRun) {
    Write-Host "Would run: build.bat"
} else {
    $buildScript = Join-Path $repoRoot "build.bat"

    # Run build.bat using cmd
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$buildScript`"" -WorkingDirectory $repoRoot -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0) {
        Write-Err "build.bat failed with exit code $($process.ExitCode)"
        exit 1
    }

    $exePath = Join-Path $repoRoot "ThemeToggle.exe"
    if (-not (Test-Path $exePath)) {
        Write-Err "ThemeToggle.exe not found after build"
        exit 1
    }

    # Verify embedded version
    $exeInfo = (Get-Item $exePath).VersionInfo
    $exeVersion = "$($exeInfo.FileMajorPart).$($exeInfo.FileMinorPart).$($exeInfo.FileBuildPart)"
    if ($exeVersion -ne $currentVersion) {
        Write-Err "Version mismatch: exe has $exeVersion, expected $currentVersion"
        Write-Host "Run: .\tools\bump-version.ps1 -Version $currentVersion" -ForegroundColor Yellow
        exit 1
    }

    Write-Success "ThemeToggle.exe built (v$exeVersion)"
}

# ============================================================================
# Step 3: Sign Executable
# ============================================================================
Write-Step "3/6" "Signing ThemeToggle.exe"

if ($SkipSign -or -not $signingEnabled) {
    Write-Warning "Signing skipped (not configured or -SkipSign)"
} elseif ($DryRun) {
    Write-Host "Would run: sign-release.ps1 -Target exe"
} else {
    & "$repoRoot\tools\signing\sign-release.ps1" -Target exe
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Signing ThemeToggle.exe failed"
        exit 1
    }
    Write-Success "ThemeToggle.exe signed"
}

# ============================================================================
# Step 4: Build NSIS Installer
# ============================================================================
Write-Step "4/6" "Building NSIS installer"

$nsisAvailable = $null -ne (Get-Command makensis -ErrorAction SilentlyContinue)

if (-not $nsisAvailable) {
    Write-Warning "NSIS not found - skipping installer"
    Write-Host "Install from: https://nsis.sourceforge.io/" -ForegroundColor DarkGray
    $skipInstaller = $true
} elseif ($DryRun) {
    Write-Host "Would run: makensis /V2 setup.nsi"
    $skipInstaller = $false
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
    $skipInstaller = $false
}

# ============================================================================
# Step 5: Sign Installer
# ============================================================================
Write-Step "5/6" "Signing installer"

if ($skipInstaller) {
    Write-Warning "Skipped (no installer)"
} elseif ($SkipSign -or -not $signingEnabled) {
    Write-Warning "Signing skipped (not configured or -SkipSign)"
} elseif ($DryRun) {
    Write-Host "Would run: sign-release.ps1 -Target installer -Version $currentVersion"
} else {
    & "$repoRoot\tools\signing\sign-release.ps1" -Target installer -Version $currentVersion
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Signing installer failed"
        exit 1
    }
    Write-Success "Installer signed"
}

# ============================================================================
# Step 6: Create Portable ZIP + Update WinGet
# ============================================================================
Write-Step "6/6" "Creating portable package & updating manifests"

if ($DryRun) {
    Write-Host "Would create: ThemeToggle-Portable.zip"
    if (-not $SkipWinget) {
        Write-Host "Would run: update-winget.ps1 -Version $currentVersion"
    }
} else {
    # Create portable ZIP
    $deployDir = Join-Path $repoRoot "deploy\ThemeToggle"
    if (Test-Path $deployDir) {
        Remove-Item $deployDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $deployDir -Force | Out-Null
    New-Item -ItemType Directory -Path "$deployDir\Resources" -Force | Out-Null

    Copy-Item "$repoRoot\ThemeToggle.exe" $deployDir
    Copy-Item "$repoRoot\LICENSE.txt" $deployDir
    Copy-Item "$repoRoot\README.md" $deployDir
    Copy-Item "$repoRoot\setup.bat" $deployDir
    Copy-Item "$repoRoot\uninstall.bat" $deployDir
    Copy-Item "$repoRoot\Resources\ThemeToggle.ico" "$deployDir\Resources\"

    # Copy launchers
    $launchersDir = Join-Path $repoRoot "dist\launchers"
    if (Test-Path $launchersDir) {
        Copy-Item "$launchersDir\*.vbs" $deployDir -ErrorAction SilentlyContinue
        Copy-Item "$launchersDir\*.ps1" $deployDir -ErrorAction SilentlyContinue
    }

    $zipPath = Join-Path $repoRoot "ThemeToggle-Portable.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Compress-Archive -Path "$deployDir\*" -DestinationPath $zipPath -Force

    Write-Success "ThemeToggle-Portable.zip created"

    # Update WinGet manifests
    if (-not $SkipWinget -and -not $skipInstaller) {
        Write-Host ""
        & "$repoRoot\dist\update-winget.ps1" -Version $currentVersion
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "WinGet manifest update had issues"
        }
    } elseif ($SkipWinget) {
        Write-Warning "WinGet update skipped (-SkipWinget)"
    } else {
        Write-Warning "WinGet update skipped (no installer)"
    }
}

# ============================================================================
# Summary
# ============================================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Release Complete: v$currentVersion" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Artifacts:" -ForegroundColor White

$artifacts = @(
    @{ Name = "ThemeToggle.exe"; Desc = "Standalone executable" }
    @{ Name = "ThemeToggle-Setup-$currentVersion.exe"; Desc = "NSIS installer" }
    @{ Name = "ThemeToggle-Portable.zip"; Desc = "Portable package" }
)

foreach ($artifact in $artifacts) {
    $path = Join-Path $repoRoot $artifact.Name
    if (Test-Path $path) {
        $size = [math]::Round((Get-Item $path).Length / 1KB)
        Write-Host "  [OK] $($artifact.Name) ($size KB)" -ForegroundColor Green
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
Write-Host "  5. Submit to WinGet (see winget/ folder)" -ForegroundColor White
Write-Host ""
