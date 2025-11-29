import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/auto_backup_service.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/services/import_service.dart';
import '../../../habits/providers/habit_providers.dart';
import '../responsive_dialog.dart';
import '../settings_section.dart';

/// Data Management settings section
class DataSectionContent extends ConsumerStatefulWidget {
  final Function(BuildContext, WidgetRef) showExportDialog;
  final Function(BuildContext, WidgetRef) showImportDialog;
  final Function(BuildContext, WidgetRef) showDatabaseStatsDialog;
  final Function(BuildContext, WidgetRef) optimizeDatabase;

  const DataSectionContent({
    super.key,
    required this.showExportDialog,
    required this.showImportDialog,
    required this.showDatabaseStatsDialog,
    required this.optimizeDatabase,
  });

  @override
  ConsumerState<DataSectionContent> createState() => _DataSectionContentState();
}

class _DataSectionContentState extends ConsumerState<DataSectionContent> {
  bool _autoBackupEnabled = false;
  int _retentionCount = 10;
  String? _userDirectory;
  String? _lastBackup;

  @override
  void initState() {
    super.initState();
    _loadAutoBackupSettings();
  }

  void _loadAutoBackupSettings() {
    setState(() {
      _autoBackupEnabled = PreferencesService.getAutoBackupEnabled();
      _retentionCount = PreferencesService.getAutoBackupRetentionCount();
      _userDirectory = PreferencesService.getAutoBackupUserDirectory();
      _lastBackup = PreferencesService.getAutoBackupLastBackup();
    });
  }

  Future<void> _toggleAutoBackup(bool enabled) async {
    await PreferencesService.setAutoBackupEnabled(enabled);
    setState(() {
      _autoBackupEnabled = enabled;
    });
    
    // Schedule or cancel background task
    if (mounted) {
      // Note: Background task scheduling should be handled in main.dart
      // This is just updating the preference
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled
              ? 'auto_backup_enabled'.tr()
              : 'auto_backup_disabled'.tr()),
        ),
      );
    }
  }

  Future<void> _updateRetentionCount(int count) async {
    if (count < 1 || count > 100) return;
    await PreferencesService.setAutoBackupRetentionCount(count);
    setState(() {
      _retentionCount = count;
    });
    // Cleanup old backups
    await AutoBackupService.cleanupOldBackups();
  }

  Future<void> _selectBackupDirectory() async {
    final directory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'auto_backup_select_directory'.tr(),
    );
    if (directory != null) {
      await PreferencesService.setAutoBackupUserDirectory(directory);
      setState(() {
        _userDirectory = directory;
      });
    }
  }

  Future<void> _clearBackupDirectory() async {
    await PreferencesService.setAutoBackupUserDirectory(null);
    setState(() {
      _userDirectory = null;
    });
  }

  Future<void> _triggerManualBackup() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final backupPath = await AutoBackupService.createBackup();
      if (mounted) {
        Navigator.pop(context);
        if (backupPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('auto_backup_success'.tr()),
              action: SnackBarAction(label: 'ok'.tr(), onPressed: () {}),
            ),
          );
          _loadAutoBackupSettings();
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
      if (mounted) {
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

  Future<void> _showRestoreDialog() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final backups = await AutoBackupService.listBackups();
      if (!mounted) return;

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

      if (selectedBackup == null || !mounted) return;

      // Confirm restore
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => ResponsiveDialog.responsiveAlertDialog(
          context: context,
          title: Text('restore_backup_confirmation'.tr()),
          content: Text('restore_backup_warning'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('restore'.tr()),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      // Show progress
      final progressNotifier = ValueNotifier<double>(0.0);
      final messageNotifier = ValueNotifier<String>('starting_restore'.tr());

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
                );
              },
            );
          },
        ),
      );

      final repository = ref.read(habitRepositoryProvider);
      final result = await AutoBackupService.restoreFromBackup(
        selectedBackup.path,
        repository,
        onProgress: (message, prog) {
          messageNotifier.value = message;
          progressNotifier.value = prog;
        },
      );

      if (mounted) {
        Navigator.pop(context);
        progressNotifier.dispose();
        messageNotifier.dispose();

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('restore_success'.tr()),
              action: SnackBarAction(label: 'ok'.tr(), onPressed: () {}),
            ),
          );
        } else {
          _showRestoreResultDialog(context, result);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'restore_error'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRestoreResultDialog(BuildContext context, ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.success
                    ? 'restore_success'.tr()
                    : 'restore_failed'.tr(),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.habitsImported > 0)
                Text('${'habits_imported'.tr()}: ${result.habitsImported}'),
              if (result.entriesImported > 0)
                Text('${'entries_imported'.tr()}: ${result.entriesImported}'),
              if (result.streaksImported > 0)
                Text('${'streaks_imported'.tr()}: ${result.streaksImported}'),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'errors'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...result.errors.map((e) => Text('• $e')),
              ],
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'warnings'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...result.warnings.map((w) => Text('• $w')),
              ],
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = _lastBackup != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(_lastBackup!))
        : null;

    return Column(
      children: [
        // Export subsection
        SettingsSubsectionHeader(
          title: 'settings_section_data_export'.tr(),
          icon: Icons.file_download,
        ),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: Text('export_data'.tr()),
          subtitle: Text('export_habit_data_description'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => widget.showExportDialog(context, ref),
        ),
        // Import subsection
        SettingsSubsectionHeader(
          title: 'settings_section_data_import'.tr(),
          icon: Icons.file_upload,
        ),
        ListTile(
          leading: const Icon(Icons.file_upload),
          title: Text('import_data'.tr()),
          subtitle: Text('import_data_description'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => widget.showImportDialog(context, ref),
        ),
        // Auto Backup subsection
        SettingsSubsectionHeader(
          title: 'settings_section_auto_backup'.tr(),
          icon: Icons.backup,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.backup),
          title: Text('auto_backup_enabled'.tr()),
          subtitle: Text('auto_backup_description'.tr()),
          value: _autoBackupEnabled,
          onChanged: _toggleAutoBackup,
        ),
        if (_autoBackupEnabled) ...[
          ListTile(
            leading: const Icon(Icons.numbers),
            title: Text('auto_backup_retention_count'.tr()),
            subtitle: Text('auto_backup_retention_description'.tr()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _retentionCount > 1
                      ? () => _updateRetentionCount(_retentionCount - 1)
                      : null,
                  tooltip: 'decrease'.tr(),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    '$_retentionCount',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _retentionCount < 100
                      ? () => _updateRetentionCount(_retentionCount + 1)
                      : null,
                  tooltip: 'increase'.tr(),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: Text('auto_backup_directory'.tr()),
            subtitle: Text(_userDirectory ?? 'auto_backup_app_directory'.tr()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_userDirectory != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearBackupDirectory,
                    tooltip: 'clear'.tr(),
                  ),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _selectBackupDirectory,
                  tooltip: 'select_directory'.tr(),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text('auto_backup_last_backup'.tr()),
            subtitle: Text(dateFormat ?? 'auto_backup_never'.tr()),
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: Text('auto_backup_manual_trigger'.tr()),
            subtitle: Text('auto_backup_manual_description'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: _triggerManualBackup,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text('restore_from_backup'.tr()),
            subtitle: Text('restore_from_backup_description'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showRestoreDialog,
          ),
        ],
        // Database subsection
        SettingsSubsectionHeader(
          title: 'settings_section_data_database'.tr(),
          icon: Icons.storage,
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text('database_statistics'.tr()),
          subtitle: Text('view_database_stats'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => widget.showDatabaseStatsDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services),
          title: Text('optimize_database'.tr()),
          subtitle: Text('optimize_database_description'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => widget.optimizeDatabase(context, ref),
        ),
      ],
    );
  }
}

