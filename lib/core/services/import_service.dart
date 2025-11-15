import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart' as db;
import 'logging_service.dart';
import 'preferences_service.dart';
import '../../features/habits/habit_repository.dart';

class ImportResult {
  bool success;
  int habitsImported;
  int habitsSkipped;
  int entriesImported;
  int entriesSkipped;
  int streaksImported;
  int streaksSkipped;
  int settingsImported;
  int settingsSkipped;
  List<String> errors;
  List<String> warnings;

  ImportResult({
    required this.success,
    this.habitsImported = 0,
    this.habitsSkipped = 0,
    this.entriesImported = 0,
    this.entriesSkipped = 0,
    this.streaksImported = 0,
    this.streaksSkipped = 0,
    this.settingsImported = 0,
    this.settingsSkipped = 0,
    List<String>? errors,
    List<String>? warnings,
  }) : errors = errors ?? [],
       warnings = warnings ?? [];

  bool get hasIssues => errors.isNotEmpty || warnings.isNotEmpty || 
    habitsSkipped > 0 || entriesSkipped > 0 || streaksSkipped > 0 || settingsSkipped > 0;
}

class ImportService {
  static Future<String?> pickImportFile({String? importType}) async {
    try {
      String dialogTitle = 'import_data'.tr();
      List<String> allowedExtensions = ['json', 'csv'];
      
      if (importType != null) {
        if (importType == 'all') {
          dialogTitle = 'import_all_data_file_picker'.tr();
          allowedExtensions = ['json', 'csv']; // Both formats allowed
        } else if (importType == 'habits') {
          dialogTitle = 'import_habits_file_picker'.tr();
          allowedExtensions = ['json']; // Only JSON for habits
        } else if (importType == 'settings') {
          dialogTitle = 'import_settings_file_picker'.tr();
          allowedExtensions = ['json']; // Only JSON for settings
        }
      }
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        dialogTitle: dialogTitle,
      );
      
      if (result != null && result.files.single.path != null) {
        return result.files.single.path;
      }
      return null;
    } catch (e) {
      LoggingService.error('Error picking import file: $e');
      return null;
    }
  }

  static Future<ImportResult> importAllData(
    HabitRepository repository,
    String filePath,
    void Function(String message, double progress)? onProgress,
  ) async {
    final result = ImportResult(success: false, errors: [], warnings: []);
    
    try {
      onProgress?.call('reading_file'.tr(), 0.1);
      final file = File(filePath);
      if (!await file.exists()) {
        result.errors.add('file_not_found'.tr());
        return result;
      }

      final content = await file.readAsString();
      final isCSV = filePath.toLowerCase().endsWith('.csv');
      
      if (isCSV) {
        return await _importFromCSV(repository, content, onProgress);
      } else {
        return await _importFromJSON(repository, content, onProgress);
      }
    } catch (e) {
      LoggingService.error('Error importing all data: $e');
      result.errors.add('${'import_error'.tr()}: $e');
      return result;
    }
  }

  static Future<ImportResult> importHabitsOnly(
    HabitRepository repository,
    String filePath,
    void Function(String message, double progress)? onProgress,
  ) async {
    final result = ImportResult(success: false, errors: [], warnings: []);
    
    try {
      onProgress?.call('reading_file'.tr(), 0.1);
      final file = File(filePath);
      if (!await file.exists()) {
        result.errors.add('file_not_found'.tr());
        return result;
      }

      final content = await file.readAsString();
      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      
      // Validate file type
      if (jsonData['type'] != 'habits' && jsonData['habits'] == null) {
        result.errors.add('invalid_habits_file'.tr());
        return result;
      }

      final habitsData = jsonData['habits'] as List<dynamic>?;
      if (habitsData == null || habitsData.isEmpty) {
        result.warnings.add('no_habits_in_file'.tr());
        result.success = true;
        return result;
      }

      onProgress?.call('importing_habits'.tr(), 0.2);
      final idMap = <int, int>{}; // oldId -> newId
      
      for (int i = 0; i < habitsData.length; i++) {
        final habitData = habitsData[i] as Map<String, dynamic>;
        final progress = 0.2 + (i / habitsData.length) * 0.8;
        final habitName = habitData['name']?.toString() ?? '?';
        onProgress?.call(
          'importing_habit'.tr(namedArgs: {'name': habitName}),
          progress,
        );

        try {
          final oldId = habitData['id'] as int?;
          final newId = await _importHabit(repository, habitData);
          
          if (oldId != null && newId != null) {
            idMap[oldId] = newId;
            result.habitsImported++;
          } else {
            result.habitsSkipped++;
            result.warnings.add('${'skipped_habit'.tr()}: $habitName');
          }
        } catch (e) {
          result.habitsSkipped++;
          result.errors.add('${'error_importing_habit'.tr()}: $habitName - $e');
        }
      }

      result.success = true;
      return result;
    } catch (e) {
      LoggingService.error('Error importing habits: $e');
      result.errors.add('${'import_error'.tr()}: $e');
      return result;
    }
  }

  static Future<ImportResult> importSettings(
    String filePath,
    void Function(String message, double progress)? onProgress,
  ) async {
    final result = ImportResult(success: false, errors: [], warnings: []);
    
    try {
      onProgress?.call('reading_file'.tr(), 0.1);
      final file = File(filePath);
      if (!await file.exists()) {
        result.errors.add('file_not_found'.tr());
        return result;
      }

      final content = await file.readAsString();
      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      
      // Validate file type
      if (jsonData['type'] != 'settings' && jsonData['settings'] == null) {
        result.errors.add('invalid_settings_file'.tr());
        return result;
      }

      final settingsData = jsonData['settings'] as Map<String, dynamic>?;
      if (settingsData == null || settingsData.isEmpty) {
        result.warnings.add('no_settings_in_file'.tr());
        result.success = true;
        return result;
      }

      onProgress?.call('importing_settings'.tr(), 0.2);
      final prefs = PreferencesService.prefs;
      int imported = 0;
      int skipped = 0;

      for (final entry in settingsData.entries) {
        try {
          final key = entry.key;
          final value = entry.value;
          
          // Skip internal keys that shouldn't be imported
          if (key == 'first_launch') {
            skipped++;
            continue;
          }

          if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is String) {
            await prefs.setString(key, value);
          } else {
            skipped++;
            result.warnings.add('${'unsupported_setting_type'.tr()}: $key');
            continue;
          }
          imported++;
        } catch (e) {
          skipped++;
          result.errors.add('${'error_importing_setting'.tr()}: ${entry.key} - $e');
        }
      }

      result.settingsImported = imported;
      result.settingsSkipped = skipped;
      result.success = true;
      return result;
    } catch (e) {
      LoggingService.error('Error importing settings: $e');
      result.errors.add('${'import_error'.tr()}: $e');
      return result;
    }
  }

  static Future<ImportResult> _importFromJSON(
    HabitRepository repository,
    String content,
    void Function(String message, double progress)? onProgress,
  ) async {
    final result = ImportResult(success: false, errors: [], warnings: []);
    
    try {
      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      
      // Check if it's a full export or habits-only
      final isHabitsOnly = jsonData['type'] == 'habits';
      final isSettingsOnly = jsonData['type'] == 'settings';
      
      if (isSettingsOnly) {
        // This shouldn't happen, but handle it
        result.errors.add('use_settings_import'.tr());
        return result;
      }

      onProgress?.call('importing_habits'.tr(), 0.1);
      final habitsData = jsonData['habits'] as List<dynamic>? ?? [];
      final idMap = <int, int>{}; // oldId -> newId
      
      // Import habits
      for (int i = 0; i < habitsData.length; i++) {
        final habitData = habitsData[i] as Map<String, dynamic>;
        final progress = 0.1 + (i / habitsData.length) * 0.3;
        final habitName = habitData['name']?.toString() ?? '?';
        onProgress?.call(
          'importing_habit'.tr(namedArgs: {'name': habitName}),
          progress,
        );

        try {
          final oldId = habitData['id'] as int?;
          final newId = await _importHabit(repository, habitData);
          
          if (oldId != null && newId != null) {
            idMap[oldId] = newId;
            result.habitsImported++;
          } else {
            result.habitsSkipped++;
            result.warnings.add('${'skipped_habit'.tr()}: $habitName');
          }
        } catch (e) {
          result.habitsSkipped++;
          result.errors.add('${'error_importing_habit'.tr()}: $habitName - $e');
        }
      }

      if (isHabitsOnly) {
        result.success = true;
        return result;
      }

      // Import entries
      onProgress?.call('importing_entries'.tr(), 0.4);
      final entriesData = jsonData['entries'] as List<dynamic>? ?? [];
      
      for (int i = 0; i < entriesData.length; i++) {
        final entryData = entriesData[i] as Map<String, dynamic>;
        final progress = 0.4 + (i / entriesData.length) * 0.3;
        onProgress?.call('importing_entry'.tr(), progress);

        try {
          final oldHabitId = entryData['habitId'] as int?;
          if (oldHabitId == null || !idMap.containsKey(oldHabitId)) {
            result.entriesSkipped++;
            continue;
          }

          final newHabitId = idMap[oldHabitId]!;
          await _importEntry(repository, newHabitId, entryData);
          result.entriesImported++;
        } catch (e) {
          result.entriesSkipped++;
          result.errors.add('${'error_importing_entry'.tr()}: $e');
        }
      }

      // Import streaks
      onProgress?.call('importing_streaks'.tr(), 0.7);
      final streaksData = jsonData['streaks'] as List<dynamic>? ?? [];
      
      for (int i = 0; i < streaksData.length; i++) {
        final streakData = streaksData[i] as Map<String, dynamic>;
        final progress = 0.7 + (i / streaksData.length) * 0.3;
        onProgress?.call('importing_streak'.tr(), progress);

        try {
          final oldHabitId = streakData['habitId'] as int?;
          if (oldHabitId == null || !idMap.containsKey(oldHabitId)) {
            result.streaksSkipped++;
            continue;
          }

          final newHabitId = idMap[oldHabitId]!;
          await _importStreak(repository, newHabitId, streakData);
          result.streaksImported++;
        } catch (e) {
          result.streaksSkipped++;
          result.errors.add('${'error_importing_streak'.tr()}: $e');
        }
      }

      result.success = true;
      return result;
    } catch (e) {
      LoggingService.error('Error importing from JSON: $e');
      result.errors.add('${'import_error'.tr()}: $e');
      return result;
    }
  }

  static Future<ImportResult> _importFromCSV(
    HabitRepository repository,
    String content,
    void Function(String message, double progress)? onProgress,
  ) async {
    final result = ImportResult(success: false, errors: [], warnings: []);
    
    try {
      final lines = content.split('\n');
      if (lines.isEmpty) {
        result.errors.add('empty_file'.tr());
        return result;
      }

      // Skip header
      final dataLines = lines.skip(1).where((l) => l.trim().isNotEmpty).toList();
      
      onProgress?.call('parsing_csv'.tr(), 0.1);
      final habitMap = <String, int>{}; // habitName -> habitId
      final entriesByHabit = <String, List<Map<String, String>>>{};

      // Parse CSV
      for (final line in dataLines) {
        try {
          final parts = _parseCSVLine(line);
          if (parts.length < 2) continue;

          final habitName = parts[0].replaceAll('"', '');
          if (!habitMap.containsKey(habitName)) {
            // Create habit if it doesn't exist
            final habitId = await _createHabitFromName(repository, habitName);
            habitMap[habitName] = habitId;
            result.habitsImported++;
          }

          entriesByHabit.putIfAbsent(habitName, () => []).add({
            'date': parts.length > 1 ? parts[1] : '',
            'completed': parts.length > 2 ? parts[2] : 'No',
            'notes': parts.length > 3 ? parts[3].replaceAll('""', '"') : '',
          });
        } catch (e) {
          result.errors.add('${'error_parsing_csv_line'.tr()}: $e');
        }
      }

      // Import entries
      onProgress?.call('importing_entries'.tr(), 0.5);
      int entryCount = 0;
      for (final entry in entriesByHabit.entries) {
        final habitId = habitMap[entry.key]!;
        for (final entryData in entry.value) {
          try {
            if (entryData['date']?.isNotEmpty == true) {
              final date = DateTime.parse(entryData['date']!);
              final completed = entryData['completed']?.toLowerCase() == 'yes';
              final notes = entryData['notes'];
              
              await repository.toggleCompletion(
                habitId,
                date,
                completed,
                notes: notes?.isEmpty == true ? null : notes,
              );
              entryCount++;
            }
          } catch (e) {
            result.entriesSkipped++;
            result.errors.add('${'error_importing_entry'.tr()}: $e');
          }
        }
      }
      result.entriesImported = entryCount;

      result.success = true;
      return result;
    } catch (e) {
      LoggingService.error('Error importing from CSV: $e');
      result.errors.add('${'import_error'.tr()}: $e');
      return result;
    }
  }

  static List<String> _parseCSVLine(String line) {
    final parts = <String>[];
    var current = '';
    var inQuotes = false;
    
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current += '"';
          i++; // Skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        parts.add(current);
        current = '';
      } else {
        current += char;
      }
    }
    parts.add(current);
    return parts;
  }

  static Future<int> _createHabitFromName(
    HabitRepository repository,
    String name,
  ) async {
    final companion = db.HabitsCompanion(
      name: drift.Value(name),
      color: drift.Value(Colors.deepPurple.toARGB32()),
      habitType: const drift.Value(0), // good
      trackingType: const drift.Value('completed'),
    );
    return await repository.createHabit(companion);
  }

  static Future<int?> _importHabit(
    HabitRepository repository,
    Map<String, dynamic> habitData,
  ) async {
    try {
      final name = habitData['name'] as String?;
      if (name == null || name.isEmpty) {
        return null;
      }

      final companion = db.HabitsCompanion(
        name: drift.Value(name),
        description: habitData['description'] != null
            ? drift.Value(habitData['description'] as String)
            : const drift.Value.absent(),
        color: habitData['color'] != null
            ? drift.Value(habitData['color'] as int)
            : drift.Value(Colors.deepPurple.toARGB32()),
        icon: habitData['icon'] != null
            ? drift.Value(habitData['icon'] as String)
            : const drift.Value.absent(),
        habitType: habitData['habitType'] != null
            ? drift.Value(habitData['habitType'] as int)
            : const drift.Value(0),
        trackingType: habitData['trackingType'] != null
            ? drift.Value(habitData['trackingType'] as String)
            : const drift.Value('completed'),
        unit: habitData['unit'] != null
            ? drift.Value(habitData['unit'] as String)
            : const drift.Value.absent(),
        goalValue: habitData['goalValue'] != null
            ? drift.Value(habitData['goalValue'] as double)
            : const drift.Value.absent(),
        goalPeriod: habitData['goalPeriod'] != null
            ? drift.Value(habitData['goalPeriod'] as String)
            : const drift.Value.absent(),
        occurrenceNames: habitData['occurrenceNames'] != null
            ? drift.Value(habitData['occurrenceNames'] as String)
            : const drift.Value.absent(),
      );

      return await repository.createHabit(companion);
    } catch (e) {
      LoggingService.error('Error importing habit: $e');
      rethrow;
    }
  }

  static Future<void> _importEntry(
    HabitRepository repository,
    int habitId,
    Map<String, dynamic> entryData,
  ) async {
    try {
      final dateStr = entryData['date'] as String?;
      if (dateStr == null) return;

      final date = DateTime.parse(dateStr);
      final completed = entryData['completed'] as bool? ?? false;
      final value = entryData['value'] as double?;
      final occurrenceData = entryData['occurrenceData'] as String?;
      final notes = entryData['notes'] as String?;

      final companion = db.TrackingEntriesCompanion(
        habitId: drift.Value(habitId),
        date: drift.Value(date),
        completed: drift.Value(completed),
        value: value != null ? drift.Value(value) : const drift.Value.absent(),
        occurrenceData: occurrenceData != null
            ? drift.Value(occurrenceData)
            : const drift.Value.absent(),
        notes: notes != null ? drift.Value(notes) : const drift.Value.absent(),
      );

      await repository.insertOrUpdateEntry(companion);
    } catch (e) {
      LoggingService.error('Error importing entry: $e');
      rethrow;
    }
  }

  static Future<void> _importStreak(
    HabitRepository repository,
    int habitId,
    Map<String, dynamic> streakData,
  ) async {
    try {
      final companion = db.StreaksCompanion(
        habitId: drift.Value(habitId),
        combinedStreak: drift.Value(streakData['combinedStreak'] as int? ?? 0),
        combinedLongestStreak: drift.Value(streakData['combinedLongestStreak'] as int? ?? 0),
        goodStreak: drift.Value(streakData['goodStreak'] as int? ?? 0),
        goodLongestStreak: drift.Value(streakData['goodLongestStreak'] as int? ?? 0),
        badStreak: drift.Value(streakData['badStreak'] as int? ?? 0),
        badLongestStreak: drift.Value(streakData['badLongestStreak'] as int? ?? 0),
        currentStreak: drift.Value(streakData['currentStreak'] as int? ?? 0),
        longestStreak: drift.Value(streakData['longestStreak'] as int? ?? 0),
        lastUpdated: drift.Value(
          streakData['lastUpdated'] != null
              ? DateTime.parse(streakData['lastUpdated'] as String)
              : DateTime.now(),
        ),
      );

      await repository.insertOrUpdateStreak(companion);
    } catch (e) {
      LoggingService.error('Error importing streak: $e');
      rethrow;
    }
  }
}

