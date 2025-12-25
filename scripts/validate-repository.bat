@echo off
REM ============================================================================
REM Pre-commit Validation Script
REM Validates repository state before committing changes
REM ============================================================================
setlocal enabledelayedexpansion

pushd "%~dp0\.."

echo.
echo ========================================
echo   Pre-Commit Validation
echo ========================================
echo.

set errors=0
set warnings=0

REM ===========================================
REM 1. Check Icon Location
REM ===========================================
echo [1/8] Checking icon location...
if exist "Resources\ThemeToggle.ico" (
    echo [OK] Icon found: Resources\ThemeToggle.ico
) else (
    echo [ERROR] Missing: Resources\ThemeToggle.ico
    set /a errors+=1
)

echo.

REM ===========================================
REM 2. Check Build Artifacts
REM ===========================================
echo [2/8] Checking for uncommitted build artifacts...

set artifacts=0
for %%F in (*.obj *.res RC* RD* *.aps) do (
    if exist "%%F" (
        echo [WARNING] Build artifact: %%F
        set /a artifacts+=1
        set /a warnings+=1
    )
)

if %artifacts%==0 (
    echo [OK] No build artifacts found
)

echo.

REM ===========================================
REM 3. Check Resource File
REM ===========================================
echo [3/8] Checking resource file configuration...
if exist "ThemeToggle.rc" (
    findstr /C:"Resources\\ThemeToggle.ico" ThemeToggle.rc >nul
    if !errorlevel!==0 (
        echo [OK] ThemeToggle.rc references correct icon
    ) else (
        echo [WARNING] Could not verify icon reference
        set /a warnings+=1
    )
) else (
    echo [ERROR] Missing: ThemeToggle.rc
    set /a errors+=1
)

echo.

REM ===========================================
REM 4. Check Documentation
REM ===========================================
echo [4/8] Checking documentation files...

for %%F in (README.md CHANGELOG.md QUICK_REFERENCE.md RELEASE_NOTES.md AUTOMATION_GUIDE.md ICON_EMBEDDING.md) do (
    if exist "%%F" (
        echo [OK] %%F
    ) else (
        echo [ERROR] Missing: %%F
        set /a errors+=1
    )
)

echo.

REM ===========================================
REM 5. Check WinGet Manifests
REM ===========================================
echo [5/8] Checking WinGet manifests...

if exist "winget\SevIQ.ThemeToggle.yaml" (
    echo [OK] winget\SevIQ.ThemeToggle.yaml
) else (
    if exist "winget\YourPublisher.ThemeToggle.yaml" (
        echo [WARNING] WinGet manifests not renamed yet
        set /a warnings+=1
    ) else (
        echo [ERROR] Missing WinGet version manifest
        set /a errors+=1
    )
)

if exist "winget\SevIQ.ThemeToggle.installer.yaml" (
    findstr /C:"REPLACE_WITH_ACTUAL_SHA256_HASH" "winget\SevIQ.ThemeToggle.installer.yaml" >nul
    if !errorlevel!==0 (
        echo [WARNING] Installer manifest has placeholder SHA256
        set /a warnings+=1
    ) else (
        echo [OK] winget\SevIQ.ThemeToggle.installer.yaml
    )
) else (
    echo [ERROR] Missing WinGet installer manifest
    set /a errors+=1
)

echo.

REM ===========================================
REM 6. Check Source Files
REM ===========================================
echo [6/8] Checking source files...

for %%F in (main.cpp Types.h RegistryManager.cpp RegistryManager.h BroadcastManager.cpp BroadcastManager.h UxThemeHelper.cpp UxThemeHelper.h) do (
    if exist "%%F" (
        echo [OK] %%F
    ) else (
        echo [ERROR] Missing: %%F
        set /a errors+=1
    )
)

echo.

REM ===========================================
REM 7. Check Build Scripts
REM ===========================================
echo [7/8] Checking build scripts...

for %%F in (build.bat setup.bat uninstall.bat) do (
    if exist "%%F" (
        echo [OK] %%F
    ) else (
        echo [ERROR] Missing: %%F
        set /a errors+=1
    )
)

echo.

REM ===========================================
REM 8. Check Git Status
REM ===========================================
echo [8/8] Checking Git status...

git status >nul 2>&1
if %errorlevel%==0 (
    echo [OK] Git repository detected
    
    REM Check for uncommitted changes
    git diff --quiet
    if !errorlevel! neq 0 (
        echo [INFO] Uncommitted changes detected
    )
    
    REM Check for untracked files
    for /f %%i in ('git ls-files --others --exclude-standard ^| find /c /v ""') do set untracked=%%i
    if !untracked! gtr 0 (
        echo [INFO] !untracked! untracked files found
    )
) else (
    echo [WARNING] Not a Git repository
    set /a warnings+=1
)

echo.

REM ===========================================
REM Summary
REM ===========================================
echo ========================================
echo   Validation Summary
echo ========================================
echo.
echo Errors:   %errors%
echo Warnings: %warnings%
echo.

if %errors% gtr 0 (
    echo [FAIL] Validation failed with %errors% error(s)
    echo Please fix errors before committing.
    goto FAIL
)

if %warnings% gtr 0 (
    echo [PASS] Validation passed with %warnings% warning(s)
    echo Consider addressing warnings before committing.
) else (
    echo [PASS] All checks passed!
)

echo.
echo Repository is ready for commit.
echo.

:SUCCESS
popd
endlocal
exit /b 0

:FAIL
popd
endlocal
exit /b 1
