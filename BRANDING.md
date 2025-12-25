# SevIQ Brand Guidelines for ThemeToggle

Brand identity reference for ThemeToggle project.

---

## Brand Identity

**Publisher Name**: `SevIQ`
**Package Name**: `ThemeToggle`
**Full Package ID**: `SevIQ.ThemeToggle`

---

## WinGet Configuration

### Package Identifier
```yaml
PackageIdentifier: SevIQ.ThemeToggle
Publisher: SevIQ
PublisherUrl: https://github.com/espensev
PublisherSupportUrl: https://github.com/espensev/DarkToggle/issues
Author: Espen Severinsen
PackageName: ThemeToggle
PackageUrl: https://github.com/espensev/DarkToggle
Moniker: themetoggle
```

---

## File Naming Convention

### WinGet Manifests
- `SevIQ.ThemeToggle.yaml`
- `SevIQ.ThemeToggle.installer.yaml`
- `SevIQ.ThemeToggle.locale.en-US.yaml`

### Executable & Installer
- `ThemeToggle.exe`
- `ThemeToggle-Setup-1.2.0.exe`

---

## Brand Usage

### In Code/Registry
```cpp
#define APP_NAME L"ThemeToggle"
#define PUBLISHER L"SevIQ"
#define MUTEX_NAME L"Global\\SevIQ_ThemeToggle_SingleInstance"
```

### Registry Keys
```
HKEY_CURRENT_USER\Software\SevIQ\ThemeToggle
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
  Name: SevIQ.ThemeToggle
```

---

## URLs & Links

- **Repository**: https://github.com/espensev/DarkToggle
- **Issues**: https://github.com/espensev/DarkToggle/issues
- **WinGet Command**: `winget install SevIQ.ThemeToggle`

---

## Icon & Branding Assets

### Application Icon
- **Location**: `Resources\ThemeToggle.ico`
- **Sizes**: 16x16, 32x32, 48x48, 256x256
- **Format**: ICO with transparency

---

## Copyright & License

**Copyright**: © 2024 SevIQ
**License**: Unlicense (Public Domain) - https://unlicense.org/

---

**Last Updated**: 2024-12-24
