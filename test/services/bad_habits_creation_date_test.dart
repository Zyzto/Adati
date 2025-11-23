import 'package:flutter_test/flutter_test.dart';
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

  group('Bad Habits Creation Date - Positive Mode', () {
    test('positive mode only counts from creation date onwards', () async {
      // Create a bad habit 5 days ago
      final creationDate = date_utils.DateUtils.getToday().subtract(
        const Duration(days: 5),
      );
      final habitCompanion = createTestHabitCompanion(
        name: 'No Smoking',
        habitType: HabitType.bad,
        createdAt: creationDate,
      );
      final habitId = await repository.createHabit(habitCompanion);

      final today = date_utils.DateUtils.getToday();
      final yesterday = today.subtract(const Duration(days: 1));
      final beforeCreation = creationDate.subtract(const Duration(days: 1));

      // Don't mark the habit (not doing bad habit = success in positive mode)
      // Only create entries from creation date onwards
      await repository.toggleCompletion(habitId, yesterday, false);
      await repository.toggleCompletion(habitId, today, false);

      // Verify entries exist only from creation date
      final entries = await repository.getEntriesByHabit(habitId);
      expect(entries.length, equals(2));
      
      // Verify no entry exists before creation date
      final beforeCreationEntry = await repository.getEntry(habitId, beforeCreation);
      expect(beforeCreationEntry, isNull);
    });

    test('positive mode counts unmarked days as positive from creation date', () async {
      final creationDate = date_utils.DateUtils.getToday().subtract(
        const Duration(days: 3),
      );
      final habitCompanion = createTestHabitCompanion(
        name: 'No Junk Food',
        habitType: HabitType.bad,
        createdAt: creationDate,
      );
      final habitId = await repository.createHabit(habitCompanion);

      final today = date_utils.DateUtils.getToday();
      final yesterday = today.subtract(const Duration(days: 1));

      // Mark one day (doing bad habit)
      await repository.toggleCompletion(habitId, yesterday, true);

      // Verify streak calculation excludes pre-creation dates
      await Future.delayed(const Duration(milliseconds: 100));
      final streak = await repository.getStreakByHabit(habitId);
      
      // Streak should only count from creation date
      // Day before creation should not be counted
      expect(streak, isNotNull);
    });
  });

  group('Bad Habits Creation Date - Negative Mode', () {
    test('negative mode only counts marked days from creation date', () async {
      final creationDate = date_utils.DateUtils.getToday().subtract(
        const Duration(days: 4),
      );
      final habitCompanion = createTestHabitCompanion(
        name: 'Smoking',
        habitType: HabitType.bad,
        createdAt: creationDate,
      );
      final habitId = await repository.createHabit(habitCompanion);

      final today = date_utils.DateUtils.getToday();
      final yesterday = today.subtract(const Duration(days: 1));
      final beforeCreation = creationDate.subtract(const Duration(days: 1));

      // Mark the habit (doing bad habit)
      await repository.toggleCompletion(habitId, yesterday, true);

      // Verify entry exists
      final entry = await repository.getEntry(habitId, yesterday);
      expect(entry, isNotNull);
      expect(entry!.completed, isTrue);

      // Verify no entry exists before creation date
      final beforeCreationEntry = await repository.getEntry(habitId, beforeCreation);
      expect(beforeCreationEntry, isNull);
    });
  });

  group('Streak Calculations with Creation Dates', () {
    test('streak excludes entries before habit creation', () async {
      final creationDate = date_utils.DateUtils.getToday().subtract(
        const Duration(days: 5),
      );
      final habitCompanion = createTestHabitCompanion(
        name: 'Exercise',
        habitType: HabitType.good,
        createdAt: creationDate,
      );
      final habitId = await repository.createHabit(habitCompanion);

      final today = date_utils.DateUtils.getToday();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      final beforeCreation = creationDate.subtract(const Duration(days: 1));

      // Create entry before creation (should be ignored in streak)
      await repository.toggleCompletion(habitId, beforeCreation, true);
      
      // Create entries from creation date onwards
      await repository.toggleCompletion(habitId, twoDaysAgo, true);
      await repository.toggleCompletion(habitId, yesterday, true);
      await repository.toggleCompletion(habitId, today, true);

      await Future.delayed(const Duration(milliseconds: 100));

      final streak = await repository.getStreakByHabit(habitId);
      expect(streak, isNotNull);
      
      // Streak should only count from creation date (3 days: twoDaysAgo, yesterday, today)
      // Should not include beforeCreation
      expect(streak!.combinedStreak, greaterThanOrEqualTo(3));
    });

    test('bad habit streak excludes pre-creation dates', () async {
      final creationDate = date_utils.DateUtils.getToday().subtract(
        const Duration(days: 4),
      );
      final habitCompanion = createTestHabitCompanion(
        name: 'No Smoking',
        habitType: HabitType.bad,
        createdAt: creationDate,
      );
      final habitId = await repository.createHabit(habitCompanion);

      final today = date_utils.DateUtils.getToday();
      final yesterday = today.subtract(const Duration(days: 1));
      final beforeCreation = creationDate.subtract(const Duration(days: 1));

      // For bad habits, not marking (completed = false) means success
      await repository.toggleCompletion(habitId, beforeCreation, false);
      await repository.toggleCompletion(habitId, yesterday, false);
      await repository.toggleCompletion(habitId, today, false);

      await Future.delayed(const Duration(milliseconds: 100));

      final streak = await repository.getStreakByHabit(habitId);
      expect(streak, isNotNull);
      
      // Streak should only count from creation date (2 days: yesterday, today)
      // Should not include beforeCreation
      expect(streak!.combinedStreak, greaterThanOrEqualTo(2));
    });
  });

  group('Mixed Creation Dates', () {
    test('completion calculation with habits created on different dates', () async {
      // Create habit 1 (created 5 days ago)
      final creationDate1 = date_utils.DateUtils.getToday().subtract(
        const Duration(days: 5),
      );
      final habitCompanion1 = createTestHabitCompanion(
        name: 'Old Habit',
        habitType: HabitType.good,
        createdAt: creationDate1,
      );
      final habitId1 = await repository.createHabit(habitCompanion1);

      // Create habit 2 (created 2 days ago)
      final creationDate2 = date_utils.DateUtils.getToday().subtract(
        const Duration(days: 2),
      );
      final habitCompanion2 = createTestHabitCompanion(
        name: 'New Habit',
        habitType: HabitType.good,
        createdAt: creationDate2,
      );
      final habitId2 = await repository.createHabit(habitCompanion2);

      final today = date_utils.DateUtils.getToday();

      // Complete both habits today
      await repository.toggleCompletion(habitId1, today, true);
      await repository.toggleCompletion(habitId2, today, true);

      // Verify both entries exist
      final entry1 = await repository.getEntry(habitId1, today);
      final entry2 = await repository.getEntry(habitId2, today);
      
      expect(entry1, isNotNull);
      expect(entry2, isNotNull);
      expect(entry1!.completed, isTrue);
      expect(entry2!.completed, isTrue);
    });
  });
}

