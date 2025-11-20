# Android MainActivity ClassNotFoundException Fix

## Problem

The Android app was crashing with:
```
java.lang.ClassNotFoundException: Didn't find class "com.shenepoy.adati.MainActivity"
```

## Root Cause

The `AndroidManifest.xml` was using a relative reference `.MainActivity` which relies on the package/namespace being correctly merged during the build process. In some cases, especially after changing package names or with build cache issues, this relative reference doesn't resolve correctly.

## Solution

### 1. Changed Manifest to Use Fully Qualified Name

**Before:**
```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    ...>
```

**After:**
```xml
<activity
    android:name="com.shenepoy.adati.MainActivity"
    android:exported="true"
    ...>
```

**File**: `android/app/src/main/AndroidManifest.xml`

### 2. Added ProGuard Keep Rule

Added explicit keep rule to prevent MainActivity from being obfuscated (even though minifyEnabled is false, this is good practice):

```proguard
# MainActivity - Keep the main entry point
-keep class com.shenepoy.adati.MainActivity { *; }
```

**File**: `android/app/proguard-rules.pro`

## Why This Works

1. **Fully Qualified Name**: Using `com.shenepoy.adati.MainActivity` instead of `.MainActivity` removes any ambiguity about which class to load. The Android system can directly find the class without relying on package resolution.

2. **ProGuard Protection**: The keep rule ensures that even if obfuscation is enabled in the future, MainActivity will never be renamed or removed.

3. **Build Cache Independence**: This fix works regardless of build cache state, making builds more reliable.

## Verification

The following files are correctly configured:

- ✅ `android/app/src/main/AndroidManifest.xml` - Uses fully qualified name
- ✅ `android/app/src/main/kotlin/com/shenepoy/adati/MainActivity.kt` - Package matches
- ✅ `android/app/build.gradle.kts` - namespace = "com.shenepoy.adati"
- ✅ `android/app/proguard-rules.pro` - Keep rule added

## Additional Steps for Clean Build

If you still encounter issues after this fix:

1. **Clean the build:**
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   ```

2. **Rebuild:**
   ```bash
   flutter build apk --release
   ```

3. **Uninstall old app** from device completely before installing new build

4. **Verify the APK** contains MainActivity:
   ```bash
   # Extract and check
   unzip -l build/app/outputs/flutter-apk/app-release.apk | grep MainActivity
   ```

## Related Files

- `android/app/src/main/AndroidManifest.xml` - Main manifest
- `android/app/src/debug/AndroidManifest.xml` - Debug-only permissions (no activity)
- `android/app/src/profile/AndroidManifest.xml` - Profile-only permissions (no activity)
- `android/app/src/main/kotlin/com/shenepoy/adati/MainActivity.kt` - MainActivity class
- `android/app/build.gradle.kts` - Build configuration with namespace

---

**Date**: 2025-11-20
**Issue**: ClassNotFoundException for MainActivity
**Status**: ✅ Fixed

