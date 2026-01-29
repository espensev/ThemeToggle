@echo off
setlocal EnableDelayedExpansion
REM Build script for ThemeToggle.exe

REM Save current directory and switch to script directory
pushd "%~dp0"

REM Detect and setup Visual Studio Build Tools environment
if not defined VSCMD_VER (
    echo Setting up Build Tools environment...
    
    set "VSINSTALL="
    
    REM Try vswhere.exe first (official VS locator tool)
    set "VSWHERE=C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
    
    if exist "!VSWHERE!" (
        echo Using vswhere.exe to locate Visual Studio...
        for /f "usebackq tokens=*" %%i in (`"!VSWHERE!" -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
            set "VSINSTALL=%%i\VC\Auxiliary\Build\vcvarsall.bat"
        )
    )
    
    REM Fallback: Try common hardcoded paths if vswhere fails
    if not defined VSINSTALL (
        echo vswhere.exe not found, trying common paths...
        
        REM VS 2026 (version 18) - Check all locations
        if exist "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" (
            set "VSINSTALL=C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"
        )
        if not defined VSINSTALL if exist "C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Auxiliary\Build\vcvarsall.bat" (
            set "VSINSTALL=C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Auxiliary\Build\vcvarsall.bat"
        )
        if not defined VSINSTALL if exist "C:\Program Files\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
            set "VSINSTALL=C:\Program Files\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
        )
        if not defined VSINSTALL if exist "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
            set "VSINSTALL=C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
        )
        
        REM VS 2022
        if not defined VSINSTALL if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
            set "VSINSTALL=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
        )
    )
    
    if not defined VSINSTALL (
        echo ERROR: Visual Studio Build Tools not found!
        echo Please install Visual Studio 2019/2022 Build Tools or run from Developer Command Prompt.
        echo Download: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
        popd
        exit /b 1
    )
    
    echo Found: !VSINSTALL!
    call "!VSINSTALL!" x64 >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        echo ERROR: Failed to initialize build environment
        popd
        exit /b 1
    )
    echo Environment initialized.
    echo.
)

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
cl /c /EHsc /std:c++17 /W4 /O2 /MT /DNDEBUG /I include src\main.cpp src\RegistryManager.cpp src\BroadcastManager.cpp src\UxThemeHelper.cpp
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
