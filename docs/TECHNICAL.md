# Technical Notes

## Performance

Typical execution: 10-15 ms (test system). Broadcasts are asynchronous; the optional stubborn-app kick can be disabled via `/kick=none`.

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

## Repository layout

| Path | Contents |
|------|----------|
| `src/main.cpp` | Entry point and CLI |
| `src/RegistryManager.cpp` | Registry operations with rollback |
| `src/BroadcastManager.cpp` | Async theme notifications |
| `src/UxThemeHelper.cpp` | Windows 11 uxtheme refresh helpers |
| `include/` | Headers |
| `Resources/` | Icon and manifest |
| `dist/launchers/` | PowerShell and VBScript launchers bundled in the portable ZIP |
| `winget/` | Local WinGet manifests for `SevIQ.ThemeToggle` |
| `tools/` | Validation, benchmarking, versioning, signing, and release scripts |
| `docs/` | User, development, release, and technical documentation |
| `setup.nsi` | Optional NSIS installer definition for manual release builds |

## Windows 11 specifics

uxtheme ordinal-based APIs (`SetPreferredAppMode`, `FlushMenuThemes`, `RefreshImmersiveColorPolicyState`) are called when available. On older builds they are no-ops.

## Stubborn-app handling

Some applications cache theme state. The kick step explicitly notifies common offenders (Explorer, dialogs, Office/WPF apps, Terminal, Chrome, Firefox). Disable with `/kick=none` for the fastest path.
