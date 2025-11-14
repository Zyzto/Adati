import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/tracking_providers.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/database/app_database.dart' as db;
import '../providers/habit_providers.dart';
import '../widgets/habit_timeline.dart';
import '../widgets/habit_management_menu.dart';
import '../widgets/note_editor_widget.dart';
import '../widgets/goal_setting_widget.dart';
import '../../settings/providers/settings_providers.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/services/preferences_service.dart';

class HabitCalendarModal extends ConsumerStatefulWidget {
  final int habitId;

  const HabitCalendarModal({super.key, required this.habitId});

  @override
  ConsumerState<HabitCalendarModal> createState() => _HabitCalendarModalState();
}

class _HabitCalendarModalState extends ConsumerState<HabitCalendarModal> {
  DateTime _selectedMonth = DateTime.now();

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

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with month navigation and settings
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'previous_month'.tr(),
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
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'next_month'.tr(),
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
                              onPressed: () =>
                                  _showManagementMenu(context, ref, habit),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              // Card preview section
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
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon - Title row
                        Row(
                          children: [
                            // Icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(habit.color),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: habit.icon != null
                                  ? Icon(
                                      IconData(
                                        int.parse(habit.icon!),
                                        fontFamily: 'MaterialIcons',
                                      ),
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // Title
                            Expanded(
                              child: Text(
                                habit.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
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
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 8),
              // Statistics section
              _buildStatisticsSection(context, ref, entriesAsync, streakAsync),
              // Divider between statistics and calendar
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
              // Calendar with animated month transitions
              Expanded(
                child: entriesAsync.when(
                  data: (entries) {
                    if (entries.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.calendar_today,
                        title: 'no_entries_yet'.tr(),
                        message: 'complete_habit_to_see_calendar'.tr(),
                      );
                    }
                    final entriesMap = {
                      for (var entry in entries)
                        app_date_utils.DateUtils.getDateOnly(entry.date):
                            entry.completed,
                    };
                    final entriesWithNotes = {
                      for (var entry in entries)
                        if (entry.notes != null && entry.notes!.isNotEmpty)
                          app_date_utils.DateUtils.getDateOnly(entry.date):
                              true,
                    };
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.3, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: animation,
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
              ),
            ],
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
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        Icons.local_fire_department,
                        '${streak?.currentStreak ?? 0}',
                        'current_streak'.tr(),
                        Colors.orange,
                      ),
                      _buildStatItem(
                        context,
                        Icons.emoji_events,
                        '${streak?.longestStreak ?? 0}',
                        'longest_streak'.tr(),
                        Colors.amber,
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
                        Colors.blue,
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
                        Colors.green,
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
                            Colors.blue,
                          ),
                        if (weeklyGoal != null && monthlyGoal != null)
                          const SizedBox(height: 8),
                        if (monthlyGoal != null)
                          _buildGoalProgress(
                            context,
                            'monthly_goal_progress'.tr(),
                            monthCompleted,
                            monthlyGoal,
                            Colors.green,
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Goal setting button
                  TextButton.icon(
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
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildGoalProgress(
    BuildContext context,
    String label,
    int completed,
    int goal,
    Color color,
  ) {
    final progress = (completed / goal).clamp(0.0, 1.0);
    final percentage = ((completed / goal) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              '$completed/$goal ($percentage%)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: progress >= 1.0 ? Colors.green : color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.green : color,
            ),
            minHeight: 6,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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

    // Calculate days to show
    final daysInMonth = lastDayOfMonth.day;
    final days = <DateTime?>[];

    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstDayWeekday; i++) {
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

    return Padding(
      key: ValueKey(monthKey),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month completion percentage
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${'completion'.tr()}: $monthCompletionPercentage%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid with swipe gestures
          Expanded(
            child: GestureDetector(
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
              child: GridView.builder(
                shrinkWrap: false,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                  final isWeekend =
                      day.weekday == 6 ||
                      day.weekday == 7; // Saturday or Sunday
                  final hasNotes = entriesWithNotes[dayOnly] ?? false;
                  final streakLength = streakMap[day] ?? 0;

                  return Semantics(
                    label: isCompleted
                        ? 'Completed on ${DateFormat('MMMM d').format(day)}'
                        : 'Not completed on ${DateFormat('MMMM d').format(day)}',
                    button: true,
                    child: _AnimatedCalendarDay(
                      isCompleted: isCompleted,
                      isToday: isToday,
                      isWeekend: isWeekend,
                      day: day,
                      entriesMap: entriesMap,
                      hasNotes: hasNotes,
                      streakLength: streakLength,
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
            ),
          ),
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

    // Get current status
    final entry = await repository.getEntry(widget.habitId, dateOnly);
    final isCompleted = entry?.completed ?? false;

    // Toggle completion
    await repository.toggleCompletion(widget.habitId, dateOnly, !isCompleted);
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

  const _AnimatedCalendarDay({
    required this.isCompleted,
    required this.isToday,
    required this.isWeekend,
    required this.day,
    required this.entriesMap,
    this.hasNotes = false,
    this.streakLength = 0,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_AnimatedCalendarDay> createState() => _AnimatedCalendarDayState();
}

class _AnimatedCalendarDayState extends State<_AnimatedCalendarDay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_AnimatedCalendarDay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted) {
      // Animate on completion change
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  Color _getTodayTextColor(BuildContext context) {
    // Always use a visible color for today - blue shade for better contrast
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.blue.shade300
        : Colors.blue.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          decoration: BoxDecoration(
            color: widget.isCompleted
                ? Colors.green
                : (widget.isToday
                      ? Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.withValues(alpha: 0.3)
                            : Colors.blue.withValues(alpha: 0.2)
                      : (widget.isWeekend
                            ? Colors.grey[100]
                            : Colors.grey[200])),
            shape: BoxShape.circle,
            border: widget.isToday
                ? Border.all(color: Colors.blue, width: 3)
                : (widget.isCompleted
                      ? Border.all(color: Colors.green.shade700, width: 1)
                      : null),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
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
                          ? Colors.white
                          : (widget.isToday
                                ? _getTodayTextColor(context)
                                : (widget.isWeekend
                                      ? Colors.grey[600]
                                      : Colors.black87)),
                    ),
                  ),
                  if (widget.isCompleted)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value,
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              // Streak indicator (top right)
              if (widget.streakLength > 1)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 10,
                          color: Colors.white,
                        ),
                        if (widget.streakLength > 9)
                          Text(
                            '${widget.streakLength}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              // Notes indicator (bottom right)
              if (widget.hasNotes)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.note, size: 8, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
