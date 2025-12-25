; ============================================================================
; ThemeToggle NSIS Installer Script
; ============================================================================
; Creates a professional Windows installer with:
; - Program Files installation
; - Start Menu shortcuts
; - Desktop shortcut (optional)
; - Startup entry (optional)
; - Scheduled tasks (optional)
; - Uninstaller with registry cleanup
; ============================================================================

!define APPNAME "ThemeToggle"
!define COMPANYNAME "ThemeToggle"
!define DESCRIPTION "Ultra-fast Windows theme switcher"
!define VERSIONMAJOR 1
!define VERSIONMINOR 2
!define VERSIONBUILD 0
!define HELPURL "https://github.com/yourusername/ThemeToggle/issues"
!define UPDATEURL "https://github.com/yourusername/ThemeToggle/releases"
!define ABOUTURL "https://github.com/yourusername/ThemeToggle"
!define INSTALLSIZE 1024

; Request admin for proper Program Files installation
RequestExecutionLevel user

; Modern UI
!include "MUI2.nsh"
!include "FileFunc.nsh"

; Installer configuration
Name "${APPNAME}"
OutFile "ThemeToggle-Setup-${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}.exe"
InstallDir "$LOCALAPPDATA\Programs\${APPNAME}"
InstallDirRegKey HKCU "Software\${APPNAME}" "InstallDir"

; Modern UI Configuration
!define MUI_ABORTWARNING
!define MUI_ICON "themetoggle_dark.ico"
!define MUI_UNICON "themetoggle_dark.ico"
!define MUI_WELCOMEPAGE_TITLE "Welcome to ${APPNAME} Setup"
!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the installation of ${APPNAME}, an ultra-fast Windows theme switcher.$\r$\n$\r$\nClick Next to continue."
!define MUI_FINISHPAGE_RUN "$INSTDIR\ThemeToggle.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Test theme toggle now"
!define MUI_FINISHPAGE_LINK "Visit project on GitHub"
!define MUI_FINISHPAGE_LINK_LOCATION "${ABOUTURL}"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Languages
!insertmacro MUI_LANGUAGE "English"

; ============================================================================
; Installer Sections
; ============================================================================

Section "Core Files" SecCore
    SectionIn RO  ; Read-only, always installed
    
    SetOutPath "$INSTDIR"
    
    ; Main executable and launchers
    File "ThemeToggle.exe"
    File "ThemeToggle.vbs"
    File "ThemeToggle-Light.vbs"
    File "ThemeToggle-Dark.vbs"
    File "ThemeToggle.ps1"
    
    ; Setup tools
    File "setup.bat"
    File "uninstall.bat"
    
    ; Documentation
    File "README.md"
    File "CHANGELOG.md"
    
    ; Icon
    File "themetoggle_dark.ico"
    
    ; Create docs subfolder
    CreateDirectory "$INSTDIR\docs"
    SetOutPath "$INSTDIR\docs"
    File "docs\RELEASE_NOTES.md"
    
    ; Store installation folder in registry
    WriteRegStr HKCU "Software\${APPNAME}" "InstallDir" "$INSTDIR"
    
    ; Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    
    ; Add uninstall information to Add/Remove Programs
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\Uninstall.exe$\" /S"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$INSTDIR\themetoggle_dark.ico"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${COMPANYNAME}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "HelpLink" "${HELPURL}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "URLUpdateInfo" "${UPDATEURL}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "URLInfoAbout" "${ABOUTURL}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayVersion" "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}"
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "VersionMajor" ${VERSIONMAJOR}
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "VersionMinor" ${VERSIONMINOR}
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoModify" 1
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoRepair" 1
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "EstimatedSize" ${INSTALLSIZE}
    
SectionEnd

Section "Start Menu Shortcuts" SecStartMenu
    CreateDirectory "$SMPROGRAMS\${APPNAME}"
    CreateShortCut "$SMPROGRAMS\${APPNAME}\Toggle Theme.lnk" "$INSTDIR\ThemeToggle.exe" "" "$INSTDIR\themetoggle_dark.ico" 0
    CreateShortCut "$SMPROGRAMS\${APPNAME}\Toggle Theme (Silent).lnk" "wscript.exe" '"$INSTDIR\ThemeToggle.vbs"' "$INSTDIR\themetoggle_dark.ico" 0
    CreateShortCut "$SMPROGRAMS\${APPNAME}\Force Light Mode.lnk" "wscript.exe" '"$INSTDIR\ThemeToggle-Light.vbs"' "$INSTDIR\themetoggle_dark.ico" 0
    CreateShortCut "$SMPROGRAMS\${APPNAME}\Force Dark Mode.lnk" "wscript.exe" '"$INSTDIR\ThemeToggle-Dark.vbs"' "$INSTDIR\themetoggle_dark.ico" 0
    CreateShortCut "$SMPROGRAMS\${APPNAME}\Uninstall.lnk" "$INSTDIR\Uninstall.exe" "" "" 0
SectionEnd

Section "Desktop Shortcut" SecDesktop
    CreateShortCut "$DESKTOP\Toggle Theme.lnk" "wscript.exe" '"$INSTDIR\ThemeToggle.vbs"' "$INSTDIR\themetoggle_dark.ico" 0
    
    ; Show message about hotkey assignment
    MessageBox MB_OK|MB_ICONINFORMATION "Desktop shortcut created!$\r$\n$\r$\nTo assign a hotkey:$\r$\n1. Right-click the shortcut$\r$\n2. Select Properties$\r$\n3. Click in 'Shortcut key' field$\r$\n4. Press your desired key combination (e.g., Ctrl+Alt+T)$\r$\n5. Click OK"
SectionEnd

Section "Add to Startup" SecStartup
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "${APPNAME}" '"wscript.exe" "$INSTDIR\ThemeToggle.vbs"'
SectionEnd

Section "Scheduled Tasks (7AM Light, 7PM Dark)" SecScheduled
    ; Create morning task (7AM Light)
    nsExec::ExecToLog 'schtasks /create /tn "${APPNAME}-Morning" /tr "wscript.exe \"$INSTDIR\ThemeToggle-Light.vbs\"" /sc daily /st 07:00 /f'
    Pop $0
    
    ; Create evening task (7PM Dark)
    nsExec::ExecToLog 'schtasks /create /tn "${APPNAME}-Evening" /tr "wscript.exe \"$INSTDIR\ThemeToggle-Dark.vbs\"" /sc daily /st 19:00 /f'
    Pop $0
    
    ${If} $0 == 0
        MessageBox MB_OK|MB_ICONINFORMATION "Scheduled tasks created!$\r$\n$\r$\n- Light mode: 7:00 AM$\r$\n- Dark mode: 7:00 PM$\r$\n$\r$\nCustomize times in Task Scheduler (taskschd.msc)"
    ${Else}
        MessageBox MB_OK|MB_ICONWARNING "Failed to create scheduled tasks.$\r$\n$\r$\nYou can manually create them by running:$\r$\n$INSTDIR\setup.bat"
    ${EndIf}
SectionEnd

; ============================================================================
; Section Descriptions
; ============================================================================

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecCore} "Core files required to run ${APPNAME} (required)."
    !insertmacro MUI_DESCRIPTION_TEXT ${SecStartMenu} "Create Start Menu shortcuts for easy access."
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} "Create desktop shortcut with hotkey capability (recommended)."
    !insertmacro MUI_DESCRIPTION_TEXT ${SecStartup} "Launch ${APPNAME} automatically when Windows starts."
    !insertmacro MUI_DESCRIPTION_TEXT ${SecScheduled} "Automatically switch to light mode at 7AM and dark mode at 7PM."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; ============================================================================
; Uninstaller Section
; ============================================================================

Section "Uninstall"
    ; Remove scheduled tasks
    nsExec::ExecToLog 'schtasks /delete /tn "${APPNAME}-Morning" /f'
    nsExec::ExecToLog 'schtasks /delete /tn "${APPNAME}-Evening" /f'
    
    ; Remove startup entry
    DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "${APPNAME}"
    
    ; Remove Start Menu shortcuts
    Delete "$SMPROGRAMS\${APPNAME}\Toggle Theme.lnk"
    Delete "$SMPROGRAMS\${APPNAME}\Toggle Theme (Silent).lnk"
    Delete "$SMPROGRAMS\${APPNAME}\Force Light Mode.lnk"
    Delete "$SMPROGRAMS\${APPNAME}\Force Dark Mode.lnk"
    Delete "$SMPROGRAMS\${APPNAME}\Uninstall.lnk"
    RMDir "$SMPROGRAMS\${APPNAME}"
    
    ; Remove desktop shortcut
    Delete "$DESKTOP\Toggle Theme.lnk"
    
    ; Remove files
    Delete "$INSTDIR\ThemeToggle.exe"
    Delete "$INSTDIR\ThemeToggle.vbs"
    Delete "$INSTDIR\ThemeToggle-Light.vbs"
    Delete "$INSTDIR\ThemeToggle-Dark.vbs"
    Delete "$INSTDIR\ThemeToggle.ps1"
    Delete "$INSTDIR\setup.bat"
    Delete "$INSTDIR\uninstall.bat"
    Delete "$INSTDIR\README.md"
    Delete "$INSTDIR\CHANGELOG.md"
    Delete "$INSTDIR\themetoggle_dark.ico"
    Delete "$INSTDIR\docs\RELEASE_NOTES.md"
    RMDir "$INSTDIR\docs"
    Delete "$INSTDIR\Uninstall.exe"
    
    ; Remove installation directory if empty
    RMDir "$INSTDIR"
    
    ; Remove registry keys
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
    DeleteRegKey HKCU "Software\${APPNAME}"
    
SectionEnd

; ============================================================================
; Installer Functions
; ============================================================================

Function .onInit
    ; Check if already installed
    ReadRegStr $0 HKCU "Software\${APPNAME}" "InstallDir"
    ${If} $0 != ""
        ${If} ${FileExists} "$0\ThemeToggle.exe"
            MessageBox MB_YESNO|MB_ICONQUESTION "${APPNAME} is already installed at:$\r$\n$0$\r$\n$\r$\nDo you want to reinstall?" IDYES continue
            Abort
            continue:
        ${EndIf}
    ${EndIf}
FunctionEnd
