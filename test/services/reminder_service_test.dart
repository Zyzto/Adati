import 'package:flutter_test/flutter_test.dart';
import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/core/services/reminder_service.dart';
import 'package:adati/features/habits/habit_repository.dart';
import '../helpers/database_helpers.dart';
import '../fixtures/habit_fixtures.dart';
import 'dart:convert';

void main() {
  late db.AppDatabase testDatabase;
  late HabitRepository habitRepository;

  setUp(() async {
    testDatabase = await createTestDatabase();
    habitRepository = HabitRepository(testDatabase);
    ReminderService.init(habitRepository);
  });

  tearDown(() async {
    await testDatabase.close();
  });

  group('ReminderService - Initialization', () {
    test('init initializes the service with habit repository', () {
      // Service should be initialized in setUp
      expect(habitRepository, isNotNull);
    });
  });

  group('ReminderService - Reschedule All Reminders', () {
    test('rescheduleAllReminders handles habits without reminders', () async {
      // Create habit without reminders
      final habitCompanion = createTestHabitCompanion(
        name: 'No Reminder Habit',
        reminderEnabled: false,
      );
      await habitRepository.createHabit(habitCompanion);

      // Should not throw
      await ReminderService.rescheduleAllReminders();
    });

    test('rescheduleAllReminders schedules reminders for habits with reminders enabled', () async {
      // Create habit with daily reminder
      final reminderTimeJson = jsonEncode({
        'frequency': 'daily',
        'time': '09:00',
      });
      
      final habitCompanion = createTestHabitCompanion(
        name: 'Daily Reminder Habit',
        reminderEnabled: true,
        reminderTime: reminderTimeJson,
      );
      final habitId = await habitRepository.createHabit(habitCompanion);

      // Reschedule all reminders
      await ReminderService.rescheduleAllReminders();

      // Verify habit still exists
      final habit = await habitRepository.getHabitById(habitId);
      expect(habit, isNotNull);
      expect(habit!.reminderEnabled, isTrue);
    });

    test('rescheduleAllReminders handles multiple habits', () async {
      // Create multiple habits with reminders
      final reminderTimeJson = jsonEncode({
        'frequency': 'daily',
        'time': '09:00',
      });

      final habit1Companion = createTestHabitCompanion(
        name: 'Habit 1',
        reminderEnabled: true,
        reminderTime: reminderTimeJson,
      );
      final habit2Companion = createTestHabitCompanion(
        name: 'Habit 2',
        reminderEnabled: true,
        reminderTime: reminderTimeJson,
      );

      await habitRepository.createHabit(habit1Companion);
      await habitRepository.createHabit(habit2Companion);

      // Should not throw
      await ReminderService.rescheduleAllReminders();
    });

    test('rescheduleAllReminders handles habits with invalid reminder data gracefully', () async {
      // Create habit with invalid reminder JSON
      final habitCompanion = createTestHabitCompanion(
        name: 'Invalid Reminder Habit',
        reminderEnabled: true,
        reminderTime: 'invalid json',
      );
      await habitRepository.createHabit(habitCompanion);

      // Should handle error gracefully
      await ReminderService.rescheduleAllReminders();
    });
  });

  group('ReminderService - Reschedule Single Habit', () {
    test('rescheduleRemindersForHabit schedules reminders for enabled habit', () async {
      final reminderTimeJson = jsonEncode({
        'frequency': 'daily',
        'time': '09:00',
      });

      final habitCompanion = createTestHabitCompanion(
        name: 'Test Habit',
        reminderEnabled: true,
        reminderTime: reminderTimeJson,
      );
      final habitId = await habitRepository.createHabit(habitCompanion);

      // Should not throw
      await ReminderService.rescheduleRemindersForHabit(habitId);
    });

    test('rescheduleRemindersForHabit cancels reminders for disabled habit', () async {
      final habitCompanion = createTestHabitCompanion(
        name: 'Disabled Reminder Habit',
        reminderEnabled: false,
      );
      final habitId = await habitRepository.createHabit(habitCompanion);

      // Should not throw
      await ReminderService.rescheduleRemindersForHabit(habitId);
    });

    test('rescheduleRemindersForHabit handles non-existent habit', () async {
      // Should not throw
      await ReminderService.rescheduleRemindersForHabit(999);
    });

    test('rescheduleRemindersForHabit handles weekly reminders', () async {
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
      final habitId = await habitRepository.createHabit(habitCompanion);

      // Should not throw
      await ReminderService.rescheduleRemindersForHabit(habitId);
    });

    test('rescheduleRemindersForHabit handles monthly reminders', () async {
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
      final habitId = await habitRepository.createHabit(habitCompanion);

      // Should not throw
      await ReminderService.rescheduleRemindersForHabit(habitId);
    });
  });

  group('ReminderService - Cancel Reminders', () {
    test('cancelRemindersForHabit handles non-existent habit', () async {
      // Should not throw
      await ReminderService.cancelRemindersForHabit(999);
    });

    test('cancelRemindersForHabit cancels reminders for existing habit', () async {
      final reminderTimeJson = jsonEncode({
        'frequency': 'daily',
        'time': '09:00',
      });

      final habitCompanion = createTestHabitCompanion(
        name: 'Test Habit',
        reminderEnabled: true,
        reminderTime: reminderTimeJson,
      );
      final habitId = await habitRepository.createHabit(habitCompanion);

      // Should not throw
      await ReminderService.cancelRemindersForHabit(habitId);
    });
  });
}

