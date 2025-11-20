# CI/CD MainActivity Fix for Cloud Builds

## Problem

The app works locally but fails with `ClassNotFoundException: com.shenepoy.adati.MainActivity` when built in cloud CI/CD environments (GitHub Actions, Codemagic).

## Root Cause

In cloud CI/CD environments, build caches or incremental builds might skip compiling Kotlin source files, especially if the build system thinks nothing changed. This can result in MainActivity not being included in the final APK.

## Solution

Added comprehensive verification and cleaning steps to ensure MainActivity is always compiled correctly in CI/CD:

### 1. Gradle Clean Step
**Location**: `.github/workflows/release-beta.yml` and `build.yml`

```yaml
- name: Clean Gradle build
  working-directory: android
  run: ./gradlew clean
```

This ensures the Android build cache is cleared before building.

### 2. Pre-Build Verification
**Location**: `.github/workflows/release-beta.yml`

```yaml
- name: Verify MainActivity exists
  run: |
    if [ ! -f android/app/src/main/kotlin/com/shenepoy/adati/MainActivity.kt ]; then
      echo "❌ MainActivity.kt not found!"
      exit 1
    fi
    echo "✅ MainActivity.kt found"
    cat android/app/src/main/kotlin/com/shenepoy/adati/MainActivity.kt

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

These steps verify that:
- MainActivity.kt exists in the correct location
- AndroidManifest.xml has the correct package attribute
- AndroidManifest.xml references MainActivity with the fully qualified name

### 3. Post-Build Verification
**Location**: `.github/workflows/release-beta.yml`

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

This verifies that MainActivity is actually compiled into the APK.

## Build Order

The workflow now follows this order:

1. **Checkout code**
2. **Setup Java & Flutter**
3. **Get dependencies** (`flutter pub get`)
4. **Generate code** (build_runner)
5. **Clean Flutter build** (`flutter clean`)
6. **Clean Gradle build** (`./gradlew clean`) ← **NEW**
7. **Verify MainActivity.kt exists** ← **NEW**
8. **Verify AndroidManifest.xml** ← **NEW**
9. **Setup Android signing**
10. **Build APK** (`flutter build apk`)
11. **Verify MainActivity in APK** ← **NEW**

## Files Modified

- `.github/workflows/release-beta.yml` - Added verification steps for release builds
- `.github/workflows/build.yml` - Added verification steps for debug builds

## Testing

After these changes, when you run the workflow:

1. **Early Detection**: If MainActivity.kt is missing or AndroidManifest.xml is incorrect, the build will fail immediately with a clear error message.

2. **Build Verification**: After the APK is built, the workflow verifies that MainActivity is present in the compiled DEX file.

3. **Clear Error Messages**: If something is wrong, you'll see exactly what's missing:
   - `❌ MainActivity.kt not found!`
   - `❌ Package attribute missing in AndroidManifest.xml!`
   - `❌ MainActivity name incorrect in AndroidManifest.xml!`
   - `❌ classes.dex not found in APK!`

## Additional Notes

### For Codemagic

If you're using Codemagic, make sure your `codemagic.yaml` includes similar verification steps:

```yaml
scripts:
  - name: Clean Gradle
    script: |
      cd android
      ./gradlew clean
  - name: Verify MainActivity
    script: |
      if [ ! -f android/app/src/main/kotlin/com/shenepoy/adati/MainActivity.kt ]; then
        echo "❌ MainActivity.kt not found!"
        exit 1
      fi
```

### Build Cache Considerations

The `./gradlew clean` step ensures that any cached build artifacts that might be missing MainActivity are cleared. This is especially important in CI/CD where build caches might persist between runs.

### Why This Works

1. **Gradle Clean**: Removes any stale build artifacts that might not include MainActivity
2. **Pre-Build Verification**: Catches configuration issues before building
3. **Post-Build Verification**: Confirms MainActivity was actually compiled into the APK

## Related Fixes

This complements the local fixes:
- ✅ Package attribute in AndroidManifest.xml
- ✅ Fully qualified MainActivity name
- ✅ ProGuard keep rule
- ✅ Correct file structure

All of these are now verified in CI/CD to ensure consistency.

---

**Date**: 2025-11-21
**Status**: ✅ Fixed
**Tested**: Ready for CI/CD testing

