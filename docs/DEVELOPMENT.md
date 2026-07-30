# Development

## Requirements

- Windows 10/11
- Visual Studio Build Tools 2019+ (MSVC), Windows SDK
- NSIS (only for installer builds)
- PowerShell 7+ (`pwsh`) for `build.bat /sign` and `tools/release/build-and-publish.ps1`

## Quick build

```cmd
build.bat
```

Produces `ThemeToggle.exe` in the repo root.

Local signed build after compile (delegates to `tools/release/build-and-publish.ps1`):

```cmd
build.bat /sign
```

## Full release build

`tools/release/build-and-publish.ps1` handles the complete pipeline - exe, installer, portable ZIP, signing, and WinGet manifest updates.
Tagged releases must use the repository signing flow from [RELEASE.md](RELEASE.md): materialized release PFX plus pinned signer thumbprint verification in GitHub Actions.

```powershell
.\tools\release\build-and-publish.ps1                    # build + package
.\tools\release\build-and-publish.ps1 -Version 1.6.0    # bump version first
.\tools\release\build-and-publish.ps1 -NoSign -NoWinget  # local packaging only; never for tagged releases
.\tools\release\build-and-publish.ps1 -DryRun            # preview only
```

See [RELEASE.md](RELEASE.md) for the full release workflow.

## Tooling

| Script | Purpose |
|--------|---------|
| `build.bat` | Compile the executable (MSVC detection built in) |
| `tools\release\build-and-publish.ps1` | Full release pipeline |
| `tools\release\refresh-portable-package.ps1` | Repack portable ZIP + refresh WinGet SHA after post-build signing |
| `tools\bump-version.ps1` | Update version across all project files |
| `tools\validate.bat` | Pre-commit validation checks |
| `tools\validate-winget.ps1` | Strict WinGet manifest/version/URL validation |
| `tools\validate-release-workflow.ps1` | Enforce the canonical CI release + WinGet workflow |
| `tools\bench.ps1` | Performance benchmarking |
| `tools\export-bench.ps1` | Export benchmark results |

## Benchmarking

```powershell
.\tools\bench.ps1 -Iterations 1000
```

Options: `-SettleMs` (delay between toggles), `-BatchSize` / `-BatchPauseMs` (reduce system stress), `-JitterMs` (add variance).

Export for another machine:

```powershell
.\tools\export-bench.ps1 -Zip
```

## Troubleshooting

**Visual Studio Build Tools not found** — `build.bat` uses `vswhere.exe` and common VS install paths. Install Visual Studio Build Tools 2019+ or run from a Developer Command Prompt.

**NSIS not found** - `tools/release/build-and-publish.ps1` skips the installer when `makensis` is not on PATH. Install NSIS or add `C:\Program Files (x86)\NSIS` to PATH.
