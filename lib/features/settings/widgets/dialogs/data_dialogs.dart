import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/services/auto_backup_service.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/services/import_service.dart';
import '../../../habits/providers/habit_providers.dart';
import '../responsive_dialog.dart';

/// Static dialog methods for Data Management section  
class DataDialogs {
  /// Show export data dialog with options for what to export
  static Future<void> showExportDialog(BuildContext context, WidgetRef ref) async {
    // First, show what to export
    final exportType = await showDialog<String>(
      context: context,
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('export_data'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.archive),
              title: Text('export_all_data'.tr()),
              subtitle: Text('export_all_data_description'.tr()),
              onTap: () => Navigator.pop(context, 'all'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: Text('export_habits'.tr()),
              subtitle: Text('export_habits_description'.tr()),
              onTap: () => Navigator.pop(context, 'habits'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text('export_settings'.tr()),
              subtitle: Text('export_settings_description'.tr()),
              onTap: () => Navigator.pop(context, 'settings'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );

    if (exportType == null || !context.mounted) return;

    // Handle settings export (no loading needed)
    if (exportType == 'settings') {
      try {
        final filePath = await ExportService.exportSettings();
        if (context.mounted) {
          if (filePath != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('export_success'.tr()),
                action: SnackBarAction(label: 'ok'.tr(), onPressed: () {}),
              ),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('export_cancelled'.tr())));
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'export_error'.tr()}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // Handle habits export (no loading needed)
    if (exportType == 'habits') {
      try {
        final repository = ref.read(habitRepositoryProvider);
        final habits = await repository.getAllHabits();
        final filePath = await ExportService.exportHabitsOnly(habits);
        if (context.mounted) {
          if (filePath != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('export_success'.tr()),
                action: SnackBarAction(label: 'ok'.tr(), onPressed: () {}),
              ),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('export_cancelled'.tr())));
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'export_error'.tr()}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // Handle all data export (with format selection)
    if (exportType == 'all') {
      final repository = ref.read(habitRepositoryProvider);

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Fetch all data
        final habits = await repository.getAllHabits();
        final entries = <db.TrackingEntry>[];
        final streaks = <db.Streak>[];

        for (final habit in habits) {
          final habitEntries = await repository.getEntriesByHabit(habit.id);
          entries.addAll(habitEntries);

          final streak = await repository.getStreakByHabit(habit.id);
          if (streak != null) {
            streaks.add(streak);
          }
        }

        if (context.mounted) {
          Navigator.pop(context); // Close loading

          // Show format selection
          final format = await showDialog<String>(
            context: context,
            builder: (context) => ResponsiveDialog.responsiveAlertDialog(
              context: context,
              title: Text('select_format'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.table_chart),
                    title: Text('export_as_csv'.tr()),
                    subtitle: Text('export_csv_description'.tr()),
                    onTap: () => Navigator.pop(context, 'csv'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: Text('export_as_json'.tr()),
                    subtitle: Text('export_json_description'.tr()),
                    onTap: () => Navigator.pop(context, 'json'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr()),
                ),
              ],
            ),
          );

          if (format != null && context.mounted) {
            String? filePath;
            if (format == 'csv') {
              filePath = await ExportService.exportToCSV(
                habits,
                entries,
                streaks,
              );
            } else {
              filePath = await ExportService.exportToJSON(
                habits,
                entries,
                streaks,
              );
            }

            if (context.mounted) {
              if (filePath != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('export_success'.tr()),
                    action: SnackBarAction(label: 'ok'.tr(), onPressed: () {}),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('export_cancelled'.tr())),
                );
              }
            }
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'export_error'.tr()}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Show import data dialog with options for what to import
  static Future<void> showImportDialog(BuildContext context, WidgetRef ref) async {
    final importType = await showDialog<String>(
      context: context,
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('import_data'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.archive),
              title: Text('import_all_data'.tr()),
              subtitle: Text('import_all_data_description_with_format'.tr()),
              onTap: () => Navigator.pop(context, 'all'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: Text('import_habits'.tr()),
              subtitle: Text('import_habits_description_with_format'.tr()),
              onTap: () => Navigator.pop(context, 'habits'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text('import_settings'.tr()),
              subtitle: Text('import_settings_description_with_format'.tr()),
              onTap: () => Navigator.pop(context, 'settings'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );

    if (importType == null || !context.mounted) return;

    // Pick file
    final filePath = await ImportService.pickImportFile(importType: importType);
    if (filePath == null || !context.mounted) return;

    // Show progress dialog with ValueNotifier for updates
    final progressNotifier = ValueNotifier<double>(0.0);
    final messageNotifier = ValueNotifier<String>('starting_import'.tr());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder<double>(
        valueListenable: progressNotifier,
        builder: (context, progress, _) {
          return ValueListenableBuilder<String>(
            valueListenable: messageNotifier,
            builder: (context, message, _) {
              return ResponsiveDialog.responsiveAlertDialog(
                context: context,
                title: const SizedBox.shrink(),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      value: progress > 0 ? progress : null,
                    ),
                    const SizedBox(height: 16),
                    Text(message),
                  ],
                ),
                actions: null,
              );
            },
          );
        },
      ),
    );

    ImportResult result;
    final repository = ref.read(habitRepositoryProvider);

    try {
      if (importType == 'all') {
        result = await ImportService.importAllData(repository, filePath, (
          message,
          prog,
        ) {
          messageNotifier.value = message;
          progressNotifier.value = prog;
        });
      } else if (importType == 'habits') {
        result = await ImportService.importHabitsOnly(repository, filePath, (
          message,
          prog,
        ) {
          messageNotifier.value = message;
          progressNotifier.value = prog;
        });
      } else {
        result = await ImportService.importSettings(filePath, (message, prog) {
          messageNotifier.value = message;
          progressNotifier.value = prog;
        });
      }
    } catch (e) {
      result = ImportResult(
        success: false,
        errors: ['${'import_error'.tr()}: $e'],
      );
    }

    if (context.mounted) {
      Navigator.pop(context); // Close progress dialog
      progressNotifier.dispose();
      messageNotifier.dispose();
      showImportResultDialog(context, result);
    }
  }

  /// Show import result dialog with statistics
  static void showImportResultDialog(BuildContext context, ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text(
          result.success ? 'import_success'.tr() : 'import_failed'.tr(),
        ),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              if (result.habitsImported > 0)
                _buildResultRow(
                  'habits_imported'.tr(),
                  result.habitsImported,
                  true,
                ),
              if (result.habitsSkipped > 0)
                _buildResultRow(
                  'habits_skipped'.tr(),
                  result.habitsSkipped,
                  false,
                ),
              if (result.entriesImported > 0)
                _buildResultRow(
                  'entries_imported'.tr(),
                  result.entriesImported,
                  true,
                ),
              if (result.entriesSkipped > 0)
                _buildResultRow(
                  'entries_skipped'.tr(),
                  result.entriesSkipped,
                  false,
                ),
              if (result.streaksImported > 0)
                _buildResultRow(
                  'streaks_imported'.tr(),
                  result.streaksImported,
                  true,
                ),
              if (result.streaksSkipped > 0)
                _buildResultRow(
                  'streaks_skipped'.tr(),
                  result.streaksSkipped,
                  false,
                ),
              if (result.settingsImported > 0)
                _buildResultRow(
                  'settings_imported'.tr(),
                  result.settingsImported,
                  true,
                ),
              if (result.settingsSkipped > 0)
                _buildResultRow(
                  'settings_skipped'.tr(),
                  result.settingsSkipped,
                  false,
                ),
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'warnings'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...result.warnings
                    .map((w) => Text('• $w', style: TextStyle(fontSize: 12))),
              ],
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'errors'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...result.errors.map(
                  (e) => Text('• $e',
                      style: TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ],
            ],
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  /// Build a result row for import dialog
  static Widget _buildResultRow(String label, int count, bool isSuccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSuccess ? Icons.check_circle : Icons.warning,
                size: 16,
                color: isSuccess ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show database statistics dialog
  static Future<void> showDatabaseStatsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final repository = ref.read(habitRepositoryProvider);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final habits = await repository.getAllHabits();
      int totalEntries = 0;
      int totalStreaks = 0;

      for (final habit in habits) {
        final entries = await repository.getEntriesByHabit(habit.id);
        totalEntries += entries.length;

        final streak = await repository.getStreakByHabit(habit.id);
        if (streak != null) {
          totalStreaks++;
        }
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        showDialog(
          context: context,
          builder: (context) => ResponsiveDialog.responsiveAlertDialog(
            context: context,
            title: Text('database_statistics'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatRow('habits'.tr(), habits.length),
                _buildStatRow('entries'.tr(), totalEntries),
                _buildStatRow('streaks'.tr(), totalStreaks),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('ok'.tr()),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Build a stat row for database stats dialog
  static Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Trigger a manual backup
  static Future<void> triggerManualBackup(BuildContext context) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final backupPath = await AutoBackupService.createBackup();
      if (context.mounted) {
        Navigator.pop(context);
        if (backupPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('auto_backup_success'.tr()),
              action: SnackBarAction(label: 'ok'.tr(), onPressed: () {}),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('auto_backup_failed'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'auto_backup_failed'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show restore from backup dialog
  static Future<void> showRestoreDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final backups = await AutoBackupService.listBackups();
      if (!context.mounted) return;

      Navigator.pop(context);

      if (backups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_backups_found'.tr())),
        );
        return;
      }

      final selectedBackup = await showDialog<BackupInfo>(
        context: context,
        builder: (context) => ResponsiveDialog.responsiveAlertDialog(
          context: context,
          title: Text('restore_from_backup'.tr()),
          scrollable: true,
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: backups.length,
              itemBuilder: (context, index) {
                final backup = backups[index];
                final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
                return ListTile(
                  leading: const Icon(Icons.backup),
                  title: Text(dateFormat.format(backup.date)),
                  subtitle: Text(
                    '${backup.habitsCount} ${'habits'.tr()}, '
                    '${backup.entriesCount} ${'entries'.tr()}, '
                    '${backup.streaksCount} ${'streaks'.tr()}\n'
                    '${(backup.size / 1024).toStringAsFixed(1)} KB',
                  ),
                  onTap: () => Navigator.pop(context, backup),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
          ],
        ),
      );

      if (selectedBackup == null || !context.mounted) return;

      // Confirm restore
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => ResponsiveDialog.responsiveAlertDialog(
          context: context,
          title: Text('restore_confirmation'.tr()),
          content: Text('restore_confirmation_message'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('restore'.tr()),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      // Show progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final repository = ref.read(habitRepositoryProvider);
      final result = await AutoBackupService.restoreFromBackup(
        selectedBackup.path,
        repository,
      );

      if (context.mounted) {
        Navigator.pop(context);
        
        if (result.success) {
          ref.invalidate(habitRepositoryProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('restore_success'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errors.join(', ')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'restore_failed'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Optimize database (vacuum)
  static Future<void> optimizeDatabase(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repository = ref.read(habitRepositoryProvider);
      await repository.vacuumDatabase();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('database_optimized'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

