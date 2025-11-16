import 'logging_service.dart';

/// Helper class for logging in static contexts
/// Automatically detects component name from stack trace
class Log {
  /// Get component name from stack trace
  static String? _getComponentFromStackTrace() {
    try {
      final stackTrace = StackTrace.current;
      final lines = stackTrace.toString().split('\n');

      // Look for the calling class in the stack trace
      // Format: #0  ClassName.methodName (file:line)
      for (final line in lines) {
        // Match patterns like "PreferencesService.getThemeMode" or "ExportService.exportToCSV"
        final match = RegExp(r'(\w+Service)\.(\w+)').firstMatch(line);
        if (match != null) {
          return match.group(1); // Return the class name
        }

        // Also match DAO patterns
        final daoMatch = RegExp(r'(\w+Dao)\.(\w+)').firstMatch(line);
        if (daoMatch != null) {
          return daoMatch.group(1);
        }

        // Match repository patterns
        final repoMatch = RegExp(r'(\w+Repository)\.(\w+)').firstMatch(line);
        if (repoMatch != null) {
          return repoMatch.group(1);
        }
      }
    } catch (e) {
      // Fallback if stack trace parsing fails
    }
    return null;
  }

  /// Log a debug message
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    LoggingService.debug(
      message,
      component: _getComponentFromStackTrace(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an info message
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    LoggingService.info(
      message,
      component: _getComponentFromStackTrace(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a warning message
  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    LoggingService.warning(
      message,
      component: _getComponentFromStackTrace(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an error message
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    LoggingService.error(
      message,
      component: _getComponentFromStackTrace(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a severe error
  static void severe(String message, {Object? error, StackTrace? stackTrace}) {
    LoggingService.severe(
      message,
      component: _getComponentFromStackTrace(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}
