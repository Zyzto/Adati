# Services Documentation

This document provides comprehensive documentation for all services in the Adati codebase, including usage examples and API reference.

## Table of Contents

- [LoggingService](#loggingservice)
- [PreferencesService](#preferencesservice)
- [NotificationService](#notificationservice)
- [ReminderService](#reminderservice)
- [ExportService](#exportservice)
- [ImportService](#importservice)
- [AutoBackupService](#autobackupservice)
- [DemoDataService](#demodataservice)
- [Log Helper](#log-helper)

---

## LoggingService

Comprehensive logging service with file persistence, log aggregation, and crash tracking.

### Initialization

```dart
await LoggingService.init();
```

**Note**: Must be called before any other service initialization in `main.dart`.

### Features

- **File Logging**: Logs are written to `adati.log` in the app's documents directory
- **Crash Logging**: Separate crash logs in `adati_crashes.log`
- **Log Aggregation**: Similar log messages are aggregated to reduce noise
- **Log Rotation**: Automatic log file rotation when size limits are reached
- **Log Levels**: DEBUG, INFO, WARNING, ERROR, SEVERE

### API Reference

#### Static Methods

- `init()` - Initialize the logging service (must be called first)
- `disableFileLogging()` - Disable file logging (useful for tests)
- `severe(String message, {String? component, Object? error, StackTrace? stackTrace})` - Log severe errors/crashes
- `getLogFile()` - Get the path to the main log file
- `getCrashLogFile()` - Get the path to the crash log file
- `exportLogs()` - Export all logs as a string
- `exportCrashLogs()` - Export crash logs as a string
- `clearLogs()` - Clear all log files
- `getLastCrashSummary()` - Get summary of the last crash

### Usage Example

```dart
// Log an info message
LoggingService.severe(
  'Failed to load habits',
  component: 'HabitRepository',
  error: e,
  stackTrace: stackTrace,
);
```

**Note**: In practice, use the `Log` helper from `log_helper.dart` instead of calling `LoggingService` directly.

---

## PreferencesService

Service for managing user preferences and settings using `SharedPreferences`.

### Initialization

```dart
await PreferencesService.init();
```

### Features

- Persistent storage of user preferences
- Type-safe getters and setters for all settings
- Automatic logging of preference changes
- Support for various data types (String, int, bool, double)

### API Reference

#### Common Methods

- `init()` - Initialize the service
- `prefs` - Get the SharedPreferences instance
- `resetAllSettings()` - Reset all settings to defaults
- `clear()` - Clear all preferences

#### Theme Settings

- `getThemeMode()` / `setThemeMode(String mode)` - Theme mode (light, dark, system)
- `getThemeColor()` / `setThemeColor(int color)` - Theme color (ARGB32)
- `getCardElevation()` / `setCardElevation(double elevation)` - Card elevation
- `getCardBorderRadius()` / `setCardBorderRadius(double radius)` - Card border radius

#### Language Settings

- `getLanguage()` / `setLanguage(String language)` - App language (en, ar)

#### Display Settings

- `getTimelineDays()` / `setTimelineDays(int days)` - Number of days to show in timeline
- `getFontSizeScale()` / `setFontSizeScale(String scale)` - Font size scale
- `getShowStreakBorders()` / `setShowStreakBorders(bool show)` - Show streak borders
- `getTimelineCompactMode()` / `setTimelineCompactMode(bool compact)` - Timeline compact mode
- And many more display-related preferences...

#### Auto-Backup Settings

- `getAutoBackupEnabled()` / `setAutoBackupEnabled(bool enabled)` - Enable/disable auto-backup
- `getAutoBackupRetentionCount()` / `setAutoBackupRetentionCount(int count)` - Number of backups to keep
- `getAutoBackupUserDirectory()` / `setAutoBackupUserDirectory(String? directory)` - Custom backup directory
- `getAutoBackupLastBackup()` / `setAutoBackupLastBackup(String? iso8601String)` - Last backup timestamp

### Usage Example

```dart
// Get theme mode
final themeMode = PreferencesService.getThemeMode();

// Set theme mode
await PreferencesService.setThemeMode('dark');

// Check if first launch
if (PreferencesService.isFirstLaunch()) {
  // Show onboarding
}
```

---

## NotificationService

Service for managing local notifications across all platforms.

### Initialization

```dart
await NotificationService.init();
await NotificationService.requestPermissions();
```

### Features

- Cross-platform notification support (Android, iOS, Linux, macOS, Windows)
- Scheduled notifications with exact timing
- Notification channels (Android)
- Notification tap handling with navigation
- Permission management

### API Reference

#### Static Methods

- `init()` - Initialize the notification service
- `requestPermissions()` - Request notification permissions
- `showNotification({required int id, required String title, required String body, String? payload})` - Show immediate notification
- `scheduleNotification({required int id, required DateTime scheduledDate, required String title, required String body, String? payload})` - Schedule a notification
- `cancelNotification(int id)` - Cancel a notification
- `cancelScheduledNotification(int id, {bool silent = false})` - Cancel a scheduled notification
- `cancelAllNotifications()` - Cancel all notifications
- `setRouter(GoRouter router)` - Set router for navigation from notification taps

### Usage Example

```dart
// Show immediate notification
await NotificationService.showNotification(
  id: 1,
  title: 'Habit Reminder',
  body: 'Don\'t forget to complete your habit!',
  payload: '/timeline',
);

// Schedule notification
await NotificationService.scheduleNotification(
  id: 2,
  scheduledDate: DateTime.now().add(Duration(hours: 1)),
  title: 'Daily Reminder',
  body: 'Time to check your habits',
);
```

---

## ReminderService

Centralized service for managing habit reminders with platform-specific behavior.

### Initialization

```dart
ReminderService.init(habitRepository);
```

### Features

- Platform-specific reminder scheduling:
  - **Android**: Precise scheduled notifications + WorkManager fallback
  - **iOS**: Precise scheduled notifications + Background Fetch
  - **Desktop**: App-level periodic checks (when app is open)
- Automatic rescheduling of all reminders
- Cancellation of reminders for deleted habits

### API Reference

#### Static Methods

- `init(HabitRepository habitRepository)` - Initialize with habit repository
- `rescheduleAllReminders()` - Reschedule all active reminders for all habits
- `cancelRemindersForHabit(int habitId)` - Cancel all reminders for a specific habit

### Usage Example

```dart
// Initialize
ReminderService.init(habitRepository);

// Reschedule all reminders (called automatically on app startup)
await ReminderService.rescheduleAllReminders();

// Cancel reminders for a deleted habit
await ReminderService.cancelRemindersForHabit(habitId);
```

---

## ExportService

Service for exporting app data in JSON or CSV format.

### Features

- Export all data (habits, entries, streaks)
- Export habits only
- Export settings only
- Support for JSON and CSV formats
- Automatic file naming with timestamps

### API Reference

#### Static Methods

- `exportToJSON(List<Habit> habits, List<TrackingEntry> entries, List<Streak> streaks)` - Export all data as JSON
- `exportToCSV(List<Habit> habits, List<TrackingEntry> entries, List<Streak> streaks)` - Export all data as CSV
- `exportHabitsOnly(List<Habit> habits)` - Export only habits as JSON
- `exportSettings()` - Export settings as JSON

All methods return `Future<String?>` where the string is the file path, or `null` if export failed.

### Usage Example

```dart
// Export all data
final habits = await repository.getAllHabits();
final entries = await repository.getAllEntries();
final streaks = await repository.getAllStreaks();

final filePath = await ExportService.exportToJSON(habits, entries, streaks);
if (filePath != null) {
  print('Exported to: $filePath');
}

// Export habits only
final habitsPath = await ExportService.exportHabitsOnly(habits);

// Export settings
final settingsPath = await ExportService.exportSettings();
```

---

## ImportService

Service for importing app data from JSON or CSV files.

### Features

- Import all data (habits, entries, streaks)
- Import habits only
- Import settings only
- Support for JSON and CSV formats
- Progress callbacks
- Error handling and reporting

### API Reference

#### Classes

**ImportResult**
- `success` - Whether import was successful
- `habitsImported` / `habitsSkipped` - Habit import statistics
- `entriesImported` / `entriesSkipped` - Entry import statistics
- `streaksImported` / `streaksSkipped` - Streak import statistics
- `settingsImported` / `settingsSkipped` - Settings import statistics
- `errors` - List of error messages
- `warnings` - List of warning messages
- `hasIssues` - Whether there are any issues

#### Static Methods

- `pickImportFile({String? importType})` - Pick an import file (returns file path or null)
- `importAllData(HabitRepository repository, String filePath, void Function(String message, double progress)? onProgress)` - Import all data
- `importHabitsOnly(HabitRepository repository, String filePath, void Function(String message, double progress)? onProgress)` - Import habits only
- `importSettings(String filePath, void Function(String message, double progress)? onProgress)` - Import settings only

### Usage Example

```dart
// Pick and import file
final filePath = await ImportService.pickImportFile();
if (filePath != null) {
  final result = await ImportService.importAllData(
    repository,
    filePath,
    (message, progress) {
      print('$message: ${(progress * 100).toInt()}%');
    },
  );
  
  if (result.success) {
    print('Imported ${result.habitsImported} habits');
  } else {
    print('Errors: ${result.errors}');
  }
}
```

---

## AutoBackupService

Service for automatic backup creation and management.

### Initialization

```dart
AutoBackupService.init(habitRepository);
```

### Features

- Automatic daily backups
- Backup retention management
- Backup restoration
- Custom backup directory support
- Backup information retrieval

### API Reference

#### Classes

**BackupInfo**
- `path` - Backup file path
- `date` - Backup date
- `size` - Backup file size
- `habitsCount` - Number of habits in backup
- `entriesCount` - Number of entries in backup
- `streaksCount` - Number of streaks in backup
- `version` - App version when backup was created

#### Static Methods

- `init(HabitRepository repository)` - Initialize with habit repository
- `checkAndCreateBackupIfDue()` - Check if backup is due and create one if needed
- `createBackup()` - Create a backup manually
- `getBackupDirectory()` - Get the backup directory
- `listBackups()` - List all available backups
- `getBackupInfo(String backupPath)` - Get information about a backup
- `restoreFromBackup(String backupPath, HabitRepository repository, {void Function(String message, double progress)? onProgress})` - Restore from a backup
- `deleteBackup(String backupPath)` - Delete a backup file
- `cleanupOldBackups()` - Delete old backups beyond retention count

### Usage Example

```dart
// Initialize
AutoBackupService.init(habitRepository);

// Check and create backup if due (called automatically on app startup)
await AutoBackupService.checkAndCreateBackupIfDue();

// Create backup manually
final backupPath = await AutoBackupService.createBackup();

// List backups
final backups = await AutoBackupService.listBackups();
for (final backup in backups) {
  print('${backup.date}: ${backup.habitsCount} habits');
}

// Restore from backup
final result = await AutoBackupService.restoreFromBackup(
  backupPath,
  repository,
  (message, progress) => print('$message: ${(progress * 100).toInt()}%'),
);
```

---

## DemoDataService

Service for managing demo data (used for onboarding and testing).

### Features

- Load demo data from JSON configuration
- Check if demo data exists
- Check if a habit is demo data
- Delete demo data

### API Reference

#### Static Methods

- `loadDemoData(HabitRepository repository)` - Load demo data from assets
- `hasDemoData(HabitRepository repository)` - Check if demo data exists
- `isDemoData(int habitId, HabitRepository repository)` - Check if a habit is demo data
- `deleteDemoData(HabitRepository repository)` - Delete all demo data

### Usage Example

```dart
// Load demo data
await DemoDataService.loadDemoData(repository);

// Check if demo data exists
if (await DemoDataService.hasDemoData(repository)) {
  // Show delete demo data button
}

// Delete demo data
await DemoDataService.deleteDemoData(repository);
```

---

## Log Helper

Convenience wrapper around `LoggingService` for easier logging throughout the app.

### Usage

Instead of calling `LoggingService` directly, use the `Log` helper:

```dart
import 'package:adati/core/services/log_helper.dart';

// Debug log (only in debug mode)
Log.debug('Debug message', component: 'MyComponent');

// Info log
Log.info('Info message', component: 'MyComponent');

// Warning log
Log.warning('Warning message', component: 'MyComponent');

// Error log
Log.error(
  'Error message',
  component: 'MyComponent',
  error: e,
  stackTrace: stackTrace,
);
```

### API Reference

- `Log.debug(String message, {String? component})` - Debug level log
- `Log.info(String message, {String? component})` - Info level log
- `Log.warning(String message, {String? component})` - Warning level log
- `Log.error(String message, {String? component, Object? error, StackTrace? stackTrace})` - Error level log

**Note**: For severe errors/crashes, use `LoggingService.severe()` directly.

---

## Service Initialization Order

Services must be initialized in this order in `main.dart`:

1. `LoggingService.init()` - Must be first (needed for all other logging)
2. `PreferencesService.init()` - Needed for user preferences
3. `NotificationService.init()` - For notifications
4. `ReminderService.init()` - For reminders (requires habit repository)
5. `AutoBackupService.init()` - For auto-backups (requires habit repository)

See `lib/main.dart` for the complete initialization sequence.

---

## Platform-Specific Notes

### Android
- Notifications require `SCHEDULE_EXACT_ALARM` permission for precise scheduling
- WorkManager is used as a fallback for reminders

### iOS
- Background Fetch is used for reminder checks
- Notification permissions are requested on first use

### Desktop (Linux, Windows, macOS)
- Reminders are checked periodically when the app is in the foreground
- WorkManager is not available on desktop platforms

### Web
- Notifications use browser API
- File operations may have limitations

---

## Error Handling

All services handle errors gracefully:
- Errors are logged using `LoggingService`
- Services continue to function even if non-critical operations fail
- User-friendly error messages are provided where appropriate

---

## Testing

To disable file logging in tests:

```dart
LoggingService.disableFileLogging();
```

This prevents log files from being created during test execution.
