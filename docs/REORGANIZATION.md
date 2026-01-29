# ThemeToggle - Repository Reorganization (2026-01-17)

## New Structure

### Created Files

#### Distribution Pipeline
- **[setup.nsi](../setup.nsi)** - NSIS installer script (Nullsoft installer for WinGet)
- **[dist/build-release.bat](../dist/build-release.bat)** - Unified build pipeline (builds and signs if configured)
- **[dist/update-winget.ps1](../dist/update-winget.ps1)** - Auto-calculate SHA256/GUID for WinGet

#### Consolidated Launchers
- **[dist/launchers/ThemeToggle.vbs](../dist/launchers/ThemeToggle.vbs)** - Silent toggle
- **[dist/launchers/ThemeToggle-Light.vbs](../dist/launchers/ThemeToggle-Light.vbs)** - Force light mode
- **[dist/launchers/ThemeToggle-Dark.vbs](../dist/launchers/ThemeToggle-Dark.vbs)** - Force dark mode
- **[dist/launchers/ThemeToggle.ps1](../dist/launchers/ThemeToggle.ps1)** - PowerShell launcher

#### Tools
- **[tools/cleanup.bat](../tools/cleanup.bat)** - Remove build artifacts
- **[tools/validate.bat](../tools/validate.bat)** - Pre-commit validation
- **[tools/signing/sign-release.ps1](../tools/signing/sign-release.ps1)** - Sign release artifacts

---

## Simplified Build Chain

### OLD (7 manual steps)
```
1. build.bat
2. Copy to deploy/
3. scripts/package-release.ps1
4. scripts/validate-repository.bat
5. Update winget manifests manually
6. Create NSIS installer separately
7. Upload to GitHub
```

### NEW (3 automated steps)
```batch
# Step 1: Build executable
build.bat

# Step 2: Build installer + package + validate (auto-signs if configured)
dist\build-release.bat

# Step 3: Update manifests with real SHA256/GUID
dist\update-winget.ps1
```

---

## Usage Guide

### Development
```batch
# Build executable only
build.bat

# Clean workspace
tools\cleanup.bat

# Validate before commit
tools\validate.bat
```

### Release Process
```batch
# 1. Build everything (exe + installer + ZIP; auto-signs if configured)
dist\build-release.bat

# 2. Update WinGet manifests (auto-SHA256/GUID)
cd dist
.\update-winget.ps1

# 3. Create GitHub release (tag v<version>)
# - Upload ThemeToggle-Setup-<version>.exe
# - Upload ThemeToggle-Portable.zip
# - Upload ThemeToggle.exe

# 4. Submit to WinGet
# - Fork microsoft/winget-pkgs
# - Copy manifests to: manifests/s/SevIQ/ThemeToggle/<version>/
# - Create pull request
```

### Automation (GitHub Actions)
If you use the automated release/tag workflow, the release and WinGet submission are handled by CI after pushing a tag. See [docs/WINGET_SUBMISSION.md](WINGET_SUBMISSION.md) for setup details.

---

## Distribution Status: Nearly complete

### Complete
- [x] NSIS installer script ([setup.nsi](../setup.nsi))
- [x] Automated build pipeline ([dist/build-release.bat](../dist/build-release.bat))
- [x] Automated manifest updates ([dist/update-winget.ps1](../dist/update-winget.ps1))
- [x] Consolidated launcher structure ([dist/launchers/](../dist/launchers/))
- [x] Simplified tools ([tools/](../tools/))
- [x] Signing tooling ([tools/signing/sign-release.ps1](../tools/signing/sign-release.ps1))

### Optional
- [ ] Code signing certificate (set THEMETOGGLE_SIGN_PFX_PATH/THEMETOGGLE_SIGN_PFX_PASSWORD to auto-sign)

### Ready for Distribution
You can now:
1. Run `dist\build-release.bat` to create all release artifacts
2. Run `dist\update-winget.ps1` to auto-fill SHA256/GUID
3. Upload to GitHub releases
4. Submit to WinGet community repository

---

## Next Steps

1. **Test the new pipeline:**
   ```batch
   dist\build-release.bat
   ```

2. **Install NSIS** (if not already installed):
   - Download from: https://nsis.sourceforge.io/
   - Or: `winget install NSIS.NSIS`

3. **Update manifests:**
   ```powershell
   cd dist
   .\update-winget.ps1
   ```

4. **Create GitHub release** (v<version>):
   - Tag: `v<version>`
   - Upload: `ThemeToggle-Setup-<version>.exe`
   - Upload: `ThemeToggle-Portable.zip`

5. **Submit to WinGet:**
   - Fork: https://github.com/microsoft/winget-pkgs
   - Path: `manifests/s/SevIQ/ThemeToggle/<version>/`
   - Create PR with 3 manifest files

---

**Date:** 2026-01-17  
**Status:** Ready for Release
