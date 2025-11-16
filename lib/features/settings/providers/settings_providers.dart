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
  ref.keepAlive(); // Keep provider alive across app restarts
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

// Display Preferences
// Show Streak Borders
class ShowStreakBordersNotifier {
  bool _value;

  ShowStreakBordersNotifier() : _value = PreferencesService.getShowStreakBorders();

  bool get value => _value;

  Future<void> setShowStreakBorders(bool value) async {
    _value = value;
    await PreferencesService.setShowStreakBorders(value);
  }
}

final showStreakBordersNotifierProvider = Provider<ShowStreakBordersNotifier>((ref) {
  return ShowStreakBordersNotifier();
});

final showStreakBordersProvider = Provider<bool>((ref) {
  return ref.watch(showStreakBordersNotifierProvider).value;
});

// Timeline Compact Mode
class TimelineCompactModeNotifier {
  bool _value;

  TimelineCompactModeNotifier() : _value = PreferencesService.getTimelineCompactMode();

  bool get value => _value;

  Future<void> setTimelineCompactMode(bool value) async {
    _value = value;
    await PreferencesService.setTimelineCompactMode(value);
  }
}

final timelineCompactModeNotifierProvider = Provider<TimelineCompactModeNotifier>((ref) {
  return TimelineCompactModeNotifier();
});

final timelineCompactModeProvider = Provider<bool>((ref) {
  return ref.watch(timelineCompactModeNotifierProvider).value;
});

// Show Week/Month Highlights
class ShowWeekMonthHighlightsNotifier {
  bool _value;

  ShowWeekMonthHighlightsNotifier() : _value = PreferencesService.getShowWeekMonthHighlights();

  bool get value => _value;

  Future<void> setShowWeekMonthHighlights(bool value) async {
    _value = value;
    await PreferencesService.setShowWeekMonthHighlights(value);
  }
}

final showWeekMonthHighlightsNotifierProvider = Provider<ShowWeekMonthHighlightsNotifier>((ref) {
  return ShowWeekMonthHighlightsNotifier();
});

final showWeekMonthHighlightsProvider = Provider<bool>((ref) {
  return ref.watch(showWeekMonthHighlightsNotifierProvider).value;
});

// Timeline Spacing
class TimelineSpacingNotifier {
  double _value;

  TimelineSpacingNotifier() : _value = PreferencesService.getTimelineSpacing();

  double get value => _value;

  Future<void> setTimelineSpacing(double value) async {
    _value = value;
    await PreferencesService.setTimelineSpacing(value);
  }
}

final timelineSpacingNotifierProvider = Provider<TimelineSpacingNotifier>((ref) {
  return TimelineSpacingNotifier();
});

final timelineSpacingProvider = Provider<double>((ref) {
  return ref.watch(timelineSpacingNotifierProvider).value;
});

// Show Streak Numbers
class ShowStreakNumbersNotifier {
  bool _value;

  ShowStreakNumbersNotifier() : _value = PreferencesService.getShowStreakNumbers();

  bool get value => _value;

  Future<void> setShowStreakNumbers(bool value) async {
    _value = value;
    await PreferencesService.setShowStreakNumbers(value);
  }
}

final showStreakNumbersNotifierProvider = Provider<ShowStreakNumbersNotifier>((ref) {
  return ShowStreakNumbersNotifier();
});

final showStreakNumbersProvider = Provider<bool>((ref) {
  return ref.watch(showStreakNumbersNotifierProvider).value;
});

// Show Descriptions
class ShowDescriptionsNotifier {
  bool _value;

  ShowDescriptionsNotifier() : _value = PreferencesService.getShowDescriptions();

  bool get value => _value;

  Future<void> setShowDescriptions(bool value) async {
    _value = value;
    await PreferencesService.setShowDescriptions(value);
  }
}

final showDescriptionsNotifierProvider = Provider<ShowDescriptionsNotifier>((ref) {
  return ShowDescriptionsNotifier();
});

final showDescriptionsProvider = Provider<bool>((ref) {
  return ref.watch(showDescriptionsNotifierProvider).value;
});

// Compact Cards
class CompactCardsNotifier {
  bool _value;

  CompactCardsNotifier() : _value = PreferencesService.getCompactCards();

  bool get value => _value;

  Future<void> setCompactCards(bool value) async {
    _value = value;
    await PreferencesService.setCompactCards(value);
  }
}

final compactCardsNotifierProvider = Provider<CompactCardsNotifier>((ref) {
  return CompactCardsNotifier();
});

final compactCardsProvider = Provider<bool>((ref) {
  return ref.watch(compactCardsNotifierProvider).value;
});

// Icon Size
class IconSizeNotifier {
  String _size;

  IconSizeNotifier() : _size = PreferencesService.getIconSize();

  String get size => _size;

  Future<void> setIconSize(String size) async {
    _size = size;
    await PreferencesService.setIconSize(size);
  }
}

final iconSizeNotifierProvider = Provider<IconSizeNotifier>((ref) {
  return IconSizeNotifier();
});

final iconSizeProvider = Provider<String>((ref) {
  return ref.watch(iconSizeNotifierProvider).size;
});

// Progress Indicator Style
class ProgressIndicatorStyleNotifier {
  String _style;

  ProgressIndicatorStyleNotifier() : _style = PreferencesService.getProgressIndicatorStyle();

  String get style => _style;

  Future<void> setProgressIndicatorStyle(String style) async {
    _style = style;
    await PreferencesService.setProgressIndicatorStyle(style);
  }
}

final progressIndicatorStyleNotifierProvider = Provider<ProgressIndicatorStyleNotifier>((ref) {
  return ProgressIndicatorStyleNotifier();
});

final progressIndicatorStyleProvider = Provider<String>((ref) {
  return ref.watch(progressIndicatorStyleNotifierProvider).style;
});

// Calendar Completion Color
class CalendarCompletionColorNotifier {
  int _color;

  CalendarCompletionColorNotifier() : _color = PreferencesService.getCalendarCompletionColor();

  int get color => _color;

  Future<void> setCalendarCompletionColor(int color) async {
    _color = color;
    await PreferencesService.setCalendarCompletionColor(color);
  }
}

final calendarCompletionColorNotifierProvider = Provider<CalendarCompletionColorNotifier>((ref) {
  return CalendarCompletionColorNotifier();
});

final calendarCompletionColorProvider = Provider<int>((ref) {
  return ref.watch(calendarCompletionColorNotifierProvider).color;
});

// Habit Card Completion Color
class HabitCardCompletionColorNotifier {
  int _color;

  HabitCardCompletionColorNotifier() : _color = PreferencesService.getHabitCardCompletionColor();

  int get color => _color;

  Future<void> setHabitCardCompletionColor(int color) async {
    _color = color;
    await PreferencesService.setHabitCardCompletionColor(color);
  }
}

final habitCardCompletionColorNotifierProvider = Provider<HabitCardCompletionColorNotifier>((ref) {
  return HabitCardCompletionColorNotifier();
});

final habitCardCompletionColorProvider = Provider<int>((ref) {
  return ref.watch(habitCardCompletionColorNotifierProvider).color;
});

// Calendar Timeline Completion Color
class CalendarTimelineCompletionColorNotifier {
  int _color;

  CalendarTimelineCompletionColorNotifier() : _color = PreferencesService.getCalendarTimelineCompletionColor();

  int get color => _color;

  Future<void> setCalendarTimelineCompletionColor(int color) async {
    _color = color;
    await PreferencesService.setCalendarTimelineCompletionColor(color);
  }
}

final calendarTimelineCompletionColorNotifierProvider = Provider<CalendarTimelineCompletionColorNotifier>((ref) {
  return CalendarTimelineCompletionColorNotifier();
});

final calendarTimelineCompletionColorProvider = Provider<int>((ref) {
  return ref.watch(calendarTimelineCompletionColorNotifierProvider).color;
});

// Main Timeline Completion Color
class MainTimelineCompletionColorNotifier {
  int _color;

  MainTimelineCompletionColorNotifier() : _color = PreferencesService.getMainTimelineCompletionColor();

  int get color => _color;

  Future<void> setMainTimelineCompletionColor(int color) async {
    _color = color;
    await PreferencesService.setMainTimelineCompletionColor(color);
  }
}

final mainTimelineCompletionColorNotifierProvider = Provider<MainTimelineCompletionColorNotifier>((ref) {
  return MainTimelineCompletionColorNotifier();
});

final mainTimelineCompletionColorProvider = Provider<int>((ref) {
  return ref.watch(mainTimelineCompletionColorNotifierProvider).color;
});

// Bad Habit Completion Colors
class CalendarBadHabitCompletionColorNotifier {
  int _color;

  CalendarBadHabitCompletionColorNotifier() : _color = PreferencesService.getCalendarBadHabitCompletionColor();

  int get color => _color;

  Future<void> setCalendarBadHabitCompletionColor(int color) async {
    _color = color;
    await PreferencesService.setCalendarBadHabitCompletionColor(color);
  }
}

final calendarBadHabitCompletionColorNotifierProvider = Provider<CalendarBadHabitCompletionColorNotifier>((ref) {
  return CalendarBadHabitCompletionColorNotifier();
});

final calendarBadHabitCompletionColorProvider = Provider<int>((ref) {
  return ref.watch(calendarBadHabitCompletionColorNotifierProvider).color;
});

class HabitCardBadHabitCompletionColorNotifier {
  int _color;

  HabitCardBadHabitCompletionColorNotifier() : _color = PreferencesService.getHabitCardBadHabitCompletionColor();

  int get color => _color;

  Future<void> setHabitCardBadHabitCompletionColor(int color) async {
    _color = color;
    await PreferencesService.setHabitCardBadHabitCompletionColor(color);
  }
}

final habitCardBadHabitCompletionColorNotifierProvider = Provider<HabitCardBadHabitCompletionColorNotifier>((ref) {
  return HabitCardBadHabitCompletionColorNotifier();
});

final habitCardBadHabitCompletionColorProvider = Provider<int>((ref) {
  return ref.watch(habitCardBadHabitCompletionColorNotifierProvider).color;
});

class CalendarTimelineBadHabitCompletionColorNotifier {
  int _color;

  CalendarTimelineBadHabitCompletionColorNotifier() : _color = PreferencesService.getCalendarTimelineBadHabitCompletionColor();

  int get color => _color;

  Future<void> setCalendarTimelineBadHabitCompletionColor(int color) async {
    _color = color;
    await PreferencesService.setCalendarTimelineBadHabitCompletionColor(color);
  }
}

final calendarTimelineBadHabitCompletionColorNotifierProvider = Provider<CalendarTimelineBadHabitCompletionColorNotifier>((ref) {
  return CalendarTimelineBadHabitCompletionColorNotifier();
});

final calendarTimelineBadHabitCompletionColorProvider = Provider<int>((ref) {
  return ref.watch(calendarTimelineBadHabitCompletionColorNotifierProvider).color;
});

class MainTimelineBadHabitCompletionColorNotifier {
  int _color;

  MainTimelineBadHabitCompletionColorNotifier() : _color = PreferencesService.getMainTimelineBadHabitCompletionColor();

  int get color => _color;

  Future<void> setMainTimelineBadHabitCompletionColor(int color) async {
    _color = color;
    await PreferencesService.setMainTimelineBadHabitCompletionColor(color);
  }
}

final mainTimelineBadHabitCompletionColorNotifierProvider = Provider<MainTimelineBadHabitCompletionColorNotifier>((ref) {
  return MainTimelineBadHabitCompletionColorNotifier();
});

final mainTimelineBadHabitCompletionColorProvider = Provider<int>((ref) {
  return ref.watch(mainTimelineBadHabitCompletionColorNotifierProvider).color;
});

// Streak Color Scheme
class StreakColorSchemeNotifier {
  String _scheme;

  StreakColorSchemeNotifier() : _scheme = PreferencesService.getStreakColorScheme();

  String get scheme => _scheme;

  Future<void> setStreakColorScheme(String scheme) async {
    _scheme = scheme;
    await PreferencesService.setStreakColorScheme(scheme);
  }
}

final streakColorSchemeNotifierProvider = Provider<StreakColorSchemeNotifier>((ref) {
  return StreakColorSchemeNotifier();
});

final streakColorSchemeProvider = Provider<String>((ref) {
  return ref.watch(streakColorSchemeNotifierProvider).scheme;
});

// Show Percentage
class ShowPercentageNotifier {
  bool _value;

  ShowPercentageNotifier() : _value = PreferencesService.getShowPercentage();

  bool get value => _value;

  Future<void> setShowPercentage(bool value) async {
    _value = value;
    await PreferencesService.setShowPercentage(value);
  }
}

final showPercentageNotifierProvider = Provider<ShowPercentageNotifier>((ref) {
  return ShowPercentageNotifier();
});

final showPercentageProvider = Provider<bool>((ref) {
  return ref.watch(showPercentageNotifierProvider).value;
});

// Font Size Scale
class FontSizeScaleNotifier {
  String _scale;

  FontSizeScaleNotifier() : _scale = PreferencesService.getFontSizeScale();

  String get scale => _scale;

  Future<void> setFontSizeScale(String scale) async {
    _scale = scale;
    await PreferencesService.setFontSizeScale(scale);
  }
}

final fontSizeScaleNotifierProvider = Provider<FontSizeScaleNotifier>((ref) {
  return FontSizeScaleNotifier();
});

final fontSizeScaleProvider = Provider<String>((ref) {
  return ref.watch(fontSizeScaleNotifierProvider).scale;
});

// Card Spacing
class CardSpacingNotifier {
  double _spacing;

  CardSpacingNotifier() : _spacing = PreferencesService.getCardSpacing();

  double get spacing => _spacing;

  Future<void> setCardSpacing(double spacing) async {
    _spacing = spacing;
    await PreferencesService.setCardSpacing(spacing);
  }
}

final cardSpacingNotifierProvider = Provider<CardSpacingNotifier>((ref) {
  return CardSpacingNotifier();
});

final cardSpacingProvider = Provider<double>((ref) {
  return ref.watch(cardSpacingNotifierProvider).spacing;
});

// Show Statistics Card
class ShowStatisticsCardNotifier {
  bool _value;

  ShowStatisticsCardNotifier() : _value = PreferencesService.getShowStatisticsCard();

  bool get value => _value;

  Future<void> setShowStatisticsCard(bool value) async {
    _value = value;
    await PreferencesService.setShowStatisticsCard(value);
  }
}

final showStatisticsCardNotifierProvider = Provider<ShowStatisticsCardNotifier>((ref) {
  return ShowStatisticsCardNotifier();
});

final showStatisticsCardProvider = Provider<bool>((ref) {
  return ref.watch(showStatisticsCardNotifierProvider).value;
});

// Show Main Timeline
class ShowMainTimelineNotifier {
  bool _value;

  ShowMainTimelineNotifier() : _value = PreferencesService.getShowMainTimeline();

  bool get value => _value;

  Future<void> setShowMainTimeline(bool value) async {
    _value = value;
    await PreferencesService.setShowMainTimeline(value);
  }
}

final showMainTimelineNotifierProvider = Provider<ShowMainTimelineNotifier>((ref) {
  return ShowMainTimelineNotifier();
});

final showMainTimelineProvider = Provider<bool>((ref) {
  return ref.watch(showMainTimelineNotifierProvider).value;
});

// Default View
class DefaultViewNotifier {
  String _view;

  DefaultViewNotifier() : _view = PreferencesService.getDefaultView();

  String get view => _view;

  Future<void> setDefaultView(String view) async {
    _view = view;
    await PreferencesService.setDefaultView(view);
  }
}

final defaultViewNotifierProvider = Provider<DefaultViewNotifier>((ref) {
  return DefaultViewNotifier();
});

final defaultViewProvider = Provider<String>((ref) {
  return ref.watch(defaultViewNotifierProvider).view;
});

// Show Streak on Card
class ShowStreakOnCardNotifier {
  bool _value;

  ShowStreakOnCardNotifier() : _value = PreferencesService.getShowStreakOnCard();

  bool get value => _value;

  Future<void> setShowStreakOnCard(bool value) async {
    _value = value;
    await PreferencesService.setShowStreakOnCard(value);
  }
}

final showStreakOnCardNotifierProvider = Provider<ShowStreakOnCardNotifier>((ref) {
  return ShowStreakOnCardNotifier();
});

final showStreakOnCardProvider = Provider<bool>((ref) {
  return ref.watch(showStreakOnCardNotifierProvider).value;
});

// Bad Habit Logic Mode
class BadHabitLogicModeNotifier {
  String _mode;

  BadHabitLogicModeNotifier() : _mode = PreferencesService.getBadHabitLogicMode();

  String get mode => _mode;

  Future<void> setBadHabitLogicMode(String mode) async {
    _mode = mode;
    await PreferencesService.setBadHabitLogicMode(mode);
  }
}

final badHabitLogicModeNotifierProvider = Provider<BadHabitLogicModeNotifier>((ref) {
  return BadHabitLogicModeNotifier();
});

final badHabitLogicModeProvider = Provider<String>((ref) {
  return ref.watch(badHabitLogicModeNotifierProvider).mode;
});

