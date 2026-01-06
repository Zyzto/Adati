import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../habits/providers/habit_providers.dart';
import '../../habits/providers/tracking_providers.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/database/models/tracking_types.dart';
import '../../settings/providers/settings_framework_providers.dart';
import '../../settings/settings_definitions.dart';

class TimelineStats extends ConsumerWidget {
  const TimelineStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final today = app_date_utils.DateUtils.getToday();
    final dayEntriesAsync = ref.watch(dayEntriesProvider(today));
    final streaksAsync = ref.watch(allStreaksProvider);

    return habitsAsync.when(
      data: (habits) {
        if (habits.isEmpty) {
          return const SizedBox.shrink();
        }

        return dayEntriesAsync.when(
          data: (entries) {
            return streaksAsync.when(
              data: (streaks) {
                final settings = ref.watch(adatiSettingsProvider);
                final badHabitLogicMode = ref.watch(settings.provider(badHabitLogicModeSettingDef));
                final completionRate = _calculateWeightedCompletionRate(
                  habits,
                  entries,
                  badHabitLogicMode,
                  today,
                );
                final completionRatePercent = (completionRate * 100).toInt();
                
                // Calculate display count based on mode
                int goodCompleted = 0;
                int badCount = 0;
                int totalGood = 0;
                int totalBad = 0;
                
                for (final habit in habits) {
                  // Only count habits that were created on or before today
                  if (!app_date_utils.DateUtils.isDateAfterHabitCreation(today, habit.createdAt)) {
                    continue;
                  }
                  
                  final entryCompleted = entries[habit.id] ?? false;
                  final isGoodHabit = habit.habitType == HabitType.good.value;
                  
                  if (isGoodHabit) {
                    totalGood++;
                    if (entryCompleted) goodCompleted++;
                  } else {
                    totalBad++;
                    if (badHabitLogicMode == 'negative') {
                      if (entryCompleted) badCount++;
                    } else {
                      if (!entryCompleted) badCount++;
                    }
                  }
                }
                
                final displayCount = badHabitLogicMode == 'negative'
                    ? (totalGood > 0 ? goodCompleted - badCount : totalBad - badCount)
                    : goodCompleted + badCount;
                final totalHabits = habits.length;
                
                final activeStreaks = streaks.where((s) => s.currentStreak > 0).length;

            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'today'.tr(),
                      value: '$displayCount/$totalHabits',
                      icon: Icons.check_circle,
                      color: completionRatePercent == 100
                          ? Colors.green
                          : completionRatePercent >= 50
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    _StatItem(
                      label: 'completion'.tr(),
                      value: '$completionRatePercent%',
                      icon: Icons.trending_up,
                      color: completionRatePercent == 100
                          ? Colors.green
                          : completionRatePercent >= 50
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    _StatItem(
                      label: 'active_streaks'.tr(),
                      value: '$activeStreaks',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ],
                ),
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
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  double _calculateWeightedCompletionRate(
    List habits,
    Map<int, bool> entries,
    String badHabitLogicMode,
    DateTime date,
  ) {
    int goodCompleted = 0;
    int badCount = 0; // bad marked (negative) or bad not marked (positive)
    int totalGood = 0;
    int totalBad = 0;

    final dateOnly = app_date_utils.DateUtils.getDateOnly(date);

    for (final habit in habits) {
      // Only count habits that were created on or before the date being calculated
      if (!app_date_utils.DateUtils.isDateAfterHabitCreation(dateOnly, habit.createdAt)) {
        continue;
      }

      final entryCompleted = entries[habit.id] ?? false;
      final isGoodHabit = habit.habitType == HabitType.good.value;

      if (isGoodHabit) {
        totalGood++;
        if (entryCompleted) goodCompleted++;
      } else {
        totalBad++;
        if (badHabitLogicMode == 'negative') {
          // Negative mode: count marked bad habits
          if (entryCompleted) badCount++;
        } else {
          // Positive mode: count not marked bad habits
          if (!entryCompleted) badCount++;
        }
      }
    }

    if (badHabitLogicMode == 'negative') {
      if (totalGood > 0) {
        // Normal case: (good completed - bad marked) / total good
        return ((goodCompleted - badCount) / totalGood).clamp(0.0, 1.0);
      } else if (totalBad > 0) {
        // Only bad habits: start at 100%, decrease by bad marked / total bad
        return (1.0 - (badCount / totalBad)).clamp(0.0, 1.0);
      }
    } else {
      // Positive mode: (good completed + bad not marked) / total habits
      final totalHabits = totalGood + totalBad;
      if (totalHabits > 0) {
        return ((goodCompleted + badCount) / totalHabits).clamp(0.0, 1.0);
      }
    }

    return 0.0; // No habits
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

