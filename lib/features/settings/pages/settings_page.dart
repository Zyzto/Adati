import 'dart:io' show Platform, Process;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animations/animations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/services/import_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/database/app_database.dart' as db;
import '../providers/settings_providers.dart';
import '../../habits/widgets/checkbox_style.dart';
import '../../habits/providers/habit_providers.dart';
import '../../habits/widgets/tag_management.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Expansion state for each section
  bool _generalExpanded = true;
  bool _appearanceExpanded = false;
  bool _displayExpanded = false;
  bool _displayPreferencesExpanded = false;
  bool _notificationsExpanded = false;
  bool _tagsExpanded = false;
  bool _dataExportExpanded = false;
  bool _advancedExpanded = false;
  bool _aboutExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadExpansionStates();
  }

  void _loadExpansionStates() {
    setState(() {
      _generalExpanded = PreferencesService.getSettingsGeneralExpanded();
      _appearanceExpanded = PreferencesService.getSettingsAppearanceExpanded();
      _displayExpanded = PreferencesService.getSettingsDisplayExpanded();
      _displayPreferencesExpanded =
          PreferencesService.getSettingsDisplayPreferencesExpanded();
      _notificationsExpanded =
          PreferencesService.getSettingsNotificationsExpanded();
      _tagsExpanded = PreferencesService.getSettingsTagsExpanded();
      _dataExportExpanded = PreferencesService.getSettingsDataExportExpanded();
      _advancedExpanded = PreferencesService.getSettingsAdvancedExpanded();
      _aboutExpanded = PreferencesService.getSettingsAboutExpanded();
    });
  }

  Future<void> _saveExpansionState(String section, bool expanded) async {
    switch (section) {
      case 'general':
        await PreferencesService.setSettingsGeneralExpanded(expanded);
        break;
      case 'appearance':
        await PreferencesService.setSettingsAppearanceExpanded(expanded);
        break;
      case 'display':
        await PreferencesService.setSettingsDisplayExpanded(expanded);
        break;
      case 'displayPreferences':
        await PreferencesService.setSettingsDisplayPreferencesExpanded(
          expanded,
        );
        break;
      case 'notifications':
        await PreferencesService.setSettingsNotificationsExpanded(expanded);
        break;
      case 'tags':
        await PreferencesService.setSettingsTagsExpanded(expanded);
        break;
      case 'dataExport':
        await PreferencesService.setSettingsDataExportExpanded(expanded);
        break;
      case 'advanced':
        await PreferencesService.setSettingsAdvancedExpanded(expanded);
        break;
      case 'about':
        await PreferencesService.setSettingsAboutExpanded(expanded);
        break;
    }
  }

  /// Get package info with error handling for Linux compatibility
  Future<PackageInfo?> _getPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (e) {
      // Fallback for Linux when /proc/self/exe is not available
      // Return null and use fallback values in the UI
      return null;
    }
  }

  /// Launch a URL in the default browser
  Future<void> _launchUrl(String urlString) async {
    // Try url_launcher first, with Linux fallback using xdg-open
    try {
      final uri = Uri.parse(urlString);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return; // Success, exit early
    } on PlatformException {
      // If url_launcher fails on Linux, try xdg-open directly
      if (Platform.isLinux) {
        try {
          await Process.run('xdg-open', [urlString]);
          return; // Success with xdg-open
        } catch (e) {
          // xdg-open also failed, fall through to error handling
        }
      }
    } catch (e) {
      // Other errors, fall through to error handling
    }

    // If all methods failed, show error message with copy option
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'could_not_open_link'.tr(namedArgs: {'url': urlString}),
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'copy'.tr(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: urlString));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('url_copied_to_clipboard'.tr()),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
      );
    }
  }

  void _showLibrariesDialog(BuildContext context) {
    final packages = [
      {
        'name': 'flutter_riverpod',
        'version': '^3.0.1',
        'description': 'State management',
      },
      {
        'name': 'go_router',
        'version': '^17.0.0',
        'description': 'Navigation & routing',
      },
      {
        'name': 'easy_localization',
        'version': '^3.0.7',
        'description': 'Localization & i18n',
      },
      {'name': 'drift', 'version': '^2.18.0', 'description': 'Database ORM'},
      {
        'name': 'shared_preferences',
        'version': '^2.3.3',
        'description': 'Local storage',
      },
      {
        'name': 'file_picker',
        'version': '^10.3.6',
        'description': 'File handling',
      },
      {
        'name': 'url_launcher',
        'version': '^6.3.1',
        'description': 'URL launching',
      },
      {
        'name': 'flutter_local_notifications',
        'version': '^19.5.0',
        'description': 'Notifications',
      },
      {
        'name': 'animations',
        'version': '^2.1.0',
        'description': 'UI animations',
      },
      {
        'name': 'skeletonizer',
        'version': '^2.1.0+1',
        'description': 'Loading skeletons',
      },
      {
        'name': 'package_info_plus',
        'version': '^9.0.0',
        'description': 'App information',
      },
      {
        'name': 'intl',
        'version': '^0.20.2',
        'description': 'Internationalization',
      },
      {
        'name': 'timezone',
        'version': '^0.10.1',
        'description': 'Timezone support',
      },
      {'name': 'easy_logger', 'version': '^0.0.2', 'description': 'Logging'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('packages_used'.tr()),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final package = packages[index];
              return ListTile(
                dense: true,
                title: Text(
                  package['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${package['version']} - ${package['description']}',
                ),
                onTap: () =>
                    _launchUrl('https://pub.dev/packages/${package['name']}'),
                trailing: const Icon(Icons.open_in_new, size: 16),
              );
            },
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

  void _showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('license'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'license_title'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'license_description_full'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'you_are_free_to'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${'license_share'.tr()}'),
              Text('• ${'license_adapt'.tr()}'),
              const SizedBox(height: 16),
              Text(
                'under_following_terms'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${'license_attribution'.tr()}'),
              Text('• ${'license_noncommercial'.tr()}'),
              Text('• ${'license_sharealike'.tr()}'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _launchUrl(
                  'https://creativecommons.org/licenses/by-nc-sa/4.0/',
                ),
                child: Text('view_license'.tr()),
              ),
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

  void _showUsageRightsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('usage_rights'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'terms_and_conditions'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'usage_agreement'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                '1. ${'usage_license_section'.tr()}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('usage_license_text'.tr()),
              const SizedBox(height: 16),
              Text(
                '2. ${'usage_usage_section'.tr()}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${'usage_personal'.tr()}'),
              Text('• ${'usage_modify'.tr()}'),
              Text('• ${'usage_attribution'.tr()}'),
              const SizedBox(height: 16),
              Text(
                '3. ${'usage_limitations_section'.tr()}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${'usage_no_commercial'.tr()}'),
              Text('• ${'usage_no_warranty'.tr()}'),
              Text('• ${'usage_at_own_risk'.tr()}'),
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

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('privacy_policy'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'privacy_policy'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'privacy_data_storage'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('privacy_data_storage_text'.tr()),
              const SizedBox(height: 16),
              Text(
                'privacy_data_collection'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('privacy_data_collection_text'.tr()),
              const SizedBox(height: 16),
              Text(
                'privacy_permissions'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${'privacy_notifications'.tr()}'),
              Text('• ${'privacy_file_access'.tr()}'),
              Text('• ${'privacy_network'.tr()}'),
              const SizedBox(height: 16),
              Text(
                'privacy_your_rights'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('privacy_your_rights_text'.tr()),
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

  // Helper method to build radio list item
  Widget _buildRadioListItem<T>({
    required BuildContext context,
    required Widget title,
    Widget? subtitle,
    required T value,
    required T? groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    final isSelected = value == groupValue;
    final theme = Theme.of(context);
    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Material(
          shape: const CircleBorder(),
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onChanged(value),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  width: 2,
                ),
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
            ),
          ),
        ),
      ),
      onTap: () => onChanged(value),
    );
  }

  // Default values
  static const double defaultCardElevation = 2.0;
  static const double defaultCardBorderRadius = 12.0;
  static const String defaultDaySquareSize = 'large';
  static const int defaultTimelineDays = 100;
  static const int defaultModalTimelineDays = 200;

  String _getLanguageName(String? code) {
    switch (code) {
      case 'en':
        return 'english'.tr();
      case 'ar':
        return 'arabic'.tr();
      default:
        return 'english'.tr();
    }
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light'.tr();
      case ThemeMode.dark:
        return 'dark'.tr();
      case ThemeMode.system:
        return 'system'.tr();
    }
  }

  String _getDaySquareSizeName(String size) {
    switch (size) {
      case 'small':
        return 'small'.tr();
      case 'medium':
        return 'medium'.tr();
      case 'large':
        return 'large'.tr();
      default:
        return 'medium'.tr();
    }
  }

  String _getDateFormatName(String format) {
    switch (format) {
      case 'yyyy-MM-dd':
        return 'YYYY-MM-DD';
      case 'MM/dd/yyyy':
        return 'MM/DD/YYYY';
      case 'dd/MM/yyyy':
        return 'DD/MM/YYYY';
      case 'dd.MM.yyyy':
        return 'DD.MM.YYYY';
      default:
        return format;
    }
  }

  String _getFirstDayOfWeekName(int day) {
    return day == 0 ? 'sunday'.tr() : 'monday'.tr();
  }

  Future<void> _showExportDialog(BuildContext context, WidgetRef ref) async {
    // First, show what to export
    final exportType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
            builder: (context) => AlertDialog(
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

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    final importType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
              return AlertDialog(
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
      _showImportResultDialog(context, result);
    }
  }

  void _showImportResultDialog(BuildContext context, ImportResult result) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.success ? 'import_success'.tr() : 'import_failed'.tr(),
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
                const SizedBox(height: 8),
                Text(
                  'warnings'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...result.warnings.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $w', style: theme.textTheme.bodySmall),
                  ),
                ),
              ],
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'errors'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...result.errors.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $e', style: theme.textTheme.bodySmall),
                  ),
                ),
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

  Widget _buildResultRow(String label, int count, bool isSuccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.warning,
            size: 16,
            color: isSuccess ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatabaseStatsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final repository = ref.read(habitRepositoryProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final stats = await repository.getDatabaseStats();

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('database_statistics'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('habits'.tr(), stats['habits'] ?? 0),
                _buildStatRow('tags'.tr(), stats['tags'] ?? 0),
                _buildStatRow('entries'.tr(), stats['entries'] ?? 0),
                _buildStatRow('streaks'.tr(), stats['streaks'] ?? 0),
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

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetHabitsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('reset_all_habits'.tr()),
        content: Text('reset_all_habits_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('reset'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = ref.read(habitRepositoryProvider);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await repository.deleteAllHabits();

        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('habits_reset_success'.tr()),
              backgroundColor: Colors.green,
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
  }

  Future<void> _showResetSettingsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('reset_all_settings'.tr()),
        content: Text('reset_all_settings_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('reset'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final success = await PreferencesService.resetAllSettings();

        if (context.mounted) {
          Navigator.pop(context); // Close loading

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('settings_reset_success'.tr()),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('settings_reset_failed'.tr()),
                backgroundColor: Colors.red,
              ),
            );
          }
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
  }

  Future<void> _showClearAllDataDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('clear_all_data'.tr()),
        content: Text('clear_all_data_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('clear'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = ref.read(habitRepositoryProvider);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await repository.deleteAllData();
        await PreferencesService.resetAllSettings();

        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('all_data_cleared_success'.tr()),
              backgroundColor: Colors.green,
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
  }

  Future<void> _returnToOnboarding(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('return_to_onboarding'.tr()),
        content: Text('return_to_onboarding_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('continue'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await PreferencesService.setFirstLaunch(true);
      if (context.mounted) {
        context.go('/onboarding');
      }
    }
  }

  Future<void> _optimizeDatabase(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('optimize_database'.tr()),
        content: Text('optimize_database_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('optimize'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = ref.read(habitRepositoryProvider);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await repository.vacuumDatabase();

        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('database_optimized_success'.tr()),
              backgroundColor: Colors.green,
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
  }

  Future<void> _showLogsDialog(BuildContext context, WidgetRef ref) async {
    // Get log file size
    final logSize = await LoggingService.getLogFileSize();
    final crashLogSize = await LoggingService.getCrashLogFileSize();
    final totalSize = logSize + crashLogSize;
    final sizeInMB = (totalSize / (1024 * 1024)).toStringAsFixed(2);

    // Get last crash info
    final lastCrashTime = LoggingService.getLastCrashTime();
    final lastCrashSummary = LoggingService.getLastCrashSummary();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logs'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Log file size
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text('log_file_size'.tr()),
                subtitle: Text(
                  'log_file_size_mb'.tr(namedArgs: {'size': sizeInMB}),
                ),
                dense: true,
              ),
              const Divider(),

              // Last crash info
              if (lastCrashTime != null) ...[
                ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: Text('last_crash'.tr()),
                  subtitle: Text(
                    '${DateFormat('yyyy-MM-dd HH:mm:ss').format(lastCrashTime)}\n${lastCrashSummary ?? ''}',
                  ),
                  dense: true,
                ),
                const Divider(),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('no_crashes'.tr()),
                  dense: true,
                ),
                const Divider(),
              ],

              // Action buttons
              const SizedBox(height: 8),
              SizedBox(
                width: double.maxFinite,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _downloadLogs(context);
                  },
                  icon: const Icon(Icons.download),
                  label: Text('download_logs'.tr()),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.maxFinite,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _clearLogs(context);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text('clear_logs'.tr()),
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.maxFinite,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _sendLogsToGitHub(context);
                  },
                  icon: const Icon(Icons.send),
                  label: Text('send_logs_to_github'.tr()),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadLogs(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final filePath = await LoggingService.exportLogs();

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('logs_downloaded_successfully'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'error'.tr()}: ${'failed_to_export_logs'.tr()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  Future<void> _clearLogs(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('clear_logs'.tr()),
        content: Text('clear_logs_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('clear'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final success = await LoggingService.clearLogs();

        if (context.mounted) {
          Navigator.pop(context); // Close loading

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('logs_cleared_successfully'.tr()),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${'error'.tr()}: ${'failed_to_clear_logs'.tr()}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
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
  }

  Future<void> _sendLogsToGitHub(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('send_logs_to_github'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'github_issue_title'.tr(),
                  hintText: 'github_issue_title_hint'.tr(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'github_issue_description'.tr(),
                  hintText: 'github_issue_description_hint'.tr(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('send_logs'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      if (titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('please_enter_issue_title'.tr()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final success = await LoggingService.sendLogsToGitHub(
          titleController.text.trim(),
          descriptionController.text.trim(),
        );

        if (context.mounted) {
          Navigator.pop(context); // Close loading

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('logs_sent_successfully'.tr()),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${'error'.tr()}: ${'failed_to_send_logs'.tr()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
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
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isExpanded,
    required ValueChanged<bool> onExpansionChanged,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => onExpansionChanged(!isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(children: children)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLanguage = PreferencesService.getLanguage() ?? 'en';
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('select_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('english'.tr()),
              value: 'en',
              groupValue: currentLanguage,
              onChanged: (value) async {
                if (value != null) {
                  await PreferencesService.setLanguage(value);
                  if (dialogContext.mounted) {
                    await dialogContext.setLocale(Locale(value));
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('arabic'.tr()),
              value: 'ar',
              groupValue: currentLanguage,
              onChanged: (value) async {
                if (value != null) {
                  await PreferencesService.setLanguage(value);
                  if (dialogContext.mounted) {
                    await dialogContext.setLocale(Locale(value));
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('select_theme'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<ThemeMode>(
              context: dialogContext,
              title: Text('light'.tr()),
              value: ThemeMode.light,
              groupValue: currentTheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setThemeMode(value);
                  ref.invalidate(themeModeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<ThemeMode>(
              context: dialogContext,
              title: Text('dark'.tr()),
              value: ThemeMode.dark,
              groupValue: currentTheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setThemeMode(value);
                  ref.invalidate(themeModeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<ThemeMode>(
              context: dialogContext,
              title: Text('system'.tr()),
              value: ThemeMode.system,
              groupValue: currentTheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setThemeMode(value);
                  ref.invalidate(themeModeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showThemeColorDialog(BuildContext context, WidgetRef ref) {
    final currentColor = ref.watch(themeColorProvider);
    final notifier = ref.read(themeColorNotifierProvider);
    final navigator = Navigator.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isLandscape = screenWidth > mediaQuery.size.height;
    final maxWidth = 600.0; // Same as settings list max width
    final contentWidth = isLandscape ? maxWidth : screenWidth * 0.5;
    final colors = [
      Colors.deepPurple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.brown,
      Colors.purple,
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('select_theme_color'.tr()),
        content: SizedBox(
          width: contentWidth,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              final colorValue = color.toARGB32();
              final isSelected = colorValue == currentColor;
              return GestureDetector(
                onTap: () async {
                  await notifier.setThemeColor(colorValue);
                  ref.invalidate(themeColorNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showCardStyleDialog(BuildContext context, WidgetRef ref) {
    final initialElevation = ref.watch(cardElevationProvider);
    final initialBorderRadius = ref.watch(cardBorderRadiusProvider);
    final cardStyleNotifier = ref.read(cardStyleNotifierProvider);

    showDialog(
      context: context,
      builder: (context) {
        return _CardStyleDialogContent(
          initialElevation: initialElevation,
          initialBorderRadius: initialBorderRadius,
          cardStyleNotifier: cardStyleNotifier,
          ref: ref,
        );
      },
    );
  }

  void _showDaySquareSizeDialog(BuildContext context, WidgetRef ref) {
    final currentSize = ref.watch(daySquareSizeProvider);
    final notifier = ref.read(daySquareSizeNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('day_square_size'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('small'.tr()),
              value: 'small',
              groupValue: currentSize,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setDaySquareSize(value);
                  ref.invalidate(daySquareSizeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('medium'.tr()),
              value: 'medium',
              groupValue: currentSize,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setDaySquareSize(value);
                  ref.invalidate(daySquareSizeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('large'.tr()),
              value: 'large',
              groupValue: currentSize,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setDaySquareSize(value);
                  ref.invalidate(daySquareSizeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDateFormatDialog(BuildContext context, WidgetRef ref) {
    final currentFormat = ref.watch(dateFormatProvider);
    final notifier = ref.read(dateFormatNotifierProvider);
    final navigator = Navigator.of(context);
    final formats = ['yyyy-MM-dd', 'MM/dd/yyyy', 'dd/MM/yyyy', 'dd.MM.yyyy'];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('date_format'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats.map((format) {
            return _buildRadioListItem<String>(
              context: dialogContext,
              title: Text(_getDateFormatName(format)),
              subtitle: Text(DateTime.now().toString().split(' ')[0]),
              value: format,
              groupValue: currentFormat,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setDateFormat(value);
                  ref.invalidate(dateFormatNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showFirstDayOfWeekDialog(BuildContext context, WidgetRef ref) {
    final currentDay = ref.watch(firstDayOfWeekProvider);
    final notifier = ref.read(firstDayOfWeekNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('first_day_of_week'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<int>(
              context: dialogContext,
              title: Text('sunday'.tr()),
              value: 0,
              groupValue: currentDay,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setFirstDayOfWeek(value);
                  ref.invalidate(firstDayOfWeekNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<int>(
              context: dialogContext,
              title: Text('monday'.tr()),
              value: 1,
              groupValue: currentDay,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setFirstDayOfWeek(value);
                  ref.invalidate(firstDayOfWeekNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showHabitCheckboxStyleDialog(BuildContext context, WidgetRef ref) {
    final currentStyle = ref.watch(habitCheckboxStyleProvider);
    final notifier = ref.read(habitCheckboxStyleNotifierProvider);
    final navigator = Navigator.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isLandscape = screenWidth > mediaQuery.size.height;
    final maxWidth = 600.0; // Same as settings list max width
    final contentWidth = isLandscape ? maxWidth : screenWidth * 0.5;

    final styles = HabitCheckboxStyle.values;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('habit_checkbox_style'.tr()),
        content: SizedBox(
          width: contentWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: styles.map((style) {
              final styleString = habitCheckboxStyleToString(style);
              return _buildRadioListItem<String>(
                context: dialogContext,
                title: Row(
                  children: [
                    Text(_getCheckboxStyleName(styleString)),
                    const SizedBox(width: 16),
                    // Preview: completed state
                    buildCheckboxWidget(style, true, 24, null),
                    const SizedBox(width: 8),
                    // Preview: uncompleted state
                    buildCheckboxWidget(style, false, 24, null),
                  ],
                ),
                value: styleString,
                groupValue: currentStyle,
                onChanged: (value) async {
                  if (value != null) {
                    await notifier.setHabitCheckboxStyle(value);
                    ref.invalidate(habitCheckboxStyleNotifierProvider);
                    if (dialogContext.mounted) {
                      navigator.pop();
                    }
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  String _getCheckboxStyleName(String style) {
    switch (style) {
      case 'square':
        return 'square'.tr();
      case 'bordered':
        return 'bordered'.tr();
      case 'circle':
        return 'circle'.tr();
      case 'radio':
        return 'radio'.tr();
      case 'task':
        return 'task'.tr();
      case 'verified':
        return 'verified'.tr();
      case 'taskAlt':
        return 'task_alt'.tr();
      default:
        return style;
    }
  }

  Future<void> _revertCardStyle(BuildContext context, WidgetRef ref) async {
    final cardStyleNotifier = ref.read(cardStyleNotifierProvider);
    await cardStyleNotifier.setElevation(defaultCardElevation);
    await cardStyleNotifier.setBorderRadius(defaultCardBorderRadius);
    ref.invalidate(cardStyleNotifierProvider);
  }

  Future<void> _revertDaySquareSize(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(daySquareSizeNotifierProvider);
    await notifier.setDaySquareSize(defaultDaySquareSize);
    ref.invalidate(daySquareSizeNotifierProvider);
  }

  Future<void> _revertTimelineDays(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(timelineDaysNotifierProvider);
    await notifier.setTimelineDays(defaultTimelineDays);
    ref.invalidate(timelineDaysNotifierProvider);
  }

  Future<void> _revertModalTimelineDays(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final notifier = ref.read(modalTimelineDaysNotifierProvider);
    await notifier.setModalTimelineDays(defaultModalTimelineDays);
    ref.invalidate(modalTimelineDaysNotifierProvider);
  }

  void _showTimelineDaysDialog(BuildContext context, WidgetRef ref) {
    final currentDays = ref.watch(timelineDaysProvider);
    final notifier = ref.read(timelineDaysNotifierProvider);
    final navigator = Navigator.of(context);
    final controller = TextEditingController(text: currentDays.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('timeline_days'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'number_of_days_to_show'.tr(),
                hintText: 'enter_number_of_days'.tr(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final days = int.tryParse(controller.text);
              if (days != null && days > 0) {
                await notifier.setTimelineDays(days);
                ref.invalidate(timelineDaysNotifierProvider);
                if (dialogContext.mounted) {
                  navigator.pop();
                }
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  void _showModalTimelineDaysDialog(BuildContext context, WidgetRef ref) {
    final currentDays = ref.watch(modalTimelineDaysProvider);
    final notifier = ref.read(modalTimelineDaysNotifierProvider);
    final navigator = Navigator.of(context);
    final controller = TextEditingController(text: currentDays.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('modal_timeline_days'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'number_of_days_to_show'.tr(),
                hintText: 'enter_number_of_days'.tr(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final days = int.tryParse(controller.text);
              if (days != null && days > 0) {
                await notifier.setModalTimelineDays(days);
                ref.invalidate(modalTimelineDaysNotifierProvider);
                if (dialogContext.mounted) {
                  navigator.pop();
                }
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  // Display Preferences Helper Methods
  String _getIconSizeName(String size) {
    switch (size) {
      case 'small':
        return 'small'.tr();
      case 'medium':
        return 'medium'.tr();
      case 'large':
        return 'large'.tr();
      default:
        return 'medium'.tr();
    }
  }

  String _getProgressIndicatorStyleName(String style) {
    switch (style) {
      case 'circular':
        return 'circular'.tr();
      case 'linear':
        return 'linear'.tr();
      default:
        return 'circular'.tr();
    }
  }

  String _getStreakColorSchemeName(String scheme) {
    switch (scheme) {
      case 'default':
        return 'default'.tr();
      case 'vibrant':
        return 'vibrant'.tr();
      case 'subtle':
        return 'subtle'.tr();
      case 'monochrome':
        return 'monochrome'.tr();
      default:
        return 'default'.tr();
    }
  }

  String _getFontSizeScaleName(String scale) {
    switch (scale) {
      case 'small':
        return 'small'.tr();
      case 'normal':
        return 'normal'.tr();
      case 'large':
        return 'large'.tr();
      case 'extra_large':
        return 'extra_large'.tr();
      default:
        return 'normal'.tr();
    }
  }

  String _getDefaultViewName(String view) {
    switch (view) {
      case 'habits':
        return 'habits'.tr();
      case 'timeline':
        return 'timeline'.tr();
      default:
        return 'habits'.tr();
    }
  }

  // Display Preferences Dialog Methods
  void _showTimelineSpacingDialog(BuildContext context, WidgetRef ref) {
    final currentSpacing = ref.watch(timelineSpacingProvider);
    final notifier = ref.read(timelineSpacingNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          double spacing = currentSpacing;
          return AlertDialog(
            title: Text('timeline_spacing'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${spacing.toStringAsFixed(1)}px'),
                Slider(
                  value: spacing,
                  min: 4.0,
                  max: 12.0,
                  divisions: 16,
                  onChanged: (value) {
                    setDialogState(() {
                      spacing = value;
                    });
                    notifier.setTimelineSpacing(value);
                    ref.invalidate(timelineSpacingNotifierProvider);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(),
                child: Text('done'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showIconSizeDialog(BuildContext context, WidgetRef ref) {
    final currentSize = ref.watch(iconSizeProvider);
    final notifier = ref.read(iconSizeNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('icon_size'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('small'.tr()),
              value: 'small',
              groupValue: currentSize,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setIconSize(value);
                  ref.invalidate(iconSizeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('medium'.tr()),
              value: 'medium',
              groupValue: currentSize,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setIconSize(value);
                  ref.invalidate(iconSizeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('large'.tr()),
              value: 'large',
              groupValue: currentSize,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setIconSize(value);
                  ref.invalidate(iconSizeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showProgressIndicatorStyleDialog(BuildContext context, WidgetRef ref) {
    final currentStyle = ref.watch(progressIndicatorStyleProvider);
    final notifier = ref.read(progressIndicatorStyleNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('progress_indicator_style'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('circular'.tr()),
              value: 'circular',
              groupValue: currentStyle,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setProgressIndicatorStyle(value);
                  ref.invalidate(progressIndicatorStyleNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('linear'.tr()),
              value: 'linear',
              groupValue: currentStyle,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setProgressIndicatorStyle(value);
                  ref.invalidate(progressIndicatorStyleNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showCompletionColorDialog(BuildContext context, WidgetRef ref) {
    final currentColor = ref.watch(completionColorProvider);
    final notifier = ref.read(completionColorNotifierProvider);
    final navigator = Navigator.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isLandscape = screenWidth > mediaQuery.size.height;
    final maxWidth = 600.0;
    final contentWidth = isLandscape ? maxWidth : screenWidth * 0.5;
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.pink,
      Colors.brown,
      Colors.grey,
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('completion_color'.tr()),
        content: SizedBox(
          width: contentWidth,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              final colorValue = color.toARGB32();
              final isSelected = colorValue == currentColor;
              return GestureDetector(
                onTap: () async {
                  await notifier.setCompletionColor(colorValue);
                  ref.invalidate(completionColorNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showStreakColorSchemeDialog(BuildContext context, WidgetRef ref) {
    final currentScheme = ref.watch(streakColorSchemeProvider);
    final notifier = ref.read(streakColorSchemeNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('streak_color_scheme'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('default'.tr()),
              value: 'default',
              groupValue: currentScheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setStreakColorScheme(value);
                  ref.invalidate(streakColorSchemeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('vibrant'.tr()),
              value: 'vibrant',
              groupValue: currentScheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setStreakColorScheme(value);
                  ref.invalidate(streakColorSchemeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('subtle'.tr()),
              value: 'subtle',
              groupValue: currentScheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setStreakColorScheme(value);
                  ref.invalidate(streakColorSchemeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('monochrome'.tr()),
              value: 'monochrome',
              groupValue: currentScheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setStreakColorScheme(value);
                  ref.invalidate(streakColorSchemeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showFontSizeScaleDialog(BuildContext context, WidgetRef ref) {
    final currentScale = ref.watch(fontSizeScaleProvider);
    final notifier = ref.read(fontSizeScaleNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('font_size_scale'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('small'.tr()),
              value: 'small',
              groupValue: currentScale,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setFontSizeScale(value);
                  ref.invalidate(fontSizeScaleNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('normal'.tr()),
              value: 'normal',
              groupValue: currentScale,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setFontSizeScale(value);
                  ref.invalidate(fontSizeScaleNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('large'.tr()),
              value: 'large',
              groupValue: currentScale,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setFontSizeScale(value);
                  ref.invalidate(fontSizeScaleNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('extra_large'.tr()),
              value: 'extra_large',
              groupValue: currentScale,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setFontSizeScale(value);
                  ref.invalidate(fontSizeScaleNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showCardSpacingDialog(BuildContext context, WidgetRef ref) {
    final currentSpacing = ref.watch(cardSpacingProvider);
    final notifier = ref.read(cardSpacingNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          double spacing = currentSpacing;
          return AlertDialog(
            title: Text('card_spacing'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${spacing.toStringAsFixed(1)}px'),
                Slider(
                  value: spacing,
                  min: 8.0,
                  max: 24.0,
                  divisions: 32,
                  onChanged: (value) {
                    setDialogState(() {
                      spacing = value;
                    });
                    notifier.setCardSpacing(value);
                    ref.invalidate(cardSpacingNotifierProvider);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(),
                child: Text('done'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDefaultViewDialog(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(defaultViewProvider);
    final notifier = ref.read(defaultViewNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('default_view'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('habits'.tr()),
              value: 'habits',
              groupValue: currentView,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setDefaultView(value);
                  ref.invalidate(defaultViewNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('timeline'.tr()),
              value: 'timeline',
              groupValue: currentView,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setDefaultView(value);
                  ref.invalidate(defaultViewNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = PreferencesService.getLanguage() ?? 'en';
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);
    final cardElevation = ref.watch(cardElevationProvider);
    final cardBorderRadius = ref.watch(cardBorderRadiusProvider);
    final daySquareSize = ref.watch(daySquareSizeProvider);
    final dateFormat = ref.watch(dateFormatProvider);
    final firstDayOfWeek = ref.watch(firstDayOfWeekProvider);
    final timelineDays = ref.watch(timelineDaysProvider);
    final modalTimelineDays = ref.watch(modalTimelineDaysProvider);
    final habitCheckboxStyle = ref.watch(habitCheckboxStyleProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final notificationsNotifier = ref.read(
      notificationsEnabledNotifierProvider,
    );
    // Display Preferences
    final showStreakBorders = ref.watch(showStreakBordersProvider);
    final timelineCompactMode = ref.watch(timelineCompactModeProvider);
    final showWeekMonthHighlights = ref.watch(showWeekMonthHighlightsProvider);
    final timelineSpacing = ref.watch(timelineSpacingProvider);
    final showStreakNumbers = ref.watch(showStreakNumbersProvider);
    final showDescriptions = ref.watch(showDescriptionsProvider);
    final compactCards = ref.watch(compactCardsProvider);
    final iconSize = ref.watch(iconSizeProvider);
    final progressIndicatorStyle = ref.watch(progressIndicatorStyleProvider);
    final completionColor = ref.watch(completionColorProvider);
    final streakColorScheme = ref.watch(streakColorSchemeProvider);
    final showPercentage = ref.watch(showPercentageProvider);
    final fontSizeScale = ref.watch(fontSizeScaleProvider);
    final cardSpacing = ref.watch(cardSpacingProvider);
    final showStatisticsCard = ref.watch(showStatisticsCardProvider);
    final defaultView = ref.watch(defaultViewProvider);
    final showStreakOnCard = ref.watch(showStreakOnCardProvider);

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
    final maxWidth = 600.0; // Maximum width for the centered content

    final settingsList = ListView(
      children: [
        // General Section
        _buildCollapsibleSection(
          title: 'general'.tr(),
          icon: Icons.settings,
          isExpanded: _generalExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _generalExpanded = expanded;
            });
            _saveExpansionState('general', expanded);
          },
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: Text('language'.tr()),
              subtitle: Text(_getLanguageName(currentLanguage)),
              onTap: () => _showLanguageDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text('theme'.tr()),
              subtitle: Text(_getThemeName(themeMode)),
              onTap: () => _showThemeDialog(context, ref),
            ),
          ],
        ),

        // Appearance Section
        _buildCollapsibleSection(
          title: 'appearance'.tr(),
          icon: Icons.palette,
          isExpanded: _appearanceExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _appearanceExpanded = expanded;
            });
            _saveExpansionState('appearance', expanded);
          },
          children: [
            ListTile(
              leading: const Icon(Icons.palette),
              title: Text('select_theme_color'.tr()),
              trailing: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(themeColor),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1.5,
                  ),
                ),
              ),
              onTap: () => _showThemeColorDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.style),
              title: Text('card_style'.tr()),
              subtitle: Text(
                '${'elevation'.tr()}: ${cardElevation.toStringAsFixed(1)}, ${'border_radius'.tr()}: ${cardBorderRadius.toStringAsFixed(1)}',
              ),
              trailing:
                  (cardElevation != defaultCardElevation ||
                      cardBorderRadius != defaultCardBorderRadius)
                  ? IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'reset_to_default'.tr(),
                      onPressed: () => _revertCardStyle(context, ref),
                    )
                  : null,
              onTap: () => _showCardStyleDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.square),
              title: Text('day_square_size'.tr()),
              subtitle: Text(_getDaySquareSizeName(daySquareSize)),
              trailing: daySquareSize != defaultDaySquareSize
                  ? IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'reset_to_default'.tr(),
                      onPressed: () => _revertDaySquareSize(context, ref),
                    )
                  : null,
              onTap: () => _showDaySquareSizeDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.check_box),
              title: Text('habit_checkbox_style'.tr()),
              subtitle: Text(_getCheckboxStyleName(habitCheckboxStyle)),
              onTap: () => _showHabitCheckboxStyleDialog(context, ref),
            ),
          ],
        ),

        // Display Section
        _buildCollapsibleSection(
          title: 'display'.tr(),
          icon: Icons.display_settings,
          isExpanded: _displayExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _displayExpanded = expanded;
            });
            _saveExpansionState('display', expanded);
          },
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('date_format'.tr()),
              subtitle: Text(_getDateFormatName(dateFormat)),
              onTap: () => _showDateFormatDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.view_week),
              title: Text('first_day_of_week'.tr()),
              subtitle: Text(_getFirstDayOfWeekName(firstDayOfWeek)),
              onTap: () => _showFirstDayOfWeekDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_week),
              title: Text('timeline_days'.tr()),
              subtitle: Text('$timelineDays ${'days'.tr()}'),
              trailing: timelineDays != defaultTimelineDays
                  ? IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'reset_to_default'.tr(),
                      onPressed: () => _revertTimelineDays(context, ref),
                    )
                  : null,
              onTap: () => _showTimelineDaysDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.view_timeline),
              title: Text('modal_timeline_days'.tr()),
              subtitle: Text('$modalTimelineDays ${'days'.tr()}'),
              trailing: modalTimelineDays != defaultModalTimelineDays
                  ? IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'reset_to_default'.tr(),
                      onPressed: () => _revertModalTimelineDays(context, ref),
                    )
                  : null,
              onTap: () => _showModalTimelineDaysDialog(context, ref),
            ),
          ],
        ),

        // Display Preferences Section
        _buildCollapsibleSection(
          title: 'display_preferences'.tr(),
          icon: Icons.tune,
          isExpanded: _displayPreferencesExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _displayPreferencesExpanded = expanded;
            });
            _saveExpansionState('displayPreferences', expanded);
          },
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.border_color),
              title: Text('show_streak_borders'.tr()),
              subtitle: Text('show_streak_borders_description'.tr()),
              value: showStreakBorders,
              onChanged: (value) async {
                final notifier = ref.read(showStreakBordersNotifierProvider);
                await notifier.setShowStreakBorders(value);
                ref.invalidate(showStreakBordersNotifierProvider);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.compress),
              title: Text('timeline_compact_mode'.tr()),
              subtitle: Text('timeline_compact_mode_description'.tr()),
              value: timelineCompactMode,
              onChanged: (value) async {
                final notifier = ref.read(timelineCompactModeNotifierProvider);
                await notifier.setTimelineCompactMode(value);
                ref.invalidate(timelineCompactModeNotifierProvider);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.highlight),
              title: Text('show_week_month_highlights'.tr()),
              subtitle: Text('show_week_month_highlights_description'.tr()),
              value: showWeekMonthHighlights,
              onChanged: (value) async {
                final notifier = ref.read(
                  showWeekMonthHighlightsNotifierProvider,
                );
                await notifier.setShowWeekMonthHighlights(value);
                ref.invalidate(showWeekMonthHighlightsNotifierProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.space_bar),
              title: Text('timeline_spacing'.tr()),
              subtitle: Text('${timelineSpacing.toStringAsFixed(1)}px'),
              onTap: () => _showTimelineSpacingDialog(context, ref),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.numbers),
              title: Text('show_streak_numbers'.tr()),
              subtitle: Text('show_streak_numbers_description'.tr()),
              value: showStreakNumbers,
              onChanged: (value) async {
                final notifier = ref.read(showStreakNumbersNotifierProvider);
                await notifier.setShowStreakNumbers(value);
                ref.invalidate(showStreakNumbersNotifierProvider);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.description),
              title: Text('show_descriptions'.tr()),
              subtitle: Text('show_descriptions_description'.tr()),
              value: showDescriptions,
              onChanged: (value) async {
                final notifier = ref.read(showDescriptionsNotifierProvider);
                await notifier.setShowDescriptions(value);
                ref.invalidate(showDescriptionsNotifierProvider);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.view_compact),
              title: Text('compact_cards'.tr()),
              subtitle: Text('compact_cards_description'.tr()),
              value: compactCards,
              onChanged: (value) async {
                final notifier = ref.read(compactCardsNotifierProvider);
                await notifier.setCompactCards(value);
                ref.invalidate(compactCardsNotifierProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: Text('icon_size'.tr()),
              subtitle: Text(_getIconSizeName(iconSize)),
              onTap: () => _showIconSizeDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: Text('progress_indicator_style'.tr()),
              subtitle: Text(
                _getProgressIndicatorStyleName(progressIndicatorStyle),
              ),
              onTap: () => _showProgressIndicatorStyleDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.palette),
              title: Text('completion_color'.tr()),
              trailing: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(completionColor),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1.5,
                  ),
                ),
              ),
              onTap: () => _showCompletionColorDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: Text('streak_color_scheme'.tr()),
              subtitle: Text(_getStreakColorSchemeName(streakColorScheme)),
              onTap: () => _showStreakColorSchemeDialog(context, ref),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.percent),
              title: Text('show_percentage'.tr()),
              subtitle: Text('show_percentage_description'.tr()),
              value: showPercentage,
              onChanged: (value) async {
                final notifier = ref.read(showPercentageNotifierProvider);
                await notifier.setShowPercentage(value);
                ref.invalidate(showPercentageNotifierProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: Text('font_size_scale'.tr()),
              subtitle: Text(_getFontSizeScaleName(fontSizeScale)),
              onTap: () => _showFontSizeScaleDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.format_line_spacing),
              title: Text('card_spacing'.tr()),
              subtitle: Text('${cardSpacing.toStringAsFixed(1)}px'),
              onTap: () => _showCardSpacingDialog(context, ref),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.bar_chart),
              title: Text('show_statistics_card'.tr()),
              subtitle: Text('show_statistics_card_description'.tr()),
              value: showStatisticsCard,
              onChanged: (value) async {
                final notifier = ref.read(showStatisticsCardNotifierProvider);
                await notifier.setShowStatisticsCard(value);
                ref.invalidate(showStatisticsCardNotifierProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text('default_view'.tr()),
              subtitle: Text(_getDefaultViewName(defaultView)),
              onTap: () => _showDefaultViewDialog(context, ref),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.local_fire_department),
              title: Text('show_streak_on_card'.tr()),
              subtitle: Text('show_streak_on_card_description'.tr()),
              value: showStreakOnCard,
              onChanged: (value) async {
                final notifier = ref.read(showStreakOnCardNotifierProvider);
                await notifier.setShowStreakOnCard(value);
                ref.invalidate(showStreakOnCardNotifierProvider);
              },
            ),
          ],
        ),

        // Notifications Section
        _buildCollapsibleSection(
          title: 'notifications'.tr(),
          icon: Icons.notifications,
          isExpanded: _notificationsExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _notificationsExpanded = expanded;
            });
            _saveExpansionState('notifications', expanded);
          },
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: Text('enable_notifications'.tr()),
              subtitle: Text('receive_habit_reminders'.tr()),
              value: notificationsEnabled,
              onChanged: (value) async {
                await notificationsNotifier.setNotificationsEnabled(value);
                ref.invalidate(notificationsEnabledNotifierProvider);
              },
            ),
          ],
        ),
        // Tags Section
        _buildCollapsibleSection(
          title: 'tags'.tr(),
          icon: Icons.label,
          isExpanded: _tagsExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _tagsExpanded = expanded;
            });
            _saveExpansionState('tags', expanded);
          },
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TagManagementWidget(),
            ),
          ],
        ),
        // Data & Export Section
        _buildCollapsibleSection(
          title: 'data_export'.tr(),
          icon: Icons.folder,
          isExpanded: _dataExportExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _dataExportExpanded = expanded;
            });
            _saveExpansionState('dataExport', expanded);
          },
          children: [
            ListTile(
              leading: const Icon(Icons.file_download),
              title: Text('export_data'.tr()),
              subtitle: Text('export_habit_data_description'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showExportDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: Text('import_data'.tr()),
              subtitle: Text('import_data_description'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showImportDialog(context, ref),
            ),
          ],
        ),

        // Advanced Section
        _buildCollapsibleSection(
          title: 'advanced'.tr(),
          icon: Icons.settings_applications,
          isExpanded: _advancedExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _advancedExpanded = expanded;
            });
            _saveExpansionState('advanced', expanded);
          },
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text('database_statistics'.tr()),
              subtitle: Text('view_database_stats'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDatabaseStatsDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: Text('reset_all_habits'.tr()),
              subtitle: Text('reset_all_habits_description'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showResetHabitsDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: Text('reset_all_settings'.tr()),
              subtitle: Text('reset_all_settings_description'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showResetSettingsDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: Text('clear_all_data'.tr()),
              subtitle: Text('clear_all_data_description'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showClearAllDataDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: Text('optimize_database'.tr()),
              subtitle: Text('optimize_database_description'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _optimizeDatabase(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: Text('logs'.tr()),
              subtitle: Text('logs_description'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLogsDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: Text('return_to_onboarding'.tr()),
              subtitle: Text('return_to_onboarding_description'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _returnToOnboarding(context),
            ),
          ],
        ),

        // About Section
        _buildCollapsibleSection(
          title: 'about'.tr(),
          icon: Icons.info,
          isExpanded: _aboutExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _aboutExpanded = expanded;
            });
            _saveExpansionState('about', expanded);
          },
          children: [
            FutureBuilder<PackageInfo?>(
              future: _getPackageInfo(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    leading: const CircularProgressIndicator(),
                    title: Text('loading'.tr()),
                  );
                }

                // Use fallback values if PackageInfo fails (e.g., on Linux)
                final packageInfo = snapshot.data;
                final appName = packageInfo?.appName ?? 'Adati';
                final version = packageInfo?.version ?? '0.1.0';
                final buildNumber = packageInfo?.buildNumber ?? '1';
                final packageName = packageInfo?.packageName ?? 'adati';

                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.apps),
                      title: Text('app_name'.tr()),
                      subtitle: Text(appName),
                    ),
                    ListTile(
                      leading: const Icon(Icons.tag),
                      title: Text('version'.tr()),
                      subtitle: Text('$version ($buildNumber)'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: Text('description'.tr()),
                      subtitle: Text('app_description'.tr()),
                    ),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: Text('package_name'.tr()),
                      subtitle: Text(packageName),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text('developer'.tr()),
                      subtitle: const Text('Shenepoy'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.code_off),
                      title: Text('open_source_libraries'.tr()),
                      subtitle: Text('open_source_libraries_description'.tr()),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLibrariesDialog(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.gavel),
                      title: Text('license'.tr()),
                      subtitle: Text('license_description'.tr()),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLicenseDialog(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text('usage_rights'.tr()),
                      subtitle: Text('usage_rights_description'.tr()),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showUsageRightsDialog(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: Text('privacy_policy'.tr()),
                      subtitle: Text('privacy_policy_description'.tr()),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showPrivacyPolicyDialog(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: Text('github'.tr()),
                      subtitle: Text('view_source_code_on_github'.tr()),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _launchUrl('https://github.com/Zyzto/Adati'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.bug_report),
                      title: Text('report_issue'.tr()),
                      subtitle: Text('report_issue_description'.tr()),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _launchUrl(
                        'https://github.com/Zyzto/Adati/issues/new',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.lightbulb_outline),
                      title: Text('suggest_feature'.tr()),
                      subtitle: Text('suggest_feature_description'.tr()),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _launchUrl(
                        'https://github.com/Zyzto/Adati/issues/new?template=feature_request.md',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );

    final bodyContent = isLandscape
        ? Center(
            key: const ValueKey('landscape'),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: settingsList,
            ),
          )
        : Container(key: const ValueKey('portrait'), child: settingsList);

    if (isLandscape) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                AppBar(
                  title: Text('settings'.tr()),
                  automaticallyImplyLeading: true,
                ),
                Expanded(
                  child: PageTransitionSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (
                          Widget child,
                          Animation<double> primaryAnimation,
                          Animation<double> secondaryAnimation,
                        ) {
                          return SharedAxisTransition(
                            animation: primaryAnimation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.horizontal,
                            fillColor: Colors.transparent,
                            child: child,
                          );
                        },
                    child: bodyContent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder:
            (
              Widget child,
              Animation<double> primaryAnimation,
              Animation<double> secondaryAnimation,
            ) {
              return SharedAxisTransition(
                animation: primaryAnimation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.horizontal,
                fillColor: Colors.transparent,
                child: child,
              );
            },
        child: bodyContent,
      ),
    );
  }
}

class _CardStyleDialogContent extends StatefulWidget {
  final double initialElevation;
  final double initialBorderRadius;
  final dynamic cardStyleNotifier;
  final dynamic ref;

  const _CardStyleDialogContent({
    required this.initialElevation,
    required this.initialBorderRadius,
    required this.cardStyleNotifier,
    required this.ref,
  });

  @override
  State<_CardStyleDialogContent> createState() =>
      _CardStyleDialogContentState();
}

class _CardStyleDialogContentState extends State<_CardStyleDialogContent> {
  late double _elevation;
  late double _borderRadius;

  @override
  void initState() {
    super.initState();
    _elevation = widget.initialElevation;
    _borderRadius = widget.initialBorderRadius;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('card_style'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${'elevation'.tr()}: ${_elevation.toStringAsFixed(1)}'),
          Slider(
            value: _elevation,
            min: 0,
            max: 8,
            divisions: 16,
            onChanged: (value) {
              setState(() {
                _elevation = value;
              });
              widget.cardStyleNotifier.setElevation(value);
              widget.ref.invalidate(cardStyleNotifierProvider);
            },
          ),
          const SizedBox(height: 16),
          Text('${'border_radius'.tr()}: ${_borderRadius.toStringAsFixed(1)}'),
          Slider(
            value: _borderRadius,
            min: 0,
            max: 24,
            divisions: 48,
            onChanged: (value) {
              setState(() {
                _borderRadius = value;
              });
              widget.cardStyleNotifier.setBorderRadius(value);
              widget.ref.invalidate(cardStyleNotifierProvider);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('done'.tr()),
        ),
      ],
    );
  }
}
