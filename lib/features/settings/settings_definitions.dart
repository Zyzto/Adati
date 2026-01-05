/// Adati Settings Definitions
///
/// All app settings defined using the Flutter Settings Framework.
/// This file replaces the verbose notifier-per-setting approach with
/// declarative setting definitions.
library;

import 'package:flutter/material.dart';
import '../../packages/flutter_settings_framework/flutter_settings_framework.dart';

// =============================================================================
// SECTIONS
// =============================================================================

/// General settings section (language, theme, etc.)
const generalSection = SettingSection(
  key: 'general',
  titleKey: 'general',
  icon: Icons.settings,
  order: 0,
  initiallyExpanded: true,
);

/// Appearance settings section
const appearanceSection = SettingSection(
  key: 'appearance',
  titleKey: 'appearance',
  icon: Icons.palette,
  order: 1,
);

/// Date & Time settings section
const dateTimeSection = SettingSection(
  key: 'date_time',
  titleKey: 'date_time',
  icon: Icons.access_time,
  order: 2,
);

/// Display & Layout settings section
const displayLayoutSection = SettingSection(
  key: 'display_layout',
  titleKey: 'display_layout',
  icon: Icons.view_quilt,
  order: 3,
);

/// Notifications settings section
const notificationsSection = SettingSection(
  key: 'notifications',
  titleKey: 'notifications',
  icon: Icons.notifications,
  order: 4,
);

/// Tags management section
const tagsSection = SettingSection(
  key: 'tags',
  titleKey: 'tags',
  icon: Icons.label,
  order: 5,
);

/// Data & Export section
const dataSection = SettingSection(
  key: 'data_export',
  titleKey: 'data_export',
  icon: Icons.cloud_upload,
  order: 6,
);

/// Advanced settings section
const advancedSection = SettingSection(
  key: 'advanced',
  titleKey: 'advanced',
  icon: Icons.build,
  order: 7,
);

/// About section
const aboutSection = SettingSection(
  key: 'about',
  titleKey: 'about',
  icon: Icons.info,
  order: 8,
);

// =============================================================================
// GENERAL SETTINGS
// =============================================================================

/// Theme mode setting (system, light, dark)
const themeModeSettingDef = EnumSetting(
  'theme_mode',
  defaultValue: 'system',
  titleKey: 'theme',
  options: ['system', 'light', 'dark'],
  optionLabels: {
    'system': 'system',
    'light': 'light',
    'dark': 'dark',
  },
  icon: Icons.dark_mode,
  section: 'general',
  order: 0,
  searchTerms: {
    'en': ['theme', 'dark', 'light', 'mode', 'appearance', 'system'],
    'ar': ['المظهر', 'داكن', 'فاتح', 'النظام', 'الوضع'],
  },
);

/// Language setting
const languageSettingDef = EnumSetting(
  'language',
  defaultValue: 'en',
  titleKey: 'language',
  options: ['en', 'ar'],
  optionLabels: {
    'en': 'english',
    'ar': 'arabic',
  },
  icon: Icons.language,
  section: 'general',
  order: 1,
  searchTerms: {
    'en': ['language', 'locale', 'english', 'arabic', 'translation'],
    'ar': ['اللغة', 'إنجليزي', 'عربي', 'ترجمة'],
  },
);

/// Theme color setting
const themeColorSettingDef = ColorSetting(
  'theme_color',
  defaultValue: 4283215696, // Default gray color
  titleKey: 'select_theme_color',
  icon: Icons.palette,
  section: 'general',
  order: 2,
  searchTerms: {
    'en': ['color', 'theme', 'accent', 'primary'],
    'ar': ['لون', 'المظهر', 'اللون الأساسي'],
  },
);

/// First launch flag (internal)
const firstLaunchSettingDef = BoolSetting(
  'first_launch',
  defaultValue: true,
  titleKey: 'first_launch',
  visible: false,
);

// =============================================================================
// APPEARANCE SETTINGS - Typography & Icons
// =============================================================================

/// Font size scale
const fontSizeScaleSettingDef = EnumSetting(
  'font_size_scale',
  defaultValue: 'normal',
  titleKey: 'font_size_scale',
  options: ['small', 'normal', 'large', 'extra_large'],
  icon: Icons.text_fields,
  section: 'appearance',
  subSection: 'typography',
  order: 0,
  searchTerms: {
    'en': ['font', 'size', 'scale', 'text', 'typography'],
    'ar': ['الخط', 'حجم', 'نص', 'الطباعة'],
  },
);

/// Icon size
const iconSizeSettingDef = EnumSetting(
  'icon_size',
  defaultValue: 'medium',
  titleKey: 'icon_size',
  options: ['small', 'medium', 'large'],
  icon: Icons.image,
  section: 'appearance',
  subSection: 'typography',
  order: 1,
  searchTerms: {
    'en': ['icon', 'size', 'image'],
    'ar': ['أيقونة', 'حجم', 'صورة'],
  },
);

// =============================================================================
// APPEARANCE SETTINGS - Card Style
// =============================================================================

/// Card border radius
const cardBorderRadiusSettingDef = DoubleSetting(
  'card_border_radius',
  defaultValue: 12.0,
  titleKey: 'border_radius',
  icon: Icons.rounded_corner,
  section: 'appearance',
  subSection: 'card_style',
  order: 0,
  min: 0,
  max: 32,
  step: 1,
  searchTerms: {
    'en': ['border', 'radius', 'corner', 'round', 'card'],
    'ar': ['حدود', 'زاوية', 'مستدير', 'بطاقة'],
  },
);

/// Card elevation
const cardElevationSettingDef = DoubleSetting(
  'card_elevation',
  defaultValue: 2.0,
  titleKey: 'elevation',
  icon: Icons.layers,
  section: 'appearance',
  subSection: 'card_style',
  order: 1,
  min: 0,
  max: 16,
  step: 0.5,
  searchTerms: {
    'en': ['elevation', 'shadow', 'depth', 'card'],
    'ar': ['ارتفاع', 'ظل', 'عمق', 'بطاقة'],
  },
);

/// Card spacing
const cardSpacingSettingDef = DoubleSetting(
  'card_spacing',
  defaultValue: 12.0,
  titleKey: 'card_spacing',
  icon: Icons.view_agenda,
  section: 'appearance',
  subSection: 'card_style',
  order: 2,
  min: 0,
  max: 32,
  step: 2,
  searchTerms: {
    'en': ['spacing', 'gap', 'margin', 'card'],
    'ar': ['تباعد', 'مسافة', 'هامش', 'بطاقة'],
  },
);

// =============================================================================
// APPEARANCE SETTINGS - Component Styles
// =============================================================================

/// Habit checkbox style
const habitCheckboxStyleSettingDef = EnumSetting(
  'habit_checkbox_style',
  defaultValue: 'circle',
  titleKey: 'habit_checkbox_style',
  options: ['square', 'bordered', 'circle', 'radio', 'task', 'verified', 'taskAlt'],
  icon: Icons.check_box,
  section: 'appearance',
  subSection: 'component_styles',
  order: 0,
  searchTerms: {
    'en': ['checkbox', 'check', 'style', 'habit', 'tick'],
    'ar': ['مربع اختيار', 'علامة', 'نمط', 'عادة'],
  },
);

/// Progress indicator style
const progressIndicatorStyleSettingDef = EnumSetting(
  'progress_indicator_style',
  defaultValue: 'circular',
  titleKey: 'progress_indicator_style',
  options: ['circular', 'linear'],
  icon: Icons.trending_up,
  section: 'appearance',
  subSection: 'component_styles',
  order: 1,
  searchTerms: {
    'en': ['progress', 'indicator', 'style', 'circular', 'linear'],
    'ar': ['تقدم', 'مؤشر', 'نمط', 'دائري', 'خطي'],
  },
);

// =============================================================================
// APPEARANCE SETTINGS - Completion Colors (Positive Habits)
// =============================================================================

/// Calendar completion color
const calendarCompletionColorSettingDef = ColorSetting(
  'calendar_completion_color',
  defaultValue: 0xFF4CAF50, // green
  titleKey: 'calendar_completion_color',
  icon: Icons.calendar_today,
  section: 'appearance',
  subSection: 'completion_colors_positive',
  order: 0,
  searchTerms: {
    'en': ['calendar', 'completion', 'color', 'green', 'complete'],
    'ar': ['تقويم', 'إكمال', 'لون', 'أخضر'],
  },
);

/// Habit card completion color
const habitCardCompletionColorSettingDef = ColorSetting(
  'habit_card_completion_color',
  defaultValue: 0xFF4CAF50,
  titleKey: 'habit_card_completion_color',
  icon: Icons.credit_card,
  section: 'appearance',
  subSection: 'completion_colors_positive',
  order: 1,
  searchTerms: {
    'en': ['habit', 'card', 'completion', 'color', 'border'],
    'ar': ['عادة', 'بطاقة', 'إكمال', 'لون', 'حدود'],
  },
);

/// Calendar timeline completion color
const calendarTimelineCompletionColorSettingDef = ColorSetting(
  'calendar_timeline_completion_color',
  defaultValue: 4282339765,
  titleKey: 'calendar_timeline_completion_color',
  icon: Icons.timeline,
  section: 'appearance',
  subSection: 'completion_colors_positive',
  order: 2,
  searchTerms: {
    'en': ['calendar', 'timeline', 'completion', 'color'],
    'ar': ['تقويم', 'جدول زمني', 'إكمال', 'لون'],
  },
);

/// Main timeline completion color
const mainTimelineCompletionColorSettingDef = ColorSetting(
  'main_timeline_completion_color',
  defaultValue: 0xFF4CAF50,
  titleKey: 'main_timeline_completion_color',
  icon: Icons.view_timeline,
  section: 'appearance',
  subSection: 'completion_colors_positive',
  order: 3,
  searchTerms: {
    'en': ['main', 'timeline', 'completion', 'color'],
    'ar': ['رئيسي', 'جدول زمني', 'إكمال', 'لون'],
  },
);

// =============================================================================
// APPEARANCE SETTINGS - Completion Colors (Negative Habits)
// =============================================================================

/// Calendar bad habit completion color
const calendarBadHabitCompletionColorSettingDef = ColorSetting(
  'calendar_bad_habit_completion_color',
  defaultValue: 0xFFF44336, // red
  titleKey: 'calendar_bad_habit_completion_color',
  icon: Icons.calendar_today,
  section: 'appearance',
  subSection: 'completion_colors_negative',
  order: 0,
  searchTerms: {
    'en': ['calendar', 'bad', 'habit', 'completion', 'color', 'red'],
    'ar': ['تقويم', 'عادة سيئة', 'إكمال', 'لون', 'أحمر'],
  },
);

/// Habit card bad habit completion color
const habitCardBadHabitCompletionColorSettingDef = ColorSetting(
  'habit_card_bad_habit_completion_color',
  defaultValue: 0xFFF44336,
  titleKey: 'habit_card_bad_habit_completion_color',
  icon: Icons.thumb_down,
  section: 'appearance',
  subSection: 'completion_colors_negative',
  order: 1,
  searchTerms: {
    'en': ['habit', 'card', 'bad', 'completion', 'color'],
    'ar': ['عادة', 'بطاقة', 'سيئة', 'إكمال', 'لون'],
  },
);

/// Calendar timeline bad habit completion color
const calendarTimelineBadHabitCompletionColorSettingDef = ColorSetting(
  'calendar_timeline_bad_habit_completion_color',
  defaultValue: 4280391411,
  titleKey: 'calendar_timeline_bad_habit_completion_color',
  icon: Icons.thumb_down,
  section: 'appearance',
  subSection: 'completion_colors_negative',
  order: 2,
  searchTerms: {
    'en': ['calendar', 'timeline', 'bad', 'completion', 'color'],
    'ar': ['تقويم', 'جدول زمني', 'سيئة', 'إكمال', 'لون'],
  },
);

/// Main timeline bad habit completion color
const mainTimelineBadHabitCompletionColorSettingDef = ColorSetting(
  'main_timeline_bad_habit_completion_color',
  defaultValue: 0xFFF44336,
  titleKey: 'main_timeline_bad_habit_completion_color',
  icon: Icons.thumb_down,
  section: 'appearance',
  subSection: 'completion_colors_negative',
  order: 3,
  searchTerms: {
    'en': ['main', 'timeline', 'bad', 'completion', 'color'],
    'ar': ['رئيسي', 'جدول زمني', 'سيئة', 'إكمال', 'لون'],
  },
);

// =============================================================================
// APPEARANCE SETTINGS - Streak Colors
// =============================================================================

/// Streak color scheme
const streakColorSchemeSettingDef = EnumSetting(
  'streak_color_scheme',
  defaultValue: 'default',
  titleKey: 'streak_color_scheme',
  options: ['default', 'vibrant', 'subtle', 'monochrome'],
  icon: Icons.color_lens,
  section: 'appearance',
  subSection: 'streak_colors',
  order: 0,
  searchTerms: {
    'en': ['streak', 'color', 'scheme', 'palette'],
    'ar': ['سلسلة', 'لون', 'نظام', 'لوحة'],
  },
);

// =============================================================================
// DATE & TIME SETTINGS
// =============================================================================

/// Date format
const dateFormatSettingDef = EnumSetting(
  'date_format',
  defaultValue: 'yyyy-MM-dd',
  titleKey: 'date_format',
  options: ['yyyy-MM-dd', 'MM/dd/yyyy', 'dd/MM/yyyy', 'dd.MM.yyyy'],
  // Raw format strings - useRawLabels prevents translation attempts
  useRawLabels: true,
  icon: Icons.date_range,
  section: 'date_time',
  order: 0,
  searchTerms: {
    'en': ['date', 'format', 'day', 'month', 'year'],
    'ar': ['تاريخ', 'تنسيق', 'يوم', 'شهر', 'سنة'],
  },
);

/// First day of week (0=Sunday, 1=Monday)
const firstDayOfWeekSettingDef = IntSetting(
  'first_day_of_week',
  defaultValue: 0,
  titleKey: 'first_day_of_week',
  icon: Icons.calendar_today,
  section: 'date_time',
  order: 1,
  min: 0,
  max: 1,
  searchTerms: {
    'en': ['first', 'day', 'week', 'sunday', 'monday'],
    'ar': ['أول', 'يوم', 'أسبوع', 'الأحد', 'الاثنين'],
  },
);

// =============================================================================
// DISPLAY & LAYOUT SETTINGS - Habits Layout
// =============================================================================

/// Habits layout mode (list/grid)
const habitsLayoutModeSettingDef = EnumSetting(
  'habits_layout_mode',
  defaultValue: 'list',
  titleKey: 'habits_layout_mode',
  options: ['list', 'grid'],
  optionLabels: {
    'list': 'habits_layout_list',
    'grid': 'habits_layout_grid',
  },
  icon: Icons.view_list,
  section: 'display_layout',
  subSection: 'habits_layout',
  order: 0,
  searchTerms: {
    'en': ['habits', 'layout', 'list', 'grid', 'view'],
    'ar': ['عادات', 'تخطيط', 'قائمة', 'شبكة', 'عرض'],
  },
);

/// Default view
const defaultViewSettingDef = EnumSetting(
  'default_view',
  defaultValue: 'habits',
  titleKey: 'default_view',
  options: ['habits', 'timeline'],
  icon: Icons.home,
  section: 'display_layout',
  subSection: 'habits_layout',
  order: 1,
  searchTerms: {
    'en': ['default', 'view', 'home', 'start'],
    'ar': ['افتراضي', 'عرض', 'الصفحة الرئيسية', 'بداية'],
  },
);

/// Habit card layout mode
const habitCardLayoutModeSettingDef = EnumSetting(
  'habit_card_layout_mode',
  defaultValue: 'classic',
  titleKey: 'habit_card_layout_mode',
  options: ['classic', 'top_row'],
  optionLabels: {
    'classic': 'habit_card_layout_mode_classic',
    'top_row': 'habit_card_layout_mode_top_row',
  },
  icon: Icons.view_module,
  section: 'display_layout',
  subSection: 'habit_cards',
  order: 0,
  searchTerms: {
    'en': ['habit', 'card', 'layout', 'classic', 'top'],
    'ar': ['عادة', 'بطاقة', 'تخطيط', 'كلاسيكي'],
  },
);

// =============================================================================
// DISPLAY & LAYOUT SETTINGS - Display Preferences
// =============================================================================

/// Show streak borders
const showStreakBordersSettingDef = BoolSetting(
  'show_streak_borders',
  defaultValue: false,
  titleKey: 'show_streak_borders',
  subtitleKey: 'show_streak_borders_description',
  icon: Icons.border_outer,
  section: 'display_layout',
  subSection: 'display_preferences',
  order: 0,
  searchTerms: {
    'en': ['streak', 'borders', 'show', 'display'],
    'ar': ['سلسلة', 'حدود', 'إظهار', 'عرض'],
  },
);

/// Show streak numbers
const showStreakNumbersSettingDef = BoolSetting(
  'show_streak_numbers',
  defaultValue: false,
  titleKey: 'show_streak_numbers',
  subtitleKey: 'show_streak_numbers_description',
  icon: Icons.format_list_numbered,
  section: 'display_layout',
  subSection: 'display_preferences',
  order: 1,
  searchTerms: {
    'en': ['streak', 'numbers', 'show', 'count'],
    'ar': ['سلسلة', 'أرقام', 'إظهار', 'عدد'],
  },
);

/// Show streak on card
const showStreakOnCardSettingDef = BoolSetting(
  'show_streak_on_card',
  defaultValue: false,
  titleKey: 'show_streak_on_card',
  subtitleKey: 'show_streak_on_card_description',
  icon: Icons.local_fire_department,
  section: 'display_layout',
  subSection: 'display_preferences',
  order: 2,
  searchTerms: {
    'en': ['streak', 'card', 'show'],
    'ar': ['سلسلة', 'بطاقة', 'إظهار'],
  },
);

/// Show descriptions
const showDescriptionsSettingDef = BoolSetting(
  'show_descriptions',
  defaultValue: true,
  titleKey: 'show_descriptions',
  subtitleKey: 'show_descriptions_description',
  icon: Icons.description,
  section: 'display_layout',
  subSection: 'display_preferences',
  order: 3,
  searchTerms: {
    'en': ['descriptions', 'show', 'text', 'details'],
    'ar': ['أوصاف', 'إظهار', 'نص', 'تفاصيل'],
  },
);

/// Show percentage
const showPercentageSettingDef = BoolSetting(
  'show_percentage',
  defaultValue: true,
  titleKey: 'show_percentage',
  subtitleKey: 'show_percentage_description',
  icon: Icons.percent,
  section: 'display_layout',
  subSection: 'display_preferences',
  order: 4,
  searchTerms: {
    'en': ['percentage', 'percent', 'show'],
    'ar': ['نسبة مئوية', 'نسبة', 'إظهار'],
  },
);

/// Compact cards
const compactCardsSettingDef = BoolSetting(
  'compact_cards',
  defaultValue: false,
  titleKey: 'compact_cards',
  subtitleKey: 'compact_cards_description',
  icon: Icons.compress,
  section: 'display_layout',
  subSection: 'display_preferences',
  order: 5,
  searchTerms: {
    'en': ['compact', 'cards', 'small', 'dense'],
    'ar': ['مضغوط', 'بطاقات', 'صغير', 'كثيف'],
  },
);

// =============================================================================
// DISPLAY & LAYOUT SETTINGS - Timeline
// =============================================================================

/// Main timeline days
const timelineDaysSettingDef = IntSetting(
  'timeline_days',
  defaultValue: 100,
  titleKey: 'timeline_days',
  icon: Icons.view_timeline,
  section: 'display_layout',
  subSection: 'timelines',
  order: 0,
  min: 7,
  max: 365,
  step: 1,
  searchTerms: {
    'en': ['timeline', 'days', 'history', 'range'],
    'ar': ['جدول زمني', 'أيام', 'تاريخ', 'نطاق'],
  },
);

/// Modal timeline days
const modalTimelineDaysSettingDef = IntSetting(
  'modal_timeline_days',
  defaultValue: 100,
  titleKey: 'modal_timeline_days',
  icon: Icons.view_timeline,
  section: 'display_layout',
  subSection: 'timelines',
  order: 1,
  min: 7,
  max: 365,
  searchTerms: {
    'en': ['modal', 'detail', 'timeline', 'days'],
    'ar': ['نافذة', 'تفاصيل', 'جدول زمني', 'أيام'],
  },
);

/// Habit card timeline days
const habitCardTimelineDaysSettingDef = IntSetting(
  'habit_card_timeline_days',
  defaultValue: 50,
  titleKey: 'habit_card_timeline_days',
  icon: Icons.view_timeline,
  section: 'display_layout',
  subSection: 'timelines',
  order: 2,
  min: 7,
  max: 200,
  searchTerms: {
    'en': ['habit', 'card', 'timeline', 'days'],
    'ar': ['عادة', 'بطاقة', 'جدول زمني', 'أيام'],
  },
);

/// Day square size
const daySquareSizeSettingDef = EnumSetting(
  'day_square_size',
  defaultValue: 'large',
  titleKey: 'day_square_size',
  options: ['small', 'medium', 'large'],
  icon: Icons.grid_on,
  section: 'display_layout',
  subSection: 'timelines',
  order: 3,
  searchTerms: {
    'en': ['day', 'square', 'size', 'cell'],
    'ar': ['يوم', 'مربع', 'حجم', 'خلية'],
  },
);

/// Timeline spacing
const timelineSpacingSettingDef = DoubleSetting(
  'timeline_spacing',
  defaultValue: 6.0,
  titleKey: 'timeline_spacing',
  icon: Icons.space_bar,
  section: 'display_layout',
  subSection: 'timelines',
  order: 4,
  min: 0,
  max: 16,
  step: 1,
  searchTerms: {
    'en': ['timeline', 'spacing', 'gap'],
    'ar': ['جدول زمني', 'تباعد', 'فجوة'],
  },
);

/// Timeline compact mode
const timelineCompactModeSettingDef = BoolSetting(
  'timeline_compact_mode',
  defaultValue: false,
  titleKey: 'timeline_compact_mode',
  subtitleKey: 'timeline_compact_mode_description',
  icon: Icons.compress,
  section: 'display_layout',
  subSection: 'timelines',
  order: 5,
  searchTerms: {
    'en': ['timeline', 'compact', 'dense'],
    'ar': ['جدول زمني', 'مضغوط', 'كثيف'],
  },
);

/// Show week/month highlights
const showWeekMonthHighlightsSettingDef = BoolSetting(
  'show_week_month_highlights',
  defaultValue: true,
  titleKey: 'show_week_month_highlights',
  subtitleKey: 'show_week_month_highlights_description',
  icon: Icons.highlight,
  section: 'display_layout',
  subSection: 'timelines',
  order: 6,
  searchTerms: {
    'en': ['week', 'month', 'highlights', 'show'],
    'ar': ['أسبوع', 'شهر', 'تمييز', 'إظهار'],
  },
);

/// Use streak colors for squares
const useStreakColorsForSquaresSettingDef = BoolSetting(
  'use_streak_colors_for_squares',
  defaultValue: false,
  titleKey: 'use_streak_colors_for_squares',
  subtitleKey: 'use_streak_colors_for_squares_description',
  icon: Icons.color_lens,
  section: 'display_layout',
  subSection: 'timelines',
  order: 7,
  searchTerms: {
    'en': ['streak', 'colors', 'squares', 'gradient'],
    'ar': ['سلسلة', 'ألوان', 'مربعات', 'تدرج'],
  },
);

// =============================================================================
// DISPLAY & LAYOUT SETTINGS - Fill Lines Mode
// =============================================================================

/// Habit card timeline fill lines
const habitCardTimelineFillLinesSettingDef = BoolSetting(
  'habit_card_timeline_fill_lines',
  defaultValue: false,
  titleKey: 'habit_card_timeline_fill_lines',
  subtitleKey: 'habit_card_timeline_fill_lines_description',
  icon: Icons.view_array,
  section: 'display_layout',
  subSection: 'timelines',
  order: 10,
  searchTerms: {
    'en': ['habit', 'card', 'timeline', 'fill', 'lines'],
    'ar': ['عادة', 'بطاقة', 'جدول زمني', 'ملء', 'خطوط'],
  },
);

/// Habit card timeline lines count
const habitCardTimelineLinesSettingDef = IntSetting(
  'habit_card_timeline_lines',
  defaultValue: 3,
  titleKey: 'habit_card_timeline_lines',
  icon: Icons.view_array,
  section: 'display_layout',
  subSection: 'timelines',
  order: 11,
  min: 1,
  max: 10,
  searchTerms: {
    'en': ['habit', 'card', 'timeline', 'lines', 'rows'],
    'ar': ['عادة', 'بطاقة', 'جدول زمني', 'خطوط', 'صفوف'],
  },
);

/// Main timeline fill lines
const mainTimelineFillLinesSettingDef = BoolSetting(
  'main_timeline_fill_lines',
  defaultValue: false,
  titleKey: 'main_timeline_fill_lines',
  subtitleKey: 'main_timeline_fill_lines_description',
  icon: Icons.view_array,
  section: 'display_layout',
  subSection: 'timelines',
  order: 12,
  searchTerms: {
    'en': ['main', 'timeline', 'fill', 'lines'],
    'ar': ['رئيسي', 'جدول زمني', 'ملء', 'خطوط'],
  },
);

/// Main timeline lines count
const mainTimelineLinesSettingDef = IntSetting(
  'main_timeline_lines',
  defaultValue: 3,
  titleKey: 'main_timeline_lines',
  icon: Icons.view_array,
  section: 'display_layout',
  subSection: 'timelines',
  order: 13,
  min: 1,
  max: 10,
  searchTerms: {
    'en': ['main', 'timeline', 'lines', 'rows'],
    'ar': ['رئيسي', 'جدول زمني', 'خطوط', 'صفوف'],
  },
);

// =============================================================================
// DISPLAY & LAYOUT SETTINGS - Statistics & Main Timeline
// =============================================================================

/// Show statistics card
const showStatisticsCardSettingDef = BoolSetting(
  'show_statistics_card',
  defaultValue: true,
  titleKey: 'show_statistics_card',
  subtitleKey: 'show_statistics_card_description',
  icon: Icons.bar_chart,
  section: 'display_layout',
  subSection: 'statistics',
  order: 0,
  searchTerms: {
    'en': ['statistics', 'stats', 'card', 'show'],
    'ar': ['إحصائيات', 'بطاقة', 'إظهار'],
  },
);

/// Show main timeline
const showMainTimelineSettingDef = BoolSetting(
  'show_main_timeline',
  defaultValue: true,
  titleKey: 'show_main_timeline',
  subtitleKey: 'show_main_timeline_description',
  icon: Icons.view_timeline,
  section: 'display_layout',
  subSection: 'statistics',
  order: 1,
  searchTerms: {
    'en': ['main', 'timeline', 'show', 'calendar'],
    'ar': ['رئيسي', 'جدول زمني', 'إظهار', 'تقويم'],
  },
);

// =============================================================================
// DISPLAY & LAYOUT SETTINGS - Grid View
// =============================================================================

/// Grid show icon
const gridShowIconSettingDef = BoolSetting(
  'grid_show_icon',
  defaultValue: true,
  titleKey: 'grid_show_icon',
  icon: Icons.image,
  section: 'display_layout',
  subSection: 'grid_view',
  order: 0,
  searchTerms: {
    'en': ['grid', 'icon', 'show'],
    'ar': ['شبكة', 'أيقونة', 'إظهار'],
  },
);

/// Grid show completion
const gridShowCompletionSettingDef = BoolSetting(
  'grid_show_completion',
  defaultValue: true,
  titleKey: 'grid_show_completion',
  icon: Icons.check_circle,
  section: 'display_layout',
  subSection: 'grid_view',
  order: 1,
  searchTerms: {
    'en': ['grid', 'completion', 'button', 'show'],
    'ar': ['شبكة', 'إكمال', 'زر', 'إظهار'],
  },
);

/// Grid completion button placement
const gridCompletionButtonPlacementSettingDef = EnumSetting(
  'grid_completion_button_placement',
  defaultValue: 'center',
  titleKey: 'grid_completion_button_placement',
  options: ['center', 'overlay'],
  icon: Icons.place,
  section: 'display_layout',
  subSection: 'grid_view',
  order: 2,
  searchTerms: {
    'en': ['grid', 'completion', 'button', 'placement', 'position'],
    'ar': ['شبكة', 'إكمال', 'زر', 'موضع'],
  },
);

/// Grid show timeline
const gridShowTimelineSettingDef = BoolSetting(
  'grid_show_timeline',
  defaultValue: true,
  titleKey: 'grid_show_timeline',
  icon: Icons.view_timeline,
  section: 'display_layout',
  subSection: 'grid_view',
  order: 3,
  searchTerms: {
    'en': ['grid', 'timeline', 'show'],
    'ar': ['شبكة', 'جدول زمني', 'إظهار'],
  },
);

/// Grid timeline box size
const gridTimelineBoxSizeSettingDef = EnumSetting(
  'grid_timeline_box_size',
  defaultValue: 'small',
  titleKey: 'grid_timeline_box_size',
  options: ['small', 'medium', 'large'],
  icon: Icons.grid_on,
  section: 'display_layout',
  subSection: 'grid_view',
  order: 4,
  searchTerms: {
    'en': ['grid', 'timeline', 'box', 'size'],
    'ar': ['شبكة', 'جدول زمني', 'مربع', 'حجم'],
  },
);

/// Grid timeline fit mode
const gridTimelineFitModeSettingDef = EnumSetting(
  'grid_timeline_fit_mode',
  defaultValue: 'fit',
  titleKey: 'grid_timeline_fill_lines',
  options: ['fit', 'scroll'],
  icon: Icons.fit_screen,
  section: 'display_layout',
  subSection: 'grid_view',
  order: 5,
  searchTerms: {
    'en': ['grid', 'timeline', 'fit', 'scroll'],
    'ar': ['شبكة', 'جدول زمني', 'ملاءمة', 'تمرير'],
  },
);

// =============================================================================
// NOTIFICATIONS SETTINGS
// =============================================================================

/// Notifications enabled
const notificationsEnabledSettingDef = BoolSetting(
  'notifications_enabled',
  defaultValue: true,
  titleKey: 'enable_notifications',
  subtitleKey: 'receive_habit_reminders',
  icon: Icons.notifications,
  section: 'notifications',
  order: 0,
  searchTerms: {
    'en': ['notifications', 'reminders', 'alerts', 'enable'],
    'ar': ['إشعارات', 'تذكيرات', 'تنبيهات', 'تفعيل'],
  },
);

// =============================================================================
// ADVANCED SETTINGS
// =============================================================================

/// Bad habit logic mode
const badHabitLogicModeSettingDef = EnumSetting(
  'bad_habit_logic_mode',
  defaultValue: 'positive',
  titleKey: 'bad_habit_logic_mode',
  subtitleKey: 'bad_habit_logic_mode_description',
  options: ['positive', 'negative'],
  optionLabels: {
    'positive': 'bad_habit_logic_mode_positive',
    'negative': 'bad_habit_logic_mode_negative',
  },
  icon: Icons.swap_horiz,
  section: 'advanced',
  order: 0,
  searchTerms: {
    'en': ['bad', 'habit', 'logic', 'mode', 'positive', 'negative'],
    'ar': ['عادة سيئة', 'منطق', 'وضع', 'إيجابي', 'سلبي'],
  },
);

// =============================================================================
// AUTO-BACKUP SETTINGS
// =============================================================================

/// Auto backup enabled
const autoBackupEnabledSettingDef = BoolSetting(
  'auto_backup_enabled',
  defaultValue: false,
  titleKey: 'auto_backup_enabled',
  subtitleKey: 'auto_backup_description',
  icon: Icons.backup,
  section: 'data_export',
  order: 0,
  searchTerms: {
    'en': ['auto', 'backup', 'automatic', 'save'],
    'ar': ['تلقائي', 'نسخ احتياطي', 'حفظ'],
  },
);

/// Auto backup retention count
const autoBackupRetentionCountSettingDef = IntSetting(
  'auto_backup_retention_count',
  defaultValue: 10,
  titleKey: 'auto_backup_retention_count',
  subtitleKey: 'auto_backup_retention_description',
  icon: Icons.history,
  section: 'data_export',
  order: 1,
  min: 1,
  max: 100,
  searchTerms: {
    'en': ['backup', 'retention', 'count', 'keep'],
    'ar': ['نسخ احتياطي', 'احتفاظ', 'عدد', 'حفظ'],
  },
);

/// Auto backup user directory
const autoBackupUserDirectorySettingDef = StringSetting(
  'auto_backup_user_directory',
  defaultValue: '',
  titleKey: 'auto_backup_directory',
  icon: Icons.folder,
  section: 'data_export',
  order: 2,
  searchTerms: {
    'en': ['backup', 'directory', 'folder', 'path'],
    'ar': ['نسخ احتياطي', 'مجلد', 'مسار'],
  },
);

/// Auto backup last backup timestamp
const autoBackupLastBackupSettingDef = StringSetting(
  'auto_backup_last_backup',
  defaultValue: '',
  titleKey: 'auto_backup_last_backup',
  icon: Icons.access_time,
  section: 'data_export',
  order: 3,
  visible: false,
  searchTerms: {},
);

// =============================================================================
// INTERNAL/SESSION SETTINGS (not visible in UI)
// =============================================================================

/// Habit sort order
const habitSortOrderSettingDef = StringSetting(
  'habit_sort_order',
  defaultValue: 'name',
  titleKey: 'sort',
  visible: false,
);

/// Habit filter query
const habitFilterQuerySettingDef = StringSetting(
  'habit_filter_query',
  defaultValue: '',
  titleKey: 'search',
  visible: false,
);

/// Habit group by
const habitGroupBySettingDef = StringSetting(
  'habit_group_by',
  defaultValue: '',
  titleKey: 'group_by_type',
  visible: false,
);

/// Habit filter by type
const habitFilterByTypeSettingDef = StringSetting(
  'habit_filter_by_type',
  defaultValue: '',
  titleKey: 'filter_by_tags',
  visible: false,
);

/// Habit filter by tags
const habitFilterByTagsSettingDef = StringSetting(
  'habit_filter_by_tags',
  defaultValue: '',
  titleKey: 'filter_by_tags',
  visible: false,
);

// =============================================================================
// SETTINGS PAGE EXPANSION STATES (internal)
// =============================================================================

const settingsGeneralExpandedDef = BoolSetting(
  'settings_general_expanded',
  defaultValue: true,
  titleKey: 'general',
  visible: false,
);

const settingsAppearanceExpandedDef = BoolSetting(
  'settings_appearance_expanded',
  defaultValue: false,
  titleKey: 'appearance',
  visible: false,
);

const settingsDateTimeExpandedDef = BoolSetting(
  'settings_date_time_expanded',
  defaultValue: false,
  titleKey: 'date_time',
  visible: false,
);

const settingsDisplayExpandedDef = BoolSetting(
  'settings_display_expanded',
  defaultValue: false,
  titleKey: 'display',
  visible: false,
);

const settingsDisplayPreferencesExpandedDef = BoolSetting(
  'settings_display_preferences_expanded',
  defaultValue: false,
  titleKey: 'display_preferences',
  visible: false,
);

const settingsDisplayLayoutExpandedDef = BoolSetting(
  'settings_display_layout_expanded',
  defaultValue: false,
  titleKey: 'display_layout',
  visible: false,
);

const settingsNotificationsExpandedDef = BoolSetting(
  'settings_notifications_expanded',
  defaultValue: false,
  titleKey: 'notifications',
  visible: false,
);

const settingsTagsExpandedDef = BoolSetting(
  'settings_tags_expanded',
  defaultValue: false,
  titleKey: 'tags',
  visible: false,
);

const settingsDataExportExpandedDef = BoolSetting(
  'settings_data_export_expanded',
  defaultValue: false,
  titleKey: 'data_export',
  visible: false,
);

const settingsAdvancedExpandedDef = BoolSetting(
  'settings_advanced_expanded',
  defaultValue: false,
  titleKey: 'advanced',
  visible: false,
);

const settingsAboutExpandedDef = BoolSetting(
  'settings_about_expanded',
  defaultValue: false,
  titleKey: 'about',
  visible: false,
);

// =============================================================================
// REGISTRY - All settings and sections
// =============================================================================

/// All setting sections.
const allSections = [
  generalSection,
  appearanceSection,
  dateTimeSection,
  displayLayoutSection,
  notificationsSection,
  tagsSection,
  dataSection,
  advancedSection,
  aboutSection,
];

/// All setting definitions.
const allSettings = <SettingDefinition>[
  // General
  themeModeSettingDef,
  languageSettingDef,
  themeColorSettingDef,
  firstLaunchSettingDef,

  // Appearance - Typography
  fontSizeScaleSettingDef,
  iconSizeSettingDef,

  // Appearance - Card Style
  cardBorderRadiusSettingDef,
  cardElevationSettingDef,
  cardSpacingSettingDef,

  // Appearance - Component Styles
  habitCheckboxStyleSettingDef,
  progressIndicatorStyleSettingDef,

  // Appearance - Completion Colors (Positive)
  calendarCompletionColorSettingDef,
  habitCardCompletionColorSettingDef,
  calendarTimelineCompletionColorSettingDef,
  mainTimelineCompletionColorSettingDef,

  // Appearance - Completion Colors (Negative)
  calendarBadHabitCompletionColorSettingDef,
  habitCardBadHabitCompletionColorSettingDef,
  calendarTimelineBadHabitCompletionColorSettingDef,
  mainTimelineBadHabitCompletionColorSettingDef,

  // Appearance - Streak Colors
  streakColorSchemeSettingDef,

  // Date & Time
  dateFormatSettingDef,
  firstDayOfWeekSettingDef,

  // Display & Layout - Habits
  habitsLayoutModeSettingDef,
  defaultViewSettingDef,
  habitCardLayoutModeSettingDef,

  // Display & Layout - Display Preferences
  showStreakBordersSettingDef,
  showStreakNumbersSettingDef,
  showStreakOnCardSettingDef,
  showDescriptionsSettingDef,
  showPercentageSettingDef,
  compactCardsSettingDef,

  // Display & Layout - Timeline
  timelineDaysSettingDef,
  modalTimelineDaysSettingDef,
  habitCardTimelineDaysSettingDef,
  daySquareSizeSettingDef,
  timelineSpacingSettingDef,
  timelineCompactModeSettingDef,
  showWeekMonthHighlightsSettingDef,
  useStreakColorsForSquaresSettingDef,
  habitCardTimelineFillLinesSettingDef,
  habitCardTimelineLinesSettingDef,
  mainTimelineFillLinesSettingDef,
  mainTimelineLinesSettingDef,

  // Display & Layout - Statistics
  showStatisticsCardSettingDef,
  showMainTimelineSettingDef,

  // Display & Layout - Grid View
  gridShowIconSettingDef,
  gridShowCompletionSettingDef,
  gridCompletionButtonPlacementSettingDef,
  gridShowTimelineSettingDef,
  gridTimelineBoxSizeSettingDef,
  gridTimelineFitModeSettingDef,

  // Notifications
  notificationsEnabledSettingDef,

  // Advanced
  badHabitLogicModeSettingDef,

  // Data & Export
  autoBackupEnabledSettingDef,
  autoBackupRetentionCountSettingDef,
  autoBackupUserDirectorySettingDef,
  autoBackupLastBackupSettingDef,

  // Internal/Session settings
  habitSortOrderSettingDef,
  habitFilterQuerySettingDef,
  habitGroupBySettingDef,
  habitFilterByTypeSettingDef,
  habitFilterByTagsSettingDef,

  // Settings page expansion states
  settingsGeneralExpandedDef,
  settingsAppearanceExpandedDef,
  settingsDateTimeExpandedDef,
  settingsDisplayExpandedDef,
  settingsDisplayPreferencesExpandedDef,
  settingsDisplayLayoutExpandedDef,
  settingsNotificationsExpandedDef,
  settingsTagsExpandedDef,
  settingsDataExportExpandedDef,
  settingsAdvancedExpandedDef,
  settingsAboutExpandedDef,
];

/// Create the Adati settings registry.
SettingsRegistry createAdatiSettingsRegistry() {
  return SettingsRegistry.withSettings(
    sections: allSections,
    settings: allSettings,
  );
}

