# Settings Implementation Documentation

## Overview

The Adati app has a comprehensive settings system that allows users to customize their experience. The settings are organized into modular components, use Riverpod for state management, and persist data using SharedPreferences.

## Architecture

### High-Level Structure

```
lib/features/settings/
├── pages/
│   └── settings_page.dart          # Main settings UI
├── providers/
│   └── settings_providers.dart     # Riverpod state management
├── widgets/
│   ├── settings_section.dart       # Reusable section widget
│   ├── settings_dialogs.dart       # Generic dialog helpers
│   ├── sections/                   # Modular section widgets
│   │   ├── general_section.dart
│   │   ├── appearance_section.dart
│   │   ├── display_section.dart
│   │   ├── date_time_section.dart
│   │   ├── notifications_section.dart
│   │   ├── tags_section.dart
│   │   ├── data_section.dart
│   │   ├── advanced_section.dart
│   │   └── about_section.dart
│   └── dialogs/                    # Specialized dialog helpers
│       ├── about_dialogs.dart
│       ├── data_dialogs.dart
│       ├── advanced_dialogs.dart
│       ├── appearance_dialogs.dart
│       └── display_dialogs.dart
└── utils/
    └── settings_formatters.dart    # Display name formatters

lib/core/services/
└── preferences_service.dart        # SharedPreferences wrapper
```

## Core Components

### 1. PreferencesService (`lib/core/services/preferences_service.dart`)

**Purpose:** Central service for persisting and retrieving user preferences using SharedPreferences.

**Key Features:**
- Static methods for easy access throughout the app
- Type-safe getters and setters
- Consistent key naming convention
- Default values for all settings

**Example:**
```dart
class PreferencesService {
  static const String _keyThemeMode = 'theme_mode';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? getThemeMode() => _prefs!.getString(_keyThemeMode);
  
  static Future<bool> setThemeMode(String mode) async {
    return _prefs!.setString(_keyThemeMode, mode);
  }
}
```

**All Settings Keys:**
- Theme & Appearance: `theme_mode`, `theme_color`, `font_size_scale`, `icon_size`, `day_square_size`
- Display: `habits_layout_mode`, `show_descriptions`, `compact_cards`, `show_percentage`
- Timelines: `timeline_days`, `modal_timeline_days`, `habit_card_timeline_days`, `timeline_spacing`
- Colors: `calendar_completion_color`, `habit_card_completion_color`, `streak_color_scheme`
- Card Style: `card_border_radius`, `card_elevation`, `card_spacing`
- Date & Time: `date_format`, `first_day_of_week`, `language`
- Notifications: `notifications_enabled`, `notification_time`, `show_percentage_in_notification`
- Advanced: `bad_habit_logic_mode`, `enable_crash_reports`

### 2. Settings Providers (`lib/features/settings/providers/settings_providers.dart`)

**Purpose:** Reactive state management using Riverpod. Connects UI to PreferencesService.

**Architecture Pattern:**
Each setting has three components:
1. **Notifier Class** - Manages state and updates
2. **Notifier Provider** - Provides access to the notifier
3. **Value Provider** - Provides reactive access to the current value

**Example:**
```dart
// 1. Notifier Class
class ThemeModeNotifier {
  ThemeMode _mode;

  ThemeModeNotifier() : _mode = _getInitialThemeMode();

  ThemeMode get mode => _mode;

  Future<void> setThemeMode(ThemeMode mode) async {
    _mode = mode;
    await PreferencesService.setThemeMode(mode.toString());
  }
}

// 2. Notifier Provider
final themeModeNotifierProvider = Provider<ThemeModeNotifier>((ref) {
  return ThemeModeNotifier();
});

// 3. Value Provider (for reactive watching)
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeModeNotifierProvider).mode;
});
```

**Usage in UI:**
```dart
// Read value
final themeMode = ref.watch(themeModeProvider);

// Update value
final notifier = ref.read(themeModeNotifierProvider);
await notifier.setThemeMode(ThemeMode.dark);
ref.invalidate(themeModeNotifierProvider); // Trigger rebuild
```

### 3. Settings Page (`lib/features/settings/pages/settings_page.dart`)

**Purpose:** Main UI that orchestrates all settings sections.

**Key Features:**
- Search functionality
- Collapsible sections using ExpansionTile
- Independent expansion state for each section
- Modular section integration
- Responsive layout

**Structure:**
```dart
class SettingsPage extends ConsumerStatefulWidget {
  // Expansion state management
  bool _isGeneralExpanded = false;
  bool _isAppearanceExpanded = false;
  // ... etc

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(/* Search bar */),
      body: ListView(
        children: [
          // Each section as ExpansionTile
          _buildCollapsibleSection(
            context: context,
            title: 'general'.tr(),
            icon: Icons.settings,
            isExpanded: _isGeneralExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _isGeneralExpanded = expanded);
            },
            children: [
              GeneralSectionContent(/* ... */),
            ],
          ),
          // ... more sections
        ],
      ),
    );
  }
}
```

### 4. Section Widgets (`lib/features/settings/widgets/sections/`)

**Purpose:** Modular, self-contained widgets for each settings category.

**Benefits:**
- Improved maintainability
- Better code organization
- Reusability
- Easier testing
- Reduced file size

**Pattern:**
Each section widget:
1. Takes dialog callback functions as parameters
2. Watches relevant providers
3. Returns a Column of ListTiles and SwitchListTiles
4. Handles its own layout and sub-sections

**Example (General Section):**
```dart
class GeneralSectionContent extends ConsumerWidget {
  final Function(BuildContext) showLanguageDialog;
  final Function(BuildContext, WidgetRef) showThemeDialog;
  final Function(BuildContext, WidgetRef) showThemeColorDialog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = PreferencesService.getLanguage() ?? 'en';
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.language),
          title: Text('language'.tr()),
          subtitle: Text(SettingsFormatters.getLanguageName(currentLanguage)),
          onTap: () => showLanguageDialog(context),
        ),
        // ... more settings
      ],
    );
  }
}
```

### 5. Settings Formatters (`lib/features/settings/utils/settings_formatters.dart`)

**Purpose:** Utility class for formatting setting values into user-friendly display strings.

**All Formatters:**
```dart
class SettingsFormatters {
  static String getLanguageName(String? code) { /* en → English */ }
  static String getThemeName(ThemeMode mode) { /* ThemeMode.dark → Dark */ }
  static String getDaySquareSizeName(String size) { /* large → Large */ }
  static String getDateFormatName(String format) { /* dd/MM/yyyy → DD/MM/YYYY */ }
  static String getFirstDayOfWeekName(int day) { /* 0 → Sunday */ }
  static String getCheckboxStyleName(String style) { /* square → Square */ }
  static String getIconSizeName(String size) { /* medium → Medium */ }
  static String getProgressIndicatorStyleName(String style) { /* circular → Circular */ }
  static String getStreakColorSchemeName(String scheme) { /* vibrant → Vibrant */ }
  static String getFontSizeScaleName(String scale) { /* normal → Normal */ }
}
```

### 6. Dialog Helpers

#### Generic Dialogs (`lib/features/settings/widgets/settings_dialogs.dart`)

**Purpose:** Reusable dialog patterns for common UI interactions.

**Available Helpers:**
```dart
class SettingsDialogs {
  // Slider dialog for numeric values
  static void showSliderDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required double currentValue,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) valueFormatter,
    required Future<void> Function(double) onChanged,
    required dynamic provider,
  });

  // Radio button dialog for single selection
  static Future<T?> showRadioDialog<T>({
    required BuildContext context,
    required String title,
    required T currentValue,
    required List<RadioOption<T>> options,
  });

  // Color picker dialog (placeholder)
  static Future<Color?> showColorPickerDialog({
    required BuildContext context,
    required String title,
    required Color currentColor,
  });

  // Custom radio list item widget
  static Widget buildRadioListItem<T>({
    required BuildContext context,
    required Widget title,
    Widget? subtitle,
    required T value,
    required T? groupValue,
    required ValueChanged<T?> onChanged,
  });
}
```

#### Specialized Dialogs

**About Dialogs** (`lib/features/settings/widgets/dialogs/about_dialogs.dart`)
- `showLibrariesDialog()` - Open source licenses
- `showLicenseDialog()` - App license
- `showUsageRightsDialog()` - Usage terms
- `showPrivacyPolicyDialog()` - Privacy policy
- `launchUrlWithFallback()` - URL launcher with Linux support

**Data Dialogs** (`lib/features/settings/widgets/dialogs/data_dialogs.dart`)
- `showExportDialog()` - Export habits and settings
- `showImportDialog()` - Import data from JSON
- `showImportResultDialog()` - Display import statistics
- `showDatabaseStatsDialog()` - Show database metrics
- `optimizeDatabase()` - Vacuum database

**Advanced Dialogs** (`lib/features/settings/widgets/dialogs/advanced_dialogs.dart`)
- `showResetHabitsDialog()` - Reset all habits
- `showResetSettingsDialog()` - Reset to defaults
- `showClearAllDataDialog()` - Nuclear option
- `showLogsDialog()` - View app logs
- `downloadLogs()` - Save logs to file
- `clearLogs()` - Delete log files
- `sendLogsToGitHub()` - Create GitHub issue
- `returnToOnboarding()` - Reset onboarding flag

## Settings Organization

### Hierarchical Structure

```
Settings Page
├── 🌐 General
│   ├── Language
│   ├── Theme (Light/Dark/System)
│   └── Theme Color
│
├── 🎨 Appearance
│   ├── Font Size Scale
│   ├── Icon Size
│   ├── Day Square Size
│   ├── Card Style
│   │   ├── Border Radius
│   │   ├── Elevation
│   │   └── Card Spacing
│   ├── Completion Colors
│   │   ├── Positive Habits
│   │   │   ├── Calendar Color
│   │   │   ├── Habit Card Color
│   │   │   ├── Calendar Timeline Color
│   │   │   └── Main Timeline Color
│   │   └── Negative Habits
│   │       ├── Calendar Color
│   │       ├── Habit Card Color
│   │       ├── Calendar Timeline Color
│   │       └── Main Timeline Color
│   ├── Streak Color Scheme
│   └── Use Streak Colors for Squares
│
├── 📱 Display
│   ├── Habits
│   │   ├── Layout Mode (List/Grid)
│   │   ├── Grid Show Icon
│   │   ├── Grid Show Completion
│   │   └── Grid Show Timeline
│   ├── Timelines
│   │   ├── Timeline Days
│   │   ├── Modal Timeline Days
│   │   ├── Habit Card Timeline Days
│   │   ├── Timeline Spacing
│   │   ├── Timeline Compact Mode
│   │   ├── Show Streak Borders
│   │   ├── Show Week/Month Highlights
│   │   └── Show Streak Numbers
│   ├── Habit Cards
│   │   ├── Show Descriptions
│   │   ├── Compact Cards
│   │   ├── Show Percentage
│   │   ├── Habit Checkbox Style
│   │   ├── Show Streak on Card
│   │   ├── Show Main Timeline
│   │   ├── Card Timeline Fill Lines
│   │   └── Card Timeline Lines
│   └── Statistics
│       ├── Progress Indicator Style
│       ├── Show Statistics Card
│       ├── Main Timeline Fill Lines
│       ├── Main Timeline Lines
│       └── Card Layout Mode
│
├── 📅 Date & Time
│   ├── Date Format
│   ├── First Day of Week
│   └── Week Numbers
│
├── 🔔 Notifications
│   ├── Enable Notifications
│   ├── Notification Time
│   ├── Show Percentage in Notification
│   └── Notification Sound
│
├── 🏷️ Tags
│   └── Manage Tags
│
├── 💾 Data
│   ├── Export Data
│   ├── Import Data
│   ├── Database Statistics
│   └── Optimize Database
│
├── ⚙️ Advanced
│   ├── Bad Habit Logic Mode
│   ├── Enable Crash Reports
│   ├── Reset Habits
│   ├── Reset Settings
│   ├── Clear All Data
│   ├── View Logs
│   └── Return to Onboarding
│
└── ℹ️ About
    ├── App Version
    ├── Open Source Libraries
    ├── License
    ├── Usage Rights
    ├── Privacy Policy
    └── GitHub Repository
```

## Data Flow

### Reading a Setting

```
User opens Settings
    ↓
SettingsPage renders
    ↓
Section widget watches provider
    ↓
ref.watch(settingProvider)
    ↓
Provider reads from notifier
    ↓
Notifier returns cached value
    ↓
UI displays value
```

### Updating a Setting

```
User taps setting
    ↓
Dialog shows current value
    ↓
User changes value
    ↓
Dialog calls notifier.setSetting(newValue)
    ↓
Notifier updates internal state
    ↓
Notifier calls PreferencesService.setSetting(newValue)
    ↓
SharedPreferences persists to disk
    ↓
ref.invalidate(notifierProvider) called
    ↓
Provider rebuilds
    ↓
UI updates automatically
```

## Translation Integration

### Easy Localization

The app uses `easy_localization` package for internationalization.

**Supported Languages:**
- English (en)
- Arabic (ar)

**Translation Files:**
- `assets/translations/en.json`
- `assets/translations/ar.json`

**Usage in Settings:**
```dart
// Simple translation
Text('language'.tr())

// Translation with parameters
Text('timeline_days_value'.tr(args: ['$days']))

// Formatted display names
Text(SettingsFormatters.getLanguageName(currentLanguage))
```

**Key Translation Patterns:**

1. **Setting Labels:** Direct keys
   ```dart
   'language' → 'Language'
   'theme' → 'Theme'
   ```

2. **Setting Values:** Suffixed keys
   ```dart
   'small' → 'Small'
   'medium' → 'Medium'
   'large' → 'Large'
   ```

3. **Descriptions:** `_description` suffix
   ```dart
   'compact_cards_description' → 'Reduce spacing between habit cards'
   ```

4. **Section Headers:** Prefixed keys
   ```dart
   'settings_section_appearance_card_style' → 'Card Style'
   ```

## Search Functionality

### Implementation

The settings page includes a search bar that filters visible settings based on keywords.

**How it works:**
```dart
String _searchQuery = '';

List<Widget> _filterSectionChildren(
  String sectionTitle,
  List<Widget> children, {
  List<String>? tags,
}) {
  if (_searchQuery.isEmpty) return children;
  
  // Check if section title matches
  if (sectionTitle.toLowerCase().contains(_searchQuery)) {
    return children;
  }
  
  // Check if any tags match
  if (tags != null) {
    for (var tag in tags) {
      if (tag.toLowerCase().contains(_searchQuery)) {
        return children;
      }
    }
  }
  
  return []; // Hide section if no match
}
```

**Search Tags:**
Each section has associated search tags (translated keys) that are checked against the query.

## Best Practices

### 1. Adding a New Setting

**Step 1:** Add to PreferencesService
```dart
// preferences_service.dart
static const String _keyNewSetting = 'new_setting';

static String getNewSetting() => _prefs!.getString(_keyNewSetting) ?? 'default';

static Future<bool> setNewSetting(String value) =>
    _prefs!.setString(_keyNewSetting, value);
```

**Step 2:** Create Riverpod Providers
```dart
// settings_providers.dart
class NewSettingNotifier {
  String _value;
  
  NewSettingNotifier() : _value = PreferencesService.getNewSetting();
  
  String get value => _value;
  
  Future<void> setValue(String newValue) async {
    _value = newValue;
    await PreferencesService.setNewSetting(newValue);
  }
}

final newSettingNotifierProvider = Provider<NewSettingNotifier>((ref) {
  return NewSettingNotifier();
});

final newSettingProvider = Provider<String>((ref) {
  return ref.watch(newSettingNotifierProvider).value;
});
```

**Step 3:** Add to Section Widget
```dart
// Appropriate section file
final newSetting = ref.watch(newSettingProvider);

ListTile(
  leading: Icon(Icons.new_icon),
  title: Text('new_setting'.tr()),
  subtitle: Text(newSetting),
  onTap: () => _showNewSettingDialog(context, ref),
),
```

**Step 4:** Create Dialog (if needed)
```dart
void _showNewSettingDialog(BuildContext context, WidgetRef ref) {
  // Use SettingsDialogs helper or create custom dialog
}
```

**Step 5:** Add Translations
```json
// en.json
{
  "new_setting": "New Setting",
  "new_setting_description": "Description of what it does"
}

// ar.json
{
  "new_setting": "إعداد جديد",
  "new_setting_description": "وصف لما يفعله"
}
```

### 2. Widget Types for Different Settings

**Boolean Settings:** Use `SwitchListTile`
```dart
SwitchListTile(
  secondary: Icon(Icons.icon),
  title: Text('setting_name'.tr()),
  subtitle: Text('setting_description'.tr()),
  value: currentValue,
  onChanged: (value) async {
    final notifier = ref.read(settingNotifierProvider);
    await notifier.setValue(value);
    ref.invalidate(settingNotifierProvider);
  },
)
```

**Selection Settings:** Use `ListTile` with dialog
```dart
ListTile(
  leading: Icon(Icons.icon),
  title: Text('setting_name'.tr()),
  subtitle: Text(SettingsFormatters.getDisplayName(currentValue)),
  onTap: () => _showSelectionDialog(context, ref),
)
```

**Numeric Settings:** Use `ListTile` with slider dialog
```dart
ListTile(
  leading: Icon(Icons.icon),
  title: Text('setting_name'.tr()),
  subtitle: Text('${currentValue.toStringAsFixed(1)}'),
  onTap: () => SettingsDialogs.showSliderDialog(
    context: context,
    ref: ref,
    title: 'setting_name'.tr(),
    currentValue: currentValue,
    min: 0,
    max: 100,
    divisions: 100,
    valueFormatter: (value) => '${value.toStringAsFixed(1)}',
    onChanged: (value) async {
      final notifier = ref.read(settingNotifierProvider);
      await notifier.setValue(value);
    },
    provider: settingNotifierProvider,
  ),
)
```

### 3. Radio Group Pattern (Flutter 3.32.0+)

For single-selection dialogs, wrap RadioListTile widgets in RadioGroup:

```dart
Future<void> _showSelectionDialog() async {
  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      String temp = currentValue;
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('select_option'.tr()),
            content: RadioGroup<String>(
              groupValue: temp,
              onChanged: (value) {
                if (value == null) return;
                setDialogState(() {
                  temp = value;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text('option_1'.tr()),
                    value: 'option1',
                  ),
                  RadioListTile<String>(
                    title: Text('option_2'.tr()),
                    value: 'option2',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, temp),
                child: Text('ok'.tr()),
              ),
            ],
          );
        },
      );
    },
  );

  if (result != null) {
    final notifier = ref.read(settingNotifierProvider);
    await notifier.setValue(result);
    ref.invalidate(settingNotifierProvider);
  }
}
```

### 4. Section Organization

**Sub-sections:** Use Divider and SettingsSubsectionHeader
```dart
Column(
  children: [
    // Top-level settings
    ListTile(...),
    ListTile(...),
    
    // Sub-section
    const Divider(),
    SettingsSubsectionHeader(
      title: 'subsection_name'.tr(),
      icon: Icons.icon,
    ),
    ListTile(...),
    ListTile(...),
  ],
)
```

## Performance Considerations

### 1. Provider Invalidation

Only invalidate providers when values actually change:
```dart
if (newValue != currentValue) {
  await notifier.setValue(newValue);
  ref.invalidate(notifierProvider);
}
```

### 2. Minimal Rebuilds

Use `ConsumerWidget` or `Consumer` to limit rebuild scope:
```dart
// Only this widget rebuilds when setting changes
class SettingWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(settingProvider);
    return ListTile(...);
  }
}
```

### 3. Lazy Providers

Providers are created lazily - they only initialize when first watched:
```dart
final settingProvider = Provider<String>((ref) {
  // Only called when first watched
  return ref.watch(settingNotifierProvider).value;
});
```

## Testing

### Unit Testing Settings

```dart
void main() {
  group('Settings Formatters', () {
    test('getLanguageName returns correct display names', () {
      expect(SettingsFormatters.getLanguageName('en'), 'English');
      expect(SettingsFormatters.getLanguageName('ar'), 'العربية');
    });
    
    test('getThemeName handles all ThemeMode values', () {
      expect(SettingsFormatters.getThemeName(ThemeMode.light), 'Light');
      expect(SettingsFormatters.getThemeName(ThemeMode.dark), 'Dark');
      expect(SettingsFormatters.getThemeName(ThemeMode.system), 'System');
    });
  });
  
  group('PreferencesService', () {
    setUp(() async {
      await PreferencesService.init();
    });
    
    test('setting and getting theme mode', () async {
      await PreferencesService.setThemeMode('dark');
      expect(PreferencesService.getThemeMode(), 'dark');
    });
  });
}
```

## Common Issues and Solutions

### Issue 1: Setting not updating in UI

**Cause:** Forgot to invalidate provider
**Solution:** Call `ref.invalidate(notifierProvider)` after updating

### Issue 2: Type mismatch errors

**Cause:** Default value type doesn't match provider type
**Solution:** Ensure consistency across PreferencesService, Notifier, and UI

### Issue 3: Deprecation warnings for RadioListTile

**Cause:** Using deprecated `groupValue` parameter directly on RadioListTile
**Solution:** Wrap in `RadioGroup` widget (Flutter 3.32.0+)

### Issue 4: Settings not persisting

**Cause:** PreferencesService.init() not called or not awaited
**Solution:** Ensure init is called in main() before runApp()

## Migration Guide

### From Monolithic to Modular (Completed)

The settings page was refactored from a single 4,828-line file to a modular structure:

**Before:**
- All code in `settings_page.dart`
- Difficult to maintain
- Long file loading times
- Hard to test individual components

**After:**
- Main page: 3,579 lines (25.9% reduction)
- 9 section widgets
- 4 dialog helper files
- 1 formatter utility
- Much better maintainability

**Key Changes:**
1. Extracted section content into separate widgets
2. Created dialog helper classes
3. Moved formatters to utility file
4. Improved code reusability

## Future Enhancements

### Potential Improvements

1. **Settings Categories**
   - Add collapsible categories within sections
   - Implement nested expansion tiles

2. **Settings Sync**
   - Cloud backup of preferences
   - Cross-device synchronization

3. **Settings Profiles**
   - Multiple user profiles
   - Quick profile switching

4. **Advanced Search**
   - Fuzzy matching
   - Search suggestions
   - Recent searches

5. **Settings Import/Export**
   - Export settings separately from data
   - Share settings presets

6. **Accessibility**
   - Screen reader optimization
   - Keyboard navigation
   - High contrast mode

## Conclusion

The Adati settings implementation follows modern Flutter best practices:

- ✅ Modular architecture for maintainability
- ✅ Riverpod for reactive state management
- ✅ SharedPreferences for persistence
- ✅ Type-safe throughout
- ✅ Full internationalization support
- ✅ Comprehensive search functionality
- ✅ Reusable dialog components
- ✅ Clean separation of concerns

This architecture makes it easy to add new settings, maintain existing ones, and test components in isolation.

---

**Last Updated:** November 19, 2025  
**Version:** 1.0  
**Author:** Adati Development Team

