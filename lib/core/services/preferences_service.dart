import 'package:shared_preferences/shared_preferences.dart';
import 'log_helper.dart';

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
  static const String _keyHabitCardTimelineDays = 'habit_card_timeline_days';
  static const String _keyHabitSortOrder = 'habit_sort_order';
  static const String _keyHabitFilterQuery = 'habit_filter_query';
  static const String _keyHabitWeeklyGoal = 'habit_weekly_goal_';
  static const String _keyHabitMonthlyGoal = 'habit_monthly_goal_';
  // Display Preferences
  static const String _keyShowStreakBorders = 'show_streak_borders';
  static const String _keyTimelineCompactMode = 'timeline_compact_mode';
  static const String _keyShowWeekMonthHighlights =
      'show_week_month_highlights';
  static const String _keyTimelineSpacing = 'timeline_spacing';
  static const String _keyShowStreakNumbers = 'show_streak_numbers';
  static const String _keyShowDescriptions = 'show_descriptions';
  static const String _keyCompactCards = 'compact_cards';
  static const String _keyIconSize = 'icon_size';
  static const String _keyProgressIndicatorStyle = 'progress_indicator_style';
  static const String _keyCalendarCompletionColor = 'calendar_completion_color';
  static const String _keyHabitCardCompletionColor =
      'habit_card_completion_color';
  static const String _keyCalendarTimelineCompletionColor =
      'calendar_timeline_completion_color';
  static const String _keyMainTimelineCompletionColor =
      'main_timeline_completion_color';
  static const String _keyCalendarBadHabitCompletionColor =
      'calendar_bad_habit_completion_color';
  static const String _keyHabitCardBadHabitCompletionColor =
      'habit_card_bad_habit_completion_color';
  static const String _keyCalendarTimelineBadHabitCompletionColor =
      'calendar_timeline_bad_habit_completion_color';
  static const String _keyMainTimelineBadHabitCompletionColor =
      'main_timeline_bad_habit_completion_color';
  static const String _keyStreakColorScheme = 'streak_color_scheme';
  static const String _keyShowPercentage = 'show_percentage';
  static const String _keyFontSizeScale = 'font_size_scale';
  static const String _keyCardSpacing = 'card_spacing';
  static const String _keyShowStatisticsCard = 'show_statistics_card';
  static const String _keyShowMainTimeline = 'show_main_timeline';
  static const String _keyUseStreakColorsForSquares =
      'use_streak_colors_for_squares';
  static const String _keyDefaultView = 'default_view';
  static const String _keyShowStreakOnCard = 'show_streak_on_card';
  static const String _keyHabitCardLayoutMode = 'habit_card_layout_mode';
  static const String _keyHabitCardTimelineFillLines =
      'habit_card_timeline_fill_lines';
  static const String _keyHabitCardTimelineLines =
      'habit_card_timeline_lines';
  static const String _keyMainTimelineFillLines =
      'main_timeline_fill_lines';
  static const String _keyMainTimelineLines = 'main_timeline_lines';
  static const String _keyHabitsLayoutMode = 'habits_layout_mode';
  static const String _keyGridShowIcon = 'grid_show_icon';
  static const String _keyGridShowCompletion = 'grid_show_completion';
  static const String _keyGridShowTimeline = 'grid_show_timeline';
  static const String _keyBadHabitLogicMode = 'bad_habit_logic_mode';
  // Habit filtering/grouping (session-based but stored for convenience)
  static const String _keyHabitGroupBy = 'habit_group_by';
  static const String _keyHabitFilterByType = 'habit_filter_by_type';
  static const String _keyHabitFilterByTags = 'habit_filter_by_tags';
  // Settings page section expansion states
  static const String _keySettingsGeneralExpanded = 'settings_general_expanded';
  static const String _keySettingsAppearanceExpanded =
      'settings_appearance_expanded';
  static const String _keySettingsDisplayExpanded = 'settings_display_expanded';
  static const String _keySettingsDisplayPreferencesExpanded =
      'settings_display_preferences_expanded';
  static const String _keySettingsDisplayLayoutExpanded =
      'settings_display_layout_expanded';
  static const String _keySettingsNotificationsExpanded =
      'settings_notifications_expanded';
  static const String _keySettingsTagsExpanded = 'settings_tags_expanded';
  static const String _keySettingsDataExportExpanded =
      'settings_data_export_expanded';
  static const String _keySettingsAdvancedExpanded =
      'settings_advanced_expanded';
  static const String _keySettingsAboutExpanded = 'settings_about_expanded';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    Log.info('PreferencesService initialized');
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('PreferencesService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Advanced: Reset all settings to defaults
  static Future<bool> resetAllSettings() async {
    try {
      await prefs.clear();
      Log.info('All settings reset to defaults');
      return true;
    } catch (e) {
      Log.error('Error resetting settings: $e');
      return false;
    }
  }

  // Theme mode
  static String? getThemeMode() {
    final mode = prefs.getString(_keyThemeMode);
    Log.debug('getThemeMode() = $mode');
    return mode;
  }

  static Future<bool> setThemeMode(String mode) async {
    Log.info('setThemeMode(mode=$mode)');
    return prefs.setString(_keyThemeMode, mode);
  }

  // Language
  static String? getLanguage() {
    final lang = prefs.getString(_keyLanguage);
    Log.debug('getLanguage() = $lang');
    return lang;
  }

  static Future<bool> setLanguage(String language) async {
    Log.info('setLanguage(language=$language)');
    return prefs.setString(_keyLanguage, language);
  }

  // First launch
  static bool isFirstLaunch() {
    final value = prefs.getBool(_keyFirstLaunch) ?? true;
    Log.debug('isFirstLaunch() = $value');
    return value;
  }

  static Future<bool> setFirstLaunch(bool value) async {
    Log.info('setFirstLaunch(value=$value)');
    return prefs.setBool(_keyFirstLaunch, value);
  }

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
  static String getDaySquareSize() {
    final value = prefs.getString(_keyDaySquareSize);
    return (value == null || value.isEmpty) ? 'large' : value;
  }

  static Future<bool> setDaySquareSize(String size) =>
      prefs.setString(_keyDaySquareSize, size);

  // Date format
  static String getDateFormat() {
    final value = prefs.getString(_keyDateFormat);
    return (value == null || value.isEmpty) ? 'yyyy-MM-dd' : value;
  }

  static Future<bool> setDateFormat(String format) =>
      prefs.setString(_keyDateFormat, format);

  // First day of week (0=Sunday, 1=Monday)
  static int getFirstDayOfWeek() => prefs.getInt(_keyFirstDayOfWeek) ?? 0;
  static Future<bool> setFirstDayOfWeek(int day) =>
      prefs.setInt(_keyFirstDayOfWeek, day);

  // Notifications enabled
  static bool getNotificationsEnabled() {
    final value = prefs.getBool(_keyNotificationsEnabled) ?? true;
    Log.debug('getNotificationsEnabled() = $value');
    return value;
  }

  static Future<bool> setNotificationsEnabled(bool enabled) async {
    Log.info('setNotificationsEnabled(enabled=$enabled)');
    return prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  // Habit checkbox style (default: circle)
  static String getHabitCheckboxStyle() {
    final value = prefs.getString(_keyHabitCheckboxStyle);
    return (value == null || value.isEmpty) ? 'circle' : value;
  }

  static Future<bool> setHabitCheckboxStyle(String style) =>
      prefs.setString(_keyHabitCheckboxStyle, style);

  // Habit detail timeline days (default: 100)
  static int getModalTimelineDays() =>
      prefs.getInt(_keyModalTimelineDays) ?? 100;
  static Future<bool> setModalTimelineDays(int days) =>
      prefs.setInt(_keyModalTimelineDays, days);

  // Habit card timeline days (default: 50)
  static int getHabitCardTimelineDays() =>
      prefs.getInt(_keyHabitCardTimelineDays) ?? 50;
  static Future<bool> setHabitCardTimelineDays(int days) =>
      prefs.setInt(_keyHabitCardTimelineDays, days);

  // Habit sort order (default: 'name')
  static String getHabitSortOrder() {
    final value = prefs.getString(_keyHabitSortOrder);
    return (value == null || value.isEmpty) ? 'name' : value;
  }

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
      prefs.getBool(_keyShowStreakBorders) ?? false;
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

  static bool getCompactCards() => prefs.getBool(_keyCompactCards) ?? false;
  static Future<bool> setCompactCards(bool value) =>
      prefs.setBool(_keyCompactCards, value);

  static String getIconSize() {
    final value = prefs.getString(_keyIconSize);
    return (value == null || value.isEmpty) ? 'medium' : value;
  }

  static Future<bool> setIconSize(String size) =>
      prefs.setString(_keyIconSize, size);

  static String getProgressIndicatorStyle() {
    final value = prefs.getString(_keyProgressIndicatorStyle);
    return (value == null || value.isEmpty) ? 'circular' : value;
  }

  static Future<bool> setProgressIndicatorStyle(String style) =>
      prefs.setString(_keyProgressIndicatorStyle, style);

  // Calendar completion color (for calendar day squares)
  static int getCalendarCompletionColor() {
    // Migrate from old key if it exists
    final oldKey = 'completion_color';
    if (prefs.containsKey(oldKey) &&
        !prefs.containsKey(_keyCalendarCompletionColor)) {
      final oldValue = prefs.getInt(oldKey);
      if (oldValue != null) {
        setCalendarCompletionColor(oldValue);
        prefs.remove(oldKey); // Remove old key after migration
      }
    }
    return prefs.getInt(_keyCalendarCompletionColor) ??
        0xFF4CAF50; // green default
  }

  static Future<bool> setCalendarCompletionColor(int color) =>
      prefs.setInt(_keyCalendarCompletionColor, color);

  // Habit card completion color (for checkbox/display in habit cards)
  static int getHabitCardCompletionColor() =>
      prefs.getInt(_keyHabitCardCompletionColor) ?? 0xFF4CAF50; // green default
  static Future<bool> setHabitCardCompletionColor(int color) =>
      prefs.setInt(_keyHabitCardCompletionColor, color);

  // Calendar timeline completion color (for timeline inside calendar modal)
  static int getCalendarTimelineCompletionColor() =>
      prefs.getInt(_keyCalendarTimelineCompletionColor) ??
      4282339765; // Updated default
  static Future<bool> setCalendarTimelineCompletionColor(int color) =>
      prefs.setInt(_keyCalendarTimelineCompletionColor, color);

  // Main timeline completion color (for main timeline page)
  static int getMainTimelineCompletionColor() =>
      prefs.getInt(_keyMainTimelineCompletionColor) ??
      0xFF4CAF50; // green default
  static Future<bool> setMainTimelineCompletionColor(int color) =>
      prefs.setInt(_keyMainTimelineCompletionColor, color);

  // Bad habit completion colors (default: red)
  static int getCalendarBadHabitCompletionColor() =>
      prefs.getInt(_keyCalendarBadHabitCompletionColor) ??
      0xFFF44336; // red default
  static Future<bool> setCalendarBadHabitCompletionColor(int color) =>
      prefs.setInt(_keyCalendarBadHabitCompletionColor, color);

  static int getHabitCardBadHabitCompletionColor() =>
      prefs.getInt(_keyHabitCardBadHabitCompletionColor) ??
      0xFFF44336; // red default
  static Future<bool> setHabitCardBadHabitCompletionColor(int color) =>
      prefs.setInt(_keyHabitCardBadHabitCompletionColor, color);

  static int getCalendarTimelineBadHabitCompletionColor() =>
      prefs.getInt(_keyCalendarTimelineBadHabitCompletionColor) ??
      4280391411; // Updated default
  static Future<bool> setCalendarTimelineBadHabitCompletionColor(int color) =>
      prefs.setInt(_keyCalendarTimelineBadHabitCompletionColor, color);

  static int getMainTimelineBadHabitCompletionColor() =>
      prefs.getInt(_keyMainTimelineBadHabitCompletionColor) ??
      0xFFF44336; // red default
  static Future<bool> setMainTimelineBadHabitCompletionColor(int color) =>
      prefs.setInt(_keyMainTimelineBadHabitCompletionColor, color);

  static String getStreakColorScheme() {
    final value = prefs.getString(_keyStreakColorScheme);
    return (value == null || value.isEmpty) ? 'default' : value;
  }

  static Future<bool> setStreakColorScheme(String scheme) =>
      prefs.setString(_keyStreakColorScheme, scheme);

  static bool getShowPercentage() => prefs.getBool(_keyShowPercentage) ?? true;
  static Future<bool> setShowPercentage(bool value) =>
      prefs.setBool(_keyShowPercentage, value);

  static String getFontSizeScale() {
    final value = prefs.getString(_keyFontSizeScale);
    return (value == null || value.isEmpty) ? 'normal' : value;
  }

  static Future<bool> setFontSizeScale(String scale) =>
      prefs.setString(_keyFontSizeScale, scale);

  static double getCardSpacing() => prefs.getDouble(_keyCardSpacing) ?? 12.0;
  static Future<bool> setCardSpacing(double value) =>
      prefs.setDouble(_keyCardSpacing, value);

  static bool getShowStatisticsCard() =>
      prefs.getBool(_keyShowStatisticsCard) ?? true;
  static Future<bool> setShowStatisticsCard(bool value) =>
      prefs.setBool(_keyShowStatisticsCard, value);

  static bool getShowMainTimeline() =>
      prefs.getBool(_keyShowMainTimeline) ?? true;
  static Future<bool> setShowMainTimeline(bool value) =>
      prefs.setBool(_keyShowMainTimeline, value);

  static bool getUseStreakColorsForSquares() =>
      prefs.getBool(_keyUseStreakColorsForSquares) ?? false;
  static Future<bool> setUseStreakColorsForSquares(bool value) =>
      prefs.setBool(_keyUseStreakColorsForSquares, value);

  static String getDefaultView() {
    final value = prefs.getString(_keyDefaultView);
    return (value == null || value.isEmpty) ? 'habits' : value;
  }

  static Future<bool> setDefaultView(String view) =>
      prefs.setString(_keyDefaultView, view);

  static String getHabitCardLayoutMode() {
    final value = prefs.getString(_keyHabitCardLayoutMode);
    return (value == null || value.isEmpty) ? 'classic' : value;
  }

  static Future<bool> setHabitCardLayoutMode(String mode) =>
      prefs.setString(_keyHabitCardLayoutMode, mode);

  static bool getHabitCardTimelineFillLines() =>
      prefs.getBool(_keyHabitCardTimelineFillLines) ?? false;

  static Future<bool> setHabitCardTimelineFillLines(bool value) =>
      prefs.setBool(_keyHabitCardTimelineFillLines, value);

  static int getHabitCardTimelineLines() =>
      prefs.getInt(_keyHabitCardTimelineLines) ?? 3;

  static Future<bool> setHabitCardTimelineLines(int lines) =>
      prefs.setInt(_keyHabitCardTimelineLines, lines);

  static bool getMainTimelineFillLines() =>
      prefs.getBool(_keyMainTimelineFillLines) ?? false;

  static Future<bool> setMainTimelineFillLines(bool value) =>
      prefs.setBool(_keyMainTimelineFillLines, value);

  static int getMainTimelineLines() =>
      prefs.getInt(_keyMainTimelineLines) ?? 3;

  static Future<bool> setMainTimelineLines(int lines) =>
      prefs.setInt(_keyMainTimelineLines, lines);

  static String getHabitsLayoutMode() {
    final value = prefs.getString(_keyHabitsLayoutMode);
    return (value == null || value.isEmpty) ? 'list' : value;
  }

  static Future<bool> setHabitsLayoutMode(String mode) =>
      prefs.setString(_keyHabitsLayoutMode, mode);

  static bool getGridShowIcon() =>
      prefs.getBool(_keyGridShowIcon) ?? true;

  static Future<bool> setGridShowIcon(bool value) =>
      prefs.setBool(_keyGridShowIcon, value);

  static bool getGridShowCompletion() =>
      prefs.getBool(_keyGridShowCompletion) ?? true;

  static Future<bool> setGridShowCompletion(bool value) =>
      prefs.setBool(_keyGridShowCompletion, value);

  static bool getGridShowTimeline() =>
      prefs.getBool(_keyGridShowTimeline) ?? true;

  static Future<bool> setGridShowTimeline(bool value) =>
      prefs.setBool(_keyGridShowTimeline, value);

  static String getBadHabitLogicMode() {
    final value = prefs.getString(_keyBadHabitLogicMode);
    return (value == null || value.isEmpty) ? 'positive' : value;
  }

  static Future<bool> setBadHabitLogicMode(String mode) =>
      prefs.setString(_keyBadHabitLogicMode, mode);

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

  static String? getHabitFilterByType() =>
      prefs.getString(_keyHabitFilterByType);
  static Future<bool> setHabitFilterByType(String? value) {
    if (value == null || value.isEmpty) {
      return prefs.remove(_keyHabitFilterByType);
    }
    return prefs.setString(_keyHabitFilterByType, value);
  }

  static String? getHabitFilterByTags() =>
      prefs.getString(_keyHabitFilterByTags);
  static Future<bool> setHabitFilterByTags(String? value) {
    if (value == null || value.isEmpty) {
      return prefs.remove(_keyHabitFilterByTags);
    }
    return prefs.setString(_keyHabitFilterByTags, value);
  }

  // Settings page section expansion states
  static bool getSettingsGeneralExpanded() =>
      prefs.getBool(_keySettingsGeneralExpanded) ?? true; // Default: expanded
  static Future<bool> setSettingsGeneralExpanded(bool value) =>
      prefs.setBool(_keySettingsGeneralExpanded, value);

  static bool getSettingsAppearanceExpanded() =>
      prefs.getBool(_keySettingsAppearanceExpanded) ?? false;
  static Future<bool> setSettingsAppearanceExpanded(bool value) =>
      prefs.setBool(_keySettingsAppearanceExpanded, value);

  static bool getSettingsDisplayExpanded() =>
      prefs.getBool(_keySettingsDisplayExpanded) ?? false;
  static Future<bool> setSettingsDisplayExpanded(bool value) =>
      prefs.setBool(_keySettingsDisplayExpanded, value);

  static bool getSettingsDisplayPreferencesExpanded() =>
      prefs.getBool(_keySettingsDisplayPreferencesExpanded) ?? false;
  static Future<bool> setSettingsDisplayPreferencesExpanded(bool value) =>
      prefs.setBool(_keySettingsDisplayPreferencesExpanded, value);

  static bool getSettingsDisplayLayoutExpanded() =>
      prefs.getBool(_keySettingsDisplayLayoutExpanded) ?? false;
  static Future<bool> setSettingsDisplayLayoutExpanded(bool value) =>
      prefs.setBool(_keySettingsDisplayLayoutExpanded, value);

  static bool getSettingsNotificationsExpanded() =>
      prefs.getBool(_keySettingsNotificationsExpanded) ?? false;
  static Future<bool> setSettingsNotificationsExpanded(bool value) =>
      prefs.setBool(_keySettingsNotificationsExpanded, value);

  static bool getSettingsTagsExpanded() =>
      prefs.getBool(_keySettingsTagsExpanded) ?? false;
  static Future<bool> setSettingsTagsExpanded(bool value) =>
      prefs.setBool(_keySettingsTagsExpanded, value);

  static bool getSettingsDataExportExpanded() =>
      prefs.getBool(_keySettingsDataExportExpanded) ?? false;
  static Future<bool> setSettingsDataExportExpanded(bool value) =>
      prefs.setBool(_keySettingsDataExportExpanded, value);

  static bool getSettingsAdvancedExpanded() =>
      prefs.getBool(_keySettingsAdvancedExpanded) ?? false;
  static Future<bool> setSettingsAdvancedExpanded(bool value) =>
      prefs.setBool(_keySettingsAdvancedExpanded, value);

  static bool getSettingsAboutExpanded() =>
      prefs.getBool(_keySettingsAboutExpanded) ?? false;
  static Future<bool> setSettingsAboutExpanded(bool value) =>
      prefs.setBool(_keySettingsAboutExpanded, value);

  // Clear all preferences
  static Future<bool> clear() => prefs.clear();
}
