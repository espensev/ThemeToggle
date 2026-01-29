; ============================================================================
; ThemeToggle NSIS Installer Script
; ============================================================================
; Creates a professional Windows installer with:
; - Automatic installation to AppData\Local\ThemeToggle
; - Desktop shortcut with optional hotkey
; - Start Menu entries
; - Optional startup integration
; - Optional scheduled tasks (sunrise/sunset automation)
; - Proper uninstaller with registry cleanup
; ============================================================================

!define PRODUCT_NAME "ThemeToggle"
!define PRODUCT_VERSION "1.5.0"
!define PRODUCT_PUBLISHER "SevIQ"
!define PRODUCT_WEB_SITE "https://github.com/espensev/ThemeToggle"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKCU"

; Modern UI
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"

; Installer settings
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "ThemeToggle-Setup-${PRODUCT_VERSION}.exe"
InstallDir "$LOCALAPPDATA\${PRODUCT_NAME}"
InstallDirRegKey HKCU "Software\${PRODUCT_NAME}" "InstallDir"
RequestExecutionLevel user
ShowInstDetails show
ShowUnInstDetails show

; Modern UI Configuration
!define MUI_ABORTWARNING
!define MUI_ICON "Resources\ThemeToggle.ico"
!define MUI_UNICON "Resources\ThemeToggle.ico"
!define MUI_HEADERIMAGE
!define MUI_WELCOMEFINISHPAGE_BITMAP_NOSTRETCH
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

; Finish page options
!define MUI_FINISHPAGE_RUN "$INSTDIR\ThemeToggle.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Test theme toggle now"
!define MUI_FINISHPAGE_SHOWREADME ""
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Create desktop shortcut"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION CreateDesktopShortcut

; Installer pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
!insertmacro MUI_PAGE_DIRECTORY
Page custom InstallOptionsPage InstallOptionsPageLeave
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Language
!insertmacro MUI_LANGUAGE "English"

; Variables for custom options
Var CreateShortcut
Var AddToStartup
Var CreateScheduledTasks

; Custom options page
Function InstallOptionsPage
  !insertmacro MUI_HEADER_TEXT "Installation Options" "Choose additional setup options"
  
  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}
  
  ${NSD_CreateLabel} 0 0 100% 12u "Select additional features:"
  Pop $0
  
  ${NSD_CreateCheckbox} 10u 20u 100% 12u "Create desktop shortcut (recommended for hotkey setup)"
  Pop $CreateShortcut
  ${NSD_Check} $CreateShortcut
  
  ${NSD_CreateCheckbox} 10u 40u 100% 12u "Add to Windows startup (auto-toggle on login)"
  Pop $AddToStartup
  
  ${NSD_CreateCheckbox} 10u 60u 100% 12u "Create scheduled tasks (Light at 7 AM, Dark at 7 PM)"
  Pop $CreateScheduledTasks
  
  ${NSD_CreateLabel} 10u 80u 100% 24u "Note: You can change these settings later by running setup.bat or uninstall.bat in the installation directory."
  Pop $0
  
  nsDialogs::Show
FunctionEnd

Function InstallOptionsPageLeave
  ${NSD_GetState} $CreateShortcut $CreateShortcut
  ${NSD_GetState} $AddToStartup $AddToStartup
  ${NSD_GetState} $CreateScheduledTasks $CreateScheduledTasks
FunctionEnd

; Main installation section
Section "MainSection" SEC01
  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer
  
  ; Core files
  File "ThemeToggle.exe"
  File "dist\launchers\ThemeToggle.ps1"
  File "LICENSE.txt"
  File "README.md"
  
  ; Launcher scripts
  File "dist\launchers\ThemeToggle.vbs"
  File "dist\launchers\ThemeToggle-Light.vbs"
  File "dist\launchers\ThemeToggle-Dark.vbs"
  
  ; Setup and uninstall scripts
  File "setup.bat"
  File "uninstall.bat"
  
  ; Resources folder
  SetOutPath "$INSTDIR\Resources"
  File "Resources\ThemeToggle.ico"
  
  ; Create Start Menu shortcuts
  CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk" "$INSTDIR\ThemeToggle.vbs" "" "$INSTDIR\Resources\ThemeToggle.ico" 0
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Light Mode.lnk" "$INSTDIR\ThemeToggle-Light.vbs" "" "$INSTDIR\Resources\ThemeToggle.ico" 0
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Dark Mode.lnk" "$INSTDIR\ThemeToggle-Dark.vbs" "" "$INSTDIR\Resources\ThemeToggle.ico" 0
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Setup.lnk" "$INSTDIR\setup.bat" "" "$INSTDIR\Resources\ThemeToggle.ico" 0
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall.lnk" "$INSTDIR\uninstall.bat" "" "$INSTDIR\Resources\ThemeToggle.ico" 0
  
  ; Registry entries
  WriteRegStr HKCU "Software\${PRODUCT_NAME}" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\${PRODUCT_NAME}" "Version" "${PRODUCT_VERSION}"
  
  ; Uninstaller
  WriteUninstaller "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "${PRODUCT_NAME}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\Resources\ThemeToggle.ico"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  
  ; Calculate installed size
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "EstimatedSize" "$0"
  
  ; Optional: Desktop shortcut
  ${If} $CreateShortcut == ${BST_CHECKED}
    CreateShortCut "$DESKTOP\Toggle Theme.lnk" "$INSTDIR\ThemeToggle.vbs" "" "$INSTDIR\Resources\ThemeToggle.ico" 0
  ${EndIf}

  ; Optional: Add to startup
  ${If} $AddToStartup == ${BST_CHECKED}
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "${PRODUCT_NAME}" '"$INSTDIR\ThemeToggle.vbs"'
  ${EndIf}

  ; Optional: Create scheduled tasks
  ${If} $CreateScheduledTasks == ${BST_CHECKED}
    DetailPrint "Creating scheduled tasks..."
    ExecWait 'schtasks /create /tn "ThemeToggle-Morning" /tr "\"$INSTDIR\ThemeToggle-Light.vbs\"" /sc daily /st 07:00 /f'
    ExecWait 'schtasks /create /tn "ThemeToggle-Evening" /tr "\"$INSTDIR\ThemeToggle-Dark.vbs\"" /sc daily /st 19:00 /f'
  ${EndIf}
SectionEnd

; Desktop shortcut function (called from finish page)
Function CreateDesktopShortcut
  CreateShortCut "$DESKTOP\Toggle Theme.lnk" "$INSTDIR\ThemeToggle.vbs" "" "$INSTDIR\Resources\ThemeToggle.ico" 0
FunctionEnd

; Uninstaller section
Section Uninstall
  ; Remove scheduled tasks
  ExecWait 'schtasks /delete /tn "ThemeToggle-Morning" /f' $0
  ExecWait 'schtasks /delete /tn "ThemeToggle-Evening" /f' $0
  
  ; Remove startup entry
  DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "${PRODUCT_NAME}"
  
  ; Remove desktop shortcut
  Delete "$DESKTOP\Toggle Theme.lnk"
  
  ; Remove Start Menu shortcuts
  RMDir /r "$SMPROGRAMS\${PRODUCT_NAME}"
  
  ; Remove files
  Delete "$INSTDIR\ThemeToggle.exe"
  Delete "$INSTDIR\ThemeToggle.ps1"
  Delete "$INSTDIR\ThemeToggle.vbs"
  Delete "$INSTDIR\ThemeToggle-Light.vbs"
  Delete "$INSTDIR\ThemeToggle-Dark.vbs"
  Delete "$INSTDIR\setup.bat"
  Delete "$INSTDIR\uninstall.bat"
  Delete "$INSTDIR\LICENSE.txt"
  Delete "$INSTDIR\README.md"
  Delete "$INSTDIR\Resources\ThemeToggle.ico"
  Delete "$INSTDIR\uninst.exe"
  
  ; Remove directories
  RMDir "$INSTDIR\Resources"
  RMDir "$INSTDIR"
  
  ; Remove registry entries
  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKCU "Software\${PRODUCT_NAME}"
  
  SetAutoClose true
SectionEnd
