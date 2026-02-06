# Signing Tooling

This folder contains the release signing script.

## Usage

```powershell
.\sign-release.ps1 -Version 1.5.3
```

The script signs:
- `ThemeToggle.exe`
- `ThemeToggle-Setup-1.5.3.exe`

## Configuration (choose one)

### 1) Windows certificate store (preferred)

Set the cert thumbprint in the current user store:
```
setx THEMETOGGLE_SIGN_CERT_THUMBPRINT "THUMBPRINT"
```

Optional:
```
setx THEMETOGGLE_SIGN_STORE "My"
setx THEMETOGGLE_SIGN_STORE_LOCATION "currentuser"
```

### 2) PFX file

Set the PFX path and password (or leave the password unset to prompt):
```
setx THEMETOGGLE_SIGN_PFX_PATH "C:\path\to\cert.pfx"
setx THEMETOGGLE_SIGN_PFX_PASSWORD "your-password"
```

## Optional settings

```
setx THEMETOGGLE_SIGN_TIMESTAMP_URL "http://timestamp.digicert.com"
setx THEMETOGGLE_SIGN_DESCRIPTION "ThemeToggle"
```
