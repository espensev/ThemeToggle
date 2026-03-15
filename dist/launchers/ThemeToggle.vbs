' ============================================================================
' ThemeToggle Silent Launcher
' ============================================================================
' Purpose: Launch ThemeToggle.exe silently without showing console window
' Usage:
'   - Double-click to toggle theme silently
'   - Assign to hotkey for instant theme switching
'   - Use in scheduled tasks for sunrise/sunset automation
' ============================================================================

Option Explicit

' Configuration
Const TOGGLE_EXE = "ThemeToggle.exe"
Const WINDOW_HIDDEN = 0
Const DONT_WAIT = False

' Get the directory where this VBS script is located
Dim fso, scriptDir, exePath
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
exePath = ResolveExePath(fso, scriptDir)

' Verify ThemeToggle.exe exists
If Len(exePath) = 0 Then
    ' Show error only if exe not found (critical failure)
    WScript.Echo "Error: ThemeToggle.exe not found in:" & vbCrLf & scriptDir
    WScript.Quit 1
End If

' Create shell object and run silently
Dim shell, exitCode
Set shell = CreateObject("WScript.Shell")

' Run ThemeToggle.exe with /quiet flag, hidden window, don't wait
' This makes it completely silent and non-blocking
exitCode = shell.Run("""" & exePath & """ /quiet", WINDOW_HIDDEN, DONT_WAIT)

' Clean up
Set shell = Nothing
Set fso = Nothing

' Exit silently
WScript.Quit 0

Function ResolveExePath(fileSystem, baseDir)
    Dim candidate, parentDir, grandparentDir

    candidate = fileSystem.BuildPath(baseDir, TOGGLE_EXE)
    If fileSystem.FileExists(candidate) Then
        ResolveExePath = candidate
        Exit Function
    End If

    parentDir = fileSystem.GetParentFolderName(baseDir)
    If Len(parentDir) > 0 Then
        candidate = fileSystem.BuildPath(parentDir, TOGGLE_EXE)
        If fileSystem.FileExists(candidate) Then
            ResolveExePath = candidate
            Exit Function
        End If

        grandparentDir = fileSystem.GetParentFolderName(parentDir)
        If Len(grandparentDir) > 0 Then
            candidate = fileSystem.BuildPath(grandparentDir, TOGGLE_EXE)
            If fileSystem.FileExists(candidate) Then
                ResolveExePath = candidate
                Exit Function
            End If
        End If
    End If

    ResolveExePath = ""
End Function
