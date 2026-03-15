# Release & WinGet

## Pre-release checklist

1. Bump version:
   ```powershell
   .\tools\bump-version.ps1 -Version 1.6.0
   ```
2. Optionally add an entry to `docs/RELEASE_NOTES.md`.
3. Commit on `main`.

## Automated release (GitHub Actions)

Push a version tag to trigger the pipeline:

```cmd
git tag v1.6.0
git push origin v1.6.0
```

The pipeline builds all artifacts, calculates SHA256 hashes, creates a GitHub Release, and triggers the WinGet publish workflow. The Release workflow verifies that the `VERSION` file matches the tag.
It also regenerates the `winget/` manifests from the CI-built artifacts, validates those manifests against the CI-built installer and portable ZIP, and uploads the generated manifest snapshot for the downstream WinGet publish job.
Tags that are not reachable from `main` are rejected by the release workflow.
Code signing is required in CI. The workflow fails unless the repository secrets `THEMETOGGLE_SIGN_PFX_BASE64` and `THEMETOGGLE_SIGN_PFX_PASSWORD` are set.

## Manual release

Run the unified build script:

```powershell
.\tools\release\build-and-publish.ps1
```

This produces `ThemeToggle.exe`, the NSIS installer, and a portable ZIP, then updates WinGet manifests with the correct SHA256 hash. Use `-DryRun` to preview, or `-NoSign` / `-NoWinget` / `-NoInstaller` / `-NoZip` to skip individual steps.

Upload the artifacts to a GitHub Release tagged `v<version>`.

## Signing

`tools/release/build-and-publish.ps1` signs automatically when credentials are available. Pass `-NoSign` to skip.

Credential options (set one):

| Env var | Description |
|---------|-------------|
| `THEMETOGGLE_SIGN_CERT_THUMBPRINT` | Certificate thumbprint (preferred) |
| `THEMETOGGLE_SIGN_PFX_PATH` | Path to PFX file |
| `THEMETOGGLE_SIGN_PFX_PASSWORD` | PFX password (prompts if missing) |
| `PFX_PATH` / `PFX_PASS` | Fallback aliases |

Optional: `THEMETOGGLE_SIGN_TIMESTAMP_URL`, `THEMETOGGLE_SIGN_DESCRIPTION`. See `tools/signing/README.md`.

### GitHub Actions signing setup

Add these repository secrets before pushing a release tag:

| Secret | Description |
|--------|-------------|
| `THEMETOGGLE_SIGN_PFX_BASE64` | Base64-encoded `.pfx` contents |
| `THEMETOGGLE_SIGN_PFX_PASSWORD` | Password for that `.pfx` |

Generate the base64 payload from a local PFX file with PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\cert.pfx"))
```

The release workflow writes that certificate to the runner temp directory, signs both EXEs, and fails if either Authenticode signature is missing or invalid.

## WinGet publishing

### First-time setup

1. Create a **classic** GitHub PAT (fine-grained PATs do not work for winget-pkgs) with `public_repo` scope.
2. Add it as a repository secret named `WINGET_GITHUB_TOKEN`.
3. Fork `microsoft/winget-pkgs` under the same account.

### Automated

The WinGet publish workflow runs automatically after a successful release. It validates the local `winget/` manifests and submits them with `wingetcreate submit`. It can also be triggered manually:

```cmd
gh workflow run "Publish to WinGet" -f version=1.6.0 -f dry_run=false
```

Manual runs auto-discover the latest successful `Release` workflow for the requested tag and restore the uploaded `winget-manifests` artifact before validating or submitting anything. To force a specific snapshot, pass `release_run_id` as an additional workflow input.

### Manual submission

Submit the local `winget/` manifests (recommended):

```cmd
pwsh -File .\tools\validate-winget.ps1 -Version 1.6.0
wingetcreate submit --prtitle "Update SevIQ.ThemeToggle 1.6.0" --token <PAT> winget
```

`wingetcreate update` is only suitable when installer URL mapping matches the existing manifest shape. For this package (installer + portable ZIP), submitting the curated local manifests is the most reliable path.

Keep the manifest schema headers and `ManifestVersion` on the last version that passes `winget validate --manifest winget` in GitHub Actions. Do not bump them just to match newer winget-pkgs checklist text. As of `2026-03-13`, the validated schema version in this repo is `1.10.0`.

## Troubleshooting

**SHA256 mismatch** — Recalculate from the published artifact and compare against the manifest value.

**Token issues** — Use a classic PAT with `public_repo` scope. The PAT owner must have forked `microsoft/winget-pkgs`. `WINGET_GITHUB_TOKEN` must be set as a repo secret.

**Schema header warnings / `winget validate` failure** — If `winget validate --manifest winget` reports schema header URL warnings or fails immediately after a schema bump, revert the manifest header URLs and `ManifestVersion` fields to the last validated repo version (`1.10.0` currently) and rerun validation before publishing.
