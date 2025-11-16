# Android Release Signing Guide

This guide explains how to set up signing for release builds of the Adati app.

## Prerequisites

- Java KeyStore (JKS) file for signing
- Keystore password
- Key alias
- Key password

## Creating a Keystore

If you don't have a keystore yet, create one using:

```bash
keytool -genkey -v -keystore ~/adati-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias adati
```

**Important**: 
- Store the keystore file in a secure location
- Remember your passwords - you'll need them for every release
- Keep a backup of your keystore file

## Setting Up Signing Configuration

1. Copy the example key properties file:
   ```bash
   cp android/key.properties.example android/key.properties
   ```

2. Edit `android/key.properties` and fill in your actual values:
   ```properties
   storeFile=/absolute/path/to/your/keystore.jks
   storePassword=your_store_password
   keyAlias=your_key_alias
   keyPassword=your_key_password
   ```

3. **Important**: The `key.properties` file is already in `.gitignore` - never commit it to version control!

## Building a Release APK

Once the signing configuration is set up, build a release APK:

```bash
flutter build apk --release
```

The signed APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Building a Release App Bundle (AAB)

For Google Play Store, build an App Bundle:

```bash
flutter build appbundle --release
```

The signed AAB will be located at:
```
build/app/outputs/bundle/release/app-release.aab
```

## Troubleshooting

### Signing config not found
If you get an error about signing config, make sure:
- `android/key.properties` exists
- All paths in `key.properties` are absolute paths
- The keystore file exists at the specified path

### Build falls back to debug signing
If the release build uses debug signing, check:
- `key.properties` file exists and is readable
- All properties are correctly set
- The keystore file path is correct

## Security Best Practices

1. **Never commit `key.properties`** - It's already in `.gitignore`
2. **Never commit your keystore file** - Keep it secure and backed up
3. **Use environment variables for CI/CD** - For automated builds, use secure environment variables instead of `key.properties`
4. **Rotate keys if compromised** - If your keystore is ever compromised, create a new one and update your app

## CI/CD Integration

For GitHub Actions or other CI/CD systems, use environment variables or secrets instead of `key.properties`:

```kotlin
// In build.gradle.kts, you can also use environment variables:
storeFile = file(System.getenv("KEYSTORE_FILE") ?: keystoreProperties["storeFile"] as String)
storePassword = System.getenv("KEYSTORE_PASSWORD") ?: keystoreProperties["storePassword"] as String
keyAlias = System.getenv("KEY_ALIAS") ?: keystoreProperties["keyAlias"] as String
keyPassword = System.getenv("KEY_PASSWORD") ?: keystoreProperties["keyPassword"] as String
```

