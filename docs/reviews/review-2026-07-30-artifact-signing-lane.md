# Review - Artifact Signing pilot lane + release policy hardening (working tree)

**Date:** 2026-07-30
**Surface:** working tree on `fix/winget-publish-release-assets` (branch HEAD `b07b2cf` is already merged into `origin/main` via PR #7; this review covers only the uncommitted changes: 11 modified files + 1 untracked script)
**Spec source:** none found (user request: "review and cleanup, but know it's live" — `SevIQ.ThemeToggle 1.5.7` is published on WinGet)
**Standards sources:** `AGENTS.md`; executable invariants in `tools/validate-release-workflow.ps1` and `tools/validate-winget.ps1`
**Verdict:** PASS WITH NOTES (all findings low/medium; fixed in the cleanup pass accompanying this review)

## Findings

### Medium

- [axis: regression] `README.md:16` - New claim "ThemeToggle runs silently by default; the theme change is the only visible feedback" is inaccurate.
  Evidence: `src/main.cpp:94-116` (`PrintMessage` prints a status line whenever not `/quiet`), `src/main.cpp:507-519` (`wWinMain` + `AttachConsole(ATTACH_PARENT_PROCESS)`) — console runs print a colored status line by default; only GUI launches (no parent console) are silent. The previously committed wording ("GUI launches are silent by default") was precise.
  Impact: README for a live product misstates default behavior and makes `/quiet` look pointless.
  Recommendation: restore GUI-launch-specific wording. **Fixed in cleanup.**

### Low

- [axis: spec] `winget/SevIQ.ThemeToggle.locale.en-US.yaml:30` - Feature bullet "Standalone executable, portable ZIP, and optional installer distribution" advertises an installer that is not distributed.
  Evidence: v1.5.6 dropped the NSIS installer from releases; CI publishes only `ThemeToggle.exe` + `ThemeToggle-Portable.zip`, and `tools/validate-release-workflow.ps1` forbids the `ThemeToggle-Setup-*` asset. The installer exists only as a local build option.
  Impact: next WinGet submission would publish a misleading package description.
  Recommendation: "Standalone executable and portable ZIP distribution". **Fixed in cleanup.**

- [axis: regression] `tools/release/refresh-portable-package.ps1:77` - `($lines -join "`n") | Set-Content -NoNewline` strips the manifest's trailing newline (all three committed manifests end with LF, no BOM), so the CI-refreshed `installer.yaml` would differ in formatting from the `build-and-publish.ps1` write path (`Get-Content -Raw` → `Set-Content -NoNewline`, which preserves it).
  Impact: cosmetic byte-diff in the published manifest snapshot; winget accepts it either way.
  Recommendation: append a final `` `n `` after the join. **Fixed in cleanup.**

- [axis: standards] `tools/validate-release-workflow.ps1:703-704` - The release-workflow assertion for the availability sentence is tacked onto the end of the file after the release-template section, apart from the other `$releaseWorkflow` asserts.
  Impact: organizational only.
  Recommendation: fold it into the main release-workflow assert block. **Fixed in cleanup.**

- [axis: standards] `.github/RELEASE_TEMPLATE.md:38` - The internal author instruction "Do not announce `winget install SevIQ.ThemeToggle` until that PR is merged." sits in the public-facing **Notes** section of the release template; copy-pasting the template into a release body would leak an internal instruction.
  Impact: cosmetic/wording leak risk in public release notes.
  Recommendation: keep the public-appropriate availability sentence in Notes and move the instruction (verbatim, so the validator literal still matches) into the Validation Checklist. **Fixed in cleanup.**

## Verified sound (live-pipeline risk checks)

- `azure/artifact-signing-action@v1` is real. Microsoft renamed Trusted Signing → **Artifact Signing** in January 2026; the action repo is `Azure/artifact-signing-action` with floating tags `v1` and `v2` present, so the `uses:` reference resolves at job setup — a nonexistent ref would have failed **every** tagged release, even with the lane disabled, since GitHub resolves all `uses:` actions before evaluating `if:` conditions. All inputs used by the workflow (`signing-account-name`, `files`, `append-signature`, `description`, `description-url`, `timestamp-rfc3161`, `exclude-*-credential`) exist at the `v1` ref; only `endpoint` and `certificate-profile-name` are required, and both are wired. Vendor README now examples `@v2` (v2.0.0, May 2026, module migration) — staying on the proven `v1` line is a reasonable conservative pin for a pilot lane; revisit once the lane is actually enabled.
- Rollout is safe-by-default: `gh variable list` returns zero repo variables, so `THEMETOGGLE_ARTIFACT_SIGNING_ENABLED` is unset → lane disabled → the next tagged release runs exactly the proven v1.5.7 path plus the new hard thumbprint requirement.
- The hard thumbprint requirement cannot brick the next release: `gh secret list` confirms `THEMETOGGLE_SIGN_PFX_BASE64`, `THEMETOGGLE_SIGN_PFX_PASSWORD`, and `THEMETOGGLE_SIGN_CERT_THUMBPRINT` all exist (set 2026-03-15).
- Append-signing hash flow is correct: `installer.yaml` is portable-ZIP-only (the exe is a `NestedInstallerFiles` entry, not a separate installer), so after the append signature mutates the exe, refreshing only the ZIP hash is sufficient. Step order is right: refresh → Calculate SHA256 (release body) → `validate-winget -VerifyLocalArtifacts` (checks the refreshed ZIP hash against the actual artifact) → stage manifest snapshot → create release.
- `refresh-portable-package.ps1` rebuilds the ZIP with the same layout as `build-and-publish.ps1` (`Compress-Archive -Path "$deployDir\*"`, exe at ZIP root, matching `RelativeFilePath: ThemeToggle.exe`) and mirrors its `Set-Content -NoNewline -Encoding UTF8` manifest write.
- `permissions: id-token: write` is required for OIDC `azure/login@v2` and harmless while the lane is disabled.
- The locale `ReleaseNotes` rewrite for 1.5.7 only changes the repo template copy; the live 1.5.7 listing in `microsoft/winget-pkgs` is unaffected, and the existing validator rule (ReleaseNotes first line must start with `PackageVersion`) still passes.
- `build-and-publish.ps1` tagged-CI guard is coherent: the workflow materializes the PFX into `GITHUB_ENV` before the build step, so requiring `THEMETOGGLE_SIGN_PFX_PATH` + `THEMETOGGLE_SIGN_CERT_THUMBPRINT` under `Test-TaggedCiRelease` passes in CI and is skipped locally.

## Verification

- `.\tools\validate-release-workflow.ps1` - PASS (working tree)
- `.\tools\validate-winget.ps1` - PASS, including real `winget validate --manifest winget` (working tree)
- `gh secret list` / `gh variable list --repo espensev/ThemeToggle` - secrets present; no variables (lane off)
- Web verification of `Azure/artifact-signing-action` (tags page, `v1` `action.yml`, README) - action, `v1` floating tag, and all used inputs confirmed
- Both validators re-run after cleanup edits - see final response

## Coverage Notes

- Files reviewed deeply: all 11 modified files (full diff read) plus current-state reads of `release.yml`, `validate-winget.ps1`, `validate-release-workflow.ps1` (via validator run), all three `winget/*.yaml`, `RELEASE_TEMPLATE.md`, relevant `build-and-publish.ps1` sections, `src/main.cpp` (silent-behavior claim); untracked `tools/release/refresh-portable-package.ps1` read in full.
- Files sampled or excluded: `.github/workflows/winget-publish.yml` (not modified; interface via manifest snapshot unchanged).

## Open Questions

- None blocking. Operational reminder: `tools/release/refresh-portable-package.ps1` is untracked — it must be included in the commit, or CI's `validate-release-workflow.ps1` (which requires the file) and the enabled-lane workflow step will fail.
