# Development

This page covers local build, tooling, and benchmarking.

## Requirements

- Windows 10/11
- Visual Studio 2019+ (MSVC), Windows SDK
- NSIS (only required for the installer)

## Build

Build the standalone executable:
```cmd
build.bat
```

Build full release artifacts (exe + installer + ZIP; auto-signs if configured):
```cmd
dist\build-release.bat
```

## Tooling

Clean build artifacts:
```cmd
tools\cleanup.bat
```

Pre-commit validation:
```cmd
tools\validate.bat
```

Update WinGet manifests (SHA256/GUID):
```powershell
dist\update-winget.ps1
```

## Benchmarking

```powershell
.\tools\bench.ps1 -Iterations 1000
```

Optional knobs:
- `-SettleMs` wait between toggles (default 250ms)
- `-BatchSize` / `-BatchPauseMs` reduce system stress
- `-JitterMs` add variance

Export for another machine:
```powershell
.\tools\export-bench.ps1 -Zip
```
