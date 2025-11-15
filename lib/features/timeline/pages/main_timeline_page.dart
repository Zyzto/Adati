import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/timeline_stats.dart';
import '../../habits/widgets/habits_section.dart';
import '../../habits/providers/habit_providers.dart';
import '../../habits/widgets/habit_form_modal.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/services/demo_data_service.dart';

class MainTimelinePage extends ConsumerWidget {
  const MainTimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final hasDemoDataAsync = ref.watch(hasDemoDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('timeline'.tr()),
        actions: [
          // Delete demo data button (only visible when demo data exists)
          hasDemoDataAsync.when(
            data: (hasDemo) {
              if (hasDemo) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'delete_demo_data'.tr(),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('delete_demo_data'.tr()),
                        content: Text('delete_demo_data_confirmation'.tr()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('cancel'.tr()),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('delete'.tr()),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final repository = ref.read(habitRepositoryProvider);
                      await DemoDataService.deleteDemoData(repository);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('demo_data_deleted'.tr())),
                        );
                      }
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            // Show unified empty state
            final theme = Theme.of(context);
            return EmptyStateWidget(
              icon: Icons.timeline,
              title: 'no_habits_title'.tr(),
              message: 'no_habits_message'.tr(),
              actions: [
                FilledButton.icon(
                  onPressed: () => HabitFormModal.show(context),
                  icon: const Icon(Icons.add, size: 24),
                  label: Text(
                    'create_habit'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            );
          }

          // Show normal layout when habits exist
          return const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [TimelineStats(), CalendarGrid(), HabitsSection()],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${'error'.tr()}: $error')),
      ),
    );
  }
}
