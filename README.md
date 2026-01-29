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

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | No change needed |
| `1` | Changed to Light |
| `2` | Changed to Dark |
| `10` | Registry access failed |
| `11` | Registry write failed |
| `20` | Broadcast failed |
| `30` | Already running |

## Building from Source

```cmd
build.bat
```

**Requirements:** Visual Studio 2019+ (MSVC), Windows SDK, NSIS (for installer)

**Build output:** `ThemeToggle.exe` (single-file, no dependencies)

## Release Process

### Automated (GitHub Actions)

Push a version tag to trigger automatic release:
```cmd
git tag v1.5.2
git push origin v1.5.2
```

This builds all artifacts, calculates SHA256 hashes, creates a GitHub release, and submits to WinGet automatically.

**First-time setup:**
- Add a classic PAT (`ghp_`) with `public_repo` as `WINGET_GITHUB_TOKEN` (fine-grained PATs do not work for `winget-pkgs`)
- Fork `microsoft/winget-pkgs` with the same account as the PAT
- Ensure `winget/` manifests are current (run `dist/update-winget.ps1` and commit) before the first tag

See [docs/WINGET_SUBMISSION.md](docs/WINGET_SUBMISSION.md).

### Manual

```cmd
dist\build-release.bat      # Build exe, installer, portable ZIP
dist\update-winget.ps1      # Update manifests with SHA256
```

If signing env vars are set, artifacts are signed automatically.

## Benchmarking

```powershell
.\tools\bench.ps1 -Iterations 1000
```
Use `-SettleMs` to wait between toggles so apps can visually update (default: 250ms).
For longer runs, consider `-BatchSize`/`-BatchPauseMs` and `-JitterMs` to reduce system stress.

**Export for another machine:**
```powershell
.\tools\export-bench.ps1 -Zip
```

## Technical Details

- **Performance:** 10-15ms execution
- **Runtime:** Static (`/MT`) - no DLL dependencies
- **Compatibility:** Windows 10 (1809+), Windows 11, Server 2019+
- **Architecture:** x86 (runs on both 32-bit and 64-bit Windows)
- **Compiler:** MSVC 19.44 (C++17)
- **Build flags:** `/O2`
- **Size:** ~220 KB

## Registry Keys Modified

```
HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize
  SystemUsesLightTheme (DWORD) - 0=Dark, 1=Light
  AppsUseLightTheme    (DWORD) - 0=Dark, 1=Light
```

## Project Structure

```
ThemeToggle/
  src/                          Source files
    main.cpp                    Entry point
    RegistryManager.cpp         Registry operations
    BroadcastManager.cpp        Theme notifications
    UxThemeHelper.cpp           Windows 11 API
  include/                      Headers
    Types.h                     RAII wrappers, exit codes
    RegistryManager.h
    BroadcastManager.h
    UxThemeHelper.h
    StringUtils.h
  Resources/
    ThemeToggle.ico             Application icon
    ThemeToggle.manifest        Windows manifest
  .github/
    workflows/                  GitHub Actions
      build.yml                 CI build on push/PR
      release.yml               Automated release on tag
      validate-winget.yml       Manifest validation
      winget-publish.yml        Auto-submit to WinGet
  dist/
    build-release.bat           Release pipeline
    update-winget.ps1           WinGet manifest updater
    launchers/                  VBS/PS1 silent launchers
  tools/
    signing/sign-release.ps1    Release signing
    bump-version.ps1            Version management
    bench.ps1                   Benchmarking
  winget/                       WinGet package manifests
  ThemeToggle.rc                Resource script
  setup.nsi                     NSIS installer
  build.bat                     Build script
```


## License

Public domain ([Unlicense](https://unlicense.org/)). Use freely in any project.

---

**WinGet:** `winget install SevIQ.ThemeToggle`  
**Issues:** [GitHub Issues](https://github.com/espensev/ThemeToggle/issues)
