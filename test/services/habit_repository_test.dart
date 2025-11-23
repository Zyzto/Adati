import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/core/database/models/tracking_types.dart';
import 'package:adati/core/utils/date_utils.dart' as date_utils;
import 'package:adati/features/habits/habit_repository.dart';
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

  group('HabitRepository - CRUD Operations', () {
    test('createHabit creates a new habit', () async {
      final habitCompanion = createTestHabitCompanion(
        name: 'Exercise',
        habitType: HabitType.good,
      );

      final habitId = await repository.createHabit(habitCompanion);

      expect(habitId, greaterThan(0));

      final createdHabit = await repository.getHabitById(habitId);
      expect(createdHabit, isNotNull);
      expect(createdHabit!.name, equals('Exercise'));
      expect(createdHabit.habitType, equals(HabitType.good.value));
    });

    test('getHabitById returns the correct habit', () async {
      final habitCompanion = createTestHabitCompanion(name: 'Read Books');
      final habitId = await repository.createHabit(habitCompanion);

      final habit = await repository.getHabitById(habitId);

      expect(habit, isNotNull);
      expect(habit!.name, equals('Read Books'));
    });

    test('getHabitById returns null for non-existent habit', () async {
      final habit = await repository.getHabitById(999);

      expect(habit, isNull);
    });

    test('getAllHabits returns all habits', () async {
      await repository.createHabit(createTestHabitCompanion(name: 'Habit 1'));
      await repository.createHabit(createTestHabitCompanion(name: 'Habit 2'));
      await repository.createHabit(createTestHabitCompanion(name: 'Habit 3'));

      final habits = await repository.getAllHabits();

      expect(habits.length, equals(3));
    });

    test('updateHabit updates habit properties', () async {
      final habitCompanion = createTestHabitCompanion(name: 'Original Name');
      final habitId = await repository.createHabit(habitCompanion);

      // Get the existing habit to preserve all fields
      final existingHabit = await repository.getHabitById(habitId);
      expect(existingHabit, isNotNull);

      // Create update companion with all required fields
      final updateCompanion = db.HabitsCompanion(
        id: drift.Value(habitId),
        name: drift.Value('Updated Name'),
        description: drift.Value(existingHabit!.description),
        color: drift.Value(existingHabit.color),
        icon: existingHabit.icon != null
            ? drift.Value(existingHabit.icon)
            : const drift.Value.absent(),
        habitType: drift.Value(existingHabit.habitType),
        trackingType: drift.Value(existingHabit.trackingType),
        unit: existingHabit.unit != null
            ? drift.Value(existingHabit.unit)
            : const drift.Value.absent(),
        goalValue: existingHabit.goalValue != null
            ? drift.Value(existingHabit.goalValue)
            : const drift.Value.absent(),
        goalPeriod: existingHabit.goalPeriod != null
            ? drift.Value(existingHabit.goalPeriod)
            : const drift.Value.absent(),
        occurrenceNames: existingHabit.occurrenceNames != null
            ? drift.Value(existingHabit.occurrenceNames)
            : const drift.Value.absent(),
        reminderEnabled: drift.Value(existingHabit.reminderEnabled),
        reminderTime: existingHabit.reminderTime != null
            ? drift.Value(existingHabit.reminderTime)
            : const drift.Value.absent(),
        createdAt: drift.Value(existingHabit.createdAt),
        updatedAt: drift.Value(DateTime.now()),
      );

      final success = await repository.updateHabit(updateCompanion);

      expect(success, isTrue);

      final updatedHabit = await repository.getHabitById(habitId);
      expect(updatedHabit!.name, equals('Updated Name'));
    });

    test('deleteHabit removes the habit', () async {
      final habitCompanion = createTestHabitCompanion(name: 'To Delete');
      final habitId = await repository.createHabit(habitCompanion);

      await repository.deleteHabit(habitId);

      final deletedHabit = await repository.getHabitById(habitId);
      expect(deletedHabit, isNull);
    });
  });

  group('HabitRepository - Tracking Entries', () {
    late int habitId;

    setUp(() async {
      final habitCompanion = createTestHabitCompanion();
      habitId = await repository.createHabit(habitCompanion);
    });

    test('toggleCompletion creates a new entry', () async {
      final today = date_utils.DateUtils.getToday();
      final success = await repository.toggleCompletion(habitId, today, true);

      expect(success, isTrue);

      final entry = await repository.getEntry(habitId, today);
      expect(entry, isNotNull);
      expect(entry!.completed, isTrue);
    });

    test('toggleCompletion updates existing entry', () async {
      final today = date_utils.DateUtils.getToday();
      await repository.toggleCompletion(habitId, today, true);

      await repository.toggleCompletion(habitId, today, false);

      final entry = await repository.getEntry(habitId, today);
      expect(entry!.completed, isFalse);
    });

    test('getEntriesByHabit returns all entries for a habit', () async {
      final today = date_utils.DateUtils.getToday();
      final yesterday = today.subtract(const Duration(days: 1));

      await repository.toggleCompletion(habitId, today, true);
      await repository.toggleCompletion(habitId, yesterday, false);

      final entries = await repository.getEntriesByHabit(habitId);

      expect(entries.length, equals(2));
    });

    test('getEntriesByDate returns entries for a specific date', () async {
      final today = date_utils.DateUtils.getToday();
      final habitCompanion2 = createTestHabitCompanion(name: 'Habit 2');
      final habitId2 = await repository.createHabit(habitCompanion2);

      await repository.toggleCompletion(habitId, today, true);
      await repository.toggleCompletion(habitId2, today, true);

      final entries = await repository.getEntriesByDate(today);

      expect(entries.length, equals(2));
    });
  });

  group('HabitRepository - Measurable Tracking', () {
    late int habitId;

    setUp(() async {
      final habitCompanion = createTestHabitCompanion(
        name: 'Exercise',
        trackingType: TrackingType.measurable,
        unit: 'minutes',
        goalValue: 30.0,
        goalPeriod: GoalPeriod.daily,
      );
      habitId = await repository.createHabit(habitCompanion);
    });

    test('trackMeasurable creates entry with value', () async {
      final today = date_utils.DateUtils.getToday();
      final success = await repository.trackMeasurable(habitId, today, 45.0);

      expect(success, isTrue);

      final entry = await repository.getEntry(habitId, today);
      expect(entry, isNotNull);
      expect(entry!.value, equals(45.0));
      expect(entry.completed, isTrue); // Should be completed since 45 >= 30
    });

    test('trackMeasurable marks as incomplete when below goal', () async {
      final today = date_utils.DateUtils.getToday();
      await repository.trackMeasurable(habitId, today, 15.0);

      final entry = await repository.getEntry(habitId, today);
      expect(entry!.completed, isFalse); // 15 < 30, so not completed
    });

    test('trackMeasurable for bad habit marks as complete when below limit', () async {
      final badHabitCompanion = createTestHabitCompanion(
        name: 'Smoking',
        habitType: HabitType.bad,
        trackingType: TrackingType.measurable,
        unit: 'cigarettes',
        goalValue: 5.0,
        goalPeriod: GoalPeriod.daily,
      );
      final badHabitId = await repository.createHabit(badHabitCompanion);

      final today = date_utils.DateUtils.getToday();
      await repository.trackMeasurable(badHabitId, today, 3.0);

      final entry = await repository.getEntry(badHabitId, today);
      expect(entry!.completed, isTrue); // 3 <= 5, so completed (stayed under limit)
    });
  });

  group('HabitRepository - Streak Calculations', () {
    test('streak calculation for good habit', () async {
      final habitCompanion = createTestHabitCompanion(
        name: 'Daily Exercise',
        habitType: HabitType.good,
      );
      final habitId = await repository.createHabit(habitCompanion);

      final today = date_utils.DateUtils.getToday();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      // Create consecutive completed entries
      await repository.toggleCompletion(habitId, twoDaysAgo, true);
      await repository.toggleCompletion(habitId, yesterday, true);
      await repository.toggleCompletion(habitId, today, true);

      // Wait for streak to update
      await Future.delayed(const Duration(milliseconds: 100));

      final streak = await repository.getStreakByHabit(habitId);
      expect(streak, isNotNull);
      expect(streak!.combinedStreak, greaterThanOrEqualTo(3));
    });

    test('streak calculation for bad habit (not doing = success)', () async {
      final habitCompanion = createTestHabitCompanion(
        name: 'No Smoking',
        habitType: HabitType.bad,
      );
      final habitId = await repository.createHabit(habitCompanion);

      final today = date_utils.DateUtils.getToday();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      // For bad habits, not marking (completed = false) means success
      // Don't create entries, or create entries with completed = false
      await repository.toggleCompletion(habitId, twoDaysAgo, false);
      await repository.toggleCompletion(habitId, yesterday, false);
      await repository.toggleCompletion(habitId, today, false);

      await Future.delayed(const Duration(milliseconds: 100));

      final streak = await repository.getStreakByHabit(habitId);
      expect(streak, isNotNull);
      expect(streak!.combinedStreak, greaterThanOrEqualTo(3));
    });

    test('streak resets when habit is not completed', () async {
      final habitCompanion = createTestHabitCompanion();
      final habitId = await repository.createHabit(habitCompanion);

      final today = date_utils.DateUtils.getToday();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      await repository.toggleCompletion(habitId, twoDaysAgo, true);
      await repository.toggleCompletion(habitId, yesterday, true);
      // Skip today - streak should reset

      await Future.delayed(const Duration(milliseconds: 100));

      final streak = await repository.getStreakByHabit(habitId);
      // Streak should be 0 since today is not completed
      expect(streak!.combinedStreak, equals(0));
    });
  });

  group('HabitRepository - Creation Date Handling', () {
    test('streak excludes entries before habit creation', () async {
      final creationDate = date_utils.DateUtils.getToday().subtract(
        const Duration(days: 5),
      );
      final habitCompanion = createTestHabitCompanion(
        name: 'New Habit',
        createdAt: creationDate,
      );
      final habitId = await repository.createHabit(habitCompanion);

      final today = date_utils.DateUtils.getToday();
      final yesterday = today.subtract(const Duration(days: 1));
      final beforeCreation = creationDate.subtract(const Duration(days: 1));

      // Try to create entry before creation date (should be ignored in streak)
      await repository.toggleCompletion(habitId, beforeCreation, true);
      await repository.toggleCompletion(habitId, yesterday, true);
      await repository.toggleCompletion(habitId, today, true);

      await Future.delayed(const Duration(milliseconds: 100));

      final streak = await repository.getStreakByHabit(habitId);
      // Streak should only count from creation date onwards
      expect(streak!.combinedStreak, greaterThanOrEqualTo(2));
      // Should not include the entry before creation
    });
  });
}

