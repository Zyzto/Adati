import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/habit.dart';
import '../providers/habit_providers.dart';

class HabitManagementMenu extends ConsumerWidget {
  final Habit habit;

  const HabitManagementMenu({super.key, required this.habit});

  Future<void> _deleteHabit(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = ref.read(habitRepositoryProvider);
      await repository.deleteHabit(habit.id!);
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
            title: const Text('Edit Habit'),
            onTap: () {
              Navigator.pop(context);
              context.push('/habits/${habit.id}/edit');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Habit', style: TextStyle(color: Colors.red)),
            onTap: () => _deleteHabit(context, ref),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

