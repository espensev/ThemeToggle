@echo off
REM ============================================================================
REM VBS Launcher Reorganization Script
REM Moves VBS launchers to scripts\launchers folder for better organization
REM ============================================================================
setlocal enabledelayedexpansion

pushd "%~dp0\.."

echo.
echo ========================================
echo   VBS Launcher Reorganization
echo ========================================
echo.
echo This script will:
echo   1. Create scripts\launchers\ folder
echo   2. Move all VBS files to launchers folder
echo   3. Create symbolic links in root (for backward compatibility)
echo   4. Update setup.bat references
echo.

set /p confirm="Continue? (Y/N): "
if /I not "%confirm%"=="Y" (
    echo Reorganization cancelled.
    goto END
)

echo.
echo Starting reorganization...
echo.

REM ===========================================
REM 1. Create launchers folder
REM ===========================================
if not exist "scripts\launchers" (
    mkdir "scripts\launchers"
    echo [OK] Created: scripts\launchers\
) else (
    echo [SKIP] Folder already exists: scripts\launchers\
)

echo.

REM ===========================================
REM 2. Move VBS files
REM ===========================================
echo Moving VBS files...
echo.

set moved=0

for %%F in (ThemeToggle.vbs ThemeToggle-Light.vbs ThemeToggle-Dark.vbs) do (
    if exist "%%F" (
        if not exist "scripts\launchers\%%F" (
            move "%%F" "scripts\launchers\%%F" >nul
            echo [OK] Moved: %%F
            set /a moved+=1
        ) else (
            echo [SKIP] Already exists: scripts\launchers\%%F
        )
    ) else (
        echo [SKIP] Not found: %%F
    )
)

echo.
echo Files moved: %moved%
echo.

REM ===========================================
REM 3. Create backward compatibility links
REM ===========================================
echo Creating symbolic links for backward compatibility...
echo (This requires administrator privileges)
echo.

REM Check admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] Not running as administrator.
    echo Symbolic links not created. Manual update may be required.
    goto SKIP_LINKS
)

for %%F in (ThemeToggle.vbs ThemeToggle-Light.vbs ThemeToggle-Dark.vbs) do (
    if not exist "%%F" (
        if exist "scripts\launchers\%%F" (
            mklink "%%F" "scripts\launchers\%%F" >nul 2>&1
            if exist "%%F" (
                echo [OK] Linked: %%F
            ) else (
                echo [FAIL] Could not create link: %%F
            )
        )
    )
)

:SKIP_LINKS

echo.

REM ===========================================
REM 4. Summary
REM ===========================================
echo ========================================
echo   Reorganization Complete
echo ========================================
echo.
echo New structure:
echo   scripts\launchers\ThemeToggle.vbs
echo   scripts\launchers\ThemeToggle-Light.vbs
echo   scripts\launchers\ThemeToggle-Dark.vbs
echo.
echo Backward compatibility:
if exist "ThemeToggle.vbs" (
    echo   [OK] Symbolic links created in root
) else (
    echo   [MANUAL] Update scripts to use new paths:
    echo     Old: "%%CD%%\ThemeToggle.vbs"
    echo     New: "%%CD%%\scripts\launchers\ThemeToggle.vbs"
)
echo.
echo Next steps:
echo   1. Update setup.bat paths (if needed)
echo   2. Update any custom shortcuts
echo   3. Test theme toggle functionality
echo   4. Commit changes to Git
echo.

:END
popd
endlocal
pause
