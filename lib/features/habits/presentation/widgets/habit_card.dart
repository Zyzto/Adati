import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/habit.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../providers/habit_providers.dart';
import '../widgets/habit_timeline.dart';
import 'habit_management_menu.dart';
import 'habit_calendar_modal.dart';

class HabitCard extends ConsumerWidget {
  final Habit habit;

  const HabitCard({super.key, required this.habit});

  Future<void> _toggleTodayCompletion(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(habitRepositoryProvider);
    final today = app_date_utils.DateUtils.getToday();
    
    // Get current status
    final entry = await repository.getEntry(habit.id!, today);
    final isCompleted = entry?.completed ?? false;
    
    // Toggle completion
    await repository.toggleCompletion(
      habit.id!,
      today,
      !isCompleted,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayEntryAsync = ref.watch(todayEntryProvider(habit.id!));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => HabitCalendarModal(habitId: habit.id!),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon - Title - Checkmark row
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
                            IconData(int.parse(habit.icon!), fontFamily: 'MaterialIcons'),
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Title with settings cog
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _showManagementMenu(context, ref);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Checkmark button
                  todayEntryAsync.when(
                    data: (isCompleted) => IconButton(
                      icon: Icon(
                        isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                        color: isCompleted ? Colors.green : Colors.grey,
                        size: 32,
                      ),
                      onPressed: () => _toggleTodayCompletion(context, ref),
                    ),
                    loading: () => const SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (_, __) => IconButton(
                      icon: const Icon(Icons.check_circle_outline, size: 32),
                      onPressed: () => _toggleTodayCompletion(context, ref),
                    ),
                  ),
                ],
              ),
              // Timeline visualization (disabled clicks)
              const SizedBox(height: 16),
              HabitTimeline(habitId: habit.id!, compact: true),
            ],
          ),
        ),
      ),
    );
  }

  void _showManagementMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => HabitManagementMenu(habit: habit),
    );
  }
}
