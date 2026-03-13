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
