import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path/path.dart' as path;
import '../database/app_database.dart' as db;
import 'log_helper.dart';
import 'preferences_service.dart';

class ExportService {
  static Future<String?> exportToCSV(
    List<db.Habit> habits,
    List<db.TrackingEntry> entries,
    List<db.Streak> streaks,
  ) async {
    Log.info('exportToCSV(habits=${habits.length}, entries=${entries.length}, streaks=${streaks.length})');
    try {
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln('csv_header'.tr());
      
      // Group entries by habit
      final entriesByHabit = <int, List<db.TrackingEntry>>{};
      for (final entry in entries) {
        entriesByHabit.putIfAbsent(entry.habitId, () => []).add(entry);
      }
      
      // Write data
      for (final habit in habits) {
        final habitEntries = entriesByHabit[habit.id] ?? [];
        final streak = streaks.firstWhere(
          (s) => s.habitId == habit.id,
          orElse: () => db.Streak(
            id: 0,
            habitId: habit.id,
            combinedStreak: 0,
            combinedLongestStreak: 0,
            goodStreak: 0,
            goodLongestStreak: 0,
            badStreak: 0,
            badLongestStreak: 0,
            currentStreak: 0,
            longestStreak: 0,
            lastUpdated: DateTime.now(),
          ),
        );
        
        if (habitEntries.isEmpty) {
          // Write habit with no entries
          buffer.writeln(
            '"${habit.name}",,,,${streak.currentStreak},${streak.longestStreak}',
          );
        } else {
          for (final entry in habitEntries) {
            final dateStr = DateFormat('yyyy-MM-dd').format(entry.date);
            final notes = entry.notes?.replaceAll('"', '""') ?? '';
            final completedStr = entry.completed ? 'yes'.tr() : 'no'.tr();
            buffer.writeln(
              '"${habit.name}",$dateStr,$completedStr,"$notes",${streak.currentStreak},${streak.longestStreak}',
            );
          }
        }
      }
      
      // Save file
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'adati_export_$timestamp.csv';
      
      // Use file_picker to save
      final result = await FilePicker.platform.saveFile(
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        dialogTitle: 'export_data'.tr(),
      );
      
      if (result != null) {
        try {
          // Ensure parent directory exists
          final file = File(result);
          final parentDir = Directory(path.dirname(result));
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }
          // Write to the selected path
          await file.writeAsString(buffer.toString());
          Log.info('Exported data to: $result');
          return result;
        } on FileSystemException catch (e) {
          Log.error(
            'File system error exporting CSV (permissions or disk space): $e',
          );
          return null;
        } on IOException catch (e) {
          Log.error(
            'IO error exporting CSV: $e',
          );
          return null;
        } catch (e) {
          Log.error('Error exporting to CSV: $e');
          return null;
        }
      }
      
      return null;
    } catch (e) {
      Log.error('Error exporting to CSV: $e');
      return null;
    }
  }

  static Future<String?> exportToJSON(
    List<db.Habit> habits,
    List<db.TrackingEntry> entries,
    List<db.Streak> streaks,
  ) async {
    try {
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
          'createdAt': h.createdAt.toIso8601String(),
          'updatedAt': h.updatedAt.toIso8601String(),
          'reminderEnabled': h.reminderEnabled,
          'reminderTime': h.reminderTime,
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
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      // Save file
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'adati_export_$timestamp.json';
      
      final result = await FilePicker.platform.saveFile(
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'export_data'.tr(),
      );
      
      if (result != null) {
        try {
          // Ensure parent directory exists
          final file = File(result);
          final parentDir = Directory(path.dirname(result));
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }
          // Write to the selected path
          await file.writeAsString(jsonString);
          Log.info('Exported data to: $result');
          return result;
        } on FileSystemException catch (e) {
          Log.error(
            'File system error exporting JSON (permissions or disk space): $e',
          );
          return null;
        } on IOException catch (e) {
          Log.error(
            'IO error exporting JSON: $e',
          );
          return null;
        } catch (e) {
          Log.error('Error exporting to JSON: $e');
          return null;
        }
      }
      
      return null;
    } catch (e) {
      Log.error('Error exporting to JSON: $e');
      return null;
    }
  }

  static Future<String?> exportHabitsOnly(
    List<db.Habit> habits,
  ) async {
    try {
      final data = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'type': 'habits',
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
          'createdAt': h.createdAt.toIso8601String(),
          'updatedAt': h.updatedAt.toIso8601String(),
          'reminderEnabled': h.reminderEnabled,
          'reminderTime': h.reminderTime,
        }).toList(),
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'adati_habits_$timestamp.json';
      
      final result = await FilePicker.platform.saveFile(
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'export_habits'.tr(),
      );
      
      if (result != null) {
        try {
          // Ensure parent directory exists
          final file = File(result);
          final parentDir = Directory(path.dirname(result));
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }
          // Write to the selected path
          await file.writeAsString(jsonString);
          Log.info('Exported habits to: $result');
          return result;
        } on FileSystemException catch (e) {
          Log.error(
            'File system error exporting habits (permissions or disk space): $e',
          );
          return null;
        } on IOException catch (e) {
          Log.error(
            'IO error exporting habits: $e',
          );
          return null;
        } catch (e) {
          Log.error('Error exporting habits: $e');
          return null;
        }
      }
      
      return null;
    } catch (e) {
      Log.error('Error exporting habits: $e');
      return null;
    }
  }

  static Future<String?> exportSettings() async {
    try {
      final prefs = PreferencesService.prefs;
      final allKeys = prefs.getKeys();
      
      final settings = <String, dynamic>{};
      for (final key in allKeys) {
        final value = prefs.get(key);
        if (value != null) {
          settings[key] = value;
        }
      }
      
      final data = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'type': 'settings',
        'settings': settings,
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'adati_settings_$timestamp.json';
      
      final result = await FilePicker.platform.saveFile(
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'export_settings'.tr(),
      );
      
      if (result != null) {
        try {
          // Ensure parent directory exists
          final file = File(result);
          final parentDir = Directory(path.dirname(result));
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }
          // Write to the selected path
          await file.writeAsString(jsonString);
          Log.info('Exported settings to: $result');
          return result;
        } on FileSystemException catch (e) {
          Log.error(
            'File system error exporting settings (permissions or disk space): $e',
          );
          return null;
        } on IOException catch (e) {
          Log.error(
            'IO error exporting settings: $e',
          );
          return null;
        } catch (e) {
          Log.error('Error exporting settings: $e');
          return null;
        }
      }
      
      return null;
    } catch (e) {
      Log.error('Error exporting settings: $e');
      return null;
    }
  }
}

