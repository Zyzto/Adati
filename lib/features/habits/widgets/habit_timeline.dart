import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/tracking_providers.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../timeline/widgets/day_square.dart';
import '../../../../core/widgets/skeleton_loader.dart';

class HabitTimeline extends ConsumerWidget {
  final int habitId;
  final bool compact;
  final int? daysToShow;

  const HabitTimeline({
    super.key,
    required this.habitId,
    this.compact = false,
    this.daysToShow,
  });

  Map<DateTime, int> _calculateStreaks(List<DateTime> days, Map<DateTime, bool> entriesMap) {
    final streakMap = <DateTime, int>{};
    int currentStreak = 0;
    
    // Calculate streaks going backwards from today
    for (int i = days.length - 1; i >= 0; i--) {
      final day = days[i];
      if (entriesMap[day] == true) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(trackingEntriesProvider(habitId));
    final calculatedDaysToShow = daysToShow ?? (compact ? 30 : 100);
    final needsScroll = calculatedDaysToShow > 100;

    return entriesAsync.when(
      data: (entries) {
        final days = app_date_utils.DateUtils.getLastNDays(calculatedDaysToShow);
        final entriesMap = {
          for (var entry in entries)
            app_date_utils.DateUtils.getDateOnly(entry.date): entry.completed
        };
        
        final streakMap = _calculateStreaks(days, entriesMap);

        final timelineWidget = Wrap(
          spacing: compact ? 4 : 6,
          runSpacing: compact ? 4 : 6,
          children: days.map((day) {
            final completed = entriesMap[day] ?? false;
            final streakLength = streakMap[day] ?? 0;
            final isCurrentWeek = _isInCurrentWeek(day);
            final isCurrentMonth = _isInCurrentMonth(day);
            
            return DaySquare(
              date: day,
              completed: completed,
              size: compact ? 12 : null,
              onTap: null,
              streakLength: streakLength,
              highlightWeek: isCurrentWeek,
              highlightMonth: isCurrentMonth,
            );
          }).toList(),
        );

        if (needsScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: timelineWidget,
          );
        }

        return timelineWidget;
      },
      loading: () => const SizedBox(
        height: 50,
        child: SkeletonTimeline(),
      ),
      error: (error, stack) => Text('${'error'.tr()}: $error'),
    );
  }
}

