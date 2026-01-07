import 'package:adati/features/habits/habit_repository.dart';
import 'package:adati/core/services/log_helper.dart';
import 'package:adati/core/services/platform_utils.dart';
import 'package:adati/core/services/reminder_data.dart';
import 'package:adati/core/services/notification_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:easy_localization/easy_localization.dart';

/// Centralized service for managing habit reminders
///
/// **Platform-specific behavior:**
/// - **Android**: Uses precise scheduled notifications (exact alarms) + WorkManager as fallback
/// - **iOS**: Uses precise scheduled notifications + Background Fetch (system-scheduled)
/// - **Desktop**: Uses app-level periodic checks (when app is open)
///
/// **Precise Notifications:**
/// - Notifications are scheduled to show at the exact minute set by the user
/// - Uses `AndroidScheduleMode.exactAllowWhileIdle` on Android (requires SCHEDULE_EXACT_ALARM permission)
/// - Uses scheduled notifications on iOS (native support for exact timing)
/// - WorkManager/Background Fetch acts as a fallback to catch any missed notifications
class ReminderService {
  static HabitRepository? _habitRepository;
  static bool _isRescheduling = false;
  static const String _reminderTaskName = 'checkReminders';
  static const int _maxScheduledDays = 30; // Schedule up to 30 days ahead

  /// Initialize the reminder service with a habit repository
  static void init(HabitRepository habitRepository) {
    _habitRepository = habitRepository;
    Log.info('ReminderService initialized');
  }

  /// Reschedule all active reminders for all habits
  ///
  /// **Platform behavior:**
  /// - **Android**: Schedules precise notifications + registers WorkManager periodic task (15 min)
  /// - **iOS**: Schedules precise notifications + registers Background Fetch task
  /// - **Desktop**: Does nothing (handled by app-level periodic checks)
  static Future<void> rescheduleAllReminders() async {
    if (_habitRepository == null) {
      Log.warning('ReminderService not initialized, cannot reschedule reminders');
      return;
    }

    if (_isRescheduling) {
      Log.info('Reminder rescheduling already in progress, skipping');
      return;
    }

    _isRescheduling = true;
    Log.info('Starting to reschedule all reminders');

    try {
      final habits = await _habitRepository!.getAllHabits();
      final habitsWithReminders = habits.where((h) {
        if (!h.reminderEnabled) return false;
        if (h.reminderTime == null || h.reminderTime!.isEmpty) return false;
        final reminderData = ReminderDataValidator.parseAndValidate(h.reminderTime);
        return reminderData != null;
      }).toList();

      if (kIsWeb || isDesktop) {
        // Desktop: Do nothing - handled by app-level periodic checks
        Log.info(
          'Desktop platform: Reminders will be checked by app-level periodic timer (when app is open)',
        );
        _isRescheduling = false;
        return;
      }

      // Mobile platforms: Schedule precise notifications + register background task
      if (habitsWithReminders.isEmpty) {
        Log.info('No habits with reminders enabled, skipping notification scheduling');
        // Cancel any existing WorkManager task
        try {
          await Workmanager().cancelByUniqueName(_reminderTaskName);
          Log.info('Cancelled existing WorkManager task (no reminders to schedule)');
        } catch (e) {
          // Ignore errors when cancelling non-existent tasks
        }
        _isRescheduling = false;
        return;
      }

      Log.info(
        'Found ${habitsWithReminders.length} habits with reminders enabled. '
        'Scheduling precise notifications...',
      );

      int scheduledCount = 0;
      int failedCount = 0;

      // Schedule precise notifications for each habit
      for (final habit in habitsWithReminders) {
        try {
          // Cancel existing notifications for this habit
          await NotificationService.cancelScheduledNotification(habit.id);

          final reminderData = ReminderDataValidator.parseAndValidate(habit.reminderTime!);
          if (reminderData == null) {
            Log.warning('Invalid reminder data for habit ${habit.id}, skipping');
            failedCount++;
            continue;
          }

          // Get next occurrences
          final occurrences = reminderData.getNextOccurrences(maxDays: _maxScheduledDays);

          if (occurrences.isEmpty) {
            Log.warning(
              'No future occurrences found for habit ${habit.id} (${habit.name}), skipping',
            );
            failedCount++;
            continue;
          }

          // Schedule notifications for each occurrence
          int habitScheduledCount = 0;
          for (int i = 0; i < occurrences.length; i++) {
            final occurrence = occurrences[i];
            
            // Use a unique ID: habitId * 10000 + day offset (0-9999)
            // This prevents collisions between habits and days
            final notificationId = habit.id * 10000 + i;
            
            final scheduled = await NotificationService.schedulePreciseNotification(
              id: notificationId,
              scheduledDate: occurrence,
              title: 'reminder_title'.tr(namedArgs: {'habit': habit.name}),
              body: 'reminder_body'.tr(namedArgs: {'habit': habit.name}),
              payload: habit.id.toString(),
            );

            if (scheduled) {
              habitScheduledCount++;
            }
          }

          if (habitScheduledCount > 0) {
            scheduledCount++;
            Log.info(
              'Scheduled $habitScheduledCount precise notifications for habit ${habit.id} (${habit.name})',
            );
          } else {
            failedCount++;
            Log.warning(
              'Failed to schedule any notifications for habit ${habit.id} (${habit.name})',
            );
          }
        } catch (e, stackTrace) {
          Log.error(
            'Failed to schedule notifications for habit ${habit.id}',
            error: e,
            stackTrace: stackTrace,
          );
          failedCount++;
        }
      }

      Log.info(
        'Precise notification scheduling complete: '
        '$scheduledCount habits scheduled successfully, $failedCount failed',
      );

      // Register WorkManager/Background Fetch as fallback
      await _registerBackgroundTask();

      Log.info('Rescheduled reminders successfully');
    } catch (e, stackTrace) {
      Log.error(
        'Failed to reschedule all reminders',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isRescheduling = false;
    }
  }

  /// Register background task (WorkManager on Android, Background Fetch on iOS)
  static Future<void> _registerBackgroundTask() async {
    try {
      // Cancel existing task
      await Workmanager().cancelByUniqueName(_reminderTaskName);

      if (isAndroid) {
        // Android: Register periodic task (minimum 15 minutes)
        await Workmanager().registerPeriodicTask(
          _reminderTaskName,
          _reminderTaskName,
          frequency: Duration(minutes: 15),
          constraints: Constraints(
            networkType: NetworkType.notRequired,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false,
          ),
        );
        Log.info(
          'Android: Registered WorkManager periodic task (every 15 minutes) '
          'as fallback for missed notifications',
        );
      } else if (isIOS) {
        // iOS: Register one-off task that reschedules itself
        // Note: iOS doesn't support periodic tasks, but we can register a one-off
        // that will be executed by the system's Background Fetch (timing is system-controlled)
        await Workmanager().registerOneOffTask(
          _reminderTaskName,
          _reminderTaskName,
          initialDelay: Duration(minutes: 15),
          constraints: Constraints(
            networkType: NetworkType.notRequired,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false,
          ),
        );
        Log.info(
          'iOS: Registered Background Fetch task (system-controlled timing, typically every few hours) '
          'as fallback for missed notifications. '
          'Note: iOS Background Fetch timing is controlled by the system based on usage patterns.',
        );
      }
    } catch (e, stackTrace) {
      Log.error(
        'Failed to register background task',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Reschedule reminders for a specific habit
  /// This will reschedule all reminders to ensure consistency
  static Future<void> rescheduleRemindersForHabit(int habitId) async {
    if (_habitRepository == null) {
      Log.warning('ReminderService not initialized, cannot reschedule reminders');
      return;
    }

    try {
      final habit = await _habitRepository!.getHabitById(habitId);
      if (habit == null) {
        Log.warning('Habit $habitId not found, cannot reschedule reminders');
        return;
      }

      if (kIsWeb || isDesktop) {
        Log.info('Desktop platform: Reminders will be checked by app-level periodic timer');
        return;
      }

      // Reschedule all reminders to ensure consistency
      // This is more reliable than trying to reschedule just one habit
      await rescheduleAllReminders();

      Log.info('Rescheduled reminders for habit $habitId');
    } catch (e, stackTrace) {
      Log.error(
        'Failed to reschedule reminders for habit $habitId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Cancel all reminders for a specific habit
  /// Cancels all scheduled notifications for this habit
  static Future<void> cancelRemindersForHabit(int habitId) async {
    if (kIsWeb || isDesktop) {
      Log.info('Desktop platform: Reminders are checked by app-level timer, no cancellation needed');
      return;
    }

    try {
      // Cancel all scheduled notifications for this habit
      // We use a range of IDs: habitId * 10000 + index (0-9999)
      for (int i = 0; i < 10000; i++) {
        await NotificationService.cancelScheduledNotification(habitId * 10000 + i);
      }

      Log.info('Cancelled all scheduled notifications for habit $habitId');

      // Reschedule all reminders to update the background task if needed
      await rescheduleAllReminders();
    } catch (e, stackTrace) {
      Log.error(
        'Failed to cancel reminders for habit $habitId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
