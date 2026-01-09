import 'package:flutter/material.dart';
import 'package:adati/features/habits/habit_repository.dart';
import 'package:adati/core/services/log_helper.dart';
import 'package:adati/core/services/notification_service.dart';
import 'package:adati/core/services/reminder_data.dart';
import 'package:easy_localization/easy_localization.dart';

/// Service for checking if reminders are due and showing notifications
/// Used by both WorkManager (mobile) and periodic checks (desktop)
class ReminderChecker {
  /// Check all habits for due reminders and show notifications
  ///
  /// This method:
  /// 1. Loads all habits with reminders enabled
  /// 2. Parses reminder time configuration
  /// 3. Checks if current time matches reminder time (within ±15 minute window)
  /// 4. Shows notifications for matching reminders
  ///
  /// [forceShow] - If true, shows notifications for all habits with reminders enabled
  /// regardless of time window (useful for testing)
  static Future<void> checkAndShowDueReminders(
    HabitRepository repository, {
    bool forceShow = false,
  }) async {
    try {
      final habits = await repository.getAllHabits();
      final now = DateTime.now();
      final currentTime = TimeOfDay.fromDateTime(now);
      final currentWeekday = now.weekday; // 1=Monday, 7=Sunday
      final currentDay = now.day;

      Log.debug(
        'ReminderChecker: Checking reminders at ${currentTime.hour}:${currentTime.minute.toString().padLeft(2, '0')}',
      );

      int checkedCount = 0;
      int dueCount = 0;

      for (final habit in habits) {
        // Check data consistency: if reminderEnabled is true, reminderTime must be valid
        if (!habit.reminderEnabled) {
          // If disabled but reminderTime exists, log warning (data inconsistency)
          if (habit.reminderTime != null && habit.reminderTime!.isNotEmpty) {
            Log.warning(
              'ReminderChecker: Data inconsistency for habit ${habit.id}: '
              'reminderEnabled is false but reminderTime is not null. Skipping.',
            );
          }
          continue;
        }

        // If enabled, reminderTime must be present and valid
        if (habit.reminderTime == null || habit.reminderTime!.isEmpty) {
          Log.error(
            'ReminderChecker: Data inconsistency for habit ${habit.id}: '
            'reminderEnabled is true but reminderTime is null/empty. Skipping.',
          );
          continue;
        }

        checkedCount++;

        try {
          // Parse reminder data using ReminderData model
          final reminderData = ReminderDataValidator.parseAndValidate(
            habit.reminderTime!,
          );

          if (reminderData == null) {
            Log.error(
              'ReminderChecker: Failed to parse reminder data for habit ${habit.id}: ${habit.reminderTime}',
            );
            continue;
          }

          Log.debug(
            'ReminderChecker: Parsed reminder for habit ${habit.id}: $reminderData',
          );

          final frequency = reminderData.frequency;
          final days = reminderData.days;
          final timeStr = reminderData.time;

          // Parse time string
          final timeParts = timeStr.split(':');
          if (timeParts.length != 2) {
            Log.warning('Invalid time format for habit ${habit.id}: $timeStr');
            continue;
          }

          final hour = int.tryParse(timeParts[0]) ?? 9;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          final reminderTime = TimeOfDay(hour: hour, minute: minute);

          Log.debug(
            'ReminderChecker: Habit ${habit.id} (${habit.name}) - reminder time: ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}, frequency: $frequency, days: $days',
          );

          // Check if reminder time matches current time (within ±15 minute window)
          // FIXED: Increased window from ±5 to ±15 minutes to match WorkManager's 15-minute interval
          // This ensures we catch reminders even if WorkManager runs at the edge of its interval
          final currentMinutes = currentTime.hour * 60 + currentTime.minute;
          final reminderMinutes = reminderTime.hour * 60 + reminderTime.minute;
          final timeDifference = currentMinutes - reminderMinutes;

          Log.debug(
            'ReminderChecker: Habit ${habit.id} - current: ${currentTime.hour}:${currentTime.minute.toString().padLeft(2, '0')}, reminder: ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}, difference: $timeDifference minutes',
          );

          // Allow ±15 minute window to match WorkManager's 15-minute interval
          // This ensures we catch reminders even if WorkManager runs at minute 14 before or after
          // Skip time check if forceShow is true (for testing)
          if (!forceShow && timeDifference.abs() > 15) {
            // Not within the 15-minute window
            Log.debug(
              'ReminderChecker: Habit ${habit.id} - not within time window (diff: $timeDifference, window: ±15 min)',
            );
            continue;
          }

          if (forceShow) {
            Log.info(
              'ReminderChecker: Force show enabled - showing notification for habit ${habit.id} regardless of time',
            );
          }

          // Check frequency-specific conditions
          bool shouldShow = false;

          if (frequency == 'daily') {
            shouldShow = true;
            Log.debug(
              'ReminderChecker: Habit ${habit.id} - daily reminder, should show',
            );
          } else if (frequency == 'weekly' && days.isNotEmpty) {
            // Check if current weekday is in the days list
            shouldShow = days.contains(currentWeekday);
            Log.debug(
              'ReminderChecker: Habit ${habit.id} - weekly reminder, current weekday: $currentWeekday, days: $days, should show: $shouldShow',
            );
          } else if (frequency == 'monthly' && days.isNotEmpty) {
            // Check if current day of month is in the days list
            shouldShow = days.contains(currentDay);
            Log.debug(
              'ReminderChecker: Habit ${habit.id} - monthly reminder, current day: $currentDay, days: $days, should show: $shouldShow',
            );
          }

          if (shouldShow) {
            // Show notification
            Log.info(
              'ReminderChecker: Showing notification for habit ${habit.id}: ${habit.name}',
            );

            // Check if notifications are available before trying to show
            if (!NotificationService.isAvailable()) {
              Log.warning(
                'ReminderChecker: Notifications not available - cannot show notification for habit ${habit.id}',
              );
              continue;
            }

            try {
              await NotificationService.showNotification(
                id: habit.id,
                title: 'reminder_title'.tr(namedArgs: {'habit': habit.name}),
                body: 'reminder_body'.tr(namedArgs: {'habit': habit.name}),
                payload: habit.id.toString(),
              );
              dueCount++;
              Log.info(
                'ReminderChecker: Successfully showed reminder notification for habit ${habit.id}: ${habit.name}',
              );
            } catch (e, stackTrace) {
              Log.error(
                'ReminderChecker: Failed to show notification for habit ${habit.id}',
                error: e,
                stackTrace: stackTrace,
              );
            }
          } else {
            Log.debug(
              'ReminderChecker: Habit ${habit.id} - conditions not met, not showing',
            );
          }
        } catch (e, stackTrace) {
          Log.error(
            'Failed to check reminder for habit ${habit.id}',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      Log.info(
        'ReminderChecker: Checked $checkedCount habits for reminders, found $dueCount due reminders',
      );
    } catch (e, stackTrace) {
      Log.error('Failed to check reminders', error: e, stackTrace: stackTrace);
    }
  }
}
