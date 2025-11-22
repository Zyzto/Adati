import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/preferences_service.dart';
import '../../../habits/providers/habit_providers.dart';
import '../responsive_dialog.dart';

/// Static dialog methods for Advanced section (reset, clear, logs, onboarding)
class AdvancedDialogs {
  /// Show reset all habits confirmation dialog
  static Future<void> showResetHabitsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('reset_all_habits'.tr()),
        content: Text('reset_all_habits_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('reset'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(habitRepositoryProvider);
        final habits = await repository.getAllHabits();
        
        for (final habit in habits) {
          await repository.deleteHabit(habit.id);
        }
        
        ref.invalidate(habitRepositoryProvider);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('habits_reset_success'.tr())),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'error'.tr()}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Show reset all settings confirmation dialog
  static Future<void> showResetSettingsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('reset_all_settings'.tr()),
        content: Text('reset_all_settings_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('reset'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await PreferencesService.clear();
        await PreferencesService.init();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('settings_reset_success'.tr())),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('settings_reset_failed'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Show clear all data confirmation dialog
  static Future<void> showClearAllDataDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('clear_all_data'.tr()),
        content: Text('clear_all_data_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('clear'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(habitRepositoryProvider);
        final habits = await repository.getAllHabits();
        
        for (final habit in habits) {
          await repository.deleteHabit(habit.id);
        }
        
        await PreferencesService.clear();
        await PreferencesService.init();
        
        ref.invalidate(habitRepositoryProvider);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('all_data_cleared_success'.tr())),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'error'.tr()}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Show logs dialog
  static Future<void> showLogsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Implementation for logs dialog
    // This would need access to LoggingService methods
    // Placeholder for now
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('logs'.tr()),
        content: Text('Logs dialog implementation'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  /// Return to onboarding screen
  static Future<void> returnToOnboarding(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('return_to_onboarding'.tr()),
        content: Text('return_to_onboarding_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('continue'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await PreferencesService.setFirstLaunch(true);
      if (context.mounted) {
        context.go('/onboarding');
      }
    }
  }

  /// Optimize database
  static Future<void> optimizeDatabase(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('optimize_database'.tr()),
        content: Text('optimize_database_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('optimize'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(habitRepositoryProvider);
        await repository.vacuumDatabase();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('database_optimized_success'.tr())),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'error'.tr()}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

