# Release Artifacts Guide

This document describes all artifacts produced by the CI/CD pipeline and how to troubleshoot artifact issues.

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

#### 4. **ZIP File** (Full Package)
- **File**: `adati-{VERSION}-windows-x64.zip`
- **Format**: `.zip` (compressed archive)
- **Size**: ~60-80 MB
- **Contents**: Complete application with all DLLs and dependencies
- **Usage**: Recommended for most users
- **Installation**:
  1. Download the ZIP file
  2. Extract to a folder (e.g., `C:\Program Files\Adati\`)
  3. Run `adati.exe` from the extracted folder
- **Note**: Contains all required DLLs and runtime libraries

#### 5. **EXE File** (Standalone)
- **File**: `adati-{VERSION}-windows-x64.exe`
- **Format**: `.exe` (standalone executable)
- **Size**: ~40-50 MB
- **Usage**: Reference/portable version
- **Note**: Requires DLLs from the ZIP file to run properly
- **Recommendation**: Use the ZIP file instead for full functionality

---

## 📍 Where to Find Artifacts

### Option 1: GitHub Release Page (Recommended)
**Location**: `https://github.com/{owner}/{repo}/releases`

This is where **all release artifacts** are attached:
- ✅ Android APK
- ✅ Android AAB  
- ✅ Linux AppImage
- ✅ Windows ZIP
- ✅ Windows EXE

**How to access:**
1. Go to your repository on GitHub
2. Click "Releases" in the right sidebar
3. Click on the release (e.g., "Beta 0.2.1")
4. Scroll down to "Assets" section
5. You should see all 5 files listed

---

### Option 2: GitHub Actions Artifacts
**Location**: `https://github.com/{owner}/{repo}/actions`

This shows **intermediate build artifacts** (before release creation):
- Individual job artifacts
- Debug builds
- Build logs

**How to access:**
1. Go to your repository on GitHub
2. Click "Actions" tab
3. Click on a workflow run
4. Click on a job (e.g., "Build Android")
5. Scroll down to "Artifacts" section

**Note**: These are separate artifacts per job. The release combines them.

---

## 🔍 Troubleshooting: Missing Artifacts

### Why You Might Only See 1 Artifact

#### Scenario 1: Looking at Build Workflow
**Problem**: The `build.yml` workflow only builds Android debug APK

**Solution**: Use the `release-beta.yml` workflow instead (triggered by tags)

---

#### Scenario 2: Release Not Created Yet
**Problem**: The release creation job hasn't run or failed

**Check**:
1. Go to Actions → "Beta Release" workflow
2. Check if `create-github-prerelease` job ran
3. Look for errors in the logs

**Common causes**:
- Build jobs failed (Linux/Windows builds)
- Missing permissions
- Tag not created properly

---

#### Scenario 3: Some Build Jobs Failed
**Problem**: Linux or Windows builds failed, so artifacts weren't uploaded

**Check**:
1. Go to Actions → "Beta Release" workflow
2. Check each build job:
   - `build-android` ✅
   - `build-linux` ❌ (might have failed)
   - `build-windows` ❌ (might have failed)

**Common failure reasons**:
- Missing dependencies (Linux)
- Build errors
- Timeout issues
- Flutter version incompatibility

---

#### Scenario 4: Artifacts Not Downloaded
**Problem**: The release job couldn't download artifacts from other jobs

**Check logs for**:
```
=== Downloaded Artifacts ===
=== Artifact Directories ===
⚠️ Missing artifacts: Linux AppImage, Windows ZIP
```

**Solution**: The workflow now has better error handling and will show what's missing.

---

## 🛠️ How to Fix Missing Artifacts

### Fix 1: Trigger a New Release
```bash
# Create and push a version tag
git tag v0.2.1
git push origin v0.2.1
```

This triggers the `release-beta.yml` workflow which:
1. Builds all platforms
2. Uploads artifacts
3. Creates GitHub release with all artifacts

---

### Fix 2: Check Build Job Logs

**For Linux build failures:**
```yaml
# Check if dependencies are installed
- name: Install Linux dependencies
  run: |
    sudo apt-get update
    sudo apt-get install -y cmake ninja-build libgtk-3-dev libblkid-dev liblzma-dev
```

**For Windows build failures:**
- Check PowerShell errors
- Verify Flutter Windows support
- Check disk space

---

### Fix 3: Manual Release Creation

If automated release fails, you can manually create one:

1. **Download artifacts from Actions:**
   - Go to Actions → Latest workflow run
   - Download each artifact:
     - `android-apk-release`
     - `android-aab-release`
     - `linux-appimage`
     - `windows-zip`
     - `windows-exe`

2. **Rename files:**
   ```bash
   # Rename to match release naming
   mv app-release.apk adati-0.2.1-android.apk
   mv app-release.aab adati-0.2.1-android.aab
   mv adati-x86_64.AppImage adati-0.2.1-linux-x86_64.AppImage
   mv adati-*-windows-x64.zip adati-0.2.1-windows-x64.zip
   mv adati-*-windows-x64.exe adati-0.2.1-windows-x64.exe
   ```

3. **Create GitHub Release:**
   - Go to Releases → "Draft a new release"
   - Tag: `v0.2.1`
   - Title: "Beta 0.2.1"
   - Upload all 5 files
   - Mark as "Pre-release"
   - Publish

---

## 📊 Expected Artifacts

### From `build.yml` (CI builds):
- ✅ `android-debug-apk` (1 file)

### From `release-beta.yml` (Release builds):
- ✅ `android-apk-release` (1 file)
- ✅ `android-aab-release` (1 file)
- ✅ `linux-appimage` (1 file)
- ✅ `windows-zip` (1 file)
- ✅ `windows-exe` (1 file)

**Total**: 5 artifacts → Combined into GitHub Release

---

## 🔍 Debugging Steps

### Step 1: Check Workflow Status
```bash
# Check if workflow ran
gh run list --workflow=release-beta.yml

# View latest run
gh run view --web
```

### Step 2: Check Artifact Uploads
Look for these log messages:
```
✅ Upload Release APK
✅ Upload Release App Bundle
✅ Upload AppImage
✅ Upload Windows ZIP
✅ Upload Windows EXE
```

### Step 3: Check Artifact Downloads
Look for these log messages:
```
=== Downloaded Artifacts ===
✅ Android APK prepared
✅ Android AAB prepared
✅ Linux AppImage prepared
✅ Windows ZIP prepared
✅ Windows EXE prepared
```

### Step 4: Check Release Creation
Look for:
```
✅ Create Prerelease
Release created: v0.2.1
```

---

## 📝 Quick Checklist

- [ ] Are you looking at the **GitHub Release page** (not Actions artifacts)?
- [ ] Did you create a **version tag** (e.g., `v0.2.1`)?
- [ ] Did the **release-beta workflow** run?
- [ ] Did all **3 build jobs** succeed?
- [ ] Did the **create-github-prerelease** job run?
- [ ] Check the **workflow logs** for errors

---

## 🚀 Next Steps

1. **Check the latest workflow run:**
   - Go to Actions → "Beta Release"
   - Click on the latest run
   - Check each job status

2. **Review the logs:**
   - Look for "Prepare release artifacts" step
   - Check for missing artifacts warnings
   - Verify all artifacts were found

3. **If artifacts are missing:**
   - Check which build jobs failed
   - Review error messages
   - Fix the build issues
   - Re-run the workflow

---

**Last Updated**: 2025-11-21

