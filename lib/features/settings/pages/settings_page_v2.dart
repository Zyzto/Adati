/// Adati Settings Page V2
///
/// This is the settings page using the Flutter Settings Framework.
/// It features Card-based sections with custom styling matching the original
/// settings page design.
library;

import 'package:animations/animations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/services/preferences_service.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart';
import '../settings_definitions.dart';
import '../providers/settings_framework_providers.dart';
import '../widgets/dialogs/about_dialogs.dart';
import '../widgets/dialogs/advanced_dialogs.dart';
import '../widgets/dialogs/data_dialogs.dart';
import '../widgets/sections/tags_section.dart';

/// Settings page built with the new framework.
///
/// This page demonstrates:
/// - Card-based sections with custom styling
/// - Multi-language search
/// - Responsive layout (split-screen on landscape)
/// - Section expansion state persistence
class SettingsPageV2 extends ConsumerStatefulWidget {
  const SettingsPageV2({super.key});

  @override
  ConsumerState<SettingsPageV2> createState() => _SettingsPageV2State();
}

class _SettingsPageV2State extends ConsumerState<SettingsPageV2> {
  // Search state
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchExpanded = false;

  // Split-screen detail state
  String? _selectedSectionId;
  Widget? _detailContent;
  String? _detailTitle;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
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

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearchExpanded = false;
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(adatiSettingsProvider);
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
    final hasSearch = _searchQuery.isNotEmpty;

    // Build sections
    final sections = _buildSections(settings, isLandscape, hasSearch);

    // Filter sections if searching
    final filteredSections = hasSearch
        ? _buildSearchResults(settings)
        : sections;

    final settingsList = ListView(children: filteredSections);

    // Clear detail pane when switching to portrait
    if (!isLandscape && _selectedSectionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _clearDetailPane();
      });
    }

    final bodyContent = isLandscape
        ? SplitScreenLayout(
            key: const ValueKey('landscape'),
            listPane: settingsList,
            detailPane: _detailContent,
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

    return Scaffold(
      appBar: _buildAppBar(),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
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

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('settings'.tr()),
      actions: [_buildExpandableSearch()],
    );
  }

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
            if (_searchController.text.trim().isEmpty) {
              _collapseSearch();
            } else {
              _searchFocusNode.requestFocus();
            }
          },
          onChanged: (value) {
            if (!_searchFocusNode.hasFocus) {
              _searchFocusNode.requestFocus();
            }
          },
        ),
      ),
    );
  }

  // ==========================================================================
  // COLLAPSIBLE SECTION BUILDER (Using package's CardSettingsSection)
  // ==========================================================================

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isExpanded,
    required ValueChanged<bool> onExpansionChanged,
    required String sectionId,
    required bool isLandscape,
  }) {
    return CardSettingsSection(
      title: title,
      icon: icon,
      isExpanded: isExpanded,
      onExpansionChanged: onExpansionChanged,
      sectionId: sectionId,
      isSelected: _selectedSectionId == sectionId && isLandscape,
      isLandscape: isLandscape,
      onLandscapeTap: () => _showSectionInDetailPane(
        sectionId: sectionId,
        content: ListView(
          padding: const EdgeInsets.all(16),
          children: children,
        ),
        title: title,
      ),
      children: children,
    );
  }

  void _showSectionInDetailPane({
    required String sectionId,
    required Widget content,
    required String title,
  }) {
    setState(() {
      _selectedSectionId = sectionId;
      _detailContent = content;
      _detailTitle = title;
    });
  }

  void _clearDetailPane() {
    setState(() {
      _selectedSectionId = null;
      _detailContent = null;
      _detailTitle = null;
    });
  }

  // ==========================================================================
  // BUILD SECTIONS
  // ==========================================================================

  List<Widget> _buildSections(
    SettingsProviders settings,
    bool isLandscape,
    bool hasSearch,
  ) {
    final sections = <Widget>[];

    // General section
    final generalChildren = _buildGeneralChildren(settings);
    if (!hasSearch || _hasVisibleItems(generalChildren)) {
      sections.add(_buildGeneralSection(settings, isLandscape, hasSearch));
    }

    // Appearance section
    final appearanceChildren = _buildAppearanceChildren(settings);
    if (!hasSearch || _hasVisibleItems(appearanceChildren)) {
      sections.add(_buildAppearanceSection(settings, isLandscape, hasSearch));
    }

    // Date & Time section
    final dateTimeChildren = _buildDateTimeChildren(settings);
    if (!hasSearch || _hasVisibleItems(dateTimeChildren)) {
      sections.add(_buildDateTimeSection(settings, isLandscape, hasSearch));
    }

    // Display & Layout section
    final displayChildren = _buildDisplayLayoutChildren(settings);
    if (!hasSearch || _hasVisibleItems(displayChildren)) {
      sections.add(
        _buildDisplayLayoutSection(settings, isLandscape, hasSearch),
      );
    }

    // Notifications section
    final notificationsChildren = _buildNotificationsChildren(settings);
    if (!hasSearch || _hasVisibleItems(notificationsChildren)) {
      sections.add(
        _buildNotificationsSection(settings, isLandscape, hasSearch),
      );
    }

    // Tags section - excluded from search
    if (!hasSearch) {
      sections.add(_buildTagsSection(settings, isLandscape));
    }

    // Data section
    final dataChildren = _buildDataChildren(settings);
    if (!hasSearch || _hasVisibleItems(dataChildren)) {
      sections.add(_buildDataSection(settings, isLandscape, hasSearch));
    }

    // Advanced section
    final advancedChildren = _buildAdvancedChildren(settings);
    if (!hasSearch || _hasVisibleItems(advancedChildren)) {
      sections.add(_buildAdvancedSection(settings, isLandscape, hasSearch));
    }

    // About section
    final aboutChildren = _buildAboutChildren(settings);
    if (!hasSearch || _hasVisibleItems(aboutChildren)) {
      sections.add(_buildAboutSection(settings, isLandscape, hasSearch));
    }

    return sections;
  }

  bool _hasVisibleItems(List<Widget> widgets) {
    return widgets.isNotEmpty;
  }

  List<Widget> _buildSearchResults(SettingsProviders settings) {
    final results = ref.watch(settingsSearchResultsProvider(_searchQuery));

    if (results.isEmpty) {
      return [
        EmptySearchResults(query: _searchQuery, message: 'no_results'.tr()),
      ];
    }

    return buildSearchResultWidgets(
      results,
      tileBuilder: (setting) => _buildTileForSetting(settings, setting),
      sectionTitleBuilder: (key) => key.tr(),
    );
  }

  Widget _buildTileForSetting(
    SettingsProviders settings,
    SettingDefinition setting,
  ) {
    if (setting is BoolSetting) {
      return _buildBoolTile(settings, setting);
    } else if (setting is EnumSetting) {
      return _buildEnumTile(settings, setting);
    } else if (setting is IntSetting) {
      return _buildIntTile(settings, setting);
    } else if (setting is DoubleSetting) {
      return _buildDoubleTile(settings, setting);
    } else if (setting is ColorSetting) {
      return _buildColorTile(settings, setting);
    }
    return const SizedBox.shrink();
  }

  // ==========================================================================
  // GENERAL SECTION
  // ==========================================================================

  List<Widget> _buildGeneralChildren(SettingsProviders settings) {
    return [
      _buildLanguageTile(settings),
      _buildEnumTile(settings, themeModeSettingDef),
      _buildColorTile(settings, themeColorSettingDef),
    ];
  }

  Widget _buildGeneralSection(
    SettingsProviders settings,
    bool isLandscape,
    bool hasSearch,
  ) {
    final isExpanded = hasSearch
        ? true
        : ref.watch(settings.provider(settingsGeneralExpandedDef));

    return _buildSection(
      title: 'general'.tr(),
      icon: Icons.settings,
      isExpanded: isExpanded,
      onExpansionChanged: (expanded) {
        if (!hasSearch) {
          ref
              .read(settings.provider(settingsGeneralExpandedDef).notifier)
              .set(expanded);
        }
      },
      children: _buildGeneralChildren(settings),
      sectionId: 'general',
      isLandscape: isLandscape,
    );
  }

  Widget _buildLanguageTile(SettingsProviders settings) {
    final value = ref.watch(settings.provider(languageSettingDef));
    return SelectSettingsTile.fromEnumSetting(
      setting: languageSettingDef,
      title: languageSettingDef.titleKey.tr(),
      subtitle: _getEnumLabel(languageSettingDef, value),
      value: value,
      labelBuilder: (opt) => _getEnumLabel(languageSettingDef, opt),
      dialogTitle: languageSettingDef.titleKey.tr(),
      onChanged: (newValue) async {
        if (newValue != null && newValue != value) {
          await _updateSetting(
            settings,
            languageSettingDef,
            newValue,
            showSnackBar: true,
          );
          if (mounted) {
            context.setLocale(Locale(newValue));
          }
        }
      },
    );
  }

  // ==========================================================================
  // APPEARANCE SECTION
  // ==========================================================================

  List<Widget> _buildAppearanceChildren(SettingsProviders settings) {
    return [
      SettingsSubsectionHeader(
        title: 'settings_section_appearance_typography'.tr(),
        icon: Icons.text_fields,
      ),
      _buildEnumTile(settings, fontSizeScaleSettingDef),
      _buildEnumTile(settings, iconSizeSettingDef),
      const Divider(),
      SettingsSubsectionHeader(
        title: 'settings_section_appearance_card_style'.tr(),
        icon: Icons.credit_card,
      ),
      _buildDoubleTile(settings, cardBorderRadiusSettingDef),
      _buildDoubleTile(settings, cardElevationSettingDef),
      _buildDoubleTile(settings, cardSpacingSettingDef),
      const Divider(),
      SettingsSubsectionHeader(
        title: 'settings_section_appearance_component_styles'.tr(),
        icon: Icons.style,
      ),
      _buildEnumTile(settings, habitCheckboxStyleSettingDef),
      _buildEnumTile(settings, progressIndicatorStyleSettingDef),
      const Divider(),
      SettingsSubsectionHeader(
        title: 'settings_section_appearance_completion_colors_positive'.tr(),
        icon: Icons.thumb_up,
      ),
      _buildColorTile(settings, calendarCompletionColorSettingDef),
      _buildColorTile(settings, habitCardCompletionColorSettingDef),
      _buildColorTile(settings, calendarTimelineCompletionColorSettingDef),
      _buildColorTile(settings, mainTimelineCompletionColorSettingDef),
      const Divider(),
      SettingsSubsectionHeader(
        title: 'settings_section_appearance_completion_colors_negative'.tr(),
        icon: Icons.thumb_down,
      ),
      _buildColorTile(settings, calendarBadHabitCompletionColorSettingDef),
      _buildColorTile(settings, habitCardBadHabitCompletionColorSettingDef),
      _buildColorTile(
        settings,
        calendarTimelineBadHabitCompletionColorSettingDef,
      ),
      _buildColorTile(settings, mainTimelineBadHabitCompletionColorSettingDef),
      const Divider(),
      SettingsSubsectionHeader(
        title: 'settings_section_appearance_streak_colors'.tr(),
        icon: Icons.local_fire_department,
      ),
      _buildEnumTile(settings, streakColorSchemeSettingDef),
    ];
  }

  Widget _buildAppearanceSection(
    SettingsProviders settings,
    bool isLandscape,
    bool hasSearch,
  ) {
    final isExpanded = hasSearch
        ? true
        : ref.watch(settings.provider(settingsAppearanceExpandedDef));

    return _buildSection(
      title: 'appearance'.tr(),
      icon: Icons.palette,
      isExpanded: isExpanded,
      onExpansionChanged: (expanded) {
        if (!hasSearch) {
          ref
              .read(settings.provider(settingsAppearanceExpandedDef).notifier)
              .set(expanded);
        }
      },
      children: _buildAppearanceChildren(settings),
      sectionId: 'appearance',
      isLandscape: isLandscape,
    );
  }

  // ==========================================================================
  // DATE & TIME SECTION
  // ==========================================================================

  List<Widget> _buildDateTimeChildren(SettingsProviders settings) {
    return [
      _buildEnumTile(settings, dateFormatSettingDef),
      _buildFirstDayOfWeekTile(settings),
    ];
  }

  Widget _buildDateTimeSection(
    SettingsProviders settings,
    bool isLandscape,
    bool hasSearch,
  ) {
    final isExpanded = hasSearch
        ? true
        : ref.watch(settings.provider(settingsDateTimeExpandedDef));

    return _buildSection(
      title: 'date_time'.tr(),
      icon: Icons.calendar_today,
      isExpanded: isExpanded,
      onExpansionChanged: (expanded) {
        if (!hasSearch) {
          ref
              .read(settings.provider(settingsDateTimeExpandedDef).notifier)
              .set(expanded);
        }
      },
      children: _buildDateTimeChildren(settings),
      sectionId: 'dateTime',
      isLandscape: isLandscape,
    );
  }

  // ==========================================================================
  // DISPLAY & LAYOUT SECTION
  // ==========================================================================

  List<Widget> _buildDisplayLayoutChildren(SettingsProviders settings) {
    return [
      // Habits Layout subsection
      SettingsSubsectionHeader(
        title: 'settings_section_display_habits_layout'.tr(),
        icon: Icons.view_list,
      ),
      _buildEnumTile(settings, habitsLayoutModeSettingDef),
      _buildEnumTile(settings, defaultViewSettingDef),
      _buildEnumTile(settings, habitCardLayoutModeSettingDef),
      const Divider(),
      // Display Preferences subsection
      SettingsSubsectionHeader(
        title: 'display_preferences'.tr(),
        icon: Icons.tune,
      ),
      _buildBoolTile(settings, showStreakBordersSettingDef),
      _buildBoolTile(settings, showStreakNumbersSettingDef),
      _buildBoolTile(settings, showStreakOnCardSettingDef),
      _buildBoolTile(settings, showDescriptionsSettingDef),
      _buildBoolTile(settings, showPercentageSettingDef),
      _buildBoolTile(settings, compactCardsSettingDef),
      const Divider(),
      // Grid View subsection
      SettingsSubsectionHeader(
        title: 'grid_view_settings'.tr(),
        icon: Icons.grid_view,
      ),
      _buildBoolTile(settings, gridShowIconSettingDef),
      _buildBoolTile(settings, gridShowCompletionSettingDef),
      _buildEnumTile(settings, gridCompletionButtonPlacementSettingDef),
      _buildBoolTile(settings, gridShowTimelineSettingDef),
      _buildEnumTile(settings, gridTimelineBoxSizeSettingDef),
      _buildEnumTile(settings, gridTimelineFitModeSettingDef),
      const Divider(),
      // Timelines subsection
      SettingsSubsectionHeader(
        title: 'settings_section_display_timelines'.tr(),
        icon: Icons.view_timeline,
      ),
      _buildIntTile(settings, timelineDaysSettingDef),
      _buildIntTile(settings, modalTimelineDaysSettingDef),
      _buildIntTile(settings, habitCardTimelineDaysSettingDef),
      _buildEnumTile(settings, daySquareSizeSettingDef),
      _buildDoubleTile(settings, timelineSpacingSettingDef),
      _buildBoolTile(settings, timelineCompactModeSettingDef),
      _buildBoolTile(settings, showWeekMonthHighlightsSettingDef),
      _buildBoolTile(settings, useStreakColorsForSquaresSettingDef),
      const Divider(),
      // Main Timeline Lines subsection
      SettingsSubsectionHeader(
        title: 'main_timeline_settings'.tr(),
        icon: Icons.timeline,
      ),
      _buildBoolTile(settings, mainTimelineFillLinesSettingDef),
      _buildIntTile(settings, mainTimelineLinesSettingDef),
      const Divider(),
      // Habit Card Timeline Lines subsection
      SettingsSubsectionHeader(
        title: 'habit_card_timeline_settings'.tr(),
        icon: Icons.credit_card,
      ),
      _buildBoolTile(settings, habitCardTimelineFillLinesSettingDef),
      _buildIntTile(settings, habitCardTimelineLinesSettingDef),
      const Divider(),
      // Statistics subsection
      SettingsSubsectionHeader(
        title: 'settings_section_display_statistics'.tr(),
        icon: Icons.bar_chart,
      ),
      _buildBoolTile(settings, showStatisticsCardSettingDef),
      _buildBoolTile(settings, showMainTimelineSettingDef),
    ];
  }

  Widget _buildDisplayLayoutSection(
    SettingsProviders settings,
    bool isLandscape,
    bool hasSearch,
  ) {
    final isExpanded = hasSearch
        ? true
        : ref.watch(settings.provider(settingsDisplayLayoutExpandedDef));

    return _buildSection(
      title: 'display_layout'.tr(),
      icon: Icons.view_quilt,
      isExpanded: isExpanded,
      onExpansionChanged: (expanded) {
        if (!hasSearch) {
          ref
              .read(
                settings.provider(settingsDisplayLayoutExpandedDef).notifier,
              )
              .set(expanded);
        }
      },
      children: _buildDisplayLayoutChildren(settings),
      sectionId: 'displayLayout',
      isLandscape: isLandscape,
    );
  }

  // ==========================================================================
  // NOTIFICATIONS SECTION
  // ==========================================================================

  List<Widget> _buildNotificationsChildren(SettingsProviders settings) {
    return [_buildBoolTile(settings, notificationsEnabledSettingDef)];
  }

  Widget _buildNotificationsSection(
    SettingsProviders settings,
    bool isLandscape,
    bool hasSearch,
  ) {
    final isExpanded = hasSearch
        ? true
        : ref.watch(settings.provider(settingsNotificationsExpandedDef));

    return _buildSection(
      title: 'notifications'.tr(),
      icon: Icons.notifications,
      isExpanded: isExpanded,
      onExpansionChanged: (expanded) {
        if (!hasSearch) {
          ref
              .read(
                settings.provider(settingsNotificationsExpandedDef).notifier,
              )
              .set(expanded);
        }
      },
      children: _buildNotificationsChildren(settings),
      sectionId: 'notifications',
      isLandscape: isLandscape,
    );
  }

  // ==========================================================================
  // TAGS SECTION
  // ==========================================================================

  Widget _buildTagsSection(SettingsProviders settings, bool isLandscape) {
    final isExpanded = ref.watch(settings.provider(settingsTagsExpandedDef));

    return _buildSection(
      title: 'tags'.tr(),
      icon: Icons.label,
      isExpanded: isExpanded,
      onExpansionChanged: (expanded) {
        ref
            .read(settings.provider(settingsTagsExpandedDef).notifier)
            .set(expanded);
      },
      children: const [TagsSectionContent()],
      sectionId: 'tags',
      isLandscape: isLandscape,
    );
  }

  // ==========================================================================
  // DATA SECTION
  // ==========================================================================

  List<Widget> _buildDataChildren(SettingsProviders settings) {
    return [
      // Auto-backup settings subsection
      SettingsSubsectionHeader(
        title: 'settings_section_auto_backup'.tr(),
        icon: Icons.backup,
      ),
      _buildBoolTile(settings, autoBackupEnabledSettingDef),
      _buildIntTile(settings, autoBackupRetentionCountSettingDef),
      _AutoBackupDirectoryTile(),
      _AutoBackupLastBackupTile(),
      NavigationSettingsTile(
        leading: const Icon(Icons.play_arrow),
        title: Text('auto_backup_manual_trigger'.tr()),
        subtitle: Text('auto_backup_manual_description'.tr()),
        onTap: () => DataDialogs.triggerManualBackup(context),
      ),
      NavigationSettingsTile(
        leading: const Icon(Icons.restore),
        title: Text('restore_from_backup'.tr()),
        subtitle: Text('restore_from_backup_description'.tr()),
        onTap: () => DataDialogs.showRestoreDialog(context, ref),
      ),
      const Divider(),
      // Import/Export subsection
      SettingsSubsectionHeader(
        title: 'import_export'.tr(),
        icon: Icons.import_export,
      ),
      ActionSettingsTile(
        leading: const Icon(Icons.file_upload),
        title: Text('export_data'.tr()),
        subtitle: Text('export_habit_data_description'.tr()),
        onTap: () => DataDialogs.showExportDialog(context, ref),
      ),
      ActionSettingsTile(
        leading: const Icon(Icons.file_download),
        title: Text('import_data'.tr()),
        subtitle: Text('import_data_description'.tr()),
        onTap: () => DataDialogs.showImportDialog(context, ref),
      ),
      const Divider(),
      // Database subsection
      SettingsSubsectionHeader(
        title: 'settings_section_data_database'.tr(),
        icon: Icons.storage,
      ),
      NavigationSettingsTile(
        leading: const Icon(Icons.info_outline),
        title: Text('database_statistics'.tr()),
        subtitle: Text('database_statistics_description'.tr()),
        onTap: () => DataDialogs.showDatabaseStatsDialog(context, ref),
      ),
      ActionSettingsTile(
        leading: const Icon(Icons.cleaning_services),
        title: Text('optimize_database'.tr()),
        subtitle: Text('optimize_database_description'.tr()),
        onTap: () => DataDialogs.optimizeDatabase(context, ref),
      ),
    ];
  }

  Widget _buildDataSection(
    SettingsProviders settings,
    bool isLandscape,
    bool hasSearch,
  ) {
    final isExpanded = hasSearch
        ? true
        : ref.watch(settings.provider(settingsDataExportExpandedDef));

    return _buildSection(
      title: 'data_management'.tr(),
      icon: Icons.storage,
      isExpanded: isExpanded,
      onExpansionChanged: (expanded) {
        if (!hasSearch) {
          ref
              .read(settings.provider(settingsDataExportExpandedDef).notifier)
              .set(expanded);
        }
      },
      children: _buildDataChildren(settings),
      sectionId: 'data',
      isLandscape: isLandscape,
    );
  }

  // ==========================================================================
  // ADVANCED SECTION
  // ==========================================================================

  List<Widget> _buildAdvancedChildren(SettingsProviders settings) {
    return [
      _buildEnumTile(settings, badHabitLogicModeSettingDef),
      const Divider(),
      SettingsSubsectionHeader(
        title: 'dangerous_actions'.tr(),
        icon: Icons.warning,
      ),
      ActionSettingsTile(
        leading: const Icon(Icons.delete_sweep),
        title: Text('reset_all_habits'.tr()),
        subtitle: Text('reset_all_habits_description'.tr()),
        isDangerous: true,
        onTap: () => AdvancedDialogs.showResetHabitsDialog(context, ref),
      ),
      ActionSettingsTile(
        leading: const Icon(Icons.settings_backup_restore),
        title: Text('reset_all_settings'.tr()),
        subtitle: Text('reset_all_settings_description'.tr()),
        isDangerous: true,
        onTap: () => _showResetConfirmation(),
      ),
      ActionSettingsTile(
        leading: const Icon(Icons.delete_forever),
        title: Text('clear_all_data'.tr()),
        subtitle: Text('clear_all_data_description'.tr()),
        isDangerous: true,
        onTap: () => AdvancedDialogs.showClearAllDataDialog(context, ref),
      ),
      const Divider(),
      SettingsSubsectionHeader(title: 'tools'.tr(), icon: Icons.build),
      NavigationSettingsTile(
        leading: const Icon(Icons.description),
        title: Text('logs'.tr()),
        subtitle: Text('logs_description'.tr()),
        onTap: () => AdvancedDialogs.showLogsDialog(context, ref),
      ),
      NavigationSettingsTile(
        leading: const Icon(Icons.school),
        title: Text('return_to_onboarding'.tr()),
        subtitle: Text('return_to_onboarding_description'.tr()),
        onTap: () => AdvancedDialogs.returnToOnboarding(context),
      ),
    ];
  }

  Widget _buildAdvancedSection(
    SettingsProviders settings,
    bool isLandscape,
    bool hasSearch,
  ) {
    final isExpanded = hasSearch
        ? true
        : ref.watch(settings.provider(settingsAdvancedExpandedDef));

    return _buildSection(
      title: 'advanced'.tr(),
      icon: Icons.settings_applications,
      isExpanded: isExpanded,
      onExpansionChanged: (expanded) {
        if (!hasSearch) {
          ref
              .read(settings.provider(settingsAdvancedExpandedDef).notifier)
              .set(expanded);
        }
      },
      children: _buildAdvancedChildren(settings),
      sectionId: 'advanced',
      isLandscape: isLandscape,
    );
  }

  // ==========================================================================
  // ABOUT SECTION
  // ==========================================================================

  List<Widget> _buildAboutChildren(SettingsProviders settings) {
    return [
      FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.hasData
              ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
              : '...';
          return InfoSettingsTile(
            leading: const Icon(Icons.info),
            title: Text('app_name_label'.tr()),
            value: Text('Adati v$version'),
          );
        },
      ),
      NavigationSettingsTile(
        leading: const Icon(Icons.code),
        title: Text('open_source_libraries'.tr()),
        subtitle: Text('open_source_libraries_description'.tr()),
        onTap: () => AboutDialogs.showLibrariesDialog(context),
      ),
      NavigationSettingsTile(
        leading: const Icon(Icons.description),
        title: Text('license'.tr()),
        subtitle: Text('license_description'.tr()),
        onTap: () => AboutDialogs.showLicenseDialog(context),
      ),
      NavigationSettingsTile(
        leading: const Icon(Icons.privacy_tip),
        title: Text('privacy_policy'.tr()),
        subtitle: Text('privacy_policy_description'.tr()),
        onTap: () => AboutDialogs.showPrivacyPolicyDialog(context),
      ),
    ];
  }

  Widget _buildAboutSection(
    SettingsProviders settings,
    bool isLandscape,
    bool hasSearch,
  ) {
    final isExpanded = hasSearch
        ? true
        : ref.watch(settings.provider(settingsAboutExpandedDef));

    return _buildSection(
      title: 'about'.tr(),
      icon: Icons.info,
      isExpanded: isExpanded,
      onExpansionChanged: (expanded) {
        if (!hasSearch) {
          ref
              .read(settings.provider(settingsAboutExpandedDef).notifier)
              .set(expanded);
        }
      },
      children: _buildAboutChildren(settings),
      sectionId: 'about',
      isLandscape: isLandscape,
    );
  }

  // ==========================================================================
  // TILE BUILDERS
  // ==========================================================================

  /// Check if a setting is enabled based on its dependencies.
  /// This watches the dependency provider reactively so UI updates automatically.
  bool _isSettingEnabled(
    SettingsProviders settings,
    SettingDefinition setting,
  ) {
    if (setting.dependsOn == null) return true;

    // Find the dependency setting in the registry
    final depSetting = settings.registry.get(setting.dependsOn!);
    if (depSetting == null) return true;

    // Watch the dependency value reactively
    final depValue = ref.watch(settings.provider(depSetting));

    // Check if the dependency condition is met
    return depValue == setting.enabledWhen;
  }

  Widget _buildBoolTile(SettingsProviders settings, BoolSetting setting) {
    final value = ref.watch(settings.provider(setting));
    final enabled = _isSettingEnabled(settings, setting);
    return SwitchSettingsTile.fromSetting(
      setting: setting,
      title: setting.titleKey.tr(),
      subtitle: setting.subtitleKey?.tr(),
      value: value,
      enabled: enabled,
      onChanged: enabled
          ? (newValue) => _updateSetting(settings, setting, newValue)
          : null,
    );
  }

  Widget _buildEnumTile(SettingsProviders settings, EnumSetting setting) {
    final value = ref.watch(settings.provider(setting));
    final enabled = _isSettingEnabled(settings, setting);
    final isInline = setting.editMode == SettingEditMode.inline;
    return EnumSettingsTile.fromSetting(
      setting: setting,
      title: setting.titleKey.tr(),
      subtitle: _getEnumLabel(setting, value),
      value: value,
      labelBuilder: (opt) => _getEnumLabel(setting, opt),
      dialogTitle: setting.titleKey.tr(),
      enabled: enabled,
      onChanged: enabled
          ? (newValue) => _updateSetting(
              settings,
              setting,
              newValue,
              showSnackBar: !isInline,
            )
          : null,
    );
  }

  String _getEnumLabel(EnumSetting setting, String value) {
    if (setting.useRawLabels) {
      return value;
    }

    final labelKey = setting.optionLabels?[value];
    if (labelKey != null) {
      return labelKey.tr();
    }

    return value.tr();
  }

  Widget _buildIntTile(SettingsProviders settings, IntSetting setting) {
    final value = ref.watch(settings.provider(setting));
    final enabled = _isSettingEnabled(settings, setting);
    final isInline = setting.editMode == SettingEditMode.inline;
    return IntSettingsTile.fromSetting(
      setting: setting,
      title: setting.titleKey.tr(),
      value: value,
      dialogTitle: setting.titleKey.tr(),
      enabled: enabled,
      onChanged: enabled
          ? (newValue) => _updateSetting(
              settings,
              setting,
              newValue,
              showSnackBar: !isInline,
            )
          : null,
    );
  }

  /// Build first day of week tile with formatted day name.
  Widget _buildFirstDayOfWeekTile(SettingsProviders settings) {
    final value = ref.watch(settings.provider(firstDayOfWeekSettingDef));
    final enabled = _isSettingEnabled(settings, firstDayOfWeekSettingDef);

    // Format day name: 0 = Sunday, 1 = Monday
    final dayName = value == 0 ? 'sunday'.tr() : 'monday'.tr();

    return ListTile(
      leading: Icon(firstDayOfWeekSettingDef.icon),
      title: Text(firstDayOfWeekSettingDef.titleKey.tr()),
      subtitle: Text(dayName),
      trailing: const Icon(Icons.chevron_right),
      enabled: enabled,
      onTap: enabled ? () => _showFirstDayOfWeekDialog(settings) : null,
    );
  }

  /// Show first day of week selection dialog.
  Future<void> _showFirstDayOfWeekDialog(SettingsProviders settings) async {
    final currentValue = ref.read(settings.provider(firstDayOfWeekSettingDef));

    final result = await SettingsDialog.select<int>(
      context: context,
      title: firstDayOfWeekSettingDef.titleKey.tr(),
      options: [0, 1],
      itemBuilder: (day) => Text(day == 0 ? 'sunday'.tr() : 'monday'.tr()),
      selectedValue: currentValue,
    );

    if (result != null && result != currentValue) {
      await _updateSetting(
        settings,
        firstDayOfWeekSettingDef,
        result,
        showSnackBar: true,
      );
    }
  }

  Widget _buildDoubleTile(SettingsProviders settings, DoubleSetting setting) {
    final value = ref.watch(settings.provider(setting));
    final enabled = _isSettingEnabled(settings, setting);
    return SliderSettingsTile.fromDoubleSetting(
      setting: setting,
      title: setting.titleKey.tr(),
      value: value,
      dialogTitle: setting.titleKey.tr(),
      enabled: enabled,
      onChanged: enabled
          ? (newValue) => _updateSetting(settings, setting, newValue)
          : null,
    );
  }

  Widget _buildColorTile(SettingsProviders settings, ColorSetting setting) {
    final value = ref.watch(settings.provider(setting));
    final enabled = _isSettingEnabled(settings, setting);
    return ColorSettingsTile.fromSetting(
      setting: setting,
      title: setting.titleKey.tr(),
      value: value,
      dialogTitle: setting.titleKey.tr(),
      enabled: enabled,
      onChanged: enabled
          ? (newValue) => _updateSetting(settings, setting, newValue)
          : null,
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  /// Show an undo SnackBar after a setting change.
  void _showUndoSnackBar(SettingsProviders settings, String settingName) {
    AppSnackbar.undo(
      context: context,
      message: '$settingName ${'changed'.tr()}',
      undoLabel: 'undo'.tr(),
      onUndo: () async {
        final success = await settings.undo();
        if (success && mounted) {
          AppSnackbar.success(
            context: context,
            message: 'change_undone'.tr(),
            duration: const Duration(seconds: 2),
          );
        }
      },
    );
  }

  /// Update a setting value and optionally show undo SnackBar.
  /// Set [showSnackBar] to false for inline edits to avoid spam.
  Future<void> _updateSetting<T>(
    SettingsProviders settings,
    SettingDefinition<T> setting,
    T value, {
    bool showSnackBar = true,
  }) async {
    await ref.read(settings.provider(setting).notifier).set(value);
    if (mounted && showSnackBar) {
      _showUndoSnackBar(settings, setting.titleKey.tr());
    }
  }

  Future<void> _showResetConfirmation() async {
    final confirmed = await SettingsDialog.confirm(
      context: context,
      title: 'reset_all_settings'.tr(),
      message: 'reset_all_settings_confirmation'.tr(),
      confirmText: 'reset'.tr(),
      cancelText: 'cancel'.tr(),
      isDangerous: true,
    );

    if (confirmed) {
      final settings = ref.read(adatiSettingsProvider);
      await settings.controller.resetAll();
      settings.clearUndoHistory();
      if (mounted) {
        AppSnackbar.success(
          context: context,
          message: 'settings_reset_success'.tr(),
        );
      }
    }
  }
}

// =============================================================================
// PRIVATE WIDGET CLASSES FOR DATA SECTION
// =============================================================================

/// Auto backup directory tile with file picker functionality
class _AutoBackupDirectoryTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AutoBackupDirectoryTile> createState() =>
      _AutoBackupDirectoryTileState();
}

class _AutoBackupDirectoryTileState
    extends ConsumerState<_AutoBackupDirectoryTile> {
  String? _userDirectory;

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  void _loadDirectory() {
    final settings = ref.read(adatiSettingsProvider);
    setState(() {
      _userDirectory = ref.read(
        settings.provider(autoBackupUserDirectorySettingDef),
      );
      if (_userDirectory?.isEmpty ?? true) {
        _userDirectory = null;
      }
    });
  }

  Future<void> _selectDirectory() async {
    final directory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'auto_backup_select_directory'.tr(),
    );
    if (directory != null) {
      final settings = ref.read(adatiSettingsProvider);
      await ref
          .read(settings.provider(autoBackupUserDirectorySettingDef).notifier)
          .set(directory);
      setState(() {
        _userDirectory = directory;
      });
    }
  }

  Future<void> _clearDirectory() async {
    final settings = ref.read(adatiSettingsProvider);
    await ref
        .read(settings.provider(autoBackupUserDirectorySettingDef).notifier)
        .set('');
    setState(() {
      _userDirectory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder),
      title: Text('auto_backup_directory'.tr()),
      subtitle: Text(_userDirectory ?? 'auto_backup_app_directory'.tr()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_userDirectory != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearDirectory,
              tooltip: 'clear'.tr(),
            ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _selectDirectory,
            tooltip: 'select_directory'.tr(),
          ),
        ],
      ),
    );
  }
}

/// Auto backup last backup display tile
class _AutoBackupLastBackupTile extends StatefulWidget {
  @override
  State<_AutoBackupLastBackupTile> createState() =>
      _AutoBackupLastBackupTileState();
}

class _AutoBackupLastBackupTileState extends State<_AutoBackupLastBackupTile> {
  String? _lastBackup;

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  void _loadLastBackup() {
    setState(() {
      _lastBackup = PreferencesService.getAutoBackupLastBackup();
    });
  }

  @override
  Widget build(BuildContext context) {
    String displayText;
    if (_lastBackup == null || _lastBackup!.isEmpty) {
      displayText = 'auto_backup_never'.tr();
    } else {
      try {
        final date = DateTime.parse(_lastBackup!);
        final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
        displayText = dateFormat.format(date);
      } catch (e) {
        displayText = _lastBackup!;
      }
    }

    return ListTile(
      leading: const Icon(Icons.schedule),
      title: Text('auto_backup_last_backup'.tr()),
      subtitle: Text(displayText),
      trailing: IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: _loadLastBackup,
        tooltip: 'refresh'.tr(),
      ),
    );
  }
}
