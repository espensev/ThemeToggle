# Release v1.3.0 - "Distribution Pipeline"

Distribution-focused update with installer, automated release pipeline, and WinGet tooling.

---

## What's New

- NSIS installer with optional shortcuts/startup/scheduled tasks (user-scope install)
- Unified release pipeline: `dist/build-release.bat`
- WinGet manifest updater: `dist/update-winget.ps1`
- Consolidated silent launchers in `dist/launchers`
- Resource embedding via `ThemeToggle.rc`

---

## Download

### Portable Executable (Recommended)
- `ThemeToggle.exe`
  - https://github.com/espensev/ThemeToggle/releases/download/v1.3.0/ThemeToggle.exe

### Installer
- `ThemeToggle-Setup-1.3.0.exe`
  - https://github.com/espensev/ThemeToggle/releases/download/v1.3.0/ThemeToggle-Setup-1.3.0.exe

### Portable ZIP
- `ThemeToggle-Portable.zip`
  - https://github.com/espensev/ThemeToggle/releases/download/v1.3.0/ThemeToggle-Portable.zip

### Source Code
- https://github.com/espensev/ThemeToggle/archive/refs/tags/v1.3.0.zip
- https://github.com/espensev/ThemeToggle/archive/refs/tags/v1.3.0.tar.gz

---

## Quick Start

```cmd
ThemeToggle.exe           # Toggle current theme
ThemeToggle.exe /light    # Force light mode
ThemeToggle.exe /dark     # Force dark mode
ThemeToggle.vbs           # Silent toggle (for hotkeys)
```

---

## System Requirements

- OS: Windows 10 (1809+) or Windows 11
- Architecture: x86 (runs on 32-bit and 64-bit Windows)
- Permissions: User-level (no admin required)
- Dependencies: None

---

## Performance

- 10-15ms execution time (unchanged)

---

## What's Included

### Executables
- `ThemeToggle.exe` - Main executable (~220 KB)

### Launchers (Silent Execution)
- `ThemeToggle.vbs` - Silent toggle (for hotkeys)
- `ThemeToggle-Light.vbs` - Force light mode
- `ThemeToggle-Dark.vbs` - Force dark mode
- `ThemeToggle.ps1` - PowerShell version

### Setup Tools
- `setup.bat` - Interactive installer (creates shortcuts, scheduled tasks)
- `uninstall.bat` - Cleanup script
- `build.bat` - Build from source (requires Visual Studio)

---

## Building from Source

Requires Visual Studio 2019+ (MSVC) and Windows SDK.

```cmd
git clone https://github.com/espensev/ThemeToggle.git
cd ThemeToggle
build.bat
```

Output: `ThemeToggle.exe` (~220 KB standalone executable)

---

## Known Issues

- Browsers (Chrome, Firefox, Edge) often require manual refresh to update theme
- Legacy apps that hardcode colors will not update
- Apps with proprietary theme engines may not respond

---

## Documentation

- https://github.com/espensev/ThemeToggle/blob/main/README.md
- https://github.com/espensev/ThemeToggle/blob/main/docs/RELEASE_NOTES.md

---

## Support

- https://github.com/espensev/ThemeToggle/issues
