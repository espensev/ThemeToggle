# Technical Notes

## Performance

Measured on the test system (Windows 11, busy desktop with ~30 top-level app windows), a full toggle spends roughly: <1 ms on registry read/write/flush, 3-11 ms in the uxtheme refresh, 1-2 ms on DWM, 16-18 ms in the global broadcast fan-out, and 5-11 ms kicking stubborn apps — about 25-45 ms in-process, plus ~10 ms of process start. Lighter desktops complete faster. Broadcasts are asynchronous; the stubborn-app kick runs before the global broadcast (enumerating windows after it costs ~10x more, since every window is then busy repainting) and can be disabled via `/kick=none`. `/passthru` prints per-stage timings (`Timing*Ms`).

## Compatibility

- Static build (`/MT`), no DLL dependencies
- Windows 10 (1809+), Windows 11, Server 2019+

## Execution flow

1. Acquire single-instance mutex
2. Read current theme from registry
3. Write new theme values
4. Flush registry (unless `/noflush`)
5. Broadcast theme change (async)
6. Optional stubborn-app kick (`/kick=...`)

## CLI reference

| Option | Description |
|--------|-------------|
| `/toggle` | Toggle theme (default) |
| `/light`, `/dark` | Force a specific theme |
| `/quiet` | Suppress console output |
| `/exitcode` | Return status as exit code |
| `/kick=all\|core\|none` | Control stubborn-app notifications |
| `/noflush` | Skip registry flush |
| `/?`, `/help` | Show usage |

All options accept `-` or `--` prefixes.
GUI launches stay silent by default. `/notify` is still accepted for backward compatibility, but it no longer shows dialogs.

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | No change needed |
| 1 | Changed to Light |
| 2 | Changed to Dark |
| 11 | Registry write failed |
| 12 | Registry read failed |
| 20 | Broadcast failed (registry updated) |
| 30 | Already running |
| 99 | Unknown error |

## Registry keys

```
HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize
  SystemUsesLightTheme  (DWORD)  0 = Dark, 1 = Light
  AppsUseLightTheme     (DWORD)  0 = Dark, 1 = Light
```

## Source layout

| Path | Contents |
|------|----------|
| `src/main.cpp` | Entry point and CLI |
| `src/RegistryManager.cpp` | Registry operations with rollback |
| `src/BroadcastManager.cpp` | Async theme notifications |
| `src/UxThemeHelper.cpp` | Windows 11 uxtheme refresh helpers |
| `include/` | Headers |
| `Resources/` | Icon and manifest |

## Windows 11 specifics

uxtheme ordinal-based APIs (`SetPreferredAppMode`, `FlushMenuThemes`, `RefreshImmersiveColorPolicyState`) are called when available. On older builds they are no-ops.

## Stubborn-app handling

Most applications react to the standard broadcast sequence (global `WM_SETTINGCHANGE` "ImmersiveColorSet" + `WM_THEMECHANGED`, DWM attribute, uxtheme refresh). The kick step is a best-effort extra nudge for windows known to miss or defer that sequence: File Explorer and common dialogs (`/kick=core`), plus Chromium/Electron-family and Firefox windows (`/kick=all`, the default). The list is intentionally small and empirical — entries are added only for reproduced misses, not to catalogue every app that caches theme state. Disable with `/kick=none` for the fastest path.

Kicks are best-effort and fully asynchronous: a miss (for example an elevated window blocked by UIPI) never affects the exit code. Exit code 20 (`BroadcastFailed`) reflects only the global `HWND_BROADCAST` sequence. Kick messages must be pointer-free — Windows rejects targeted asynchronous sends of pointer-carrying messages such as a `WM_SETTINGCHANGE` string (`ERROR_MESSAGE_SYNC_ONLY`), which is why the theme-change signal itself travels only via the global broadcast.
