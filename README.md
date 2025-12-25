# Windows Theme Toggle

? Ultra-fast Windows theme switcher (10-15ms execution).

## Features

- **Instant toggle** - Sub-15ms execution (<1 frame @ 60fps)
- **Hotkey support** - Silent VBScript launchers for keyboard shortcuts
- **Scheduled automation** - Sunrise/sunset theme changes
- **Stubborn app handling** - Explicitly kicks ~14 common apps (Explorer, VS Code, Terminal)
- **Windows optimized** - Detects Win10/11, uses version-specific APIs

## Quick Start

```cmd
ThemeToggle.exe           # Toggle current theme
ThemeToggle.exe /light    # Force light mode
ThemeToggle.exe /dark     # Force dark mode
ThemeToggle.vbs           # Silent toggle (for hotkeys)
```

## Installation

Run `setup.bat` for interactive installer:
- **Desktop shortcut** - Assign custom hotkey via properties
- **Startup entry** - Auto-toggle on login  
- **Scheduled tasks** - 7AM light, 7PM dark (customizable)

## Command-Line Options

| Option | Description |
|--------|-------------|
| `/light` | Force light theme |
| `/dark` | Force dark theme |
| `/toggle` | Toggle current theme (default) |
| `/quiet` | Suppress console output |
| `/exitcode` | Return status as exit code |
| `/nokick` | Skip stubborn app notifications |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | No change needed (already set) |
| `1` | Changed to Light theme |
| `2` | Changed to Dark theme |
| `10` | Registry access failed |
| `11` | Registry write failed |
| `20` | Broadcast failed (theme changed) |
| `30` | Already running (mutex locked) |

## Building from Source

Requires Visual Studio 2019+ (MSVC) and Windows SDK.

```cmd
build.bat  # Compiles to ThemeToggle.exe (~220 KB)
```

**Build configuration:**
- C++17 with `/O2` optimizations
- Static runtime (`/MT`) - no dependencies
- Embedded icon and manifest

## Architecture

### Components
- **RegistryManager** - Safe registry operations with rollback on failure
- **BroadcastManager** - Parallel notifications + stubborn app kicking  
- **UxThemeHelper** - Windows 11 undocumented APIs (ordinal 104, 135, 136)
- **Types.h** - RAII wrappers (RegKey, MutexGuard, PriorityBoost)

### Performance
- **Execution time:** 10-15ms (imperceptible to users)
- **App coverage:** ~95% (targets taskbar, tray, Explorer, Settings, widgets)
- **Reliability:** Mutex prevents race conditions, RAII prevents leaks
- **Fire-and-forget broadcasts** - Zero blocking on hung windows

## Automation Examples

### Hotkey (Recommended)
1. Run `setup.bat` ? Create desktop shortcut
2. Right-click shortcut ? Properties ? Shortcut Key
3. Assign `Ctrl+Alt+T` (or your preference)

### PowerShell
```powershell
.\ThemeToggle.ps1          # Toggle
.\ThemeToggle.ps1 -Light   # Force light
.\ThemeToggle.ps1 -Dark    # Force dark
```

### Task Scheduler (Sunrise/Sunset)
```cmd
# Edit times in Task Scheduler (taskschd.msc)
setup.bat  # Creates ThemeToggle-Morning and ThemeToggle-Evening tasks
```

## Registry Keys Modified

```
HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize
??? SystemUsesLightTheme (DWORD) - 0=Dark, 1=Light
??? AppsUseLightTheme    (DWORD) - 0=Dark, 1=Light
```

## Compatibility

- Windows 10 (1809+)
- Windows 11 (all versions)
- Windows Server 2019+
- LTSC builds (auto-creates missing keys)

## License

Public domain. Use freely in any project, commercial or personal.

## Credits

Developed with focus on speed, reliability, and Windows internals knowledge.

---

**See [CHANGELOG.md](CHANGELOG.md) for version history.**  
**See [docs/RELEASE_NOTES.md](docs/RELEASE_NOTES.md) for detailed patch notes.**
