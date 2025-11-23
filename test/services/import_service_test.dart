import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/core/services/import_service.dart';
import 'package:adati/core/database/models/tracking_types.dart';
import 'package:adati/features/habits/habit_repository.dart';
import '../helpers/database_helpers.dart';

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

  group('ImportService - JSON Import', () {
    test('importFromJSON creates habits correctly', () async {
      final jsonData = {
        'habits': [
          {
            'id': 1,
            'name': 'Imported Habit',
            'description': 'Test description',
            'color': 0xFF2196F3,
            'icon': null,
            'habitType': HabitType.good.value,
            'trackingType': TrackingType.completed.value,
            'unit': null,
            'goalValue': null,
            'goalPeriod': null,
            'occurrenceNames': null,
            'reminderEnabled': false,
            'reminderTime': null,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        ],
        'entries': [],
        'streaks': [],
        'tags': [],
      };

      final jsonString = jsonEncode(jsonData);
      final result = await ImportService.importAllData(
        repository,
        jsonString,
        null, // No progress callback for test
      );

      expect(result.success, isTrue);
      expect(result.habitsImported, equals(1));

      // Verify habit was imported
      final habits = await repository.getAllHabits();
      expect(habits.length, equals(1));
      expect(habits[0].name, equals('Imported Habit'));
    });

    test('importAllData creates tracking entries correctly', () async {
      final today = DateTime.now();
      final jsonData = {
        'habits': [
          {
            'id': 1,
            'name': 'Test Habit',
            'description': null,
            'color': 0xFF2196F3,
            'icon': null,
            'habitType': HabitType.good.value,
            'trackingType': TrackingType.completed.value,
            'unit': null,
            'goalValue': null,
            'goalPeriod': null,
            'occurrenceNames': null,
            'reminderEnabled': false,
            'reminderTime': null,
            'createdAt': today.toIso8601String(),
            'updatedAt': today.toIso8601String(),
          },
        ],
        'entries': [
          {
            'habitId': 1,
            'date': today.toIso8601String(),
            'completed': true,
            'value': null,
            'occurrenceData': null,
            'notes': 'Test note',
          },
        ],
        'streaks': [],
        'tags': [],
      };

      // Create a temporary file for import
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_import_${DateTime.now().millisecondsSinceEpoch}.json');
      await tempFile.writeAsString(jsonEncode(jsonData));
      
      final result = await ImportService.importAllData(
        repository,
        tempFile.path,
        null,
      );

      expect(result.success, isTrue);
      expect(result.entriesImported, equals(1));

      // Verify entry was imported
      final habits = await repository.getAllHabits();
      expect(habits.length, equals(1));
      
      final entries = await repository.getEntriesByHabit(habits[0].id);
      expect(entries.length, equals(1));
      expect(entries[0].completed, equals(true));
      expect(entries[0].notes, equals('Test note'));
      
      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test('importAllData handles invalid JSON gracefully', () async {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_import_invalid_${DateTime.now().millisecondsSinceEpoch}.json');
      await tempFile.writeAsString('not valid json');
      
      final result = await ImportService.importAllData(
        repository,
        tempFile.path,
        null,
      );
      
      expect(result.success, isFalse);
      expect(result.errors.isNotEmpty, isTrue);
      
      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });
  });
}

