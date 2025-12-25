# Winget Quick Reference

Quick commands for Winget manifest preparation and submission.

---

## ?? Quick Start

### 1. Build Installer
```cmd
build.bat
build-installer.bat
```

### 2. Prepare Manifests
```cmd
prepare-winget-manifest.bat
```
This generates:
- SHA256 hash
- Product GUID
- Customization summary

### 3. Edit Manifests
Open files in `winget\` folder, replace:
- `YourPublisher` ? Your publisher name
- `yourusername` ? Your GitHub username
- `SHA256` and `GUID` ? Values from summary

### 4. Validate
```powershell
winget validate --manifest winget
```

### 5. Test Locally
```powershell
winget install --manifest winget\YourPublisher.ThemeToggle.yaml
```

### 6. Submit
See `WINGET_SUBMISSION_GUIDE.md` for full instructions.

---

## ?? Manifest Files

| File | Purpose |
|------|---------|
| `YourPublisher.ThemeToggle.yaml` | Version manifest (simple) |
| `YourPublisher.ThemeToggle.installer.yaml` | Installer details, hash, URL |
| `YourPublisher.ThemeToggle.locale.en-US.yaml` | Descriptions, tags, release notes |

---

## ?? Key Values to Replace

| Placeholder | Replace With | Example |
|-------------|--------------|---------|
| `YourPublisher` | Publisher name | `JohnDoe` |
| `yourusername` | GitHub username | `johndoe` |
| `REPLACE_WITH_ACTUAL_SHA256_HASH` | SHA256 hash | (from script) |
| `{REPLACE_WITH_PRODUCT_GUID}` | Product GUID | (from script) |
| `Your Publisher Name` | Full name | `John Doe` |
| `Your Name` | Author name | `John Doe` |

---

## ? Validation Checklist

Before submission:
- [ ] All placeholders replaced
- [ ] SHA256 hash inserted
- [ ] Product GUID inserted
- [ ] GitHub URLs updated
- [ ] `winget validate` passes
- [ ] Local install tested
- [ ] Silent install works (`/S`)
- [ ] Uninstall verified

---

## ?? Submission Commands

```bash
# Fork and clone winget-pkgs
git clone https://github.com/yourusername/winget-pkgs.git
cd winget-pkgs

# Create folder structure
mkdir -p manifests/y/YourPublisher/ThemeToggle/1.2.0

# Copy manifests
cp ../ThemeToggle/winget/* manifests/y/YourPublisher/ThemeToggle/1.2.0/

# Commit and push
git checkout -b add-themetoggle-1.2.0
git add manifests/y/YourPublisher/ThemeToggle/
git commit -m "New package: YourPublisher.ThemeToggle version 1.2.0"
git push origin add-themetoggle-1.2.0
```

Then create PR on GitHub.

---

## ?? Update Package (Future Versions)

```cmd
# 1. Build new version
build.bat
build-installer.bat

# 2. Prepare manifests
prepare-winget-manifest.bat

# 3. Update version in all 3 YAML files
PackageVersion: 1.3.0

# 4. Update installer URL and hash
# 5. Validate and submit as new version
```

---

## ??? Useful Commands

```powershell
# Search for package
winget search ThemeToggle

# Show package info
winget show YourPublisher.ThemeToggle

# Install
winget install ThemeToggle

# Update
winget upgrade ThemeToggle

# Uninstall
winget uninstall ThemeToggle

# List installed
winget list | findstr ThemeToggle
```

---

## ?? Common Errors

| Error | Solution |
|-------|----------|
| "SHA256 mismatch" | Recalculate hash, update manifest |
| "URL not accessible" | Verify GitHub release is public |
| "Invalid YAML" | Check indentation (spaces, not tabs) |
| "Silent install fails" | Test `/S` flag manually |

---

## ?? Full Documentation

- **Detailed guide:** `WINGET_SUBMISSION_GUIDE.md`
- **Manifest files:** `winget/` folder
- **Preparation script:** `prepare-winget-manifest.bat`

---

**Timeline:** ~1-7 days from submission to approval ??
