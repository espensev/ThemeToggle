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

### End-to-end signing flow

```
YOU (one-time setup)                      GITHUB ACTIONS (every tagged release)
─────────────────────                     ────────────────────────────────────

1. Have PFX + password on your machine
   (env vars or file on disk)

2. Run set-github-secrets.ps1
   ├─ Reads PFX from env / param
   ├─ Base64-encodes PFX ──────────────► THEMETOGGLE_SIGN_PFX_BASE64
   ├─ Passes password through ─────────► THEMETOGGLE_SIGN_PFX_PASSWORD
   └─ Extracts thumbprint ────────────► THEMETOGGLE_SIGN_CERT_THUMBPRINT

3. Push a version tag
   git tag v1.x.x && git push --tags
                                          4. Workflow triggers on v*.*.*
                                             ├─ Validate tag on main + VERSION match
                                             ├─ Require secrets (fail-fast if missing)
                                             │
                                             ├─ MATERIALIZE CERT
                                             │   ├─ Decode base64 → PFX file in runner temp
                                             │   └─ Set PFX_PATH + PASSWORD in env
                                             │
                                             ├─ BUILD + SIGN
                                             │   ├─ build-and-publish.ps1 -NoInstaller
                                             │   ├─ Compiles ThemeToggle.exe
                                             │   ├─ Signs exe with signtool (reads PFX from env)
                                             │   └─ Creates ThemeToggle-Portable.zip (contains signed exe)
                                             │
                                             ├─ VERIFY
                                             │   ├─ Get-AuthenticodeSignature
                                             │   ├─ Compare thumbprint against CERT_THUMBPRINT secret
                                             │   └─ Accept Valid, or expected self-signed untrusted-root UnknownError
                                             │
                                             ├─ PUBLISH
                                             │   ├─ SHA256 hashes for exe + zip
                                             │   ├─ Validate winget manifests
                                             │   └─ Create GitHub Release with artifacts
                                             │
                                             └─ CLEANUP (always runs)
                                                 └─ Delete PFX file from disk
```

**Why no trust store import?** The cert is self-signed (`CN=Sev_CodeHQ`).
On GitHub-hosted Windows runners, `Get-AuthenticodeSignature` can return
`UnknownError` with an untrusted-root chain message even when `signtool`
signed the file correctly. Importing the release PFX into `CurrentUser\Root`
is intentionally avoided in CI because that trust-store write hung the
`v1.5.7` recovery run on March 15, 2026. The workflow now verifies signer
identity by thumbprint and accepts only the expected untrusted-root
`UnknownError` case for that known self-signed certificate.

**Certificate renewal:** When the cert expires (check `$cert.NotAfter`), generate
a new PFX and re-run `set-github-secrets.ps1` — the script shows expiry date and
warns if < 30 days remain.
