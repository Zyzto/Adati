import 'package:intl/intl.dart';
import '../services/preferences_service.dart';

class DateUtils {
  static DateTime getToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime getDateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return getDateOnly(date1).isAtSameMomentAs(getDateOnly(date2));
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  static List<DateTime> getDaysRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = getDateOnly(start);
    final endDate = getDateOnly(end);

    while (!current.isAfter(endDate)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  static List<DateTime> getLastNDays(int n) {
    final today = getToday();
    final start = today.subtract(Duration(days: n - 1));
    return getDaysRange(start, today);
  }

  static String formatDate(DateTime date, {String? format}) {
    final dateFormat = format ?? PreferencesService.getDateFormat();
    return DateFormat(dateFormat).format(date);
  }

  static String formatDateShort(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isYesterday(date)) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }

  static int daysBetween(DateTime start, DateTime end) {
    final startDate = getDateOnly(start);
    final endDate = getDateOnly(end);
    return endDate.difference(startDate).inDays;
  }

  static int getFirstDayOfWeek() {
    return PreferencesService.getFirstDayOfWeek();
  }

  /// Check if a date is on or after the habit creation date
  /// Returns true if the date is >= habit creation date (same day or later)
  static bool isDateAfterHabitCreation(DateTime date, DateTime habitCreatedAt) {
    final dateOnly = getDateOnly(date);
    final habitCreatedAtOnly = getDateOnly(habitCreatedAt);
    return !dateOnly.isBefore(habitCreatedAtOnly);
  }
}

