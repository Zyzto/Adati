import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/habit_providers.dart';
import '../../../settings/providers/settings_providers.dart';
import '../cards/quick_actions.dart';
import '../../../../../core/widgets/empty_state_widget.dart';
import 'habits_section_header.dart';
import '../filters/habits_search_bar.dart';
import '../filters/habits_tag_filter/habits_tag_filter.dart';
import 'habits_list_view.dart';

class HabitsSection extends ConsumerStatefulWidget {
  const HabitsSection({super.key});

  @override
  ConsumerState<HabitsSection> createState() => _HabitsSectionState();
}

class _HabitsSectionState extends ConsumerState<HabitsSection> {
  bool _showSearch = false;
  bool _showQuickActions = false;
  final TextEditingController _searchController = TextEditingController();
  // View options (session-based)
  String? _cardLayout; // null means use provider value
  bool _showTags = true;
  bool _showDescriptions = true;
  bool _compactCards = false;
  bool _showTagFilter = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize card layout from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cardLayout = ref.read(habitsLayoutModeProvider);
      // Show search if there's an active query
      final filterQuery = ref.read(habitFilterQueryProvider);
      if (filterQuery != null && filterQuery.isNotEmpty) {
        _searchController.text = filterQuery;
        setState(() {
          _showSearch = true;
        });
      }
    });
  }

  Widget _buildAnimatedSwitcher(Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: child,
    );
  }

  void _handleSearchToggle() async {
    setState(() {
      _showSearch = !_showSearch;
    });
    if (!_showSearch) {
      // Clear search when hiding
      final notifier = ref.read(habitFilterQueryNotifierProvider);
      await notifier.setHabitFilterQuery(null);
      ref.invalidate(habitFilterQueryNotifierProvider);
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(filteredSortedHabitsProvider);
    final filterQuery = ref.watch(habitFilterQueryProvider);
    // Watch the layout mode provider so it updates when changed in settings
    final providerCardLayout = ref.watch(habitsLayoutModeProvider);
    
    // Listen for provider changes and sync local state (e.g., when changed from settings page)
    ref.listen<String>(habitsLayoutModeProvider, (previous, next) {
      if (previous != next && _cardLayout != next) {
        setState(() {
          _cardLayout = next;
        });
      }
    });
    
    // Use local state if set (for immediate updates), otherwise use provider value
    final cardLayout = _cardLayout ?? providerCardLayout;

    // Auto-show search if there's an active query
    if (filterQuery != null && filterQuery.isNotEmpty && !_showSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchController.text = filterQuery;
          setState(() {
            _showSearch = true;
          });
        }
      });
    }

    // Sync controller when filter is cleared externally
    if (filterQuery == null && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    return habitsAsync.when(
      data: (habits) {
        // Only show empty state for filtered results (when search has no matches)
        if (habits.isEmpty && (filterQuery != null && filterQuery.isNotEmpty)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HabitsSectionHeader(
                showSearch: _showSearch,
                onSearchToggle: _handleSearchToggle,
                showQuickActions: _showQuickActions,
                onQuickActionsToggle: () =>
                    setState(() => _showQuickActions = !_showQuickActions),
                cardLayout: cardLayout,
                showTags: _showTags,
                showDescriptions: _showDescriptions,
                compactCards: _compactCards,
                showTagFilter: _showTagFilter,
                onCardLayoutChanged: (value) {
                  // Update UI immediately
                  setState(() {
                    _cardLayout = value;
                  });
                  // Persist in background
                  final notifier = ref.read(habitsLayoutModeNotifierProvider);
                  notifier.setHabitsLayoutMode(value).then(
                    (_) => ref.invalidate(habitsLayoutModeNotifierProvider),
                  );
                },
                onShowTagsChanged: (value) => setState(() => _showTags = value),
                onShowDescriptionsChanged: (value) =>
                    setState(() => _showDescriptions = value),
                onCompactCardsChanged: (value) =>
                    setState(() => _compactCards = value),
                onShowTagFilterChanged: (value) =>
                    setState(() => _showTagFilter = value),
              ),
              _buildAnimatedSwitcher(
                _showSearch
                    ? HabitsSearchBar(
                        controller: _searchController,
                        autofocus: _showSearch,
                        key: const ValueKey('search'),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
              if (_showTagFilter) const HabitsTagFilter(),
              _buildAnimatedSwitcher(
                _showQuickActions
                    ? const QuickActionsWidget(key: ValueKey('quick_actions'))
                    : const SizedBox.shrink(key: ValueKey('empty_qa')),
              ),
              const SizedBox(height: 24),
              EmptyStateWidget(
                icon: Icons.search_off,
                title: 'no_results'.tr(),
                message: 'no_habits_match_search'.tr(),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HabitsSectionHeader(
              showSearch: _showSearch,
              onSearchToggle: _handleSearchToggle,
              showQuickActions: _showQuickActions,
              onQuickActionsToggle: () =>
                  setState(() => _showQuickActions = !_showQuickActions),
              cardLayout: cardLayout,
              showTags: _showTags,
              showDescriptions: _showDescriptions,
              compactCards: _compactCards,
              showTagFilter: _showTagFilter,
              onCardLayoutChanged: (value) {
                // Update UI immediately
                setState(() {
                  _cardLayout = value;
                });
                // Persist in background
                final notifier = ref.read(habitsLayoutModeNotifierProvider);
                notifier.setHabitsLayoutMode(value).then(
                  (_) => ref.invalidate(habitsLayoutModeNotifierProvider),
                );
              },
              onShowTagsChanged: (value) => setState(() => _showTags = value),
              onShowDescriptionsChanged: (value) =>
                  setState(() => _showDescriptions = value),
              onCompactCardsChanged: (value) =>
                  setState(() => _compactCards = value),
              onShowTagFilterChanged: (value) =>
                  setState(() => _showTagFilter = value),
            ),
            _buildAnimatedSwitcher(
              _showSearch
                  ? HabitsSearchBar(
                      controller: _searchController,
                      autofocus: _showSearch,
                      key: const ValueKey('search'),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
            if (_showTagFilter) const HabitsTagFilter(),
            _buildAnimatedSwitcher(
              _showQuickActions
                  ? const QuickActionsWidget(key: ValueKey('quick_actions'))
                  : const SizedBox.shrink(key: ValueKey('empty_qa')),
            ),
            HabitsListView(habits: habits, cardLayout: cardLayout),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text('${'error'.tr()}: $error')),
      ),
    );
  }
}
