@echo off
setlocal enabledelayedexpansion

REM Save current directory and switch to repository root
pushd "%~dp0\.."

REM Read product version
set "PRODUCT_VERSION="
if exist "VERSION" (
    for /f "usebackq tokens=* delims=" %%v in ("VERSION") do (
        set "PRODUCT_VERSION=%%v"
    )
)

set "SIGNING_ENABLED=0"
if defined THEMETOGGLE_SIGN_PFX_PATH set "SIGNING_ENABLED=1"
if defined THEMETOGGLE_SIGN_CERT_THUMBPRINT set "SIGNING_ENABLED=1"
if defined PFX_PATH set "SIGNING_ENABLED=1"

echo ========================================
echo   ThemeToggle - Build Release
echo ========================================

echo [1/8] Cleaning workspace...
del *.obj *.res RC* RD* *.aps 2>nul
echo [OK] Workspace cleaned

echo [2/8] Building ThemeToggle.exe...
call build.bat
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed!
    goto ERROR
)

echo [3/8] Verifying executable...
if not exist "ThemeToggle.exe" (
    echo [ERROR] ThemeToggle.exe not found!
    goto ERROR
)
echo [OK] ThemeToggle.exe verified

echo [4/8] Signing executable (optional)...
if "%SIGNING_ENABLED%"=="1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "tools\signing\sign-release.ps1" -Target exe
    echo [OK] ThemeToggle.exe signed
) else (
    echo [SKIP] Signing not configured
)

echo [5/8] Building NSIS installer...
where makensis >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [SKIP] makensis not found
    set "SKIP_INSTALLER=1"
) else (
    makensis /V2 setup.nsi
    if !ERRORLEVEL! EQU 0 (
        echo [OK] NSIS installer created
        set "SKIP_INSTALLER=0"
    ) else (
        echo [ERROR] NSIS installer build failed
        set "SKIP_INSTALLER=1"
    )
)

echo [6/8] Signing installer (optional)...
if "%SKIP_INSTALLER%"=="0" (
    if "%SIGNING_ENABLED%"=="1" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "tools\signing\sign-release.ps1" -Target installer -Version "%PRODUCT_VERSION%"
        echo [OK] Installer signed
    ) else (
        echo [SKIP] Signing not configured
    )
)

echo [7/8] Creating portable package...
if not exist "deploy\ThemeToggle" mkdir "deploy\ThemeToggle"
copy /Y "ThemeToggle.exe" "deploy\ThemeToggle\" >nul
copy /Y "dist\launchers\ThemeToggle.ps1" "deploy\ThemeToggle\" >nul
copy /Y "LICENSE.txt" "deploy\ThemeToggle\" >nul
copy /Y "README.md" "deploy\ThemeToggle\" >nul
copy /Y "dist\launchers\ThemeToggle.vbs" "deploy\ThemeToggle\" >nul
copy /Y "dist\launchers\ThemeToggle-Light.vbs" "deploy\ThemeToggle\" >nul
copy /Y "dist\launchers\ThemeToggle-Dark.vbs" "deploy\ThemeToggle\" >nul
copy /Y "setup.bat" "deploy\ThemeToggle\" >nul
copy /Y "uninstall.bat" "deploy\ThemeToggle\" >nul
if not exist "deploy\ThemeToggle\Resources" mkdir "deploy\ThemeToggle\Resources"
copy /Y "Resources\ThemeToggle.ico" "deploy\ThemeToggle\Resources\" >nul

powershell -NoProfile -Command "Compress-Archive -Path 'deploy\ThemeToggle\*' -DestinationPath 'ThemeToggle-Portable.zip' -Force"
echo [OK] Portable package created

echo [8/8] Validating outputs...
if exist "ThemeToggle.exe" echo [OK] ThemeToggle.exe
if exist "ThemeToggle-Portable.zip" echo [OK] ThemeToggle-Portable.zip

echo ========================================
echo   Build Complete!
echo ========================================
popd
endlocal
exit /b 0

:ERROR
echo ========================================
echo   Build Failed!
echo ========================================
popd
endlocal
exit /b 1