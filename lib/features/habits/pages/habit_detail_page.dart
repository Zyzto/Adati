import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/tracking_providers.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/models/tracking_types.dart';
import '../providers/habit_providers.dart';
import '../widgets/cards/habit_timeline.dart';
import '../widgets/cards/habit_management_menu.dart';
import '../widgets/forms/note_editor.dart';
import '../widgets/forms/goal_setting.dart';
import '../../settings/providers/settings_providers.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/utils/icon_utils.dart';

class HabitDetailPage extends ConsumerStatefulWidget {
  final int habitId;

  const HabitDetailPage({super.key, required this.habitId});

  @override
  ConsumerState<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends ConsumerState<HabitDetailPage> {
  DateTime _selectedMonth = DateTime.now();
  // Optimistic updates: track pending changes for immediate UI feedback
  final Map<DateTime, bool> _optimisticUpdates = {};

  void _showManagementMenu(
    BuildContext context,
    WidgetRef ref,
    db.Habit habit,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => HabitManagementMenu(habit: habit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(trackingEntriesProvider(widget.habitId));
    final habitAsync = ref.watch(habitByIdProvider(widget.habitId));
    final modalTimelineDays = ref.watch(modalTimelineDaysProvider);
    final streakAsync = ref.watch(streakProvider(widget.habitId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Clear optimistic updates when actual data arrives from database
    ref.listen(trackingEntriesProvider(widget.habitId), (previous, next) {
      if (next.hasValue && _optimisticUpdates.isNotEmpty) {
        // Clear all optimistic updates when we get fresh data from the stream
        // The stream update means the database operation completed
        final hadUpdates = _optimisticUpdates.isNotEmpty;
        _optimisticUpdates.clear();
        if (hadUpdates && mounted) {
          setState(() {});
        }
      }
    });

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // Enhanced handle bar with theme colors
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Enhanced header with better theming
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        tooltip: 'previous_month'.tr(),
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month - 1,
                            );
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          DateFormat(
                            'MMMM yyyy',
                            context.locale.languageCode,
                          ).format(_selectedMonth),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        tooltip: 'next_month'.tr(),
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month + 1,
                            );
                          });
                        },
                      ),
                      habitAsync.when(
                        data: (habit) => habit != null
                            ? IconButton(
                                icon: const Icon(Icons.settings, size: 20),
                                tooltip: 'habit_settings'.tr(),
                                style: IconButton.styleFrom(
                                  foregroundColor: colorScheme.onSurface,
                                ),
                                onPressed: () =>
                                    _showManagementMenu(context, ref, habit),
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                // Enhanced card preview section
                habitAsync.when(
                  data: (habit) {
                    if (habit == null) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon - Title row
                          Row(
                            children: [
                              // Icon with better theming
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Color(habit.color),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(
                                        habit.color,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: habit.icon != null
                                    ? Icon(
                                        createIconDataFromString(habit.icon!),
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              // Title
                              Expanded(
                                child: Text(
                                  habit.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Timeline visualization
                          const SizedBox(height: 16),
                          HabitTimeline(
                            habitId: habit.id,
                            compact: false,
                            daysToShow: modalTimelineDays,
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonCard(),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                // Statistics section
                _buildStatisticsSection(
                  context,
                  ref,
                  entriesAsync,
                  streakAsync,
                ),
                // Enhanced divider
                Divider(
                  height: 24,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colorScheme.outlineVariant,
                ),
                // Calendar with animated month transitions
                entriesAsync.when(
                  data: (entries) {
                    if (entries.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.calendar_today,
                        title: 'no_entries_yet'.tr(),
                        message: 'complete_habit_to_see_calendar'.tr(),
                      );
                    }
                    // Merge actual entries with optimistic updates for immediate feedback
                    final entriesMap = <DateTime, bool>{
                      for (var entry in entries)
                        app_date_utils.DateUtils.getDateOnly(entry.date):
                            entry.completed,
                    };
                    // Apply optimistic updates (they override actual entries)
                    entriesMap.addAll(_optimisticUpdates);

                    final entriesWithNotes = {
                      for (var entry in entries)
                        if (entry.notes != null && entry.notes!.isNotEmpty)
                          app_date_utils.DateUtils.getDateOnly(entry.date):
                              true,
                    };
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.2, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: _buildCalendar(
                        entriesMap,
                        entriesWithNotes,
                        entries,
                      ),
                    );
                  },
                  loading: () => const SkeletonCalendar(),
                  error: (error, stack) =>
                      Center(child: Text('${'error'.tr()}: $error')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<db.TrackingEntry>> entriesAsync,
    AsyncValue<db.Streak?> streakAsync,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return entriesAsync.when(
      data: (entries) {
        return streakAsync.when(
          data: (streak) {
            // Calculate statistics for selected month
            final firstDayOfMonth = DateTime(
              _selectedMonth.year,
              _selectedMonth.month,
              1,
            );
            final lastDayOfMonth = DateTime(
              _selectedMonth.year,
              _selectedMonth.month + 1,
              0,
            );
            final monthDays = app_date_utils.DateUtils.getDaysRange(
              firstDayOfMonth,
              lastDayOfMonth,
            );

            final monthEntries = entries.where((e) {
              final entryDate = app_date_utils.DateUtils.getDateOnly(e.date);
              return entryDate.isAfter(
                    firstDayOfMonth.subtract(const Duration(days: 1)),
                  ) &&
                  entryDate.isBefore(
                    lastDayOfMonth.add(const Duration(days: 1)),
                  );
            }).toList();

            final monthCompleted = monthEntries
                .where((e) => e.completed)
                .length;
            final monthCompletionPercentage = monthDays.isNotEmpty
                ? ((monthCompleted / monthDays.length) * 100).round()
                : 0;

            // Calculate this week
            final today = app_date_utils.DateUtils.getToday();
            final weekStart = today.subtract(Duration(days: today.weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 6));
            final weekDays = app_date_utils.DateUtils.getDaysRange(
              weekStart,
              weekEnd,
            );

            final weekEntries = entries.where((e) {
              final entryDate = app_date_utils.DateUtils.getDateOnly(e.date);
              return entryDate.isAfter(
                    weekStart.subtract(const Duration(days: 1)),
                  ) &&
                  entryDate.isBefore(weekEnd.add(const Duration(days: 1)));
            }).toList();

            final weekCompleted = weekEntries.where((e) => e.completed).length;

            // Get goals
            final weeklyGoal = PreferencesService.getHabitWeeklyGoal(
              widget.habitId,
            );
            final monthlyGoal = PreferencesService.getHabitMonthlyGoal(
              widget.habitId,
            );

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        Icons.local_fire_department,
                        '${streak?.combinedStreak ?? 0}',
                        'current_streak'.tr(),
                        colorScheme.primary,
                      ),
                      _buildStatItem(
                        context,
                        Icons.emoji_events,
                        '${streak?.combinedLongestStreak ?? 0}',
                        'longest_streak'.tr(),
                        colorScheme.secondary,
                      ),
                      _buildStatItem(
                        context,
                        Icons.trending_up,
                        weeklyGoal != null
                            ? '$weekCompleted/$weeklyGoal'
                            : '$monthCompletionPercentage%',
                        weeklyGoal != null
                            ? 'this_week_goal'.tr()
                            : 'this_month'.tr(),
                        colorScheme.tertiary,
                      ),
                      _buildStatItem(
                        context,
                        Icons.calendar_today,
                        monthlyGoal != null
                            ? '$monthCompleted/$monthlyGoal'
                            : '$weekCompleted/${weekDays.length}',
                        monthlyGoal != null
                            ? 'this_month_goal'.tr()
                            : 'this_week'.tr(),
                        colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Goal progress bars
                  if (weeklyGoal != null || monthlyGoal != null)
                    Column(
                      children: [
                        if (weeklyGoal != null)
                          _buildGoalProgress(
                            context,
                            'weekly_goal_progress'.tr(),
                            weekCompleted,
                            weeklyGoal,
                            colorScheme.tertiary,
                          ),
                        if (weeklyGoal != null && monthlyGoal != null)
                          const SizedBox(height: 8),
                        if (monthlyGoal != null)
                          _buildGoalProgress(
                            context,
                            'monthly_goal_progress'.tr(),
                            monthCompleted,
                            monthlyGoal,
                            colorScheme.primaryContainer,
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Goal setting button with theme colors
                  FilledButton.icon(
                    onPressed: () {
                      final habitAsync = ref.read(
                        habitByIdProvider(widget.habitId),
                      );
                      habitAsync.whenData((habit) {
                        if (habit != null && context.mounted) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) =>
                                GoalSettingWidget(habit: habit),
                          );
                        }
                      });
                    },
                    icon: const Icon(Icons.flag, size: 18),
                    label: Text('set_goals'.tr()),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildGoalProgress(
    BuildContext context,
    String label,
    int completed,
    int goal,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = (completed / goal).clamp(0.0, 1.0);
    final percentage = ((completed / goal) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$completed/$goal ($percentage%)',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: progress >= 1.0
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: colorScheme.brightness == Brightness.dark ? 0.5 : 0.3,
            ),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? colorScheme.primary : color,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.25 : 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Map<DateTime, int> _calculateStreaksForMonth(
    List<db.TrackingEntry> entries,
    List<DateTime> days,
  ) {
    final streakMap = <DateTime, int>{};
    final completedEntries = entries
        .where((e) => e.completed)
        .map((e) => app_date_utils.DateUtils.getDateOnly(e.date))
        .toSet();

    // Calculate streaks going backwards from today
    int currentStreak = 0;
    final today = app_date_utils.DateUtils.getDateOnly(
      app_date_utils.DateUtils.getToday(),
    );

    // Sort days in reverse order (newest first)
    final sortedDays = List<DateTime>.from(days)
      ..sort((a, b) => b.compareTo(a));

    for (final day in sortedDays) {
      final dayOnly = app_date_utils.DateUtils.getDateOnly(day);

      if (completedEntries.contains(dayOnly)) {
        if (dayOnly.isBefore(today) || dayOnly.isAtSameMomentAs(today)) {
          currentStreak++;
          streakMap[day] = currentStreak;
        } else {
          // Future dates don't count in streak
          streakMap[day] = 0;
        }
      } else {
        // If this day is not completed, reset streak
        if (dayOnly.isBefore(today) || dayOnly.isAtSameMomentAs(today)) {
          currentStreak = 0;
        }
        streakMap[day] = 0;
      }
    }

    return streakMap;
  }

  Widget _buildCalendar(
    Map<DateTime, bool> entriesMap,
    Map<DateTime, bool> entriesWithNotes,
    List<db.TrackingEntry> allEntries,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final firstDayOfWeekSetting = ref.watch(firstDayOfWeekProvider);

    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    // Use month as key for AnimatedSwitcher
    final monthKey = '${_selectedMonth.year}-${_selectedMonth.month}';
    final lastDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
    final firstDayWeekday = firstDayOfMonth.weekday;

    // Convert setting (0=Sunday, 1=Monday) to Dart weekday (1=Monday, 7=Sunday)
    final startWeekday = firstDayOfWeekSetting == 0 ? 7 : firstDayOfWeekSetting;

    // Calculate days to show
    final daysInMonth = lastDayOfMonth.day;
    final days = <DateTime?>[];

    // Calculate offset: how many days to shift the first day of month
    // Dart weekday: 1=Monday, 7=Sunday
    // We need to align firstDayWeekday with startWeekday
    // When startWeekday is 7 (Sunday), we want Sunday to be in column 0
    int offset = (firstDayWeekday - startWeekday) % 7;
    if (offset < 0) {
      offset += 7;
    }

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < offset; i++) {
      days.add(null);
    }

    // Add all days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      days.add(DateTime(_selectedMonth.year, _selectedMonth.month, day));
    }

    // Calculate streaks for this month
    final monthDays = days.whereType<DateTime>().toList();
    final streakMap = _calculateStreaksForMonth(allEntries, monthDays);

    // Calculate monthly completion percentage
    final monthCompleted = entriesMap.values.where((v) => v).length;
    final monthCompletionPercentage = monthDays.isNotEmpty
        ? ((monthCompleted / monthDays.length) * 100).round()
        : 0;

    // Calculate number of weeks needed
    final numberOfWeeks = (days.length / 7).ceil();

    return Padding(
      key: ValueKey(monthKey),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month completion percentage with theme colors
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, size: 18, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  '${'completion'.tr()}: $monthCompletionPercentage%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Weekday headers with theme colors - use full names, respect first day of week
          Builder(
            builder: (context) {
              // Weekday names in order: Monday, Tuesday, ..., Sunday
              final weekdayNames = [
                'monday',
                'tuesday',
                'wednesday',
                'thursday',
                'friday',
                'saturday',
                'sunday',
              ];

              // Reorder based on first day of week setting
              // 0 = Sunday, 1 = Monday
              final orderedWeekdays = firstDayOfWeekSetting == 0
                  ? [
                      'sunday',
                      'monday',
                      'tuesday',
                      'wednesday',
                      'thursday',
                      'friday',
                      'saturday',
                    ]
                  : weekdayNames;

              return Row(
                children: orderedWeekdays
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          // Calendar grid with swipe gestures - fixed height
          LayoutBuilder(
            builder: (context, constraints) {
              final cellSize =
                  (constraints.maxWidth - 24) / 7; // 24 = 4*6 spacing
              final gridHeight =
                  (cellSize * numberOfWeeks) + (4 * (numberOfWeeks - 1));

              return GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! > 0) {
                      // Swipe right - previous month
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        );
                      });
                    } else if (details.primaryVelocity! < 0) {
                      // Swipe left - next month
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                      });
                    }
                  }
                },
                child: SizedBox(
                  height: gridHeight,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: false,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final day = days[index];
                      if (day == null) {
                        return const SizedBox.shrink();
                      }

                      final dayOnly = app_date_utils.DateUtils.getDateOnly(day);
                      final isCompleted = entriesMap[dayOnly] ?? false;
                      final isToday = app_date_utils.DateUtils.isToday(day);
                      // Weekend detection based on first day of week setting
                      // If week starts Sunday (0): weekends are Friday (5) and Saturday (6)
                      // If week starts Monday (1): weekends are Saturday (6) and Sunday (7)
                      final isWeekend = firstDayOfWeekSetting == 0
                          ? (day.weekday == 5 ||
                                day.weekday == 6) // Friday or Saturday
                          : (day.weekday == 6 ||
                                day.weekday == 7); // Saturday or Sunday
                      final hasNotes = entriesWithNotes[dayOnly] ?? false;
                      final streakLength = streakMap[day] ?? 0;

                      return Semantics(
                        label: isCompleted
                            ? 'completed_on'.tr(
                                namedArgs: {
                                  'date': DateFormat(
                                    'MMMM d',
                                    context.locale.languageCode,
                                  ).format(day),
                                },
                              )
                            : 'not_completed_on'.tr(
                                namedArgs: {
                                  'date': DateFormat(
                                    'MMMM d',
                                    context.locale.languageCode,
                                  ).format(day),
                                },
                              ),
                        button: true,
                        child: Builder(
                          builder: (context) {
                            final habitAsync = ref.watch(habitByIdProvider(widget.habitId));
                            return habitAsync.when(
                              data: (habit) {
                                final isGoodHabit = habit?.habitType == HabitType.good.value;
                                final completionColor = isGoodHabit
                                    ? ref.watch(calendarCompletionColorProvider)
                                    : ref.watch(calendarBadHabitCompletionColorProvider);
                                return _AnimatedCalendarDay(
                                  key: ValueKey('${day.year}-${day.month}-${day.day}'),
                                  isCompleted: isCompleted,
                                  isToday: isToday,
                                  isWeekend: isWeekend,
                                  day: day,
                                  entriesMap: entriesMap,
                                  hasNotes: hasNotes,
                                  streakLength: streakLength,
                                  completionColor: completionColor,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _toggleDay(day);
                                  },
                                  onLongPress: () {
                                    HapticFeedback.mediumImpact();
                                    _showNoteEditor(context, day);
                                  },
                                );
                              },
                              loading: () => _AnimatedCalendarDay(
                                key: ValueKey('${day.year}-${day.month}-${day.day}'),
                                isCompleted: isCompleted,
                                isToday: isToday,
                                isWeekend: isWeekend,
                                day: day,
                                entriesMap: entriesMap,
                                hasNotes: hasNotes,
                                streakLength: streakLength,
                                completionColor: ref.watch(calendarCompletionColorProvider),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _toggleDay(day);
                                },
                                onLongPress: () {
                                  HapticFeedback.mediumImpact();
                                  _showNoteEditor(context, day);
                                },
                              ),
                              error: (_, _) => _AnimatedCalendarDay(
                                key: ValueKey('${day.year}-${day.month}-${day.day}'),
                                isCompleted: isCompleted,
                                isToday: isToday,
                                isWeekend: isWeekend,
                                day: day,
                                entriesMap: entriesMap,
                                hasNotes: hasNotes,
                                streakLength: streakLength,
                                completionColor: ref.watch(calendarCompletionColorProvider),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _toggleDay(day);
                                },
                                onLongPress: () {
                                  HapticFeedback.mediumImpact();
                                  _showNoteEditor(context, day);
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16), // Bottom padding
        ],
      ),
    );
  }

  void _showNoteEditor(BuildContext context, DateTime day) {
    final repository = ref.read(habitRepositoryProvider);
    final dateOnly = app_date_utils.DateUtils.getDateOnly(day);

    // Get current entry to show existing notes
    repository.getEntry(widget.habitId, dateOnly).then((entry) {
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => NoteEditorWidget(
            habitId: widget.habitId,
            date: day,
            initialNotes: entry?.notes,
          ),
        );
      }
    });
  }

  Future<void> _toggleDay(DateTime day) async {
    final repository = ref.read(habitRepositoryProvider);
    final dateOnly = app_date_utils.DateUtils.getDateOnly(day);

    // Get current state from entries provider for immediate feedback
    final entriesAsync = ref.read(trackingEntriesProvider(widget.habitId));
    final currentEntries = entriesAsync.maybeWhen(
      data: (entries) => entries,
      orElse: () => <db.TrackingEntry>[],
    );
    final currentEntry = currentEntries
        .where((e) => app_date_utils.DateUtils.getDateOnly(e.date) == dateOnly)
        .firstOrNull;
    final currentCompleted = currentEntry?.completed ?? false;

    // Apply optimistic update immediately for instant UI feedback
    final newCompleted = !currentCompleted;
    setState(() {
      _optimisticUpdates[dateOnly] = newCompleted;
    });

    final habitAsync = ref.read(habitByIdProvider(widget.habitId).future);
    final habit = await habitAsync;
    if (habit == null) {
      // Revert optimistic update if habit not found
      setState(() {
        _optimisticUpdates.remove(dateOnly);
      });
      return;
    }

    final trackingType = TrackingType.fromValue(habit.trackingType);

    // Handle different tracking types
    if (trackingType == TrackingType.completed) {
      // Simple toggle for completed tracking - don't await to make UI responsive
      repository
          .toggleCompletion(widget.habitId, dateOnly, newCompleted)
          .then((_) {
            // Clear optimistic update once database confirms
            if (mounted) {
              setState(() {
                _optimisticUpdates.remove(dateOnly);
              });
            }
          })
          .catchError((error) {
            // Revert optimistic update on error
            if (mounted) {
              setState(() {
                _optimisticUpdates.remove(dateOnly);
              });
            }
          });
    } else if (trackingType == TrackingType.measurable) {
      // Revert optimistic update and open dialog
      setState(() {
        _optimisticUpdates.remove(dateOnly);
      });
      if (mounted) {
        _showMeasurableInputDialog(context, day, currentEntry, habit);
      }
    } else if (trackingType == TrackingType.occurrences) {
      // Revert optimistic update and open dialog
      setState(() {
        _optimisticUpdates.remove(dateOnly);
      });
      if (mounted) {
        _showOccurrencesInputDialog(context, day, currentEntry, habit);
      }
    }
  }

  void _showMeasurableInputDialog(
    BuildContext context,
    DateTime day,
    db.TrackingEntry? entry,
    db.Habit habit,
  ) {
    final repository = ref.read(habitRepositoryProvider);
    final dateOnly = app_date_utils.DateUtils.getDateOnly(day);
    final currentValue = entry?.value ?? 0.0;
    final unit = habit.unit ?? '';
    final goalValue = habit.goalValue;

    final controller = TextEditingController(
      text: currentValue > 0 ? currentValue.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(habit.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app_date_utils.DateUtils.formatDate(
                    dateOnly,
                    format: 'MMMM d, yyyy',
                  ),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 16),
                // Quick action buttons (25%, 50%, 75%, 100%)
                if (goalValue != null && goalValue > 0) ...[
                  Text(
                    'quick_actions'.tr(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          '25%',
                          goalValue * 0.25,
                          controller,
                          setDialogState,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          '50%',
                          goalValue * 0.5,
                          controller,
                          setDialogState,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          '75%',
                          goalValue * 0.75,
                          controller,
                          setDialogState,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          '100%',
                          goalValue,
                          controller,
                          setDialogState,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                // Value input field with +/- buttons
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        final current =
                            double.tryParse(controller.text.trim()) ?? 0.0;
                        final step = 1.0;
                        final newValue = (current - step).clamp(
                          0.0,
                          double.infinity,
                        );
                        controller.text = newValue.toStringAsFixed(
                          newValue % 1 == 0 ? 0 : 1,
                        );
                        setDialogState(() {});
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'value'.tr(),
                          suffixText: unit.isNotEmpty ? unit : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        final current =
                            double.tryParse(controller.text.trim()) ?? 0.0;
                        final step = 1.0;
                        final newValue = current + step;
                        controller.text = newValue.toStringAsFixed(
                          newValue % 1 == 0 ? 0 : 1,
                        );
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
                if (goalValue != null) ...[
                  const SizedBox(height: 16),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      final inputValue =
                          double.tryParse(value.text.trim()) ?? currentValue;
                      final percentage = (inputValue / goalValue * 100).clamp(
                        0.0,
                        double.infinity,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'progress'.tr(),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percentage > 100 ? 1.0 : percentage / 100,
                            backgroundColor: Colors.grey[300],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${inputValue.toStringAsFixed(1)} / ${goalValue.toStringAsFixed(1)} $unit (${percentage.toStringAsFixed(0)}%)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () async {
                final value = double.tryParse(controller.text.trim()) ?? 0.0;
                await repository.trackMeasurable(
                  widget.habitId,
                  dateOnly,
                  value,
                  notes: entry?.notes,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text('save'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    double value,
    TextEditingController controller,
    StateSetter setDialogState,
  ) {
    return OutlinedButton(
      onPressed: () {
        controller.text = value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
        setDialogState(() {});
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(60, 36),
      ),
      child: Text(label),
    );
  }

  void _showOccurrencesInputDialog(
    BuildContext context,
    DateTime day,
    db.TrackingEntry? entry,
    db.Habit habit,
  ) {
    final repository = ref.read(habitRepositoryProvider);
    final dateOnly = app_date_utils.DateUtils.getDateOnly(day);

    List<String> occurrenceNames = [];
    if (habit.occurrenceNames != null && habit.occurrenceNames!.isNotEmpty) {
      try {
        occurrenceNames = List<String>.from(jsonDecode(habit.occurrenceNames!));
      } catch (e) {
        occurrenceNames = [];
      }
    }

    if (occurrenceNames.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('no_occurrences'.tr()),
          content: Text('please_define_occurrences'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ok'.tr()),
            ),
          ],
        ),
      );
      return;
    }

    List<String> selectedOccurrences = [];
    if (entry != null &&
        entry.occurrenceData != null &&
        entry.occurrenceData!.isNotEmpty) {
      try {
        selectedOccurrences = List<String>.from(
          jsonDecode(entry.occurrenceData!),
        );
      } catch (e) {
        selectedOccurrences = [];
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(habit.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app_date_utils.DateUtils.formatDate(
                    dateOnly,
                    format: 'MMMM d, yyyy',
                  ),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'select_occurrences'.tr(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                ...occurrenceNames.map((name) {
                  final isSelected = selectedOccurrences.contains(name);
                  return CheckboxListTile(
                    title: Text(name),
                    value: isSelected,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedOccurrences.add(name);
                        } else {
                          selectedOccurrences.remove(name);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () async {
                await repository.trackOccurrences(
                  widget.habitId,
                  dateOnly,
                  selectedOccurrences,
                  notes: entry?.notes,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text('save'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCalendarDay extends StatefulWidget {
  final bool isCompleted;
  final bool isToday;
  final bool isWeekend;
  final DateTime day;
  final Map<DateTime, bool> entriesMap;
  final bool hasNotes;
  final int streakLength;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int completionColor;

  const _AnimatedCalendarDay({
    super.key,
    required this.isCompleted,
    required this.isToday,
    required this.isWeekend,
    required this.day,
    required this.entriesMap,
    this.hasNotes = false,
    this.streakLength = 0,
    required this.completionColor,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_AnimatedCalendarDay> createState() => _AnimatedCalendarDayState();
}

class _AnimatedCalendarDayState extends State<_AnimatedCalendarDay>
    with TickerProviderStateMixin {
  late final AnimationController _tapController;
  late final AnimationController _completionController;
  late final Animation<double> _tapScaleAnimation;
  late final Animation<double> _completionScaleAnimation;

  @override
  void initState() {
    super.initState();
    // Controller for tap feedback
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _tapScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeOut));

    // Controller for completion state change
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _completionScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.easeOut),
    );

    // Set initial state based on completion
    if (widget.isCompleted) {
      _completionController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _tapController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_AnimatedCalendarDay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted) {
      // Animate completion state change
      if (widget.isCompleted) {
        // Marking: grow from 0 to 1
        _completionController.forward();
      } else {
        // Unmarking: shrink from 1 to 0
        _completionController.reverse();
      }
    }
  }

  Color _getCompletedColor(int completionColorValue) {
    return Color(completionColorValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) {
        _tapController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _tapController.reverse(),
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _tapScaleAnimation,
        child: AnimatedBuilder(
          animation: _completionScaleAnimation,
          builder: (context, child) {
            // Interpolate between uncompleted and completed states
            final completionValue = _completionScaleAnimation.value;
            final isAnimatingCompleted = completionValue > 0.0;

            // Calculate background color based on animation
            Color backgroundColor;
            // Grey color for weekends - more visible
            final weekendColor = colorScheme.brightness == Brightness.dark
                ? Colors.grey[700]!.withValues(alpha: 0.6)
                : Colors.grey[300]!;

            if (isAnimatingCompleted) {
              // Interpolate between uncompleted and completed colors
              final uncompletedColor = widget.isToday
                  ? colorScheme.primaryContainer.withValues(
                      alpha: colorScheme.brightness == Brightness.dark
                          ? 0.4
                          : 0.3,
                    )
                  : (widget.isWeekend ? weekendColor : colorScheme.surface);
              // For weekends, blend with weekend color even when completing
              final completedColor = widget.isWeekend
                  ? Color.lerp(weekendColor, _getCompletedColor(widget.completionColor), 0.7)!
                  : _getCompletedColor(widget.completionColor);
              backgroundColor = Color.lerp(
                uncompletedColor,
                completedColor,
                completionValue,
              )!;
            } else {
              // For completed weekends, use a blend of grey and completed color
              if (widget.isCompleted && widget.isWeekend) {
                backgroundColor = Color.lerp(
                  weekendColor,
                  _getCompletedColor(widget.completionColor),
                  0.6,
                )!;
              } else {
                backgroundColor = widget.isCompleted
                    ? _getCompletedColor(widget.completionColor)
                    : (widget.isToday
                          ? colorScheme.primaryContainer.withValues(
                              alpha: colorScheme.brightness == Brightness.dark
                                  ? 0.4
                                  : 0.3,
                            )
                          : (widget.isWeekend
                                ? weekendColor
                                : colorScheme.surface));
              }
            }

            // Scale the container based on completion animation
            // When marking: scale grows from 1.0 to 1.02 (very subtle growth)
            // When unmarking: scale shrinks from 1.0 to 0.95 (subtle shrinkage)
            final containerScale = widget.isCompleted
                ? 1.0 +
                      (completionValue * 0.02) // Grow when marking (2% max)
                : 1.0 -
                      ((1.0 - completionValue) *
                          0.05); // Shrink when unmarking (5% max)

            return LayoutBuilder(
              builder: (context, constraints) {
                // Use the smaller dimension to ensure circle fits in grid cell
                final size = constraints.maxWidth < constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight;

                return Center(
                  child: Transform.scale(
                    scale: containerScale,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                        border: widget.isToday
                            ? Border.all(color: colorScheme.primary, width: 2.5)
                            : (isAnimatingCompleted || widget.isCompleted
                                  ? Border.all(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.8 * completionValue,
                                      ),
                                      width: 1.5,
                                    )
                                  : null),
                      ),
                      child: child,
                    ),
                  ),
                );
              },
            );
          },
          child: _buildContent(colorScheme),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.day.day}',
              style: TextStyle(
                fontWeight: widget.isToday
                    ? FontWeight.bold
                    : (widget.isCompleted
                          ? FontWeight.w600
                          : FontWeight.normal),
                fontSize: widget.isToday ? 15 : 14,
                color: widget.isCompleted
                    ? colorScheme.onPrimary
                    : (widget.isToday
                          ? colorScheme.onPrimaryContainer
                          : (widget.isWeekend
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface)),
              ),
            ),
            if (widget.isCompleted)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  // Clamp values to valid ranges
                  final clampedOpacity = value.clamp(0.0, 1.0);
                  final clampedScale = value.clamp(0.0, 1.2);
                  return Transform.scale(
                    scale: clampedScale,
                    child: Opacity(
                      opacity: clampedOpacity,
                      child: Icon(
                        Icons.check,
                        size: 12,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        // Streak indicator with theme colors
        if (widget.streakLength > 1)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.secondary.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Icon(
                Icons.local_fire_department,
                size: 11,
                color: colorScheme.onSecondary,
              ),
            ),
          ),
        // Notes indicator with theme colors
        if (widget.hasNotes)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colorScheme.tertiary,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.tertiary.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Icon(Icons.note, size: 9, color: colorScheme.onTertiary),
            ),
          ),
      ],
    );
  }
}
