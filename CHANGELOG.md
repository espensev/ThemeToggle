# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.2.0] - 2024-12-24

### Performance
- **83% faster execution** - Reduced from 110ms to 10-15ms
- Eliminated all blocking operations (fire-and-forget broadcasts)
- Removed DWM window enumeration (3-5ms savings)
- Removed broadcast timeouts (10-25ms savings)
- Now sub-16ms (imperceptible, <1 video frame @ 60fps)

### Added
- Stubborn app detection and kicking (~14 common apps)
- Windows 11 undocumented API integration (ordinals 104, 135, 136)
- Multi-monitor taskbar support (secondary taskbars)
- Windows 11 widgets panel notifications
- Mutex-based single instance protection
- Priority boost for faster execution
- `/nokick` flag to skip stubborn app notifications

### Changed
- Refactored into modular components (RegistryManager, BroadcastManager, UxThemeHelper)
- Switched to fire-and-forget messaging (SendNotifyMessage)
- Improved error handling with typed exceptions
- RAII wrappers for all resources (zero leaks)

### Fixed
- Race conditions from concurrent toggles (mutex)
- Registry rollback on partial write failure
- Hung window blocking (eliminated timeouts)
- Missing registry keys on LTSC builds

## [1.1.0] - 2024-12-15

### Added
- Parallel broadcast strategy (5 layers)
- Targeted system window notifications
- DWM integration for titlebar updates
- Windows version detection (Win10 vs Win11)
- Registry flush for immediate persistence

### Performance
- 36% faster (110ms ? 70ms)
- Instant taskbar updates (<25ms)
- 4x faster titlebar color changes

### Fixed
- Multi-monitor taskbar synchronization
- Explorer.exe restart detection
- High contrast mode compatibility

## [1.0.0] - 2024-12-01

### Initial Release
- Basic theme toggle functionality
- Command-line interface
- VBScript launchers for silent execution
- Setup and uninstall scripts
- Embedded icon and manifest
- Exit code support for scripting

[1.2.0]: https://github.com/yourusername/ThemeToggle/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/yourusername/ThemeToggle/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/yourusername/ThemeToggle/releases/tag/v1.0.0
