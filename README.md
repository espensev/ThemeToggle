# Windows Theme Toggler

A utility for switching between Light and Dark themes on Windows 10/11.

## Features

- **Reliable Performance**: Executes theme toggling operations efficiently.
- **Standalone Application**: No external dependencies required.
- **Immediate Feedback**: Updates the user interface promptly after toggling.
- **Script-Friendly**: Designed to work seamlessly with automation scripts.
- **Modern C++ Implementation**: Utilizes C++17 features for resource management.

## Performance Overview

| Operation         | Time (ms) | Notes                          |
|-------------------|-----------|--------------------------------|
| No change needed  | 5-10      | Exits early if no action needed|
| Registry read     | 2-5       | Read-only access              |
| Registry write    | 2-5       | Only performed when necessary |
| Broadcast         | ~50       | Asynchronous with timeout     |
| Theme change      | ~110      | Includes all operations       |

### Comparison with Previous Implementation
- Faster theme changes (~110ms compared to ~5000ms).
- Improved reliability in handling registry keys.

## Usage

### Command-Line Execution
```bash
# Toggle current theme (default)
ThemeToggle.exe

# Force light theme
ThemeToggle.exe /light

# Force dark theme
ThemeToggle.exe /dark

# Suppress output
ThemeToggle.exe /quiet

# Get detailed information
ThemeToggle.exe /passthru

# Return exit code (for scripts)
ThemeToggle.exe /exitcode
```

### Shortcuts & Automation
- Double-clicking `ThemeToggle.exe` toggles the theme (no console window).
- Create shortcuts with explicit modes, e.g.:
  - `ThemeToggle.exe /light /quiet`
  - `ThemeToggle.exe /dark /quiet`
  - `ThemeToggle.exe /quiet` (toggle silently)
- Scheduled tasks can call the executable directly with the same arguments.

**PowerShell alternative:**
```powershell
.\ThemeToggle.ps1           # Toggle
.\ThemeToggle.ps1 -Light    # Force light
.\ThemeToggle.ps1 -Dark     # Force dark
```

Refer to [AUTOMATION_GUIDE.md](AUTOMATION_GUIDE.md) for:
- Hotkey setup
- Sunrise/sunset automation
- Context menu integration
- Integration with macro pads

## Exit Codes

| Code | Description                     |
|------|---------------------------------|
| 0    | No change needed                |
| 1    | Switched to Light theme         |
| 2    | Switched to Dark theme          |
| 10   | Registry key access failed      |
| 11   | Registry write failed           |
| 20   | Broadcast failed (theme changed)|

When exit code `20` occurs the registry values were updated successfully, but one or more broadcast notifications did not complete. The console output includes a "broadcast issue detected" note so scripts and operators can decide whether to retry.

## Example Usage in Scripts

### PowerShell
```powershell
# Toggle and check result
.\ThemeToggle.exe /exitcode
switch ($LASTEXITCODE) {
    0 { Write-Host "No change needed" }
    1 { Write-Host "Switched to Light mode" }
    2 { Write-Host "Switched to Dark mode" }
}
```

### Batch Script
```batch
@echo off
ThemeToggle.exe /exitcode
if %ERRORLEVEL% EQU 1 echo Switched to Light mode
if %ERRORLEVEL% EQU 2 echo Switched to Dark mode
```

### Scheduled Task
```batch
REM Toggle theme at sunrise/sunset
ThemeToggle.exe /light /quiet
```

## Building from Source

### Prerequisites
- Visual Studio 2019 or later (MSVC)
- Windows SDK

### Quick Build
```batch
build.bat
```

This process includes:
1. Compiling resources (e.g., embedded icons).
2. Compiling C++ source files.
3. Linking with manifest and icon.
4. Copying deployment-ready files into `deploy\ThemeToggle`.
5. Generating `ThemeToggle.exe` as a standalone executable (also copied into the deployment folder).

After a successful build, the `deploy\ThemeToggle` folder (git-ignored so it stays local) contains everything needed for distribution:
- `ThemeToggle.exe`
- PowerShell launcher (`ThemeToggle.ps1`)
- Setup helpers (`setup.bat`, `uninstall.bat`)
- `Resources\ThemeToggle.ico` for shortcuts or shell customization.

To generate a zip file for releases run:
```powershell
.\scripts\package-release.ps1 [-VersionTag v1.2.3] [-Rebuild]
```
This creates `deploy\ThemeToggle-<tag>.zip` from the latest build artifacts (and optionally runs `build.bat` first when `-Rebuild` is passed).
> Tip: only use `-Rebuild` from a Visual Studio Developer Command Prompt so `rc.exe`/`cl.exe` are on the PATH.

### Manual Build
```batch
# 1. Compile resources
rc ThemeToggle.rc

# 2. Compile and link
cl /EHsc /std:c++17 /W4 /O2 /MT main.cpp ThemeToggle.res /Fe:ThemeToggle.exe user32.lib advapi32.lib
```

### Icon Attribution
The embedded icon (`Resources\ThemeToggle.ico`) visually represents the theme switching functionality.

The executable is built in Release mode with:
- `/O2` - Optimizations for speed
- `/MT` - Static runtime linking
- `/DNDEBUG` - Release configuration
- Embedded icon and manifest
- Approximate size: ~220 KB

## Technical Details

### Key Improvements

1. Early exit for no-op cases to avoid unnecessary operations.
2. Clear registry access methods for reading and writing.
3. Cached console handle to reduce redundant system calls.
4. Detection of redirected output for safe automation.
5. Dual broadcast mechanism for immediate UI updates.
6. Asynchronous broadcasts with timeout for reliability.
7. RAII-based resource management for safety and cleanup.
8. Use of `std::wstring_view` for efficient string handling.
9. Embedded manifest for modern app compatibility.
10. Designed for integration into other applications.

### Registry Keys Modified

```
HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize
  - SystemUsesLightTheme (DWORD): 0 = Dark, 1 = Light
  - AppsUseLightTheme (DWORD): 0 = Dark, 1 = Light
```

### Broadcast Messages Sent

1. `WM_SETTINGCHANGE` with `ImmersiveColorSet` for theme updates.
2. `WM_SETTINGCHANGE` with `ColorizationColor` for taskbar and border updates.

### Compatibility

- Windows 10 (1809+)
- Windows 11 (all versions)
- Windows Server 2019+
- LTSC builds (creates missing registry keys)
- Supports automation and scripting environments

## Benchmarks

Tested on: Windows 11 23H2, Intel i7-12700K, NVMe SSD

| Scenario            | Previous | Current | Improvement |
|---------------------|----------|---------|-------------|
| No change (same theme) | 5-10ms  | 5-10ms  | Same        |
| Theme toggle        | ~5000ms  | ~110ms  | Significant |
| Repeated calls      | ~5000ms  | 5-10ms  | Significant |

## License

This project is released into the public domain. It can be used freely in any project.

## Contributing

Suggestions and improvements are welcome. The code aims to serve as a reference implementation for efficient Windows theme toggling.

## Credits

Developed with a focus on reliability, maintainability, and real-world use cases.
