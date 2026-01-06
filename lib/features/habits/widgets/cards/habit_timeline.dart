import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/tracking_providers.dart';
import '../../providers/habit_providers.dart';
import '../../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../../core/database/models/tracking_types.dart';
import '../../../timeline/widgets/day_square.dart';
import '../../../../../core/widgets/skeleton_loader.dart';
import '../../../settings/providers/settings_framework_providers.dart';
import '../../../settings/settings_definitions.dart';

class HabitTimeline extends ConsumerStatefulWidget {
  final int habitId;
  final bool compact;
  final int? daysToShow;
  final bool disableScroll;
  final String? gridBoxSize; // 'small', 'medium', 'large' for grid view
  final String? gridFitMode; // 'fit' or 'fixed' for grid view

  const HabitTimeline({
    super.key,
    required this.habitId,
    this.compact = false,
    this.daysToShow,
    this.disableScroll = false,
    this.gridBoxSize,
    this.gridFitMode,
  });

  @override
  ConsumerState<HabitTimeline> createState() => _HabitTimelineState();
}

class _HabitTimelineState extends ConsumerState<HabitTimeline> {
  final ScrollController _scrollController = ScrollController();
  bool _hasAutoScrolledVertical = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Map<DateTime, int> _calculateStreaks(
    List<DateTime> days,
    Map<DateTime, bool> entriesMap,
    bool isGoodHabit,
    DateTime habitCreatedAt,
  ) {
    final streakMap = <DateTime, int>{};
    int currentStreak = 0;
    final habitCreatedAtOnly = app_date_utils.DateUtils.getDateOnly(habitCreatedAt);
    
    // Calculate streaks going forward from oldest to newest
    // For good habits: completed == true means success
    // For bad habits: completed == false means success (not doing bad habit)
    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final dayOnly = app_date_utils.DateUtils.getDateOnly(day);
      
      // Skip days before habit creation
      if (!app_date_utils.DateUtils.isDateAfterHabitCreation(dayOnly, habitCreatedAtOnly)) {
        streakMap[day] = 0;
        continue;
      }
      
      final entryCompleted = entriesMap[day] ?? false;
      final isSuccess = isGoodHabit ? entryCompleted : !entryCompleted;
      
      if (isSuccess) {
        currentStreak++;
        streakMap[day] = currentStreak;
      } else {
        currentStreak = 0;
        streakMap[day] = 0;
      }
    }
    
    return streakMap;
  }

  bool _isInCurrentWeek(DateTime date) {
    final today = app_date_utils.DateUtils.getToday();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final dateOnly = app_date_utils.DateUtils.getDateOnly(date);
    return dateOnly.isAfter(weekStart.subtract(const Duration(days: 1))) &&
           dateOnly.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  bool _isInCurrentMonth(DateTime date) {
    final today = app_date_utils.DateUtils.getToday();
    return date.year == today.year && date.month == today.month;
  }

  double? _getSquareSize() {
    // If grid box size is specified, use it
    if (widget.gridBoxSize != null) {
      switch (widget.gridBoxSize) {
        case 'small':
          return 10.0;
        case 'medium':
          return 12.0;
        case 'large':
          return 14.0;
        default:
          return 12.0;
      }
    }
    // Otherwise use compact mode logic
    return widget.compact ? 12 : null;
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(trackingEntriesProvider(widget.habitId));
    final habitAsync = ref.watch(habitByIdProvider(widget.habitId));
    final calculatedDaysToShow =
        widget.daysToShow ?? (widget.compact ? 30 : 100);

    return habitAsync.when(
      data: (habit) {
        if (habit == null) {
          return const SizedBox.shrink();
        }

        final isGoodHabit = habit.habitType == HabitType.good.value;

        return entriesAsync.when(
          data: (entries) {
            final entriesMap = {
              for (var entry in entries)
                app_date_utils.DateUtils.getDateOnly(entry.date): entry.completed
            };

            final settings = ref.watch(adatiSettingsProvider);
            final timelineSpacing = ref.watch(settings.provider(timelineSpacingSettingDef));
            final showWeekMonthHighlights =
                ref.watch(settings.provider(showWeekMonthHighlightsSettingDef));
            final spacing = widget.compact ? 4.0 : timelineSpacing;

            // For grid view, use fit mode to determine fillLines
            final fillLines = widget.gridFitMode == 'fit'
                ? true
                : widget.gridFitMode == 'fixed'
                    ? false
                    : ref.watch(settings.provider(habitCardTimelineFillLinesSettingDef));
            // For grid fill mode, calculate lines dynamically based on available height
            final lineCount = widget.gridFitMode == 'fit'
                ? null
                : ref.watch(settings.provider(habitCardTimelineLinesSettingDef));

            Widget buildTimelineForDays(List<DateTime> days) {
              final needsScroll = days.length > 100;
              // Calculate streaks based on habit type
              final streakMap =
                  _calculateStreaks(days, entriesMap, isGoodHabit, habit.createdAt);

              final badHabitLogicMode = ref.watch(settings.provider(badHabitLogicModeSettingDef));
              final habitCreatedAtOnly = app_date_utils.DateUtils.getDateOnly(habit.createdAt);
              final timelineWidget = Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: days.map((day) {
                  final dayOnly = app_date_utils.DateUtils.getDateOnly(day);
                  final isBeforeCreation = !app_date_utils.DateUtils.isDateAfterHabitCreation(dayOnly, habitCreatedAtOnly);
                  
                  final entryCompleted = entriesMap[day] ?? false;
                  // For display: respect bad habit logic mode setting
                  final displayCompleted = isGoodHabit
                      ? entryCompleted
                      : (badHabitLogicMode == 'negative'
                          ? !entryCompleted // Negative mode: mark = incomplete
                          : !entryCompleted); // Positive mode: not mark = complete (same logic)
                  final streakLength = streakMap[day] ?? 0;
                  final isCurrentWeek =
                      showWeekMonthHighlights && _isInCurrentWeek(day);
                  final isCurrentMonth =
                      showWeekMonthHighlights && _isInCurrentMonth(day);

                  final completionColor = isGoodHabit
                      ? ref.watch(settings.provider(calendarTimelineCompletionColorSettingDef))
                      : ref.watch(settings.provider(calendarTimelineBadHabitCompletionColorSettingDef));

                  // Smoothly animate completion / streak changes for each day.
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      );
                      return FadeTransition(
                        opacity: curved,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.9,
                            end: 1.0,
                          ).animate(curved),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(
                        '${day.toIso8601String()}_${displayCompleted}_$streakLength',
                      ),
                      child: Opacity(
                        opacity: isBeforeCreation ? 0.3 : 1.0,
                        child: DaySquare(
                          date: day,
                          completed: displayCompleted,
                          size: _getSquareSize(),
                          onTap: null,
                          streakLength: streakLength,
                          highlightWeek: isCurrentWeek,
                          highlightMonth: isCurrentMonth,
                          completionColor: completionColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );

              // If scrolling is disabled, return widget directly
              if (widget.disableScroll) {
                return timelineWidget;
              }

              if (needsScroll) {
                // Horizontal scroll without auto-jumping: default is start/oldest.
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: timelineWidget,
                );
              }

              // Vertical mode: auto-scroll to end (latest days) once after layout.
              if (!_hasAutoScrolledVertical) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || !_scrollController.hasClients) return;
                  final max = _scrollController.position.maxScrollExtent;
                  if (max > 0) {
                    _scrollController.jumpTo(max);
                  }
                  _hasAutoScrolledVertical = true;
                });
              }

              return SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.vertical,
                child: timelineWidget,
              );
            }

            if (fillLines) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final maxHeight = constraints.maxHeight;

                  // Approximate square size based on the same logic as DaySquare.
                  double squareSize;
                  if (widget.gridBoxSize != null) {
                    // Use grid-specific box size
                    switch (widget.gridBoxSize) {
                      case 'small':
                        squareSize = 10.0;
                        break;
                      case 'medium':
                        squareSize = 12.0;
                        break;
                      case 'large':
                        squareSize = 14.0;
                        break;
                      default:
                        squareSize = 12.0;
                    }
                  } else if (widget.compact) {
                    squareSize = 12.0;
                  } else {
                    final sizePreference = ref.watch(settings.provider(daySquareSizeSettingDef));
                    switch (sizePreference) {
                      case 'small':
                        squareSize = 12.0;
                        break;
                      case 'large':
                        squareSize = 20.0;
                        break;
                      case 'medium':
                      default:
                        squareSize = 16.0;
                        break;
                    }
                  }

                  // Use math to find the maximum number of squares that fit per line
                  // given squareSize and spacing, so we fill each line as much as possible
                  // without wrapping into an extra line.
                  int perLine;
                  if (!maxWidth.isFinite || maxWidth <= 0 || squareSize <= 0) {
                    // Fallback: conservative number of squares per line
                    perLine = widget.compact ? 18 : 12;
                  } else {
                    perLine = 1;
                    while (perLine < 1000) {
                      final widthNeeded =
                          perLine * squareSize + (perLine - 1) * spacing;
                      if (widthNeeded > maxWidth) {
                        perLine = perLine - 1;
                        break;
                      }
                      perLine++;
                    }
                    if (perLine < 1) {
                      perLine = 1;
                    }
                  }

                  // For grid fill mode, calculate lines dynamically based on available height
                  // For regular fill mode, use the setting
                  int calculatedLineCount;
                  if (lineCount == null && widget.gridFitMode == 'fit') {
                    // Dynamic calculation for grid fill mode
                    if (maxHeight.isFinite && maxHeight > 0 && squareSize > 0) {
                      // Calculate how many lines fit in the available height
                      calculatedLineCount = ((maxHeight + spacing) / (squareSize + spacing)).floor();
                      if (calculatedLineCount < 1) {
                        calculatedLineCount = 1;
                      }
                      // Cap at reasonable maximum
                      calculatedLineCount = calculatedLineCount.clamp(1, 10);
                    } else {
                      calculatedLineCount = 2; // Fallback
                    }
                  } else {
                    calculatedLineCount = lineCount ?? 2;
                  }

                  final totalDays =
                      (perLine * calculatedLineCount).clamp(1, 365);
                  final days = app_date_utils.DateUtils
                      .getLastNDays(totalDays);
                  return buildTimelineForDays(days);
                },
              );
            }

            final days = app_date_utils.DateUtils
                .getLastNDays(calculatedDaysToShow);
            return buildTimelineForDays(days);
          },
          loading: () => const SizedBox(
            height: 50,
            child: SkeletonTimeline(),
          ),
          error: (error, stack) => Text('${'error'.tr()}: $error'),
        );
      },
      loading: () => const SizedBox(
        height: 50,
        child: SkeletonTimeline(),
      ),
      error: (error, stack) => Text('${'error'.tr()}: $error'),
    );
  }
}

