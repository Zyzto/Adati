import 'package:shared_preferences/shared_preferences.dart';
import '../services/logging_service.dart';

class PreferencesService {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyTimelineDays = 'timeline_days';
  static const String _keyThemeColor = 'theme_color';
  static const String _keyCardElevation = 'card_elevation';
  static const String _keyCardBorderRadius = 'card_border_radius';
  static const String _keyDaySquareSize = 'day_square_size';
  static const String _keyDateFormat = 'date_format';
  static const String _keyFirstDayOfWeek = 'first_day_of_week';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyHabitCheckboxStyle = 'habit_checkbox_style';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    LoggingService.info('PreferencesService initialized');
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('PreferencesService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Theme mode
  static String? getThemeMode() => prefs.getString(_keyThemeMode);
  static Future<bool> setThemeMode(String mode) =>
      prefs.setString(_keyThemeMode, mode);

  // Language
  static String? getLanguage() => prefs.getString(_keyLanguage);
  static Future<bool> setLanguage(String language) =>
      prefs.setString(_keyLanguage, language);

  // First launch
  static bool isFirstLaunch() => prefs.getBool(_keyFirstLaunch) ?? true;
  static Future<bool> setFirstLaunch(bool value) =>
      prefs.setBool(_keyFirstLaunch, value);

  // Timeline days
  static int getTimelineDays() => prefs.getInt(_keyTimelineDays) ?? 100;
  static Future<bool> setTimelineDays(int days) =>
      prefs.setInt(_keyTimelineDays, days);

  // Theme color
  static int getThemeColor() =>
      prefs.getInt(_keyThemeColor) ?? 0xFF673AB7; // deepPurple default
  static Future<bool> setThemeColor(int color) =>
      prefs.setInt(_keyThemeColor, color);

  // Card elevation
  static double getCardElevation() => prefs.getDouble(_keyCardElevation) ?? 2.0;
  static Future<bool> setCardElevation(double elevation) =>
      prefs.setDouble(_keyCardElevation, elevation);

  // Card border radius
  static double getCardBorderRadius() =>
      prefs.getDouble(_keyCardBorderRadius) ?? 12.0;
  static Future<bool> setCardBorderRadius(double radius) =>
      prefs.setDouble(_keyCardBorderRadius, radius);

  // Day square size (default: large)
  static String getDaySquareSize() =>
      prefs.getString(_keyDaySquareSize) ?? 'large';
  static Future<bool> setDaySquareSize(String size) =>
      prefs.setString(_keyDaySquareSize, size);

  // Date format
  static String getDateFormat() =>
      prefs.getString(_keyDateFormat) ?? 'yyyy-MM-dd';
  static Future<bool> setDateFormat(String format) =>
      prefs.setString(_keyDateFormat, format);

  // First day of week (0=Sunday, 1=Monday)
  static int getFirstDayOfWeek() => prefs.getInt(_keyFirstDayOfWeek) ?? 1;
  static Future<bool> setFirstDayOfWeek(int day) =>
      prefs.setInt(_keyFirstDayOfWeek, day);

  // Notifications enabled
  static bool getNotificationsEnabled() =>
      prefs.getBool(_keyNotificationsEnabled) ?? true;
  static Future<bool> setNotificationsEnabled(bool enabled) =>
      prefs.setBool(_keyNotificationsEnabled, enabled);

  // Habit checkbox style (default: square)
  static String getHabitCheckboxStyle() =>
      prefs.getString(_keyHabitCheckboxStyle) ?? 'square';
  static Future<bool> setHabitCheckboxStyle(String style) =>
      prefs.setString(_keyHabitCheckboxStyle, style);

  // Clear all preferences
  static Future<bool> clear() => prefs.clear();
}
