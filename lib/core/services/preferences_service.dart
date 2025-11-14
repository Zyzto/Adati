import 'package:shared_preferences/shared_preferences.dart';
import '../services/logging_service.dart';

class PreferencesService {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyTimelineDays = 'timeline_days';

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
  static Future<bool> setThemeMode(String mode) => prefs.setString(_keyThemeMode, mode);

  // Language
  static String? getLanguage() => prefs.getString(_keyLanguage);
  static Future<bool> setLanguage(String language) => prefs.setString(_keyLanguage, language);

  // First launch
  static bool isFirstLaunch() => prefs.getBool(_keyFirstLaunch) ?? true;
  static Future<bool> setFirstLaunch(bool value) => prefs.setBool(_keyFirstLaunch, value);

  // Timeline days
  static int getTimelineDays() => prefs.getInt(_keyTimelineDays) ?? 50;
  static Future<bool> setTimelineDays(int days) => prefs.setInt(_keyTimelineDays, days);

  // Clear all preferences
  static Future<bool> clear() => prefs.clear();
}

