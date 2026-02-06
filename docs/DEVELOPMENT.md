# Development

This page covers local build, tooling, and benchmarking.

## Quickstart

1) Build the executable:
```cmd
build.bat
```

2) Run a quick help check:
```cmd
ThemeToggle.exe /?
```

## Requirements

- Windows 10/11
- Visual Studio Build Tools 2019+ (MSVC), Windows SDK
- NSIS (only required for the installer / `dist\build-release.bat`)

Optional:
- GitHub CLI (`gh`) if you trigger workflows locally

## Build (Local)

Build the standalone executable:
```cmd
build.bat
```

Output: `ThemeToggle.exe` in the repo root.

## Build (Release Artifacts)

Build exe + installer + portable ZIP (auto-signs if configured):
```cmd
dist\build-release.bat
```

Outputs:
- `ThemeToggle.exe`
- `ThemeToggle-Setup-<version>.exe` (if NSIS is available)
- `ThemeToggle-Portable.zip`

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

## Troubleshooting

### Visual Studio Build Tools not found
`build.bat` looks for `vswhere.exe` and common VS install paths. Fix by:
- Installing Visual Studio Build Tools 2019+, or
- Running from a Developer Command Prompt, or
- Installing VS where it can be discovered.

### NSIS not found
`dist\build-release.bat` skips the installer if `makensis` is not on PATH. Fix by:
- Installing NSIS, or
- Adding `C:\Program Files (x86)\NSIS` to PATH.
