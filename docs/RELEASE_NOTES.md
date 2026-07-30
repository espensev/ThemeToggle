# Release Notes

Newest entry at the top.

---

## Unreleased

- No unreleased notes yet.

---

## 1.6.0 — Honest Broadcasts (2026-07-30)

- Removed per-window shell pokes and the Word/Terminal kick entries: Windows rejects targeted asynchronous sends of pointer-carrying messages (`ERROR_MESSAGE_SYNC_ONLY`), so these had failed on every run since 1.2.0. The global `HWND_BROADCAST` sequence — which does work and reaches all top-level windows, including secondary-monitor taskbars — is the authoritative signal.
- Exit code 20 (`BroadcastFailed`) was chronically returned on every successful theme change because those doomed sends set the failure flag. It now reflects only the global broadcast sequence; kicks are best-effort and never fail the toggle.
- Stubborn-app kick list slimmed to entries that verifiably deliver: File Explorer and common dialogs (`/kick=core`), plus Chromium/Electron-family and Firefox windows (`/kick=all`). `StubbornAppsKicked` now counts actual deliveries. New entries require a reproduced miss and a pointer-free message.
- Kick now runs before the global broadcast: enumerating windows afterwards costs ~10x more while every window repaints (26-30 ms → 5-11 ms measured).
- `/passthru` prints per-stage timings (`Timing*Ms`) for future performance work.
- Removed the dead fast-target/enum-cache path in `BroadcastManager`.
- Performance docs updated to measured numbers: ~25-45 ms in-process on a busy desktop, dominated by the global broadcast fan-out; the old 10-15 ms claim predated measurement.
- Release pipeline: optional Microsoft Artifact Signing pilot lane (OIDC, additive, off by default), tagged releases require the pinned signing thumbprint, and the WinGet validator pins `ManifestVersion`/`ManifestType`.

---

## 1.5.7 — Release Recovery & WinGet Publishing (2026-03-15)

- Documented the March 15, 2026 `v1.5.7` release recovery: importing the self-signed release certificate into `CurrentUser\Root` hung GitHub's Windows runner, so CI verification now relies on signer thumbprint matching and explicitly allows the expected untrusted-root `UnknownError` case instead of mutating the trust store.
- Fixed the WinGet publish workflow to validate and submit the exact asset URLs declared by the restored manifest snapshot instead of assuming a `ThemeToggle-Setup-<version>.exe` release asset still exists.
- Documented the March 15, 2026 `v1.5.7` WinGet failure: the publish job was still hard-coded for the old installer filename even though the signed release had moved to `ThemeToggle.exe` plus `ThemeToggle-Portable.zip`.

---

## 1.5.6 — Signed Release & Wrapper Packaging (2026-03-15)

- GitHub release builds now require signing secrets and verify Authenticode signatures before publishing artifacts.
- Portable ZIPs now include the `dist\launchers` helper scripts again.
- Wrapper scripts now resolve `ThemeToggle.exe` correctly from both the repo layout and the portable ZIP layout.

---

## 1.5.5 — Silent Launch & Release Pipeline (2026-03-13)

- Removed GUI dialogs from normal execution. Theme changes now stay silent even when launched without a console.
- `/notify` is retained as a backward-compatible no-op so older shortcuts do not break.
- Installer shortcuts, startup integration, and setup flows now launch `ThemeToggle.exe` directly instead of VBS wrappers.
- The release workflow now hands the exact CI-generated WinGet manifests to the publish workflow, avoiding installer hash drift between release and WinGet submission.
- Release tooling is consolidated under `tools/release/build-and-publish.ps1` and `tools/validate-winget.ps1`.

---

## 1.5.4 — Documentation & Tooling (2026-02-08)

- Preserve stdout/stderr redirection and pipes (no longer forces `CONOUT$` when output is redirected).
- `/quiet` and `/exitcode` no longer show GUI error dialogs when launched without a console.
- Relocated `test_vcvars.bat` to `tools/`.
- Added `tools/inventory.ps1` for repository file inventory generation.
- PowerShell launcher supports `-Wait` and no longer shadows PowerShell's automatic `$args`.
- NSIS startup entry runs `wscript.exe` explicitly.

---

## 1.3.0 — Distribution Pipeline (2026-01-17)

- NSIS installer (`setup.nsi`) with optional shortcuts, startup entry, and scheduled tasks.
- Unified release pipeline and WinGet manifest updater.
- Signing tooling and resource script (`ThemeToggle.rc`) for icon/manifest embedding.
- No runtime behavior changes.

---

## 1.2.0 — Asynchronous Broadcasts (2024-12-24)

Execution time reduced from 110 ms to 10-15 ms.

### Changes

- Replaced blocking broadcasts (`SendMessageTimeoutW`) with async (`SendNotifyMessageW`), saving 10-25 ms per broadcast.
- Removed redundant DWM window enumeration (~3-5 ms).
- Multi-layered broadcast strategy: direct system windows, DWM integration, global broadcasts, optional stubborn-app kick.
- Architecture refactored from a single 600+ line file into focused components (`RegistryManager`, `BroadcastManager`, `UxThemeHelper`, `main`).
- Mutex protection prevents race conditions from rapid toggles.
- Registry rollback on partial write failure.
- RAII wrappers for registry handles, mutexes, and priority boost.

### Stubborn-app kick

Explicitly notifies apps that commonly miss theme changes: Explorer, common dialogs, Word, Windows Terminal, Chromium/Electron-family, and Firefox windows. Controlled via `/kick=...`.

### Windows 11 APIs

uxtheme ordinal calls (`SetPreferredAppMode` #135, `FlushMenuThemes` #136, `RefreshImmersiveColorPolicyState` #104) force context menu and UI element refresh.

### New CLI option

- `/nokick` — skip stubborn-app notifications.

---

## 1.1.0 — Parallel Broadcast (2024-12-15)

Execution time reduced from 110 ms to 70 ms.

- Parallel broadcast strategy: targeted system windows, DWM integration, timeout broadcasts, async notifications, Windows 11 accent color updates.
- Windows version detection (Win 10 sends `ColorizationColor`; Win 11 sends `WindowsAccentColor` + modern APIs).
- Registry flush for immediate persistence.
- Multi-monitor support (secondary taskbars).

---

## 1.0.0 — Initial Release (2024-12-01)

- Light/Dark toggle via `/light`, `/dark`, `/toggle`.
- Exit codes for script integration.
- VBScript launchers for silent execution.
- Embedded icon and manifest.
- `build.bat` with MSVC C++17 compilation, `/O2 /MT`, ~220 KB standalone executable.
- `setup.bat` installer (desktop shortcut, startup entry, scheduled tasks) and `uninstall.bat`.

---

## Performance history

| Version | Time | Reduction |
|---------|------|-----------|
| 1.0.0 | 110 ms | — |
| 1.1.0 | 70 ms | 36% |
| 1.2.0 | 10-15 ms | 83-86% |
