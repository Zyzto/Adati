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
import '../../habits/widgets/components/checkbox_style.dart';
import '../../habits/providers/habit_providers.dart';

// Modular section widgets
import '../widgets/sections/general_section.dart';
import '../widgets/sections/appearance_section.dart';
import '../widgets/sections/display_section.dart';
import '../widgets/sections/date_time_section.dart';
import '../widgets/sections/notifications_section.dart';
import '../widgets/sections/tags_section.dart';
import '../widgets/sections/data_section.dart';
import '../widgets/sections/advanced_section.dart';
import '../widgets/sections/about_section.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Expansion state for each section
  bool _generalExpanded = true;
  bool _appearanceExpanded = false;
  bool _dateTimeExpanded = false;
  bool _displayLayoutExpanded = false;
  bool _notificationsExpanded = false;
  bool _tagsExpanded = false;
  bool _dataExportExpanded = false;
  bool _advancedExpanded = false;
  bool _aboutExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
    _loadExpansionStates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    if (query == _searchQuery) return;
    setState(() {
      _searchQuery = query;
    });
  }

  void _loadExpansionStates() {
    setState(() {
      _generalExpanded = PreferencesService.getSettingsGeneralExpanded();
      _appearanceExpanded = PreferencesService.getSettingsAppearanceExpanded();
      // Migrate from old display/displayPreferences keys to new displayLayout key
      final oldDisplayExpanded =
          PreferencesService.getSettingsDisplayExpanded();
      final oldDisplayPreferencesExpanded =
          PreferencesService.getSettingsDisplayPreferencesExpanded();
      // If either old section was expanded, expand the new merged section
      // Otherwise, use the new key if it exists
      if (oldDisplayExpanded || oldDisplayPreferencesExpanded) {
        _displayLayoutExpanded = true;
        // Migrate the state to the new key
        PreferencesService.setSettingsDisplayLayoutExpanded(true);
      } else {
        _displayLayoutExpanded =
            PreferencesService.getSettingsDisplayLayoutExpanded();
      }
      // Use the legacy display-expanded key to store Date & Time section state
      _dateTimeExpanded = oldDisplayExpanded;
      _notificationsExpanded =
          PreferencesService.getSettingsNotificationsExpanded();
      _tagsExpanded = PreferencesService.getSettingsTagsExpanded();
      _dataExportExpanded = PreferencesService.getSettingsDataExportExpanded();
      _advancedExpanded = PreferencesService.getSettingsAdvancedExpanded();
      _aboutExpanded = PreferencesService.getSettingsAboutExpanded();
    });
  }

  String _keyToSearchText(String key) {
    return key.replaceAll('_', ' ');
  }

  List<Widget> _filterSectionChildren(
    String sectionTitle,
    List<Widget> children, {
    List<String>? tags,
  }) {
    if (_searchQuery.isEmpty) return children;

    final query = _searchQuery.toLowerCase();

    bool matchesText(String? text) {
      if (text == null) return false;
      return text.toLowerCase().contains(query);
    }

    // If the section title itself matches, keep all children.
    if (matchesText(sectionTitle)) {
      return children;
    }

    bool widgetMatches(Widget child, String? extraText) {
      if (child is ListTile) {
        final titleWidget = child.title;
        final subtitleWidget = child.subtitle;
        String? titleText;
        String? subtitleText;

        if (titleWidget is Text) {
          titleText = titleWidget.data;
        }
        if (subtitleWidget is Text) {
          subtitleText = subtitleWidget.data;
        }
        if (matchesText(titleText) || matchesText(subtitleText)) {
          return true;
        }
        if (extraText != null && matchesText(extraText)) {
          return true;
        }
        return false;
      }

      if (child is SwitchListTile) {
        final titleWidget = child.title;
        final subtitleWidget = child.subtitle;
        String? titleText;
        String? subtitleText;

        if (titleWidget is Text) {
          titleText = titleWidget.data;
        }
        if (subtitleWidget is Text) {
          subtitleText = subtitleWidget.data;
        }
        if (matchesText(titleText) || matchesText(subtitleText)) {
          return true;
        }
        if (extraText != null && matchesText(extraText)) {
          return true;
        }
        return false;
      }

      if (extraText != null && matchesText(extraText)) {
        return true;
      }

      return false;
    }

    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final tagText = (tags != null && i < tags.length) ? tags[i] : null;
      if (widgetMatches(child, tagText)) {
        result.add(child);
      }
    }
    return result;
  }

  Future<void> _saveExpansionState(String section, bool expanded) async {
    switch (section) {
      case 'general':
        await PreferencesService.setSettingsGeneralExpanded(expanded);
        break;
      case 'appearance':
        await PreferencesService.setSettingsAppearanceExpanded(expanded);
        break;
      case 'dateTime':
        await PreferencesService.setSettingsDisplayExpanded(expanded);
        break;
      case 'displayLayout':
        await PreferencesService.setSettingsDisplayLayoutExpanded(expanded);
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
  static const String defaultDaySquareSize = 'large';
  static const int defaultTimelineDays = 100;
  static const int defaultModalTimelineDays = 100;
  static const int defaultHabitCardTimelineDays = 50;

  String _getDateFormatName(String format) {
    switch (format) {
      case 'yyyy-MM-dd':
        return 'date_format_yyyy_mm_dd'.tr();
      case 'MM/dd/yyyy':
        return 'date_format_mm_dd_yyyy'.tr();
      case 'dd/MM/yyyy':
        return 'date_format_dd_mm_yyyy'.tr();
      case 'dd.MM.yyyy':
        return 'date_format_dd_mm_yyyy_dots'.tr();
      default:
        // Return default format key if invalid
        return 'date_format_yyyy_mm_dd'.tr();
    }
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
            // Invalidate all settings providers to reload from cleared preferences
            ref.invalidate(themeModeNotifierProvider);
            ref.invalidate(themeColorNotifierProvider);
            ref.invalidate(timelineDaysNotifierProvider);
            ref.invalidate(modalTimelineDaysNotifierProvider);
            ref.invalidate(daySquareSizeNotifierProvider);
            ref.invalidate(dateFormatNotifierProvider);
            ref.invalidate(firstDayOfWeekNotifierProvider);
            ref.invalidate(notificationsEnabledNotifierProvider);
            ref.invalidate(habitCheckboxStyleNotifierProvider);
            ref.invalidate(habitSortOrderNotifierProvider);
            ref.invalidate(showStreakBordersNotifierProvider);
            ref.invalidate(timelineCompactModeNotifierProvider);
            ref.invalidate(showWeekMonthHighlightsNotifierProvider);
            ref.invalidate(timelineSpacingNotifierProvider);
            ref.invalidate(showStreakNumbersNotifierProvider);
            ref.invalidate(showDescriptionsNotifierProvider);
            ref.invalidate(compactCardsNotifierProvider);
            ref.invalidate(iconSizeNotifierProvider);
            ref.invalidate(progressIndicatorStyleNotifierProvider);
            ref.invalidate(calendarCompletionColorNotifierProvider);
            ref.invalidate(habitCardCompletionColorNotifierProvider);
            ref.invalidate(calendarTimelineCompletionColorNotifierProvider);
            ref.invalidate(mainTimelineCompletionColorNotifierProvider);
            ref.invalidate(calendarBadHabitCompletionColorNotifierProvider);
            ref.invalidate(habitCardBadHabitCompletionColorNotifierProvider);
            ref.invalidate(
              calendarTimelineBadHabitCompletionColorNotifierProvider,
            );
            ref.invalidate(mainTimelineBadHabitCompletionColorNotifierProvider);
            ref.invalidate(streakColorSchemeNotifierProvider);
            ref.invalidate(showPercentageNotifierProvider);
            ref.invalidate(fontSizeScaleNotifierProvider);
            ref.invalidate(cardSpacingNotifierProvider);
            ref.invalidate(showStatisticsCardNotifierProvider);
            ref.invalidate(defaultViewNotifierProvider);
            ref.invalidate(showStreakOnCardNotifierProvider);

            // Reload expansion states to defaults
            _loadExpansionStates();

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
                  ref.invalidate(themeModeProvider);
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
                  ref.invalidate(themeModeProvider);
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
                  ref.invalidate(themeModeProvider);
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
                  ref.invalidate(themeColorProvider);
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
                  ref.invalidate(daySquareSizeProvider);
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
                  ref.invalidate(daySquareSizeProvider);
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
                  ref.invalidate(daySquareSizeProvider);
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
    final exampleDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('date_format'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats.map((format) {
            final formattedExample = DateFormat(format).format(exampleDate);
            return _buildRadioListItem<String>(
              context: dialogContext,
              title: Text(_getDateFormatName(format)),
              subtitle: Text(formattedExample),
              value: format,
              groupValue: currentFormat,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setDateFormat(value);
                  ref.invalidate(dateFormatNotifierProvider);
                  ref.invalidate(dateFormatProvider);
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

  void _showHabitCardTimelineDaysDialog(BuildContext context, WidgetRef ref) {
    final currentDays = ref.watch(habitCardTimelineDaysProvider);
    final notifier = ref.read(habitCardTimelineDaysNotifierProvider);
    final navigator = Navigator.of(context);
    final controller = TextEditingController(text: currentDays.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('habit_card_timeline_days'.tr()),
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
                await notifier.setHabitCardTimelineDays(days);
                ref.invalidate(habitCardTimelineDaysNotifierProvider);
                ref.invalidate(habitCardTimelineDaysProvider);
                if (dialogContext.mounted) {
                  navigator.pop();
                }
              } else {
                // Show error for invalid input
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('please_enter_valid_number'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('save'.tr()),
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
                  ref.invalidate(firstDayOfWeekProvider);
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
                  ref.invalidate(firstDayOfWeekProvider);
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
                    ref.invalidate(habitCheckboxStyleProvider);
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
        // Return default if invalid value
        return 'square'.tr();
    }
  }

  Future<void> _revertDaySquareSize(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(daySquareSizeNotifierProvider);
    await notifier.setDaySquareSize(defaultDaySquareSize);
    ref.invalidate(daySquareSizeNotifierProvider);
    ref.invalidate(daySquareSizeProvider);
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
    ref.invalidate(modalTimelineDaysProvider);
  }

  Future<void> _revertHabitCardTimelineDays(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final notifier = ref.read(habitCardTimelineDaysNotifierProvider);
    await notifier.setHabitCardTimelineDays(defaultHabitCardTimelineDays);
    ref.invalidate(habitCardTimelineDaysNotifierProvider);
    ref.invalidate(habitCardTimelineDaysProvider);
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
                ref.invalidate(timelineDaysProvider);
                if (dialogContext.mounted) {
                  navigator.pop();
                }
              } else {
                // Show error for invalid input
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('please_enter_valid_number'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
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
                ref.invalidate(modalTimelineDaysProvider);
                if (dialogContext.mounted) {
                  navigator.pop();
                }
              } else {
                // Show error for invalid input
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('please_enter_valid_number'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
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
                    ref.invalidate(timelineSpacingProvider);
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
                  ref.invalidate(iconSizeProvider);
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
                  ref.invalidate(iconSizeProvider);
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
                  ref.invalidate(iconSizeProvider);
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
                  ref.invalidate(progressIndicatorStyleProvider);
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
                  ref.invalidate(progressIndicatorStyleProvider);
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

  void _showCompletionColorDialog(
    BuildContext context,
    WidgetRef ref,
    String titleKey,
    int currentColor,
    Future<void> Function(int) onColorSelected,
    Provider<dynamic> notifierProvider,
    Provider<dynamic>? valueProvider,
  ) {
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
        title: Text(titleKey.tr()),
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
                  await onColorSelected(colorValue);
                  ref.invalidate(notifierProvider);
                  if (valueProvider != null) {
                    ref.invalidate(valueProvider);
                  }
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
                  ref.invalidate(streakColorSchemeProvider);
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
                  ref.invalidate(streakColorSchemeProvider);
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
                  ref.invalidate(streakColorSchemeProvider);
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
                  ref.invalidate(streakColorSchemeProvider);
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
                  ref.invalidate(fontSizeScaleProvider);
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
                  ref.invalidate(fontSizeScaleProvider);
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
                  ref.invalidate(fontSizeScaleProvider);
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
                  ref.invalidate(fontSizeScaleProvider);
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
    final navigator = Navigator.of(context);
    final currentSpacing = ref.read(cardSpacingProvider);
    final notifier = ref.read(cardSpacingNotifierProvider);
    double spacing = currentSpacing;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
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
                  },
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
                  await notifier.setCardSpacing(spacing);
                  ref.invalidate(cardSpacingNotifierProvider);
                  ref.invalidate(cardSpacingProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                },
                child: Text('done'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCardBorderRadiusDialog(BuildContext context, WidgetRef ref) {
    final navigator = Navigator.of(context);
    final currentRadius = ref.read(cardBorderRadiusProvider);
    final notifier = ref.read(cardStyleNotifierProvider);
    double radius = currentRadius;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('border_radius'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${radius.toStringAsFixed(1)}px'),
                Slider(
                  value: radius,
                  min: 0.0,
                  max: 32.0,
                  divisions: 32,
                  onChanged: (value) {
                    setDialogState(() {
                      radius = value;
                    });
                  },
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
                  await notifier.setBorderRadius(radius);
                  ref.invalidate(cardStyleNotifierProvider);
                  ref.invalidate(cardBorderRadiusProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                },
                child: Text('done'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCardElevationDialog(BuildContext context, WidgetRef ref) {
    final navigator = Navigator.of(context);
    final currentElevation = ref.read(cardElevationProvider);
    final notifier = ref.read(cardStyleNotifierProvider);
    double elevation = currentElevation;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('elevation'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(elevation.toStringAsFixed(1)),
                Slider(
                  value: elevation,
                  min: 0.0,
                  max: 16.0,
                  divisions: 16,
                  onChanged: (value) {
                    setDialogState(() {
                      elevation = value;
                    });
                  },
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
                  await notifier.setElevation(elevation);
                  ref.invalidate(cardStyleNotifierProvider);
                  ref.invalidate(cardElevationProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                },
                child: Text('done'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBadHabitLogicModeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(badHabitLogicModeProvider);
    final notifier = ref.read(badHabitLogicModeNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('bad_habit_logic_mode'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'bad_habit_logic_mode_description'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('bad_habit_logic_mode_negative'.tr()),
              value: 'negative',
              groupValue: currentMode,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setBadHabitLogicMode(value);
                  ref.invalidate(badHabitLogicModeNotifierProvider);
                  ref.invalidate(badHabitLogicModeProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('bad_habit_logic_mode_positive'.tr()),
              value: 'positive',
              groupValue: currentMode,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setBadHabitLogicMode(value);
                  ref.invalidate(badHabitLogicModeNotifierProvider);
                  ref.invalidate(badHabitLogicModeProvider);
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
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
    final maxWidth = 600.0; // Maximum width for the centered content
    final hasSearch = _searchQuery.isNotEmpty;

    // Build children for each section so we can filter them.
    final generalTitle = 'general'.tr();
    final generalChildren = <Widget>[
      GeneralSectionContent(
        showLanguageDialog: _showLanguageDialog,
        showThemeDialog: _showThemeDialog,
        showThemeColorDialog: _showThemeColorDialog,
      ),
    ];
    final generalTags = <String>[
      _keyToSearchText('language'),
      _keyToSearchText('theme'),
      _keyToSearchText('select_theme_color'),
    ];
    final generalFiltered = _filterSectionChildren(
      generalTitle,
      generalChildren,
      tags: generalTags,
    );

    final appearanceTitle = 'appearance'.tr();
    final appearanceChildren = <Widget>[
      AppearanceSectionContent(
        showFontSizeScaleDialog: _showFontSizeScaleDialog,
        showIconSizeDialog: _showIconSizeDialog,
        showDaySquareSizeDialog: _showDaySquareSizeDialog,
        revertDaySquareSize: _revertDaySquareSize,
        showCardBorderRadiusDialog: _showCardBorderRadiusDialog,
        showCardElevationDialog: _showCardElevationDialog,
        showCardSpacingDialog: _showCardSpacingDialog,
        showCompletionColorDialog: _showCompletionColorDialog,
        showStreakColorSchemeDialog: _showStreakColorSchemeDialog,
      ),
    ];
    final appearanceTags = <String>[
      _keyToSearchText('day_square_size'),
      _keyToSearchText('icon_size'),
      _keyToSearchText('calendar_completion_color'),
      _keyToSearchText('habit_card_completion_color'),
      _keyToSearchText('calendar_timeline_completion_color'),
      _keyToSearchText('main_timeline_completion_color'),
      '', // Divider
      _keyToSearchText('calendar_bad_habit_completion_color'),
      _keyToSearchText('habit_card_bad_habit_completion_color'),
      _keyToSearchText('calendar_timeline_bad_habit_completion_color'),
      _keyToSearchText('main_timeline_bad_habit_completion_color'),
      _keyToSearchText('streak_color_scheme'),
      _keyToSearchText('card_spacing'),
      _keyToSearchText('use_streak_colors_for_squares'),
      _keyToSearchText('font_size_scale'),
    ];
    final appearanceFiltered = _filterSectionChildren(
      appearanceTitle,
      appearanceChildren,
      tags: appearanceTags,
    );

    // Date & Time section
    final dateTimeTitle = 'date_time'.tr();
    final dateTimeChildren = <Widget>[
      DateTimeSectionContent(
        showDateFormatDialog: _showDateFormatDialog,
        showFirstDayOfWeekDialog: _showFirstDayOfWeekDialog,
      ),
    ];
    final dateTimeTags = <String>[
      _keyToSearchText('date_format'),
      _keyToSearchText('first_day_of_week'),
    ];
    final dateTimeFiltered = _filterSectionChildren(
      dateTimeTitle,
      dateTimeChildren,
      tags: dateTimeTags,
    );

    // Display section (habits, habit cards, timelines, statistics)
    final displayTitle = 'display'.tr();
    final displayChildren = <Widget>[
      DisplaySectionContent(
        showTimelineDaysDialog: _showTimelineDaysDialog,
        showModalTimelineDaysDialog: _showModalTimelineDaysDialog,
        showHabitCardTimelineDaysDialog: _showHabitCardTimelineDaysDialog,
        showTimelineSpacingDialog: _showTimelineSpacingDialog,
        showHabitCheckboxStyleDialog: _showHabitCheckboxStyleDialog,
        showProgressIndicatorStyleDialog: _showProgressIndicatorStyleDialog,
        revertTimelineDays: _revertTimelineDays,
        revertModalTimelineDays: _revertModalTimelineDays,
        revertHabitCardTimelineDays: _revertHabitCardTimelineDays,
      ),
    ];
    final displayTags = <String>[
      _keyToSearchText('habits_layout_mode'),
      _keyToSearchText('grid_show_icon'),
      _keyToSearchText('grid_show_completion'),
      _keyToSearchText('grid_show_timeline'),
      '', // Divider
      _keyToSearchText('timeline_days'),
      _keyToSearchText('modal_timeline_days'),
      _keyToSearchText('habit_card_timeline_days'),
      _keyToSearchText('timeline_spacing'),
      _keyToSearchText('timeline_compact_mode'),
      _keyToSearchText('show_streak_borders'),
      _keyToSearchText('show_week_month_highlights'),
      _keyToSearchText('show_streak_numbers'),
      _keyToSearchText('show_descriptions'),
      _keyToSearchText('compact_cards'),
      _keyToSearchText('show_percentage'),
      _keyToSearchText('progress_indicator_style'),
      _keyToSearchText('show_statistics_card'),
      _keyToSearchText('show_main_timeline'),
      _keyToSearchText('main_timeline_fill_lines'),
      _keyToSearchText('main_timeline_lines'),
      _keyToSearchText('show_streak_on_card'),
      _keyToSearchText('habit_card_layout_mode'),
      _keyToSearchText('habit_card_timeline_fill_lines'),
      _keyToSearchText('habit_card_timeline_lines'),
    ];
    final displayFiltered = _filterSectionChildren(
      displayTitle,
      displayChildren,
      tags: displayTags,
    );

    // Notifications & behavior
    final notificationsTitle = 'notifications'.tr();
    final notificationsChildren = <Widget>[
      NotificationsSectionContent(
        showBadHabitLogicModeDialog: _showBadHabitLogicModeDialog,
      ),
    ];
    final notificationsTags = <String>[
      _keyToSearchText('enable_notifications'),
      _keyToSearchText('bad_habit_logic_mode'),
    ];
    final notificationsFiltered = _filterSectionChildren(
      notificationsTitle,
      notificationsChildren,
      tags: notificationsTags,
    );

    // Tags management
    final tagsTitle = 'tags'.tr();
    final tagsChildren = <Widget>[const TagsSectionContent()];
    final tagsTags = <String>[_keyToSearchText('tags')];
    final tagsFiltered = _filterSectionChildren(
      tagsTitle,
      tagsChildren,
      tags: tagsTags,
    );

    final dataTitle = 'data_management'.tr();
    final dataChildren = <Widget>[
      DataSectionContent(
        showExportDialog: _showExportDialog,
        showImportDialog: _showImportDialog,
        showDatabaseStatsDialog: _showDatabaseStatsDialog,
        optimizeDatabase: _optimizeDatabase,
      ),
    ];
    final dataTags = <String>[
      _keyToSearchText('export_data'),
      _keyToSearchText('import_data'),
      _keyToSearchText('database_statistics'),
      _keyToSearchText('optimize_database'),
    ];
    final dataFiltered = _filterSectionChildren(
      dataTitle,
      dataChildren,
      tags: dataTags,
    );

    final advancedTitle = 'advanced'.tr();
    final advancedChildren = <Widget>[
      AdvancedSectionContent(
        showResetHabitsDialog: _showResetHabitsDialog,
        showResetSettingsDialog: _showResetSettingsDialog,
        showClearAllDataDialog: _showClearAllDataDialog,
        showLogsDialog: _showLogsDialog,
        returnToOnboarding: _returnToOnboarding,
      ),
    ];
    final advancedTags = <String>[
      _keyToSearchText('reset_all_habits'),
      _keyToSearchText('reset_all_settings'),
      _keyToSearchText('clear_all_data'),
      _keyToSearchText('logs'),
      _keyToSearchText('return_to_onboarding'),
    ];
    final advancedFiltered = _filterSectionChildren(
      advancedTitle,
      advancedChildren,
      tags: advancedTags,
    );

    final aboutTitle = 'about'.tr();

    final settingsList = ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              hintText: 'search_settings'.tr(),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              isDense: true,
            ),
            textInputAction: TextInputAction.search,
          ),
        ),
        if (!hasSearch || generalFiltered.isNotEmpty)
          _buildCollapsibleSection(
            title: generalTitle,
            icon: Icons.settings,
            isExpanded: hasSearch ? true : _generalExpanded,
            onExpansionChanged: (expanded) {
              if (hasSearch) return;
              setState(() {
                _generalExpanded = expanded;
              });
              _saveExpansionState('general', expanded);
            },
            children: generalFiltered,
          ),
        if (!hasSearch || appearanceFiltered.isNotEmpty)
          _buildCollapsibleSection(
            title: appearanceTitle,
            icon: Icons.palette,
            isExpanded: hasSearch ? true : _appearanceExpanded,
            onExpansionChanged: (expanded) {
              if (hasSearch) return;
              setState(() {
                _appearanceExpanded = expanded;
              });
              _saveExpansionState('appearance', expanded);
            },
            children: appearanceFiltered,
          ),
        // Date & Time before Display
        if (!hasSearch || dateTimeFiltered.isNotEmpty)
          _buildCollapsibleSection(
            title: dateTimeTitle,
            icon: Icons.calendar_today,
            isExpanded: hasSearch ? true : _dateTimeExpanded,
            onExpansionChanged: (expanded) {
              if (hasSearch) return;
              setState(() {
                _dateTimeExpanded = expanded;
              });
              _saveExpansionState('dateTime', expanded);
            },
            children: dateTimeFiltered,
          ),
        if (!hasSearch || displayFiltered.isNotEmpty)
          _buildCollapsibleSection(
            title: displayTitle,
            icon: Icons.view_quilt,
            isExpanded: hasSearch ? true : _displayLayoutExpanded,
            onExpansionChanged: (expanded) {
              if (hasSearch) return;
              setState(() {
                _displayLayoutExpanded = expanded;
              });
              _saveExpansionState('displayLayout', expanded);
            },
            children: displayFiltered,
          ),
        if (!hasSearch || notificationsFiltered.isNotEmpty)
          _buildCollapsibleSection(
            title: notificationsTitle,
            icon: Icons.notifications,
            isExpanded: hasSearch ? true : _notificationsExpanded,
            onExpansionChanged: (expanded) {
              if (hasSearch) return;
              setState(() {
                _notificationsExpanded = expanded;
              });
              _saveExpansionState('notifications', expanded);
            },
            children: notificationsFiltered,
          ),
        if (!hasSearch || tagsFiltered.isNotEmpty)
          _buildCollapsibleSection(
            title: tagsTitle,
            icon: Icons.label,
            isExpanded: hasSearch ? true : _tagsExpanded,
            onExpansionChanged: (expanded) {
              if (hasSearch) return;
              setState(() {
                _tagsExpanded = expanded;
              });
              _saveExpansionState('tags', expanded);
            },
            children: tagsFiltered,
          ),
        if (!hasSearch || dataFiltered.isNotEmpty)
          _buildCollapsibleSection(
            title: dataTitle,
            icon: Icons.storage,
            isExpanded: hasSearch ? true : _dataExportExpanded,
            onExpansionChanged: (expanded) {
              if (hasSearch) return;
              setState(() {
                _dataExportExpanded = expanded;
              });
              _saveExpansionState('dataExport', expanded);
            },
            children: dataFiltered,
          ),
        if (!hasSearch || advancedFiltered.isNotEmpty)
          _buildCollapsibleSection(
            title: advancedTitle,
            icon: Icons.settings_applications,
            isExpanded: hasSearch ? true : _advancedExpanded,
            onExpansionChanged: (expanded) {
              if (hasSearch) return;
              setState(() {
                _advancedExpanded = expanded;
              });
              _saveExpansionState('advanced', expanded);
            },
            children: advancedFiltered,
          ),
        // About section remains unfiltered except by its title; we still
        // auto-expand it during search if it matches.
        if (!hasSearch ||
            _filterSectionChildren(aboutTitle, const [SizedBox()]).isNotEmpty)
          _buildCollapsibleSection(
            title: aboutTitle,
            icon: Icons.info,
            isExpanded: hasSearch ? true : _aboutExpanded,
            onExpansionChanged: (expanded) {
              if (hasSearch) return;
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

                  return Column(
                    children: [
                      AboutSectionContent(
                        showLibrariesDialog: _showLibrariesDialog,
                        showLicenseDialog: _showLicenseDialog,
                        showUsageRightsDialog: _showUsageRightsDialog,
                        showPrivacyPolicyDialog: _showPrivacyPolicyDialog,
                        launchUrl: (context, url) => _launchUrl(url),
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
