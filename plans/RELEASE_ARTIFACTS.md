# Release Artifacts Guide

This document describes all the artifacts produced by the CI/CD pipeline for each platform.

---

## 📦 Artifacts Produced

### Android

#### 1. **APK File** (Direct Install)
- **File**: `adati-{VERSION}-android.apk`
- **Format**: `.apk` (NOT zipped)
- **Size**: ~50-70 MB
- **Usage**: Direct installation on Android devices
- **Installation**:
  ```bash
  adb install adati-{VERSION}-android.apk
  # Or transfer to device and install via file manager
  ```

#### 2. **AAB File** (Google Play)
- **File**: `adati-{VERSION}-android.aab`
- **Format**: `.aab` (Android App Bundle)
- **Size**: ~40-60 MB (smaller than APK)
- **Usage**: Upload to Google Play Store
- **Note**: Cannot be installed directly on devices

---

### Linux

#### 3. **AppImage** (Portable)
- **File**: `adati-{VERSION}-linux-x86_64.AppImage`
- **Format**: `.AppImage` (NOT zipped)
- **Size**: ~80-100 MB
- **Architecture**: x86_64 (64-bit Intel/AMD)
- **Requirements**: GLIBC 2.31+ (Ubuntu 20.04+, most modern distros)
- **Installation**:
  ```bash
  chmod +x adati-{VERSION}-linux-x86_64.AppImage
  ./adati-{VERSION}-linux-x86_64.AppImage
  ```
- **Features**:
  - No installation required
  - Portable (can run from USB drive)
  - Self-contained (includes all dependencies)

---

### Windows

#### 4. **ZIP Package** (Recommended)
- **File**: `adati-{VERSION}-windows-x64.zip`
- **Format**: `.zip` archive
- **Size**: ~30-40 MB (compressed)
- **Architecture**: x64 (64-bit)
- **Contents**:
  ```
  adati-{VERSION}-windows-x64.zip
  ├── adati.exe           (main executable)
  ├── flutter_windows.dll (Flutter engine)
  ├── *.dll               (other dependencies)
  └── data/               (Flutter assets)
  ```
- **Installation**:
  ```powershell
  # Extract ZIP
  Expand-Archive -Path adati-{VERSION}-windows-x64.zip -DestinationPath adati
  
  # Run executable
  cd adati
  .\adati.exe
  ```

#### 5. **EXE File** (Standalone Reference)
- **File**: `adati-{VERSION}-windows-x64.exe`
- **Format**: `.exe` (NOT zipped)
- **Size**: ~200 KB (just the executable)
- **⚠️ Important**: This is just the executable. It **requires** the DLLs and data folder from the ZIP to run.
- **Usage**: For reference or if you want to replace the exe in an existing installation
- **Installation**: Extract the ZIP package and use the exe from there

---

## 📊 Artifact Comparison

| Platform | Format | Compressed | Standalone | Size |
|----------|--------|------------|------------|------|
| Android APK | `.apk` | ❌ No | ✅ Yes | ~60 MB |
| Android AAB | `.aab` | ❌ No | ⚠️ Play Store only | ~50 MB |
| Linux | `.AppImage` | ❌ No | ✅ Yes | ~90 MB |
| Windows ZIP | `.zip` | ✅ Yes | ✅ Yes (after extract) | ~35 MB |
| Windows EXE | `.exe` | ❌ No | ❌ No (needs DLLs) | ~200 KB |

---

## 🎯 Which File Should I Use?

### For End Users:
- **Android**: Use the **APK** file for direct installation
- **Linux**: Use the **AppImage** file
- **Windows**: Use the **ZIP** file (extract and run)

### For Distribution:
- **Play Store**: Use the **AAB** file
- **GitHub Releases**: All files are automatically uploaded
- **Direct Download**: Provide APK (Android), AppImage (Linux), ZIP (Windows)

### For Developers:
- **Testing**: APK (Android), AppImage (Linux), ZIP (Windows)
- **Debugging**: All artifacts include debug symbols
- **CI/CD**: AAB for Play Store automation

---

## 📝 File Naming Convention

All artifacts follow this pattern:
```
adati-{VERSION}-{platform}-{architecture}.{extension}
```

Examples:
- `adati-0.2.1-android.apk`
- `adati-0.2.1-android.aab`
- `adati-0.2.1-linux-x86_64.AppImage`
- `adati-0.2.1-windows-x64.zip`
- `adati-0.2.1-windows-x64.exe`

---

## 🚀 GitHub Release Assets

When a release is created, all artifacts are automatically attached:

```
📦 GitHub Release: v0.2.1
├── 📄 adati-0.2.1-android.apk          (Android APK)
├── 📄 adati-0.2.1-android.aab          (Google Play)
├── 📄 adati-0.2.1-linux-x86_64.AppImage (Linux)
├── 📄 adati-0.2.1-windows-x64.zip      (Windows Package)
└── 📄 adati-0.2.1-windows-x64.exe      (Windows Executable)
```

---

## 🔄 CI/CD Workflows

### Build Workflow (`build.yml`)
- Triggered on: Push to main/master, PRs
- Produces: Debug builds only
- Artifacts: Retained for 7 days

### Beta Release Workflow (`release-beta.yml`)
- Triggered on: Version tags (`v*`), manual dispatch
- Produces: Release builds for all platforms
- Artifacts: Retained for 30 days
- Deploys: Play Store beta track
- Creates: GitHub prerelease

### Production Release Workflow (`release-production.yml`)
- Triggered on: Manual dispatch (with approval)
- Promotes: Beta release to production
- Updates: GitHub release (removes prerelease flag)
- Deploys: Play Store production track

---

## ⚙️ Build Process

### Android
```yaml
1. Setup Java 17 + Flutter
2. Run flutter pub get
3. Generate code (build_runner)
4. Clean build directory
5. Build APK: flutter build apk --release
6. Build AAB: flutter build appbundle --release
7. Upload artifacts
```

### Linux
```yaml
1. Setup Flutter
2. Install dependencies (GTK3, etc.)
3. Run flutter pub get
4. Generate code (build_runner)
5. Clean build directory
6. Build: flutter build linux --release
7. Create AppImage structure
8. Package with AppImageTool
9. Upload artifact
```

### Windows
```yaml
1. Setup Flutter
2. Run flutter pub get
3. Generate code (build_runner)
4. Clean build directory
5. Build: flutter build windows --release
6. Create ZIP with all files
7. Copy standalone EXE
8. Upload both artifacts
```

---

## 🔍 Artifact Contents

### APK Contents:
- Compiled Dart code (AOT)
- Flutter engine (ARM/ARM64)
- Assets (images, fonts, translations)
- Native libraries
- AndroidManifest.xml

### AppImage Contents:
- Compiled Dart code (AOT)
- Flutter engine (x64)
- GTK3 dependencies
- Assets
- Desktop entry file
- Icon

### Windows ZIP Contents:
- `adati.exe` - Main executable
- `flutter_windows.dll` - Flutter engine
- Other DLLs (dependencies)
- `data/` folder - Flutter assets
- `data/icudtl.dat` - ICU data

---

## 📏 Size Optimization

Current build sizes are reasonable, but can be optimized further:

### Already Applied:
- ✅ `--release` flag (AOT compilation, optimizations)
- ✅ `--no-tree-shake-icons` disabled in release
- ✅ Separate debug symbols for Android

### Future Optimizations:
- [ ] Enable `--split-debug-info` for crash reporting
- [ ] Enable `--obfuscate` for release builds
- [ ] Compress assets with better algorithms
- [ ] Use dynamic feature modules (Android)
- [ ] Enable app bundles for size reduction

---

## 🐛 Debugging Artifacts

All artifacts include debug information:
- **Android**: Separate symbol files available
- **Linux**: Built with debug symbols
- **Windows**: PDB files in build directory

For crash reporting, upload symbol files to:
- Firebase Crashlytics (Android)
- Sentry (All platforms)
- Custom crash reporting service

---

## ✅ Quality Checks

Each artifact goes through:
1. ✅ Compilation check
2. ✅ Asset bundling verification
3. ✅ Code signing (Android release)
4. ✅ Size verification
5. ✅ Upload to GitHub/Play Store

---

## 📚 Additional Documentation

- **Deployment Guide**: `.github/DEPLOYMENT.md`
- **Testing Procedures**: `.github/TESTING.md`
- **Security Setup**: `.github/SECURITY_SETUP.md`
- **CI/CD Migration**: `.github/MIGRATION_SUMMARY.md`
- **Build Fix Details**: `.github/CI_BUILD_FIX.md`

---

**Last Updated**: 2025-11-20  
**Version**: 0.2.1+

