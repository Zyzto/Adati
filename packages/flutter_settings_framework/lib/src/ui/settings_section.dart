/// Flutter Settings Framework
/// Settings section and page components.
///
/// These components provide the structure for organizing settings
/// into collapsible sections with search filtering.
library;

import 'package:flutter/material.dart';
import '../core/setting_definition.dart';
import '../core/search_index.dart';

/// Collapsible settings section.
///
/// Wraps a group of related settings in an expandable panel.
class SettingsSectionWidget extends StatelessWidget {
  /// Section title.
  final String title;

  /// Section icon.
  final IconData? icon;

  /// Whether the section is initially expanded.
  final bool initiallyExpanded;

  /// Whether the section is currently expanded.
  final bool? isExpanded;

  /// Callback when expansion state changes.
  final ValueChanged<bool>? onExpansionChanged;

  /// Child widgets (setting tiles).
  final List<Widget> children;

  /// Whether the section should be visible.
  final bool visible;

  const SettingsSectionWidget({
    super.key,
    required this.title,
    this.icon,
    this.initiallyExpanded = false,
    this.isExpanded,
    this.onExpansionChanged,
    required this.children,
    this.visible = true,
  });

  /// Create from a [SettingSection] definition.
  factory SettingsSectionWidget.fromDefinition({
    Key? key,
    required SettingSection section,
    required String title,
    bool? isExpanded,
    ValueChanged<bool>? onExpansionChanged,
    required List<Widget> children,
    bool visible = true,
  }) {
    return SettingsSectionWidget(
      key: key,
      title: title,
      icon: section.icon,
      initiallyExpanded: section.initiallyExpanded,
      isExpanded: isExpanded,
      onExpansionChanged: onExpansionChanged,
      visible: visible,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!visible || children.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpansionTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      initiallyExpanded: isExpanded ?? initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      children: children,
    );
  }
}

/// Sub-section header within a settings section.
class SettingsSubsectionHeader extends StatelessWidget {
  /// Sub-section title.
  final String title;

  /// Sub-section icon.
  final IconData? icon;

  const SettingsSubsectionHeader({
    super.key,
    required this.title,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Search bar for settings.
class SettingsSearchBar extends StatefulWidget {
  /// Placeholder text.
  final String hintText;

  /// Callback when search query changes.
  final ValueChanged<String>? onChanged;

  /// Callback when search is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Whether search is currently expanded.
  final bool isExpanded;

  /// Callback when expansion state changes.
  final ValueChanged<bool>? onExpandedChanged;

  /// Initial search query.
  final String? initialQuery;

  const SettingsSearchBar({
    super.key,
    this.hintText = 'Search settings...',
    this.onChanged,
    this.onSubmitted,
    this.isExpanded = false,
    this.onExpandedChanged,
    this.initialQuery,
  });

  @override
  State<SettingsSearchBar> createState() => _SettingsSearchBarState();
}

class _SettingsSearchBarState extends State<SettingsSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();
    _isExpanded = widget.isExpanded;

    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _controller.text.isEmpty && _isExpanded) {
      _collapse();
    }
  }

  void _expand() {
    setState(() => _isExpanded = true);
    widget.onExpandedChanged?.call(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _collapse() {
    setState(() => _isExpanded = false);
    widget.onExpandedChanged?.call(false);
    _focusNode.unfocus();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    _collapse();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return IconButton(
        icon: const Icon(Icons.search),
        onPressed: _expand,
        tooltip: widget.hintText,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 300,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clear,
                )
              : null,
          hintText: widget.hintText,
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
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onTapOutside: (_) {
          if (_controller.text.isEmpty) {
            _collapse();
          }
        },
      ),
    );
  }
}

/// Settings page scaffold with search and sections.
class SettingsPageScaffold extends StatefulWidget {
  /// Page title.
  final String title;

  /// Settings sections.
  final List<Widget> sections;

  /// Whether to show search bar.
  final bool showSearch;

  /// Search hint text.
  final String searchHint;

  /// Search callback.
  final ValueChanged<String>? onSearch;

  /// Current search query.
  final String searchQuery;

  /// Additional actions for the app bar.
  final List<Widget>? actions;

  const SettingsPageScaffold({
    super.key,
    required this.title,
    required this.sections,
    this.showSearch = true,
    this.searchHint = 'Search settings...',
    this.onSearch,
    this.searchQuery = '',
    this.actions,
  });

  @override
  State<SettingsPageScaffold> createState() => _SettingsPageScaffoldState();
}

class _SettingsPageScaffoldState extends State<SettingsPageScaffold> {
  bool _isSearchExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.showSearch)
            SettingsSearchBar(
              hintText: widget.searchHint,
              isExpanded: _isSearchExpanded,
              initialQuery: widget.searchQuery,
              onExpandedChanged: (expanded) {
                setState(() => _isSearchExpanded = expanded);
              },
              onChanged: widget.onSearch,
            ),
          ...?widget.actions,
        ],
      ),
      body: ListView(
        children: widget.sections,
      ),
    );
  }
}

/// Filter widget children based on search query.
///
/// Returns a list of widgets that match the search query.
/// Widgets are matched against their text content.
List<Widget> filterWidgetsBySearch(
  List<Widget> widgets,
  String query, {
  String? sectionTitle,
}) {
  if (query.isEmpty) return widgets;

  final normalizedQuery = query.toLowerCase();

  // If section title matches, return all widgets
  if (sectionTitle != null &&
      sectionTitle.toLowerCase().contains(normalizedQuery)) {
    return widgets;
  }

  bool matchesQuery(String? text) {
    return text?.toLowerCase().contains(normalizedQuery) ?? false;
  }

  String? extractText(Widget? widget) {
    if (widget is Text) return widget.data;
    return null;
  }

  bool widgetMatches(Widget widget) {
    if (widget is ListTile) {
      return matchesQuery(extractText(widget.title)) ||
          matchesQuery(extractText(widget.subtitle));
    }
    if (widget is SwitchListTile) {
      return matchesQuery(extractText(widget.title)) ||
          matchesQuery(extractText(widget.subtitle));
    }
    return false;
  }

  return widgets.where(widgetMatches).toList();
}

/// Build settings widgets from search results.
///
/// Groups results by section and returns a list of section widgets.
List<Widget> buildSearchResultWidgets(
  List<SearchResult> results, {
  required Widget Function(SettingDefinition setting) tileBuilder,
  required String Function(String sectionKey) sectionTitleBuilder,
}) {
  if (results.isEmpty) return [];

  // Group by section
  final grouped = <String, List<SearchResult>>{};
  for (final result in results) {
    final section = result.setting.section ?? '';
    grouped.putIfAbsent(section, () => []).add(result);
  }

  // Build widgets
  final widgets = <Widget>[];
  for (final entry in grouped.entries) {
    if (entry.key.isNotEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            sectionTitleBuilder(entry.key),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
    for (final result in entry.value) {
      widgets.add(tileBuilder(result.setting));
    }
  }

  return widgets;
}

/// Card-based settings section with custom styling.
///
/// A polished settings section that uses a Card container with:
/// - Rounded corners and customizable border
/// - Icon container with primary color background
/// - Selection state for landscape split-screen mode
/// - AnimatedSize for smooth expansion
/// - Different behavior for landscape vs portrait
class CardSettingsSection extends StatelessWidget {
  /// Section title.
  final String title;

  /// Section icon.
  final IconData icon;

  /// Child widgets (setting tiles).
  final List<Widget> children;

  /// Whether the section is currently expanded (portrait mode only).
  final bool isExpanded;

  /// Callback when expansion state changes.
  final ValueChanged<bool>? onExpansionChanged;

  /// Unique identifier for this section.
  final String sectionId;

  /// Whether this section is currently selected (landscape mode).
  final bool isSelected;

  /// Whether the screen is in landscape mode.
  final bool isLandscape;

  /// Callback when section is tapped in landscape mode.
  /// Should show section content in detail pane.
  final VoidCallback? onLandscapeTap;

  /// Card margin.
  final EdgeInsets margin;

  /// Card border radius.
  final double borderRadius;

  const CardSettingsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.isExpanded = false,
    this.onExpansionChanged,
    required this.sectionId,
    this.isSelected = false,
    this.isLandscape = false,
    this.onLandscapeTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: margin,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
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
                onLandscapeTap?.call();
              } else {
                onExpansionChanged?.call(!isExpanded);
              }
            },
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(borderRadius),
            ),
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
}

/// Empty search results widget.
class EmptySearchResults extends StatelessWidget {
  /// Search query that yielded no results.
  final String query;

  /// Message to display.
  final String? message;

  const EmptySearchResults({
    super.key,
    required this.query,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'No settings found for "$query"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

