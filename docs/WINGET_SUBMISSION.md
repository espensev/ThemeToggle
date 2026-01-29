# WinGet Submission Guide

How to submit ThemeToggle to the Windows Package Manager (winget) repository.

## Overview

WinGet packages are submitted via pull request to [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs).

**Package ID:** `SevIQ.ThemeToggle`
**Manifest path:** `manifests/s/SevIQ/ThemeToggle/<version>/`

## Prerequisites

1. GitHub account
2. Fork of [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs)
3. Release published on GitHub with installer file

## Manifest Files

The `winget/` folder contains three manifest files:

| File | Purpose |
|------|---------|
| `SevIQ.ThemeToggle.yaml` | Version manifest (package identifier) |
| `SevIQ.ThemeToggle.installer.yaml` | Installer details (URL, SHA256, switches) |
| `SevIQ.ThemeToggle.locale.en-US.yaml` | Package description and metadata |

## Submission Workflow

### Step 1: Ensure Release is Published

Before submitting, verify:
- GitHub release exists (e.g., `v1.5.2`)
- Installer file is uploaded: `ThemeToggle-Setup-1.5.2.exe`
- SHA256 in manifest matches the uploaded file

Verify SHA256:
```powershell
(Get-FileHash "ThemeToggle-Setup-1.5.2.exe" -Algorithm SHA256).Hash
```

### Step 2: Update Local Manifests

Run the manifest updater to ensure SHA256 is current:
```powershell
.\dist\update-winget.ps1 -Version 1.5.2
```

### Step 3: Fork and Clone winget-pkgs

```bash
# Fork via GitHub UI, then:
git clone https://github.com/YOUR_USERNAME/winget-pkgs.git
cd winget-pkgs
git remote add upstream https://github.com/microsoft/winget-pkgs.git
```

### Step 4: Create Version Folder

```bash
# Sync with upstream
git fetch upstream
git checkout master
git merge upstream/master

# Create branch
git checkout -b SevIQ.ThemeToggle-1.5.2

# Create folder structure
mkdir -p manifests/s/SevIQ/ThemeToggle/1.5.2
```

### Step 5: Copy Manifest Files

Copy from your ThemeToggle repo:
```bash
cp /path/to/ThemeToggle/winget/*.yaml manifests/s/SevIQ/ThemeToggle/1.5.2/
```

Or manually copy these three files:
- `SevIQ.ThemeToggle.yaml`
- `SevIQ.ThemeToggle.installer.yaml`
- `SevIQ.ThemeToggle.locale.en-US.yaml`

### Step 6: Validate Manifests

Use winget-cli to validate:
```bash
winget validate manifests/s/SevIQ/ThemeToggle/1.5.2/
```

Or use the online validator at [winget.run](https://winget.run/validate).

### Step 7: Commit and Push

```bash
git add manifests/s/SevIQ/ThemeToggle/1.5.2/
git commit -m "New version: SevIQ.ThemeToggle version 1.5.2"
git push origin SevIQ.ThemeToggle-1.5.2
```

### Step 8: Create Pull Request

1. Go to your fork on GitHub
2. Click "Compare & pull request"
3. Use title: `New version: SevIQ.ThemeToggle version 1.5.2`
4. Fill in the PR template
5. Submit

### Step 9: Wait for Validation

The winget-pkgs CI will:
1. Validate manifest schema
2. Check installer URL is accessible
3. Verify SHA256 hash
4. Run security scans

Fix any issues and push updates to your branch.

## Using wingetcreate (Alternative)

Microsoft's official tool can automate manifest creation:

```bash
# Install
winget install Microsoft.WingetCreate

# Update existing package
wingetcreate update SevIQ.ThemeToggle -v 1.5.2 -u https://github.com/espensev/ThemeToggle/releases/download/v1.5.2/ThemeToggle-Setup-1.5.2.exe --submit
```

This automatically:
- Downloads the installer
- Calculates SHA256
- Creates manifest files
- Opens PR (with `--submit` flag)

## Checklist

Before submitting:

- [ ] GitHub release published with tag `v<version>`
- [ ] Installer uploaded to release
- [ ] SHA256 in manifest matches installer
- [ ] Version numbers consistent across all files
- [ ] InstallerUrl points to correct release
- [ ] No placeholder values (`REPLACE_WITH_*`)
- [ ] ReleaseNotesUrl points to correct tag
- [ ] Manifests pass `winget validate`

## Troubleshooting

### SHA256 Mismatch
Re-download the installer from GitHub and recalculate:
```powershell
Invoke-WebRequest -Uri "https://github.com/espensev/ThemeToggle/releases/download/v1.5.2/ThemeToggle-Setup-1.5.2.exe" -OutFile "temp.exe"
(Get-FileHash "temp.exe" -Algorithm SHA256).Hash
```

### Validation Errors
Common issues:
- Missing required fields
- Invalid URL format
- Schema version mismatch
- Trailing whitespace in YAML

### PR Stuck in Review
- Automated checks take 10-30 minutes
- Manual review may take 1-7 days for new publishers
- Updates to existing packages are usually faster

## Resources

- [WinGet Manifests Documentation](https://learn.microsoft.com/windows/package-manager/package/manifest)
- [WinGet-pkgs Contributing Guide](https://github.com/microsoft/winget-pkgs/blob/master/CONTRIBUTING.md)
- [WinGet CLI Documentation](https://learn.microsoft.com/windows/package-manager/winget/)
- [Manifest Schema Reference](https://github.com/microsoft/winget-pkgs/tree/master/doc/manifest)
