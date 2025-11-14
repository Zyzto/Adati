import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/database/app_database.dart' as db;
import '../providers/habit_providers.dart';

class HabitManagementMenu extends ConsumerWidget {
  final db.Habit habit;

  const HabitManagementMenu({super.key, required this.habit});

  Future<void> _deleteHabit(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_habit'.tr()),
        content: Text('delete_habit_confirmation'.tr(namedArgs: {'name': habit.name})),
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
      await repository.deleteHabit(habit.id);
      if (context.mounted) {
        Navigator.pop(context); // Close the bottom sheet
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text('edit_habit'.tr()),
            onTap: () {
              Navigator.pop(context);
              context.push('/habits/${habit.id}/edit');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text('delete_habit'.tr(), style: const TextStyle(color: Colors.red)),
            onTap: () => _deleteHabit(context, ref),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

