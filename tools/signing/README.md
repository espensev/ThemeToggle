# Signing Configuration

Signing is handled by `tools/release/build-and-publish.ps1`. No standalone signing script is needed.
Use PowerShell 7+ (`pwsh`) to run signing commands.

## Personal checklist

For this repo, the practical signing flow is:

1. Keep the current PFX and password available locally.
2. Run `.\tools\signing\set-github-secrets.ps1 -Repo espensev/ThemeToggle` whenever the certificate changes.
3. Make sure all three secrets exist on GitHub: `THEMETOGGLE_SIGN_PFX_BASE64`, `THEMETOGGLE_SIGN_PFX_PASSWORD`, `THEMETOGGLE_SIGN_CERT_THUMBPRINT`.
4. Tag from `main` only.
5. Expect the automated release to publish a signed `ThemeToggle.exe` and a `ThemeToggle-Portable.zip` that contains that signed exe.

If WinGet fails after a signed release succeeds, treat that as a manifest/publish problem first, not a signing problem.

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

Tagged releases should be configured with these repository secrets:

| Secret | Description |
|--------|-------------|
| `THEMETOGGLE_SIGN_PFX_BASE64` | Base64-encoded .pfx file |
| `THEMETOGGLE_SIGN_PFX_PASSWORD` | PFX password |
| `THEMETOGGLE_SIGN_CERT_THUMBPRINT` | Certificate thumbprint (for signer identity verification) |

`THEMETOGGLE_SIGN_CERT_THUMBPRINT` is strongly recommended for this repo. The workflow can technically continue without it, but that weakens signer identity verification and is not the intended steady-state setup.

### Quick setup (recommended)

Use the helper script to read your local PFX and push all three secrets at once:

```powershell
# Reads PFX path + password from your env vars, extracts thumbprint, pushes to GitHub
.\tools\signing\set-github-secrets.ps1 -Repo espensev/ThemeToggle

# Or specify explicitly
.\tools\signing\set-github-secrets.ps1 -Repo espensev/ThemeToggle -PfxPath "C:\path\to\cert.pfx"

# Preview without changing anything
.\tools\signing\set-github-secrets.ps1 -Repo espensev/ThemeToggle -DryRun
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
                                             │   ├─ Signs ThemeToggle.exe with signtool
                                             │   └─ Creates ThemeToggle-Portable.zip (contains that signed exe)
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

**Current release shape:** the GitHub Actions release flow does not publish the NSIS installer right now. The signed release artifacts are `ThemeToggle.exe` and `ThemeToggle-Portable.zip`.

**Why no trust store import?** The cert is self-signed (`CN=Sev_CodeHQ`).
On GitHub-hosted Windows runners, `Get-AuthenticodeSignature` can return
`UnknownError` with an untrusted-root chain message even when `signtool`
signed the file correctly. Importing the release PFX into `CurrentUser\Root`
is intentionally avoided in CI because that trust-store write hung the
`v1.5.7` recovery run on March 15, 2026. The workflow now verifies signer
identity by thumbprint and accepts only the expected untrusted-root
`UnknownError` case for that known self-signed certificate.

**Do not repeat the March 15, 2026 CI mistake:** do not try to "fix" self-signed validation on GitHub-hosted runners by importing the release certificate into the trust store. That hung the runner for hours during the `v1.5.7` recovery.

**Certificate renewal:** When the cert expires (check `$cert.NotAfter`), generate
a new PFX and re-run `set-github-secrets.ps1` — the script shows expiry date and
warns if < 30 days remain.
