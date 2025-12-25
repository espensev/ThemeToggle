' ============================================================================
' ThemeToggle - Force Dark Mode (Silent)
' ============================================================================
' Purpose: Silently switch to Dark theme
' Perfect for: Evening automation, hotkeys, scheduled tasks
' ============================================================================

Option Explicit

Dim fso, scriptDir, exePath, shell
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
exePath = fso.BuildPath(scriptDir, "ThemeToggle.exe")

If fso.FileExists(exePath) Then
    shell.Run """" & exePath & """ /dark /quiet", 0, False
End If

Set shell = Nothing
Set fso = Nothing
WScript.Quit 0
