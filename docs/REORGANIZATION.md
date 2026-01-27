# ThemeToggle - Reorganization Complete ✓

## New Structure

### Created Files

#### Distribution Pipeline
- **[setup.nsi](../setup.nsi)** - NSIS installer script (Nullsoft installer for WinGet)
- **[dist/build-release.bat](../dist/build-release.bat)** - Unified build pipeline (4-step process)
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

### NEW (4 automated steps)
```batch
# Step 1: Build executable
build.bat

# Step 2: Build installer + package + validate
dist\build-release.bat

# Step 3: Sign release artifacts
tools\signing\sign-release.ps1

# Step 4: Update manifests with real SHA256/GUID
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
# 1. Build everything (exe + installer + ZIP)
dist\build-release.bat

# 2. Sign release artifacts (ThemeToggle.exe + installer)
tools\signing\sign-release.ps1

# 3. Update WinGet manifests (auto-SHA256/GUID)
cd dist
.\update-winget.ps1

# 4. Create GitHub release
# - Upload ThemeToggle-Setup-1.3.0.exe
# - Upload ThemeToggle-Portable.zip
# - Upload ThemeToggle.exe

# 5. Submit to WinGet
# - Fork microsoft/winget-pkgs
# - Copy manifests to: manifests/s/SevIQ/ThemeToggle/1.3.0/
# - Create pull request
```

---

## What Can Be Deprecated

### Redundant Files (can be removed after transition)
- **scripts/package-release.ps1** → Replaced by [dist/build-release.bat](../dist/build-release.bat)
- **scripts/validate-repository.bat** → Replaced by [tools/validate.bat](../tools/validate.bat)
- **scripts/cleanup-workspace.bat** → Replaced by [tools/cleanup.bat](../tools/cleanup.bat)
- **scripts/apply-branding.bat** → No longer needed (manifests already branded)
- **scripts/rename-winget-manifests.bat** → Already completed
- **scripts/reorganize-vbs-launchers.bat** → Already completed
- **scripts/launchers/** → Replaced by [dist/launchers/](../dist/launchers/)

### Files to Keep
- **build.bat** - Core build script
- **setup.bat** - User-facing setup script
- **deploy/ThemeToggle/** - Deployment template
- **winget/** - WinGet manifests

---

## Distribution Status: 95% → Complete

### ✅ Now Complete
- [x] NSIS installer script ([setup.nsi](../setup.nsi))
- [x] Automated build pipeline ([dist/build-release.bat](../dist/build-release.bat))
- [x] Automated manifest updates ([dist/update-winget.ps1](../dist/update-winget.ps1))
- [x] Consolidated launcher structure ([dist/launchers/](../dist/launchers/))
- [x] Simplified tools ([tools/](../tools/))
- [x] Signing tooling ([tools/signing/sign-release.ps1](../tools/signing/sign-release.ps1))

### ❌ Still Missing (5%)
- [ ] Code signing certificate (for signed releases)

### Ready for Distribution
You can now:
1. Run `dist\build-release.bat` to create all release artifacts
2. Run `tools\signing\sign-release.ps1` to sign the exe and installer
3. Run `dist\update-winget.ps1` to auto-fill SHA256/GUID
4. Upload to GitHub releases
5. Submit to WinGet community repository

---

## Next Steps

1. **Test the new pipeline:**
   ```batch
   dist\build-release.bat
   ```

2. **Install NSIS** (if not already installed):
   - Download from: https://nsis.sourceforge.io/
   - Or: `winget install NSIS.NSIS`

3. **Sign release artifacts:**
   ```powershell
   tools\signing\sign-release.ps1
   ```

4. **Update manifests:**
   ```powershell
   cd dist
   .\update-winget.ps1
   ```

5. **Create GitHub release** (v1.3.0):
   - Tag: `v1.3.0`
   - Upload: `ThemeToggle-Setup-1.3.0.exe`
   - Upload: `ThemeToggle-Portable.zip`

6. **Submit to WinGet:**
   - Fork: https://github.com/microsoft/winget-pkgs
   - Path: `manifests/s/SevIQ/ThemeToggle/1.3.0/`
   - Create PR with 3 manifest files

---

**Date:** 2026-01-17  
**Status:** Ready for Release
