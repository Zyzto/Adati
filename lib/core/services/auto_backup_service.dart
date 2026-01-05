import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../database/app_database.dart' as db;
import 'log_helper.dart';
import 'preferences_service.dart';
import 'import_service.dart';
import '../../features/habits/habit_repository.dart';

class BackupInfo {
  final String path;
  final DateTime date;
  final int size;
  final int habitsCount;
  final int entriesCount;
  final int streaksCount;
  final String? version;

  BackupInfo({
    required this.path,
    required this.date,
    required this.size,
    required this.habitsCount,
    required this.entriesCount,
    required this.streaksCount,
    this.version,
  });
}

class AutoBackupService {
  static HabitRepository? _repository;

  /// Initialize the auto backup service with a habit repository
  static void init(HabitRepository repository) {
    _repository = repository;
    Log.info('AutoBackupService initialized');
  }

  /// Check if a backup is due and create one if needed
  /// This should be called on app startup to ensure backups are created regularly
  static Future<void> checkAndCreateBackupIfDue() async {
    if (_repository == null) {
      Log.warning(
        'AutoBackupService not initialized, cannot check backup',
      );
      return;
    }

    if (!PreferencesService.getAutoBackupEnabled()) {
      return;
    }

    try {
      final lastBackupStr = PreferencesService.getAutoBackupLastBackup();
      DateTime? lastBackup;

      if (lastBackupStr != null && lastBackupStr.isNotEmpty) {
        try {
          lastBackup = DateTime.parse(lastBackupStr);
        } catch (e) {
          Log.warning('Failed to parse last backup date: $lastBackupStr');
        }
      }

      final now = DateTime.now();
      final shouldBackup = lastBackup == null ||
          now.difference(lastBackup).inHours >= 24;

      if (shouldBackup) {
        Log.info('Backup is due, creating backup...');
        await createBackup();
      } else {
        final hoursUntilBackup = 24 - now.difference(lastBackup).inHours;
        Log.debug(
          'Backup not due yet. Next backup in approximately $hoursUntilBackup hours',
        );
      }
    } catch (e, stackTrace) {
      Log.error(
        'Failed to check if backup is due',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get the app documents backup directory
  static Future<Directory> getBackupDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(directory.path, 'backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      return backupDir;
    } catch (e, stackTrace) {
      Log.error(
        'Failed to get backup directory',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create a backup of all app data
  static Future<String?> createBackup() async {
    if (_repository == null) {
      Log.warning(
        'AutoBackupService not initialized, cannot create backup',
      );
      return null;
    }

    try {
      Log.info('Starting automatic backup creation');

      // Fetch all data
      final habits = await _repository!.getAllHabits();
      final entries = <db.TrackingEntry>[];
      final streaks = <db.Streak>[];

      for (final habit in habits) {
        final habitEntries = await _repository!.getEntriesByHabit(habit.id);
        entries.addAll(habitEntries);

        final streak = await _repository!.getStreakByHabit(habit.id);
        if (streak != null) {
          streaks.add(streak);
        }
      }

      // Create backup data structure (same as ExportService.exportToJSON)
      final data = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'type': 'auto_backup',
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

      // Save to app backup directory
      final backupDir = await getBackupDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'adati_backup_$timestamp.json';
      final backupFile = File(path.join(backupDir.path, fileName));

      await backupFile.writeAsString(jsonString);
      Log.info(
        'Backup created successfully: ${backupFile.path}',
      );

      // Optionally save to user-selected directory
      final userDir = PreferencesService.getAutoBackupUserDirectory();
      if (userDir != null && userDir.isNotEmpty) {
        try {
          final userBackupDir = Directory(userDir);
          if (await userBackupDir.exists()) {
            final userBackupFile = File(path.join(userDir, fileName));
            await userBackupFile.writeAsString(jsonString);
            Log.info(
              'Backup also saved to user directory: ${userBackupFile.path}',
            );
          }
        } catch (e, stackTrace) {
          Log.warning(
            'Failed to save backup to user directory: $e',
            error: e,
            stackTrace: stackTrace,
          );
          // Don't fail the backup if user directory fails
        }
      }

      // Update last backup time
      await PreferencesService.setAutoBackupLastBackup(DateTime.now().toIso8601String());

      // Cleanup old backups
      await cleanupOldBackups();

      return backupFile.path;
    } catch (e, stackTrace) {
      Log.error(
        'Failed to create backup',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Clean up old backups, keeping only the last N backups
  static Future<void> cleanupOldBackups() async {
    try {
      final retentionCount = PreferencesService.getAutoBackupRetentionCount();
      final backupDir = await getBackupDirectory();

      // Get all backup files
      final backupFiles = <File>[];
      if (await backupDir.exists()) {
        await for (final entity in backupDir.list()) {
          if (entity is File &&
              entity.path.endsWith('.json') &&
              path.basename(entity.path).startsWith('adati_backup_')) {
            backupFiles.add(entity);
          }
        }
      }

      // Also check user directory if configured
      final userDir = PreferencesService.getAutoBackupUserDirectory();
      if (userDir != null && userDir.isNotEmpty) {
        try {
          final userBackupDir = Directory(userDir);
          if (await userBackupDir.exists()) {
            await for (final entity in userBackupDir.list()) {
              if (entity is File &&
                  entity.path.endsWith('.json') &&
                  path.basename(entity.path).startsWith('adati_backup_')) {
                backupFiles.add(entity);
              }
            }
          }
        } catch (e) {
          // Ignore errors in user directory
        }
      }

      // Sort by modification date (newest first)
      backupFiles.sort((a, b) {
        try {
          return b.lastModifiedSync().compareTo(a.lastModifiedSync());
        } catch (e) {
          return 0;
        }
      });

      // Delete old backups beyond retention count
      if (backupFiles.length > retentionCount) {
        final toDelete = backupFiles.sublist(retentionCount);
        int deletedCount = 0;
        for (final file in toDelete) {
          try {
            await file.delete();
            deletedCount++;
          } catch (e) {
            Log.warning(
              'Failed to delete old backup: ${file.path}',
            );
          }
        }
        Log.info(
          'Cleaned up $deletedCount old backup(s), keeping $retentionCount',
        );
      }
    } catch (e, stackTrace) {
      Log.error(
        'Failed to cleanup old backups',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// List all available backups
  static Future<List<BackupInfo>> listBackups() async {
    final backups = <BackupInfo>[];

    try {
      // Get backups from app directory
      final backupDir = await getBackupDirectory();
      if (await backupDir.exists()) {
        await for (final entity in backupDir.list()) {
          if (entity is File &&
              entity.path.endsWith('.json') &&
              path.basename(entity.path).startsWith('adati_backup_')) {
            try {
              final info = await getBackupInfo(entity.path);
              if (info != null) {
                backups.add(info);
              }
            } catch (e) {
              // Skip invalid backup files
            }
          }
        }
      }

      // Get backups from user directory if configured
      final userDir = PreferencesService.getAutoBackupUserDirectory();
      if (userDir != null && userDir.isNotEmpty) {
        try {
          final userBackupDir = Directory(userDir);
          if (await userBackupDir.exists()) {
            await for (final entity in userBackupDir.list()) {
              if (entity is File &&
                  entity.path.endsWith('.json') &&
                  path.basename(entity.path).startsWith('adati_backup_')) {
                try {
                  final info = await getBackupInfo(entity.path);
                  if (info != null) {
                    backups.add(info);
                  }
                } catch (e) {
                  // Skip invalid backup files
                }
              }
            }
          }
        } catch (e) {
          // Ignore errors in user directory
        }
      }

      // Sort by date (newest first)
      backups.sort((a, b) => b.date.compareTo(a.date));

      return backups;
    } catch (e, stackTrace) {
      Log.error(
        'Failed to list backups',
        error: e,
        stackTrace: stackTrace,
      );
      return backups;
    }
  }

  /// Get backup information from a backup file
  static Future<BackupInfo?> getBackupInfo(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      final content = await file.readAsString();
      final jsonData = jsonDecode(content) as Map<String, dynamic>;

      final exportDateStr = jsonData['exportDate'] as String?;
      final exportDate = exportDateStr != null
          ? DateTime.parse(exportDateStr)
          : stat.modified;

      final habits = jsonData['habits'] as List<dynamic>? ?? [];
      final entries = jsonData['entries'] as List<dynamic>? ?? [];
      final streaks = jsonData['streaks'] as List<dynamic>? ?? [];
      final version = jsonData['version'] as String?;

      return BackupInfo(
        path: backupPath,
        date: exportDate,
        size: stat.size,
        habitsCount: habits.length,
        entriesCount: entries.length,
        streaksCount: streaks.length,
        version: version,
      );
    } catch (e, stackTrace) {
      Log.error(
        'Failed to get backup info: $backupPath',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Restore from a backup file
  static Future<ImportResult> restoreFromBackup(
    String backupPath,
    HabitRepository repository, {
    void Function(String message, double progress)? onProgress,
  }) async {
    Log.info(
      'Restoring from backup: $backupPath',
    );

    try {
      // Use existing ImportService to restore
      return await ImportService.importAllData(
        repository,
        backupPath,
        onProgress,
      );
    } catch (e, stackTrace) {
      Log.error(
        'Failed to restore from backup',
        error: e,
        stackTrace: stackTrace,
      );
      return ImportResult(
        success: false,
        errors: ['${'restore_error'.tr()}: $e'],
      );
    }
  }
}

