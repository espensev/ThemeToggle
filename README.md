# ThemeToggle

Windows theme switcher (typical 10-15ms execution on a test system).

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
1. Download `ThemeToggle.exe` from [Releases](https://github.com/espensev/ThemeToggle/releases)
2. Run it directly (no installation required)

## Automation

### Hotkey Setup
1. Create desktop shortcut to `ThemeToggle.exe`
2. Right-click > Properties > Shortcut key
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
dist\launchers\ThemeToggle.ps1           # Toggle
dist\launchers\ThemeToggle.ps1 -Light    # Force light
dist\launchers\ThemeToggle.ps1 -Dark     # Force dark
```

## Command-Line Options

| Option | Description |
|--------|-------------|
| `/light` | Force light theme |
| `/dark` | Force dark theme |
| `/toggle` | Toggle current theme (default) |
| `/quiet` | Suppress console output |
| `/passthru` | Output detailed status info |
| `/exitcode` | Return status as exit code |
| `/kick=all` | Kick all stubborn apps (default) |
| `/kick=core` | Kick core stubborn apps only |
| `/kick=none` | Do not kick stubborn apps |
| `/nokick` | Alias for `/kick=none` |
| `/noflush` | Skip registry flush (best-effort) |
| `/?` or `/help` | Show usage |

All options also accept `-` or `--` prefixes.

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | No change needed |
| `1` | Changed to Light |
| `2` | Changed to Dark |
| `11` | Registry write failed |
| `12` | Registry read failed |
| `20` | Broadcast failed (registry updated) |
| `30` | Already running |
| `99` | Unknown error |

## Development & Release Docs

- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) - build, tooling, benchmarking
- [docs/RELEASE.md](docs/RELEASE.md) - release pipeline + WinGet
- [docs/TECHNICAL.md](docs/TECHNICAL.md) - architecture + registry details
- [docs/RELEASE_NOTES.md](docs/RELEASE_NOTES.md) - deep technical changes


## License

Public domain ([Unlicense](https://unlicense.org/)). Use freely in any project.

---

**WinGet:** `winget install SevIQ.ThemeToggle`  
**Issues:** [GitHub Issues](https://github.com/espensev/ThemeToggle/issues)
