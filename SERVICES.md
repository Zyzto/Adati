# Services Documentation

This document provides comprehensive documentation for all services in the Adati codebase. Services are located in `lib/core/services/` and provide core functionality used throughout the application.

## Table of Contents

- [LoggingService](#loggingservice)
- [LogHelper](#loghelper)
- [Loggable Mixin](#loggable-mixin)
- [PreferencesService](#preferencesservice)
- [NotificationService](#notificationservice)
- [ExportService](#exportservice)
- [ImportService](#importservice)
- [DemoDataService](#demodataservice)
- [PlatformUtils](#platformutils)

---

## LoggingService

**Location**: `lib/core/services/logging_service.dart`

**Purpose**: Centralized logging system with file persistence, log aggregation, crash reporting, and GitHub Issues integration.

### What It Does

- Provides structured logging with different severity levels (DEBUG, INFO, WARNING, ERROR, SEVERE)
- Persists logs to files on disk for debugging and crash analysis
- Aggregates repetitive log messages to reduce noise
- Tracks crashes and severe errors separately
- Supports exporting logs and sending them to GitHub Issues
- Automatically rotates log files when they exceed size limits

### How It Works

1. **Initialization**: Creates log directories and files in the app's documents directory
2. **Log Levels**: 
   - `DEBUG`: Only logged in debug mode (skipped in release builds)
   - `INFO`: General informational messages
   - `WARNING`: Warning messages for potential issues
   - `ERROR`: Error messages for recoverable errors
   - `SEVERE`: Critical errors/crashes (also written to crash log)
3. **Log Aggregation**: Groups similar log messages (same component, level, and method) into a single aggregated entry showing count and parameter summaries
4. **File Persistence**: Logs are written to `adati.log` and crashes to `adati_crashes.log`
5. **Log Rotation**: When a log file exceeds 5MB, it's rotated (keeps up to 5 rotated files)

### How to Use

#### Basic Usage

```dart
import 'package:adati/core/services/logging_service.dart';

// Initialize (usually done in main.dart)
await LoggingService.init();

// Log messages
LoggingService.debug('Debug message', component: 'MyComponent');
LoggingService.info('Info message', component: 'MyComponent');
LoggingService.warning('Warning message', component: 'MyComponent');
LoggingService.error('Error message', component: 'MyComponent', error: exception);
LoggingService.severe('Critical error', component: 'MyComponent', error: exception, stackTrace: stack);
```

#### Using with LogHelper (Static Contexts)

```dart
import 'package:adati/core/services/log_helper.dart';

// Component name is automatically detected from stack trace
Log.debug('Debug message');
Log.info('Info message');
Log.warning('Warning message');
Log.error('Error message', error: exception);
Log.severe('Critical error', error: exception, stackTrace: stack);
```

#### Using with Loggable Mixin (Class Contexts)

```dart
import 'package:adati/core/services/loggable_mixin.dart';

class MyService with Loggable {
  void doSomething() {
    // Component name is automatically detected from class name
    logDebug('Doing something');
    logInfo('Something done');
    logError('Something failed', error: exception);
  }
}
```

#### Exporting Logs

```dart
// Export logs to a file
final filePath = await LoggingService.exportLogs();

// Get log file size
final size = await LoggingService.getLogFileSize();

// Clear all logs
final success = await LoggingService.clearLogs();
```

#### Sending Logs to GitHub

```dart
// Requires GITHUB_TOKEN in .env file
final success = await LoggingService.sendLogsToGitHub(
  'Issue Title',
  'Issue description',
);
```

### Key Methods

- `init()`: Initialize the logging service (must be called before use)
- `debug(message, {component, error, stackTrace})`: Log debug message
- `info(message, {component, error, stackTrace})`: Log info message
- `warning(message, {component, error, stackTrace})`: Log warning message
- `error(message, {component, error, stackTrace})`: Log error message
- `severe(message, {component, error, stackTrace})`: Log severe error (crash)
- `exportLogs()`: Export all logs to a user-selected file
- `clearLogs()`: Clear all log files
- `sendLogsToGitHub(title, description)`: Send logs to GitHub as an issue
- `getLogFileSize()`: Get total size of all log files
- `getLastCrashTime()`: Get timestamp of last crash
- `getLastCrashSummary()`: Get summary of last crash
- `setAggregationEnabled(enabled)`: Enable/disable log aggregation

### Dependencies

- `easy_logger`: For console logging
- `path_provider`: For file system access
- `http`: For GitHub API integration
- `flutter_dotenv`: For GitHub token configuration
- `file_picker`: For log export UI

---

## LogHelper

**Location**: `lib/core/services/log_helper.dart`

**Purpose**: Static helper class for logging in static contexts where you can't use the `Loggable` mixin.

### What It Does

- Provides static logging methods that automatically detect the component name from the stack trace
- Wraps `LoggingService` methods with automatic component detection
- Useful for static service methods, utility functions, and `main.dart`

### How It Works

1. When a log method is called, it captures the current stack trace
2. Parses the stack trace to find the calling class name (matches patterns like `ServiceName.methodName`, `DaoName.methodName`, `RepositoryName.methodName`)
3. Passes the detected component name to `LoggingService`

### How to Use

```dart
import 'package:adati/core/services/log_helper.dart';

class PreferencesService {
  static Future<void> init() async {
    // Component name "PreferencesService" is automatically detected
    Log.info('PreferencesService initialized');
  }
  
  static String? getThemeMode() {
    Log.debug('getThemeMode() called');
    // ...
  }
}
```

### Key Methods

- `debug(message, {error, stackTrace})`: Log debug message
- `info(message, {error, stackTrace})`: Log info message
- `warning(message, {error, stackTrace})`: Log warning message
- `error(message, {error, stackTrace})`: Log error message
- `severe(message, {error, stackTrace})`: Log severe error

---

## Loggable Mixin

**Location**: `lib/core/services/loggable_mixin.dart`

**Purpose**: Mixin that provides logging methods with automatic component detection for classes.

### What It Does

- Adds logging methods to any class that uses the mixin
- Automatically extracts component name from the class's `runtimeType`
- Removes generic type parameters from component names (e.g., `HabitDao<Habit>` → `HabitDao`)

### How It Works

1. When a class uses the `Loggable` mixin, it gets access to logging methods
2. The component name is extracted from `runtimeType.toString()`
3. Generic type parameters are stripped for cleaner component names
4. All logging calls include the component name automatically

### How to Use

```dart
import 'package:adati/core/services/loggable_mixin.dart';

class HabitDao extends DatabaseAccessor<AppDatabase> with Loggable {
  Future<List<Habit>> getAllHabits() async {
    // Component name "HabitDao" is automatically included
    logDebug('getAllHabits() called');
    try {
      final result = await select(db.habits).get();
      logInfo('getAllHabits() returned ${result.length} habits');
      return result;
    } catch (e, stackTrace) {
      logError('getAllHabits() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
```

### Key Methods

- `logDebug(message, {error, stackTrace})`: Log debug message
- `logInfo(message, {error, stackTrace})`: Log info message
- `logWarning(message, {error, stackTrace})`: Log warning message
- `logError(message, {error, stackTrace})`: Log error message
- `logSevere(message, {error, stackTrace})`: Log severe error

---

## PreferencesService

**Location**: `lib/core/services/preferences_service.dart`

**Purpose**: Persistent storage for app settings and user preferences using SharedPreferences.

### What It Does

- Stores and retrieves app settings (theme, language, timeline settings, etc.)
- Provides type-safe getters and setters for all preferences
- Handles default values for all settings
- Supports resetting all settings to defaults

### How It Works

1. Uses `SharedPreferences` (Flutter's key-value storage) for persistence
2. Each setting has a unique key constant
3. Getters return default values if the setting doesn't exist
4. All operations are async and return success/failure status

### How to Use

#### Initialization

```dart
import 'package:adati/core/services/preferences_service.dart';

// Initialize (usually done in main.dart)
await PreferencesService.init();
```

#### Theme Settings

```dart
// Get theme mode ('light', 'dark', or 'system')
final themeMode = PreferencesService.getThemeMode();

// Set theme mode
await PreferencesService.setThemeMode('dark');

// Get theme color (ARGB32 integer)
final color = PreferencesService.getThemeColor();

// Set theme color
await PreferencesService.setThemeColor(0xFF673AB7);
```

#### Language Settings

```dart
// Get language code ('en', 'ar', etc.)
final language = PreferencesService.getLanguage();

// Set language
await PreferencesService.setLanguage('ar');
```

#### Timeline Settings

```dart
// Get number of days to show in timeline
final days = PreferencesService.getTimelineDays(); // Default: 100

// Set timeline days
await PreferencesService.setTimelineDays(150);

// Get modal timeline days
final modalDays = PreferencesService.getModalTimelineDays(); // Default: 200
```

#### Display Preferences

```dart
// Card settings
final elevation = PreferencesService.getCardElevation(); // Default: 2.0
final borderRadius = PreferencesService.getCardBorderRadius(); // Default: 12.0
final spacing = PreferencesService.getCardSpacing(); // Default: 12.0

// Day square size ('small', 'medium', 'large')
final size = PreferencesService.getDaySquareSize(); // Default: 'large'

// Timeline settings
final compactMode = PreferencesService.getTimelineCompactMode();
final showStreakBorders = PreferencesService.getShowStreakBorders();
final showWeekMonthHighlights = PreferencesService.getShowWeekMonthHighlights();
final timelineSpacing = PreferencesService.getTimelineSpacing(); // Default: 6.0

// Other display settings
final showStreakNumbers = PreferencesService.getShowStreakNumbers();
final showDescriptions = PreferencesService.getShowDescriptions();
final compactCards = PreferencesService.getCompactCards();
final iconSize = PreferencesService.getIconSize(); // 'small', 'medium', 'large'
final fontSizeScale = PreferencesService.getFontSizeScale(); // 'small', 'normal', 'large'
final showPercentage = PreferencesService.getShowPercentage();
final showStatisticsCard = PreferencesService.getShowStatisticsCard();
final showStreakOnCard = PreferencesService.getShowStreakOnCard();
```

#### Habit Settings

```dart
// Checkbox style ('square', 'bordered', 'circle', 'radio', 'task', 'verified', 'taskAlt')
final style = PreferencesService.getHabitCheckboxStyle(); // Default: 'square'

// Sort order ('name', 'date', 'streak', etc.)
final sortOrder = PreferencesService.getHabitSortOrder(); // Default: 'name'

// Filter query
final query = PreferencesService.getHabitFilterQuery();

// Habit goals
final weeklyGoal = PreferencesService.getHabitWeeklyGoal(habitId);
final monthlyGoal = PreferencesService.getHabitMonthlyGoal(habitId);
```

#### Other Settings

```dart
// First launch check
final isFirstLaunch = PreferencesService.isFirstLaunch();

// Date format
final dateFormat = PreferencesService.getDateFormat(); // Default: 'yyyy-MM-dd'

// First day of week (0=Sunday, 1=Monday)
final firstDay = PreferencesService.getFirstDayOfWeek(); // Default: 1

// Notifications
final notificationsEnabled = PreferencesService.getNotificationsEnabled();

// Default view ('habits', 'timeline')
final defaultView = PreferencesService.getDefaultView(); // Default: 'habits'
```

#### Reset All Settings

```dart
// Reset all settings to defaults
final success = await PreferencesService.resetAllSettings();
```

### Key Methods

- `init()`: Initialize the service (must be called before use)
- `prefs`: Getter for SharedPreferences instance
- `resetAllSettings()`: Reset all preferences to defaults
- Various getters/setters for each setting (see code for complete list)

### Dependencies

- `shared_preferences`: For persistent key-value storage
- `log_helper`: For logging

---

## NotificationService

**Location**: `lib/core/services/notification_service.dart`

**Purpose**: Local notifications for habit reminders on mobile platforms.

### What It Does

- Schedules and manages local notifications for habit reminders
- Handles notification permissions on Android and iOS
- Supports timezone-aware scheduling
- Automatically skips on web and desktop platforms

### How It Works

1. **Initialization**: Sets up notification channels and permissions
2. **Platform Detection**: Automatically skips on web and desktop (Linux, Windows, macOS)
3. **Scheduling**: Uses timezone-aware scheduling with `flutter_local_notifications`
4. **Permissions**: Requests notification permissions on Android 13+ and iOS

### How to Use

#### Initialization

```dart
import 'package:adati/core/services/notification_service.dart';

// Initialize (usually done in main.dart)
await NotificationService.init();

// Request permissions (optional, but recommended)
final granted = await NotificationService.requestPermissions();
```

#### Scheduling Notifications

```dart
// Schedule a notification
await NotificationService.scheduleNotification(
  id: 1, // Unique ID for this notification
  title: 'Habit Reminder',
  body: 'Time to exercise!',
  scheduledDate: DateTime.now().add(Duration(hours: 1)),
  payload: 'habit_1', // Optional payload data
);
```

#### Canceling Notifications

```dart
// Cancel a specific notification
await NotificationService.cancelNotification(1);

// Cancel all notifications
await NotificationService.cancelAllNotifications();
```

### Key Methods

- `init()`: Initialize the notification service
- `requestPermissions()`: Request notification permissions (returns true if granted)
- `scheduleNotification({id, title, body, scheduledDate, payload})`: Schedule a notification
- `cancelNotification(id)`: Cancel a specific notification
- `cancelAllNotifications()`: Cancel all scheduled notifications

### Dependencies

- `flutter_local_notifications`: For local notifications
- `timezone`: For timezone-aware scheduling
- `easy_localization`: For translated notification text
- `platform_utils`: For platform detection
- `log_helper`: For logging

### Notes

- Notifications are automatically skipped on web and desktop platforms
- On Android, notifications use a high-priority channel
- Notifications are scheduled with exact timing and can wake the device from idle state
- The notification ID should be unique per habit/reminder

---

## ExportService

**Location**: `lib/core/services/export_service.dart`

**Purpose**: Export habits, tracking entries, streaks, and settings to CSV or JSON files.

### What It Does

- Exports all habit data to CSV format (for spreadsheet compatibility)
- Exports all habit data to JSON format (for backup/restore)
- Exports only habits (without entries) to JSON
- Exports only settings to JSON
- Uses file picker for user-friendly file selection

### How It Works

1. Takes lists of habits, entries, and streaks as input
2. Formats data according to the export type (CSV or JSON)
3. Uses `FilePicker` to let the user choose where to save the file
4. Writes the formatted data to the selected file
5. Returns the file path on success, null on failure

### How to Use

#### Export All Data to CSV

```dart
import 'package:adati/core/services/export_service.dart';
import 'package:adati/core/database/app_database.dart' as db;

// Get data from repository
final habits = await repository.getAllHabits();
final entries = await repository.getAllEntries();
final streaks = await repository.getAllStreaks();

// Export to CSV
final filePath = await ExportService.exportToCSV(habits, entries, streaks);
if (filePath != null) {
  print('Exported to: $filePath');
}
```

#### Export All Data to JSON

```dart
// Export to JSON
final filePath = await ExportService.exportToJSON(habits, entries, streaks);
if (filePath != null) {
  print('Exported to: $filePath');
}
```

#### Export Only Habits

```dart
// Export only habits (no entries or streaks)
final filePath = await ExportService.exportHabitsOnly(habits);
if (filePath != null) {
  print('Exported to: $filePath');
}
```

#### Export Only Settings

```dart
// Export only app settings
final filePath = await ExportService.exportSettings();
if (filePath != null) {
  print('Exported to: $filePath');
}
```

### Key Methods

- `exportToCSV(habits, entries, streaks)`: Export all data to CSV format
- `exportToJSON(habits, entries, streaks)`: Export all data to JSON format
- `exportHabitsOnly(habits)`: Export only habits to JSON
- `exportSettings()`: Export only settings to JSON

### Dependencies

- `file_picker`: For file selection UI
- `easy_localization`: For translated UI text
- `log_helper`: For logging

### File Formats

#### CSV Format

```csv
Habit Name,Date,Completed,Notes,Current Streak,Longest Streak
"Exercise",2024-01-01,Yes,"",5,10
"Read Books",2024-01-01,No,"",0,5
```

#### JSON Format

```json
{
  "exportDate": "2024-01-01T12:00:00.000Z",
  "version": "1.0",
  "habits": [
    {
      "id": 1,
      "name": "Exercise",
      "description": "Daily workout",
      "color": 4280391411,
      "icon": "fitness_center",
      "habitType": 1,
      "trackingType": "completed",
      ...
    }
  ],
  "entries": [...],
  "streaks": [...]
}
```

---

## ImportService

**Location**: `lib/core/services/import_service.dart`

**Purpose**: Import habits, tracking entries, streaks, and settings from CSV or JSON files.

### What It Does

- Imports all data from CSV or JSON files
- Imports only habits from JSON files
- Imports only settings from JSON files
- Provides progress callbacks for UI updates
- Returns detailed import results with success/error information

### How It Works

1. Uses `FilePicker` to let the user select an import file
2. Detects file format (CSV or JSON) based on file extension
3. Parses the file and validates the data structure
4. Maps old IDs to new IDs to maintain relationships
5. Imports data in batches with progress updates
6. Returns an `ImportResult` with detailed statistics

### How to Use

#### Pick Import File

```dart
import 'package:adati/core/services/import_service.dart';

// Pick a file (user selects from file picker)
final filePath = await ImportService.pickImportFile();
// Or specify import type
final filePath = await ImportService.pickImportFile(importType: 'all');
// Options: 'all', 'habits', 'settings'
```

#### Import All Data

```dart
import 'package:adati/features/habits/habit_repository.dart';

// Import with progress callback
final result = await ImportService.importAllData(
  repository,
  filePath!,
  (message, progress) {
    print('$message: ${(progress * 100).toStringAsFixed(0)}%');
  },
);

if (result.success) {
  print('Imported ${result.habitsImported} habits');
  print('Imported ${result.entriesImported} entries');
  if (result.hasIssues) {
    print('Warnings: ${result.warnings}');
    print('Errors: ${result.errors}');
  }
}
```

#### Import Only Habits

```dart
final result = await ImportService.importHabitsOnly(
  repository,
  filePath!,
  (message, progress) {
    print('$message: ${(progress * 100).toStringAsFixed(0)}%');
  },
);
```

#### Import Only Settings

```dart
final result = await ImportService.importSettings(
  filePath!,
  (message, progress) {
    print('$message: ${(progress * 100).toStringAsFixed(0)}%');
  },
);
```

### ImportResult

The `ImportResult` class provides detailed information about the import:

```dart
class ImportResult {
  bool success;                    // Overall success status
  int habitsImported;              // Number of habits imported
  int habitsSkipped;               // Number of habits skipped
  int entriesImported;           // Number of entries imported
  int entriesSkipped;            // Number of entries skipped
  int streaksImported;           // Number of streaks imported
  int streaksSkipped;            // Number of streaks skipped
  int settingsImported;          // Number of settings imported
  int settingsSkipped;           // Number of settings skipped
  List<String> errors;           // List of error messages
  List<String> warnings;         // List of warning messages
  bool hasIssues;                // True if there are any issues
}
```

### Key Methods

- `pickImportFile({importType})`: Show file picker and return selected file path
- `importAllData(repository, filePath, onProgress)`: Import all data from file
- `importHabitsOnly(repository, filePath, onProgress)`: Import only habits
- `importSettings(filePath, onProgress)`: Import only settings

### Dependencies

- `file_picker`: For file selection UI
- `easy_localization`: For translated UI text
- `habit_repository`: For data access
- `preferences_service`: For settings import
- `log_helper`: For logging

### Notes

- Old habit IDs are mapped to new IDs to maintain entry/streak relationships
- Duplicate habits (same name) may be skipped
- Invalid data entries are skipped with warnings
- Progress callbacks are called with message and progress (0.0 to 1.0)

---

## DemoDataService

**Location**: `lib/core/services/demo_data_service.dart`

**Purpose**: Generate demo data for testing, onboarding, or demonstration purposes.

### What It Does

- Creates sample habits with various tracking types (completed, measurable, occurrences)
- Generates historical tracking entries for demo habits
- Creates a demo tag to identify demo data
- Checks if demo data already exists to avoid duplicates

### How It Works

1. Checks if demo data already exists (by looking for demo tag)
2. Creates a demo tag if it doesn't exist
3. Creates multiple demo habits with different configurations:
   - Completed habits (Exercise, Meditation)
   - Measurable habits (Read Books, Water Intake)
   - Occurrence habits (Meals)
4. Generates historical tracking entries for the last 30-60 days
5. Creates streaks for demo habits

### How to Use

#### Check for Demo Data

```dart
import 'package:adati/core/services/demo_data_service.dart';
import 'package:adati/features/habits/habit_repository.dart';

// Check if demo data exists
final hasDemo = await DemoDataService.hasDemoData(repository);
```

#### Check if Habit is Demo Data

```dart
// Check if a specific habit is demo data
final isDemo = await DemoDataService.isDemoData(habitId, repository);
```

#### Load Demo Data

```dart
// Load demo data (only if it doesn't already exist)
await DemoDataService.loadDemoData(repository);
```

### Key Methods

- `hasDemoData(repository)`: Check if demo data already exists
- `isDemoData(habitId, repository)`: Check if a specific habit is demo data
- `loadDemoData(repository)`: Create demo data (skips if already exists)

### Dependencies

- `habit_repository`: For data access
- `easy_localization`: For translated demo tag name
- `log_helper`: For logging

### Demo Habits Created

1. **Exercise** - Completed habit, 75% completion rate
2. **Read Books** - Measurable habit (pages), 80% completion rate
3. **Water Intake** - Measurable habit (glasses), 70% completion rate
4. **Meditation** - Completed habit, 60% completion rate
5. **Meals** - Occurrence habit (Breakfast, Lunch, Dinner, Snack), 85% completion rate

All demo habits are tagged with a "Demo" tag for easy identification and filtering.

---

## PlatformUtils

**Location**: `lib/core/services/platform_utils.dart` (and platform-specific implementations)

**Purpose**: Platform detection utilities for conditional code execution.

### What It Does

- Detects if the app is running on desktop platforms (Linux, Windows, macOS)
- Provides platform-specific implementations for web and native platforms
- Used by other services to skip platform-incompatible features

### How It Works

1. Uses conditional imports to load platform-specific implementations
2. `platform_utils_native.dart`: For mobile/desktop platforms (uses `dart:io`)
3. `platform_utils_web.dart`: For web platform (stub implementation)
4. `platform_utils_stub.dart`: Default stub implementation

### How to Use

```dart
import 'package:adati/core/services/platform_utils.dart';

// Check if running on desktop
if (isDesktop) {
  // Skip notifications, use desktop-specific UI, etc.
  print('Running on desktop platform');
} else {
  // Mobile-specific code
  print('Running on mobile platform');
}
```

### Key Properties

- `isDesktop`: `bool` - True if running on Linux, Windows, or macOS

### Dependencies

- `dart:io`: For native platform detection (imported conditionally)

### Notes

- The `isDesktop` property is used by `NotificationService` to skip notifications on desktop platforms
- Web platform always returns `false` for `isDesktop` (notifications are handled separately)

---

## Service Initialization Order

Services should be initialized in the following order in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. LoggingService - Initialize first for error tracking
  await LoggingService.init();

  // 2. PreferencesService - Needed by other services
  await PreferencesService.init();

  // 3. NotificationService - Optional, can fail gracefully
  try {
    await NotificationService.init();
    await NotificationService.requestPermissions();
  } catch (e) {
    // Continue without notifications
  }

  // ... rest of app initialization
}
```

---

## Best Practices

1. **Always initialize services before use**: Call `init()` methods in `main.dart` before the app starts
2. **Use appropriate logging methods**: 
   - Use `Loggable` mixin for classes
   - Use `Log` helper for static methods
   - Use `LoggingService` directly only when necessary
3. **Handle errors gracefully**: Services like `NotificationService` can fail, so wrap in try-catch
4. **Use progress callbacks**: When importing/exporting large datasets, provide progress feedback to users
5. **Check for existing data**: Before creating demo data, check if it already exists
6. **Platform awareness**: Use `PlatformUtils` to conditionally enable/disable features based on platform

---

## Contributing

When adding a new service:

1. Create the service file in `lib/core/services/`
2. Add logging using `Loggable` mixin or `Log` helper
3. Document the service in this file
4. Add initialization in `main.dart` if needed
5. Add unit tests if applicable

---

## See Also

- [README.md](README.md) - Main project documentation
- [Database Documentation](docs/database.md) - Database schema and DAOs (if exists)
- [Architecture Documentation](docs/architecture.md) - Overall app architecture (if exists)

