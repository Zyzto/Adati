import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:easy_logger/easy_logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Represents a log entry for aggregation
class _LogEntry {
  final String level;
  final String message;
  final String? component;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;

  _LogEntry({
    required this.level,
    required this.message,
    this.component,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });
}

/// Represents an aggregated log group
class _AggregatedLogGroup {
  final String level;
  final String? component;
  final String baseMessage;
  final List<String> variableParts;
  final int count;
  final DateTime firstTimestamp;
  final DateTime lastTimestamp;

  _AggregatedLogGroup({
    required this.level,
    this.component,
    required this.baseMessage,
    required this.variableParts,
    required this.count,
    required this.firstTimestamp,
    required this.lastTimestamp,
  });
}

class LoggingService {
  static final EasyLogger _logger = EasyLogger(name: 'Adati');

  static File? _logFile;
  static File? _crashLogFile;
  static bool _initialized = false;
  static const int _maxLogFileSize = 5 * 1024 * 1024; // 5MB
  static const int _maxLogFiles = 5;
  static const int _maxTotalLogSize =
      50 * 1024 * 1024; // 50MB total across all log files
  static DateTime? _lastCrashTime;
  static String? _lastCrashSummary;

  // Log aggregation
  static final List<_LogEntry> _recentLogs = [];
  static Timer? _aggregationTimer;
  static const Duration _aggregationTimeout = Duration(
    milliseconds: 100,
  ); // Reduced to 100ms for faster aggregation
  static bool _aggregationEnabled = true;

  // Log level configuration
  static int _minLogLevel = 0; // 0=DEBUG, 1=INFO, 2=WARNING, 3=ERROR, 4=SEVERE
  static const int _levelDebug = 0;
  static const int _levelInfo = 1;
  static const int _levelWarning = 2;
  static const int _levelError = 3;
  static const int _levelSevere = 4;

  /// Initialize logging service with file persistence
  static Future<void> init() async {
    if (_initialized) return;

    try {
      // Load log level from environment variable
      _loadLogLevelFromEnv();

      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory(path.join(directory.path, 'logs'));
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      _logFile = File(path.join(logsDir.path, 'adati.log'));
      _crashLogFile = File(path.join(logsDir.path, 'adati_crashes.log'));

      // Check and rotate logs if they're too large on startup
      await _checkAndRotateLogsOnStartup();

      // Load last crash info if available
      await _loadLastCrashInfo();

      _initialized = true;
      info('LoggingService initialized', component: 'LoggingService');
    } catch (e) {
      // Fallback to console only if file initialization fails
      _logger.error('[LoggingService] Failed to initialize LoggingService: $e');
      _initialized = false;
    }
  }

  /// Load log level from environment variable
  static void _loadLogLevelFromEnv() {
    try {
      final logLevelStr = dotenv.env['LOG_LEVEL']?.toUpperCase();
      if (logLevelStr == null || logLevelStr.isEmpty) {
        // Default to DEBUG in debug mode, INFO in release mode
        _minLogLevel = kReleaseMode ? _levelInfo : _levelDebug;
        return;
      }

      switch (logLevelStr) {
        case 'DEBUG':
          _minLogLevel = _levelDebug;
          break;
        case 'INFO':
          _minLogLevel = _levelInfo;
          break;
        case 'WARNING':
        case 'WARN':
          _minLogLevel = _levelWarning;
          break;
        case 'ERROR':
          _minLogLevel = _levelError;
          break;
        case 'SEVERE':
        case 'FATAL':
          _minLogLevel = _levelSevere;
          break;
        default:
          // Invalid value, use default
          _minLogLevel = kReleaseMode ? _levelInfo : _levelDebug;
      }
    } catch (e) {
      // If dotenv is not loaded yet or error occurs, use default
      _minLogLevel = kReleaseMode ? _levelInfo : _levelDebug;
    }
  }

  /// Check if a log level should be logged
  static bool _shouldLog(int level) {
    return level >= _minLogLevel;
  }

  /// Load last crash information
  static Future<void> _loadLastCrashInfo() async {
    try {
      if (_crashLogFile != null && await _crashLogFile!.exists()) {
        final content = await _crashLogFile!.readAsString();
        final lines = content.split('\n');
        if (lines.isNotEmpty) {
          // Find last crash entry (look for timestamp)
          for (int i = lines.length - 1; i >= 0; i--) {
            if (lines[i].contains('CRASH') || lines[i].contains('SEVERE')) {
              _lastCrashTime = DateTime.now(); // Approximate
              _lastCrashSummary = lines[i].length > 100
                  ? '${lines[i].substring(0, 100)}...'
                  : lines[i];
              break;
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors loading crash info
    }
  }

  /// Write log to file (with aggregation support)
  /// This is called after aggregation check, so entry is already processed
  static Future<void> _writeToFile(
    String level,
    String message,
    String? component, [
    Object? error,
    StackTrace? stackTrace,
  ]) async {
    if (!_initialized) {
      await init();
    }

    if (_logFile == null) return;

    final now = DateTime.now();
    final entry = _LogEntry(
      level: level,
      message: message,
      component: component,
      timestamp: now,
      error: error,
      stackTrace: stackTrace,
    );

    // Write individual log (aggregation was already handled in debug/info/warning methods)
    await _writeLogEntry(entry);
  }

  /// Check if an entry should be aggregated
  static bool _shouldAggregate(_LogEntry entry) {
    if (_recentLogs.isEmpty) {
      _recentLogs.add(entry);
      _scheduleAggregationFlush();
      return true; // Add to buffer for potential future aggregation
    }

    // Find similar logs (same component, level, and similar message pattern)
    final similarLogs = _recentLogs
        .where(
          (log) =>
              log.component == entry.component &&
              log.level == entry.level &&
              _isSimilarMessage(log.message, entry.message),
        )
        .toList();

    // If we have at least one similar log, add this one
    // Don't aggregate immediately - let more accumulate, or wait for flush timer
    if (similarLogs.isNotEmpty) {
      _recentLogs.add(entry);
      _scheduleAggregationFlush();

      // Only try to aggregate if we have 10+ similar logs (to allow larger batches)
      // Otherwise, let the flush timer handle it when it fires
      if (similarLogs.length >= 9) {
        // 9 existing + 1 new = 10 total
        _tryAggregate(entry);
      }
      return true;
    }

    // No similar logs found - this is a different type of log
    // Flush any pending aggregated logs before adding this new one
    _flushAggregatedLogs();
    _recentLogs.add(entry);
    _scheduleAggregationFlush();
    return true; // Still buffer it in case more similar logs come
  }

  /// Write a single log entry to file
  static Future<void> _writeLogEntry(_LogEntry entry) async {
    try {
      final timestamp = entry.timestamp.toIso8601String();
      final buffer = StringBuffer();
      final componentStr = entry.component != null
          ? '[${entry.component}] '
          : '';
      buffer.writeln(
        '[$timestamp] [${entry.level}] $componentStr${entry.message}',
      );

      if (entry.error != null) {
        buffer.writeln('Error: ${entry.error}');
      }

      if (entry.stackTrace != null) {
        buffer.writeln('StackTrace: ${entry.stackTrace}');
      }

      // Check file size and rotate if needed (check more aggressively)
      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        // Rotate if file exceeds 80% of max size (rotate before hitting limit)
        if (size > (_maxLogFileSize * 0.8)) {
          await _rotateLogs();
        }
      }

      await _logFile!.writeAsString(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      // Silently fail if file writing fails
      _logger.error('[LoggingService] Failed to write to log file: $e');
    }
  }

  /// Try to aggregate a log entry with recent logs
  static void _tryAggregate(_LogEntry entry) {
    // Find similar logs (same component, level, similar message pattern)
    // Note: entry is already in _recentLogs at this point
    final similarLogs = _recentLogs
        .where(
          (log) =>
              log.component == entry.component &&
              log.level == entry.level &&
              _isSimilarMessage(log.message, entry.message),
        )
        .toList();

    // Need at least 2 similar logs (including current entry) to aggregate
    if (similarLogs.length < 2) return;

    // Extract base message and variable parts from all similar logs
    final allMessages = similarLogs.map((l) => l.message).toList();
    final baseMessage = _extractBaseMessage(allMessages);
    if (baseMessage == null) {
      // If we can't extract base message, try a simpler approach
      // Just check if all messages have the same method name
      final methodNames = allMessages
          .map((m) => m.split('(').first.trim())
          .toSet();
      if (methodNames.length == 1) {
        // All have same method name, use it as base
        final simpleBase = '${methodNames.first}()';
        final variableParts = similarLogs
            .map((log) => _extractVariableParts(log.message, simpleBase))
            .toList();
        final group = _AggregatedLogGroup(
          level: entry.level,
          component: entry.component,
          baseMessage: simpleBase,
          variableParts: variableParts,
          count: similarLogs.length,
          firstTimestamp: similarLogs.first.timestamp,
          lastTimestamp: entry.timestamp,
        );
        _recentLogs.removeWhere((log) => similarLogs.contains(log));
        _writeAggregatedLog(group);
      }
      return;
    }

    // Extract variable parts
    final variableParts = similarLogs
        .map((log) => _extractVariableParts(log.message, baseMessage))
        .toList();

    // Create aggregated group (count includes all similar logs)
    final group = _AggregatedLogGroup(
      level: entry.level,
      component: entry.component,
      baseMessage: baseMessage,
      variableParts: variableParts,
      count: similarLogs.length,
      firstTimestamp: similarLogs.first.timestamp,
      lastTimestamp: entry.timestamp,
    );

    // Remove similar logs from recent logs (they'll be written as aggregated)
    _recentLogs.removeWhere((log) => similarLogs.contains(log));

    // Write aggregated log (this will also log to console)
    _writeAggregatedLog(group);
  }

  /// Check if two messages are similar (same method, different parameters)
  static bool _isSimilarMessage(String msg1, String msg2) {
    // Extract method name (text before first parenthesis)
    final method1 = msg1.split('(').first.trim();
    final method2 = msg2.split('(').first.trim();

    if (method1 != method2) return false;

    // Check if both have parameters (must have opening parenthesis)
    if (!msg1.contains('(') || !msg2.contains('(')) return false;

    // Both must have the same method name and both have parameters
    return true;
  }

  /// Extract base message pattern from multiple similar messages
  static String? _extractBaseMessage(List<String> messages) {
    if (messages.isEmpty) return null;

    final first = messages.first;
    final methodName = first.split('(').first.trim();

    // Extract parameter patterns from all messages
    final patterns = messages.map((msg) {
      // Match content inside first set of parentheses
      final match = RegExp(r'\(([^)]+)\)').firstMatch(msg);
      return match?.group(1) ?? '';
    }).toList();

    // Check if all patterns are non-empty and unique (different parameters)
    // This means we can aggregate them
    if (patterns.every((p) => p.isNotEmpty)) {
      // Count how many times each pattern appears
      final patternCounts = <String, int>{};
      for (final pattern in patterns) {
        patternCounts[pattern] = (patternCounts[pattern] ?? 0) + 1;
      }

      // If all patterns appear exactly once, they're all different - can aggregate
      if (patternCounts.values.every((count) => count == 1)) {
        return '$methodName()';
      }
    }

    return null;
  }

  /// Extract variable parts from a message
  static String _extractVariableParts(String message, String baseMessage) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(message);
    return match?.group(1) ?? '';
  }

  /// Write an aggregated log entry
  static Future<void> _writeAggregatedLog(_AggregatedLogGroup group) async {
    try {
      final timestamp = group.firstTimestamp.toIso8601String();
      final buffer = StringBuffer();
      final componentStr = group.component != null
          ? '[${group.component}] '
          : '';

      // Format aggregated message
      final summary = _formatAggregatedSummary(group);
      buffer.writeln(
        '[$timestamp] [${group.level}] [AGGREGATED] $componentStr${group.baseMessage} called ${group.count} times $summary',
      );

      // Check file size and rotate if needed (check more aggressively)
      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        // Rotate if file exceeds 80% of max size (rotate before hitting limit)
        if (size > (_maxLogFileSize * 0.8)) {
          await _rotateLogs();
        }
      }

      await _logFile!.writeAsString(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );

      // Also log to console with appropriate level
      final componentStr2 = group.component != null
          ? '[${group.component}] '
          : '';
      final aggregatedMessage =
          '[AGGREGATED] $componentStr2${group.baseMessage} called ${group.count} times $summary';
      switch (group.level) {
        case 'DEBUG':
          _logger.debug(aggregatedMessage);
          break;
        case 'INFO':
          _logger.info(aggregatedMessage);
          break;
        case 'WARNING':
          _logger.warning(aggregatedMessage);
          break;
        case 'ERROR':
        case 'SEVERE':
          _logger.error(aggregatedMessage);
          break;
        default:
          _logger.info(aggregatedMessage);
      }
    } catch (e) {
      _logger.error('[LoggingService] Failed to write aggregated log: $e');
    }
  }

  /// Format summary of aggregated variable parts
  static String _formatAggregatedSummary(_AggregatedLogGroup group) {
    if (group.variableParts.isEmpty) return '';

    // Try to extract common parameter names and values
    final paramMap = <String, List<String>>{};

    for (final part in group.variableParts) {
      // Parse parameters like "date=2025-11-01" or "habitId=20"
      final params = part.split(',');
      for (final param in params) {
        final trimmed = param.trim();
        final match = RegExp(r'(\w+)=(.+)').firstMatch(trimmed);
        if (match != null) {
          final key = match.group(1)!;
          final value = match.group(2)!;
          paramMap.putIfAbsent(key, () => []).add(value);
        }
      }
    }

    if (paramMap.isEmpty) {
      // Fallback: just show count of unique values
      final uniqueParts = group.variableParts.toSet();
      if (uniqueParts.length <= 10) {
        return '(params: ${uniqueParts.join(", ")})';
      } else {
        return '(params: ${uniqueParts.take(5).join(", ")} ... and ${uniqueParts.length - 5} more)';
      }
    }

    // Format each parameter
    final summaries = <String>[];
    for (final entry in paramMap.entries) {
      final key = entry.key;
      final values = entry.value.toSet().toList();

      if (values.length == 1) {
        summaries.add('$key=${values.first}');
      } else if (values.length <= 5) {
        summaries.add('$key: ${values.join(", ")}');
      } else {
        // Try to detect ranges (for dates, IDs)
        final sorted =
            values
                .map((v) {
                  // Try to parse as number
                  final num = int.tryParse(v);
                  if (num != null) return num;
                  // Try to parse as date
                  final date = DateTime.tryParse(v);
                  if (date != null) return date.millisecondsSinceEpoch;
                  return null;
                })
                .whereType<num>()
                .toList()
              ..sort();

        if (sorted.length == values.length && sorted.length > 1) {
          summaries.add('$key: ${values.first} to ${values.last}');
        } else {
          summaries.add(
            '$key: ${values.take(3).join(", ")} ... and ${values.length - 3} more',
          );
        }
      }
    }

    return summaries.isEmpty ? '' : '(${summaries.join(", ")})';
  }

  /// Schedule aggregation flush
  static void _scheduleAggregationFlush() {
    _aggregationTimer?.cancel();
    _aggregationTimer = Timer(_aggregationTimeout, () {
      _flushAggregatedLogs();
    });
  }

  /// Flush any remaining aggregated logs
  static void _flushAggregatedLogs() {
    if (_recentLogs.isEmpty) {
      _aggregationTimer?.cancel();
      _aggregationTimer = null;
      return;
    }

    // Group remaining logs by similarity before flushing
    final processed = <_LogEntry>{};
    final remaining = <_LogEntry>[];

    for (final entry in _recentLogs) {
      if (processed.contains(entry)) continue;

      // Find all similar logs to this one
      final similarLogs = _recentLogs
          .where(
            (log) =>
                !processed.contains(log) &&
                log.component == entry.component &&
                log.level == entry.level &&
                _isSimilarMessage(log.message, entry.message),
          )
          .toList();

      if (similarLogs.length >= 2) {
        // Try to aggregate this group
        final allMessages = similarLogs.map((l) => l.message).toList();
        final baseMessage = _extractBaseMessage(allMessages);

        if (baseMessage != null ||
            similarLogs
                    .map((m) => m.message.split('(').first.trim())
                    .toSet()
                    .length ==
                1) {
          // Can aggregate
          final simpleBase =
              baseMessage ??
              '${similarLogs.first.message.split('(').first.trim()}()';
          final variableParts = similarLogs
              .map((log) => _extractVariableParts(log.message, simpleBase))
              .toList();
          final group = _AggregatedLogGroup(
            level: entry.level,
            component: entry.component,
            baseMessage: simpleBase,
            variableParts: variableParts,
            count: similarLogs.length,
            firstTimestamp: similarLogs.first.timestamp,
            lastTimestamp: similarLogs.last.timestamp,
          );
          _writeAggregatedLog(group);
          processed.addAll(similarLogs);
        } else {
          // Can't aggregate, add to remaining
          remaining.addAll(similarLogs);
          processed.addAll(similarLogs);
        }
      } else {
        // Not enough similar logs, add to remaining
        remaining.add(entry);
        processed.add(entry);
      }
    }

    // Write any remaining individual logs that couldn't be aggregated
    for (final entry in remaining) {
      final componentStr = entry.component != null
          ? '[${entry.component}] '
          : '';
      final message = '$componentStr${entry.message}';
      switch (entry.level) {
        case 'DEBUG':
          _logger.debug(message);
          break;
        case 'INFO':
          _logger.info(message);
          break;
        case 'WARNING':
          _logger.warning(message);
          break;
        default:
          _logger.info(message);
      }
      _writeLogEntry(entry);
    }

    _recentLogs.clear();
    _aggregationTimer?.cancel();
    _aggregationTimer = null;
  }

  /// Rotate log files
  /// Check and rotate logs on startup if they're too large
  static Future<void> _checkAndRotateLogsOnStartup() async {
    try {
      if (_logFile == null) return;

      if (await _logFile!.exists()) {
        int size = await _logFile!.length();
        // Rotate if file is larger than max size (even if just slightly over)
        if (size > _maxLogFileSize) {
          // For very large files, rotate multiple times to reduce size
          int rotationCount = 0;
          const maxStartupRotations = 20; // Allow more rotations on startup

          while (size > _maxLogFileSize && await _logFile!.exists()) {
            // Safety: don't rotate more than maxStartupRotations times
            if (++rotationCount > maxStartupRotations) {
              // If we've rotated many times, force cleanup and break
              await _cleanupOldLogs();
              break;
            }

            await _rotateLogs();
            if (await _logFile!.exists()) {
              size = await _logFile!.length();
            } else {
              break;
            }
          }

          // Clean up any large rotated files
          await _cleanupLargeRotatedFiles();
        }
      }

      // Also check total log directory size and clean up if needed
      await _cleanupOldLogs();
    } catch (e) {
      _logger.error(
        '[LoggingService] Failed to check/rotate logs on startup: $e',
      );
    }
  }

  /// Clean up old log files if total size exceeds limit
  static Future<void> _cleanupOldLogs() async {
    try {
      if (_logFile == null) return;

      final logDir = _logFile!.parent;
      if (!await logDir.exists()) return;

      // Get all log files
      final logFiles = <File>[];
      if (await _logFile!.exists()) {
        logFiles.add(_logFile!);
      }

      for (int i = 1; i <= _maxLogFiles; i++) {
        final rotatedFile = File(path.join(logDir.path, 'adati.log.$i'));
        if (await rotatedFile.exists()) {
          logFiles.add(rotatedFile);
        }
      }

      // Calculate total size
      int totalSize = 0;
      for (final file in logFiles) {
        totalSize += await file.length();
      }

      // If total size exceeds limit, delete oldest files
      if (totalSize > _maxTotalLogSize) {
        // Sort by modification time (oldest first)
        final filesWithTime = <MapEntry<File, DateTime>>[];
        for (final file in logFiles) {
          final stat = await file.stat();
          filesWithTime.add(MapEntry(file, stat.modified));
        }
        filesWithTime.sort((a, b) => a.value.compareTo(b.value));

        // Delete oldest files until we're under the limit
        for (final entry in filesWithTime) {
          if (totalSize <= _maxTotalLogSize) break;
          final fileSize = await entry.key.length();
          // Use safe delete for cross-platform compatibility
          final deleted = await _safeDelete(entry.key);
          if (deleted) {
            totalSize -= fileSize;
          }
        }
      }
    } catch (e) {
      _logger.error('[LoggingService] Failed to cleanup old logs: $e');
    }
  }

  /// Safely rename a file with cross-platform compatibility
  /// Handles platform differences: Linux/macOS don't overwrite, Windows may have locking issues
  static Future<bool> _safeRename(File source, File target) async {
    try {
      // On all platforms, delete target first to ensure rename works
      // Linux/macOS: rename() doesn't overwrite existing files
      // Windows: May have file locking issues, so delete first is safer
      if (await target.exists()) {
        try {
          await target.delete();
          // Small delay to ensure file system has processed deletion
          await Future.delayed(const Duration(milliseconds: 10));
        } catch (e) {
          // If deletion fails, try rename anyway (might work on some platforms)
          warning(
            'Failed to delete target before rename, attempting rename anyway: $e',
            component: 'LoggingService',
            error: e,
          );
        }
      }

      // Attempt rename with retry for Windows file locking issues
      int retries = 3;
      while (retries > 0) {
        try {
          await source.rename(target.path);
          return true;
        } catch (e) {
          retries--;
          if (retries > 0) {
            // Wait before retry (Windows file locking)
            await Future.delayed(Duration(milliseconds: 50 * (4 - retries)));
          } else {
            rethrow;
          }
        }
      }
      return false;
    } catch (e) {
      warning(
        'Failed to rename file from ${source.path} to ${target.path}: $e',
        component: 'LoggingService',
        error: e,
      );
      return false;
    }
  }

  /// Safely delete a file with cross-platform compatibility
  static Future<bool> _safeDelete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      // Log but don't throw - deletion failures are often non-critical
      warning(
        'Failed to delete file ${file.path}: $e',
        component: 'LoggingService',
        error: e,
      );
      return false;
    }
  }

  static Future<void> _rotateLogs() async {
    try {
      if (_logFile == null) return;

      final logDir = _logFile!.parent;

      // Rotate existing logs (from oldest to newest)
      for (int i = _maxLogFiles - 1; i >= 1; i--) {
        final oldFile = File(path.join(logDir.path, 'adati.log.$i'));
        final newFile = File(path.join(logDir.path, 'adati.log.${i + 1}'));

        if (await oldFile.exists()) {
          if (i + 1 >= _maxLogFiles) {
            // Delete oldest file (beyond max rotation count)
            await _safeDelete(oldFile);
          } else {
            // Rename to next number
            await _safeRename(oldFile, newFile);
          }
        }
      }

      // Move current log to .1
      if (await _logFile!.exists()) {
        final rotatedFile = File(path.join(logDir.path, 'adati.log.1'));

        // Use safe rename which handles all platform differences
        final success = await _safeRename(_logFile!, rotatedFile);

        if (!success) {
          throw Exception('Failed to rotate current log file');
        }
      }

      // Create new log file reference (file will be created on first write)
      _logFile = File(path.join(logDir.path, 'adati.log'));
    } catch (e, stackTrace) {
      _logger.error('[LoggingService] Failed to rotate logs: $e');
      error(
        'Failed to rotate logs',
        component: 'LoggingService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static void debug(
    String message, {
    String? component,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Skip debug logs in release mode
    if (kReleaseMode) return;

    // Check log level
    if (!_shouldLog(_levelDebug)) return;

    // Check if this should be aggregated (before logging to console)
    final now = DateTime.now();
    final entry = _LogEntry(
      level: 'DEBUG',
      message: message,
      component: component,
      timestamp: now,
      error: error,
      stackTrace: stackTrace,
    );

    if (_aggregationEnabled && error == null && stackTrace == null) {
      final shouldAggregate = _shouldAggregate(entry);
      if (shouldAggregate) {
        // Entry was added to _recentLogs and aggregation was attempted
        // Don't log to console yet - will be logged when aggregated or flushed
        // File logging will happen in _writeToFile which is called after aggregation check
        return;
      }
    }

    // Log to console immediately (not aggregated)
    final componentStr = component != null ? '[$component] ' : '';
    _logger.debug('$componentStr$message');
    if (error != null) {
      _logger.debug('Error: $error');
    }
    // Write to file (not aggregated)
    _writeToFile('DEBUG', message, component, error, stackTrace);
  }

  /// Enable or disable log aggregation
  static void setAggregationEnabled(bool enabled) {
    _aggregationEnabled = enabled;
    if (!enabled) {
      _flushAggregatedLogs();
    }
  }

  static void info(
    String message, {
    String? component,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Check log level
    if (!_shouldLog(_levelInfo)) return;

    // Check if this should be aggregated (before logging to console)
    final now = DateTime.now();
    final entry = _LogEntry(
      level: 'INFO',
      message: message,
      component: component,
      timestamp: now,
      error: error,
      stackTrace: stackTrace,
    );

    if (_aggregationEnabled && error == null && stackTrace == null) {
      final shouldAggregate = _shouldAggregate(entry);
      if (shouldAggregate) {
        // Entry was added to _recentLogs and aggregation was attempted
        // Don't log to console yet - will be logged when aggregated or flushed
        return;
      }
    }

    // Log to console immediately (not aggregated)
    final componentStr = component != null ? '[$component] ' : '';
    _logger.info('$componentStr$message');
    if (error != null) {
      _logger.info('Error: $error');
    }
    // Write to file (not aggregated)
    _writeToFile('INFO', message, component, error, stackTrace);
  }

  static void warning(
    String message, {
    String? component,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Check log level
    if (!_shouldLog(_levelWarning)) return;

    // Check if this should be aggregated (before logging to console)
    final now = DateTime.now();
    final entry = _LogEntry(
      level: 'WARNING',
      message: message,
      component: component,
      timestamp: now,
      error: error,
      stackTrace: stackTrace,
    );

    if (_aggregationEnabled && error == null && stackTrace == null) {
      final shouldAggregate = _shouldAggregate(entry);
      if (shouldAggregate) {
        // Entry was added to _recentLogs and aggregation was attempted
        // Don't log to console yet - will be logged when aggregated or flushed
        return;
      }
    }

    // Log to console immediately (not aggregated)
    final componentStr = component != null ? '[$component] ' : '';
    _logger.warning('$componentStr$message');
    if (error != null) {
      _logger.warning('Error: $error');
    }
    // Write to file (not aggregated)
    _writeToFile('WARNING', message, component, error, stackTrace);
  }

  static void error(
    String message, {
    String? component,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Check log level
    if (!_shouldLog(_levelError)) return;

    // Errors are never aggregated - always log immediately
    final componentStr = component != null ? '[$component] ' : '';
    _logger.error('$componentStr$message');
    if (error != null) {
      _logger.error('Error: $error');
    }
    _writeToFile('ERROR', message, component, error, stackTrace);
  }

  static void severe(
    String message, {
    String? component,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Check log level (severe errors are always logged, but we check anyway for consistency)
    if (!_shouldLog(_levelSevere)) return;

    // Severe errors are never aggregated - always log immediately
    final componentStr = component != null ? '[$component] ' : '';
    _logger.error('$componentStr$message');
    if (error != null) {
      _logger.error('Error: $error');
    }

    // Write to crash log file
    _writeToCrashFile(message, error, stackTrace);
    _writeToFile('SEVERE', message, component, error, stackTrace);

    // Update last crash info
    _lastCrashTime = DateTime.now();
    _lastCrashSummary = message.length > 100
        ? '${message.substring(0, 100)}...'
        : message;
  }

  /// Write to crash log file
  static Future<void> _writeToCrashFile(
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) async {
    if (!_initialized) {
      await init();
    }

    if (_crashLogFile == null) return;

    try {
      final timestamp = DateTime.now().toIso8601String();
      final buffer = StringBuffer();
      buffer.writeln('=' * 80);
      buffer.writeln('CRASH [$timestamp]');
      buffer.writeln('Message: $message');

      if (error != null) {
        buffer.writeln('Error: $error');
      }

      if (stackTrace != null) {
        buffer.writeln('StackTrace:');
        buffer.writeln(stackTrace);
      }
      buffer.writeln('=' * 80);
      buffer.writeln('');

      await _crashLogFile!.writeAsString(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      _logger.error('[LoggingService] Failed to write to crash log file: $e');
    }
  }

  /// Get log file path
  static Future<String?> getLogFilePath() async {
    if (!_initialized) {
      await init();
    }
    return _logFile?.path;
  }

  /// Get crash log file path
  static Future<String?> getCrashLogFilePath() async {
    if (!_initialized) {
      await init();
    }
    return _crashLogFile?.path;
  }

  /// Get log file size in bytes
  static Future<int> getLogFileSize() async {
    if (!_initialized) {
      await init();
    }
    if (_logFile == null || !await _logFile!.exists()) {
      return 0;
    }
    return await _logFile!.length();
  }

  /// Get crash log file size in bytes
  static Future<int> getCrashLogFileSize() async {
    if (!_initialized) {
      await init();
    }
    if (_crashLogFile == null || !await _crashLogFile!.exists()) {
      return 0;
    }
    return await _crashLogFile!.length();
  }

  /// Get last crash time
  static DateTime? getLastCrashTime() => _lastCrashTime;

  /// Get last crash summary
  static String? getLastCrashSummary() => _lastCrashSummary;

  /// Read last N bytes from a file efficiently
  static Future<String> _readLastBytes(File file, int bytesToRead) async {
    try {
      final fileSize = await file.length();
      if (fileSize == 0) return '';

      final startPos = fileSize > bytesToRead ? fileSize - bytesToRead : 0;
      final randomAccessFile = await file.open();
      try {
        await randomAccessFile.setPosition(startPos);
        final bytes = await randomAccessFile.read(fileSize - startPos);
        return utf8.decode(bytes, allowMalformed: true);
      } finally {
        await randomAccessFile.close();
      }
    } catch (e) {
      return '';
    }
  }

  /// Get log content (last N lines for performance)
  /// Returns combined main log and crash log
  static Future<String> getLogContent({int maxLines = 1000}) async {
    try {
      if (!_initialized) {
        await init();
      }

      final buffer = StringBuffer();
      bool hasContent = false;

      // Read main log
      if (_logFile != null) {
        try {
          final exists = await _logFile!.exists();
          if (exists) {
            final fileSize = await _logFile!.length();
            if (fileSize > 0) {
              String content;

              if (fileSize < 10 * 1024 * 1024) {
                // Small file: read entire file
                content = await _logFile!.readAsString();
              } else {
                // Large file: read only last 5MB (enough for ~1000 lines)
                const maxBytesToRead = 5 * 1024 * 1024; // 5MB
                content = await _readLastBytes(_logFile!, maxBytesToRead);
              }

              if (content.trim().isNotEmpty) {
                final lines = content
                    .split('\n')
                    .where((line) => line.trim().isNotEmpty)
                    .toList();
                if (lines.isNotEmpty) {
                  final startLine = lines.length > maxLines
                      ? lines.length - maxLines
                      : 0;
                  final logLines = lines.sublist(startLine);

                  if (startLine > 0 || fileSize >= 10 * 1024 * 1024) {
                    buffer.writeln(
                      '... (showing last $maxLines lines, file size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB) ...',
                    );
                  }
                  buffer.writeln('=== MAIN LOG ===');
                  buffer.writeln(logLines.join('\n'));
                  buffer.writeln('');
                  hasContent = true;
                }
              }
            }
          }
        } catch (e) {
          buffer.writeln('=== MAIN LOG ===');
          buffer.writeln('Error reading log file: $e');
          buffer.writeln('');
        }
      } else {
        buffer.writeln('=== MAIN LOG ===');
        buffer.writeln('(No log file found)');
        buffer.writeln('');
      }

      if (!hasContent && _logFile != null) {
        buffer.writeln('=== MAIN LOG ===');
        buffer.writeln('(No log entries found)');
        buffer.writeln('');
      }

      // Read crash log
      if (_crashLogFile != null) {
        try {
          final exists = await _crashLogFile!.exists();
          if (exists) {
            final fileSize = await _crashLogFile!.length();
            if (fileSize > 0) {
              String content;
              if (fileSize < 1024 * 1024) {
                // Small file: read entire file
                content = await _crashLogFile!.readAsString();
              } else {
                // Large file: read only last 1MB
                content = await _readLastBytes(_crashLogFile!, 1024 * 1024);
              }

              if (content.trim().isNotEmpty) {
                buffer.writeln('=== CRASH LOG ===');
                if (fileSize >= 1024 * 1024) {
                  buffer.writeln(
                    '... (showing last portion, file size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB) ...',
                  );
                }
                buffer.writeln(content);
                buffer.writeln('');
                hasContent = true;
              }
            }
          }
        } catch (e) {
          // Silently skip crash log errors
        }
      }

      final result = buffer.toString();
      return result.trim().isEmpty ? 'No logs available.' : result;
    } catch (e) {
      return 'Error reading logs: $e';
    }
  }

  /// Export logs to a file for download
  static Future<String?> exportLogs() async {
    if (!_initialized) {
      await init();
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory(path.join(directory.path, 'exports'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final exportFile = File(
        path.join(exportDir.path, 'adati_logs_$timestamp.txt'),
      );

      final buffer = StringBuffer();
      buffer.writeln('Adati Logs Export');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln('=' * 80);
      buffer.writeln('');

      // Write main log
      if (_logFile != null && await _logFile!.exists()) {
        buffer.writeln('=== MAIN LOG ===');
        buffer.writeln(await _logFile!.readAsString());
        buffer.writeln('');
      }

      // Write crash log
      if (_crashLogFile != null && await _crashLogFile!.exists()) {
        buffer.writeln('=== CRASH LOG ===');
        buffer.writeln(await _crashLogFile!.readAsString());
        buffer.writeln('');
      }

      // Write rotated logs
      final logDir = _logFile?.parent;
      if (logDir != null) {
        for (int i = 1; i <= _maxLogFiles; i++) {
          final rotatedFile = File(path.join(logDir.path, 'adati.log.$i'));
          if (await rotatedFile.exists()) {
            buffer.writeln('=== ROTATED LOG $i ===');
            buffer.writeln(await rotatedFile.readAsString());
            buffer.writeln('');
          }
        }
      }

      await exportFile.writeAsString(buffer.toString());
      return exportFile.path;
    } catch (e, stackTrace) {
      error(
        'Failed to export logs',
        component: 'LoggingService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Rotate and cleanup logs manually (can be called from settings)
  static Future<bool> rotateAndCleanupLogs() async {
    if (!_initialized) {
      await init();
    }

    try {
      info('Starting log rotation and cleanup', component: 'LoggingService');

      // First, delete all large rotated files immediately
      await _deleteLargeRotatedFiles();

      // Force rotation if current file is too large
      if (_logFile != null && await _logFile!.exists()) {
        int size = await _logFile!.length();
        info(
          'Current log file size: ${(size / (1024 * 1024)).toStringAsFixed(2)} MB',
          component: 'LoggingService',
        );

        int rotationCount = 0;
        const maxRotations = 50; // Allow many rotations for very large files

        // Rotate until current file is small
        while (size > _maxLogFileSize && await _logFile!.exists()) {
          if (++rotationCount > maxRotations) {
            // If we've rotated many times, delete the large rotated file and break
            info(
              'Reached max rotations ($maxRotations), cleaning up',
              component: 'LoggingService',
            );
            await _deleteLargeRotatedFiles();
            break;
          }

          info(
            'Rotating log file (rotation $rotationCount)',
            component: 'LoggingService',
          );
          await _rotateLogs();

          // After rotation, delete any large rotated files that were just created
          await _deleteLargeRotatedFiles();

          // Check new file size (should be small after rotation)
          if (await _logFile!.exists()) {
            size = await _logFile!.length();
            info(
              'After rotation, new file size: ${(size / (1024 * 1024)).toStringAsFixed(2)} MB',
              component: 'LoggingService',
            );
          } else {
            break;
          }
        }
      }

      // Cleanup old logs to ensure total size is under limit
      await _cleanupOldLogs();

      // Final cleanup of any remaining large files
      await _deleteLargeRotatedFiles();

      info('Log rotation and cleanup completed', component: 'LoggingService');
      return true;
    } catch (e, stackTrace) {
      error(
        'Failed to rotate and cleanup logs',
        component: 'LoggingService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Delete rotated log files that are too large (more aggressive than _cleanupLargeRotatedFiles)
  static Future<void> _deleteLargeRotatedFiles() async {
    try {
      if (_logFile == null) return;

      final logDir = _logFile!.parent;
      if (!await logDir.exists()) return;

      // Delete ALL rotated files that are larger than max size
      for (int i = 1; i <= _maxLogFiles; i++) {
        final rotatedFile = File(path.join(logDir.path, 'adati.log.$i'));
        if (await rotatedFile.exists()) {
          try {
            final size = await rotatedFile.length();
            // Delete any rotated file larger than max size
            if (size > _maxLogFileSize) {
              info(
                'Deleting large rotated file: adati.log.$i (${(size / (1024 * 1024)).toStringAsFixed(2)} MB)',
                component: 'LoggingService',
              );
              // Use safe delete for cross-platform compatibility
              await _safeDelete(rotatedFile);
            }
          } catch (e) {
            // Log deletion errors for debugging on Linux
            warning(
              'Failed to delete large rotated file adati.log.$i: $e',
              component: 'LoggingService',
              error: e,
            );
          }
        }
      }
    } catch (e) {
      warning(
        'Error in _deleteLargeRotatedFiles: $e',
        component: 'LoggingService',
        error: e,
      );
    }
  }

  /// Clean up rotated log files that are too large
  static Future<void> _cleanupLargeRotatedFiles() async {
    try {
      if (_logFile == null) return;

      final logDir = _logFile!.parent;
      if (!await logDir.exists()) return;

      // Check all rotated files and delete ones that are too large
      for (int i = 1; i <= _maxLogFiles; i++) {
        final rotatedFile = File(path.join(logDir.path, 'adati.log.$i'));
        if (await rotatedFile.exists()) {
          final size = await rotatedFile.length();
          // Delete rotated files larger than max size (they shouldn't exist, but clean up if they do)
          // Use a more lenient threshold for cleanup (2x max) to avoid deleting files that are just slightly over
          if (size > _maxLogFileSize * 2) {
            // Use safe delete for cross-platform compatibility
            await _safeDelete(rotatedFile);
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear all log files
  static Future<bool> clearLogs() async {
    if (!_initialized) {
      await init();
    }

    try {
      // Clear main log
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.writeAsString('');
      }

      // Clear crash log
      if (_crashLogFile != null && await _crashLogFile!.exists()) {
        await _crashLogFile!.writeAsString('');
      }

      // Clear rotated logs
      final logDir = _logFile?.parent;
      if (logDir != null) {
        for (int i = 1; i <= _maxLogFiles; i++) {
          final rotatedFile = File(path.join(logDir.path, 'adati.log.$i'));
          if (await rotatedFile.exists()) {
            await rotatedFile.delete();
          }
        }
      }

      _lastCrashTime = null;
      _lastCrashSummary = null;

      info('Logs cleared', component: 'LoggingService');
      return true;
    } catch (e, stackTrace) {
      error(
        'Failed to clear logs',
        component: 'LoggingService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Send logs to GitHub as an issue
  static Future<bool> sendLogsToGitHub(String title, String description) async {
    if (!_initialized) {
      await init();
    }

    try {
      // Get GitHub token from environment or use placeholder
      final token = dotenv.env['GITHUB_TOKEN'];
      if (token == null || token.isEmpty) {
        error('GITHUB_TOKEN not found in environment variables');
        return false;
      }

      // Read log content
      final buffer = StringBuffer();
      buffer.writeln(description);
      buffer.writeln('');
      buffer.writeln('---');
      buffer.writeln('');

      // Add main log (last 5000 lines to avoid size limits)
      if (_logFile != null && await _logFile!.exists()) {
        final logContent = await _logFile!.readAsString();
        final lines = logContent.split('\n');
        final recentLines = lines.length > 5000
            ? lines.sublist(lines.length - 5000)
            : lines;
        buffer.writeln('### Main Log (last ${recentLines.length} lines)');
        buffer.writeln('```');
        buffer.writeln(recentLines.join('\n'));
        buffer.writeln('```');
        buffer.writeln('');
      }

      // Add crash log
      if (_crashLogFile != null && await _crashLogFile!.exists()) {
        final crashContent = await _crashLogFile!.readAsString();
        if (crashContent.isNotEmpty) {
          buffer.writeln('### Crash Log');
          buffer.writeln('```');
          buffer.writeln(crashContent);
          buffer.writeln('```');
        }
      }

      // Create GitHub issue
      final response = await http.post(
        Uri.parse('https://api.github.com/repos/Zyzto/Adati/issues'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'body': buffer.toString(),
          'labels': ['bug', 'logs'],
        }),
      );

      if (response.statusCode == 201) {
        final issueData = jsonDecode(response.body);
        info(
          'Logs sent to GitHub issue #${issueData['number']}',
          component: 'LoggingService',
        );
        return true;
      } else {
        error(
          'Failed to create GitHub issue: ${response.statusCode} - ${response.body}',
          component: 'LoggingService',
        );
        return false;
      }
    } catch (e, stackTrace) {
      error(
        'Failed to send logs to GitHub',
        component: 'LoggingService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Format logs for GitHub issue body
  static Future<String> formatLogsForGitHub(String userDescription) async {
    if (!_initialized) {
      await init();
    }

    final buffer = StringBuffer();
    buffer.writeln(userDescription);
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');

    // Add main log (last 5000 lines)
    if (_logFile != null && await _logFile!.exists()) {
      final logContent = await _logFile!.readAsString();
      final lines = logContent.split('\n');
      final recentLines = lines.length > 5000
          ? lines.sublist(lines.length - 5000)
          : lines;
      buffer.writeln('### Main Log (last ${recentLines.length} lines)');
      buffer.writeln('```');
      buffer.writeln(recentLines.join('\n'));
      buffer.writeln('```');
      buffer.writeln('');
    }

    // Add crash log
    if (_crashLogFile != null && await _crashLogFile!.exists()) {
      final crashContent = await _crashLogFile!.readAsString();
      if (crashContent.isNotEmpty) {
        buffer.writeln('### Crash Log');
        buffer.writeln('```');
        buffer.writeln(crashContent);
        buffer.writeln('```');
      }
    }

    return buffer.toString();
  }
}
