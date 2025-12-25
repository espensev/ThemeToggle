# Repository Cleanup Checklist

Action checklist for cleaning up the ThemeToggle repository.

---

## Pre-Flight

- [ ] Backup: `git commit -am "Pre-cleanup checkpoint"`
- [ ] Verify `Resources\ThemeToggle.ico` exists
- [ ] Close Visual Studio and File Explorer windows

---

## Phase 1: Cleanup Legacy Files

```cmd
scripts\cleanup-workspace.bat
```

**Removes:**
- Legacy temporary build artifacts (RC*, RD*, *.aps, *.obj, *.res)

**Verify after:**
- [ ] `Resources\ThemeToggle.ico` still exists
- [ ] `ThemeToggle.exe` still works
- [ ] Check `git status`

---

## Phase 2: Update WinGet Manifests

```cmd
scripts\rename-winget-manifests.bat
```

**Renames:**
- `YourPublisher.*` ? `SevIQ.*`

**Manual actions:**
- [ ] Update SHA256 hash in installer manifest
- [ ] Update release date

---

## Phase 3: Validation

```cmd
scripts\validate-repository.bat
```

**Verify:**
- [ ] Build succeeds: `build.bat`
- [ ] Executable works: `ThemeToggle.exe /dark`
- [ ] Icon displays correctly

---

## Phase 4: Git Commit

```cmd
git status
git add .
git commit -m "Refactor: Repository reorganization and cleanup"
git push origin main
```

---

## Final Verification

- [ ] Repository builds successfully
- [ ] No build artifacts committed
- [ ] WinGet manifests updated
- [ ] Documentation complete
- [ ] Changes pushed to GitHub

---

**Need Help?** Check `AUTOMATION_GUIDE.md` or `ICON_EMBEDDING.md`
