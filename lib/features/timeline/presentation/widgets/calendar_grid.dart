import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../habits/presentation/providers/habit_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No habits yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push('/habits/new'),
                  child: const Text('Create your first habit'),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last $daysToShow days',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildGrid(context, ref, days, habits),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
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
      children: days.map((day) {
        return FutureBuilder<Map<int, bool>>(
          future: _getDayEntries(ref, day, habits),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return DaySquare(
                date: day,
                completed: false,
                size: 16,
              );
            }

            final entries = snapshot.data!;
            final completedCount = entries.values.where((v) => v).length;
            final totalCount = entries.length;
            final completionRate = totalCount > 0 ? completedCount / totalCount : 0.0;

            return DaySquare(
              date: day,
              completed: completionRate > 0,
              size: 16,
              onTap: null, // Disabled for now, might be used later
            );
          },
        );
      }).toList(),
    );
  }

  Future<Map<int, bool>> _getDayEntries(
    WidgetRef ref,
    DateTime day,
    List habits,
  ) async {
    final repository = ref.read(habitRepositoryProvider);
    final entries = <int, bool>{};

    for (final habit in habits) {
      final entry = await repository.getEntry(habit.id!, day);
      entries[habit.id!] = entry?.completed ?? false;
    }

    return entries;
  }
}

