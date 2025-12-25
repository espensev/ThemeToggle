# ThemeToggle Repository Structure

Complete guide to the repository organization.

---

## Directory Structure

```
DarkToggle/
??? Resources/                  # Application assets
?   ??? ThemeToggle.ico         # Application icon
??? scripts/                    # Build and utility scripts
?   ??? launchers/              # VBS silent launchers
?   ??? cleanup-workspace.bat
?   ??? validate-repository.bat
?   ??? rename-winget-manifests.bat
??? winget/                     # WinGet package manifests
?   ??? SevIQ.ThemeToggle.yaml
?   ??? SevIQ.ThemeToggle.installer.yaml
?   ??? SevIQ.ThemeToggle.locale.en-US.yaml
??? Source Files (Root)         # C++ source code
?   ??? main.cpp
?   ??? Types.h
?   ??? RegistryManager.cpp/h
?   ??? BroadcastManager.cpp/h
?   ??? UxThemeHelper.cpp/h
??? build.bat                   # Main build script
??? ThemeToggle.rc              # Resource script
??? Documentation (Root)
    ??? README.md
    ??? AUTOMATION_GUIDE.md
    ??? ICON_EMBEDDING.md
    ??? QUICK_REFERENCE.md
```

---

## File Categories

### Build System
- `build.bat` - Compiles source to `ThemeToggle.exe`
- `ThemeToggle.rc` - Resource script (icon, manifest, version info)

### Source Code
- `main.cpp` - Entry point, CLI parsing
- `RegistryManager.*` - Registry operations
- `BroadcastManager.*` - Theme broadcasts
- `UxThemeHelper.*` - Windows 11 APIs

### Resources
- `Resources\ThemeToggle.ico` - Application icon (all sizes)

### Utility Scripts
- `scripts\cleanup-workspace.bat` - Removes legacy files
- `scripts\validate-repository.bat` - Pre-commit validation

### Documentation
- `README.md` - Main project documentation
- `AUTOMATION_GUIDE.md` - Automation setup guide
- `ICON_EMBEDDING.md` - Icon customization guide
- `QUICK_REFERENCE.md` - Command-line reference

---

## Git Workflow

### Tracked Files
- Source code (*.cpp, *.h)
- Build scripts (*.bat, *.ps1)
- Documentation (*.md)
- Resources (*.ico, *.manifest, *.rc)

### Ignored Files
See `.gitignore`:
- Build artifacts (`*.obj`, `*.res`, `*.aps`)
- Temporary files (`RC*`, `RD*`)
- IDE files (`.vs\`, `.vscode\`)

---

## Common Tasks

### Change Application Icon
1. Replace `Resources\ThemeToggle.ico`
2. Rebuild with `build.bat`
3. See `ICON_EMBEDDING.md` for details

### Clean Legacy Files
```cmd
scripts\cleanup-workspace.bat
```

### Validate Before Commit
```cmd
scripts\validate-repository.bat
