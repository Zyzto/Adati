import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/habit_providers.dart';
import '../providers/tracking_providers.dart';
import '../widgets/habit_timeline.dart';
import '../widgets/habit_form_modal.dart';

class HabitDetailPage extends ConsumerWidget {
  final int habitId;

  const HabitDetailPage({super.key, required this.habitId});

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('delete_habit'.tr()),
          content: Text(
            'delete_habit_confirmation_generic'.tr(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final repository = ref.read(habitRepositoryProvider);
                await repository.deleteHabit(habitId);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('delete'.tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitAsync = ref.watch(habitByIdProvider(habitId));
    final streakAsync = ref.watch(streakProvider(habitId));

    return Scaffold(
      appBar: AppBar(
        title: habitAsync.when(
          data: (habit) => Text(habit?.name ?? 'Habit'),
          loading: () => Text('loading'.tr()),
          error: (_, _) => Text('error'.tr()),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => HabitFormModal.show(context, habitId: habitId),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context, ref),
          ),
        ],
      ),
      body: habitAsync.when(
        data: (habit) {
          if (habit == null) {
            return Center(child: Text('habit_not_found'.tr()));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (habit.description != null) ...[
                  Text(
                    habit.description!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                ],
                streakAsync.when(
                  data: (streak) {
                    if (streak == null) {
                      return const SizedBox.shrink();
                    }
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${streak.currentStreak}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'current_streak'.tr(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '${streak.longestStreak}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'longest_streak'.tr(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                Text(
                  'timeline'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                HabitTimeline(habitId: habitId),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${'error'.tr()}: $error')),
      ),
    );
  }
}

