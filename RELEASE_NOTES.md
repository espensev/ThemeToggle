# Release Notes

## Build Configuration
- **Version:** 1.0.0
- **Compiler:** MSVC 19.44 (Visual Studio 2019+)
- **C++ Standard:** C++17
- **Optimizations:** `/O2` (speed)
- **Runtime:** `/MT` (static, no DLL dependencies)
- **Size:** ~220 KB
- **Architecture:** x86 (32-bit, compatible with x64 Windows)

## Build from Source

```cmd
build.bat
```

**Manual build:**
```cmd
rc ThemeToggle.rc
cl /EHsc /std:c++17 /W4 /O2 /MT /DNDEBUG /DUNICODE /D_UNICODE ^
   main.cpp RegistryManager.cpp BroadcastManager.cpp UxThemeHelper.cpp ^
   ThemeToggle.res user32.lib advapi32.lib dwmapi.lib shell32.lib ^
   /Fe:ThemeToggle.exe /link /SUBSYSTEM:WINDOWS /ENTRY:wWinMainCRTStartup
```

## Performance
- **No change needed:** 5-10ms (early exit)
- **Full theme toggle:** ~110ms (registry + broadcast)

## Embedded Resources
- Icon: `Resources\ThemeToggle.ico`
- Manifest: DPI awareness, Windows 10/11 compatibility
- Version information: File properties metadata

## Distribution Files
- `ThemeToggle.exe` - Main executable
- `ThemeToggle.ps1` - PowerShell alternative
- `setup.bat` - Configuration wizard
- `build.bat` - Build script

## Icon Usage
Application icon (`Resources\ThemeToggle.ico`) appears in:
- Windows Explorer
- Taskbar
- Alt+Tab menu
- Desktop shortcuts
- Task Manager
