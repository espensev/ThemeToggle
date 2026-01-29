# Technical Notes

## Performance

- Typical execution: 10-15ms on a test system
- Broadcasts are async to avoid blocking
- Optional stubborn-app kick can be disabled via `/kick=none`

## Runtime & Compatibility

- Static build (`/MT`), no DLL dependencies
- Windows 10 (1809+) / Windows 11
- Server 2019+

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
