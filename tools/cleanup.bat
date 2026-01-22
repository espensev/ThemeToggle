@echo off
REM ============================================================================
REM Workspace Cleanup - Remove build artifacts
REM ============================================================================
setlocal enabledelayedexpansion

pushd "%~dp0\.."

echo.
echo ========================================
echo   Workspace Cleanup
echo ========================================
echo.

set deleted=0

REM Remove temporary build artifacts
echo Cleaning temporary build artifacts...
for %%F in (RCa* RDa* RC* RD* *.aps *.obj *.res) do (
    if exist "%%F" (
        del "%%F" 2>nul
        echo   [OK] Deleted: %%F
        set /a deleted+=1
    )
)

REM Clean old backups
if exist "*.old" (
    del "*.old" 2>nul
    echo   [OK] Deleted: *.old files
    set /a deleted+=1
)

REM Clean deploy old artifacts
if exist "deploy\*.zip.old" (
    del "deploy\*.zip.old" 2>nul
    echo   [OK] Deleted: Old deployment zips
)

echo.
echo ========================================
echo   Cleanup Complete
echo ========================================
echo   Files deleted: %deleted%
echo.

popd
endlocal
