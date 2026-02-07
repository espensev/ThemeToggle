# Release & WinGet

This page covers the release pipeline and WinGet publishing (manual and automated).

## Pre-Release Checklist

1) Bump version:
```powershell
.\tools\bump-version.ps1 -Version 1.5.2
```

2) Update release notes (optional but recommended):
- Add a new entry to `docs/RELEASE_NOTES.md`

3) Regenerate WinGet manifests (updates SHA256 + ProductCode):
```powershell
dist\update-winget.ps1
```

4) Commit changes on `main`.

## Automated Release (GitHub Actions)

Push a version tag to trigger the full release pipeline:
```cmd
git tag v1.5.2
git push origin v1.5.2
```

Pipeline behavior:
1. Builds artifacts (exe, installer, portable ZIP)
2. Calculates SHA256 hashes
3. Creates a GitHub Release
4. Triggers WinGet publish

Notes:
- The Release workflow verifies `VERSION` matches the tag.
- The WinGet publish workflow runs only if Release succeeds.

### First-Time Setup (One-Time)

1. Create a **classic** GitHub PAT (fine-grained PATs do not work for winget-pkgs):
   - Scopes: `public_repo` only
   - Token starts with `ghp_`
2. Add as repository secret:
   - Name: `WINGET_GITHUB_TOKEN`
3. Fork `microsoft/winget-pkgs` with the same account as the PAT
4. Ensure `winget/` manifests are current:
   - Run `dist\update-winget.ps1`
   - Commit the updated manifests

### Signing (Optional)

If a signing cert is available, the pipeline will auto-sign:
- `THEMETOGGLE_SIGN_CERT_THUMBPRINT` (recommended)
- or `THEMETOGGLE_SIGN_PFX_PATH` + `THEMETOGGLE_SIGN_PFX_PASSWORD`

Aliases (supported by `tools/signing/sign-release.ps1`):
- `PFX_PATH` + `PFX_PASS`

Optional:
- `THEMETOGGLE_SIGN_TIMESTAMP_URL`
- `THEMETOGGLE_SIGN_DESCRIPTION`

See `tools/signing/README.md` for details.

### Manual Trigger

You can run the workflow manually:
```cmd
gh workflow run "Publish to WinGet" -f version=1.5.2 -f dry_run=false
```

Dry run (validate only):
```cmd
gh workflow run "Publish to WinGet" -f version=1.5.2 -f dry_run=true
```

### How WinGet Publish Works

- If the package **exists** in winget-pkgs, the workflow uses `wingetcreate update`
- If the package **does not exist**, it submits a new manifest PR using the repo's `winget/` files

## Manual Release

1. Build artifacts:
   ```cmd
   dist\build-release.bat
   ```
2. Update WinGet manifests:
   ```powershell
   dist\update-winget.ps1
   ```
3. Create GitHub Release (tag `v<version>`) and upload:
   - `ThemeToggle.exe`
   - `ThemeToggle-Setup-<version>.exe`
   - `ThemeToggle-Portable.zip`

## Manual WinGet Submission

### Existing Package (Update)
```cmd
wingetcreate update SevIQ.ThemeToggle -v 1.5.2 -u https://github.com/espensev/ThemeToggle/releases/download/v1.5.2/ThemeToggle-Setup-1.5.2.exe --submit
```

### First-Time Package (New)
1. Fork `microsoft/winget-pkgs`
2. Create folder `manifests/s/SevIQ/ThemeToggle/<version>/`
3. Copy these files from `winget/`:
   - `SevIQ.ThemeToggle.yaml`
   - `SevIQ.ThemeToggle.installer.yaml`
   - `SevIQ.ThemeToggle.locale.en-US.yaml`
4. Validate:
   ```cmd
   winget validate manifests/s/SevIQ/ThemeToggle/<version>/
   ```
5. Commit and open PR to `microsoft/winget-pkgs`

## Troubleshooting

### Package Not Found
If you see `.../manifests/s/SevIQ/ThemeToggle was not found`, the package does not exist yet. Use the first-time submission flow and ensure `winget/` manifests are current.

### SHA256 Mismatch
Recalculate from the release artifact:
```powershell
Invoke-WebRequest -Uri "https://github.com/espensev/ThemeToggle/releases/download/v1.5.2/ThemeToggle-Setup-1.5.2.exe" -OutFile "temp.exe"
(Get-FileHash "temp.exe" -Algorithm SHA256).Hash
```

### Token Issues
- Use a **classic** PAT (fine-grained tokens do not work)
- Scope must include `public_repo`
- The PAT owner must have forked `microsoft/winget-pkgs`
- `GITHUB_TOKEN` is auto-provided by Actions; `WINGET_GITHUB_TOKEN` must be a repo secret

### WinGet publish cannot reach GitHub
If `wingetcreate` reports connectivity issues:
- Verify the PAT is valid and not expired
- Re-run the workflow after updating the secret
