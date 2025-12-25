# Winget Manifest Submission Guide

This guide explains how to validate, test, and submit ThemeToggle to the Windows Package Manager (Winget) Community Repository.

---

## ?? Prerequisites

### 1. Install Winget Tools
```powershell
# Install winget (if not already present)
# Winget is included with Windows 11 and Windows 10 (via App Installer)

# Install wingetcreate (manifest creation/validation tool)
winget install Microsoft.WingetCreate
```

### 2. Fork Winget Repository
1. Go to: https://github.com/microsoft/winget-pkgs
2. Click "Fork" (top-right)
3. Clone your fork:
```bash
git clone https://github.com/yourusername/winget-pkgs.git
cd winget-pkgs
```

---

## ?? Prepare Manifests

### Step 1: Update Publisher Information

**Edit all 3 manifest files** in the `winget/` folder:

Replace these placeholders:
- `YourPublisher` ? Your actual publisher name (e.g., `JohnDoe`, `AcmeCorp`)
- `yourusername` ? Your GitHub username
- `Your Publisher Name` ? Your full name or company name
- `Your Name` ? Your name

**Example:**
```yaml
# Before
PackageIdentifier: YourPublisher.ThemeToggle

# After
PackageIdentifier: JohnDoe.ThemeToggle
```

### Step 2: Calculate SHA256 Hash

After building the installer, calculate its SHA256:

**PowerShell:**
```powershell
Get-FileHash ThemeToggle-Setup-1.2.0.exe -Algorithm SHA256
```

**Output:**
```
Algorithm       Hash
---------       ----
SHA256          ABC123DEF456...
```

**Update in `YourPublisher.ThemeToggle.installer.yaml`:**
```yaml
InstallerSha256: ABC123DEF456...  # Replace with actual hash
```

### Step 3: Get Product Code (GUID)

**Option A: Extract from installed app**
```powershell
# Install ThemeToggle, then run:
Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
  Where-Object {$_.DisplayName -like "*ThemeToggle*"} | 
  Select-Object DisplayName, PSChildName

# PSChildName is the Product Code (GUID)
```

**Option B: Generate new GUID**
```powershell
# Generate a new GUID for first-time submission
[guid]::NewGuid().ToString()
```

**Update in `YourPublisher.ThemeToggle.installer.yaml`:**
```yaml
ProductCode: '{12345678-1234-1234-1234-123456789ABC}'  # Replace
```

### Step 4: Update Installer URL

After creating a GitHub release:

```yaml
InstallerUrl: https://github.com/yourusername/ThemeToggle/releases/download/v1.2.0/ThemeToggle-Setup-1.2.0.exe
```

Replace `yourusername` with your actual GitHub username.

---

## ? Validate Manifests

### Validation Tool
```powershell
# Navigate to winget folder
cd winget

# Validate manifests
winget validate --manifest .
```

**Expected output:**
```
Manifest validation succeeded.
```

**Common errors:**
- ? "Invalid YAML syntax" ? Check indentation (use spaces, not tabs)
- ? "InstallerSha256 mismatch" ? Recalculate hash
- ? "Invalid URL" ? Ensure URL is accessible
- ? "Schema validation failed" ? Check manifest version (1.5.0)

---

## ?? Test Installation Locally

### Test from Local Manifest
```powershell
# Install from local manifest
winget install --manifest winget\YourPublisher.ThemeToggle.yaml

# Verify installation
winget list ThemeToggle

# Test uninstall
winget uninstall ThemeToggle
```

### Test Installation Behavior
- [ ] Installer runs silently with `/S` flag
- [ ] App appears in "Add/Remove Programs"
- [ ] Start Menu shortcuts created (if selected)
- [ ] Desktop shortcut created (if selected)
- [ ] Uninstaller removes all files

---

## ?? Submit to Winget Repository

### Step 1: Copy Manifests to Fork

**Manifest location structure:**
```
winget-pkgs/
??? manifests/
    ??? y/              ? First letter of publisher (lowercase)
        ??? YourPublisher/
            ??? ThemeToggle/
                ??? 1.2.0/
                    ??? YourPublisher.ThemeToggle.yaml
                    ??? YourPublisher.ThemeToggle.installer.yaml
                    ??? YourPublisher.ThemeToggle.locale.en-US.yaml
```

**Commands:**
```bash
cd winget-pkgs
mkdir -p manifests/y/YourPublisher/ThemeToggle/1.2.0
cp ../ThemeToggle/winget/* manifests/y/YourPublisher/ThemeToggle/1.2.0/
```

### Step 2: Commit and Push

```bash
git checkout -b add-themetoggle-1.2.0
git add manifests/y/YourPublisher/ThemeToggle/
git commit -m "New package: YourPublisher.ThemeToggle version 1.2.0"
git push origin add-themetoggle-1.2.0
```

### Step 3: Create Pull Request

1. Go to your fork on GitHub
2. Click "Compare & pull request"
3. **Title:** `New package: YourPublisher.ThemeToggle version 1.2.0`
4. **Description:**
```markdown
## Package Information
- **Package Name:** ThemeToggle
- **Publisher:** Your Publisher Name
- **Version:** 1.2.0
- **License:** Unlicense (Public Domain)

## Description
Ultra-fast Windows theme switcher with 10-15ms execution time. Supports hotkeys, scheduled automation, and multi-monitor setups.

## Testing
- [x] Manifest validated with `winget validate`
- [x] Tested local installation
- [x] Verified silent installation works
- [x] Tested uninstallation
- [x] SHA256 hash verified

## Links
- GitHub: https://github.com/yourusername/ThemeToggle
- Release: https://github.com/yourusername/ThemeToggle/releases/tag/v1.2.0
```

5. Submit pull request

### Step 4: Respond to Review

Microsoft's bot will automatically:
- ? Validate manifest format
- ? Check URL accessibility
- ? Verify SHA256 hash
- ? Run automated tests

**Reviewers may request:**
- Minor formatting changes
- Additional testing
- Screenshot/GIF of installation

**Response time:** 1-7 days

---

## ?? Update Package (Future Versions)

### For version 1.3.0:

1. **Build new installer:**
```cmd
build.bat
build-installer.bat
```

2. **Update manifests:**
```yaml
# All files: Update version
PackageVersion: 1.3.0

# installer.yaml: Update URL and hash
InstallerUrl: https://github.com/yourusername/ThemeToggle/releases/download/v1.3.0/ThemeToggle-Setup-1.3.0.exe
InstallerSha256: NEW_HASH_HERE

# locale.yaml: Update ReleaseNotes
```

3. **Create new manifest folder:**
```bash
mkdir -p manifests/y/YourPublisher/ThemeToggle/1.3.0
cp winget/* manifests/y/YourPublisher/ThemeToggle/1.3.0/
```

4. **Submit PR:**
```bash
git checkout -b update-themetoggle-1.3.0
git add manifests/y/YourPublisher/ThemeToggle/1.3.0/
git commit -m "Update: YourPublisher.ThemeToggle version 1.3.0"
git push origin update-themetoggle-1.3.0
```

---

## ??? Automated Manifest Generation

Use `wingetcreate` to generate manifests automatically:

```powershell
# Create new package manifest
wingetcreate new `
  --url "https://github.com/yourusername/ThemeToggle/releases/download/v1.2.0/ThemeToggle-Setup-1.2.0.exe" `
  --version "1.2.0" `
  --publisher "Your Publisher Name" `
  --name "ThemeToggle" `
  --description "Ultra-fast Windows theme switcher" `
  --license "Unlicense" `
  --out "winget"

# Update existing package
wingetcreate update YourPublisher.ThemeToggle `
  --version "1.3.0" `
  --urls "https://github.com/yourusername/ThemeToggle/releases/download/v1.3.0/ThemeToggle-Setup-1.3.0.exe" `
  --submit
```

---

## ?? After Approval

### User Installation
```powershell
# Search for package
winget search ThemeToggle

# Install
winget install ThemeToggle

# Or with full ID
winget install YourPublisher.ThemeToggle

# Update
winget upgrade ThemeToggle

# Uninstall
winget uninstall ThemeToggle
```

### Package Statistics
- View installs: https://winget.run/pkg/YourPublisher/ThemeToggle
- Monitor issues: https://github.com/microsoft/winget-pkgs/issues

---

## ?? Troubleshooting

### "SHA256 mismatch"
**Cause:** Installer file changed after hash was calculated.
**Solution:** Rebuild installer, recalculate hash, update manifest.

### "Installer URL not accessible"
**Cause:** GitHub release not public or URL incorrect.
**Solution:** Verify URL in browser, ensure release is published (not draft).

### "Silent install fails"
**Cause:** `/S` flag not working with NSIS.
**Solution:** Verify NSIS installer includes silent mode support.

### "Product code not found"
**Cause:** App not registered in registry.
**Solution:** Check NSIS script includes uninstall registry keys.

### "Manifest validation failed"
**Cause:** YAML syntax error (tabs, indentation, schema mismatch).
**Solution:** Use `winget validate` locally before submitting.

---

## ?? Resources

- **Winget Docs:** https://learn.microsoft.com/windows/package-manager/
- **Manifest Schema:** https://github.com/microsoft/winget-cli/tree/master/schemas
- **Community Repo:** https://github.com/microsoft/winget-pkgs
- **Submission Guidelines:** https://github.com/microsoft/winget-pkgs/blob/master/CONTRIBUTING.md
- **wingetcreate:** https://github.com/microsoft/winget-create

---

## ? Submission Checklist

Before submitting:

- [ ] All placeholder text replaced (YourPublisher, yourusername, etc.)
- [ ] SHA256 hash calculated and inserted
- [ ] Product code (GUID) inserted
- [ ] Installer URL points to public GitHub release
- [ ] Manifests validated with `winget validate`
- [ ] Local installation tested successfully
- [ ] Silent installation tested (`/S` flag)
- [ ] Uninstallation tested and verified clean
- [ ] Fork of winget-pkgs repository created
- [ ] Manifests copied to correct folder structure
- [ ] Pull request description complete

---

## ?? Expected Timeline

| Step | Time |
|------|------|
| Manifest creation | 15-30 minutes |
| Local testing | 10-15 minutes |
| PR submission | 5 minutes |
| Automated validation | 5-10 minutes |
| Human review | 1-7 days |
| Approval & merge | Immediate after approval |
| Package available | Within 1 hour of merge |

**Total:** ~1-7 days from submission to availability

---

**Ready to submit ThemeToggle to Winget!** ??
