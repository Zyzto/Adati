# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Drift/Database
-keep class * extends drift.** { *; }
-keep class * extends drift.runtime.** { *; }
-keep class * extends drift.native.** { *; }
-keep class * extends drift.** { *; }
-keepclassmembers class * {
    @drift.** *;
}

# SQLite
-keep class sqlite3.** { *; }
-keep class sqlite3_flutter_libs.** { *; }

# Riverpod
-keep class * extends riverpod.** { *; }
-keep class * implements riverpod.** { *; }
-keep class * extends flutter_riverpod.** { *; }
-keep class * implements flutter_riverpod.** { *; }

# Easy Localization
-keep class easy_localization.** { *; }

# Shared Preferences
-keep class shared_preferences_android.** { *; }

# Path Provider
-keep class path_provider_android.** { *; }

# File Picker
-keep class file_picker.** { *; }

# Notifications
-keep class flutter_local_notifications.** { *; }

# Package Info
-keep class package_info_plus.** { *; }

# URL Launcher
-keep class url_launcher_android.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep serialization classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep line numbers for stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

