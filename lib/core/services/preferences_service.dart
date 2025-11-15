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
  static const String _keyModalTimelineDays = 'modal_timeline_days';
  static const String _keyHabitSortOrder = 'habit_sort_order';
  static const String _keyHabitFilterQuery = 'habit_filter_query';
  static const String _keyHabitWeeklyGoal = 'habit_weekly_goal_';
  static const String _keyHabitMonthlyGoal = 'habit_monthly_goal_';
  // Display Preferences
  static const String _keyShowStreakBorders = 'show_streak_borders';
  static const String _keyTimelineCompactMode = 'timeline_compact_mode';
  static const String _keyShowWeekMonthHighlights = 'show_week_month_highlights';
  static const String _keyTimelineSpacing = 'timeline_spacing';
  static const String _keyShowStreakNumbers = 'show_streak_numbers';
  static const String _keyShowDescriptions = 'show_descriptions';
  static const String _keyCompactCards = 'compact_cards';
  static const String _keyIconSize = 'icon_size';
  static const String _keyProgressIndicatorStyle = 'progress_indicator_style';
  static const String _keyCompletionColor = 'completion_color';
  static const String _keyStreakColorScheme = 'streak_color_scheme';
  static const String _keyShowPercentage = 'show_percentage';
  static const String _keyFontSizeScale = 'font_size_scale';
  static const String _keyCardSpacing = 'card_spacing';
  static const String _keyShowStatisticsCard = 'show_statistics_card';
  static const String _keyDefaultView = 'default_view';
  static const String _keyShowStreakOnCard = 'show_streak_on_card';
  // Habit filtering/grouping (session-based but stored for convenience)
  static const String _keyHabitGroupBy = 'habit_group_by';
  static const String _keyHabitFilterByType = 'habit_filter_by_type';
  static const String _keyHabitFilterByTags = 'habit_filter_by_tags';

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

  // Modal timeline days (default: 200)
  static int getModalTimelineDays() => prefs.getInt(_keyModalTimelineDays) ?? 200;
  static Future<bool> setModalTimelineDays(int days) =>
      prefs.setInt(_keyModalTimelineDays, days);

  // Habit sort order (default: 'name')
  static String getHabitSortOrder() =>
      prefs.getString(_keyHabitSortOrder) ?? 'name';
  static Future<bool> setHabitSortOrder(String order) =>
      prefs.setString(_keyHabitSortOrder, order);

  // Habit filter query
  static String? getHabitFilterQuery() => prefs.getString(_keyHabitFilterQuery);
  static Future<bool> setHabitFilterQuery(String? query) {
    if (query == null || query.isEmpty) {
      return prefs.remove(_keyHabitFilterQuery);
    }
    return prefs.setString(_keyHabitFilterQuery, query);
  }

  // Habit Goals
  static int? getHabitWeeklyGoal(int habitId) =>
      prefs.getInt('$_keyHabitWeeklyGoal$habitId');
  static Future<bool> setHabitWeeklyGoal(int habitId, int? days) {
    if (days == null) {
      return prefs.remove('$_keyHabitWeeklyGoal$habitId');
    }
    return prefs.setInt('$_keyHabitWeeklyGoal$habitId', days);
  }

  static int? getHabitMonthlyGoal(int habitId) =>
      prefs.getInt('$_keyHabitMonthlyGoal$habitId');
  static Future<bool> setHabitMonthlyGoal(int habitId, int? days) {
    if (days == null) {
      return prefs.remove('$_keyHabitMonthlyGoal$habitId');
    }
    return prefs.setInt('$_keyHabitMonthlyGoal$habitId', days);
  }

  // Display Preferences
  static bool getShowStreakBorders() =>
      prefs.getBool(_keyShowStreakBorders) ?? true;
  static Future<bool> setShowStreakBorders(bool value) =>
      prefs.setBool(_keyShowStreakBorders, value);

  static bool getTimelineCompactMode() =>
      prefs.getBool(_keyTimelineCompactMode) ?? false;
  static Future<bool> setTimelineCompactMode(bool value) =>
      prefs.setBool(_keyTimelineCompactMode, value);

  static bool getShowWeekMonthHighlights() =>
      prefs.getBool(_keyShowWeekMonthHighlights) ?? true;
  static Future<bool> setShowWeekMonthHighlights(bool value) =>
      prefs.setBool(_keyShowWeekMonthHighlights, value);

  static double getTimelineSpacing() =>
      prefs.getDouble(_keyTimelineSpacing) ?? 6.0;
  static Future<bool> setTimelineSpacing(double value) =>
      prefs.setDouble(_keyTimelineSpacing, value);

  static bool getShowStreakNumbers() =>
      prefs.getBool(_keyShowStreakNumbers) ?? false;
  static Future<bool> setShowStreakNumbers(bool value) =>
      prefs.setBool(_keyShowStreakNumbers, value);

  static bool getShowDescriptions() =>
      prefs.getBool(_keyShowDescriptions) ?? true;
  static Future<bool> setShowDescriptions(bool value) =>
      prefs.setBool(_keyShowDescriptions, value);

  static bool getCompactCards() =>
      prefs.getBool(_keyCompactCards) ?? false;
  static Future<bool> setCompactCards(bool value) =>
      prefs.setBool(_keyCompactCards, value);

  static String getIconSize() =>
      prefs.getString(_keyIconSize) ?? 'medium';
  static Future<bool> setIconSize(String size) =>
      prefs.setString(_keyIconSize, size);

  static String getProgressIndicatorStyle() =>
      prefs.getString(_keyProgressIndicatorStyle) ?? 'circular';
  static Future<bool> setProgressIndicatorStyle(String style) =>
      prefs.setString(_keyProgressIndicatorStyle, style);

  static int getCompletionColor() =>
      prefs.getInt(_keyCompletionColor) ?? 0xFF4CAF50; // green default
  static Future<bool> setCompletionColor(int color) =>
      prefs.setInt(_keyCompletionColor, color);

  static String getStreakColorScheme() =>
      prefs.getString(_keyStreakColorScheme) ?? 'default';
  static Future<bool> setStreakColorScheme(String scheme) =>
      prefs.setString(_keyStreakColorScheme, scheme);

  static bool getShowPercentage() =>
      prefs.getBool(_keyShowPercentage) ?? true;
  static Future<bool> setShowPercentage(bool value) =>
      prefs.setBool(_keyShowPercentage, value);

  static String getFontSizeScale() =>
      prefs.getString(_keyFontSizeScale) ?? 'normal';
  static Future<bool> setFontSizeScale(String scale) =>
      prefs.setString(_keyFontSizeScale, scale);

  static double getCardSpacing() =>
      prefs.getDouble(_keyCardSpacing) ?? 12.0;
  static Future<bool> setCardSpacing(double value) =>
      prefs.setDouble(_keyCardSpacing, value);

  static bool getShowStatisticsCard() =>
      prefs.getBool(_keyShowStatisticsCard) ?? true;
  static Future<bool> setShowStatisticsCard(bool value) =>
      prefs.setBool(_keyShowStatisticsCard, value);

  static String getDefaultView() =>
      prefs.getString(_keyDefaultView) ?? 'habits';
  static Future<bool> setDefaultView(String view) =>
      prefs.setString(_keyDefaultView, view);

  static bool getShowStreakOnCard() =>
      prefs.getBool(_keyShowStreakOnCard) ?? false;
  static Future<bool> setShowStreakOnCard(bool value) =>
      prefs.setBool(_keyShowStreakOnCard, value);

  // Habit filtering/grouping
  static String? getHabitGroupBy() => prefs.getString(_keyHabitGroupBy);
  static Future<bool> setHabitGroupBy(String? value) {
    if (value == null || value.isEmpty) {
      return prefs.remove(_keyHabitGroupBy);
    }
    return prefs.setString(_keyHabitGroupBy, value);
  }

  static String? getHabitFilterByType() => prefs.getString(_keyHabitFilterByType);
  static Future<bool> setHabitFilterByType(String? value) {
    if (value == null || value.isEmpty) {
      return prefs.remove(_keyHabitFilterByType);
    }
    return prefs.setString(_keyHabitFilterByType, value);
  }

  static String? getHabitFilterByTags() => prefs.getString(_keyHabitFilterByTags);
  static Future<bool> setHabitFilterByTags(String? value) {
    if (value == null || value.isEmpty) {
      return prefs.remove(_keyHabitFilterByTags);
    }
    return prefs.setString(_keyHabitFilterByTags, value);
  }

  // Clear all preferences
  static Future<bool> clear() => prefs.clear();
}
