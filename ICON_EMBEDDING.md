# Icon Embedding Guide

Guide for embedding custom icons in ThemeToggle executable.

---

## Current Icon Configuration

**Location**: `Resources\ThemeToggle.ico`
**Embedded in**: `ThemeToggle.exe`
**Resource ID**: `1`

---

## Icon Specifications

| Property | Value |
|----------|-------|
| Format | `.ico` |
| Resolutions | 16x16, 32x32, 48x48, 256x256 |
| Color Depth | 32-bit RGBA |
| Compression | PNG (for 256x256) |
| Maximum Size | ~100 KB |

---

## How Icons Are Embedded

### Build Process

1. **Resource Script** (`ThemeToggle.rc`):
   ```rc
   1 ICON "Resources\\ThemeToggle.ico"
   ```

2. **Resource Compilation**:
   ```cmd
   rc ThemeToggle.rc
   ```

3. **Linking**:
   ```cmd
   link /OUT:ThemeToggle.exe main.obj ... ThemeToggle.res ...
   ```

---

## Changing the Icon

### Step 1: Create or Obtain New Icon

Use icon editor or convert from PNG:
```powershell
# Using ImageMagick
magick convert icon-256.png -define icon:auto-resize=256,128,64,48,32,16 icon.ico
```

### Step 2: Replace Icon File

```cmd
copy your-new-icon.ico Resources\ThemeToggle.ico
```

### Step 3: Rebuild

```cmd
del *.obj *.res 2>nul
build.bat
```

### Step 4: Verify Icon

Check in Windows Explorer Properties and taskbar.

---

## Icon Testing Checklist

- [ ] 16x16 size is clear
- [ ] 32x32 shows proper detail
- [ ] 256x256 is high quality
- [ ] Transparency renders correctly
- [ ] Works on light/dark backgrounds
- [ ] Visible in File Explorer
- [ ] Visible in taskbar

---

## Troubleshooting

### Icon not updating after rebuild

Clear icon cache:
```cmd
ie4uinit.exe -show
taskkill /IM explorer.exe /F
start explorer.exe
```

### Icon shows as generic app icon

Verify resource file exists:
```cmd
dir ThemeToggle.res
build.bat
```

---

## Icon Resources

### Tools
- [Greenfish Icon Editor Pro](http://greenfishsoftware.org/)
- [GIMP](https://www.gimp.org/)
- [ImageMagick](https://imagemagick.org/)

### Online Converters
- [ConvertICO](https://convertico.com/)
- [ICO Convert](https://icoconvert.com/)
