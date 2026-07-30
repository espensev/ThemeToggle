# ThemeToggle

[![WinGet version](https://img.shields.io/winget/v/SevIQ.ThemeToggle)](https://winstall.app/apps/SevIQ.ThemeToggle)
[![GitHub release](https://img.shields.io/github/v/release/espensev/ThemeToggle)](https://github.com/espensev/ThemeToggle/releases/latest)
[![Build](https://github.com/espensev/ThemeToggle/actions/workflows/build.yml/badge.svg)](https://github.com/espensev/ThemeToggle/actions/workflows/build.yml)
[![License: Unlicense](https://img.shields.io/github/license/espensev/ThemeToggle)](https://unlicense.org/)

A fast, lightweight Windows utility for switching between Light and Dark modes
from the command line, shortcuts, or scheduled tasks. A switch completes in
roughly 30-45 ms end-to-end on the test system's busy desktop, dominated by
the global theme broadcast to all windows.

## Quick Start

```cmd
ThemeToggle.exe           # Toggle theme
ThemeToggle.exe /light    # Force light mode
ThemeToggle.exe /dark     # Force dark mode
ThemeToggle.exe /quiet    # Silent (for automation)
```

GUI launches (shortcuts, Task Scheduler, double-click) are silent by default;
the theme change is the only visible feedback. Console runs print a short
status line unless `/quiet` is used.

## Installation

### Install with WinGet

```cmd
winget install SevIQ.ThemeToggle
```

WinGet availability can lag behind a GitHub release while the corresponding
`microsoft/winget-pkgs` manifest PR is reviewed and merged.

### Download a release

1. Download `ThemeToggle.exe` from [Releases](https://github.com/espensev/ThemeToggle/releases)
2. Run it directly; no installation is required.

## Automation

### Hotkey Setup

1. Create a desktop shortcut to `ThemeToggle.exe`.
2. Open **Properties** and select the **Shortcut key** field.
3. Assign a shortcut such as `Ctrl+Alt+T`.
4. Add `/quiet` to the target for silent operation.

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

- [Development guide](docs/DEVELOPMENT.md) — build, tooling, and benchmarking
- [Release guide](docs/RELEASE.md) — release pipeline and WinGet
- [Technical reference](docs/TECHNICAL.md) — architecture and registry behavior
- [Release notes](docs/RELEASE_NOTES.md) — detailed technical changes

## License

Released into the public domain under the [Unlicense](https://unlicense.org/).

Found a bug or have a suggestion? [Open an issue](https://github.com/espensev/ThemeToggle/issues).
