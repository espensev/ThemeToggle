@echo off
REM ============================================================================
REM ThemeToggle Quick Setup - Interactive Installer
REM Added command-line flags to allow non-interactive selective setup:
REM   /noTasks     -> Do not create scheduled tasks
REM   /noStartup   -> Do not add to startup (Run key)
REM   /noShortcut  -> Do not create desktop shortcut
REM   /minimal     -> Perform no actions (verify presence only) then exit
REM   /auto        -> Perform all available actions except those explicitly skipped
REM   /nopause     -> Skip final pause prompt
REM   /?           -> Help
REM ============================================================================
setlocal enabledelayedexpansion

REM Parse command-line flags
set skipTasks=0
set skipStartup=0
set skipShortcut=0
set autoMode=0
set minimalMode=0
set noPause=0

for %%A in (%*) do (
  if /I "%%A"=="/noTasks" set skipTasks=1
  if /I "%%A"=="/noStartup" set skipStartup=1
  if /I "%%A"=="/noShortcut" set skipShortcut=1
  if /I "%%A"=="/auto" set autoMode=1
  if /I "%%A"=="/minimal" set minimalMode=1
  if /I "%%A"=="/nopause" set noPause=1
  if /I "%%A"=="/?" goto HELP
)

if %autoMode%==1 set noPause=1

:START
REM Save current directory and switch to script directory
pushd "%~dp0"

REM Minimal mode: verify executable and exit
if %minimalMode%==1 (
  if not exist "ThemeToggle.exe" (
    echo ThemeToggle.exe not found.
    popd & endlocal & exit /b 1
  )
  echo ThemeToggle.exe found. No setup actions performed (/minimal).
  popd & endlocal & exit /b 0
)

echo.
echo ========================================
echo   ThemeToggle Quick Setup
echo ========================================
echo.

REM Check if ThemeToggle.exe exists
if not exist "ThemeToggle.exe" (
    echo ERROR: ThemeToggle.exe not found!
    echo Build first using build.bat or place executable here.
    echo.
    popd
    endlocal
    exit /b 1
)

if %autoMode%==1 goto AUTOMATED

echo ThemeToggle.exe found [OK]
echo.

REM Show menu (only if not auto mode)
:MENU
echo What would you like to set up?
echo.
if %skipShortcut%==0 echo [1] Create Desktop Shortcut (manual hotkey capable)
if %skipStartup%==0 echo [2] Add to Startup (auto-toggle on login)
if %skipTasks%==0 echo [3] Create Scheduled Tasks (Light 7AM, Dark 7PM)
if %skipShortcut%==0 if %skipStartup%==0 if %skipTasks%==0 echo [4] All of the above
if %skipShortcut%==1 if %skipStartup%==1 if %skipTasks%==1 echo (No selectable actions - all skipped via flags)
echo [5] Test theme toggle now
echo [0] Exit
echo.
set /p choice="Enter your choice (0-5): "

if "%choice%"=="5" goto TEST
if "%choice%"=="0" goto END
if %skipShortcut%==0 if "%choice%"=="1" goto SHORTCUT
if %skipStartup%==0 if "%choice%"=="2" goto STARTUP
if %skipTasks%==0 if "%choice%"=="3" goto SCHEDULED
if %skipShortcut%==0 if %skipStartup%==0 if %skipTasks%==0 if "%choice%"=="4" goto ALL
echo Invalid or disabled choice.
echo.
goto MENU

:AUTOMATED
echo Automated mode (/auto) selected.
if %skipShortcut%==0 call :SHORTCUT_AUTO
if %skipStartup%==0 call :STARTUP_AUTO
if %skipTasks%==0 call :SCHEDULED_AUTO
echo.
goto SUCCESS

:SHORTCUT
echo.
echo Creating desktop shortcut...
set scriptPath=%CD%\ThemeToggle.vbs
set desktopPath=%USERPROFILE%\Desktop
set shortcutPath=%desktopPath%\Toggle Theme.lnk
set iconPath=%CD%\ThemeToggle.exe
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%shortcutPath%'); $s.TargetPath = 'wscript.exe'; $s.Arguments = '\"%scriptPath%\"'; $s.WorkingDirectory = '%CD%'; $s.IconLocation = '%iconPath%,0'; $s.Description = 'Toggle Windows Light/Dark Theme'; $s.Save()"
if exist "%shortcutPath%" (
    echo Desktop shortcut created.
    echo (Assign hotkey manually via shortcut properties)
    echo.
) else (
    echo Failed to create shortcut.
    echo.
)
if not "%choice%"=="4" pause & goto MENU
goto STARTUP

:SHORTCUT_AUTO
set scriptPath=%CD%\ThemeToggle.vbs
set desktopPath=%USERPROFILE%\Desktop
set shortcutPath=%desktopPath%\Toggle Theme.lnk
set iconPath=%CD%\ThemeToggle.exe
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%shortcutPath%'); $s.TargetPath = 'wscript.exe'; $s.Arguments = '\"%scriptPath%\"'; $s.WorkingDirectory = '%CD%'; $s.IconLocation = '%iconPath%,0'; $s.Description = 'Toggle Windows Light/Dark Theme'; $s.Save()" >nul 2>&1
if exist "%shortcutPath%" echo [OK] Shortcut created.
exit /b 0

:STARTUP
echo.
echo Adding to Windows Startup...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "ThemeToggle" /t REG_SZ /d "wscript.exe \"%CD%\ThemeToggle.vbs\"" /f >nul 2>&1
if !errorlevel! equ 0 (
    echo Added to startup.
    echo.
) else (
    echo Failed to add to startup.
    echo.
)
if not "%choice%"=="4" pause & goto MENU
goto SCHEDULED

:STARTUP_AUTO
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "ThemeToggle" /t REG_SZ /d "wscript.exe \"%CD%\ThemeToggle.vbs\"" /f >nul 2>&1
if !errorlevel! equ 0 echo [OK] Startup entry added.
exit /b 0

:SCHEDULED
echo.
echo Creating scheduled tasks...
echo.
schtasks /create /tn "ThemeToggle-Morning" /tr "\"%CD%\ThemeToggle.exe\" /light /quiet" /sc daily /st 07:00 /f >nul 2>&1
if !errorlevel! equ 0 (echo [OK] Morning Light @ 07:00) else (echo [FAIL] Morning task)
schtasks /create /tn "ThemeToggle-Evening" /tr "\"%CD%\ThemeToggle.exe\" /dark /quiet" /sc daily /st 19:00 /f >nul 2>&1
if !errorlevel! equ 0 (echo [OK] Evening Dark @ 19:00) else (echo [FAIL] Evening task)
echo.
echo To modify times use Task Scheduler (taskschd.msc).
echo.
if not "%choice%"=="4" pause & goto MENU
goto SUCCESS

:SCHEDULED_AUTO
schtasks /create /tn "ThemeToggle-Morning" /tr "\"%CD%\ThemeToggle.exe\" /light /quiet" /sc daily /st 07:00 /f >nul 2>&1
if !errorlevel! equ 0 echo [OK] Morning task created.
schtasks /create /tn "ThemeToggle-Evening" /tr "\"%CD%\ThemeToggle.exe\" /dark /quiet" /sc daily /st 19:00 /f >nul 2>&1
if !errorlevel! equ 0 echo [OK] Evening task created.
exit /b 0

:ALL
call :SHORTCUT
call :STARTUP
call :SCHEDULED
goto SUCCESS

:TEST
echo.
echo Testing theme toggle...
cscript //nologo ThemeToggle.vbs
echo.
echo If the theme changed the executable works.
echo.
pause
goto MENU

:SUCCESS
echo.
echo ========================================
echo   Setup Complete
echo ========================================
echo.
if "%choice%"=="4" (
  if %skipShortcut%==0 echo  - Desktop shortcut created
  if %skipStartup%==0 echo  - Startup entry added
  if %skipTasks%==0 echo  - Scheduled tasks created
)
if %autoMode%==1 (
  echo Actions executed in auto mode:
  if %skipShortcut%==0 echo  - Shortcut
  if %skipStartup%==0 echo  - Startup entry
  if %skipTasks%==0 echo  - Scheduled tasks
)
echo.
goto END

:HELP
echo.
echo Usage: setup.bat [options]
echo   /noTasks       Skip creation of scheduled tasks
echo   /noStartup     Skip adding Run key startup entry
echo   /noShortcut    Skip desktop shortcut creation
echo   /auto          Execute all non-skipped actions without interaction
echo   /minimal       Verify executable only, perform no actions
echo   /nopause       Skip final pause prompt
echo   /?             Show this help
exit /b 0

:END
echo.
echo Exiting setup.
echo For more information see README.md
echo.
popd
endlocal
if %noPause%==0 pause
exit /b 0
