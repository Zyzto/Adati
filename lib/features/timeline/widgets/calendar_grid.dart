import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
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
            final completedCount = entries.values.where((v) => v).length;
            final totalCount = entries.length;
            final completionRate = totalCount > 0
                ? completedCount / totalCount
                : 0.0;

            return DaySquare(
              date: day,
              completed: completionRate > 0,
              onTap: null, // Disabled for now, might be used later
            );
          },
          loading: () => DaySquare(date: day, completed: false),
          error: (_, _) => DaySquare(date: day, completed: false),
        );
      }).toList(),
    );
  }
}
