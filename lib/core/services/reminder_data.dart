import 'dart:convert';
import 'log_helper.dart';

/// Reminder data model representing a habit's reminder configuration
class ReminderData {
  final String frequency; // 'daily', 'weekly', or 'monthly'
  final List<int> days; // For weekly: 1-7 (Mon-Sun), For monthly: 1-31
  final String time; // HH:mm format

  ReminderData({
    required this.frequency,
    required this.days,
    required this.time,
  });

  /// Convert to JSON string
  String toJson() {
    return jsonEncode({
      'frequency': frequency,
      'days': days,
      'time': time,
    });
  }

  /// Parse from JSON string
  static ReminderData? fromJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ReminderData(
        frequency: data['frequency'] as String? ?? 'daily',
        days: (data['days'] as List<dynamic>?)?.cast<int>() ?? [],
        time: data['time'] as String? ?? '09:00',
      );
    } catch (e, stackTrace) {
      Log.error(
        'Failed to parse reminder data from JSON: $jsonStr',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Parse from legacy "HH:mm" format (for backward compatibility)
  static ReminderData fromLegacy(String timeStr) {
    return ReminderData(
      frequency: 'daily',
      days: [],
      time: timeStr,
    );
  }

  /// Validate reminder data
  static bool validate(ReminderData data) {
    // Validate frequency
    if (!['daily', 'weekly', 'monthly'].contains(data.frequency)) {
      Log.warning('Invalid reminder frequency: ${data.frequency}');
      return false;
    }

    // Validate time format (HH:mm)
    final timeParts = data.time.split(':');
    if (timeParts.length != 2) {
      Log.warning('Invalid time format: ${data.time}');
      return false;
    }

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);

    if (hour == null || minute == null) {
      Log.warning('Invalid time format: ${data.time}');
      return false;
    }

    if (hour < 0 || hour > 23) {
      Log.warning('Invalid hour: $hour');
      return false;
    }

    if (minute < 0 || minute > 59) {
      Log.warning('Invalid minute: $minute');
      return false;
    }

    // Validate days based on frequency
    if (data.frequency == 'weekly') {
      for (final day in data.days) {
        if (day < 1 || day > 7) {
          Log.warning('Invalid weekday: $day (must be 1-7)');
          return false;
        }
      }
    } else if (data.frequency == 'monthly') {
      for (final day in data.days) {
        if (day < 1 || day > 31) {
          Log.warning('Invalid month day: $day (must be 1-31)');
          return false;
        }
      }
    }

    return true;
  }

  @override
  String toString() {
    return 'ReminderData(frequency: $frequency, days: $days, time: $time)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReminderData &&
        other.frequency == frequency &&
        other.days.toString() == days.toString() &&
        other.time == time;
  }

  @override
  int get hashCode => Object.hash(frequency, days.toString(), time);

  /// Calculate the next occurrence date for this reminder
  /// Returns a list of DateTime objects for the next occurrences (up to maxDays ahead)
  /// For daily: returns next maxDays days
  /// For weekly: returns next occurrences on specified weekdays
  /// For monthly: returns next occurrences on specified days of month
  List<DateTime> getNextOccurrences({int maxDays = 3}) {
    final now = DateTime.now();
    final timeParts = time.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 9;
    final minute = int.tryParse(timeParts[1]) ?? 0;

    final occurrences = <DateTime>[];

    if (frequency == 'daily') {
      // Daily: schedule for next maxDays days
      // Start from today (i=0) to catch reminders set for today
      for (int i = 0; i < maxDays; i++) {
        final date = now.add(Duration(days: i));
        final scheduled = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
        // Add if it's in the future (with 30 second buffer to account for processing delays)
        // This ensures reminders set 1 minute away are still scheduled
        if (scheduled.isAfter(now.subtract(const Duration(seconds: 30)))) {
          occurrences.add(scheduled);
        }
      }
    } else if (frequency == 'weekly' && days.isNotEmpty) {
      // Weekly: find next occurrences on specified weekdays
      for (int i = 0; i < maxDays; i++) {
        final date = now.add(Duration(days: i));
        final weekday = date.weekday; // 1=Monday, 7=Sunday
        if (days.contains(weekday)) {
          final scheduled = DateTime(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
          );
          // Add if it's in the future (with 30 second buffer)
          if (scheduled.isAfter(now.subtract(const Duration(seconds: 30)))) {
            occurrences.add(scheduled);
          }
        }
      }
    } else if (frequency == 'monthly' && days.isNotEmpty) {
      // Monthly: find next occurrences on specified days of month
      for (int i = 0; i < maxDays; i++) {
        final date = now.add(Duration(days: i));
        final dayOfMonth = date.day;
        if (days.contains(dayOfMonth)) {
          final scheduled = DateTime(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
          );
          // Add if it's in the future (with 30 second buffer)
          if (scheduled.isAfter(now.subtract(const Duration(seconds: 30)))) {
            occurrences.add(scheduled);
          }
        }
      }
    }

    return occurrences;
  }
}

/// Validator for reminder data
class ReminderDataValidator {
  /// Parse and validate reminder data from JSON string
  /// Returns ReminderData if valid, null otherwise
  static ReminderData? parseAndValidate(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) {
      return null;
    }

    ReminderData? data;

    // Try parsing as JSON first
    try {
      data = ReminderData.fromJson(jsonStr);
    } catch (e) {
      // If JSON parsing fails, try legacy format
      Log.debug('Failed to parse as JSON, trying legacy format: $jsonStr');
      try {
        data = ReminderData.fromLegacy(jsonStr);
      } catch (e2) {
        Log.warning('Failed to parse reminder data in any format: $jsonStr');
        return null;
      }
    }

    if (data == null) {
      return null;
    }

    // Validate the parsed data
    if (!ReminderData.validate(data)) {
      Log.warning('Reminder data validation failed: $data');
      return null;
    }

    return data;
  }

  /// Check if reminder data is consistent with reminderEnabled flag
  static bool isConsistent(bool reminderEnabled, String? reminderTime) {
    if (reminderEnabled) {
      // If enabled, reminderTime must be valid
      if (reminderTime == null || reminderTime.isEmpty) {
        return false;
      }
      final data = parseAndValidate(reminderTime);
      return data != null;
    } else {
      // If disabled, reminderTime should be null
      return reminderTime == null || reminderTime.isEmpty;
    }
  }
}
