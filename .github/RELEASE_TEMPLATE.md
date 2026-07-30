# Release vX.Y.Z - "<Codename>"

One-line summary of the release focus.

---

## What's New

- Key change 1.
- Key change 2.
- Key change 3.

---

## Downloads

Current CI release artifacts:

- `ThemeToggle.exe`: https://github.com/espensev/ThemeToggle/releases/download/vX.Y.Z/ThemeToggle.exe
- `ThemeToggle-Portable.zip`: https://github.com/espensev/ThemeToggle/releases/download/vX.Y.Z/ThemeToggle-Portable.zip

---

## Quick Start

```cmd
ThemeToggle.exe            # Toggle current theme
ThemeToggle.exe /light     # Force light
ThemeToggle.exe /dark      # Force dark
ThemeToggle.exe /quiet     # Silent (automation)
```

---

## Notes

- Typical execution time: 30-45 ms end-to-end on a busy desktop (test system).
- WinGet availability follows the corresponding `microsoft/winget-pkgs` PR merge.
- Full technical notes: https://github.com/espensev/ThemeToggle/blob/main/docs/RELEASE_NOTES.md

---

## Validation Checklist

- `build.bat` completes successfully.
- `ThemeToggle.exe /?` shows updated CLI options.
- `tools\validate.bat` passes.
- WinGet manifests in `winget/` match uploaded release artifacts.
- The `microsoft/winget-pkgs` PR for this version is tracked. Do not announce `winget install SevIQ.ThemeToggle` until that PR is merged.
