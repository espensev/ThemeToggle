# Repository Structure

```
DarkToggle/
??? Resources/
?   ??? ThemeToggle.ico         # Application icon (all sizes)
??? scripts/
?   ??? launchers/              # VBS silent launchers
?   ??? *.bat                   # Build and utility scripts
??? winget/                     # WinGet package manifests
?   ??? SevIQ.ThemeToggle.yaml
?   ??? SevIQ.ThemeToggle.installer.yaml
?   ??? SevIQ.ThemeToggle.locale.en-US.yaml
??? main.cpp                    # Entry point, CLI parsing
??? RegistryManager.*           # Registry operations
??? BroadcastManager.*          # Theme change notifications
??? UxThemeHelper.*             # Windows 11 API integration
??? Types.h                     # RAII wrappers, utilities
??? ThemeToggle.rc              # Resource script (icon, manifest)
??? ThemeToggle.manifest        # Windows manifest
??? build.bat                   # Build script
??? README.md                   # Documentation
```

## Key Files

### Build System
- **`build.bat`** - Compiles source to `ThemeToggle.exe`
- **`ThemeToggle.rc`** - Embeds icon, manifest, version info
- **`ThemeToggle.manifest`** - DPI awareness, Windows compatibility

### Source Code
- **`main.cpp`** - Entry point and CLI parsing
- **`RegistryManager.*`** - Safe registry operations with rollback
- **`BroadcastManager.*`** - Theme change notifications
- **`UxThemeHelper.*`** - Windows 11 undocumented APIs
- **`Types.h`** - RAII wrappers (RegKey, MutexGuard, PriorityBoost)

### Resources
- **`Resources\ThemeToggle.ico`** - Application icon (16x16, 32x32, 48x48, 256x256)

## Common Tasks

### Change Application Icon
1. Replace `Resources\ThemeToggle.ico`
2. Run `build.bat`

### Clean Build
```cmd
build.bat
```

### Git Workflow
**.gitignore** excludes:
- Build artifacts (`*.obj`, `*.res`, `*.aps`)
- Temporary files (`RC*`, `RD*`)
- IDE files (`.vs\`, `.vscode\`)
