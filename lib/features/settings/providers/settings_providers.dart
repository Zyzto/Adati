import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/preferences_service.dart';

ThemeMode _getInitialThemeMode() {
  final savedMode = PreferencesService.getThemeMode();
  if (savedMode == null) return ThemeMode.system;
  
  switch (savedMode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

class ThemeModeNotifier {
  ThemeMode _mode;

  ThemeModeNotifier() : _mode = _getInitialThemeMode() {
    _loadThemeMode();
  }

  ThemeMode get mode => _mode;

  Future<void> _loadThemeMode() async {
    final savedMode = PreferencesService.getThemeMode();
    if (savedMode != null) {
      switch (savedMode) {
        case 'light':
          _mode = ThemeMode.light;
          break;
        case 'dark':
          _mode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _mode = ThemeMode.system;
          break;
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _mode = mode;
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await PreferencesService.setThemeMode(modeString);
  }

  String getThemeModeString() {
    switch (_mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

final themeModeNotifierProvider = Provider<ThemeModeNotifier>((ref) {
  return ThemeModeNotifier();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeModeNotifierProvider).mode;
});

class TimelineDaysNotifier {
  int _days;

  TimelineDaysNotifier() : _days = PreferencesService.getTimelineDays();

  int get days => _days;

  Future<void> setTimelineDays(int days) async {
    _days = days;
    await PreferencesService.setTimelineDays(days);
  }
}

final timelineDaysNotifierProvider = Provider<TimelineDaysNotifier>((ref) {
  return TimelineDaysNotifier();
});

final timelineDaysProvider = Provider<int>((ref) {
  return ref.watch(timelineDaysNotifierProvider).days;
});

// Theme Color
class ThemeColorNotifier {
  int _color;

  ThemeColorNotifier() : _color = PreferencesService.getThemeColor();

  int get color => _color;

  Future<void> setThemeColor(int color) async {
    _color = color;
    await PreferencesService.setThemeColor(color);
  }
}

final themeColorNotifierProvider = Provider<ThemeColorNotifier>((ref) {
  return ThemeColorNotifier();
});

final themeColorProvider = Provider<int>((ref) {
  return ref.watch(themeColorNotifierProvider).color;
});

// Card Style
class CardStyleNotifier {
  double _elevation;
  double _borderRadius;

  CardStyleNotifier()
      : _elevation = PreferencesService.getCardElevation(),
        _borderRadius = PreferencesService.getCardBorderRadius();

  double get elevation => _elevation;
  double get borderRadius => _borderRadius;

  Future<void> setElevation(double elevation) async {
    _elevation = elevation;
    await PreferencesService.setCardElevation(elevation);
  }

  Future<void> setBorderRadius(double borderRadius) async {
    _borderRadius = borderRadius;
    await PreferencesService.setCardBorderRadius(borderRadius);
  }
}

final cardStyleNotifierProvider = Provider<CardStyleNotifier>((ref) {
  return CardStyleNotifier();
});

final cardElevationProvider = Provider<double>((ref) {
  return ref.watch(cardStyleNotifierProvider).elevation;
});

final cardBorderRadiusProvider = Provider<double>((ref) {
  return ref.watch(cardStyleNotifierProvider).borderRadius;
});

// Day Square Size
class DaySquareSizeNotifier {
  String _size;

  DaySquareSizeNotifier() : _size = PreferencesService.getDaySquareSize();

  String get size => _size;

  Future<void> setDaySquareSize(String size) async {
    _size = size;
    await PreferencesService.setDaySquareSize(size);
  }
}

final daySquareSizeNotifierProvider = Provider<DaySquareSizeNotifier>((ref) {
  return DaySquareSizeNotifier();
});

final daySquareSizeProvider = Provider<String>((ref) {
  return ref.watch(daySquareSizeNotifierProvider).size;
});

// Date Format
class DateFormatNotifier {
  String _format;

  DateFormatNotifier() : _format = PreferencesService.getDateFormat();

  String get format => _format;

  Future<void> setDateFormat(String format) async {
    _format = format;
    await PreferencesService.setDateFormat(format);
  }
}

final dateFormatNotifierProvider = Provider<DateFormatNotifier>((ref) {
  return DateFormatNotifier();
});

final dateFormatProvider = Provider<String>((ref) {
  return ref.watch(dateFormatNotifierProvider).format;
});

// First Day of Week
class FirstDayOfWeekNotifier {
  int _day;

  FirstDayOfWeekNotifier() : _day = PreferencesService.getFirstDayOfWeek();

  int get day => _day;

  Future<void> setFirstDayOfWeek(int day) async {
    _day = day;
    await PreferencesService.setFirstDayOfWeek(day);
  }
}

final firstDayOfWeekNotifierProvider = Provider<FirstDayOfWeekNotifier>((ref) {
  return FirstDayOfWeekNotifier();
});

final firstDayOfWeekProvider = Provider<int>((ref) {
  return ref.watch(firstDayOfWeekNotifierProvider).day;
});

// Notifications Enabled
class NotificationsEnabledNotifier {
  bool _enabled;

  NotificationsEnabledNotifier() : _enabled = PreferencesService.getNotificationsEnabled();

  bool get enabled => _enabled;

  Future<void> setNotificationsEnabled(bool enabled) async {
    _enabled = enabled;
    await PreferencesService.setNotificationsEnabled(enabled);
  }
}

final notificationsEnabledNotifierProvider = Provider<NotificationsEnabledNotifier>((ref) {
  return NotificationsEnabledNotifier();
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(notificationsEnabledNotifierProvider).enabled;
});

// Habit Checkbox Style
class HabitCheckboxStyleNotifier {
  String _style;

  HabitCheckboxStyleNotifier()
      : _style = PreferencesService.getHabitCheckboxStyle();

  String get style => _style;

  Future<void> setHabitCheckboxStyle(String style) async {
    _style = style;
    await PreferencesService.setHabitCheckboxStyle(style);
  }
}

final habitCheckboxStyleNotifierProvider =
    Provider<HabitCheckboxStyleNotifier>((ref) {
  return HabitCheckboxStyleNotifier();
});

final habitCheckboxStyleProvider = Provider<String>((ref) {
  return ref.watch(habitCheckboxStyleNotifierProvider).style;
});

// Modal Timeline Days
class ModalTimelineDaysNotifier {
  int _days;

  ModalTimelineDaysNotifier() : _days = PreferencesService.getModalTimelineDays();

  int get days => _days;

  Future<void> setModalTimelineDays(int days) async {
    _days = days;
    await PreferencesService.setModalTimelineDays(days);
  }
}

final modalTimelineDaysNotifierProvider = Provider<ModalTimelineDaysNotifier>((ref) {
  return ModalTimelineDaysNotifier();
});

final modalTimelineDaysProvider = Provider<int>((ref) {
  return ref.watch(modalTimelineDaysNotifierProvider).days;
});

// Habit Sort Order
class HabitSortOrderNotifier {
  String _order;

  HabitSortOrderNotifier() : _order = PreferencesService.getHabitSortOrder();

  String get order => _order;

  Future<void> setHabitSortOrder(String order) async {
    _order = order;
    await PreferencesService.setHabitSortOrder(order);
  }
}

final habitSortOrderNotifierProvider = Provider<HabitSortOrderNotifier>((ref) {
  return HabitSortOrderNotifier();
});

final habitSortOrderProvider = Provider<String>((ref) {
  return ref.watch(habitSortOrderNotifierProvider).order;
});

// Habit Filter Query
class HabitFilterQueryNotifier {
  String? _query;

  HabitFilterQueryNotifier() : _query = PreferencesService.getHabitFilterQuery();

  String? get query => _query;

  Future<void> setHabitFilterQuery(String? query) async {
    _query = query;
    await PreferencesService.setHabitFilterQuery(query);
  }
}

final habitFilterQueryNotifierProvider = Provider<HabitFilterQueryNotifier>((ref) {
  return HabitFilterQueryNotifier();
});

final habitFilterQueryProvider = Provider<String?>((ref) {
  return ref.watch(habitFilterQueryNotifierProvider).query;
});

