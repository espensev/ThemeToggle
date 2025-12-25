@echo off
REM ============================================================================
REM Winget Manifest Preparation Script
REM ============================================================================
REM This script automates the preparation of Winget manifests by:
REM   1. Calculating SHA256 hash of the installer
REM   2. Generating a unique GUID for ProductCode
REM   3. Creating a customization summary
REM ============================================================================

setlocal enabledelayedexpansion

echo.
echo ========================================
echo   Winget Manifest Preparation
echo ========================================
echo.

REM Check if installer exists
if not exist "ThemeToggle-Setup-1.2.0.exe" (
    echo ERROR: ThemeToggle-Setup-1.2.0.exe not found!
    echo.
    echo Please build the installer first:
    echo   1. Run: build.bat
    echo   2. Run: build-installer.bat
    echo   3. Then run this script again
    echo.
    pause
    exit /b 1
)

echo [1/3] Calculating SHA256 hash...
echo.

REM Calculate SHA256 hash using PowerShell
for /f "tokens=*" %%i in ('powershell -Command "(Get-FileHash 'ThemeToggle-Setup-1.2.0.exe' -Algorithm SHA256).Hash"') do (
    set "SHA256_HASH=%%i"
)

echo SHA256 Hash: %SHA256_HASH%
echo.

REM Generate GUID for ProductCode
echo [2/3] Generating GUID for ProductCode...
echo.

for /f "tokens=*" %%i in ('powershell -Command "[guid]::NewGuid().ToString().ToUpper()"') do (
    set "PRODUCT_GUID=%%i"
)

echo Product GUID: {%PRODUCT_GUID%}
echo.

REM Display current username for GitHub URL
echo [3/3] Gathering information...
echo.

REM Try to get GitHub username from git config
for /f "tokens=*" %%i in ('git config user.name 2^>nul') do (
    set "GIT_USERNAME=%%i"
)

if defined GIT_USERNAME (
    echo Git Username: %GIT_USERNAME%
) else (
    echo Git Username: [Not configured - please enter manually]
)
echo.

REM Create summary file
echo ========================================
echo   Summary
echo ========================================
echo.

set "SUMMARY_FILE=winget\MANIFEST_CUSTOMIZATION_SUMMARY.txt"

echo Creating customization summary: %SUMMARY_FILE%
echo.

(
echo ============================================================================
echo Winget Manifest Customization Summary
echo ============================================================================
echo Generated: %date% %time%
echo.
echo Copy and paste these values into your Winget manifest files:
echo.
echo ----------------------------------------------------------------------------
echo 1. SHA256 Hash (for installer.yaml^):
echo ----------------------------------------------------------------------------
echo.
echo   InstallerSha256: %SHA256_HASH%
echo.
echo ----------------------------------------------------------------------------
echo 2. Product Code (for installer.yaml^):
echo ----------------------------------------------------------------------------
echo.
echo   ProductCode: '{%PRODUCT_GUID%}'
echo.
echo ----------------------------------------------------------------------------
echo 3. Publisher Information (replace in ALL files^):
echo ----------------------------------------------------------------------------
echo.
echo   PackageIdentifier: YourPublisher.ThemeToggle
echo   Replace "YourPublisher" with your actual publisher name
echo   Example: JohnDoe.ThemeToggle
echo.
if defined GIT_USERNAME (
echo   Suggested: %GIT_USERNAME%.ThemeToggle
echo.
)
echo ----------------------------------------------------------------------------
echo 4. GitHub URLs (replace "yourusername" in ALL files^):
echo ----------------------------------------------------------------------------
echo.
echo   PublisherUrl: https://github.com/yourusername
echo   PackageUrl: https://github.com/yourusername/ThemeToggle
echo   LicenseUrl: https://github.com/yourusername/ThemeToggle/blob/main/LICENSE.txt
echo   InstallerUrl: https://github.com/yourusername/ThemeToggle/releases/download/v1.2.0/ThemeToggle-Setup-1.2.0.exe
echo   ReleaseNotesUrl: https://github.com/yourusername/ThemeToggle/releases/tag/v1.2.0
echo.
if defined GIT_USERNAME (
echo   Replace "yourusername" with: %GIT_USERNAME%
echo.
)
echo ----------------------------------------------------------------------------
echo 5. Publisher Details (for locale.yaml^):
echo ----------------------------------------------------------------------------
echo.
echo   Publisher: Your Publisher Name
echo   PublisherSupportUrl: https://github.com/yourusername/ThemeToggle/issues
echo   Author: Your Name
echo.
echo   Replace with your actual name or organization.
echo.
echo ----------------------------------------------------------------------------
echo 6. Files to Edit:
echo ----------------------------------------------------------------------------
echo.
echo   winget\YourPublisher.ThemeToggle.yaml
echo   winget\YourPublisher.ThemeToggle.installer.yaml
echo   winget\YourPublisher.ThemeToggle.locale.en-US.yaml
echo.
echo ============================================================================
echo Next Steps:
echo ============================================================================
echo.
echo 1. Edit the 3 manifest files in the winget\ folder
echo 2. Replace all placeholders with the values above
echo 3. Validate: winget validate --manifest winget
echo 4. Test: winget install --manifest winget\YourPublisher.ThemeToggle.yaml
echo 5. Follow WINGET_SUBMISSION_GUIDE.md for submission
echo.
echo ============================================================================
) > "%SUMMARY_FILE%"

echo Done!
echo.

REM Display summary to console
type "%SUMMARY_FILE%"

echo.
echo Customization summary saved to: %SUMMARY_FILE%
echo.
echo ========================================
echo   Ready to Customize Manifests!
echo ========================================
echo.
echo Next: Edit the 3 manifest files in the winget\ folder
echo       Replace placeholders with the values above
echo.

pause
endlocal
