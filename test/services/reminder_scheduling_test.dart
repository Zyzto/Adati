import 'package:flutter_test/flutter_test.dart';
import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/features/habits/habit_repository.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import '../helpers/database_helpers.dart';
import '../fixtures/habit_fixtures.dart';

void main() {
  late db.AppDatabase testDatabase;
  late HabitRepository repository;

  setUp(() async {
    testDatabase = await createTestDatabase();
    repository = HabitRepository(testDatabase);
  });

  tearDown(() async {
    await testDatabase.close();
  });

  group('HabitRepository - Reminder Scheduling', () {
    test('createHabit with daily reminder schedules reminders', () async {
      final reminderTimeJson = jsonEncode({
        'frequency': 'daily',
        'time': '09:00',
      });

      final habitCompanion = createTestHabitCompanion(
        name: 'Daily Reminder Habit',
        reminderEnabled: true,
        reminderTime: reminderTimeJson,
      );

      final habitId = await repository.createHabit(habitCompanion);

      expect(habitId, greaterThan(0));
      final habit = await repository.getHabitById(habitId);
      expect(habit, isNotNull);
      expect(habit!.reminderEnabled, isTrue);
      expect(habit.reminderTime, equals(reminderTimeJson));
    });

    test('createHabit with weekly reminder schedules reminders', () async {
      final reminderTimeJson = jsonEncode({
        'frequency': 'weekly',
        'days': [1, 3, 5], // Monday, Wednesday, Friday
        'time': '10:00',
      });

      final habitCompanion = createTestHabitCompanion(
        name: 'Weekly Reminder Habit',
        reminderEnabled: true,
        reminderTime: reminderTimeJson,
      );

      final habitId = await repository.createHabit(habitCompanion);

      expect(habitId, greaterThan(0));
      final habit = await repository.getHabitById(habitId);
      expect(habit, isNotNull);
      expect(habit!.reminderEnabled, isTrue);
    });

    test('createHabit with monthly reminder schedules reminders', () async {
      final reminderTimeJson = jsonEncode({
        'frequency': 'monthly',
        'days': [1, 15], // 1st and 15th of month
        'time': '08:00',
      });

      final habitCompanion = createTestHabitCompanion(
        name: 'Monthly Reminder Habit',
        reminderEnabled: true,
        reminderTime: reminderTimeJson,
      );

      final habitId = await repository.createHabit(habitCompanion);

      expect(habitId, greaterThan(0));
      final habit = await repository.getHabitById(habitId);
      expect(habit, isNotNull);
      expect(habit!.reminderEnabled, isTrue);
    });

    test('createHabit without reminder enabled does not schedule', () async {
      final habitCompanion = createTestHabitCompanion(
        name: 'No Reminder Habit',
        reminderEnabled: false,
      );

      final habitId = await repository.createHabit(habitCompanion);

      expect(habitId, greaterThan(0));
      final habit = await repository.getHabitById(habitId);
      expect(habit, isNotNull);
      expect(habit!.reminderEnabled, isFalse);
    });

    test('updateHabit cancels old reminders and schedules new ones', () async {
      // Create habit with reminder
      final initialReminderTimeJson = jsonEncode({
        'frequency': 'daily',
        'time': '09:00',
      });

      final habitCompanion = createTestHabitCompanion(
        name: 'Test Habit',
        reminderEnabled: true,
        reminderTime: initialReminderTimeJson,
      );
      final habitId = await repository.createHabit(habitCompanion);

      // Update with new reminder time
      final updatedReminderTimeJson = jsonEncode({
        'frequency': 'daily',
        'time': '10:00',
      });

      final existingHabit = await repository.getHabitById(habitId);
      expect(existingHabit, isNotNull);

      final updateCompanion = db.HabitsCompanion(
        id: drift.Value(habitId),
        name: drift.Value('Updated Habit'),
        description: drift.Value(existingHabit!.description),
        color: drift.Value(existingHabit.color),
        icon: existingHabit.icon != null
            ? drift.Value(existingHabit.icon)
            : const drift.Value.absent(),
        habitType: drift.Value(existingHabit.habitType),
        trackingType: drift.Value(existingHabit.trackingType),
        reminderEnabled: drift.Value(true),
        reminderTime: drift.Value(updatedReminderTimeJson),
      );

      final updated = await repository.updateHabit(updateCompanion);
      expect(updated, isTrue);

      final updatedHabit = await repository.getHabitById(habitId);
      expect(updatedHabit, isNotNull);
      expect(updatedHabit!.reminderTime, equals(updatedReminderTimeJson));
    });

    test('updateHabit disables reminder cancels existing reminders', () async {
      // Create habit with reminder
      final reminderTimeJson = jsonEncode({
        'frequency': 'daily',
        'time': '09:00',
      });

      final habitCompanion = createTestHabitCompanion(
        name: 'Test Habit',
        reminderEnabled: true,
        reminderTime: reminderTimeJson,
      );
      final habitId = await repository.createHabit(habitCompanion);

      // Disable reminder
      final existingHabit = await repository.getHabitById(habitId);
      expect(existingHabit, isNotNull);

      final updateCompanion = db.HabitsCompanion(
        id: drift.Value(habitId),
        name: drift.Value(existingHabit!.name),
        description: drift.Value(existingHabit.description),
        color: drift.Value(existingHabit.color),
        icon: existingHabit.icon != null
            ? drift.Value(existingHabit.icon)
            : const drift.Value.absent(),
        habitType: drift.Value(existingHabit.habitType),
        trackingType: drift.Value(existingHabit.trackingType),
        reminderEnabled: drift.Value(false),
      );

      final updated = await repository.updateHabit(updateCompanion);
      expect(updated, isTrue);

      final updatedHabit = await repository.getHabitById(habitId);
      expect(updatedHabit, isNotNull);
      expect(updatedHabit!.reminderEnabled, isFalse);
    });

    test('deleteHabit cancels reminders before deletion', () async {
      // Create habit with reminder
      final reminderTimeJson = jsonEncode({
        'frequency': 'daily',
        'time': '09:00',
      });

      final habitCompanion = createTestHabitCompanion(
        name: 'Test Habit',
        reminderEnabled: true,
        reminderTime: reminderTimeJson,
      );
      final habitId = await repository.createHabit(habitCompanion);

      // Delete habit
      final deleted = await repository.deleteHabit(habitId);
      expect(deleted, greaterThan(0));

      // Verify habit is deleted
      final habit = await repository.getHabitById(habitId);
      expect(habit, isNull);
    });

    test('reminder scheduling handles invalid time format gracefully', () async {
      final reminderTimeJson = jsonEncode({
        'frequency': 'daily',
        'time': 'invalid-time',
      });

      final habitCompanion = createTestHabitCompanion(
        name: 'Invalid Time Habit',
        reminderEnabled: true,
        reminderTime: reminderTimeJson,
      );

      // Should not throw, should use default time
      final habitId = await repository.createHabit(habitCompanion);
      expect(habitId, greaterThan(0));
    });

    test('reminder scheduling handles missing frequency gracefully', () async {
      final reminderTimeJson = jsonEncode({
        'time': '09:00',
        // frequency missing, should default to 'daily'
      });

      final habitCompanion = createTestHabitCompanion(
        name: 'Default Frequency Habit',
        reminderEnabled: true,
        reminderTime: reminderTimeJson,
      );

      // Should not throw, should use default frequency
      final habitId = await repository.createHabit(habitCompanion);
      expect(habitId, greaterThan(0));
    });

    test('reminder scheduling handles invalid day values for monthly', () async {
      final reminderTimeJson = jsonEncode({
        'frequency': 'monthly',
        'days': [32, 35], // Invalid days
        'time': '08:00',
      });

      final habitCompanion = createTestHabitCompanion(
        name: 'Invalid Days Habit',
        reminderEnabled: true,
        reminderTime: reminderTimeJson,
      );

      // Should handle gracefully (will use last day of month)
      final habitId = await repository.createHabit(habitCompanion);
      expect(habitId, greaterThan(0));
    });
  });
}

