import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../timeline/presentation/widgets/day_square.dart';

class HabitTimeline extends ConsumerWidget {
  final int habitId;
  final bool compact;

  const HabitTimeline({
    super.key,
    required this.habitId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(trackingEntriesProvider(habitId));
    final daysToShow = compact ? 30 : 100;

    return entriesAsync.when(
      data: (entries) {
        final days = app_date_utils.DateUtils.getLastNDays(daysToShow);
        final entriesMap = {
          for (var entry in entries)
            app_date_utils.DateUtils.getDateOnly(entry.date): entry.completed
        };

        return Wrap(
          spacing: compact ? 4 : 6,
          runSpacing: compact ? 4 : 6,
          children: days.map((day) {
            final completed = entriesMap[day] ?? false;
            return DaySquare(
              date: day,
              completed: completed,
              size: compact ? 12 : 16,
              onTap: null, // Disabled - clicking on boxes disabled
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

