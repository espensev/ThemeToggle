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

Tagged releases now require repository secrets for signing:

```
THEMETOGGLE_SIGN_PFX_BASE64
THEMETOGGLE_SIGN_PFX_PASSWORD
```

Create the base64 value from your PFX file:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\cert.pfx"))
```

The release workflow restores that PFX into the runner temp directory, sets `THEMETOGGLE_SIGN_PFX_PATH` and `THEMETOGGLE_SIGN_PFX_PASSWORD`, signs the EXE and installer, and then verifies both Authenticode signatures before publishing the GitHub Release.
