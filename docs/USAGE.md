# ThemeToggle

ThemeToggle switches Windows between Light and Dark modes from the command
line, a shortcut or a scheduled task. Run the executable directly; an installer
is optional.

## Install and run

Use the project's release download, extract the portable package and keep its
files together. Run commands from the extracted directory:

```powershell
.\ThemeToggle.exe
.\ThemeToggle.exe /light
.\ThemeToggle.exe /dark
.\ThemeToggle.exe /quiet
.\ThemeToggle.exe /?
```

Alternatively, install the published package with `winget install
SevIQ.ThemeToggle`. WinGet availability can lag behind a release while its
manifest is reviewed.

Shortcut and other GUI launches are silent by default. Console launches print
status unless `/quiet` is supplied. `/light`, `/dark` and the default toggle
change the current user's Windows theme; `/?` displays help.

## Options

| Option | Effect |
|---|---|
| `/light`, `/dark` | Select the requested theme |
| `/toggle` | Toggle the theme; this is the default action |
| `/quiet` | Suppress status output |
| `/passthru` | Print detailed status |
| `/exitcode` | Map the result to the exit codes below |
| `/kick=all` | Refresh all supported stubborn applications; the default |
| `/kick=core` | Refresh the core application set |
| `/kick=none`, `/nokick` | Skip application refresh kicks |
| `/noflush` | Skip the best-effort registry flush |
| `/?`, `/help`, `/h` | Display help |

Options also accept `-` or `--` prefixes. For automation, select `/light` or
`/dark` explicitly when a fixed result is required, and add `/quiet` for a
silent invocation. A shortcut can have a Windows shortcut key assigned in its
properties. Keep operator-owned scheduled tasks in an application-owned task
folder and use the actual installed executable path.

## Result codes

These result codes apply when `/exitcode` is supplied. A theme change can
therefore return a nonzero success result; automation must distinguish it
from failure.

| Code | Result |
|---|---|
| `0` | Success with no change |
| `1` | Changed to Light |
| `2` | Changed to Dark |
| `11` | Registry write failed |
| `12` | Registry read failed |
| `20` | Theme registry value changed but the broadcast failed |
| `30` | Another instance is already running |
| `99` | Unknown error |

The source repository maintains contributor instructions in
`docs/DEVELOPMENT.md`, `docs/RELEASE.md` and `docs/TECHNICAL.md`. Those source
guides are separate from this self-contained portable-package guide.
