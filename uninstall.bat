@echo off
REM ============================================================================
REM ThemeToggle Uninstaller - Remove all automated configurations
REM ============================================================================

setlocal enabledelayedexpansion

REM Save current directory and switch to script directory
pushd "%~dp0"

echo.
echo ========================================
echo   ThemeToggle Uninstaller
echo ========================================
echo.
echo This will remove:
echo  - Desktop shortcut
echo  - Startup entry
echo  - Scheduled tasks
echo.
set /p confirm="Continue? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Cancelled.
    goto END
)

echo.
echo Removing ThemeToggle configurations...
echo.

REM Remove desktop shortcut
set shortcutPath=%USERPROFILE%\Desktop\Toggle Theme.lnk
if exist "%shortcutPath%" (
    del "%shortcutPath%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [OK] Desktop shortcut removed
    ) else (
        echo [SKIP] Could not remove desktop shortcut
    )
) else (
    echo [SKIP] Desktop shortcut not found
)

REM Remove startup entry
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "ThemeToggle" /f >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Startup entry removed
) else (
    echo [SKIP] Startup entry not found
)

REM Remove scheduled tasks
schtasks /delete /tn "ThemeToggle-Morning" /f >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Morning scheduled task removed
) else (
    echo [SKIP] Morning task not found
)

schtasks /delete /tn "ThemeToggle-Evening" /f >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Evening scheduled task removed
) else (
    echo [SKIP] Evening task not found
)

echo.
echo ========================================
echo   Cleanup Complete
echo ========================================
echo.
echo All automated configurations have been removed.
echo.
echo ThemeToggle.exe and scripts remain in this folder.
echo You can still run them manually.
echo.

:END
REM Restore original directory
popd
pause
endlocal
exit /b 0
