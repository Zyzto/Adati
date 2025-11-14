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

