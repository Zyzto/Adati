/// Configuration for LoggingService
/// 
/// Provides customizable settings for log file names, sizes, and behavior.
class LoggingConfig {
  /// Application name (used for logger name and export file names)
  final String appName;

  /// Main log file name (defaults to '$appName.log')
  final String logFileName;

  /// Crash log file name (defaults to '${appName}_crashes.log')
  final String crashLogFileName;

  /// Optional custom directory for logs (defaults to app documents directory/logs)
  final String? logDirectory;

  /// Maximum size of a single log file in bytes (default: 5MB)
  final int maxLogFileSize;

  /// Maximum number of rotated log files to keep (default: 5)
  final int maxLogFiles;

  /// Maximum total size of all log files combined in bytes (default: 50MB)
  final int maxTotalLogSize;

  /// Enable log aggregation to reduce noise (default: true)
  final bool enableAggregation;

  /// Timeout for log aggregation in milliseconds (default: 100ms)
  final Duration aggregationTimeout;

  const LoggingConfig({
    required this.appName,
    String? logFileName,
    String? crashLogFileName,
    this.logDirectory,
    this.maxLogFileSize = 5 * 1024 * 1024, // 5MB
    this.maxLogFiles = 5,
    this.maxTotalLogSize = 50 * 1024 * 1024, // 50MB
    this.enableAggregation = true,
    this.aggregationTimeout = const Duration(milliseconds: 100),
  })  : logFileName = logFileName ?? '$appName.log',
        crashLogFileName = crashLogFileName ?? '${appName}_crashes.log';
}
