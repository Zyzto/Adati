# Settings Framework Example

This example demonstrates how to use the `flutter_settings_framework` package in a Flutter app.

## Running the Example

```bash
cd example
flutter pub get
flutter run
```

## What the Example Shows

The example app demonstrates:

1. **Setting Definitions**: How to define different types of settings (Bool, Enum, Color, Double)
2. **Registry Creation**: How to create a settings registry with sections
3. **Initialization**: How to initialize the framework with Riverpod
4. **UI Components**: Using pre-built settings tiles
5. **Search**: Multi-language search functionality
6. **Reactive Updates**: Watching setting values with Riverpod

## Features Demonstrated

- ✅ Boolean settings with SwitchSettingsTile
- ✅ Enum settings with SelectSettingsTile
- ✅ Color settings with ColorSettingsTile
- ✅ Double settings with SliderSettingsTile
- ✅ Settings sections and organization
- ✅ Search functionality
- ✅ Reactive value watching
- ✅ Setting value updates

## UI Features

The example app includes:
- **Settings List**: Organized by sections
- **Search Bar**: Search settings across all languages
- **Setting Tiles**: Pre-built UI components for each setting type
- **Current Values Display**: Shows all current setting values
- **Theme Integration**: Settings affect app theme

## Try It Out

1. Run the app
2. Toggle settings to see reactive updates
3. Use the search bar to find settings
4. Change theme mode, colors, and other settings
5. Observe how settings persist across app restarts
