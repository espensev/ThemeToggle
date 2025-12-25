# ThemeToggle

? Ultra-fast Windows theme switcher (10-15ms execution).

## Quick Start

```cmd
ThemeToggle.exe           # Toggle theme
ThemeToggle.exe /light    # Force light mode
ThemeToggle.exe /dark     # Force dark mode
ThemeToggle.exe /quiet    # Silent (for automation)
```

## Installation

### Option 1: WinGet (Recommended)
```cmd
winget install SevIQ.ThemeToggle
```

### Option 2: Manual
1. Download `ThemeToggle.exe` from [Releases](https://github.com/espensev/DarkToggle/releases)
2. Run it directly (no installation required)

## Automation

### Hotkey Setup
1. Create desktop shortcut to `ThemeToggle.exe`
2. Right-click ? Properties ? Shortcut key
3. Assign hotkey (e.g., `Ctrl+Alt+T`)
4. Add `/quiet` to Target for silent operation

### Scheduled Tasks (Sunrise/Sunset)
```cmd
# Light at 7 AM
schtasks /create /tn "Theme-Morning" /tr "\"C:\path\to\ThemeToggle.exe\" /light /quiet" /sc daily /st 07:00

# Dark at 7 PM
schtasks /create /tn "Theme-Evening" /tr "\"C:\path\to\ThemeToggle.exe\" /dark /quiet" /sc daily /st 19:00
```

### PowerShell
```powershell
.\ThemeToggle.ps1           # Toggle
.\ThemeToggle.ps1 -Light    # Force light
.\ThemeToggle.ps1 -Dark     # Force dark
```

## Command-Line Options

| Option | Description |
|--------|-------------|
| `/light` | Force light theme |
| `/dark` | Force dark theme |
| `/toggle` | Toggle current theme (default) |
| `/quiet` | Suppress console output |
| `/exitcode` | Return status as exit code |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | No change needed |
| `1` | Changed to Light |
| `2` | Changed to Dark |
| `10` | Registry access failed |
| `20` | Broadcast failed |
| `30` | Already running |

## Building from Source

```cmd
build.bat
```

**Requirements:** Visual Studio 2019+ (MSVC), Windows SDK

**Build output:** `ThemeToggle.exe` (~220 KB, no dependencies)

## Technical Details

- **Performance:** 10-15ms execution
- **Runtime:** Static (`/MT`) - no DLL dependencies
- **Compatibility:** Windows 10 (1809+), Windows 11, Server 2019+
- **Architecture:** x86 (runs on both 32-bit and 64-bit Windows)
- **Compiler:** MSVC 19.44 (C++17)
- **Optimizations:** `/O2` (speed)
- **Size:** ~220 KB

## Registry Keys Modified

```
HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize
??? SystemUsesLightTheme (DWORD) - 0=Dark, 1=Light
??? AppsUseLightTheme    (DWORD) - 0=Dark, 1=Light
```

## Project Structure

```
DarkToggle/
??? Resources/
?   ??? ThemeToggle.ico         # Application icon
??? scripts/
?   ??? launchers/              # VBS silent launchers
?   ??? *.bat                   # Build utilities
??? winget/                     # WinGet package manifests
??? main.cpp                    # Entry point
??? RegistryManager.*           # Registry operations
??? BroadcastManager.*          # Theme change notifications
??? UxThemeHelper.*             # Windows 11 API integration
??? ThemeToggle.rc              # Resource script
??? ThemeToggle.manifest        # Windows manifest
??? build.bat                   # Build script
```

## License

Public domain ([Unlicense](https://unlicense.org/)). Use freely in any project.

---

**WinGet:** `winget install SevIQ.ThemeToggle`  
**Issues:** [GitHub Issues](https://github.com/espensev/DarkToggle/issues)
