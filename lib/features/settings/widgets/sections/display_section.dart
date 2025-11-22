import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_providers.dart';
import '../../utils/settings_formatters.dart';
import '../settings_section.dart';
import '../responsive_dialog.dart';

/// Display settings section (habits, timelines, habit cards, statistics)
class DisplaySectionContent extends ConsumerStatefulWidget {
  final Function(BuildContext, WidgetRef) showTimelineDaysDialog;
  final Function(BuildContext, WidgetRef) showModalTimelineDaysDialog;
  final Function(BuildContext, WidgetRef) showHabitCardTimelineDaysDialog;
  final Function(BuildContext, WidgetRef) showTimelineSpacingDialog;
  final Function(BuildContext, WidgetRef) showDaySquareSizeDialog;
  final Function(BuildContext, WidgetRef) revertTimelineDays;
  final Function(BuildContext, WidgetRef) revertModalTimelineDays;
  final Function(BuildContext, WidgetRef) revertHabitCardTimelineDays;
  final Function(BuildContext, WidgetRef) revertDaySquareSize;

  const DisplaySectionContent({
    super.key,
    required this.showTimelineDaysDialog,
    required this.showModalTimelineDaysDialog,
    required this.showHabitCardTimelineDaysDialog,
    required this.showTimelineSpacingDialog,
    required this.showDaySquareSizeDialog,
    required this.revertTimelineDays,
    required this.revertModalTimelineDays,
    required this.revertHabitCardTimelineDays,
    required this.revertDaySquareSize,
  });

  @override
  ConsumerState<DisplaySectionContent> createState() =>
      _DisplaySectionContentState();
}

class _DisplaySectionContentState extends ConsumerState<DisplaySectionContent> {
  static const int defaultTimelineDays = 60;
  static const int defaultModalTimelineDays = 30;
  static const int defaultHabitCardTimelineDays = 10;
  static const String defaultDaySquareSize = 'large';

  @override
  Widget build(BuildContext context) {
    final timelineDays = ref.watch(timelineDaysProvider);
    final modalTimelineDays = ref.watch(modalTimelineDaysProvider);
    final habitCardTimelineDays = ref.watch(habitCardTimelineDaysProvider);
    final timelineSpacing = ref.watch(timelineSpacingProvider);
    final timelineCompactMode = ref.watch(timelineCompactModeProvider);
    final showStreakBorders = ref.watch(showStreakBordersProvider);
    final showWeekMonthHighlights = ref.watch(showWeekMonthHighlightsProvider);
    final showStreakNumbers = ref.watch(showStreakNumbersProvider);
    final showDescriptions = ref.watch(showDescriptionsProvider);
    final compactCards = ref.watch(compactCardsProvider);
    final showPercentage = ref.watch(showPercentageProvider);
    final showStatisticsCard = ref.watch(showStatisticsCardProvider);
    final showMainTimeline = ref.watch(showMainTimelineProvider);
    final habitsLayoutMode = ref.watch(habitsLayoutModeProvider);
    final gridShowIcon = ref.watch(gridShowIconProvider);
    final gridShowCompletion = ref.watch(gridShowCompletionProvider);
    final gridShowTimeline = ref.watch(gridShowTimelineProvider);
    final gridTimelineBoxSize = ref.watch(gridTimelineBoxSizeProvider);
    final gridTimelineFitMode = ref.watch(gridTimelineFitModeProvider);
    final mainTimelineFillLines = ref.watch(mainTimelineFillLinesProvider);
    final mainTimelineLines = ref.watch(mainTimelineLinesProvider);
    final habitCardLayoutMode = ref.watch(habitCardLayoutModeProvider);
    final habitCardTimelineFillLines = ref.watch(
      habitCardTimelineFillLinesProvider,
    );
    final habitCardTimelineLines = ref.watch(habitCardTimelineLinesProvider);
    final showStreakOnCard = ref.watch(showStreakOnCardProvider);
    final daySquareSize = ref.watch(daySquareSizeProvider);
    final useStreakColorsForSquares = ref.watch(
      useStreakColorsForSquaresProvider,
    );

    return Column(
      children: [
        // 1. Habits List/Grid Layout (grouped together)
        SettingsSubsectionHeader(
          title: 'settings_section_display_habits'.tr(),
          icon: Icons.view_agenda,
        ),
        ListTile(
          leading: const Icon(Icons.view_agenda),
          title: Text('habits_layout_mode'.tr()),
          subtitle: Text(
            habitsLayoutMode == 'grid'
                ? 'habits_layout_grid'.tr()
                : 'habits_layout_list'.tr(),
          ),
          onTap: () => _showHabitsLayoutModeDialog(habitsLayoutMode),
        ),
        // Grid options (only relevant when grid is selected)
        SwitchListTile(
          secondary: const Icon(Icons.image),
          title: Text('grid_show_icon'.tr()),
          value: gridShowIcon,
          onChanged: (value) async {
            final notifier = ref.read(gridShowIconNotifierProvider);
            await notifier.setGridShowIcon(value);
            ref.invalidate(gridShowIconNotifierProvider);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.check_circle),
          title: Text('grid_show_completion'.tr()),
          value: gridShowCompletion,
          onChanged: (value) async {
            final notifier = ref.read(gridShowCompletionNotifierProvider);
            await notifier.setGridShowCompletion(value);
            ref.invalidate(gridShowCompletionNotifierProvider);
          },
        ),
        if (gridShowCompletion)
          ListTile(
            leading: const Icon(Icons.place),
            title: Text('grid_completion_button_placement'.tr()),
            subtitle: Text(
              ref.watch(gridCompletionButtonPlacementProvider) == 'overlay'
                  ? 'grid_completion_button_placement_overlay'.tr()
                  : 'grid_completion_button_placement_center'.tr(),
            ),
            onTap: () => _showGridCompletionButtonPlacementDialog(
              ref.watch(gridCompletionButtonPlacementProvider),
            ),
          ),
        SwitchListTile(
          secondary: const Icon(Icons.timeline),
          title: Text('grid_show_timeline'.tr()),
          value: gridShowTimeline,
          onChanged: (value) async {
            final notifier = ref.read(gridShowTimelineNotifierProvider);
            await notifier.setGridShowTimeline(value);
            ref.invalidate(gridShowTimelineNotifierProvider);
          },
        ),
        if (gridShowTimeline) ...[
          SwitchListTile(
            secondary: const Icon(Icons.grid_4x4),
            title: Text('grid_timeline_fill_lines'.tr()),
            subtitle: Text('grid_timeline_fill_lines_description'.tr()),
            value: gridTimelineFitMode == 'fit',
            onChanged: (value) async {
              final notifier = ref.read(gridTimelineFitModeNotifierProvider);
              await notifier.setGridTimelineFitMode(value ? 'fit' : 'fixed');
              ref.invalidate(gridTimelineFitModeNotifierProvider);
              ref.invalidate(gridTimelineFitModeProvider);
            },
          ),
          // Only show days setting when fill mode is disabled
          if (gridTimelineFitMode == 'fixed') ...[
            ListTile(
              leading: const Icon(Icons.view_week),
              title: Text('habit_card_timeline_days'.tr()),
              subtitle: Text('$habitCardTimelineDays ${'days'.tr()}'),
              onTap: () => widget.showHabitCardTimelineDaysDialog(context, ref),
            ),
          ],
          // Box size is always available
          ListTile(
            leading: const Icon(Icons.aspect_ratio),
            title: Text('grid_timeline_box_size'.tr()),
            subtitle: Text(
              gridTimelineBoxSize == 'small'
                  ? 'day_square_size_small'.tr()
                  : gridTimelineBoxSize == 'medium'
                  ? 'day_square_size_medium'.tr()
                  : 'day_square_size_large'.tr(),
            ),
            onTap: () => _showGridTimelineBoxSizeDialog(gridTimelineBoxSize),
          ),
        ],
        const Divider(),

        // 2. Main Timeline (prominent feature - all settings together)
        SettingsSubsectionHeader(
          title: 'settings_section_display_main_timeline'.tr(),
          icon: Icons.calendar_view_week,
        ),
        // Show toggle first
        SwitchListTile(
          secondary: const Icon(Icons.calendar_view_month),
          title: Text('show_main_timeline'.tr()),
          subtitle: Text('show_main_timeline_description'.tr()),
          value: showMainTimeline,
          onChanged: (value) async {
            final notifier = ref.read(showMainTimelineNotifierProvider);
            await notifier.setShowMainTimeline(value);
            ref.invalidate(showMainTimelineNotifierProvider);
          },
        ),
        // Size settings
        ListTile(
          leading: const Icon(Icons.square),
          title: Text('day_square_size'.tr()),
          subtitle: Text(
            SettingsFormatters.getDaySquareSizeName(daySquareSize),
          ),
          trailing: daySquareSize != defaultDaySquareSize
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'reset_to_default'.tr(),
                  onPressed: () => widget.revertDaySquareSize(context, ref),
                )
              : null,
          onTap: () => widget.showDaySquareSizeDialog(context, ref),
        ),
        // Days configuration (when not in fill-lines mode)
        ListTile(
          leading: const Icon(Icons.calendar_view_week),
          title: Text('timeline_days'.tr()),
          subtitle: Text('$timelineDays ${'days'.tr()}'),
          enabled: !mainTimelineFillLines,
          trailing:
              !mainTimelineFillLines && timelineDays != defaultTimelineDays
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'reset_to_default'.tr(),
                  onPressed: () => widget.revertTimelineDays(context, ref),
                )
              : null,
          onTap: () => widget.showTimelineDaysDialog(context, ref),
        ),
        // Fill Lines Mode (toggle)
        SwitchListTile(
          secondary: const Icon(Icons.grid_4x4),
          title: Text('main_timeline_fill_lines'.tr()),
          subtitle: Text('main_timeline_fill_lines_description'.tr()),
          value: mainTimelineFillLines,
          onChanged: (value) async {
            final notifier = ref.read(mainTimelineFillLinesNotifierProvider);
            await notifier.setMainTimelineFillLines(value);
            ref.invalidate(mainTimelineFillLinesNotifierProvider);
          },
        ),
        // Lines count (when fill-lines enabled)
        ListTile(
          leading: const Icon(Icons.format_line_spacing),
          title: Text('main_timeline_lines'.tr()),
          subtitle: Text('$mainTimelineLines'),
          enabled: mainTimelineFillLines,
          onTap: () => _showMainTimelineLinesDialog(
            mainTimelineFillLines,
            mainTimelineLines,
          ),
        ),
        // Spacing
        ListTile(
          leading: const Icon(Icons.space_bar),
          title: Text('timeline_spacing'.tr()),
          subtitle: Text('${timelineSpacing.toStringAsFixed(1)}px'),
          onTap: () => widget.showTimelineSpacingDialog(context, ref),
        ),
        // Compact Mode
        SwitchListTile(
          secondary: const Icon(Icons.compress),
          title: Text('timeline_compact_mode'.tr()),
          subtitle: Text('timeline_compact_mode_description'.tr()),
          value: timelineCompactMode,
          onChanged: (value) async {
            final notifier = ref.read(timelineCompactModeNotifierProvider);
            await notifier.setTimelineCompactMode(value);
            ref.invalidate(timelineCompactModeNotifierProvider);
          },
        ),
        // Streak Colors
        SwitchListTile(
          secondary: const Icon(Icons.palette),
          title: Text('use_streak_colors_for_squares'.tr()),
          subtitle: Text('use_streak_colors_for_squares_description'.tr()),
          value: useStreakColorsForSquares,
          onChanged: (value) async {
            final notifier = ref.read(
              useStreakColorsForSquaresNotifierProvider,
            );
            await notifier.setUseStreakColorsForSquares(value);
            ref.invalidate(useStreakColorsForSquaresNotifierProvider);
            ref.invalidate(useStreakColorsForSquaresProvider);
          },
        ),
        // Visual enhancements
        SwitchListTile(
          secondary: const Icon(Icons.border_color),
          title: Text('show_streak_borders'.tr()),
          subtitle: Text('show_streak_borders_description'.tr()),
          value: showStreakBorders,
          onChanged: (value) async {
            final notifier = ref.read(showStreakBordersNotifierProvider);
            await notifier.setShowStreakBorders(value);
            ref.invalidate(showStreakBordersNotifierProvider);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.highlight),
          title: Text('show_week_month_highlights'.tr()),
          subtitle: Text('show_week_month_highlights_description'.tr()),
          value: showWeekMonthHighlights,
          onChanged: (value) async {
            final notifier = ref.read(showWeekMonthHighlightsNotifierProvider);
            await notifier.setShowWeekMonthHighlights(value);
            ref.invalidate(showWeekMonthHighlightsNotifierProvider);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.numbers),
          title: Text('show_streak_numbers'.tr()),
          subtitle: Text('show_streak_numbers_description'.tr()),
          value: showStreakNumbers,
          onChanged: (value) async {
            final notifier = ref.read(showStreakNumbersNotifierProvider);
            await notifier.setShowStreakNumbers(value);
            ref.invalidate(showStreakNumbersNotifierProvider);
          },
        ),
        const Divider(),

        // 3. Habit Cards (individual habit display)
        SettingsSubsectionHeader(
          title: 'settings_section_display_habit_cards'.tr(),
          icon: Icons.view_module,
        ),
        // Layout
        ListTile(
          leading: const Icon(Icons.view_agenda),
          title: Text('habit_card_layout_mode'.tr()),
          subtitle: Text(
            habitCardLayoutMode == 'topRow'
                ? 'habit_card_layout_mode_top_row'.tr()
                : 'habit_card_layout_mode_classic'.tr(),
          ),
          onTap: () => _showHabitCardLayoutModeDialog(habitCardLayoutMode),
        ),
        // Content visibility toggles
        SwitchListTile(
          secondary: const Icon(Icons.description),
          title: Text('show_descriptions'.tr()),
          subtitle: Text('show_descriptions_description'.tr()),
          value: showDescriptions,
          onChanged: (value) async {
            final notifier = ref.read(showDescriptionsNotifierProvider);
            await notifier.setShowDescriptions(value);
            ref.invalidate(showDescriptionsNotifierProvider);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.view_compact),
          title: Text('compact_cards'.tr()),
          subtitle: Text('compact_cards_description'.tr()),
          value: compactCards,
          onChanged: (value) async {
            final notifier = ref.read(compactCardsNotifierProvider);
            await notifier.setCompactCards(value);
            ref.invalidate(compactCardsNotifierProvider);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.percent),
          title: Text('show_percentage'.tr()),
          subtitle: Text('show_percentage_description'.tr()),
          value: showPercentage,
          onChanged: (value) async {
            final notifier = ref.read(showPercentageNotifierProvider);
            await notifier.setShowPercentage(value);
            ref.invalidate(showPercentageNotifierProvider);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.local_fire_department),
          title: Text('show_streak_on_card'.tr()),
          subtitle: Text('show_streak_on_card_description'.tr()),
          value: showStreakOnCard,
          onChanged: (value) async {
            final notifier = ref.read(showStreakOnCardNotifierProvider);
            await notifier.setShowStreakOnCard(value);
            ref.invalidate(showStreakOnCardNotifierProvider);
          },
        ),
        // Timeline settings
        SwitchListTile(
          secondary: const Icon(Icons.grid_on),
          title: Text('habit_card_timeline_fill_lines'.tr()),
          subtitle: Text('habit_card_timeline_fill_lines_description'.tr()),
          value: habitCardTimelineFillLines,
          onChanged:
              (habitsLayoutMode == 'grid' && gridTimelineFitMode == 'fit')
              ? null
              : (value) async {
                  final notifier = ref.read(
                    habitCardTimelineFillLinesNotifierProvider,
                  );
                  await notifier.setHabitCardTimelineFillLines(value);
                  ref.invalidate(habitCardTimelineFillLinesNotifierProvider);
                },
        ),
        ListTile(
          leading: const Icon(Icons.format_line_spacing),
          title: Text('habit_card_timeline_lines'.tr()),
          subtitle: Text('$habitCardTimelineLines'),
          enabled:
              habitCardTimelineFillLines &&
              !(habitsLayoutMode == 'grid' && gridTimelineFitMode == 'fit'),
          onTap: () => _showHabitCardTimelineLinesDialog(
            habitCardTimelineFillLines,
            habitCardTimelineLines,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.view_week),
          title: Text('habit_card_timeline_days'.tr()),
          subtitle: Text('$habitCardTimelineDays ${'days'.tr()}'),
          enabled: !habitCardTimelineFillLines,
          trailing:
              !habitCardTimelineFillLines &&
                  habitCardTimelineDays != defaultHabitCardTimelineDays
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'reset_to_default'.tr(),
                  onPressed: () =>
                      widget.revertHabitCardTimelineDays(context, ref),
                )
              : null,
          onTap: () => widget.showHabitCardTimelineDaysDialog(context, ref),
        ),
        const Divider(),

        // 4. Modal/Detail Timelines (timelines in dialogs and detail pages)
        SettingsSubsectionHeader(
          title: 'settings_section_display_timelines'.tr(),
          icon: Icons.view_timeline,
        ),
        ListTile(
          leading: const Icon(Icons.view_timeline),
          title: Text('modal_timeline_days'.tr()),
          subtitle: Text('$modalTimelineDays ${'days'.tr()}'),
          enabled: !habitCardTimelineFillLines,
          trailing:
              !habitCardTimelineFillLines &&
                  modalTimelineDays != defaultModalTimelineDays
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'reset_to_default'.tr(),
                  onPressed: () => widget.revertModalTimelineDays(context, ref),
                )
              : null,
          onTap: () => widget.showModalTimelineDaysDialog(context, ref),
        ),
        const Divider(),

        // 5. Statistics (supporting information)
        SettingsSubsectionHeader(
          title: 'settings_section_display_statistics'.tr(),
          icon: Icons.bar_chart,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.bar_chart),
          title: Text('show_statistics_card'.tr()),
          subtitle: Text('show_statistics_card_description'.tr()),
          value: showStatisticsCard,
          onChanged: (value) async {
            final notifier = ref.read(showStatisticsCardNotifierProvider);
            await notifier.setShowStatisticsCard(value);
            ref.invalidate(showStatisticsCardNotifierProvider);
          },
        ),
      ],
    );
  }

  Future<void> _showHabitsLayoutModeDialog(String currentMode) async {
    final mode = await showDialog<String>(
      context: context,
      builder: (context) {
        String temp = currentMode;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return ResponsiveDialog.responsiveAlertDialog(
              context: context,
              title: Text('habits_layout_mode'.tr()),
              content: RadioGroup<String>(
                groupValue: temp,
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      temp = value;
                    });
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      title: Text('habits_layout_list'.tr()),
                      value: 'list',
                    ),
                    RadioListTile<String>(
                      title: Text('habits_layout_grid'.tr()),
                      value: 'grid',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr()),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, temp),
                  child: Text('ok'.tr()),
                ),
              ],
            );
          },
        );
      },
    );

    if (mode != null && mode.isNotEmpty) {
      final notifier = ref.read(habitsLayoutModeNotifierProvider);
      await notifier.setHabitsLayoutMode(mode);
      // Invalidate both the notifier and value providers to ensure UI updates
      ref.invalidate(habitsLayoutModeNotifierProvider);
      ref.invalidate(habitsLayoutModeProvider);
    }
  }

  Future<void> _showHabitCardLayoutModeDialog(String currentMode) async {
    final mode = await showDialog<String>(
      context: context,
      builder: (context) {
        String temp = currentMode;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return ResponsiveDialog.responsiveAlertDialog(
              context: context,
              title: Text('habit_card_layout_mode'.tr()),
              content: RadioGroup<String>(
                groupValue: temp,
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      temp = value;
                    });
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      title: Text('habit_card_layout_mode_classic'.tr()),
                      value: 'classic',
                    ),
                    RadioListTile<String>(
                      title: Text('habit_card_layout_mode_top_row'.tr()),
                      value: 'topRow',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr()),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, temp),
                  child: Text('ok'.tr()),
                ),
              ],
            );
          },
        );
      },
    );

    if (mode != null && mode.isNotEmpty) {
      final notifier = ref.read(habitCardLayoutModeNotifierProvider);
      await notifier.setHabitCardLayoutMode(mode);
      // Invalidate both the notifier and value providers to ensure UI updates
      ref.invalidate(habitCardLayoutModeNotifierProvider);
      ref.invalidate(habitCardLayoutModeProvider);
    }
  }

  Future<void> _showGridCompletionButtonPlacementDialog(
    String currentPlacement,
  ) async {
    final placement = await showDialog<String>(
      context: context,
      builder: (context) {
        String temp = currentPlacement;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return ResponsiveDialog.responsiveAlertDialog(
              context: context,
              title: Text('grid_completion_button_placement'.tr()),
              content: RadioGroup<String>(
                groupValue: temp,
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      temp = value;
                    });
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      title: Text(
                        'grid_completion_button_placement_center'.tr(),
                      ),
                      value: 'center',
                    ),
                    RadioListTile<String>(
                      title: Text(
                        'grid_completion_button_placement_overlay'.tr(),
                      ),
                      value: 'overlay',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr()),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, temp),
                  child: Text('ok'.tr()),
                ),
              ],
            );
          },
        );
      },
    );

    if (placement != null && placement.isNotEmpty) {
      final notifier = ref.read(gridCompletionButtonPlacementNotifierProvider);
      await notifier.setGridCompletionButtonPlacement(placement);
      // Invalidate both the notifier and value providers to ensure UI updates
      ref.invalidate(gridCompletionButtonPlacementNotifierProvider);
      ref.invalidate(gridCompletionButtonPlacementProvider);
    }
  }

  Future<void> _showGridTimelineBoxSizeDialog(String currentSize) async {
    final size = await showDialog<String>(
      context: context,
      builder: (context) {
        String temp = currentSize;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return ResponsiveDialog.responsiveAlertDialog(
              context: context,
              title: Text('grid_timeline_box_size'.tr()),
              content: RadioGroup<String>(
                groupValue: temp,
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      temp = value;
                    });
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      title: Text('day_square_size_small'.tr()),
                      value: 'small',
                    ),
                    RadioListTile<String>(
                      title: Text('day_square_size_medium'.tr()),
                      value: 'medium',
                    ),
                    RadioListTile<String>(
                      title: Text('day_square_size_large'.tr()),
                      value: 'large',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr()),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, temp),
                  child: Text('ok'.tr()),
                ),
              ],
            );
          },
        );
      },
    );

    if (size != null && size.isNotEmpty) {
      final notifier = ref.read(gridTimelineBoxSizeNotifierProvider);
      await notifier.setGridTimelineBoxSize(size);
      ref.invalidate(gridTimelineBoxSizeNotifierProvider);
      ref.invalidate(gridTimelineBoxSizeProvider);
    }
  }

  Future<void> _showHabitCardTimelineLinesDialog(
    bool fillLinesEnabled,
    int current,
  ) async {
    if (!fillLinesEnabled) return;

    int temp = current.clamp(1, 5);
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('habit_card_timeline_lines'.tr()),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    min: 1,
                    max: 5,
                    divisions: 4,
                    value: temp.toDouble(),
                    label: '$temp',
                    onChanged: (value) {
                      setDialogState(() {
                        temp = value.round();
                      });
                    },
                  ),
                  Text('habit_card_timeline_lines_value'.tr(args: ['$temp'])),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, temp),
              child: Text('ok'.tr()),
            ),
          ],
        );
      },
    );

    if (result != null && result != current) {
      final notifier = ref.read(habitCardTimelineLinesNotifierProvider);
      await notifier.setHabitCardTimelineLines(result);
      // Invalidate both the notifier and value providers to ensure UI updates
      ref.invalidate(habitCardTimelineLinesNotifierProvider);
      ref.invalidate(habitCardTimelineLinesProvider);
    }
  }

  Future<void> _showMainTimelineLinesDialog(
    bool fillLinesEnabled,
    int current,
  ) async {
    if (!fillLinesEnabled) return;

    int temp = current.clamp(1, 6);
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return ResponsiveDialog.responsiveAlertDialog(
          context: context,
          title: Text('main_timeline_lines'.tr()),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    min: 1,
                    max: 6,
                    divisions: 5,
                    value: temp.toDouble(),
                    label: '$temp',
                    onChanged: (value) {
                      setDialogState(() {
                        temp = value.round();
                      });
                    },
                  ),
                  Text('main_timeline_lines_value'.tr(args: ['$temp'])),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, temp),
              child: Text('ok'.tr()),
            ),
          ],
        );
      },
    );

    if (result != null && result != current) {
      final notifier = ref.read(mainTimelineLinesNotifierProvider);
      await notifier.setMainTimelineLines(result);
      // Invalidate both the notifier and value providers to ensure UI updates
      ref.invalidate(mainTimelineLinesNotifierProvider);
      ref.invalidate(mainTimelineLinesProvider);
    }
  }
}
