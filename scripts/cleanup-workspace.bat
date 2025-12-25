@echo off
REM ============================================================================
REM Workspace Cleanup Script - Remove build artifacts
REM ============================================================================
setlocal enabledelayedexpansion

pushd "%~dp0\.."

echo.
echo ========================================
echo   Workspace Cleanup
echo ========================================
echo.
echo This script will remove:
echo   [1] Temporary build artifacts (RC*, RD*, *.aps)
echo   [2] Build residue (*.obj, *.res)
echo.

set /p confirm="Continue? (Y/N): "
if /I not "%confirm%"=="Y" (
    echo Cleanup cancelled.
    goto END
)

echo.
echo Starting cleanup...
echo.

set deleted=0

REM ==================================================
REM Remove temporary build artifacts
REM ==================================================
echo [PHASE 1] Temporary Build Artifacts
echo ------------------------------------

for %%F in (RCa* RDa* RC* RD*) do (
    if exist "%%F" (
        del "%%F" 2>nul
        echo [OK] Deleted: %%F
        set /a deleted+=1
    )
)

if exist "*.aps" (
    del "*.aps" 2>nul
    echo [OK] Deleted: *.aps files
    set /a deleted+=1
)

echo.

REM ==================================================
REM Remove build residue
REM ==================================================
echo [PHASE 2] Build Residue
echo -----------------------

if exist "*.obj" (
    del "*.obj" 2>nul
    echo [OK] Deleted: *.obj files
)

if exist "*.res" (
    del "*.res" 2>nul
    echo [OK] Deleted: *.res files
)

echo.

REM ==================================================
REM Clean deploy folder old artifacts
REM ==================================================
echo [PHASE 3] Deploy Folder Cleanup
echo --------------------------------

if exist "deploy\*.zip.old" (
    del "deploy\*.zip.old" 2>nul
    echo [OK] Deleted: Old deployment zips
)

echo.

REM ==================================================
REM Summary
REM ==================================================
echo ========================================
echo   Cleanup Complete
echo ========================================
echo   Files deleted: %deleted%
echo.
echo Current icon location: Resources\ThemeToggle.ico
echo.
echo Next steps:
echo   1. Review changes with: git status
echo   2. Run build.bat to verify
echo   3. Update WinGet manifests if needed
echo.

:END
popd
endlocal
pause
