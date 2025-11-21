import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_providers.dart';
import '../../utils/settings_formatters.dart';
import '../settings_section.dart';

/// Appearance settings section
class AppearanceSectionContent extends ConsumerWidget {
  final Function(BuildContext, WidgetRef) showFontSizeScaleDialog;
  final Function(BuildContext, WidgetRef) showIconSizeDialog;
  final Function(BuildContext, WidgetRef) showCardBorderRadiusDialog;
  final Function(BuildContext, WidgetRef) showCardElevationDialog;
  final Function(BuildContext, WidgetRef) showCardSpacingDialog;
  final Function(BuildContext, WidgetRef) showHabitCheckboxStyleDialog;
  final Function(BuildContext, WidgetRef) showProgressIndicatorStyleDialog;
  final void Function(
    BuildContext context,
    WidgetRef ref,
    String titleKey,
    int currentColor,
    Future<void> Function(int) onColorChanged,
    Provider<dynamic> notifierProvider,
    Provider<dynamic>? valueProvider,
  )
  showCompletionColorDialog;
  final Function(BuildContext, WidgetRef) showStreakColorSchemeDialog;

  const AppearanceSectionContent({
    super.key,
    required this.showFontSizeScaleDialog,
    required this.showIconSizeDialog,
    required this.showCardBorderRadiusDialog,
    required this.showCardElevationDialog,
    required this.showCardSpacingDialog,
    required this.showHabitCheckboxStyleDialog,
    required this.showProgressIndicatorStyleDialog,
    required this.showCompletionColorDialog,
    required this.showStreakColorSchemeDialog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSizeScale = ref.watch(fontSizeScaleProvider);
    final iconSize = ref.watch(iconSizeProvider);
    final cardBorderRadius = ref.watch(cardBorderRadiusProvider);
    final cardElevation = ref.watch(cardElevationProvider);
    final cardSpacing = ref.watch(cardSpacingProvider);
    final habitCheckboxStyle = ref.watch(habitCheckboxStyleProvider);
    final progressIndicatorStyle = ref.watch(progressIndicatorStyleProvider);
    final calendarCompletionColor = ref.watch(calendarCompletionColorProvider);
    final habitCardCompletionColor = ref.watch(
      habitCardCompletionColorProvider,
    );
    final calendarTimelineCompletionColor = ref.watch(
      calendarTimelineCompletionColorProvider,
    );
    final mainTimelineCompletionColor = ref.watch(
      mainTimelineCompletionColorProvider,
    );
    final calendarBadHabitCompletionColor = ref.watch(
      calendarBadHabitCompletionColorProvider,
    );
    final habitCardBadHabitCompletionColor = ref.watch(
      habitCardBadHabitCompletionColorProvider,
    );
    final calendarTimelineBadHabitCompletionColor = ref.watch(
      calendarTimelineBadHabitCompletionColorProvider,
    );
    final mainTimelineBadHabitCompletionColor = ref.watch(
      mainTimelineBadHabitCompletionColorProvider,
    );
    final streakColorScheme = ref.watch(streakColorSchemeProvider);

    return Column(
      children: [
        // 1. Typography & Icons (global visual settings)
        SettingsSubsectionHeader(
          title: 'settings_section_appearance_typography'.tr(),
          icon: Icons.text_fields,
        ),
        ListTile(
          leading: const Icon(Icons.text_fields),
          title: Text('font_size_scale'.tr()),
          subtitle: Text(
            SettingsFormatters.getFontSizeScaleName(fontSizeScale),
          ),
          onTap: () => showFontSizeScaleDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.image),
          title: Text('icon_size'.tr()),
          subtitle: Text(SettingsFormatters.getIconSizeName(iconSize)),
          onTap: () => showIconSizeDialog(context, ref),
        ),
        const Divider(),

        // 2. Card Style (most visible component styling)
        SettingsSubsectionHeader(
          title: 'settings_section_appearance_card_style'.tr(),
          icon: Icons.credit_card,
        ),
        ListTile(
          leading: const Icon(Icons.rounded_corner),
          title: Text('border_radius'.tr()),
          subtitle: Text('${cardBorderRadius.toStringAsFixed(1)}px'),
          onTap: () => showCardBorderRadiusDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.layers),
          title: Text('elevation'.tr()),
          subtitle: Text(cardElevation.toStringAsFixed(1)),
          onTap: () => showCardElevationDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.view_agenda),
          title: Text('card_spacing'.tr()),
          subtitle: Text('${cardSpacing.toStringAsFixed(1)}px'),
          onTap: () => showCardSpacingDialog(context, ref),
        ),
        const Divider(),

        // 3. Component Styles (specific UI component styling)
        SettingsSubsectionHeader(
          title: 'settings_section_appearance_component_styles'.tr(),
          icon: Icons.style,
        ),
        ListTile(
          leading: const Icon(Icons.check_box),
          title: Text('habit_checkbox_style'.tr()),
          subtitle: Text(
            SettingsFormatters.getCheckboxStyleName(habitCheckboxStyle),
          ),
          onTap: () => showHabitCheckboxStyleDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.trending_up),
          title: Text('progress_indicator_style'.tr()),
          subtitle: Text(
            SettingsFormatters.getProgressIndicatorStyleName(
              progressIndicatorStyle,
            ),
          ),
          onTap: () => showProgressIndicatorStyleDialog(context, ref),
        ),
        const Divider(),
        // 4. Completion Colors (organized by context, positive first)
        SettingsSubsectionHeader(
          title: 'settings_section_appearance_completion_colors'.tr(),
          icon: Icons.color_lens,
        ),
        // Positive Habits sub-subsection
        SettingsSubsectionHeader(
          title: 'settings_section_appearance_completion_colors_positive'.tr(),
          icon: Icons.thumb_up,
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text('calendar_completion_color'.tr()),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(calendarCompletionColor),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
          ),
          onTap: () => showCompletionColorDialog(
            context,
            ref,
            'calendar_completion_color',
            calendarCompletionColor,
            (color) async {
              final notifier = ref.read(
                calendarCompletionColorNotifierProvider,
              );
              await notifier.setCalendarCompletionColor(color);
            },
            calendarCompletionColorNotifierProvider,
            calendarCompletionColorProvider,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.credit_card),
          title: Text('habit_card_completion_color'.tr()),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(habitCardCompletionColor),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
          ),
          onTap: () => showCompletionColorDialog(
            context,
            ref,
            'habit_card_completion_color',
            habitCardCompletionColor,
            (color) async {
              final notifier = ref.read(
                habitCardCompletionColorNotifierProvider,
              );
              await notifier.setHabitCardCompletionColor(color);
            },
            habitCardCompletionColorNotifierProvider,
            habitCardCompletionColorProvider,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.timeline),
          title: Text('calendar_timeline_completion_color'.tr()),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(calendarTimelineCompletionColor),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
          ),
          onTap: () => showCompletionColorDialog(
            context,
            ref,
            'calendar_timeline_completion_color',
            calendarTimelineCompletionColor,
            (color) async {
              final notifier = ref.read(
                calendarTimelineCompletionColorNotifierProvider,
              );
              await notifier.setCalendarTimelineCompletionColor(color);
            },
            calendarTimelineCompletionColorNotifierProvider,
            calendarTimelineCompletionColorProvider,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.view_timeline),
          title: Text('main_timeline_completion_color'.tr()),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(mainTimelineCompletionColor),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
          ),
          onTap: () => showCompletionColorDialog(
            context,
            ref,
            'main_timeline_completion_color',
            mainTimelineCompletionColor,
            (color) async {
              final notifier = ref.read(
                mainTimelineCompletionColorNotifierProvider,
              );
              await notifier.setMainTimelineCompletionColor(color);
            },
            mainTimelineCompletionColorNotifierProvider,
            mainTimelineCompletionColorProvider,
          ),
        ),
        // Negative Habits sub-subsection
        const Divider(),
        SettingsSubsectionHeader(
          title: 'settings_section_appearance_completion_colors_negative'.tr(),
          icon: Icons.thumb_down,
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text('calendar_bad_habit_completion_color'.tr()),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(calendarBadHabitCompletionColor),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
          ),
          onTap: () => showCompletionColorDialog(
            context,
            ref,
            'calendar_bad_habit_completion_color',
            calendarBadHabitCompletionColor,
            (color) async {
              final notifier = ref.read(
                calendarBadHabitCompletionColorNotifierProvider,
              );
              await notifier.setCalendarBadHabitCompletionColor(color);
            },
            calendarBadHabitCompletionColorNotifierProvider,
            calendarBadHabitCompletionColorProvider,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.thumb_down),
          title: Text('habit_card_bad_habit_completion_color'.tr()),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(habitCardBadHabitCompletionColor),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
          ),
          onTap: () => showCompletionColorDialog(
            context,
            ref,
            'habit_card_bad_habit_completion_color',
            habitCardBadHabitCompletionColor,
            (color) async {
              final notifier = ref.read(
                habitCardBadHabitCompletionColorNotifierProvider,
              );
              await notifier.setHabitCardBadHabitCompletionColor(color);
            },
            habitCardBadHabitCompletionColorNotifierProvider,
            habitCardBadHabitCompletionColorProvider,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.thumb_down),
          title: Text('calendar_timeline_bad_habit_completion_color'.tr()),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(calendarTimelineBadHabitCompletionColor),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
          ),
          onTap: () => showCompletionColorDialog(
            context,
            ref,
            'calendar_timeline_bad_habit_completion_color',
            calendarTimelineBadHabitCompletionColor,
            (color) async {
              final notifier = ref.read(
                calendarTimelineBadHabitCompletionColorNotifierProvider,
              );
              await notifier.setCalendarTimelineBadHabitCompletionColor(color);
            },
            calendarTimelineBadHabitCompletionColorNotifierProvider,
            calendarTimelineBadHabitCompletionColorProvider,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.thumb_down),
          title: Text('main_timeline_bad_habit_completion_color'.tr()),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(mainTimelineBadHabitCompletionColor),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
          ),
          onTap: () => showCompletionColorDialog(
            context,
            ref,
            'main_timeline_bad_habit_completion_color',
            mainTimelineBadHabitCompletionColor,
            (color) async {
              final notifier = ref.read(
                mainTimelineBadHabitCompletionColorNotifierProvider,
              );
              await notifier.setMainTimelineBadHabitCompletionColor(color);
            },
            mainTimelineBadHabitCompletionColorNotifierProvider,
            mainTimelineBadHabitCompletionColorProvider,
          ),
        ),
        const Divider(),

        // 5. Streak Colors (specialized color scheme)
        SettingsSubsectionHeader(
          title: 'settings_section_appearance_streak_colors'.tr(),
          icon: Icons.local_fire_department,
        ),
        ListTile(
          leading: const Icon(Icons.color_lens),
          title: Text('streak_color_scheme'.tr()),
          subtitle: Text(
            SettingsFormatters.getStreakColorSchemeName(streakColorScheme),
          ),
          onTap: () => showStreakColorSchemeDialog(context, ref),
        ),
      ],
    );
  }
}
