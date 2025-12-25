@echo off
REM ============================================================================
REM Rename WinGet Manifests Script
REM ============================================================================
setlocal

pushd "%~dp0\..\winget"

echo.
echo ========================================
echo   Renaming WinGet Manifests
echo ========================================
echo.
echo Old: YourPublisher.ThemeToggle.*
echo New: SevIQ.ThemeToggle.*
echo.

if not exist "YourPublisher.ThemeToggle.yaml" (
    echo Files already renamed or not found.
    goto END
)

echo Renaming files...
ren "YourPublisher.ThemeToggle.yaml" "SevIQ.ThemeToggle.yaml"
ren "YourPublisher.ThemeToggle.installer.yaml" "SevIQ.ThemeToggle.installer.yaml"
ren "YourPublisher.ThemeToggle.locale.en-US.yaml" "SevIQ.ThemeToggle.locale.en-US.yaml"

echo.
echo [OK] All manifest files renamed successfully!
echo.

:END
popd
endlocal
pause
