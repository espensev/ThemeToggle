# Signing Configuration

Signing is handled by `tools/release/build-and-publish.ps1`. No standalone signing script is needed.
Use PowerShell 7+ (`pwsh`) to run signing commands.

## Quick usage

```powershell
.\tools\release\build-and-publish.ps1 # full release flow (signs when configured)
build.bat /sign                       # build + sign exe only
```

## Credential methods (choose one)

### Certificate store (preferred)

```
setx THEMETOGGLE_SIGN_CERT_THUMBPRINT "THUMBPRINT"
```

Optional overrides:

```
setx THEMETOGGLE_SIGN_STORE "My"
setx THEMETOGGLE_SIGN_STORE_LOCATION "currentuser"
```

### PFX file

```
setx THEMETOGGLE_SIGN_PFX_PATH "C:\path\to\cert.pfx"
setx THEMETOGGLE_SIGN_PFX_PASSWORD "your-password"
```

Fallback env vars (`PFX_PATH` / `PFX_PASS`) are also accepted.

## Optional settings

```
setx THEMETOGGLE_SIGN_TIMESTAMP_URL "http://timestamp.digicert.com"
setx THEMETOGGLE_SIGN_DESCRIPTION "ThemeToggle"
```

## GitHub Actions release signing

Tagged releases require three repository secrets:

| Secret | Description |
|--------|-------------|
| `THEMETOGGLE_SIGN_PFX_BASE64` | Base64-encoded .pfx file |
| `THEMETOGGLE_SIGN_PFX_PASSWORD` | PFX password |
| `THEMETOGGLE_SIGN_CERT_THUMBPRINT` | Certificate thumbprint (for signer identity verification) |

### Quick setup (recommended)

Use the helper script to read your local PFX and push all three secrets at once:

```powershell
# Reads PFX path + password from your env vars, extracts thumbprint, pushes to GitHub
.\tools\signing\set-github-secrets.ps1

# Or specify explicitly
.\tools\signing\set-github-secrets.ps1 -PfxPath "C:\path\to\cert.pfx"

# Preview without changing anything
.\tools\signing\set-github-secrets.ps1 -DryRun
```

The script resolves credentials in this order:
1. `-PfxPath` / `-PfxPassword` parameters
2. `THEMETOGGLE_SIGN_PFX_PATH` / `THEMETOGGLE_SIGN_PFX_PASSWORD` env vars
3. `PFX_PATH` / `PFX_PASS` fallback env vars
4. Interactive prompt

Requires `gh` CLI authenticated with repo scope.

### Manual setup

Create the base64 value from your PFX file:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\cert.pfx"))
```

Then set each secret individually:

```powershell
gh secret set THEMETOGGLE_SIGN_PFX_BASE64 --repo owner/repo
gh secret set THEMETOGGLE_SIGN_PFX_PASSWORD --repo owner/repo
gh secret set THEMETOGGLE_SIGN_CERT_THUMBPRINT --repo owner/repo
```

### How it works

The release workflow restores that PFX into the runner temp directory, sets `THEMETOGGLE_SIGN_PFX_PATH` and `THEMETOGGLE_SIGN_PFX_PASSWORD`, signs the EXE, and then verifies the Authenticode signature before publishing the GitHub Release. The PFX is deleted in an `always()` cleanup step.
