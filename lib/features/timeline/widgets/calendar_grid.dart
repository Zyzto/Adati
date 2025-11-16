import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/database/models/tracking_types.dart';
import '../../habits/providers/habit_providers.dart';
import '../../habits/providers/tracking_providers.dart';
import '../../settings/providers/settings_providers.dart';
import 'day_square.dart';

class CalendarGrid extends ConsumerWidget {
  const CalendarGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final daysToShow = ref.watch(timelineDaysProvider);
    final days = app_date_utils.DateUtils.getLastNDays(daysToShow);

    return habitsAsync.when(
      data: (habits) {
        if (habits.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'last_days'.tr(namedArgs: {'days': daysToShow.toString()}),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildGrid(context, ref, days, habits),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('${'error'.tr()}: $error')),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    List<DateTime> days,
    List habits,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: days.map<Widget>((day) {
        // Use provider to watch for changes reactively
        final dayEntriesAsync = ref.watch(dayEntriesProvider(day));

        return dayEntriesAsync.when(
          data: (entries) {
            final badHabitLogicMode = ref.watch(badHabitLogicModeProvider);
            final completionRate = _calculateWeightedCompletionRate(
              habits,
              entries,
              badHabitLogicMode,
            );

            return DaySquare(
              date: day,
              completed: completionRate > 0,
              onTap: null, // Disabled for now, might be used later
              completionColor: ref.watch(mainTimelineCompletionColorProvider),
            );
          },
          loading: () => DaySquare(
            date: day,
            completed: false,
            completionColor: ref.watch(mainTimelineCompletionColorProvider),
          ),
          error: (_, _) => DaySquare(
            date: day,
            completed: false,
            completionColor: ref.watch(mainTimelineCompletionColorProvider),
          ),
        );
      }).toList(),
    );
  }

  double _calculateWeightedCompletionRate(
    List habits,
    Map<int, bool> entries,
    String badHabitLogicMode,
  ) {
    int goodCompleted = 0;
    int badCount = 0; // bad marked (negative) or bad not marked (positive)
    int totalGood = 0;
    int totalBad = 0;

    for (final habit in habits) {
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
