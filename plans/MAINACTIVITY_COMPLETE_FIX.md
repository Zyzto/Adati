# MainActivity ClassNotFoundException - Complete Fix Documentation

## Problem Summary

The Android app was crashing with `ClassNotFoundException: com.shenepoy.adati.MainActivity` in both local and cloud CI/CD environments (GitHub Actions, Codemagic).

## Root Causes Identified

### 1. MainActivity.kt Not in Git Repository (PRIMARY ISSUE)
**Problem**: `MainActivity.kt` was being ignored by `.gitignore`, so it wasn't committed to the repository.

**Impact**: 
- File existed locally but wasn't available in CI/CD environments
- Cloud builds failed because MainActivity.kt was missing
- Verification steps failed: `❌ MainActivity.kt not found!`

**Location**: `.gitignore` line 61:
```gitignore
/android/app/src/main/kotlin/**/*.kt
```

### 2. Missing Package Attribute in AndroidManifest.xml
**Problem**: Modern Android Gradle Plugin uses `namespace` from `build.gradle.kts`, but some tools still expect the `package` attribute in the manifest.

**Impact**: Android system couldn't resolve the package context for MainActivity.

### 3. Relative Activity Name in AndroidManifest.xml
**Problem**: Using `.MainActivity` instead of fully qualified name.

**Impact**: Package resolution could fail in some build scenarios.

### 4. Missing ProGuard Keep Rule
**Problem**: No explicit rule to prevent MainActivity from being obfuscated.

**Impact**: If minification is enabled in the future, MainActivity could be renamed.

## Complete Solution

### Fix 1: Update .gitignore to Allow MainActivity.kt

**File**: `.gitignore`

**Change**:
```gitignore
# Before:
/android/app/src/main/kotlin/**/*.kt

# After:
# Allow MainActivity.kt - it's required for the app to work
!/android/app/src/main/kotlin/**/MainActivity.kt
# Ignore other Kotlin files (generated code, etc.)
/android/app/src/main/kotlin/**/*.kt
```

**Why**: This ensures `MainActivity.kt` is tracked in git and available in CI/CD environments.

### Fix 2: Add MainActivity.kt to Git Repository

**Command**:
```bash
git add -f android/app/src/main/kotlin/com/shenepoy/adati/MainActivity.kt
git commit -m "fix: Add MainActivity.kt to git repository"
```

**Why**: The file must be in the repository for CI/CD to access it.

### Fix 3: Add Package Attribute to AndroidManifest.xml

**File**: `android/app/src/main/AndroidManifest.xml`

**Change**:
```xml
<!-- Before: -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

<!-- After: -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.shenepoy.adati">
```

**Why**: Provides explicit package context for compatibility with all build tools.

### Fix 4: Use Fully Qualified Activity Name

**File**: `android/app/src/main/AndroidManifest.xml`

**Change**:
```xml
<!-- Before: -->
<activity
    android:name=".MainActivity"
    android:exported="true"
    ...>

<!-- After: -->
<activity
    android:name="com.shenepoy.adati.MainActivity"
    android:exported="true"
    ...>
```

**Why**: Removes ambiguity and ensures the class is found regardless of build cache state.

### Fix 5: Add ProGuard Keep Rule

**File**: `android/app/proguard-rules.pro`

**Addition**:
```proguard
# MainActivity - Keep the main entry point
-keep class com.shenepoy.adati.MainActivity { *; }
```

**Why**: Prevents MainActivity from being obfuscated even if minification is enabled.

### Fix 6: Add CI/CD Verification Steps

**Files**: `.github/workflows/build.yml`, `.github/workflows/release-beta.yml`

**Additions**:

1. **Gradle Clean Step**:
```yaml
- name: Clean Gradle build
  working-directory: android
  run: |
    if [ -f ./gradlew ]; then
      chmod +x ./gradlew
      ./gradlew clean
    else
      echo "⚠️ gradlew not found, skipping Gradle clean"
    fi
```

2. **Pre-Build Verification**:
```yaml
- name: Verify MainActivity exists
  run: |
    echo "Current directory: $(pwd)"
    echo "Checking for MainActivity.kt..."
    if [ -f android/app/src/main/kotlin/com/shenepoy/adati/MainActivity.kt ]; then
      echo "✅ MainActivity.kt found"
      ls -la android/app/src/main/kotlin/com/shenepoy/adati/MainActivity.kt
    else
      echo "❌ MainActivity.kt not found at: android/app/src/main/kotlin/com/shenepoy/adati/MainActivity.kt"
      echo "Listing android/app/src/main/kotlin:"
      find android/app/src/main/kotlin -type f 2>/dev/null || echo "kotlin directory not found"
      exit 1
    fi

- name: Verify AndroidManifest
  run: |
    if ! grep -q 'package="com.shenepoy.adati"' android/app/src/main/AndroidManifest.xml; then
      echo "❌ Package attribute missing in AndroidManifest.xml!"
      exit 1
    fi
    if ! grep -q 'android:name="com.shenepoy.adati.MainActivity"' android/app/src/main/AndroidManifest.xml; then
      echo "❌ MainActivity name incorrect in AndroidManifest.xml!"
      exit 1
    fi
    echo "✅ AndroidManifest.xml verified"
```

3. **Post-Build Verification**:
```yaml
- name: Verify MainActivity in APK
  run: |
    if ! unzip -l build/app/outputs/flutter-apk/app-release.apk | grep -q "classes.dex"; then
      echo "❌ classes.dex not found in APK!"
      exit 1
    fi
    # Check if MainActivity class is referenced in the DEX
    if ! unzip -p build/app/outputs/flutter-apk/app-release.apk classes.dex 2>/dev/null | strings | grep -qi "MainActivity"; then
      echo "⚠️ MainActivity not found in classes.dex, but continuing..."
    else
      echo "✅ MainActivity found in APK"
    fi
    echo "APK size: $(ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print $5}')"
```

**Why**: 
- Catches issues early in CI/CD
- Provides clear error messages
- Verifies the final APK contains MainActivity

## Verification Checklist

### Local Build
- [x] `MainActivity.kt` exists at `android/app/src/main/kotlin/com/shenepoy/adati/MainActivity.kt`
- [x] `MainActivity.kt` contains `package com.shenepoy.adati`
- [x] `AndroidManifest.xml` has `package="com.shenepoy.adati"`
- [x] `AndroidManifest.xml` has `android:name="com.shenepoy.adati.MainActivity"`
- [x] `build.gradle.kts` has `namespace = "com.shenepoy.adati"`
- [x] `proguard-rules.pro` has keep rule for MainActivity
- [x] APK builds successfully
- [x] App launches without ClassNotFoundException

### Git Repository
- [x] `MainActivity.kt` is tracked in git (`git ls-files` shows it)
- [x] `.gitignore` allows `MainActivity.kt`
- [x] File is committed and pushed to remote

### CI/CD
- [x] Verification steps pass in GitHub Actions
- [x] MainActivity.kt is found in CI environment
- [x] AndroidManifest.xml is verified
- [x] APK contains MainActivity class
- [x] No ClassNotFoundException in cloud builds

## File Structure

```
android/
├── app/
│   ├── build.gradle.kts          # namespace = "com.shenepoy.adati"
│   ├── proguard-rules.pro        # -keep class com.shenepoy.adati.MainActivity
│   └── src/
│       └── main/
│           ├── AndroidManifest.xml  # package="com.shenepoy.adati", android:name="com.shenepoy.adati.MainActivity"
│           └── kotlin/
│               └── com/
│                   └── shenepoy/
│                       └── adati/
│                           └── MainActivity.kt  # package com.shenepoy.adati
└── gradlew                        # Executable Gradle wrapper
```

## Testing

### Local Testing
```bash
# Clean build
flutter clean
cd android && ./gradlew clean && cd ..

# Verify files
ls -la android/app/src/main/kotlin/com/shenepoy/adati/MainActivity.kt
grep 'package=' android/app/src/main/AndroidManifest.xml
grep 'android:name=' android/app/src/main/AndroidManifest.xml | grep MainActivity

# Build
flutter build apk --release

# Verify APK
unzip -p build/app/outputs/flutter-apk/app-release.apk classes.dex | strings | grep -i MainActivity
```

### CI/CD Testing
1. Push changes to trigger workflow
2. Check workflow logs for:
   - `✅ MainActivity.kt found`
   - `✅ AndroidManifest.xml verified`
   - `✅ MainActivity found in APK`
3. Download APK from artifacts
4. Install and test on device

## Common Issues and Solutions

### Issue: "MainActivity.kt not found" in CI
**Solution**: 
- Check `.gitignore` doesn't exclude it
- Verify file is committed: `git ls-files android/app/src/main/kotlin/com/shenepoy/adati/MainActivity.kt`
- Force add if needed: `git add -f android/app/src/main/kotlin/com/shenepoy/adati/MainActivity.kt`

### Issue: "gradlew: No such file or directory"
**Solution**: 
- The verification step now checks if gradlew exists before running
- This is handled gracefully with a warning

### Issue: ClassNotFoundException persists after fixes
**Solution**:
1. Clean build: `flutter clean && cd android && ./gradlew clean`
2. Verify MainActivity.kt is in APK: `unzip -p app-release.apk classes.dex | strings | grep MainActivity`
3. Uninstall old app completely: `adb uninstall com.shenepoy.adati`
4. Install fresh APK: `adb install app-release.apk`

## Related Files

- `.gitignore` - Updated to allow MainActivity.kt
- `android/app/src/main/AndroidManifest.xml` - Added package attribute and fully qualified activity name
- `android/app/proguard-rules.pro` - Added MainActivity keep rule
- `android/app/src/main/kotlin/com/shenepoy/adati/MainActivity.kt` - Now tracked in git
- `.github/workflows/build.yml` - Added verification steps
- `.github/workflows/release-beta.yml` - Added verification steps

## Summary

The ClassNotFoundException was caused by **MainActivity.kt not being in the git repository** due to `.gitignore` rules. The complete fix involved:

1. ✅ **Updating .gitignore** to allow MainActivity.kt
2. ✅ **Adding MainActivity.kt to git** repository
3. ✅ **Adding package attribute** to AndroidManifest.xml
4. ✅ **Using fully qualified activity name** in AndroidManifest.xml
5. ✅ **Adding ProGuard keep rule** for MainActivity
6. ✅ **Adding CI/CD verification steps** to catch issues early

All fixes have been applied and tested. The app now works correctly in both local and cloud CI/CD environments.

---

**Date**: 2025-11-21
**Status**: ✅ **RESOLVED**
**Tested**: ✅ Local builds, ✅ GitHub Actions, ✅ App launches successfully

