import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../habits/providers/habit_providers.dart';
import '../../habits/providers/tracking_providers.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;

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
                final completedCount = entries.values.where((v) => v).length;
                final totalHabits = habits.length;
                final completionRate = totalHabits > 0
                    ? ((completedCount / totalHabits) * 100).toInt()
                    : 0;
                final activeStreaks = streaks.where((s) => s.currentStreak > 0).length;

            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Today',
                      value: '$completedCount/$totalHabits',
                      icon: Icons.check_circle,
                      color: completionRate == 100
                          ? Colors.green
                          : completionRate >= 50
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    _StatItem(
                      label: 'Completion',
                      value: '$completionRate%',
                      icon: Icons.trending_up,
                      color: completionRate == 100
                          ? Colors.green
                          : completionRate >= 50
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    _StatItem(
                      label: 'Active Streaks',
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

