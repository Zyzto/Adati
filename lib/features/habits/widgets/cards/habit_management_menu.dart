import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../core/database/app_database.dart' as db;
import '../../providers/habit_providers.dart';
import '../forms/habit_form_modal.dart';

class HabitManagementMenu extends ConsumerWidget {
  final db.Habit habit;

  const HabitManagementMenu({super.key, required this.habit});

  Future<void> _deleteHabit(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_habit'.tr()),
        content: Text(
          'delete_habit_confirmation'.tr(namedArgs: {'name': habit.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = ref.read(habitRepositoryProvider);
      try {
        await repository.deleteHabit(habit.id);
        if (context.mounted) {
          Navigator.pop(context); // Close the bottom sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('habit_deleted'.tr(args: [habit.name])),
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error_deleting_habit'.tr(args: [habit.name])),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(habit.color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: habit.icon != null
                    ? Icon(
                        IconData(
                          int.parse(habit.icon!),
                          fontFamily: 'MaterialIcons',
                        ),
                        color: Color(habit.color),
                      )
                    : Icon(
                        Icons.check_circle,
                        color: Color(habit.color),
                      ),
              ),
              title: Text(
                habit.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: habit.description != null &&
                      habit.description!.trim().isNotEmpty
                  ? Text(
                      habit.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text('edit_habit'.tr()),
              onTap: () {
                Navigator.pop(context);
                HabitFormModal.show(context, habitId: habit.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                'delete_habit'.tr(),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () => _deleteHabit(context, ref),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

