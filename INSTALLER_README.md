# Installer Creation Guide

This guide explains how to build the NSIS installer for ThemeToggle.

---

## Prerequisites

### 1. Build ThemeToggle.exe First
```cmd
build.bat
```
This creates `ThemeToggle.exe` (~220 KB).

### 2. Install NSIS (Nullsoft Scriptable Install System)

**Download:** https://nsis.sourceforge.io/Download

**Installation:**
- Run the NSIS installer
- Default installation path: `C:\Program Files (x86)\NSIS\`
- Add to PATH (optional but recommended)

**Verify installation:**
```cmd
"C:\Program Files (x86)\NSIS\makensis.exe" /VERSION
```
Should output: `v3.x.x`

---

## Building the Installer

### Quick Method (Recommended)
```cmd
build-installer.bat
```

This script:
1. ? Checks if `ThemeToggle.exe` exists
2. ? Locates NSIS installation
3. ? Verifies all required files are present
4. ? Builds the installer (`ThemeToggle-Setup-1.2.0.exe`)

### Manual Method
```cmd
"C:\Program Files (x86)\NSIS\makensis.exe" /V3 installer.nsi
```

---

## Required Files

The following files must be present in the workspace:

### Core Files
- ? `ThemeToggle.exe` - Main executable
- ? `themetoggle_dark.ico` - Icon

### Launchers
- ? `ThemeToggle.vbs` - Silent toggle
- ? `ThemeToggle-Light.vbs` - Force light
- ? `ThemeToggle-Dark.vbs` - Force dark
- ? `ThemeToggle.ps1` - PowerShell version

### Setup Tools
- ? `setup.bat` - Interactive installer
- ? `uninstall.bat` - Cleanup script

### Documentation
- ? `README.md` - User guide
- ? `CHANGELOG.md` - Version history
- ? `LICENSE.txt` - Public domain license
- ? `docs/RELEASE_NOTES.md` - Technical notes

### Installer Script
- ? `installer.nsi` - NSIS installer script

---

## Output

**Generated file:** `ThemeToggle-Setup-1.2.0.exe` (~500 KB)

This installer includes:
- Core files installation to `%LOCALAPPDATA%\Programs\ThemeToggle`
- Start Menu shortcuts
- Desktop shortcut (optional)
- Startup entry (optional)
- Scheduled tasks (optional)
- Uninstaller with full cleanup

---

## Installer Features

### Installation Options

Users can choose:
1. **Core Files** (required) - Executable and launchers
2. **Start Menu Shortcuts** - Quick access from Start Menu
3. **Desktop Shortcut** - One-click theme toggle (with hotkey support)
4. **Add to Startup** - Auto-launch on Windows startup
5. **Scheduled Tasks** - 7AM light mode, 7PM dark mode

### Installation Location

**Default:** `%LOCALAPPDATA%\Programs\ThemeToggle`
- No admin rights required
- User-specific installation
- Clean uninstall

**Alternative:** Users can change installation path during setup

### Start Menu Structure

```
Start Menu ? ThemeToggle
??? Toggle Theme.lnk
??? Toggle Theme (Silent).lnk
??? Force Light Mode.lnk
??? Force Dark Mode.lnk
??? Uninstall.lnk
```

### Uninstaller

The uninstaller removes:
- ? All installed files
- ? Start Menu shortcuts
- ? Desktop shortcut
- ? Startup entry (if added)
- ? Scheduled tasks (if added)
- ? Registry entries
- ? Installation directory (if empty)

**Location:** `Apps & Features` or `Add/Remove Programs`

---

## Customization

### Modify Version Number

Edit `installer.nsi`:
```nsi
!define VERSIONMAJOR 1
!define VERSIONMINOR 2
!define VERSIONBUILD 0
```

### Change Installation Path

Edit `installer.nsi`:
```nsi
InstallDir "$LOCALAPPDATA\Programs\${APPNAME}"
```

**Options:**
- `$LOCALAPPDATA\Programs\${APPNAME}` - User directory (no admin)
- `$PROGRAMFILES\${APPNAME}` - Program Files (requires admin)
- `$DESKTOP\${APPNAME}` - Desktop (not recommended)

### Add Custom Components

Edit `installer.nsi`, add new section:
```nsi
Section "My Custom Feature" SecCustom
    ; Your installation commands here
SectionEnd
```

---

## Testing the Installer

### 1. Install
```cmd
ThemeToggle-Setup-1.2.0.exe
```

### 2. Verify Installation
- Check files exist in installation directory
- Verify Start Menu shortcuts work
- Test desktop shortcut (if installed)
- Confirm scheduled tasks (if installed)

### 3. Test Functionality
```cmd
cd %LOCALAPPDATA%\Programs\ThemeToggle
ThemeToggle.exe
```

### 4. Uninstall
- Go to `Apps & Features`
- Search "ThemeToggle"
- Click `Uninstall`

### 5. Verify Cleanup
- Installation directory should be removed
- No Start Menu shortcuts
- No desktop shortcut
- No startup entry
- No scheduled tasks

---

## Silent Installation

For automated deployment:

### Silent Install
```cmd
ThemeToggle-Setup-1.2.0.exe /S /D=C:\Path\To\Install
```

### Silent Uninstall
```cmd
"%LOCALAPPDATA%\Programs\ThemeToggle\Uninstall.exe" /S
```

---

## Troubleshooting

### "NSIS not found"
**Solution:** Install NSIS from https://nsis.sourceforge.io/Download

### "ThemeToggle.exe not found"
**Solution:** Run `build.bat` first to compile the executable

### "Missing required files"
**Solution:** Ensure all VBS, BAT, MD, and ICO files are present

### Installer fails to build
**Solution:** Check NSIS output for specific errors. Common issues:
- File paths with spaces (use quotes)
- Missing files referenced in script
- Syntax errors in `installer.nsi`

### "Can't write installer to file"
**Solution:** Close any running instances of the installer

---

## Distribution Checklist

Before distributing the installer:

- [ ] Build latest `ThemeToggle.exe` with `build.bat`
- [ ] Update version number in `installer.nsi`
- [ ] Build installer with `build-installer.bat`
- [ ] Test installer on clean Windows installation
- [ ] Verify all features work (shortcuts, scheduled tasks)
- [ ] Test uninstaller completely removes all files
- [ ] Scan with antivirus (some flag NSIS installers)
- [ ] Upload to GitHub Releases
- [ ] Update release notes with installer download link

---

## NSIS Resources

- **Website:** https://nsis.sourceforge.io/
- **Documentation:** https://nsis.sourceforge.io/Docs/
- **Examples:** https://nsis.sourceforge.io/Examples/
- **Forum:** https://forums.winamp.com/forumdisplay.php?f=65

---

## Advanced: Code Signing

For production releases, consider code signing the installer:

### Why Sign?
- ? Prevents SmartScreen warnings
- ? Proves authenticity
- ? Increases user trust

### How to Sign
1. Purchase code signing certificate (~$100-400/year)
2. Use `signtool.exe` (Windows SDK):
```cmd
signtool sign /f certificate.pfx /p password /t http://timestamp.digicert.com ThemeToggle-Setup-1.2.0.exe
```

**Timestamp servers:**
- DigiCert: `http://timestamp.digicert.com`
- Sectigo: `http://timestamp.sectigo.com`

---

**Ready to build your installer!** ??
