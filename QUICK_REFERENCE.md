# ThemeToggle Quick Reference

## Files Overview

| File                     | Description              | When to Use          |
|--------------------------|--------------------------|----------------------|
| `ThemeToggle.exe`        | Main executable          | Direct command-line use |
| `ThemeToggle.vbs`        | Silent toggle launcher   | Hotkeys, shortcuts   |
| `ThemeToggle-Light.vbs`  | Silent light mode        | Morning automation   |
| `ThemeToggle-Dark.vbs`   | Silent dark mode         | Evening automation   |
| `ThemeToggle.ps1`        | PowerShell launcher      | Advanced scripting   |
| `setup.bat`              | Interactive installer    | First-time setup     |

## Quick Commands

```bash
# Direct execution (shows console)
ThemeToggle.exe            # Toggle
ThemeToggle.exe /light     # Light mode
ThemeToggle.exe /dark      # Dark mode
ThemeToggle.exe /quiet     # Silent (no output)

# Silent execution (no console)
ThemeToggle.vbs            # Toggle silently
ThemeToggle-Light.vbs      # Light mode silently
ThemeToggle-Dark.vbs       # Dark mode silently

# PowerShell
.\ThemeToggle.ps1            # Toggle
.\ThemeToggle.ps1 -Light     # Light mode
.\ThemeToggle.ps1 -Dark      # Dark mode
```

## Hotkey Setup

1. Create a desktop shortcut to `ThemeToggle.vbs`.
2. Right-click the shortcut and open "Properties".
3. Set the "Shortcut key" field to `Ctrl+Alt+T`.

Pressing the assigned hotkey will toggle the theme.

## Scheduled Automation

### Quick Setup (GUI)
Run `setup.bat` and select option 3.

### Manual Setup
```batch
# Light theme at 7 AM
schtasks /create /tn "Theme-Morning" /tr "wscript.exe \"C:\path\to\ThemeToggle-Light.vbs\"" /sc daily /st 07:00

# Dark theme at 7 PM
schtasks /create /tn "Theme-Evening" /tr "wscript.exe \"C:\path\to\ThemeToggle-Dark.vbs\"" /sc daily /st 19:00
```

## Common Use Cases

### Hotkey for Instant Toggle
Create a shortcut to `ThemeToggle.vbs`, send it to the desktop, and assign a hotkey.

### Auto-toggle on Login
Run `setup.bat` and select option 2.

### Sunrise/Sunset Automation
Run `setup.bat` and select option 3.

### One-Click Desktop Toggle
Drag `ThemeToggle.vbs` to the desktop and double-click to toggle.

### Stream Deck Button
Add an "Open" action and browse to `ThemeToggle.vbs`.

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
| VBS wrapper overhead | <1 ms |

## Troubleshooting

- **Console window flashes briefly**: Use `.vbs` files instead of `.exe`.
- **Hotkey doesn't work**: Check if another application uses the same hotkey.
- **Theme doesn't change**: Ensure compatibility with Windows 10 (1809+) or Windows 11.
- **Scheduled task fails**: Use absolute paths in Task Scheduler.
- **Batch scripts fail from other directories**: Ensure scripts use the correct directory handling pattern.

## Documentation

- `README.md`: Full documentation
- `AUTOMATION_GUIDE.md`: Advanced automation
- `setup.bat`: Interactive installer

## Tips

1. Pin `ThemeToggle.vbs` to the taskbar for quick access.
2. Add to the desktop context menu (see `AUTOMATION_GUIDE.md`).
3. Create multiple scheduled tasks for different times.
4. Test scripts before deploying them.

For more detailed instructions, refer to `AUTOMATION_GUIDE.md`.
