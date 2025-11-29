import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.shenepoy.adati"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.shenepoy.adati"
        minSdk = 29  // Android 10 (API 29)
        targetSdk = 36  // Android 15
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Support both CI/CD (environment variables) and local builds (key.properties)
        val keystorePropertiesFile = rootProject.file("key.properties")
        val hasKeystoreFile = keystorePropertiesFile.exists()
        val hasEnvVars = System.getenv("KEYSTORE_FILE") != null
        
        if (hasKeystoreFile || hasEnvVars) {
            create("release") {
                if (hasEnvVars) {
                    // CI/CD: Use environment variables from GitHub Secrets
                    // The keystore file is created in android/app/release.keystore
                    storeFile = file("release.keystore")
                    storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
                    keyAlias = System.getenv("KEY_ALIAS") ?: ""
                    keyPassword = System.getenv("KEY_PASSWORD") ?: ""
                } else {
                    // Local: Use key.properties file
                    // For local builds, create a key.properties file with:
                    // storeFile=path/to/keystore.jks
                    // storePassword=your_store_password
                    // keyAlias=your_key_alias
                    // keyPassword=your_key_password
                    val keystoreProperties = Properties()
                    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                    storeFile = file(keystoreProperties["storeFile"] as String)
                    storePassword = keystoreProperties["storePassword"] as String
                    keyAlias = keystoreProperties["keyAlias"] as String
                    keyPassword = keystoreProperties["keyPassword"] as String
                }
            }
        }
    }

    buildTypes {
        debug {
            // Use different package ID for debug builds to prevent data conflicts
            // Debug builds will use: com.shenepoy.adati.debug
            applicationIdSuffix = ".debug"
            
            // Optional: Use different app name for debug builds
            resValue("string", "app_name", "Adati Debug")
        }
        release {
            // Use release signing config if it exists, otherwise fall back to debug
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            
            // Enable debug symbols for crash reporting (doesn't affect release optimization)
            isDebuggable = false
            // Enable code minification and resource shrinking for smaller app size
            isMinifyEnabled = true
            isShrinkResources = true
            
            // ProGuard rules for code optimization and obfuscation
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Generate debug symbols for crash reporting
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
