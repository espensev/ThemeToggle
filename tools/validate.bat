@echo off
REM ============================================================================
REM Repository Validation - Pre-commit checks
REM ============================================================================
setlocal enabledelayedexpansion

pushd "%~dp0\.."

echo.
echo ========================================
echo   Repository Validation
echo ========================================
echo.

set errors=0
set warnings=0

REM Check icon
echo [1/6] Checking icon location...
if exist "Resources\ThemeToggle.ico" (
    echo [OK] Icon found
) else (
    echo [ERROR] Missing: Resources\ThemeToggle.ico
    set /a errors+=1
)

REM Check build artifacts
echo [2/6] Checking for uncommitted build artifacts...
set artifacts=0
for %%F in (*.obj *.res RC* RD* *.aps) do (
    if exist "%%F" (
        echo [WARNING] Build artifact: %%F
        set /a artifacts+=1
        set /a warnings+=1
    )
)
if %artifacts%==0 echo [OK] No build artifacts

REM Check manifests
echo [3/6] Validating WinGet manifests...
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\validate-winget.ps1"
if !ERRORLEVEL! NEQ 0 (
    echo [ERROR] WinGet manifest validation failed
    set /a errors+=1
) else (
    echo [OK] WinGet manifests validated
)

REM Check release workflow invariants
echo [4/6] Validating release workflow invariants...
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\validate-release-workflow.ps1"
if !ERRORLEVEL! NEQ 0 (
    echo [ERROR] Release workflow validation failed
    set /a errors+=1
) else (
    echo [OK] Release workflow validated
)

REM Check NSIS script
echo [5/6] Checking NSIS installer script...
if exist "setup.nsi" (
    echo [OK] NSIS script exists
) else (
    echo [WARNING] NSIS script not found
    set /a warnings+=1
)

REM Check dist structure
echo [6/6] Checking dist/ structure...
if exist "dist\launchers\ThemeToggle.vbs" (
    echo [OK] dist/launchers/ exists
) else (
    echo [WARNING] dist/launchers/ not found
    set /a warnings+=1
)

echo.
echo ========================================
echo   Validation Summary
echo ========================================
echo   Errors: %errors%
echo   Warnings: %warnings%
echo.

if %errors% GTR 0 (
    echo [FAIL] Repository has errors!
    popd
    endlocal
    exit /b 1
)

if %warnings% GTR 0 (
    echo [PASS] Repository OK (with warnings)
) else (
    echo [PASS] Repository OK
)

popd
endlocal
exit /b 0
