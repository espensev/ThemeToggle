@echo off
REM ============================================================================
REM Build NSIS Installer for ThemeToggle
REM ============================================================================
REM Prerequisites:
REM   1. NSIS (Nullsoft Scriptable Install System) installed
REM      Download from: https://nsis.sourceforge.io/Download
REM   2. ThemeToggle.exe already built (run build.bat first)
REM   3. All required files present in workspace
REM ============================================================================

setlocal enabledelayedexpansion

echo.
echo ========================================
echo   ThemeToggle Installer Builder
echo ========================================
echo.

REM Check if ThemeToggle.exe exists
if not exist "ThemeToggle.exe" (
    echo ERROR: ThemeToggle.exe not found!
    echo Please run build.bat first to compile the executable.
    echo.
    exit /b 1
)

REM Check if NSIS is installed (common paths)
set NSIS_PATH=
if exist "C:\Program Files (x86)\NSIS\makensis.exe" (
    set "NSIS_PATH=C:\Program Files (x86)\NSIS\makensis.exe"
) else if exist "C:\Program Files\NSIS\makensis.exe" (
    set "NSIS_PATH=C:\Program Files\NSIS\makensis.exe"
) else if exist "%ProgramFiles(x86)%\NSIS\makensis.exe" (
    set "NSIS_PATH=%ProgramFiles(x86)%\NSIS\makensis.exe"
) else if exist "%ProgramFiles%\NSIS\makensis.exe" (
    set "NSIS_PATH=%ProgramFiles%\NSIS\makensis.exe"
)

if "%NSIS_PATH%"=="" (
    echo ERROR: NSIS not found!
    echo.
    echo Please install NSIS from:
    echo https://nsis.sourceforge.io/Download
    echo.
    echo After installation, NSIS is typically located at:
    echo   C:\Program Files ^(x86^)\NSIS\makensis.exe
    echo.
    exit /b 1
)

echo Found NSIS at: %NSIS_PATH%
echo.

REM Verify all required files exist
echo Checking required files...
set MISSING_FILES=0

if not exist "ThemeToggle.vbs" (
    echo   [MISSING] ThemeToggle.vbs
    set MISSING_FILES=1
)
if not exist "ThemeToggle-Light.vbs" (
    echo   [MISSING] ThemeToggle-Light.vbs
    set MISSING_FILES=1
)
if not exist "ThemeToggle-Dark.vbs" (
    echo   [MISSING] ThemeToggle-Dark.vbs
    set MISSING_FILES=1
)
if not exist "ThemeToggle.ps1" (
    echo   [MISSING] ThemeToggle.ps1
    set MISSING_FILES=1
)
if not exist "setup.bat" (
    echo   [MISSING] setup.bat
    set MISSING_FILES=1
)
if not exist "uninstall.bat" (
    echo   [MISSING] uninstall.bat
    set MISSING_FILES=1
)
if not exist "README.md" (
    echo   [MISSING] README.md
    set MISSING_FILES=1
)
if not exist "CHANGELOG.md" (
    echo   [MISSING] CHANGELOG.md
    set MISSING_FILES=1
)
if not exist "themetoggle_dark.ico" (
    echo   [MISSING] themetoggle_dark.ico
    set MISSING_FILES=1
)
if not exist "LICENSE.txt" (
    echo   [MISSING] LICENSE.txt
    set MISSING_FILES=1
)
if not exist "docs\RELEASE_NOTES.md" (
    echo   [MISSING] docs\RELEASE_NOTES.md
    set MISSING_FILES=1
)
if not exist "installer.nsi" (
    echo   [MISSING] installer.nsi
    set MISSING_FILES=1
)

if %MISSING_FILES%==1 (
    echo.
    echo ERROR: Some required files are missing!
    echo Please ensure all files are present in the workspace.
    exit /b 1
)

echo   [OK] All required files present
echo.

REM Build the installer
echo Building installer...
echo.
"%NSIS_PATH%" /V3 installer.nsi

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo   Installer Build FAILED!
    echo ========================================
    echo.
    exit /b 1
)

echo.
echo ========================================
echo   Installer Build Successful!
echo ========================================
echo.

REM Find the generated installer
for %%F in (ThemeToggle-Setup-*.exe) do (
    echo Output: %%F
    echo Size: 
    dir "%%F" | find "%%F"
    echo.
    set "INSTALLER_NAME=%%F"
)

if not defined INSTALLER_NAME (
    echo Warning: Could not find generated installer file.
) else (
    echo Installation package is ready for distribution!
    echo.
    echo Usage:
    echo   1. Share %INSTALLER_NAME%
    echo   2. Users run the installer
    echo   3. Follow installation wizard prompts
    echo.
)

echo ========================================
echo.

endlocal
pause
