import 'package:adati/features/habits/habit_repository.dart';
import 'package:adati/core/services/log_helper.dart';
import 'package:adati/core/services/notification_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';

/// Centralized service for managing habit reminders
/// Handles rescheduling, cancellation, and lifecycle management
class ReminderService {
  static HabitRepository? _habitRepository;
  static bool _isRescheduling = false;

  /// Initialize the reminder service with a habit repository
  static void init(HabitRepository habitRepository) {
    _habitRepository = habitRepository;
    Log.info('ReminderService initialized');
  }

  /// Reschedule all active reminders for all habits
  /// This should be called on app startup to ensure reminders are up-to-date
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
      int rescheduledCount = 0;
      int errorCount = 0;

      for (final habit in habits) {
        if (habit.reminderEnabled && habit.reminderTime != null) {
          try {
            // Cancel existing reminders first
            await _cancelRemindersForHabit(habit.id);
            
            // Reschedule with new occurrences
            await _scheduleRemindersForHabit(
              habit.id,
              habit.name,
              habit.reminderTime!,
            );
            rescheduledCount++;
          } catch (e, stackTrace) {
            Log.error(
              'Failed to reschedule reminders for habit ${habit.id}',
              error: e,
              stackTrace: stackTrace,
            );
            errorCount++;
          }
        }
      }

      Log.info(
        'Rescheduled reminders: $rescheduledCount successful, $errorCount errors',
      );
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

  /// Reschedule reminders for a specific habit
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

      if (!habit.reminderEnabled || habit.reminderTime == null) {
        Log.info('Habit $habitId does not have reminders enabled, cancelling any existing reminders');
        await _cancelRemindersForHabit(habitId);
        return;
      }

      // Cancel existing reminders first
      await _cancelRemindersForHabit(habitId);

      // Reschedule with new occurrences
      await _scheduleRemindersForHabit(
        habitId,
        habit.name,
        habit.reminderTime!,
      );

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
  static Future<void> cancelRemindersForHabit(int habitId) async {
    await _cancelRemindersForHabit(habitId);
  }

  /// Internal method to cancel reminders for a habit
  static Future<void> _cancelRemindersForHabit(int habitId) async {
    try {
      // Cancel all reminders for this habit
      // Since we use habitId * 10000 + occurrenceIndex, we need to cancel a range
      for (int i = 0; i < 10000; i++) {
        try {
          await NotificationService.cancelNotification(habitId * 10000 + i);
        } catch (e) {
          // Some IDs might not exist, continue
        }
      }

      // Also cancel old format IDs for backward compatibility
      await NotificationService.cancelNotification(habitId);
      for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
        await NotificationService.cancelNotification(habitId * 100 + dayOfWeek);
      }
      for (int dayOfMonth = 1; dayOfMonth <= 31; dayOfMonth++) {
        await NotificationService.cancelNotification(habitId * 1000 + dayOfMonth);
      }

      Log.info('Cancelled all reminders for habit $habitId');
    } catch (e, stackTrace) {
      Log.error(
        'Failed to cancel reminders for habit $habitId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Internal method to schedule reminders for a habit
  /// This mirrors the logic from HabitRepository._scheduleReminders
  static Future<void> _scheduleRemindersForHabit(
    int habitId,
    String habitName,
    String reminderTimeJson,
  ) async {
    try {
      final reminderData = jsonDecode(reminderTimeJson) as Map<String, dynamic>;
      final frequency = reminderData['frequency'] as String? ?? 'daily';
      final days = (reminderData['days'] as List<dynamic>?)?.cast<int>() ?? [];
      final timeStr = reminderData['time'] as String? ?? '09:00';

      final timeParts = timeStr.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 9;
      final minute = int.tryParse(timeParts[1]) ?? 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (frequency == 'daily') {
        // Schedule next 90 daily occurrences
        var scheduledDate = DateTime(today.year, today.month, today.day, hour, minute);
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        int scheduledCount = 0;
        for (int i = 0; i < 90; i++) {
          final occurrenceDate = scheduledDate.add(Duration(days: i));
          final notificationId = habitId * 10000 + i;

          try {
            await NotificationService.scheduleNotification(
              id: notificationId,
              title: 'reminder_title'.tr(namedArgs: {'habit': habitName}),
              body: 'reminder_body'.tr(namedArgs: {'habit': habitName}),
              scheduledDate: occurrenceDate,
              payload: habitId.toString(),
            );
            scheduledCount++;
          } catch (e, stackTrace) {
            Log.error(
              'Failed to schedule daily reminder occurrence $i for habit $habitId',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
        Log.info('Scheduled $scheduledCount daily reminders for habit $habitId');
      } else if (frequency == 'weekly' && days.isNotEmpty) {
        // Schedule next 12-13 weekly occurrences
        int scheduledCount = 0;
        int occurrenceIndex = 0;

        for (int week = 0; week < 13; week++) {
          for (final dayOfWeek in days) {
            final targetDate = today.add(Duration(days: week * 7));
            final currentWeekday = targetDate.weekday;
            final daysUntilTarget = (dayOfWeek - currentWeekday) % 7;
            final scheduledDate = targetDate.add(
              Duration(
                days: daysUntilTarget == 0 && week == 0
                    ? (now.hour * 60 + now.minute >= hour * 60 + minute ? 7 : 0)
                    : (daysUntilTarget == 0 ? 7 : daysUntilTarget),
              ),
            );

            final scheduledDateTime = DateTime(
              scheduledDate.year,
              scheduledDate.month,
              scheduledDate.day,
              hour,
              minute,
            );

            if (scheduledDateTime.isBefore(now)) {
              continue;
            }

            final notificationId = habitId * 10000 + occurrenceIndex;
            occurrenceIndex++;

            try {
              await NotificationService.scheduleNotification(
                id: notificationId,
                title: 'reminder_title'.tr(namedArgs: {'habit': habitName}),
                body: 'reminder_body'.tr(namedArgs: {'habit': habitName}),
                scheduledDate: scheduledDateTime,
                payload: habitId.toString(),
              );
              scheduledCount++;
            } catch (e, stackTrace) {
              Log.error(
                'Failed to schedule weekly reminder occurrence for habit $habitId',
                error: e,
                stackTrace: stackTrace,
              );
            }
          }
        }
        Log.info('Scheduled $scheduledCount weekly reminders for habit $habitId');
      } else if (frequency == 'monthly' && days.isNotEmpty) {
        // Schedule next 12 monthly occurrences
        int scheduledCount = 0;
        int occurrenceIndex = 0;

        for (int monthOffset = 0; monthOffset < 12; monthOffset++) {
          for (final dayOfMonth in days) {
            try {
              final targetMonth = now.month + monthOffset;
              final targetYear = now.year + (targetMonth > 12 ? 1 : 0);
              final adjustedMonth = targetMonth > 12 ? targetMonth - 12 : targetMonth;

              DateTime scheduledDate;
              try {
                scheduledDate = DateTime(targetYear, adjustedMonth, dayOfMonth, hour, minute);
              } catch (e) {
                final lastDay = DateTime(targetYear, adjustedMonth + 1, 0).day;
                scheduledDate = DateTime(targetYear, adjustedMonth, lastDay, hour, minute);
              }

              if (monthOffset == 0 && scheduledDate.isBefore(now)) {
                continue;
              }

              final notificationId = habitId * 10000 + occurrenceIndex;
              occurrenceIndex++;

              await NotificationService.scheduleNotification(
                id: notificationId,
                title: 'reminder_title'.tr(namedArgs: {'habit': habitName}),
                body: 'reminder_body'.tr(namedArgs: {'habit': habitName}),
                scheduledDate: scheduledDate,
                payload: habitId.toString(),
              );
              scheduledCount++;
            } catch (e, stackTrace) {
              Log.error(
                'Failed to schedule monthly reminder occurrence for habit $habitId',
                error: e,
                stackTrace: stackTrace,
              );
            }
          }
        }
        Log.info('Scheduled $scheduledCount monthly reminders for habit $habitId');
      }
    } catch (e, stackTrace) {
      Log.error(
        'Failed to schedule reminders for habit $habitId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

