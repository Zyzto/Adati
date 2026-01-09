import 'logging_service.dart';

/// Mixin that provides logging methods with automatic component detection
/// 
/// Classes using this mixin can call logDebug, logInfo, logWarning, logError, logSevere
/// without needing to specify the component name - it's automatically extracted
/// from the class's runtimeType.
mixin Loggable {
  /// Get the component name from the class's runtimeType
  /// Removes generic type parameters and returns just the class name
  String get _componentName {
    final typeName = runtimeType.toString();
    // Remove generic type parameters (e.g., "HabitDao<Habit>" -> "HabitDao")
    final componentName = typeName.split('<').first;
    return componentName;
  }

  /// Log a debug message
  /// Only logs in debug mode (release builds skip this)
  void logDebug(String message, {Object? error, StackTrace? stackTrace}) {
    LoggingService.debug(
      message,
      component: _componentName,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an info message
  void logInfo(String message, {Object? error, StackTrace? stackTrace}) {
    LoggingService.info(
      message,
      component: _componentName,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a warning message
  void logWarning(String message, {Object? error, StackTrace? stackTrace}) {
    LoggingService.warning(
      message,
      component: _componentName,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an error message
  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    LoggingService.error(
      message,
      component: _componentName,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a severe error (crash-level)
  void logSevere(String message, {Object? error, StackTrace? stackTrace}) {
    LoggingService.severe(
      message,
      component: _componentName,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
