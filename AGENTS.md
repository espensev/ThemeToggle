# Repository Guidelines

## Project Structure & Module Organization

- `src/` C++ implementation (`main.cpp`, `RegistryManager.cpp`, `BroadcastManager.cpp`, `UxThemeHelper.cpp`)
- `include/` headers and shared types (`Types.h`, `StringUtils.h`, `*.h`)
- `Resources/` app icon and resources referenced by `ThemeToggle.rc`
- `dist/launchers/` VBS and PowerShell launchers bundled with portable distribution
- `tools/` dev utilities (validation, benchmarking, signing helpers)
- `tools/release/` release pipeline (`build-and-publish.ps1`)
- `winget/` WinGet manifests
- `docs/` contributor docs (`docs/DEVELOPMENT.md`, `docs/TECHNICAL.md`, `docs/RELEASE.md`)

There is no dedicated `tests/` tree at the moment; validation is primarily build + smoke-run.

## Build, Test, and Development Commands

```cmd
build.bat
```
Builds `ThemeToggle.exe` (MSVC x64, Release, static `/MT`).

```cmd
ThemeToggle.exe /?
tools\validate.bat
.\tools\release\build-and-publish.ps1
```
- `ThemeToggle.exe /?`: quick smoke-run (also used in CI).
- `tools\validate.bat`: pre-commit repo sanity checks (manifests, dist layout, stray artifacts).
- `tools\release\build-and-publish.ps1`: full release pipeline — builds exe, NSIS installer, portable ZIP, updates WinGet manifests.

Optional performance check:
```powershell
.\tools\bench.ps1 -Iterations 1000
```

## Coding Style & Naming Conventions

- C++17 + Win32 APIs; keep changes warning-clean at `/W4`.
- Indentation: 4 spaces. Follow existing brace/`else` style within the edited file.
- Naming: `PascalCase` types/functions, `UPPER_SNAKE` constants, `member_` trailing underscore for members, `g_` prefix for file-scope globals.

## Testing Guidelines

- Smoke test behavior with deterministic flags:
  - `ThemeToggle.exe /toggle /passthru /exitcode`
  - `ThemeToggle.exe /light` and `/dark`
- Don’t commit generated artifacts (`*.obj`, `ThemeToggle.exe`, `ThemeToggle-Setup-*.exe`, `deploy/` are ignored by `.gitignore`).
- If you touch broadcast/Win11 refresh logic, run `tools\bench.ps1` to catch regressions.

## Commit & Pull Request Guidelines

- Commit messages in history use short, imperative summaries (examples: "Fix ...", "Update ...", "Refactor ..."). Keep the first line concise.
- PRs should include:
  - what/why (especially registry or broadcast behavior changes)
  - how you tested (commands + Windows version if relevant)
  - screenshots only when the installer/launchers change

## Security & Configuration Tips

- Theme state changes are done via HKCU registry writes (see `docs/TECHNICAL.md`); avoid expanding scope beyond that without a strong reason.
- Release signing is optional and driven by environment variables (see `tools/release/build-and-publish.ps1` and `tools/signing/`).

