import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../providers/habit_providers.dart';

class QuickActionsWidget extends ConsumerWidget {
  const QuickActionsWidget({super.key});

  Future<void> _markAllToday(
    BuildContext context,
    WidgetRef ref,
    bool completed,
  ) async {
    HapticFeedback.mediumImpact();
    final repository = ref.read(habitRepositoryProvider);
    final habitsAsync = ref.read(habitsProvider);
    final today = app_date_utils.DateUtils.getToday();

    final habits = habitsAsync.value;
    if (habits == null || habits.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_habits_available'.tr())),
        );
      }
      return;
    }

    int updatedCount = 0;
    try {
      for (final habit in habits) {
        final entry = await repository.getEntry(habit.id, today);
        final isCompleted = entry?.completed ?? false;

        if (isCompleted != completed) {
          await repository.toggleCompletion(habit.id, today, completed);
          updatedCount++;
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_updating_habits_bulk'.tr())),
        );
      }
      return;
    }

    if (context.mounted) {
      if (updatedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_changes_needed'.tr())),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              completed
                  ? 'marked_all_today_completed'.tr()
                  : 'marked_all_today_incomplete'.tr(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _markAllYesterday(
    BuildContext context,
    WidgetRef ref,
    bool completed,
  ) async {
    HapticFeedback.mediumImpact();
    final repository = ref.read(habitRepositoryProvider);
    final habitsAsync = ref.read(habitsProvider);
    final yesterday =
        app_date_utils.DateUtils.getToday().subtract(const Duration(days: 1));

    final habits = habitsAsync.value;
    if (habits == null || habits.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_habits_available'.tr())),
        );
      }
      return;
    }

    int updatedCount = 0;
    try {
      for (final habit in habits) {
        final entry = await repository.getEntry(habit.id, yesterday);
        final isCompleted = entry?.completed ?? false;

        if (isCompleted != completed) {
          await repository.toggleCompletion(habit.id, yesterday, completed);
          updatedCount++;
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_updating_habits_bulk'.tr())),
        );
      }
      return;
    }

    if (context.mounted) {
      if (updatedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_changes_needed'.tr())),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              completed
                  ? 'marked_all_yesterday_completed'.tr()
                  : 'marked_all_yesterday_incomplete'.tr(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    Icons.flash_on,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'quick_actions'.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'quick_actions_description'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.check_circle,
                  label: 'mark_all_today'.tr(),
                  color: Colors.green,
                  onPressed: () => _markAllToday(context, ref, true),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.cancel,
                  label: 'unmark_all_today'.tr(),
                  color: theme.colorScheme.outline,
                  onPressed: () => _markAllToday(context, ref, false),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.history,
                  label: 'mark_all_yesterday'.tr(),
                  color: theme.colorScheme.primary,
                  onPressed: () => _markAllYesterday(context, ref, true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: color.withValues(alpha: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

