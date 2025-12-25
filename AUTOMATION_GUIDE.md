# ThemeToggle Automation Guide

Guide for automating Windows theme switching with ThemeToggle.

---

## Hotkey Setup

### Method 1: Desktop Shortcut (Recommended)

1. Create shortcut to `ThemeToggle.exe`
2. Right-click ? Properties
3. Set Shortcut key (e.g., `Ctrl+Alt+T`)
4. Add `/quiet` to Target for silent operation

### Method 2: AutoHotkey

```ahk
^!t::  ; Ctrl+Alt+T
Run, ThemeToggle.exe /quiet, , Hide
return
```

---

## Startup Automation

### Quick Setup

```cmd
setup.bat
# Select option [2] - Add to Startup
```

### Manual Registry

```cmd
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" ^
    /v "ThemeToggle" ^
    /t REG_SZ ^
    /d "\"C:\path\to\ThemeToggle.exe\" /quiet" ^
    /f
```

---

## Scheduled Tasks

### Quick Setup

```cmd
setup.bat
# Select option [3] - Create Scheduled Tasks
```

**Default:** Light at 7:00 AM, Dark at 7:00 PM

### Custom Times

```cmd
schtasks /create /tn "Theme-Morning" ^
    /tr "\"C:\path\to\ThemeToggle.exe\" /light /quiet" ^
    /sc daily /st 06:30 /f
```

---

## PowerShell Automation

```powershell
.\ThemeToggle.ps1           # Toggle
.\ThemeToggle.ps1 -Light    # Light mode
.\ThemeToggle.ps1 -Dark     # Dark mode
```

---

## Context Menu Integration

Save as `register-context-menu.reg`:

```reg
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\DesktopBackground\Shell\ToggleTheme]
@="Toggle Windows Theme"
"Icon"="C:\\path\\to\\ThemeToggle.exe,0"

[HKEY_CLASSES_ROOT\DesktopBackground\Shell\ToggleTheme\command]
@="\"C:\\path\\to\\ThemeToggle.exe\" /quiet"
```

---

## Advanced Scenarios

### Stream Deck Integration

1. Add **Open** action
2. Set path: `C:\path\to\ThemeToggle.exe`
3. Args: `/quiet`

### Conditional Theme Switching

```powershell
# Switch based on battery status
$battery = Get-WmiObject -Class Win32_Battery
if ($battery.BatteryStatus -eq 1) {
    & "ThemeToggle.exe" /dark /quiet
} else {
    & "ThemeToggle.exe" /light /quiet
}
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | No change needed |
| 1 | Changed to Light |
| 2 | Changed to Dark |
| 10 | Registry error |
| 11 | Write failed |
| 20 | Broadcast failed |
| 30 | Already running |

Use in scripts:

```cmd
ThemeToggle.exe /dark /exitcode
if %ERRORLEVEL% EQU 2 echo Successfully changed to dark
```

---

## Troubleshooting

- **Hotkey doesn't work**: Check for conflicts with other apps
- **Scheduled task fails**: Use absolute paths
- **Theme doesn't change**: Verify Windows 10 (1809+) or Windows 11

---

**See Also**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
