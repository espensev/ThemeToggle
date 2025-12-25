# Release v1.2.0 - "Fire and Forget" ?

Ultra-fast Windows theme toggle with sub-15ms execution time.

---

## ?? What's New

### Performance Breakthrough
- **83% faster** - Reduced from 110ms to 10-15ms (7-11x faster!)
- **Sub-16ms execution** - Imperceptible to users (<1 frame @ 60fps)
- **Zero blocking operations** - Fire-and-forget messaging eliminates all waits

### Features
- ? **Stubborn app detection** - Explicitly kicks ~14 common apps (Explorer, VS Code, Terminal)
- ? **Windows 11 optimization** - Undocumented uxtheme APIs for instant updates
- ? **Multi-monitor support** - All taskbars update simultaneously
- ? **Mutex protection** - Prevents race conditions from rapid toggles
- ? **Registry rollback** - Atomic writes with automatic failure recovery

### Architecture Improvements
- ??? **Modular design** - Separated into focused components (RegistryManager, BroadcastManager, UxThemeHelper)
- ??? **RAII wrappers** - Zero memory leaks, exception-safe cleanup
- ?? **Better error handling** - Typed exceptions with exit codes

---

## ?? Download

### Portable Executable (Recommended)
- **[ThemeToggle.exe](https://github.com/yourusername/ThemeToggle/releases/download/v1.2.0/ThemeToggle.exe)** (~220 KB)
  - No installation required
  - Standalone, no dependencies
  - Just run and use

### Installer
- **[ThemeToggle-Setup-1.2.0.exe](https://github.com/yourusername/ThemeToggle/releases/download/v1.2.0/ThemeToggle-Setup-1.2.0.exe)** (~500 KB)
  - Automatic installation to Program Files
  - Desktop shortcut creation
  - Start Menu entry
  - Uninstaller included
  - Optional: Add to startup, create scheduled tasks

### Source Code
- **[Source code (zip)](https://github.com/yourusername/ThemeToggle/archive/refs/tags/v1.2.0.zip)**
- **[Source code (tar.gz)](https://github.com/yourusername/ThemeToggle/archive/refs/tags/v1.2.0.tar.gz)**

---

## ?? Quick Start

### Portable Usage
1. Download `ThemeToggle.exe`
2. Run `ThemeToggle.exe` to toggle theme
3. Optional: Run `setup.bat` for hotkey/automation

### Installer Usage
1. Download `ThemeToggle-Setup-1.2.0.exe`
2. Run installer, follow prompts
3. Access via Start Menu or desktop shortcut

### Command-Line
```cmd
ThemeToggle.exe           # Toggle current theme
ThemeToggle.exe /light    # Force light mode
ThemeToggle.exe /dark     # Force dark mode
ThemeToggle.vbs           # Silent toggle (for hotkeys)
```

---

## ?? System Requirements

- **OS:** Windows 10 (1809+) or Windows 11
- **Architecture:** x64 (Intel/AMD)
- **Permissions:** User-level (no admin required)
- **Dependencies:** None (fully self-contained)

---

## ?? Performance Comparison

| Version | Execution Time | Improvement |
|---------|----------------|-------------|
| v1.0.0 | 110ms | Baseline |
| v1.1.0 | 70ms | 36% faster |
| **v1.2.0** | **10-15ms** | **83-86% faster** ?? |

---

## ?? What's Included

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

### Documentation
- `README.md` - Quick start guide
- `CHANGELOG.md` - Version history
- `docs/RELEASE_NOTES.md` - Detailed technical notes

---

## ??? Building from Source

Requires Visual Studio 2019+ (MSVC) and Windows SDK.

```cmd
git clone https://github.com/yourusername/ThemeToggle.git
cd ThemeToggle
build.bat
```

Output: `ThemeToggle.exe` (~220 KB standalone executable)

---

## ?? Known Issues

- **Browsers** (Chrome, Firefox, Edge) - Often require manual refresh to update theme
- **Legacy apps** - Apps that hardcode colors won't update
- **Custom theme engines** - Apps with proprietary theme systems may not respond

These are **not bugs** - they're limitations of apps that don't listen to Windows theme broadcasts.

---

## ?? Full Changelog

### [1.2.0] - 2024-12-24

#### Performance
- **83% faster** - Reduced from 110ms to 10-15ms
- Eliminated all blocking operations (fire-and-forget broadcasts)
- Removed DWM window enumeration (3-5ms savings)
- Removed broadcast timeouts (10-25ms savings)

#### Added
- Stubborn app detection (~14 common apps)
- Windows 11 undocumented API integration (ordinals 104, 135, 136)
- Multi-monitor taskbar support
- Mutex-based single instance protection
- Priority boost for faster execution
- `/nokick` flag to skip stubborn app notifications

#### Changed
- Refactored into modular components (RegistryManager, BroadcastManager, UxThemeHelper)
- Switched to fire-and-forget messaging (SendNotifyMessage)
- RAII wrappers for all resources (zero leaks)

#### Fixed
- Race conditions from concurrent toggles (mutex)
- Registry rollback on partial write failure
- Hung window blocking (eliminated timeouts)
- Missing registry keys on LTSC builds

See [CHANGELOG.md](https://github.com/yourusername/ThemeToggle/blob/main/CHANGELOG.md) for full version history.

---

## ?? Documentation

- [README.md](https://github.com/yourusername/ThemeToggle/blob/main/README.md) - Quick start guide
- [CHANGELOG.md](https://github.com/yourusername/ThemeToggle/blob/main/CHANGELOG.md) - Version history
- [RELEASE_NOTES.md](https://github.com/yourusername/ThemeToggle/blob/main/docs/RELEASE_NOTES.md) - Detailed technical notes

---

## ?? Credits

Developed with focus on speed, reliability, and Windows internals knowledge.

**Performance optimizations inspired by:**
- Windows internals research
- Raymond Chen's blog (The Old New Thing)
- Microsoft documentation and reverse engineering

---

## ?? License

Public domain. Use freely in any project, commercial or personal.

---

## ?? Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/ThemeToggle/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/ThemeToggle/discussions)

---

**Enjoy your blazing-fast theme toggle!** ???
