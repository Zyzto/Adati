import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart' as db;
import '../providers/tracking_providers.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../providers/habit_providers.dart';
import '../widgets/habit_timeline.dart';
import 'habit_calendar_modal.dart';
import 'checkbox_style_widget.dart';
import '../../settings/providers/settings_providers.dart';
import '../../../../core/widgets/skeleton_loader.dart';

class HabitCard extends ConsumerWidget {
  final db.Habit habit;

  const HabitCard({super.key, required this.habit});

  Future<void> _toggleTodayCompletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    HapticFeedback.mediumImpact();
    final repository = ref.read(habitRepositoryProvider);
    final today = app_date_utils.DateUtils.getToday();

    // Get current status
    final entry = await repository.getEntry(habit.id, today);
    final isCompleted = entry?.completed ?? false;

    // Toggle completion
    await repository.toggleCompletion(habit.id, today, !isCompleted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayEntryAsync = ref.watch(todayEntryProvider(habit.id));
    final checkboxStyleString = ref.watch(habitCheckboxStyleProvider);
    final checkboxStyle = habitCheckboxStyleFromString(checkboxStyleString);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) => HabitCalendarModal(habitId: habit.id),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                      // Timeline visualization (disabled clicks)
                      const SizedBox(height: 16),
                      HabitTimeline(habitId: habit.id, compact: true),
                    ],
                  ),
                ),
              ),
            ),
            // Checkmark button - fills entire height
            todayEntryAsync.when(
              data: (isCompleted) => Material(
                color: Colors.transparent,
                child: Semantics(
                  label: isCompleted
                      ? 'Mark as incomplete'
                      : 'Mark as complete',
                  button: true,
                  child: InkWell(
                    onTap: () => _toggleTodayCompletion(context, ref),
                    child: Container(
                      width: 96,
                      constraints: const BoxConstraints(minHeight: 44),
                      alignment: Alignment.center,
                      child: buildCheckboxWidget(
                        checkboxStyle,
                        isCompleted,
                        36,
                        () => _toggleTodayCompletion(context, ref),
                      ),
                    ),
                  ),
                ),
              ),
              loading: () => Container(
                width: 96,
                alignment: Alignment.center,
                child: SkeletonLoader(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              error: (_, _) => Material(
                color: Colors.transparent,
                child: Semantics(
                  label: 'Mark as complete',
                  button: true,
                  child: InkWell(
                    onTap: () => _toggleTodayCompletion(context, ref),
                    child: Container(
                      width: 96,
                      constraints: const BoxConstraints(minHeight: 44),
                      alignment: Alignment.center,
                      child: buildCheckboxWidget(
                        checkboxStyle,
                        false,
                        36,
                        () => _toggleTodayCompletion(context, ref),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
