# Release vX.Y.Z - "<Codename>"

One-line summary of the release focus.

---

## What's New

- Key change 1.
- Key change 2.
- Key change 3.

---

## Downloads

- `ThemeToggle.exe`: https://github.com/espensev/ThemeToggle/releases/download/vX.Y.Z/ThemeToggle.exe
- `ThemeToggle-Setup-X.Y.Z.exe`: https://github.com/espensev/ThemeToggle/releases/download/vX.Y.Z/ThemeToggle-Setup-X.Y.Z.exe
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

- Typical execution time: 10-15 ms (test system).
- WinGet package: `winget install SevIQ.ThemeToggle`
- Full technical notes: https://github.com/espensev/ThemeToggle/blob/main/docs/RELEASE_NOTES.md

---

## Validation Checklist

- `build.bat` completes successfully.
- `ThemeToggle.exe /?` shows updated CLI options.
- `tools\validate.bat` passes.
- WinGet manifests in `winget/` match uploaded release artifacts.
