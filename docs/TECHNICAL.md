# Technical Notes

## Performance

- Typical execution: 10-15ms on a test system
- Broadcasts are async to avoid blocking
- Optional stubborn-app kick can be disabled via `/kick=none`

## Runtime & Compatibility

- Static build (`/MT`), no DLL dependencies
- Windows 10 (1809+) / Windows 11
- Server 2019+

## Behavior Flow (High-Level)

1) Acquire single-instance mutex  
2) Read current theme from registry  
3) Write new theme values  
4) Flush registry (unless `/noflush`)  
5) Broadcast theme change (async)  
6) Optional stubborn-app kick (`/kick=...`)  

## CLI Behavior (Summary)

Common options:
- `/toggle` (default), `/light`, `/dark`
- `/quiet` suppress console output
- `/exitcode` return status as exit code
- `/kick=all|core|none` (or `/nokick`)
- `/noflush` skip registry flush

Exit codes:
- `0` no change needed
- `1` changed to Light
- `2` changed to Dark
- `10` registry access failed
- `11` registry write failed
- `20` broadcast failed
- `30` already running

## Registry Keys Modified

```
HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize
  SystemUsesLightTheme (DWORD) - 0=Dark, 1=Light
  AppsUseLightTheme    (DWORD) - 0=Dark, 1=Light
```

## Architecture

Key components:
- `src/main.cpp` - entry point and CLI
- `src/RegistryManager.cpp` - registry operations
- `src/BroadcastManager.cpp` - theme notifications
- `src/UxThemeHelper.cpp` - Windows 11 refresh helpers

## Windows 11 Specifics

Windows 11 refresh calls (uxtheme APIs) are used when available; on older builds they are no-ops. This helps context menus and modern UI refresh faster after a theme change.

## Stubborn App Handling

Some apps cache theme state. The optional kick step explicitly notifies common offenders (Explorer, dialogs, Office/WPF apps, Terminal, Chrome/Firefox). Use `/kick=none` if you want the fastest path.

## Project Structure

```
ThemeToggle/
  src/                          Source files
  include/                      Headers
  Resources/                    Icon + manifest
  .github/workflows/            CI + release pipelines
  dist/                         Release scripts + launchers
  tools/                        Tooling + signing
  winget/                       WinGet manifests
  ThemeToggle.rc                Resource script
  setup.nsi                     NSIS installer
  build.bat                     Build script
```
