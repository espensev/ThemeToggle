# ThemeToggle Quick Reference

## Files Overview

| File             | Description                | When to Use            |
|------------------|----------------------------|------------------------|
| `ThemeToggle.exe`| Main executable (silent)   | Direct/toggled launches|
| `ThemeToggle.ps1`| PowerShell wrapper         | Advanced scripting     |
| `setup.bat`      | Interactive setup wizard   | Hotkeys/automation     |

## Quick Commands

```bash
# Direct execution
ThemeToggle.exe             # Toggle
ThemeToggle.exe /light      # Light mode
ThemeToggle.exe /dark       # Dark mode
ThemeToggle.exe /quiet      # Silence output (use with hotkeys/tasks)
ThemeToggle.exe /exitcode   # Return precise exit code

# PowerShell
.\ThemeToggle.ps1           # Toggle
.\ThemeToggle.ps1 -Light    # Light mode
.\ThemeToggle.ps1 -Dark     # Dark mode
```

## Hotkey Setup

1. Create a desktop shortcut to `ThemeToggle.exe`.
2. Right-click the shortcut and open "Properties".
3. Set the "Shortcut key" field to `Ctrl+Alt+T`.
4. Optional: add `/quiet` to the shortcut's arguments to hide console output.

Pressing the assigned hotkey will toggle the theme.

## Scheduled Automation

### Quick Setup (GUI)
Run `setup.bat` and select option 3.

### Manual Setup
```batch
# Light theme at 7 AM
schtasks /create /tn "Theme-Morning" /tr "\"C:\path\to\ThemeToggle.exe\" /light /quiet" /sc daily /st 07:00

# Dark theme at 7 PM
schtasks /create /tn "Theme-Evening" /tr "\"C:\path\to\ThemeToggle.exe\" /dark /quiet" /sc daily /st 19:00
```

## Common Use Cases

### Hotkey for Instant Toggle
Create a shortcut to `ThemeToggle.exe /quiet`, send it to the desktop, and assign a hotkey.

### Auto-toggle on Login
Run `setup.bat` and select option 2.

### Sunrise/Sunset Automation
Run `setup.bat` and select option 3.

### One-Click Desktop Toggle
Drag `ThemeToggle.exe` to the desktop and double-click to toggle (add `/quiet` for silent operation).

### Stream Deck Button
Add an "Open" action and browse to `ThemeToggle.exe` (append `/light` or `/dark` as needed).

## Exit Codes (with /exitcode)

| Code | Meaning               |
|------|-----------------------|
| 0    | No change needed      |
| 1    | Changed to Light      |
| 2    | Changed to Dark       |
| 10   | Registry error        |
| 11   | Write failed          |
| 20   | Broadcast failed (theme already changed) |

Exit code `20` indicates the theme registry values switched but at least one broadcast call did not complete. The executable prints a short warning so you can retry broadcasts if necessary.

## Performance

| Action             | Time     |
|--------------------|----------|
| No change needed   | 5-10 ms  |
| Full theme toggle  | ~110 ms  |
| Shortcut/hotkey overhead | <1 ms |

## Troubleshooting

- **Console window flashes briefly**: Add `/quiet` to your shortcut or task arguments.
- **Hotkey doesn't work**: Check if another application uses the same hotkey.
- **Theme doesn't change**: Ensure compatibility with Windows 10 (1809+) or Windows 11.
- **Scheduled task fails**: Use absolute paths in Task Scheduler.
- **Batch scripts fail from other directories**: Ensure scripts use the correct directory handling pattern.

## Documentation

- `README.md`: Full documentation
- `AUTOMATION_GUIDE.md`: Advanced automation
- `setup.bat`: Interactive installer

## Tips

1. Pin `ThemeToggle.exe /quiet` to the taskbar for quick access.
2. Add to the desktop context menu (see `AUTOMATION_GUIDE.md`).
3. Create multiple scheduled tasks for different times.
4. Test scripts before deploying them.

For more detailed instructions, refer to `AUTOMATION_GUIDE.md`.
