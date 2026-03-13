@echo off
setlocal EnableDelayedExpansion
REM Build script for ThemeToggle.exe

REM Optional flags:
REM   /sign   Build + sign via tools\release\build-and-publish.ps1
REM   --help  Show help

set DO_SIGN=0
set "ARG1=%~1"
set "ARG2=%~2"

if /I "!ARG1!"=="/sign" set DO_SIGN=1
if /I "!ARG1!"=="--help" goto USAGE
if /I "!ARG1!"=="/?" goto USAGE

if /I "!ARG2!"=="/sign" set DO_SIGN=1
if /I "!ARG2!"=="--help" goto USAGE
if /I "!ARG2!"=="/?" goto USAGE

REM Save current directory and switch to script directory
pushd "%~dp0"

REM Backward-compatible signing path:
REM delegate to the unified release script so /sign keeps working after
REM standalone signing helpers were consolidated.
if %DO_SIGN%==1 (
    if not exist "tools\release\build-and-publish.ps1" (
        echo ERROR: tools\release\build-and-publish.ps1 not found.
        popd
        exit /b 1
    )

    where pwsh >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        echo ERROR: pwsh ^(PowerShell 7+^) is required for build.bat /sign.
        echo        Install PowerShell 7+ or run tools\release\build-and-publish.ps1 directly with pwsh.
        popd
        exit /b 1
    )

    echo Delegating build + signing to tools\release\build-and-publish.ps1...
    pwsh -NoProfile -ExecutionPolicy Bypass -File "tools\release\build-and-publish.ps1" -NoInstaller -NoZip -NoWinget
    set RESULT=%ERRORLEVEL%
    popd
    exit /b %RESULT%
)

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
        
        REM VS 2026 (version 18)
        if exist "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" (
            set "VSINSTALL=C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"
        )
        if not defined VSINSTALL if exist "C:\Program Files\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
            set "VSINSTALL=C:\Program Files\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
        )
        
        REM VS 2022
        if not defined VSINSTALL if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
            set "VSINSTALL=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
        )
    )
    
    if not defined VSINSTALL (
        echo ERROR: Visual Studio Build Tools not found!
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
)

echo Building ThemeToggle (Release)...

REM Clean
del *.obj *.res 2>nul

REM Step 1: Compile resource file
rc ThemeToggle.rc
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Resource compilation failed!
    popd
    exit /b 1
)

REM Step 2: Compile C++ source files
cl /c /EHsc /std:c++17 /W4 /O2 /MT /DNDEBUG /I include src\main.cpp src\RegistryManager.cpp src\BroadcastManager.cpp src\UxThemeHelper.cpp
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Compilation failed!
    popd
    exit /b 1
)

REM Step 3: Link
link /SUBSYSTEM:WINDOWS /ENTRY:wWinMainCRTStartup /OUT:ThemeToggle.exe main.obj RegistryManager.obj BroadcastManager.obj UxThemeHelper.obj ThemeToggle.res user32.lib advapi32.lib dwmapi.lib shell32.lib
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Linking failed!
    popd
    exit /b 1
)

REM Step 4: Cleanup
del *.obj 2>nul
del ThemeToggle.res 2>nul

echo Build completed successfully!
popd
exit /b 0

:USAGE
echo Usage: build.bat [/sign]
exit /b 0
