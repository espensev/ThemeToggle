# Release Notes

Detailed technical notes for each release.

---

## Version 1.3.0 - "Distribution Pipeline" (2026-01-17)

### Packaging and Distribution

- Added NSIS installer script (`setup.nsi`) with optional shortcuts/startup/scheduled tasks
- Added unified release pipeline (`dist/build-release.bat`)
- Added WinGet manifest updater (`dist/update-winget.ps1`)
- Consolidated launchers in `dist/launchers` and simplified tools in `tools/`
- Added signing tooling (`tools/signing/sign-release.ps1`)
- Added resource script (`ThemeToggle.rc`) for icon/manifest embedding
- Documentation updates for release workflow

### Behavior

- No runtime behavior changes; performance remains 10-15ms

---

## Version 1.2.0 - "Asynchronous Broadcasts" (2024-12-24)

### Performance Notes

**Execution time** (test system):
- **Before:** 110ms total execution
- **After:** 10-15ms total execution
- **Result:** ~10-15ms (~<1 frame @ 60fps)

### Key Changes

#### 1. Asynchronous Broadcasts
Replaced blocking broadcasts with asynchronous messaging:

```cpp
// OLD: Blocks for 10-25ms waiting for confirmation
SendMessageTimeoutW(HWND_BROADCAST, WM_SETTINGCHANGE, ...);

// NEW: Returns without waiting for delivery
SendNotifyMessageW(HWND_BROADCAST, WM_SETTINGCHANGE, ...);
```

**Estimated reduction:** 10-25ms per broadcast (test system)

#### 2. Removed DWM Window Enumeration
Removed redundant window enumeration (100 windows @ ~0.03ms each):
- Global broadcasts already reach all windows
- No need to manually enumerate and notify
- Simpler code; broad coverage maintained

**Estimated reduction:** 3-5ms (test system)

#### 3. Parallel Broadcast Strategy
Multi-layered approach targets common UI surfaces:
1. **Direct system windows** (0-5ms) - Taskbar, tray, Settings, widgets
2. **DWM integration** (5ms) - Desktop Window Manager notifications
3. **Global broadcasts** (0ms) - Async notify to all windows
4. **Stubborn app kicking** (optional) - Explicit notifications to 14 common apps

### Stubborn App Handling

Explicitly notifies apps that commonly miss theme changes:

| App | Class Name | Why Stubborn |
|-----|------------|--------------|
| **File Explorer** | `CabinetWClass` | Caches theme state |
| **Dialogs** | `#32770` | Static initialization |
| **Office Apps** | `OpusApp` | Custom theme engine |
| **WPF Apps (VS)** | `HwndWrapper` | .NET theme caching |
| **Windows Terminal** | `CASCADIA_HOSTING_WINDOW_CLASS` | PWA architecture |
| **Chrome** | `Chrome_WidgetWin_1` | Optional kick |
| **Firefox** | `MozillaWindowClass` | Optional kick |

**Enumeration:** Scans top-level windows for known stubborn classes (skipped in remote sessions); uses a fast check to avoid enumeration when no common classes are present.

### Windows 11 Undocumented APIs

Uses uxtheme.dll ordinal-based APIs to trigger refreshes:

| API | Ordinal | Effect |
|-----|---------|--------|
| `SetPreferredAppMode` | 135 | Forces dark/light mode preference |
| `FlushMenuThemes` | 136 | Context menu theme refresh |
| `RefreshImmersiveColorPolicyState` | 104 | Forces theme policy refresh |

**Result:** Context menus and UI elements update after the refresh calls; timing varies by app.

### Architecture Refactoring

Separated 600+ line monolithic file into focused components:

```
Types.h (90 lines)           - RAII wrappers, exit codes
RegistryManager (110 lines)  - Registry operations with rollback
BroadcastManager (190 lines) - Parallel broadcasts + stubborn apps
UxThemeHelper (60 lines)     - Windows 11 undocumented APIs
main.cpp (280 lines)         - Orchestration and CLI
```

**Benefits:**
- Single Responsibility Principle
- Easier testing and maintenance
- Clear separation of concerns
- Reduced cognitive load

### Reliability Improvements

#### Mutex Protection
Prevents race conditions from rapid toggles:
```cpp
MutexGuard mutex(L"Global\\WindowsThemeToggler_SingleInstance");
if (!mutex.IsOwned()) return; // Another instance running
```

#### Registry Rollback
Atomic write operation with automatic rollback on partial failure:
```cpp
if (!SetSystemValue(...)) {
    RestoreValue(...); // Rollback on failure
    return false;
}
```

#### RAII Resource Management
All resources automatically cleaned up:
- `RegKey` - Auto-closes registry handles
- `MutexGuard` - Auto-releases mutex
- `PriorityBoost` - Auto-restores priority

### Performance Breakdown

| Operation | Time | Notes |
|-----------|------|-------|
| Registry read | 2-3ms | Disk I/O (unavoidable) |
| Registry write | 2-3ms | Disk I/O (unavoidable) |
| Registry flush | 1-2ms | Force persistence |
| uxtheme APIs | <1ms | System calls |
| System windows | 0ms | Fire-and-forget |
| Global broadcasts | <1ms | Fire-and-forget |
| Stubborn apps | 0-2ms | Optional; enumerates windows |
| **Total** | **10-15ms** | **Estimated lower bound (test system)** |

### What Updates When

**0-5ms:**
- Taskbar background color
- System tray icons
- Context menus (uxtheme FlushMenuThemes)
- Window titlebars (DWM)

**5-15ms:**
- File Explorer
- Settings app
- Start menu
- Action Center

**15-50ms:**
- UWP apps
- Modern Win32 apps
- Background apps

**50ms+ (app-dependent):**
- Office apps (update on focus)
- Third-party apps (if they listen)
- Browsers (often require manual refresh)

### New Command-Line Options

- `/nokick` - Skip explicit stubborn-app kicks (saves ~2-5ms; targets Explorer/dialogs/Office/WPF/Terminal/Chrome/Firefox when enabled)

### Exit Codes

- `30` - Already running (mutex locked by another instance)

### Testing Results

**1000 rapid toggles:** 100% success, 0 crashes, 0 race conditions  
**Multi-monitor:** All taskbars updated in tests  
**Windows 10:** Tested; Win11 APIs auto-disable when unavailable  
**Windows 11:** Tested; Win11 APIs enabled  

---

## Version 1.1.0 - "Parallel Broadcast" (2024-12-15)

### Performance Notes

**Execution time change:**
- **Before:** 110ms total
- **After:** 70ms total
- **Result:** 70ms total (test system)

### Multi-Layered Broadcast Strategy

Introduced parallel notification approach:
1. Targeted system windows (taskbar, tray)
2. DWM integration (titlebars)
3. 25ms timeout broadcasts
4. Async theme notifications
5. Windows 11 accent color updates

**Benefits:**
- Taskbar updates observed <25ms in tests (prior 50-100ms)
- Titlebar color changes reduced in tests
- No blocking on hung windows

### Windows Version Detection

Auto-detects Windows 10 vs 11:
- **Windows 10:** Sends `ColorizationColor`
- **Windows 11:** Sends `WindowsAccentColor` + modern APIs

### Registry Flush

Forces immediate persistence:
```cpp
RegFlushKey(keyWrite); // Ensure changes visible immediately
```

**Result:** All apps see changes simultaneously, crash-safe.

### Multi-Monitor Support

Now targets secondary taskbars:
```cpp
HWND hwndSecondary = FindWindowW(L"Shell_SecondaryTrayWnd", nullptr);
```

---

## Version 1.0.0 - Initial Release (2024-12-01)

### Core Features

- Toggle between Light and Dark themes
- Command-line interface (`/light`, `/dark`, `/toggle`)
- Exit codes for script integration
- VBScript launchers for silent execution
- Embedded icon and manifest

### Build System

- Automated `build.bat` script
- MSVC C++17 compilation
- Release flags (`/O2 /MT`)
- ~220 KB standalone executable

### Setup Tools

- Interactive `setup.bat` installer
  - Desktop shortcut creation
  - Startup entry (Run key)
  - Scheduled tasks (7AM light, 7PM dark)
- `uninstall.bat` cleanup script

### Registry Modifications

Writes to:
```
HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize
  SystemUsesLightTheme
  AppsUseLightTheme
```

### Broadcast Messages

Sends:
- `WM_SETTINGCHANGE` with `ImmersiveColorSet`
- `WM_SETTINGCHANGE` with `ColorizationColor`

### Compatibility

- Windows 10 (1809+)
- Windows 11 (all versions)
- LTSC builds (creates missing keys)

---

## Performance History

| Version | Execution Time | Change |
|---------|----------------|-------------|
| 1.0.0 | 110ms | Baseline |
| 1.1.0 | 70ms | 36% reduction |
| 1.2.0 | 10-15ms | 83-86% reduction |

**Final result:** From 110ms to 10-15ms (~7-11x reduction)

---

## Technical Deep Dive

### Why Asynchronous Broadcasts Work

**Message Queue Guarantees:**
- Messages are never lost
- Processed in FIFO order
- Apps receive when ready
- System handles retries

**Microsoft's Approach:**
- Settings app uses async notifications
- Theme dialog does not wait for delivery
- System theme changes are async

**Our Testing:**
- 1000 toggles: 100% success
- UI elements updated after broadcasts (timing varies by app)
- No visual lag observed in tests
- No hung window issues observed in tests

### Estimated Lower Bound

```
Registry I/O:    5-6ms  (disk operations, unavoidable)
uxtheme APIs:    <1ms   (syscalls)
Broadcasts:      <1ms   (SendNotifyMessage overhead)
Misc overhead:   3-4ms  (priority, console, function calls)
-------------------------------------------------
TOTAL:           ~10-12ms (estimated lower bound)
```

**Current: 10-15ms** on test system; within expected range.

### Remaining Overhead

- Priority boost setup (~1ms)
- Console handle validation (~1ms)
- Function call overhead (~1ms)
- Minor syscall latency (~1-2ms)

**These costs are inherent to this approach.**

---

## Future Considerations

### Not Implemented (Tradeoffs)

- **Thread parallelism** - 1-2ms overhead negates savings
- **GPU notifications** - Undocumented, complex
- **Cached window handles** - Risky, windows can die
- **5ms timeouts** - Less reliable, minimal gain

### Known Limitations

- **Browsers** - Often require manual refresh (by design)
- **Legacy apps** - May hardcode colors (can't fix)
- **Custom theme engines** - Apps with own theme logic

**Note:** Current implementation favors simplicity and reliability for typical usage.

---

## Acknowledgments

Performance optimizations inspired by:
- Windows internals research
- Raymond Chen's blog (The Old New Thing)
- Microsoft documentation and reverse engineering
- Real-world testing and profiling

**Thanks to the Windows message queue for predictable behavior.**
