# Flutter Logging Service

A comprehensive logging service for Flutter apps with file persistence, log aggregation, and crash tracking.

## Features

- **File Logging**: Persistent logs written to files with automatic rotation
- **Crash Logging**: Separate crash log file for severe errors
- **Log Aggregation**: Similar log messages are aggregated to reduce noise
- **Log Rotation**: Automatic log file rotation when size limits are reached
- **Log Levels**: DEBUG, INFO, WARNING, ERROR, SEVERE
- **Component Detection**: Automatic component name detection from stack traces
- **Cross-Platform**: Works on Android, iOS, Linux, macOS, Windows, and Web

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_logging_service:
    path: packages/flutter_logging_service  # For local package
    # Or from pub.dev when published:
    # flutter_logging_service: ^1.0.0
```

## Quick Start

### 1. Initialize in main.dart

```dart
import 'package:flutter_logging_service/flutter_logging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging service FIRST (before any other services)
  await LoggingService.init(LoggingConfig(
    appName: 'MyApp',
    logFileName: 'myapp.log',
    crashLogFileName: 'myapp_crashes.log',
  ));
  
  runApp(MyApp());
}
```

### 2. Use Log Helper (Recommended)

```dart
import 'package:flutter_logging_service/flutter_logging_service.dart';

class MyService {
  void doSomething() {
    Log.info('Doing something important');
    Log.debug('Debug information');
    Log.warning('This is a warning');
    Log.error('An error occurred', error: exception, stackTrace: stackTrace);
    Log.severe('Critical error!', error: exception, stackTrace: stackTrace);
  }
}
```

### 3. Use Loggable Mixin

```dart
import 'package:flutter_logging_service/flutter_logging_service.dart';

class MyRepository with Loggable {
  void fetchData() {
    logInfo('Fetching data');
    logDebug('Debug details');
    logError('Failed to fetch', error: e, stackTrace: stackTrace);
  }
}
```

## Configuration

### LoggingConfig Options

```dart
LoggingConfig(
  appName: 'MyApp',                    // Required: App name for logger
  logFileName: 'myapp.log',            // Optional: Defaults to '$appName.log'
  crashLogFileName: 'myapp_crashes.log', // Optional: Defaults to '${appName}_crashes.log'
  logDirectory: '/custom/path',        // Optional: Custom log directory
  maxLogFileSize: 5 * 1024 * 1024,    // Optional: Default 5MB
  maxLogFiles: 5,                      // Optional: Default 5 rotated files
  maxTotalLogSize: 50 * 1024 * 1024,  // Optional: Default 50MB total
  enableAggregation: true,             // Optional: Default true
  aggregationTimeout: Duration(milliseconds: 100), // Optional: Default 100ms
)
```

## API Reference

### LoggingService

#### Static Methods

- `init(LoggingConfig config)` - Initialize the logging service (must be called first)
- `disableFileLogging()` - Disable file logging (useful for tests)
- `debug(String message, {String? component, Object? error, StackTrace? stackTrace})`
- `info(String message, {String? component, Object? error, StackTrace? stackTrace})`
- `warning(String message, {String? component, Object? error, StackTrace? stackTrace})`
- `error(String message, {String? component, Object? error, StackTrace? stackTrace})`
- `severe(String message, {String? component, Object? error, StackTrace? stackTrace})`
- `getLogFilePath()` - Get path to main log file
- `getCrashLogFilePath()` - Get path to crash log file
- `getLogContent({int maxLines = 1000})` - Get log content as string
- `exportLogs()` - Export all logs to a file
- `clearLogs()` - Clear all log files
- `rotateAndCleanupLogs()` - Manually rotate and cleanup logs

### Log Helper

The `Log` class provides convenient static methods with automatic component detection:

- `Log.debug(String message, {Object? error, StackTrace? stackTrace})`
- `Log.info(String message, {Object? error, StackTrace? stackTrace})`
- `Log.warning(String message, {Object? error, StackTrace? stackTrace})`
- `Log.error(String message, {Object? error, StackTrace? stackTrace})`
- `Log.severe(String message, {Object? error, StackTrace? stackTrace})`

### Loggable Mixin

Classes using the `Loggable` mixin get automatic component name detection:

- `logDebug(String message, {Object? error, StackTrace? stackTrace})`
- `logInfo(String message, {Object? error, StackTrace? stackTrace})`
- `logWarning(String message, {Object? error, StackTrace? stackTrace})`
- `logError(String message, {Object? error, StackTrace? stackTrace})`
- `logSevere(String message, {Object? error, StackTrace? stackTrace})`

## Log Levels

- **DEBUG**: Development debugging (only in debug mode)
- **INFO**: Important information
- **WARNING**: Warnings that don't break functionality
- **ERROR**: Errors that are handled gracefully
- **SEVERE**: Critical errors/crashes

## Log Aggregation

Similar log messages are automatically aggregated to reduce noise. For example:

```
[INFO] [AGGREGATED] fetchData() called 10 times (params: id=1, id=2, id=3 ... and 7 more)
```

## Example App

A complete example app is included in the `example/` directory. Run it with:

```bash
cd example
flutter run
```

The example demonstrates:
- Initializing the logging service
- Using Log helper for static logging
- Using Loggable mixin in classes
- Viewing log content
- Exporting logs
- Rotating and clearing logs

## Testing

Disable file logging in tests:

```dart
void main() {
  setUpAll(() {
    LoggingService.disableFileLogging();
  });
  
  test('my test', () {
    // Logs will only go to console, not files
  });
}
```

## Error Handling

The logging service handles errors gracefully:
- If file initialization fails, falls back to console logging
- File write errors are logged but don't crash the app
- Log rotation failures are handled safely

## Platform Support

- ✅ Android
- ✅ iOS
- ✅ Linux
- ✅ macOS
- ✅ Windows
- ✅ Web (with limitations)

## License

See LICENSE file for details.
