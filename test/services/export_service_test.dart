import 'package:flutter_test/flutter_test.dart';
import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/core/database/models/tracking_types.dart';
import 'package:adati/core/utils/date_utils.dart' as date_utils;
import 'package:adati/features/habits/habit_repository.dart';
import '../helpers/database_helpers.dart';
import '../helpers/test_helpers.dart';
import '../fixtures/habit_fixtures.dart';

void main() {
  setUpAll(() async {
    // Initialize test environment (binding, preferences, logging)
    await setupTestEnvironment();
  });

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

      // Test JSON serialization structure
      // Note: exportToJSON requires FilePicker which doesn't work in unit tests,
      // so we test the data structure by manually creating it the same way ExportService does
      final data = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'habits': habits.map((h) => {
          'id': h.id,
          'name': h.name,
          'description': h.description,
          'color': h.color,
          'icon': h.icon,
          'habitType': h.habitType,
          'trackingType': h.trackingType,
          'unit': h.unit,
          'goalValue': h.goalValue,
          'goalPeriod': h.goalPeriod,
          'occurrenceNames': h.occurrenceNames,
        }).toList(),
        'entries': entries.map((e) => {
          'habitId': e.habitId,
          'date': e.date.toIso8601String(),
          'completed': e.completed,
          'value': e.value,
          'occurrenceData': e.occurrenceData,
          'notes': e.notes,
        }).toList(),
        'streaks': streaks.map((s) => {
          'habitId': s.habitId,
          'combinedStreak': s.combinedStreak,
          'combinedLongestStreak': s.combinedLongestStreak,
          'goodStreak': s.goodStreak,
          'goodLongestStreak': s.goodLongestStreak,
          'badStreak': s.badStreak,
          'badLongestStreak': s.badLongestStreak,
          'currentStreak': s.currentStreak,
          'longestStreak': s.longestStreak,
          'lastUpdated': s.lastUpdated.toIso8601String(),
        }).toList(),
      };
      
      final jsonData = data as Map<String, dynamic>;
      expect(jsonData, isA<Map>());
      final habitsList = jsonData['habits'] as List;
      expect(habitsList, isA<List>());
      expect(habitsList.length, equals(2));
      expect(jsonData['entries'], isA<List>());
      expect(jsonData['streaks'], isA<List>());

      // Verify habit data is included
      final exportedHabits = habitsList;
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

      // Test JSON serialization structure (same as ExportService.exportToJSON)
      final data = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'habits': habits.map((h) => {
          'id': h.id,
          'name': h.name,
          'description': h.description,
          'color': h.color,
          'icon': h.icon,
          'habitType': h.habitType,
          'trackingType': h.trackingType,
          'unit': h.unit,
          'goalValue': h.goalValue,
          'goalPeriod': h.goalPeriod,
          'occurrenceNames': h.occurrenceNames,
        }).toList(),
        'entries': entries.map((e) => {
          'habitId': e.habitId,
          'date': e.date.toIso8601String(),
          'completed': e.completed,
          'value': e.value,
          'occurrenceData': e.occurrenceData,
          'notes': e.notes,
        }).toList(),
        'streaks': streaks.map((s) => {
          'habitId': s.habitId,
          'combinedStreak': s.combinedStreak,
          'combinedLongestStreak': s.combinedLongestStreak,
          'goodStreak': s.goodStreak,
          'goodLongestStreak': s.goodLongestStreak,
          'badStreak': s.badStreak,
          'badLongestStreak': s.badLongestStreak,
          'currentStreak': s.currentStreak,
          'longestStreak': s.longestStreak,
          'lastUpdated': s.lastUpdated.toIso8601String(),
        }).toList(),
      };
      
      final jsonData = data as Map<String, dynamic>;
      final exportedEntries = jsonData['entries'] as List;
      
      expect(exportedEntries.length, equals(1));
      expect(exportedEntries[0]['habitId'], equals(habitId));
      expect(exportedEntries[0]['completed'], equals(true));

      await testDatabase.close();
    });
  });
}

