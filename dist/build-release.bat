@echo off
REM ============================================================================
REM Unified Build & Release Script
REM ============================================================================
REM Complete build pipeline:
REM   1. Clean workspace
REM   2. Build ThemeToggle.exe
REM   3. Sign ThemeToggle.exe (if signing env is set)
REM   4. Build NSIS installer
REM   5. Sign installer (if signing env is set)
REM   6. Create portable ZIP package
REM   7. Validate all outputs
REM   8. Display next steps for distribution
REM ============================================================================

setlocal enabledelayedexpansion

REM Save current directory and switch to repository root
pushd "%~dp0\.."

REM Read product version (VERSION file preferred, fallback to setup.nsi)
set "PRODUCT_VERSION="
if exist "VERSION" (
    for /f "usebackq tokens=* delims=" %%v in ("VERSION") do (
        set "PRODUCT_VERSION=%%v"
    )
)
if not defined PRODUCT_VERSION (
    for /f "tokens=3 delims=\" %%v in ('findstr /R /C:"PRODUCT_VERSION \"[0-9]" setup.nsi') do (
        set "PRODUCT_VERSION=%%v"
    )
)

set SIGNING_ENABLED=0
if defined THEMETOGGLE_SIGN_PFX_PATH set SIGNING_ENABLED=1
if defined THEMETOGGLE_SIGN_CERT_THUMBPRINT set SIGNING_ENABLED=1

echo.
echo ========================================
echo   ThemeToggle - Build Release
echo ========================================
echo.

REM ==================================================
REM Step 1: Clean workspace
REM ==================================================
echo [1/8] Cleaning workspace...
echo ------------------------------------
del *.obj *.res RC* RD* *.aps 2>nul
if exist "ThemeToggle-Setup-*.exe" (
    echo Found existing installer, backing up...
    ren "ThemeToggle-Setup-*.exe" "*.old" 2>nul
)
echo [OK] Workspace cleaned
echo.

REM ==================================================
REM Step 2: Build executable
REM ==================================================
echo [2/8] Building ThemeToggle.exe...
echo ------------------------------------
call build.bat
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed! Check Visual Studio installation.
    goto ERROR
)
echo.

REM ==================================================
REM Step 3: Verify executable
REM ==================================================
echo [3/8] Verifying executable...
echo ------------------------------------
if not exist "ThemeToggle.exe" (
    echo [ERROR] ThemeToggle.exe not found after build!
    goto ERROR
)

REM Test execution
ThemeToggle.exe /? >nul 2>&1
if %ERRORLEVEL% GTR 10 (
    echo [WARNING] Executable may have issues
) else (
    echo [OK] ThemeToggle.exe verified
)
echo.

REM ==================================================
REM Step 4: Sign executable (optional)
REM ==================================================
echo [4/8] Signing ThemeToggle.exe (optional)...
echo ------------------------------------
if %SIGNING_ENABLED% EQU 1 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "tools\signing\sign-release.ps1" -Target exe
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Signing ThemeToggle.exe failed
        goto ERROR
    )
    echo [OK] ThemeToggle.exe signed
) else (
    echo [SKIP] Signing not configured
)
echo.

REM ==================================================
REM Step 5: Build NSIS installer
REM ==================================================
echo [5/8] Building NSIS installer...
echo ------------------------------------

REM Check for NSIS
where makensis >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] NSIS not found in PATH
    echo [INFO] Install NSIS from: https://nsis.sourceforge.io/
    echo [INFO] Or add NSIS to PATH: "C:\Program Files (x86)\NSIS"
    echo [SKIP] Skipping installer creation
    set SKIP_INSTALLER=1
) else (
    makensis /V2 setup.nsi
    if !ERRORLEVEL! EQU 0 (
        echo [OK] NSIS installer created
        set SKIP_INSTALLER=0
    ) else (
        echo [ERROR] NSIS installer build failed
        set SKIP_INSTALLER=1
    )
)
echo.

REM ==================================================
REM Step 6: Sign installer (optional)
REM ==================================================
echo [6/8] Signing installer (optional)...
echo ------------------------------------
if "%SKIP_INSTALLER%"=="0" (
    if %SIGNING_ENABLED% EQU 1 (
        if defined PRODUCT_VERSION (
            powershell -NoProfile -ExecutionPolicy Bypass -File "tools\signing\sign-release.ps1" -Target installer -Version "%PRODUCT_VERSION%"
        ) else (
            powershell -NoProfile -ExecutionPolicy Bypass -File "tools\signing\sign-release.ps1" -Target installer
        )
        if %ERRORLEVEL% NEQ 0 (
            echo [ERROR] Signing installer failed
            goto ERROR
        )
        echo [OK] Installer signed
    ) else (
        echo [SKIP] Signing not configured
    )
) else (
    echo [SKIP] Installer not built
)
echo.

REM ==================================================
REM Step 7: Create portable ZIP
REM ==================================================
echo [7/8] Creating portable package...
echo ------------------------------------

if not exist "deploy\ThemeToggle" mkdir "deploy\ThemeToggle"

REM Copy core files
copy /Y "ThemeToggle.exe" "deploy\ThemeToggle\" >nul
copy /Y "dist\launchers\ThemeToggle.ps1" "deploy\ThemeToggle\" >nul
copy /Y "LICENSE.txt" "deploy\ThemeToggle\" >nul
copy /Y "README.md" "deploy\ThemeToggle\" >nul

REM Copy launchers from dist
copy /Y "dist\launchers\ThemeToggle.vbs" "deploy\ThemeToggle\" >nul
copy /Y "dist\launchers\ThemeToggle-Light.vbs" "deploy\ThemeToggle\" >nul
copy /Y "dist\launchers\ThemeToggle-Dark.vbs" "deploy\ThemeToggle\" >nul

REM Copy setup scripts
copy /Y "setup.bat" "deploy\ThemeToggle\" >nul
copy /Y "uninstall.bat" "deploy\ThemeToggle\" >nul

REM Copy Resources folder
if not exist "deploy\ThemeToggle\Resources" mkdir "deploy\ThemeToggle\Resources"
copy /Y "Resources\ThemeToggle.ico" "deploy\ThemeToggle\Resources\" >nul

REM Create ZIP using PowerShell
powershell -NoProfile -Command "Compress-Archive -Path 'deploy\ThemeToggle\*' -DestinationPath 'ThemeToggle-Portable.zip' -Force"
if %ERRORLEVEL% EQU 0 (
    echo [OK] Portable package created: ThemeToggle-Portable.zip
) else (
    echo [ERROR] Failed to create ZIP
)
echo.

REM ==================================================
REM Step 8: Validate outputs
REM ==================================================
echo [8/8] Validating outputs...
echo ------------------------------------

set VALIDATION_OK=1

if exist "ThemeToggle.exe" (
    echo [OK] ThemeToggle.exe
) else (
    echo [ERROR] Missing: ThemeToggle.exe
    set VALIDATION_OK=0
)

if "%SKIP_INSTALLER%"=="0" (
    if exist "ThemeToggle-Setup-*.exe" (
        echo [OK] ThemeToggle-Setup-*.exe
    ) else (
        echo [WARNING] Missing: ThemeToggle-Setup-*.exe
    )
)

if exist "ThemeToggle-Portable.zip" (
    echo [OK] ThemeToggle-Portable.zip
) else (
    echo [ERROR] Missing: ThemeToggle-Portable.zip
    set VALIDATION_OK=0
)

if exist "dist\launchers\ThemeToggle.vbs" (
    echo [OK] Launchers in dist\launchers\
) else (
    echo [ERROR] Missing: dist\launchers\
    set VALIDATION_OK=0
)

echo.

REM ==================================================
REM Summary & Next Steps
REM ==================================================
if %VALIDATION_OK% EQU 1 (
    echo ========================================
    echo   Build Complete! ✓
    echo ========================================
    echo.
    echo Release artifacts:
    if exist "ThemeToggle-Setup-*.exe" echo   • ThemeToggle-Setup-*.exe  [NSIS Installer]
    echo   • ThemeToggle-Portable.zip     [Portable package]
    echo   • ThemeToggle.exe              [Standalone executable]
    echo.
    echo Next steps:
    echo   1. Test the installer and portable package
    echo   2. Run: dist\update-winget.ps1 (to update manifests with SHA256)
    echo   3. Create GitHub release and upload artifacts
    echo   4. Submit to WinGet: https://github.com/microsoft/winget-pkgs
    echo.
    goto SUCCESS
) else (
    echo ========================================
    echo   Build completed with warnings
    echo ========================================
    echo.
    echo Some artifacts were not created. Review output above.
    echo.
)

:SUCCESS
popd
endlocal
exit /b 0

:ERROR
echo.
echo ========================================
echo   Build Failed!
echo ========================================
echo.
popd
endlocal
exit /b 1
