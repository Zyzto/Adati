import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animations/animations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
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
import '../widgets/responsive_dialog.dart';
import '../widgets/split_screen_settings_layout.dart';
import '../widgets/dialogs/about_dialogs.dart';
import '../widgets/settings_section.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Search state
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;
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

  // Split-screen detail pane state
  String? _selectedSectionId;
  Widget? _detailContent;
  String? _detailTitle;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _loadExpansionStates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    // If focus is lost and field is empty, collapse search
    if (!_searchFocusNode.hasFocus &&
        _searchController.text.trim().isEmpty &&
        _isSearchExpanded) {
      setState(() {
        _isSearchExpanded = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _searchQuery) return;
    setState(() {
      _searchQuery = query;
    });
  }

  void _expandSearch() {
    setState(() {
      _isSearchExpanded = true;
    });
    // Focus the search field after expansion animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _collapseSearch() {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _isSearchExpanded = false;
      });
      _searchFocusNode.unfocus();
    }
  }

  /// Clear search state completely
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearchExpanded = false;
      _searchQuery = '';
    });
  }

  /// Build expandable search button/widget
  Widget _buildExpandableSearch() {
    if (!_isSearchExpanded) {
      return IconButton(
        icon: const Icon(Icons.search),
        onPressed: _expandSearch,
        tooltip: 'search_settings'.tr(),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 300,
      child: FocusScope(
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
            hintText: 'search_settings'.tr(),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          textInputAction: TextInputAction.search,
          onTapOutside: (event) {
            // Only collapse if field is empty
            if (_searchController.text.trim().isEmpty) {
              _collapseSearch();
            } else {
              // Keep focus if field has content
              _searchFocusNode.requestFocus();
            }
          },
          onChanged: (value) {
            // Ensure focus is maintained while typing
            if (!_searchFocusNode.hasFocus) {
              _searchFocusNode.requestFocus();
            }
          },
        ),
      ),
    );
  }

  void _loadExpansionStates() {
    setState(() {
      _generalExpanded = PreferencesService.getSettingsGeneralExpanded();
      _appearanceExpanded = PreferencesService.getSettingsAppearanceExpanded();

      // Migrate from old display/displayPreferences keys to new displayLayout key
      final oldDisplayExpanded = PreferencesService.getSettingsDisplayExpanded();
      final oldDisplayPreferencesExpanded =
          PreferencesService.getSettingsDisplayPreferencesExpanded();

      if (oldDisplayExpanded || oldDisplayPreferencesExpanded) {
        _displayLayoutExpanded = true;
        PreferencesService.setSettingsDisplayLayoutExpanded(true);
      } else {
        _displayLayoutExpanded =
            PreferencesService.getSettingsDisplayLayoutExpanded();
      }

      _dateTimeExpanded = oldDisplayExpanded;
      _notificationsExpanded =
          PreferencesService.getSettingsNotificationsExpanded();
      _tagsExpanded = PreferencesService.getSettingsTagsExpanded();
      _dataExportExpanded = PreferencesService.getSettingsDataExportExpanded();
      _advancedExpanded = PreferencesService.getSettingsAdvancedExpanded();
      _aboutExpanded = PreferencesService.getSettingsAboutExpanded();
    });
  }

  /// Checks if a list of widgets contains any visible/searchable items.
  bool _hasVisibleItems(List<Widget> widgets) {
    if (widgets.isEmpty) return false;

    for (final widget in widgets) {
      if (widget is ListTile || widget is SwitchListTile) {
        return true;
      }
      if (widget is Column && _hasVisibleItems(widget.children)) {
        return true;
      }
      if (widget is SizedBox) {
        // Skip SizedBox.shrink()
        if (widget.width == 0 && widget.height == 0) continue;
        return true;
      }
      // Consumer widgets are built dynamically - assume they might have content
      if (widget is Consumer) return true;
    }
    return false;
  }

  /// Filters section children based on search query.
  /// Matches against displayed text from widgets (current UI language only).
  List<Widget> _filterSectionChildren(
    String sectionTitle,
    List<Widget> children,
  ) {
    if (_searchQuery.isEmpty) return children;

    final query = _searchQuery.toLowerCase();

    bool matchesText(String? text) {
      return text?.toLowerCase().contains(query) ?? false;
    }

    // If section title matches, keep all children
    if (matchesText(sectionTitle)) return children;

    String? extractTextFromWidget(Widget? widget) {
      return (widget is Text) ? widget.data : null;
    }

    bool widgetMatches(Widget child) {
      Widget? titleWidget;
      Widget? subtitleWidget;

      if (child is ListTile) {
        titleWidget = child.title;
        subtitleWidget = child.subtitle;
      } else if (child is SwitchListTile) {
        titleWidget = child.title;
        subtitleWidget = child.subtitle;
      } else {
        return false;
      }

      final titleText = extractTextFromWidget(titleWidget);
      final subtitleText = extractTextFromWidget(subtitleWidget);
      return matchesText(titleText) || matchesText(subtitleText);
    }

    /// Creates a Column with filtered children, preserving original properties.
    Widget createFilteredColumn(Column original, List<Widget> filteredChildren) {
      return Column(
        crossAxisAlignment: original.crossAxisAlignment,
        mainAxisAlignment: original.mainAxisAlignment,
        mainAxisSize: original.mainAxisSize,
        textBaseline: original.textBaseline,
        textDirection: original.textDirection,
        verticalDirection: original.verticalDirection,
        children: filteredChildren,
      );
    }

    /// Filters column children, hiding subsections with no matching items.
    List<Widget> filterColumnChildren(List<Widget> columnChildren) {
      final filteredColumnChildren = <Widget>[];
      List<Widget> pendingSubsectionWidgets = [];
      bool hasMatchingItemsInSubsection = false;

      for (final columnChild in columnChildren) {
        final isSubsectionHeader = columnChild is SettingsSubsectionHeader;
        final isDivider = columnChild is Divider;

        if (columnChild is ListTile || columnChild is SwitchListTile) {
          if (widgetMatches(columnChild)) {
            filteredColumnChildren.addAll(pendingSubsectionWidgets);
            pendingSubsectionWidgets.clear();
            hasMatchingItemsInSubsection = true;
            filteredColumnChildren.add(columnChild);
          }
        } else if (isSubsectionHeader || isDivider) {
          pendingSubsectionWidgets.clear();
          pendingSubsectionWidgets.add(columnChild);
          hasMatchingItemsInSubsection = false;
        } else if (hasMatchingItemsInSubsection || pendingSubsectionWidgets.isEmpty) {
          filteredColumnChildren.add(columnChild);
        }
      }

      pendingSubsectionWidgets.clear();
      return filteredColumnChildren;
    }

    final result = <Widget>[];
    for (final child in children) {
      // Handle Column widgets (section content widgets like GeneralSectionContent return Column)
      // For ConsumerWidget, we need to use Consumer to build and filter
      if (child is ConsumerWidget) {
        // Wrap in Consumer to build the widget and access the Column
        result.add(
          Consumer(
            builder: (context, ref, _) {
              // Build the ConsumerWidget to get the Column
              final builtWidget = child.build(context, ref);

              if (builtWidget is Column) {
                final filteredColumnChildren = filterColumnChildren(builtWidget.children);
                return filteredColumnChildren.isNotEmpty
                    ? createFilteredColumn(builtWidget, filteredColumnChildren)
                    : const SizedBox.shrink();
              }

              // If not a Column, return as-is (shouldn't happen for section content widgets)
              return builtWidget;
            },
          ),
        );
      } else if (child is Column) {
        final filteredColumnChildren = filterColumnChildren(child.children);
        if (filteredColumnChildren.isNotEmpty) {
          result.add(createFilteredColumn(child, filteredColumnChildren));
        }
      } else if (widgetMatches(child)) {
        result.add(child);
      }
    }
    return result;
  }

  /// Show a loading dialog (non-dismissible)
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  /// Close loading dialog if context is mounted
  void _closeLoadingDialog(BuildContext context) {
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  /// Show section content in split-screen detail pane (landscape mode)
  void _showSectionInDetailPane({
    required String sectionId,
    required Widget content,
    required String title,
  }) {
    if (ResponsiveDialog.shouldUseSplitScreen(context)) {
      setState(() {
        _selectedSectionId = sectionId;
        _detailContent = content;
        _detailTitle = title;
      });
    }
  }

  /// Clear the detail pane
  void _clearDetailPane() {
    setState(() {
      _selectedSectionId = null;
      _detailContent = null;
      _detailTitle = null;
    });
  }

  /// Creates an expansion change handler for a section.
  void Function(bool) _createExpansionHandler({
    required String sectionId,
    required bool hasSearch,
    required void Function(bool) updateState,
  }) {
    return (expanded) {
      if (hasSearch) return;
      setState(() => updateState(expanded));
      _saveExpansionState(sectionId, expanded);
    };
  }

  /// Creates the page transition builder.
  Widget Function(Widget, Animation<double>, Animation<double>) _createTransitionBuilder() {
    return (child, primaryAnimation, secondaryAnimation) {
      return SharedAxisTransition(
        animation: primaryAnimation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.horizontal,
        fillColor: Colors.transparent,
        child: child,
      );
    };
  }

  Future<void> _saveExpansionState(String section, bool expanded) async {
    final saveFunctions = <String, Future<void> Function(bool)>{
      'general': PreferencesService.setSettingsGeneralExpanded,
      'appearance': PreferencesService.setSettingsAppearanceExpanded,
      'dateTime': PreferencesService.setSettingsDisplayExpanded,
      'displayLayout': PreferencesService.setSettingsDisplayLayoutExpanded,
      'notifications': PreferencesService.setSettingsNotificationsExpanded,
      'tags': PreferencesService.setSettingsTagsExpanded,
      'dataExport': PreferencesService.setSettingsDataExportExpanded,
      'advanced': PreferencesService.setSettingsAdvancedExpanded,
      'about': PreferencesService.setSettingsAboutExpanded,
    };
    await saveFunctions[section]?.call(expanded);
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
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('packages_used'.tr()),
        scrollable: true,
        content: ListView.builder(
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
              onTap: () => AboutDialogs.launchUrlWithFallback(
                context,
                'https://pub.dev/packages/${package['name']}',
              ),
              trailing: const Icon(Icons.open_in_new, size: 16),
            );
          },
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
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('license'.tr()),
        scrollable: true,
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
                onPressed: () => AboutDialogs.launchUrlWithFallback(
                  context,
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
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('usage_rights'.tr()),
        scrollable: true,
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
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('privacy_policy'.tr()),
        scrollable: true,
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
          _showErrorSnackBar(context, '${'export_error'.tr()}: $e');
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
          _showErrorSnackBar(context, '${'export_error'.tr()}: $e');
        }
      }
      return;
    }

    // Handle all data export (with format selection)
    if (exportType == 'all') {
      final repository = ref.read(habitRepositoryProvider);

      // Show loading
      _showLoadingDialog(context);

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
          _closeLoadingDialog(context);

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
          _closeLoadingDialog(context);
          _showErrorSnackBar(context, '${'export_error'.tr()}: $e');
        }
      }
    }
  }

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
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
                result.success ? 'import_success'.tr() : 'import_failed'.tr(),
              ),
            ),
          ],
        ),
        scrollable: true,
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
        _closeLoadingDialog(context);

        showDialog(
          context: context,
          builder: (context) => ResponsiveDialog.responsiveAlertDialog(
            context: context,
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
        _closeLoadingDialog(context);
        _showErrorSnackBar(context, '${'error'.tr()}: $e');
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
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
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

      _showLoadingDialog(context);

      try {
        await repository.deleteAllHabits();

        if (context.mounted) {
          _closeLoadingDialog(context);
          _showSuccessSnackBar(context, 'habits_reset_success'.tr());
        }
      } catch (e) {
        if (context.mounted) {
          _closeLoadingDialog(context);
          _showErrorSnackBar(context, '${'error'.tr()}: $e');
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
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
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
      _showLoadingDialog(context);

      try {
        final success = await PreferencesService.resetAllSettings();

        if (context.mounted) {
          _closeLoadingDialog(context);

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

            _showSuccessSnackBar(context, 'settings_reset_success'.tr());
          } else {
            _showErrorSnackBar(context, 'settings_reset_failed'.tr());
          }
        }
      } catch (e) {
        if (context.mounted) {
          _closeLoadingDialog(context);
          _showErrorSnackBar(context, '${'error'.tr()}: $e');
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
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
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

      _showLoadingDialog(context);

      try {
        await repository.deleteAllData();
        await PreferencesService.resetAllSettings();

        if (context.mounted) {
          _closeLoadingDialog(context);
          _showSuccessSnackBar(context, 'all_data_cleared_success'.tr());
        }
      } catch (e) {
        if (context.mounted) {
          _closeLoadingDialog(context);
          _showErrorSnackBar(context, '${'error'.tr()}: $e');
        }
      }
    }
  }

  Future<void> _returnToOnboarding(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
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
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
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

      _showLoadingDialog(context);

      try {
        await repository.vacuumDatabase();

        if (context.mounted) {
          _closeLoadingDialog(context);
          _showSuccessSnackBar(context, 'database_optimized_success'.tr());
        }
      } catch (e) {
        if (context.mounted) {
          _closeLoadingDialog(context);
          _showErrorSnackBar(context, '${'error'.tr()}: $e');
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
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('logs'.tr()),
        scrollable: true,
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
                    await _viewLogs(context);
                  },
                  icon: const Icon(Icons.visibility),
                  label: Text('view_logs'.tr()),
                ),
              ),
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
                    await _rotateAndCleanupLogs(context);
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text('rotate_and_cleanup_logs'.tr()),
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

  Future<void> _viewLogs(BuildContext context) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    String logContent = 'no_logs_available'.tr();

    try {
      // Add timeout to prevent hanging
      logContent = await LoggingService.getLogContent().timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            'Error: Timeout reading logs. The log file may be too large.',
      );
    } catch (e) {
      logContent = 'Error reading logs: $e';
    } finally {
      // Always close loading dialog
      if (context.mounted) {
        _closeLoadingDialog(context);
      }
    }

    // Show logs dialog
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => ResponsiveDialog.responsiveDialog(
          context: context,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'logs'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      logContent.isEmpty
                          ? 'no_logs_available'.tr()
                          : logContent,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[900],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: logContent));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('logs_copied_to_clipboard'.tr()),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: Text('copy'.tr()),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('close'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
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
        _closeLoadingDialog(context);

        if (filePath != null) {
          _showSuccessSnackBar(context, 'logs_downloaded_successfully'.tr());
        } else {
          _showErrorSnackBar(
            context,
            '${'error'.tr()}: ${'failed_to_export_logs'.tr()}',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _closeLoadingDialog(context);
        _showErrorSnackBar(context, '${'error'.tr()}: $e');
      }
    }
  }

  Future<void> _rotateAndCleanupLogs(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await LoggingService.rotateAndCleanupLogs();

      if (context.mounted) {
        _closeLoadingDialog(context);

        if (success) {
          _showSuccessSnackBar(
            context,
            'logs_rotated_and_cleaned_successfully'.tr(),
          );
        } else {
          _showErrorSnackBar(
            context,
            '${'error'.tr()}: ${'failed_to_rotate_logs'.tr()}',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _closeLoadingDialog(context);
        _showErrorSnackBar(context, '${'error'.tr()}: $e');
      }
    }
  }

  Future<void> _clearLogs(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
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
      _showLoadingDialog(context);

      try {
        final success = await LoggingService.clearLogs();

        if (context.mounted) {
          _closeLoadingDialog(context);

          if (success) {
            _showSuccessSnackBar(context, 'logs_cleared_successfully'.tr());
          } else {
            _showErrorSnackBar(
              context,
              '${'error'.tr()}: ${'failed_to_clear_logs'.tr()}',
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          _closeLoadingDialog(context);
          _showErrorSnackBar(context, '${'error'.tr()}: $e');
        }
      }
    }
  }

  Future<void> _sendLogsToGitHub(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('send_logs_to_github'.tr()),
        scrollable: true,
        content: Column(
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

      _showLoadingDialog(context);

      try {
        final success = await LoggingService.sendLogsToGitHub(
          titleController.text.trim(),
          descriptionController.text.trim(),
        );

        if (context.mounted) {
          _closeLoadingDialog(context);

          if (success) {
            _showSuccessSnackBar(context, 'logs_sent_successfully'.tr());
          } else {
            _showErrorSnackBar(
              context,
              '${'error'.tr()}: ${'failed_to_send_logs'.tr()}',
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          _closeLoadingDialog(context);
          _showErrorSnackBar(context, '${'error'.tr()}: $e');
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
    required String sectionId,
  }) {
    final theme = Theme.of(context);
    final isLandscape = ResponsiveDialog.shouldUseSplitScreen(context);
    final isSelected = _selectedSectionId == sectionId && isLandscape;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.dividerColor.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (isLandscape) {
                // In landscape: show section content in detail pane
                _showSectionInDetailPane(
                  sectionId: sectionId,
                  content: ListView(
                    padding: const EdgeInsets.all(16),
                    children: children,
                  ),
                  title: title,
                );
                // Don't expand in left pane when in landscape
              } else {
                // In portrait: toggle expansion as normal
                onExpansionChanged(!isExpanded);
              }
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ),
                  if (!isLandscape)
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (isLandscape && isSelected)
                    Icon(Icons.chevron_right, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
          // Only show expanded content in portrait mode
          if (!isLandscape)
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
      builder: (dialogContext) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
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
      builder: (dialogContext) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
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
      builder: (dialogContext) {
        final crossAxisCount = ResponsiveDialog.getGridCrossAxisCount(
          context,
          itemCount: colors.length,
        );
        return ResponsiveDialog.responsiveAlertDialog(
          context: context,
          title: Text('select_theme_color'.tr()),
          content: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
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
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text('cancel'.tr()),
            ),
          ],
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
      builder: (dialogContext) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
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
      builder: (dialogContext) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
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
                  _showErrorSnackBar(
                    dialogContext,
                    'please_enter_valid_number'.tr(),
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
      builder: (dialogContext) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
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

    final styles = HabitCheckboxStyle.values;

    showDialog(
      context: context,
      builder: (dialogContext) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
        title: Text('habit_checkbox_style'.tr()),
        scrollable: styles.length > 5,
        content: Column(
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
                  _showErrorSnackBar(
                    dialogContext,
                    'please_enter_valid_number'.tr(),
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
                  _showErrorSnackBar(
                    dialogContext,
                    'please_enter_valid_number'.tr(),
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
      builder: (dialogContext) {
        final crossAxisCount = ResponsiveDialog.getGridCrossAxisCount(
          context,
          itemCount: colors.length,
        );
        return ResponsiveDialog.responsiveAlertDialog(
          context: context,
          title: Text(titleKey.tr()),
          content: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
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
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text('cancel'.tr()),
            ),
          ],
        );
      },
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
      builder: (dialogContext) => ResponsiveDialog.responsiveAlertDialog(
        context: context,
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
    final generalFiltered = _filterSectionChildren(
      generalTitle,
      generalChildren,
    );

    final appearanceTitle = 'appearance'.tr();
    final appearanceChildren = <Widget>[
      AppearanceSectionContent(
        showFontSizeScaleDialog: _showFontSizeScaleDialog,
        showIconSizeDialog: _showIconSizeDialog,
        showCardBorderRadiusDialog: _showCardBorderRadiusDialog,
        showCardElevationDialog: _showCardElevationDialog,
        showCardSpacingDialog: _showCardSpacingDialog,
        showHabitCheckboxStyleDialog: _showHabitCheckboxStyleDialog,
        showProgressIndicatorStyleDialog: _showProgressIndicatorStyleDialog,
        showCompletionColorDialog: _showCompletionColorDialog,
        showStreakColorSchemeDialog: _showStreakColorSchemeDialog,
      ),
    ];
    final appearanceFiltered = _filterSectionChildren(
      appearanceTitle,
      appearanceChildren,
    );

    // Date & Time section
    final dateTimeTitle = 'date_time'.tr();
    final dateTimeChildren = <Widget>[
      DateTimeSectionContent(
        showDateFormatDialog: _showDateFormatDialog,
        showFirstDayOfWeekDialog: _showFirstDayOfWeekDialog,
      ),
    ];
    final dateTimeFiltered = _filterSectionChildren(
      dateTimeTitle,
      dateTimeChildren,
    );

    // Display section (habits, habit cards, timelines, statistics)
    final displayTitle = 'display'.tr();
    final displayChildren = <Widget>[
      DisplaySectionContent(
        showTimelineDaysDialog: _showTimelineDaysDialog,
        showModalTimelineDaysDialog: _showModalTimelineDaysDialog,
        showHabitCardTimelineDaysDialog: _showHabitCardTimelineDaysDialog,
        showTimelineSpacingDialog: _showTimelineSpacingDialog,
        showDaySquareSizeDialog: _showDaySquareSizeDialog,
        revertTimelineDays: _revertTimelineDays,
        revertModalTimelineDays: _revertModalTimelineDays,
        revertHabitCardTimelineDays: _revertHabitCardTimelineDays,
        revertDaySquareSize: _revertDaySquareSize,
      ),
    ];
    final displayFiltered = _filterSectionChildren(
      displayTitle,
      displayChildren,
    );

    // Notifications & behavior
    final notificationsTitle = 'notifications'.tr();
    final notificationsChildren = <Widget>[
      NotificationsSectionContent(
        showBadHabitLogicModeDialog: _showBadHabitLogicModeDialog,
      ),
    ];
    final notificationsFiltered = _filterSectionChildren(
      notificationsTitle,
      notificationsChildren,
    );

    // Tags management - excluded from search
    final tagsTitle = 'tags'.tr();
    final tagsChildren = <Widget>[const TagsSectionContent()];
    // Tags section is never filtered - it doesn't match search queries
    final tagsFiltered = tagsChildren;

    final dataTitle = 'data_management'.tr();
    final dataChildren = <Widget>[
      DataSectionContent(
        showExportDialog: _showExportDialog,
        showImportDialog: _showImportDialog,
        showDatabaseStatsDialog: _showDatabaseStatsDialog,
        optimizeDatabase: _optimizeDatabase,
      ),
    ];
    final dataFiltered = _filterSectionChildren(dataTitle, dataChildren);

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
    final advancedFiltered = _filterSectionChildren(
      advancedTitle,
      advancedChildren,
    );

    final aboutTitle = 'about'.tr();
    final aboutChildren = <Widget>[
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
                launchUrl: (context, url) =>
                    AboutDialogs.launchUrlWithFallback(context, url),
              ),
            ],
          );
        },
      ),
    ];
    final aboutFiltered = _filterSectionChildren(aboutTitle, aboutChildren);

    // Build settings list - filter sections based on search
    final settingsList = ListView(
      children: [
        if (!hasSearch || _hasVisibleItems(generalFiltered))
          _buildCollapsibleSection(
            title: generalTitle,
            icon: Icons.settings,
            isExpanded: hasSearch ? true : _generalExpanded,
            onExpansionChanged: _createExpansionHandler(
              sectionId: 'general',
              hasSearch: hasSearch,
              updateState: (expanded) => _generalExpanded = expanded,
            ),
            children: generalFiltered,
            sectionId: 'general',
          ),
        if (!hasSearch || _hasVisibleItems(appearanceFiltered))
          _buildCollapsibleSection(
            title: appearanceTitle,
            icon: Icons.palette,
            isExpanded: hasSearch ? true : _appearanceExpanded,
            onExpansionChanged: _createExpansionHandler(
              sectionId: 'appearance',
              hasSearch: hasSearch,
              updateState: (expanded) => _appearanceExpanded = expanded,
            ),
            children: appearanceFiltered,
            sectionId: 'appearance',
          ),
        // Date & Time before Display
        if (!hasSearch || _hasVisibleItems(dateTimeFiltered))
          _buildCollapsibleSection(
            title: dateTimeTitle,
            icon: Icons.calendar_today,
            isExpanded: hasSearch ? true : _dateTimeExpanded,
            onExpansionChanged: _createExpansionHandler(
              sectionId: 'dateTime',
              hasSearch: hasSearch,
              updateState: (expanded) => _dateTimeExpanded = expanded,
            ),
            children: dateTimeFiltered,
            sectionId: 'dateTime',
          ),
        if (!hasSearch || _hasVisibleItems(displayFiltered))
          _buildCollapsibleSection(
            title: displayTitle,
            icon: Icons.view_quilt,
            isExpanded: hasSearch ? true : _displayLayoutExpanded,
            onExpansionChanged: _createExpansionHandler(
              sectionId: 'displayLayout',
              hasSearch: hasSearch,
              updateState: (expanded) => _displayLayoutExpanded = expanded,
            ),
            children: displayFiltered,
            sectionId: 'display',
          ),
        if (!hasSearch || _hasVisibleItems(notificationsFiltered))
          _buildCollapsibleSection(
            title: notificationsTitle,
            icon: Icons.notifications,
            isExpanded: hasSearch ? true : _notificationsExpanded,
            onExpansionChanged: _createExpansionHandler(
              sectionId: 'notifications',
              hasSearch: hasSearch,
              updateState: (expanded) => _notificationsExpanded = expanded,
            ),
            children: notificationsFiltered,
            sectionId: 'notifications',
          ),
        // Tags section is only shown when there's no search (excluded from search)
        if (!hasSearch)
          _buildCollapsibleSection(
            title: tagsTitle,
            icon: Icons.label,
            isExpanded: _tagsExpanded,
            onExpansionChanged: _createExpansionHandler(
              sectionId: 'tags',
              hasSearch: false,
              updateState: (expanded) => _tagsExpanded = expanded,
            ),
            children: tagsFiltered,
            sectionId: 'tags',
          ),
        if (!hasSearch || _hasVisibleItems(dataFiltered))
          _buildCollapsibleSection(
            title: dataTitle,
            icon: Icons.storage,
            isExpanded: hasSearch ? true : _dataExportExpanded,
            onExpansionChanged: _createExpansionHandler(
              sectionId: 'dataExport',
              hasSearch: hasSearch,
              updateState: (expanded) => _dataExportExpanded = expanded,
            ),
            children: dataFiltered,
            sectionId: 'data',
          ),
        if (!hasSearch || _hasVisibleItems(advancedFiltered))
          _buildCollapsibleSection(
            title: advancedTitle,
            icon: Icons.settings_applications,
            isExpanded: hasSearch ? true : _advancedExpanded,
            onExpansionChanged: _createExpansionHandler(
              sectionId: 'advanced',
              hasSearch: hasSearch,
              updateState: (expanded) => _advancedExpanded = expanded,
            ),
            children: advancedFiltered,
            sectionId: 'advanced',
          ),
        // About section
        if (!hasSearch || _hasVisibleItems(aboutFiltered))
          _buildCollapsibleSection(
            title: aboutTitle,
            icon: Icons.info,
            isExpanded: hasSearch ? true : _aboutExpanded,
            onExpansionChanged: _createExpansionHandler(
              sectionId: 'about',
              hasSearch: hasSearch,
              updateState: (expanded) => _aboutExpanded = expanded,
            ),
            children: aboutFiltered,
            sectionId: 'about',
          ),
      ],
    );

    // Clear detail pane when switching to portrait
    if (!isLandscape && _selectedSectionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _clearDetailPane();
      });
    }

    final bodyContent = isLandscape
        ? SplitScreenSettingsLayout(
            key: const ValueKey('landscape'),
            settingsList: settingsList,
            detailContent: _detailContent,
            detailTitle: _detailTitle,
            onCloseDetail: _clearDetailPane,
          )
        : SizedBox(
            key: const ValueKey('portrait'),
            width: double.infinity,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: settingsList,
              ),
            ),
          );

    if (isLandscape) {
      return Scaffold(
        appBar: AppBar(
          title: Text('settings'.tr()),
          automaticallyImplyLeading: true,
          actions: [_buildExpandableSearch()],
        ),
        body: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: _createTransitionBuilder(),
          child: bodyContent,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
        actions: [_buildExpandableSearch()],
      ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: _createTransitionBuilder(),
        child: bodyContent,
      ),
    );
  }
}

