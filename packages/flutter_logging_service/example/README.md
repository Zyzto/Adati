# Logging Service Example

This example demonstrates how to use the `flutter_logging_service` package in a Flutter app.

## Running the Example

```bash
cd example
flutter pub get
flutter run
```

## What the Example Shows

The example app demonstrates:

1. **Initialization**: How to initialize the logging service in `main.dart`
2. **Log Helper**: Using the `Log` class for convenient static logging
3. **Loggable Mixin**: Using the `Loggable` mixin in classes for automatic component detection
4. **Direct Service Calls**: Using `LoggingService` directly with explicit components
5. **Error Logging**: Logging exceptions with stack traces
6. **Log Aggregation**: Demonstrating how similar messages are aggregated
7. **Viewing Logs**: Displaying log content in the UI
8. **Log Management**: Exporting, rotating, and clearing logs

## Features Demonstrated

- ✅ All log levels (DEBUG, INFO, WARNING, ERROR, SEVERE)
- ✅ Automatic component detection
- ✅ Error and stack trace logging
- ✅ Log aggregation
- ✅ Viewing log files
- ✅ Exporting logs
- ✅ Rotating logs
- ✅ Clearing logs

## UI Features

The example app includes:
- **Log File Information**: Shows log file paths and sizes
- **Action Buttons**: Test logging, refresh, export, rotate, and clear logs
- **Log Viewer**: Displays the last 100 lines of log content in a scrollable, selectable text view

## Try It Out

1. Run the app
2. Click "Test Logging" to generate various log messages
3. Click "Refresh Logs" to see the generated logs
4. Try exporting logs to see where they're saved
5. Test log rotation and clearing
