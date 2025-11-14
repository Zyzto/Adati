import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../providers/habit_providers.dart';

class QuickActionsWidget extends ConsumerWidget {
  const QuickActionsWidget({super.key});

  Future<void> _markAllToday(BuildContext context, WidgetRef ref, bool completed) async {
    HapticFeedback.mediumImpact();
    final repository = ref.read(habitRepositoryProvider);
    final habitsAsync = ref.read(habitsProvider);
    final today = app_date_utils.DateUtils.getToday();
    
    final habits = habitsAsync.value;
    if (habits == null) return;
    
    for (final habit in habits) {
      final entry = await repository.getEntry(habit.id, today);
      final isCompleted = entry?.completed ?? false;
      
      if (isCompleted != completed) {
        await repository.toggleCompletion(habit.id, today, completed);
      }
    }
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(completed 
              ? 'marked_all_today_completed'.tr() 
              : 'marked_all_today_incomplete'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _markAllYesterday(BuildContext context, WidgetRef ref, bool completed) async {
    HapticFeedback.mediumImpact();
    final repository = ref.read(habitRepositoryProvider);
    final habitsAsync = ref.read(habitsProvider);
    final yesterday = app_date_utils.DateUtils.getToday().subtract(const Duration(days: 1));
    
    final habits = habitsAsync.value;
    if (habits == null) return;
    
    for (final habit in habits) {
      final entry = await repository.getEntry(habit.id, yesterday);
      final isCompleted = entry?.completed ?? false;
      
      if (isCompleted != completed) {
        await repository.toggleCompletion(habit.id, yesterday, completed);
      }
    }
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(completed 
              ? 'marked_all_yesterday_completed'.tr() 
              : 'marked_all_yesterday_incomplete'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.flash_on, size: 18, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'quick_actions'.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  context,
                  ref,
                  icon: Icons.check_circle,
                  label: 'mark_all_today'.tr(),
                  color: Colors.green,
                  onPressed: () => _markAllToday(context, ref, true),
                ),
                _buildActionButton(
                  context,
                  ref,
                  icon: Icons.cancel,
                  label: 'unmark_all_today'.tr(),
                  color: Colors.grey,
                  onPressed: () => _markAllToday(context, ref, false),
                ),
                _buildActionButton(
                  context,
                  ref,
                  icon: Icons.history,
                  label: 'mark_all_yesterday'.tr(),
                  color: Colors.blue,
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
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
    );
  }
}

