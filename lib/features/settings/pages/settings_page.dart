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

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

/// Represents a search result item
class SearchResult {
  final String sectionId;
  final String sectionTitle;
  final IconData sectionIcon;
  final Widget item;
  final String? itemTitle;
  final String? itemSubtitle;
  final int itemIndex; // Index within the section
  final String? searchMatchText; // The text that matched

  const SearchResult({
    required this.sectionId,
    required this.sectionTitle,
    required this.sectionIcon,
    required this.item,
    this.itemTitle,
    this.itemSubtitle,
    required this.itemIndex,
    this.searchMatchText,
  });
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Search state
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;

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

  // Search results (memoized)
  List<SearchResult>? _cachedSearchResults;
  String? _cachedSearchQuery;
  String? _highlightedItemId; // For highlighting specific items

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
    final query = _searchController.text;
    final trimmedQuery = query.trim();

    // Invalidate cache if query changed
    if (trimmedQuery != _cachedSearchQuery) {
      setState(() {
        _cachedSearchResults = null;
        _cachedSearchQuery = null;
        _highlightedItemId = null;
        // Clear detail pane when search is cleared in landscape mode
        if (trimmedQuery.isEmpty &&
            ResponsiveDialog.shouldUseSplitScreen(context)) {
          _selectedSectionId = null;
          _detailContent = null;
          _detailTitle = null;
        }
      });
    }
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
      _cachedSearchResults = null;
      _cachedSearchQuery = null;
      _highlightedItemId = null;
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

  /// Extract individual items from a Column widget (for search)
  List<Widget> _extractItemsFromColumn(Column column) {
    final items = <Widget>[];
    for (final child in column.children) {
      if (child is ListTile || child is SwitchListTile) {
        items.add(child);
      } else if (child is Column) {
        items.addAll(_extractItemsFromColumn(child));
      }
    }
    return items;
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

  /// Get title text from a widget (supports ListTile and SwitchListTile)
  String? _getTitleFromWidget(Widget widget) {
    if (widget is ListTile || widget is SwitchListTile) {
      final title = widget is ListTile
          ? widget.title
          : (widget as SwitchListTile).title;
      return title is Text ? title.data : null;
    }
    return null;
  }

  /// Get subtitle text from a widget (supports ListTile and SwitchListTile)
  String? _getSubtitleFromWidget(Widget widget) {
    if (widget is ListTile || widget is SwitchListTile) {
      final subtitle = widget is ListTile
          ? widget.subtitle
          : (widget as SwitchListTile).subtitle;
      return subtitle is Text ? subtitle.data : null;
    }
    return null;
  }

  /// Build highlighted text widget with matching portions highlighted
  /// Build grouped search results view (for right pane in landscape)
  Widget _buildGroupedSearchResults(List<SearchResult> results, String query) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'no_results_found'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group results by section
    final grouped = <String, List<SearchResult>>{};
    for (final result in results) {
      if (!grouped.containsKey(result.sectionId)) {
        grouped[result.sectionId] = [];
      }
      grouped[result.sectionId]!.add(result);
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: grouped.entries.map((entry) {
        final sectionResults = entry.value;
        final firstResult = sectionResults.first;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header (clickable)
              InkWell(
                onTap: () =>
                    _navigateToSectionFromSearch(firstResult.sectionId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        firstResult.sectionIcon,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          firstResult.sectionTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                        ),
                      ),
                      Chip(
                        label: Text('${sectionResults.length}'),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: const TextStyle(fontSize: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              // Section items (smaller size) - preserve original functionality
              ...sectionResults.map((result) {
                final resultItemId = '${result.sectionId}_${result.itemIndex}';
                final resultIsHighlighted = _highlightedItemId == resultItemId;

                // Wrap the original item to make it smaller while preserving functionality
                Widget itemWidget = result.item;

                // If it's a ListTile, wrap onTap to clear search after action
                if (itemWidget is ListTile && itemWidget.onTap != null) {
                  final originalOnTap = itemWidget.onTap!;
                  itemWidget = ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: itemWidget.leading,
                    title: itemWidget.title != null
                        ? DefaultTextStyle(
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium!.copyWith(fontSize: 14),
                            child: itemWidget.title!,
                          )
                        : null,
                    subtitle: itemWidget.subtitle != null
                        ? DefaultTextStyle(
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall!.copyWith(fontSize: 12),
                            child: itemWidget.subtitle!,
                          )
                        : null,
                    trailing: itemWidget.trailing,
                    onTap: () {
                      originalOnTap();
                      // Clear search after action
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _clearSearch();
                        }
                      });
                    },
                  );
                } else if (itemWidget is SwitchListTile) {
                  // SwitchListTile - preserve original functionality, just make smaller
                  itemWidget = SwitchListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    secondary: itemWidget.secondary,
                    title: itemWidget.title != null
                        ? DefaultTextStyle(
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium!.copyWith(fontSize: 14),
                            child: itemWidget.title!,
                          )
                        : null,
                    subtitle: itemWidget.subtitle != null
                        ? DefaultTextStyle(
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall!.copyWith(fontSize: 12),
                            child: itemWidget.subtitle!,
                          )
                        : null,
                    value: itemWidget.value,
                    onChanged: itemWidget.onChanged,
                  );
                } else {
                  // Other widgets - just make smaller
                  itemWidget = Transform.scale(scale: 0.9, child: itemWidget);
                }

                return Container(
                  decoration: BoxDecoration(
                    color: resultIsHighlighted
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.2)
                        : null,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: itemWidget,
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Navigate to section from search results
  void _navigateToSectionFromSearch(String sectionId) {
    // Clear search
    _clearSearch();
    setState(() {
      _highlightedItemId = null;
    });

    // Navigate to section (same as clicking section in left pane)
    final isLandscape = ResponsiveDialog.shouldUseSplitScreen(context);

    // Get section data from the sections map (will be available in build context)
    // For now, use a helper method that will be called from build
    _navigateToSection(sectionId, isLandscape);
  }

  /// Helper to navigate to a section
  void _navigateToSection(String sectionId, bool isLandscape) {
    if (isLandscape) {
      // Show section in detail pane
      // We'll need to get the children from the build method
      // For now, trigger section click behavior
      switch (sectionId) {
        case 'general':
          _showSectionInDetailPane(
            sectionId: sectionId,
            content: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GeneralSectionContent(
                  showLanguageDialog: _showLanguageDialog,
                  showThemeDialog: _showThemeDialog,
                  showThemeColorDialog: _showThemeColorDialog,
                ),
              ],
            ),
            title: 'general'.tr(),
          );
          break;
        case 'appearance':
          _showSectionInDetailPane(
            sectionId: sectionId,
            content: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppearanceSectionContent(
                  showFontSizeScaleDialog: _showFontSizeScaleDialog,
                  showIconSizeDialog: _showIconSizeDialog,
                  showCardBorderRadiusDialog: _showCardBorderRadiusDialog,
                  showCardElevationDialog: _showCardElevationDialog,
                  showCardSpacingDialog: _showCardSpacingDialog,
                  showHabitCheckboxStyleDialog: _showHabitCheckboxStyleDialog,
                  showProgressIndicatorStyleDialog:
                      _showProgressIndicatorStyleDialog,
                  showCompletionColorDialog: _showCompletionColorDialog,
                  showStreakColorSchemeDialog: _showStreakColorSchemeDialog,
                ),
              ],
            ),
            title: 'appearance'.tr(),
          );
          break;
        case 'dateTime':
          _showSectionInDetailPane(
            sectionId: sectionId,
            content: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DateTimeSectionContent(
                  showDateFormatDialog: _showDateFormatDialog,
                  showFirstDayOfWeekDialog: _showFirstDayOfWeekDialog,
                ),
              ],
            ),
            title: 'date_time'.tr(),
          );
          break;
        case 'display':
          _showSectionInDetailPane(
            sectionId: sectionId,
            content: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DisplaySectionContent(
                  showTimelineDaysDialog: _showTimelineDaysDialog,
                  showModalTimelineDaysDialog: _showModalTimelineDaysDialog,
                  showHabitCardTimelineDaysDialog:
                      _showHabitCardTimelineDaysDialog,
                  showTimelineSpacingDialog: _showTimelineSpacingDialog,
                  showDaySquareSizeDialog: _showDaySquareSizeDialog,
                  revertTimelineDays: _revertTimelineDays,
                  revertModalTimelineDays: _revertModalTimelineDays,
                  revertHabitCardTimelineDays: _revertHabitCardTimelineDays,
                  revertDaySquareSize: _revertDaySquareSize,
                ),
              ],
            ),
            title: 'display'.tr(),
          );
          break;
        case 'notifications':
          _showSectionInDetailPane(
            sectionId: sectionId,
            content: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                NotificationsSectionContent(
                  showBadHabitLogicModeDialog: _showBadHabitLogicModeDialog,
                ),
              ],
            ),
            title: 'notifications'.tr(),
          );
          break;
        case 'tags':
          _showSectionInDetailPane(
            sectionId: sectionId,
            content: ListView(
              padding: const EdgeInsets.all(16),
              children: const [TagsSectionContent()],
            ),
            title: 'tags'.tr(),
          );
          break;
        case 'data':
          _showSectionInDetailPane(
            sectionId: sectionId,
            content: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DataSectionContent(
                  showExportDialog: _showExportDialog,
                  showImportDialog: _showImportDialog,
                  showDatabaseStatsDialog: _showDatabaseStatsDialog,
                  optimizeDatabase: _optimizeDatabase,
                ),
              ],
            ),
            title: 'data_management'.tr(),
          );
          break;
        case 'advanced':
          _showSectionInDetailPane(
            sectionId: sectionId,
            content: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AdvancedSectionContent(
                  showResetHabitsDialog: _showResetHabitsDialog,
                  showResetSettingsDialog: _showResetSettingsDialog,
                  showClearAllDataDialog: _showClearAllDataDialog,
                  showLogsDialog: _showLogsDialog,
                  returnToOnboarding: _returnToOnboarding,
                ),
              ],
            ),
            title: 'advanced'.tr(),
          );
          break;
        case 'about':
          _showSectionInDetailPane(
            sectionId: sectionId,
            content: FutureBuilder<PackageInfo?>(
              future: _getPackageInfo(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
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
            title: 'about'.tr(),
          );
          break;
      }
    } else {
      // Expand section in portrait
      switch (sectionId) {
        case 'general':
          setState(() => _generalExpanded = true);
          _saveExpansionState('general', true);
          break;
        case 'appearance':
          setState(() => _appearanceExpanded = true);
          _saveExpansionState('appearance', true);
          break;
        case 'dateTime':
          setState(() => _dateTimeExpanded = true);
          _saveExpansionState('dateTime', true);
          break;
        case 'display':
          setState(() => _displayLayoutExpanded = true);
          _saveExpansionState('displayLayout', true);
          break;
        case 'notifications':
          setState(() => _notificationsExpanded = true);
          _saveExpansionState('notifications', true);
          break;
        case 'tags':
          setState(() => _tagsExpanded = true);
          _saveExpansionState('tags', true);
          break;
        case 'data':
          setState(() => _dataExportExpanded = true);
          _saveExpansionState('dataExport', true);
          break;
        case 'advanced':
          setState(() => _advancedExpanded = true);
          _saveExpansionState('advanced', true);
          break;
        case 'about':
          setState(() => _aboutExpanded = true);
          _saveExpansionState('about', true);
          break;
      }
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
      _highlightedItemId = null;
    });
  }

  /// Check if text matches the search query
  bool _matchesText(String? text, String queryLower) {
    if (text == null) return false;
    return text.toLowerCase().contains(queryLower);
  }

  /// Check if a widget matches the search query and return match info
  ({bool matches, String? matchText}) _checkWidgetMatch(
    Widget widget,
    String? itemTag,
    String queryLower,
  ) {
    final titleText = _getTitleFromWidget(widget);
    final subtitleText = _getSubtitleFromWidget(widget);

    // Priority 1: Check the specific tag for this item (most reliable)
    if (itemTag != null && _matchesText(itemTag, queryLower)) {
      return (matches: true, matchText: itemTag);
    }
    // Priority 2: Check title text (user-visible, most important)
    if (titleText != null && _matchesText(titleText, queryLower)) {
      return (matches: true, matchText: titleText);
    }
    // Priority 3: Check subtitle text (less important, but useful)
    if (subtitleText != null && _matchesText(subtitleText, queryLower)) {
      return (matches: true, matchText: subtitleText);
    }

    return (matches: false, matchText: null);
  }

  /// Process a single widget and add to results if it matches
  void _processWidgetForSearch({
    required Widget widget,
    required String sectionId,
    required String sectionTitle,
    required IconData sectionIcon,
    required String? itemTag,
    required String queryLower,
    required List<SearchResult> results,
    required int itemIndex,
  }) {
    final match = _checkWidgetMatch(widget, itemTag, queryLower);
    if (match.matches && match.matchText != null) {
      results.add(
        SearchResult(
          sectionId: sectionId,
          sectionTitle: sectionTitle,
          sectionIcon: sectionIcon,
          item: widget,
          itemTitle: _getTitleFromWidget(widget),
          itemSubtitle: _getSubtitleFromWidget(widget),
          itemIndex: itemIndex,
          searchMatchText: match.matchText,
        ),
      );
    }
  }

  /// Get search results with memoization
  List<SearchResult> _getSearchResults(
    String trimmedQuery,
    Map<String, Map<String, dynamic>> sectionsMap,
  ) {
    // Return cached results if query hasn't changed
    if (trimmedQuery == _cachedSearchQuery && _cachedSearchResults != null) {
      return _cachedSearchResults!;
    }

    // Calculate new results
    final results = trimmedQuery.isEmpty
        ? <SearchResult>[]
        : _performSearch(query: trimmedQuery, sections: sectionsMap);

    // Cache the results
    _cachedSearchResults = results;
    _cachedSearchQuery = trimmedQuery;

    return results;
  }

  /// Perform unified search across all sections
  List<SearchResult> _performSearch({
    required String query,
    required Map<String, Map<String, dynamic>> sections,
  }) {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();
    final results = <SearchResult>[];

    // Process each section
    sections.forEach((sectionId, sectionData) {
      final sectionTitle = sectionData['title'] as String;
      final sectionIcon = sectionData['icon'] as IconData;
      final children = sectionData['children'] as List<Widget>;
      final tags = sectionData['tags'] as List<String>?;

      int itemIndex = 0;

      for (int i = 0; i < children.length; i++) {
        final child = children[i];

        // If child is a Column (like section content), extract individual items
        if (child is Column) {
          final items = _extractItemsFromColumn(child);
          // Tags array should correspond to items in order (one tag per item)
          for (int itemIdx = 0; itemIdx < items.length; itemIdx++) {
            final item = items[itemIdx];
            final itemTag = (tags != null && itemIdx < tags.length)
                ? tags[itemIdx]
                : null;

            _processWidgetForSearch(
              widget: item,
              sectionId: sectionId,
              sectionTitle: sectionTitle,
              sectionIcon: sectionIcon,
              itemTag: itemTag,
              queryLower: queryLower,
              results: results,
              itemIndex: itemIndex,
            );
            itemIndex++;
          }
        } else {
          // Regular widget (not a Column)
          final itemTag = (tags != null && i < tags.length) ? tags[i] : null;

          _processWidgetForSearch(
            widget: child,
            sectionId: sectionId,
            sectionTitle: sectionTitle,
            sectionIcon: sectionIcon,
            itemTag: itemTag,
            queryLower: queryLower,
            results: results,
            itemIndex: itemIndex,
          );
          itemIndex++;
        }
      }
    });

    return results;
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
    final trimmedQuery = _searchController.text.trim();
    final hasSearch = trimmedQuery.isNotEmpty;

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
    final appearanceTags = <String>[
      _keyToSearchText('font_size_scale'),
      _keyToSearchText('icon_size'),
      _keyToSearchText('border_radius'),
      _keyToSearchText('elevation'),
      _keyToSearchText('card_spacing'),
      _keyToSearchText('habit_checkbox_style'),
      _keyToSearchText('progress_indicator_style'),
      _keyToSearchText('calendar_completion_color'),
      _keyToSearchText('habit_card_completion_color'),
      _keyToSearchText('calendar_timeline_completion_color'),
      _keyToSearchText('main_timeline_completion_color'),
      _keyToSearchText('calendar_bad_habit_completion_color'),
      _keyToSearchText('habit_card_bad_habit_completion_color'),
      _keyToSearchText('calendar_timeline_bad_habit_completion_color'),
      _keyToSearchText('main_timeline_bad_habit_completion_color'),
      _keyToSearchText('streak_color_scheme'),
    ];

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
    final displayTags = <String>[
      _keyToSearchText('habits_layout_mode'),
      _keyToSearchText('grid_show_icon'),
      _keyToSearchText('grid_show_completion'),
      _keyToSearchText('grid_show_timeline'),
      _keyToSearchText('show_main_timeline'),
      _keyToSearchText('day_square_size'),
      _keyToSearchText('timeline_days'),
      _keyToSearchText('main_timeline_fill_lines'),
      _keyToSearchText('main_timeline_lines'),
      _keyToSearchText('timeline_spacing'),
      _keyToSearchText('timeline_compact_mode'),
      _keyToSearchText('use_streak_colors_for_squares'),
      _keyToSearchText('show_streak_borders'),
      _keyToSearchText('show_week_month_highlights'),
      _keyToSearchText('show_streak_numbers'),
      _keyToSearchText('habit_card_layout_mode'),
      _keyToSearchText('show_descriptions'),
      _keyToSearchText('compact_cards'),
      _keyToSearchText('show_percentage'),
      _keyToSearchText('show_streak_on_card'),
      _keyToSearchText('habit_card_timeline_fill_lines'),
      _keyToSearchText('habit_card_timeline_lines'),
      _keyToSearchText('habit_card_timeline_days'),
      _keyToSearchText('modal_timeline_days'),
      _keyToSearchText('show_statistics_card'),
    ];

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

    // Tags management
    final tagsTitle = 'tags'.tr();
    final tagsChildren = <Widget>[const TagsSectionContent()];
    final tagsTags = <String>[_keyToSearchText('tags')];

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

    final aboutTitle = 'about'.tr();

    // Collect all sections for unified search
    final sectionsMap = <String, Map<String, dynamic>>{
      'general': {
        'title': generalTitle,
        'icon': Icons.settings,
        'children': generalChildren,
        'tags': generalTags,
      },
      'appearance': {
        'title': appearanceTitle,
        'icon': Icons.palette,
        'children': appearanceChildren,
        'tags': appearanceTags,
      },
      'dateTime': {
        'title': dateTimeTitle,
        'icon': Icons.calendar_today,
        'children': dateTimeChildren,
        'tags': dateTimeTags,
      },
      'display': {
        'title': displayTitle,
        'icon': Icons.view_quilt,
        'children': displayChildren,
        'tags': displayTags,
      },
      'notifications': {
        'title': notificationsTitle,
        'icon': Icons.notifications,
        'children': notificationsChildren,
        'tags': notificationsTags,
      },
      'tags': {
        'title': tagsTitle,
        'icon': Icons.label,
        'children': tagsChildren,
        'tags': tagsTags,
      },
      'data': {
        'title': dataTitle,
        'icon': Icons.storage,
        'children': dataChildren,
        'tags': dataTags,
      },
      'advanced': {
        'title': advancedTitle,
        'icon': Icons.settings_applications,
        'children': advancedChildren,
        'tags': advancedTags,
      },
      'about': {
        'title': aboutTitle,
        'icon': Icons.info,
        'children': [
          FutureBuilder<PackageInfo?>(
            future: _getPackageInfo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text('loading'),
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
        ],
        'tags': [_keyToSearchText('about')],
      },
    };

    // Perform search with memoization (only recalculate when query changes)
    final searchResults = _getSearchResults(trimmedQuery, sectionsMap);

    // Build settings list - always show normal sections (never affected by search)
    final settingsList = ListView(
      children: [
        _buildCollapsibleSection(
          title: generalTitle,
          icon: Icons.settings,
          isExpanded: _generalExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _generalExpanded = expanded;
            });
            _saveExpansionState('general', expanded);
          },
          children: generalChildren,
          sectionId: 'general',
        ),
        _buildCollapsibleSection(
          title: appearanceTitle,
          icon: Icons.palette,
          isExpanded: _appearanceExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _appearanceExpanded = expanded;
            });
            _saveExpansionState('appearance', expanded);
          },
          children: appearanceChildren,
          sectionId: 'appearance',
        ),
        // Date & Time before Display
        _buildCollapsibleSection(
          title: dateTimeTitle,
          icon: Icons.calendar_today,
          isExpanded: _dateTimeExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _dateTimeExpanded = expanded;
            });
            _saveExpansionState('dateTime', expanded);
          },
          children: dateTimeChildren,
          sectionId: 'dateTime',
        ),
        _buildCollapsibleSection(
          title: displayTitle,
          icon: Icons.view_quilt,
          isExpanded: _displayLayoutExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _displayLayoutExpanded = expanded;
            });
            _saveExpansionState('displayLayout', expanded);
          },
          children: displayChildren,
          sectionId: 'display',
        ),
        _buildCollapsibleSection(
          title: notificationsTitle,
          icon: Icons.notifications,
          isExpanded: _notificationsExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _notificationsExpanded = expanded;
            });
            _saveExpansionState('notifications', expanded);
          },
          children: notificationsChildren,
          sectionId: 'notifications',
        ),
        _buildCollapsibleSection(
          title: tagsTitle,
          icon: Icons.label,
          isExpanded: _tagsExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _tagsExpanded = expanded;
            });
            _saveExpansionState('tags', expanded);
          },
          children: tagsChildren,
          sectionId: 'tags',
        ),
        _buildCollapsibleSection(
          title: dataTitle,
          icon: Icons.storage,
          isExpanded: _dataExportExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _dataExportExpanded = expanded;
            });
            _saveExpansionState('dataExport', expanded);
          },
          children: dataChildren,
          sectionId: 'data',
        ),
        _buildCollapsibleSection(
          title: advancedTitle,
          icon: Icons.settings_applications,
          isExpanded: _advancedExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _advancedExpanded = expanded;
            });
            _saveExpansionState('advanced', expanded);
          },
          children: advancedChildren,
          sectionId: 'advanced',
        ),
        // About section
        _buildCollapsibleSection(
          title: aboutTitle,
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
          ],
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

    // In landscape with search, show grouped results in right pane
    final landscapeDetailContent =
        isLandscape && hasSearch && searchResults.isNotEmpty
        ? _buildGroupedSearchResults(searchResults, trimmedQuery)
        : _detailContent;

    final landscapeDetailTitle =
        isLandscape && hasSearch && searchResults.isNotEmpty
        ? 'search_results'.tr()
        : _detailTitle;

    // Show empty state in right pane if search is active but no results
    final finalLandscapeDetailContent =
        isLandscape && hasSearch && searchResults.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'no_results_found'.tr(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        : landscapeDetailContent;

    final bodyContent = isLandscape
        ? SplitScreenSettingsLayout(
            key: const ValueKey('landscape'),
            settingsList: settingsList,
            detailContent: finalLandscapeDetailContent,
            detailTitle: landscapeDetailTitle,
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

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
        actions: [_buildExpandableSearch()],
      ),
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
