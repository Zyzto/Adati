import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/core/services/export_service.dart';
import 'package:adati/core/database/models/tracking_types.dart';
import 'package:adati/core/utils/date_utils.dart' as date_utils;
import 'package:adati/features/habits/habit_repository.dart';
import '../helpers/database_helpers.dart';
import '../fixtures/habit_fixtures.dart';

void main() {
  group('ExportService - Data Transformation', () {
    test('exportToJSON includes all habit data', () async {
      final testDatabase = await createTestDatabase();
      final repository = HabitRepository(testDatabase);

      // Create test habits
      final habitCompanion1 = createTestHabitCompanion(
        name: 'Exercise',
        habitType: HabitType.good,
      );
      final habitCompanion2 = createTestHabitCompanion(
        name: 'No Smoking',
        habitType: HabitType.bad,
      );
      
      final habitId1 = await repository.createHabit(habitCompanion1);
      final habitId2 = await repository.createHabit(habitCompanion2);

      // Create tracking entries
      final today = date_utils.DateUtils.getToday();
      await repository.toggleCompletion(habitId1, today, true);
      await repository.toggleCompletion(habitId2, today, false);

      // Get all data
      final habits = await repository.getAllHabits();
      final entries = <db.TrackingEntry>[];
      for (final habit in habits) {
        final habitEntries = await repository.getEntriesByHabit(habit.id);
        entries.addAll(habitEntries);
      }
      final streaks = <db.Streak>[];
      for (final habit in habits) {
        final streak = await repository.getStreakByHabit(habit.id);
        if (streak != null) {
          streaks.add(streak);
        }
      }

      // Export to JSON (this will test data serialization)
      // Note: Actual file saving requires platform interaction, so we test the data structure
      final jsonString = await ExportService.exportToJSON(
        habits,
        entries,
        streaks,
      );

      expect(jsonString, isNotNull);
      expect(jsonString, isNotEmpty);

      // Verify JSON is valid
      final jsonData = jsonDecode(jsonString!);
      expect(jsonData, isA<Map>());
      expect(jsonData['habits'], isA<List>());
      expect(jsonData['habits'].length, equals(2));
      expect(jsonData['entries'], isA<List>());
      expect(jsonData['streaks'], isA<List>());

      // Verify habit data is included
      final exportedHabits = jsonData['habits'] as List;
      expect(exportedHabits.any((h) => h['name'] == 'Exercise'), isTrue);
      expect(exportedHabits.any((h) => h['name'] == 'No Smoking'), isTrue);

      await testDatabase.close();
    });

    test('exportToJSON includes tracking entries', () async {
      final testDatabase = await createTestDatabase();
      final repository = HabitRepository(testDatabase);

      final habitCompanion = createTestHabitCompanion(name: 'Test Habit');
      final habitId = await repository.createHabit(habitCompanion);

      final today = date_utils.DateUtils.getToday();
      await repository.toggleCompletion(habitId, today, true);

      final habits = await repository.getAllHabits();
      final entries = await repository.getEntriesByHabit(habitId);
      final streaks = <db.Streak>[];

      final jsonString = await ExportService.exportToJSON(
        habits,
        entries,
        streaks,
      );

      final jsonData = jsonDecode(jsonString!);
      final exportedEntries = jsonData['entries'] as List;
      
      expect(exportedEntries.length, equals(1));
      expect(exportedEntries[0]['habitId'], equals(habitId));
      expect(exportedEntries[0]['completed'], equals(true));

      await testDatabase.close();
    });
  });
}

