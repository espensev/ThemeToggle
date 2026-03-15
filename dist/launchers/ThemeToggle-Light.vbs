' ============================================================================
' ThemeToggle - Force Light Mode (Silent)
' ============================================================================
' Purpose: Silently switch to Light theme
' Perfect for: Morning automation, hotkeys, scheduled tasks
' ============================================================================

Option Explicit

Dim fso, scriptDir, exePath, shell
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
exePath = ResolveExePath(fso, scriptDir)

If Len(exePath) > 0 Then
    shell.Run """" & exePath & """ /light /quiet", 0, False
End If

Set shell = Nothing
Set fso = Nothing
WScript.Quit 0

Function ResolveExePath(fileSystem, baseDir)
    Dim candidate, parentDir, grandparentDir

    candidate = fileSystem.BuildPath(baseDir, "ThemeToggle.exe")
    If fileSystem.FileExists(candidate) Then
        ResolveExePath = candidate
        Exit Function
    End If

    parentDir = fileSystem.GetParentFolderName(baseDir)
    If Len(parentDir) > 0 Then
        candidate = fileSystem.BuildPath(parentDir, "ThemeToggle.exe")
        If fileSystem.FileExists(candidate) Then
            ResolveExePath = candidate
            Exit Function
        End If

        grandparentDir = fileSystem.GetParentFolderName(parentDir)
        If Len(grandparentDir) > 0 Then
            candidate = fileSystem.BuildPath(grandparentDir, "ThemeToggle.exe")
            If fileSystem.FileExists(candidate) Then
                ResolveExePath = candidate
                Exit Function
            End If
        End If
    End If

    ResolveExePath = ""
End Function
