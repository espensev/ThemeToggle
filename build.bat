@echo off
REM Build script for ThemeToggle.exe with refactored source files

REM Save current directory and switch to script directory
pushd "%~dp0"

echo Building ThemeToggle (Release - Refactored)...
echo.

REM Clean previous build artifacts
echo [0/4] Cleaning...
del *.obj *.res "*.lnk" 2>nul

REM Step 1: Compile resource file
echo [1/4] Compiling resources (with Resources\\ThemeToggle.ico)...
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

REM Organize deployable files into a dedicated folder
set "DIST_DIR=deploy"
set "PACKAGE_DIR=%DIST_DIR%\\ThemeToggle"
set "PACKAGE_RES=%PACKAGE_DIR%\\Resources"

echo.
echo Packaging artifacts into %PACKAGE_DIR% ...
if exist "%PACKAGE_DIR%" rd /s /q "%PACKAGE_DIR%"
mkdir "%PACKAGE_RES%" >nul 2>&1

copy /y ThemeToggle.exe "%PACKAGE_DIR%\\" >nul
copy /y ThemeToggle.vbs "%PACKAGE_DIR%\\" >nul
copy /y ThemeToggle-Light.vbs "%PACKAGE_DIR%\\" >nul
copy /y ThemeToggle-Dark.vbs "%PACKAGE_DIR%\\" >nul
copy /y ThemeToggle.ps1 "%PACKAGE_DIR%\\" >nul
copy /y setup.bat "%PACKAGE_DIR%\\" >nul
copy /y uninstall.bat "%PACKAGE_DIR%\\" >nul
copy /y Resources\\ThemeToggle.ico "%PACKAGE_RES%\\" >nul

echo.
echo ===================================
echo Build completed successfully!
echo ===================================
echo.
echo Output: ThemeToggle.exe (Refactored + Optimized)
echo   Size: ~220 KB (Release build with static runtime)
echo   Icon: ThemeToggle.ico (embedded)
echo   Package: %PACKAGE_DIR%
echo.
echo Source files:
echo   main.cpp           - Entry point + orchestration
echo   RegistryManager    - Registry operations
echo   BroadcastManager   - Parallel broadcasts + stubborn apps
echo   UxThemeHelper      - Windows 11 undocumented APIs
echo   Types.h            - Shared types and RAII wrappers
echo.
echo Available launchers:
echo   ThemeToggle.vbs         - Silent toggle
echo   ThemeToggle-Light.vbs   - Silent light mode
echo   ThemeToggle-Dark.vbs    - Silent dark mode
echo   ThemeToggle.ps1         - PowerShell version
echo.

REM Restore original directory
popd
