@echo off
REM Build script for ThemeToggle.exe

REM Save current directory and switch to script directory
pushd "%~dp0"

echo Building ThemeToggle (Release)...
echo.

REM Clean previous build artifacts
echo [0/4] Cleaning...
del *.obj *.res 2>nul

REM Step 1: Compile resource file
echo [1/4] Compiling resources (Resources\ThemeToggle.ico)...
rc ThemeToggle.rc
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Resource compilation failed!
    popd
    exit /b 1
)

REM Step 2: Compile C++ source files
echo [2/4] Compiling source files...
cl /c /EHsc /std:c++17 /W4 /O2 /MT /DNDEBUG main.cpp RegistryManager.cpp BroadcastManager.cpp UxThemeHelper.cpp
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Compilation failed!
    popd
    exit /b 1
)

REM Step 3: Link object files and resources
echo [3/4] Linking...
link /SUBSYSTEM:WINDOWS /ENTRY:wWinMainCRTStartup /OUT:ThemeToggle.exe main.obj RegistryManager.obj BroadcastManager.obj UxThemeHelper.obj ThemeToggle.res user32.lib advapi32.lib dwmapi.lib shell32.lib
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Linking failed!
    popd
    exit /b 1
)

REM Step 4: Cleanup intermediate files
echo [4/4] Cleaning up...
del *.obj 2>nul
del ThemeToggle.res 2>nul

echo.
echo ===================================
echo Build completed successfully!
echo ===================================
echo.
echo Output: ThemeToggle.exe (~220 KB)
echo Icon: Resources\ThemeToggle.ico
echo.

REM Restore original directory
popd
