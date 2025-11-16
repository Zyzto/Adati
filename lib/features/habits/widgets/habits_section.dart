import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/habit_providers.dart';
import '../../../../core/database/app_database.dart' as db;
import 'habit_card.dart';
import 'quick_actions.dart';
import 'habit_form_modal.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../settings/providers/settings_providers.dart';

// Filter type constants
const String _filterTypeGood = 'good';
const String _filterTypeBad = 'bad';

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
  String _cardLayout = 'list'; // 'list' or 'grid'
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
    // Show search if there's an active query
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filterQuery = ref.read(habitFilterQueryProvider);
      if (filterQuery != null && filterQuery.isNotEmpty) {
        _searchController.text = filterQuery;
        setState(() {
          _showSearch = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(filteredSortedHabitsProvider);
    final filterQuery = ref.watch(habitFilterQueryProvider);

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

    // Sync controller when filter is cleared externally (e.g., when hiding search)
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
              _buildHeader(context, ref),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, -0.3),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _showSearch
                    ? _buildSearchBar(context, ref)
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
              if (_showTagFilter) _buildTagFilterRow(context, ref),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, -0.3),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _showQuickActions
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
            _buildHeader(context, ref),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, -0.3),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _showSearch
                  ? _buildSearchBar(context, ref)
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
            if (_showTagFilter) _buildTagFilterRow(context, ref),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, -0.3),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _showQuickActions
                  ? const QuickActionsWidget(key: ValueKey('quick_actions'))
                  : const SizedBox.shrink(key: ValueKey('empty_qa')),
            ),
            _buildHabitsList(context, ref, habits),
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

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'habits'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortButton(context, ref),
              const SizedBox(width: 8),
              _buildViewOptionsButton(context, ref),
              const SizedBox(width: 8),
              _buildQuickActionsToggle(context),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_showSearch ? Icons.search_off : Icons.search),
                onPressed: () async {
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
                },
                tooltip: _showSearch ? 'hide_search'.tr() : 'search'.tr(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => HabitFormModal.show(context),
                tooltip: 'add_habit'.tr(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    final filterQuery = ref.watch(habitFilterQueryProvider);
    final notifier = ref.read(habitFilterQueryNotifierProvider);

    return Padding(
      key: const ValueKey('search'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        autofocus: _showSearch,
        onChanged: (value) {
          notifier.setHabitFilterQuery(value.isEmpty ? null : value);
          ref.invalidate(habitFilterQueryNotifierProvider);
        },
        decoration: InputDecoration(
          hintText: 'search_habits'.tr(),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: filterQuery != null && filterQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () async {
                    await notifier.setHabitFilterQuery(null);
                    ref.invalidate(habitFilterQueryNotifierProvider);
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }

  Widget _buildTagFilterRow(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);
    final filterByTags = ref.watch(habitFilterByTagsProvider);
    final filterByTagsNotifier = ref.read(habitFilterByTagsNotifierProvider);
    final selectedTagIds = filterByTags != null && filterByTags.isNotEmpty
        ? filterByTags
              .split(',')
              .map((id) => int.tryParse(id))
              .whereType<int>()
              .toSet()
        : <int>{};

    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 40,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate available width (accounting for "+" button if needed)
              const buttonWidth = 40.0; // Width of the "+" button
              final availableWidth = constraints.maxWidth;

              // Build tags and measure their widths to determine overflow
              return _TagOverflowDetector(
                tags: tags,
                selectedTagIds: selectedTagIds,
                filterByTagsNotifier: filterByTagsNotifier,
                availableWidth: availableWidth,
                buttonWidth: buttonWidth,
                onTagsChanged: () {
                  ref.invalidate(habitFilterByTagsNotifierProvider);
                },
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildSortButton(BuildContext context, WidgetRef ref) {
    final sortOrder = ref.watch(habitSortOrderProvider);
    final notifier = ref.read(habitSortOrderNotifierProvider);
    final groupBy = ref.watch(habitGroupByProvider);
    final filterByType = ref.watch(habitFilterByTypeProvider);
    final groupByNotifier = ref.read(habitGroupByNotifierProvider);
    final filterByTypeNotifier = ref.read(habitFilterByTypeNotifierProvider);

    IconData icon;
    String tooltip;
    switch (sortOrder) {
      case 'name':
        icon = Icons.sort_by_alpha;
        tooltip = 'sort_by_name'.tr();
        break;
      case 'name_desc':
        icon = Icons.sort_by_alpha;
        tooltip = 'sort_by_name_desc'.tr();
        break;
      case 'streak':
      case 'streak_desc':
        icon = Icons.local_fire_department;
        tooltip = 'sort_by_streak'.tr();
        break;
      case 'created':
        icon = Icons.access_time;
        tooltip = 'sort_by_created'.tr();
        break;
      case 'created_desc':
        icon = Icons.access_time;
        tooltip = 'sort_by_created_desc'.tr();
        break;
      default:
        icon = Icons.sort;
        tooltip = 'sort'.tr();
    }

    return PopupMenuButton<String>(
      icon: Icon(icon),
      tooltip: tooltip,
      onSelected: (value) async {
        if (value.startsWith('sort:')) {
          await notifier.setHabitSortOrder(value.substring(5));
          ref.invalidate(habitSortOrderNotifierProvider);
        } else if (value.startsWith('group:')) {
          final groupValue = value.substring(6);
          await groupByNotifier.setHabitGroupBy(
            groupValue.isEmpty ? null : groupValue,
          );
          ref.invalidate(habitGroupByNotifierProvider);
        } else if (value.startsWith('filter_type:')) {
          final filterValue = value.substring(12);
          await filterByTypeNotifier.setHabitFilterByType(
            filterValue.isEmpty ? null : filterValue,
          );
          ref.invalidate(habitFilterByTypeNotifierProvider);
        }
      },
      itemBuilder: (context) => [
        // Sort Options
        PopupMenuItem(
          value: 'sort:name',
          child: Row(
            children: [
              Icon(
                Icons.sort_by_alpha,
                size: 20,
                color: sortOrder == 'name'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('sort_by_name'.tr())),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'sort:name_desc',
          child: Row(
            children: [
              Icon(
                Icons.sort_by_alpha,
                size: 20,
                color: sortOrder == 'name_desc'
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('sort_by_name_desc'.tr())),
              if (sortOrder == 'name_desc') ...[
                const SizedBox(width: 8),
                const Icon(Icons.check, size: 16),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: 'sort:streak',
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 20,
                color: sortOrder == 'streak'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('sort_by_streak'.tr())),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'sort:streak_desc',
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 20,
                color: sortOrder == 'streak_desc'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('sort_by_streak_desc'.tr())),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'sort:created',
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 20,
                color: sortOrder == 'created'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('sort_by_created'.tr())),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'sort:created_desc',
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 20,
                color: sortOrder == 'created_desc'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('sort_by_created_desc'.tr())),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Group Options
        PopupMenuItem(
          value: 'group:',
          child: Row(
            children: [
              Icon(
                Icons.view_list,
                size: 20,
                color: groupBy == null || groupBy.isEmpty
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('no_grouping'.tr())),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'group:type',
          child: Row(
            children: [
              Icon(
                Icons.category,
                size: 20,
                color: groupBy == 'type'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('group_by_type'.tr())),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Filter Options
        PopupMenuItem(
          value: 'filter_type:',
          child: Row(
            children: [
              Icon(
                Icons.filter_alt_off,
                size: 20,
                color: filterByType == null || filterByType.isEmpty
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('all_habits'.tr())),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'filter_type:$_filterTypeGood',
          child: Row(
            children: [
              Icon(
                Icons.thumb_up,
                size: 20,
                color: filterByType == _filterTypeGood
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('good_habits_only'.tr())),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'filter_type:$_filterTypeBad',
          child: Row(
            children: [
              Icon(
                Icons.thumb_down,
                size: 20,
                color: filterByType == _filterTypeBad
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('bad_habits_only'.tr())),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHabitsList(BuildContext context, WidgetRef ref, List habits) {
    final groupBy = ref.watch(habitGroupByProvider);

    if (groupBy == 'type') {
      // Group by type
      final goodHabits = habits.where((h) => h.habitType == 0).toList();
      final badHabits = habits.where((h) => h.habitType == 1).toList();

      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if (goodHabits.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'good_habits'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            ...goodHabits.map((habit) => HabitCard(habit: habit)),
          ],
          if (badHabits.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'bad_habits'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            ...badHabits.map((habit) => HabitCard(habit: habit)),
          ],
        ],
      );
    }

    // No grouping - regular list or grid
    if (_cardLayout == 'grid') {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: habits.length,
        itemBuilder: (context, index) {
          return HabitCard(habit: habits[index]);
        },
      );
    }

    // List view
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        return HabitCard(habit: habits[index]);
      },
    );
  }

  Widget _buildViewOptionsButton(BuildContext context, WidgetRef ref) {
    final sessionOptions = ref.watch(sessionViewOptionsProvider);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.tune),
      tooltip: 'view_options'.tr(),
      onSelected: (value) {
        setState(() {
          switch (value) {
            case 'layout_list':
              _cardLayout = 'list';
              break;
            case 'layout_grid':
              _cardLayout = 'grid';
              break;
            case 'toggle_tags':
              _showTags = !_showTags;
              updateSessionViewOptions(
                ref,
                sessionOptions.copyWith(showTags: _showTags),
              );
              break;
            case 'toggle_descriptions':
              _showDescriptions = !_showDescriptions;
              updateSessionViewOptions(
                ref,
                sessionOptions.copyWith(showDescriptions: _showDescriptions),
              );
              break;
            case 'toggle_compact':
              _compactCards = !_compactCards;
              updateSessionViewOptions(
                ref,
                sessionOptions.copyWith(compactCards: _compactCards),
              );
              break;
            case 'toggle_tag_filter':
              _showTagFilter = !_showTagFilter;
              break;
          }
        });
      },
      itemBuilder: (context) =>
          _buildViewOptionsMenuItems(context, sessionOptions),
    );
  }

  List<PopupMenuEntry<String>> _buildViewOptionsMenuItems(
    BuildContext context,
    dynamic sessionOptions,
  ) {
    return [
      PopupMenuItem(
        value: 'layout_list',
        child: Row(
          children: [
            Icon(
              Icons.view_list,
              size: 20,
              color: _cardLayout == 'list'
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('list_view'.tr())),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'layout_grid',
        child: Row(
          children: [
            Icon(
              Icons.grid_view,
              size: 20,
              color: _cardLayout == 'grid'
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('grid_view'.tr())),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'toggle_tags',
        child: Row(
          children: [
            Icon(
              Icons.label,
              size: 20,
              color: (sessionOptions.showTags ?? _showTags)
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                (sessionOptions.showTags ?? _showTags)
                    ? 'hide_tags'.tr()
                    : 'show_tags'.tr(),
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'toggle_descriptions',
        child: Row(
          children: [
            Icon(
              Icons.description,
              size: 20,
              color: (sessionOptions.showDescriptions ?? _showDescriptions)
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                (sessionOptions.showDescriptions ?? _showDescriptions)
                    ? 'hide_descriptions'.tr()
                    : 'show_descriptions'.tr(),
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'toggle_compact',
        child: Row(
          children: [
            Icon(
              Icons.view_compact,
              size: 20,
              color: (sessionOptions.compactCards ?? _compactCards)
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                (sessionOptions.compactCards ?? _compactCards)
                    ? 'normal_cards'.tr()
                    : 'compact_cards'.tr(),
              ),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'toggle_tag_filter',
        child: Row(
          children: [
            Icon(
              Icons.filter_alt,
              size: 20,
              color: _showTagFilter
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _showTagFilter
                    ? 'hide_tag_filter'.tr()
                    : 'show_tag_filter'.tr(),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildQuickActionsToggle(BuildContext context) {
    return IconButton(
      icon: Icon(_showQuickActions ? Icons.flash_off : Icons.flash_on),
      tooltip: _showQuickActions
          ? 'hide_quick_actions'.tr()
          : 'show_quick_actions'.tr(),
      onPressed: () {
        setState(() {
          _showQuickActions = !_showQuickActions;
        });
      },
    );
  }
}

/// Widget that detects tag overflow and shows only visible tags with a "+" button for overflowed ones
class _TagOverflowDetector extends StatefulWidget {
  final List<db.Tag> tags;
  final Set<int> selectedTagIds;
  final dynamic filterByTagsNotifier;
  final double availableWidth;
  final double buttonWidth;
  final VoidCallback onTagsChanged;

  const _TagOverflowDetector({
    required this.tags,
    required this.selectedTagIds,
    required this.filterByTagsNotifier,
    required this.availableWidth,
    required this.buttonWidth,
    required this.onTagsChanged,
  });

  @override
  State<_TagOverflowDetector> createState() => _TagOverflowDetectorState();
}

class _TagOverflowDetectorState extends State<_TagOverflowDetector> {
  final GlobalKey _rowKey = GlobalKey();
  bool _hasOverflow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverflow();
    });
  }

  @override
  void didUpdateWidget(_TagOverflowDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tags.length != widget.tags.length ||
        oldWidget.availableWidth != widget.availableWidth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkOverflow();
      });
    }
  }

  void _checkOverflow() {
    if (!mounted || _rowKey.currentContext == null) return;

    final RenderBox? renderBox =
        _rowKey.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final rowWidth = renderBox.size.width;
    final availableWidthForTags = widget.availableWidth - widget.buttonWidth;
    final hasOverflow = rowWidth > availableWidthForTags;

    if (mounted) {
      setState(() {
        _hasOverflow = hasOverflow;
      });
    }
  }

  Widget _buildTagChip(db.Tag tag, bool isSelected, {bool isDisabled = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(tag.name, maxLines: 1),
        selected: isSelected,
        showCheckmark: false,
        onSelected: isDisabled
            ? null
            : (selected) async {
                final newSelectedIds = Set<int>.from(widget.selectedTagIds);
                if (selected) {
                  newSelectedIds.add(tag.id);
                } else {
                  newSelectedIds.remove(tag.id);
                }
                final tagIdsString = newSelectedIds.isEmpty
                    ? null
                    : newSelectedIds.map((id) => id.toString()).join(',');
                await widget.filterByTagsNotifier.setHabitFilterByTags(
                  tagIdsString,
                );
                widget.onTagsChanged();
              },
        selectedColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.15),
        checkmarkColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildPlusButton() {
    return PopupMenuButton<db.Tag>(
      tooltip: 'more_tags'.tr(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, size: 18),
      ),
      itemBuilder: (context) {
        if (widget.tags.isEmpty) {
          return [
            PopupMenuItem<db.Tag>(
              enabled: false,
              child: Text('no_more_tags'.tr()),
            ),
          ];
        }

        // Calculate which tags are visible and show only overflowed (hidden) ones
        final availableWidthForTags =
            widget.availableWidth - widget.buttonWidth - 8; // 8 for padding
        List<db.Tag> overflowedTags = [];

        if (_rowKey.currentContext != null) {
          final RenderBox? renderBox =
              _rowKey.currentContext!.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final rowWidth = renderBox.size.width;
            if (rowWidth > availableWidthForTags && widget.tags.isNotEmpty) {
              // Estimate how many tags fit in available width
              // Each tag has padding (8px right) + chip width
              // Rough estimate: average tag width based on total width
              final averageTagWidth = rowWidth / widget.tags.length;
              final estimatedVisibleCount =
                  (availableWidthForTags / averageTagWidth).floor().clamp(
                    0,
                    widget.tags.length,
                  );

              // The last tag is disabled (partially visible, fading)
              // So visible tags are from 0 to (estimatedVisibleCount - 1)
              // The last tag (at length - 1) is the one that's fading/overflowing
              // We want to show all tags that are not fully visible, including the last one

              // Show tags starting from the estimated visible count
              // This includes the last tag which is fading
              final overflowStartIndex = estimatedVisibleCount.clamp(
                0,
                widget.tags.length,
              );

              if (overflowStartIndex < widget.tags.length) {
                // Show all tags from overflowStartIndex onwards (including the last tag)
                // But exclude the tag before the last one
                final allOverflowed = widget.tags.sublist(overflowStartIndex);
                if (allOverflowed.length > 1) {
                  // Remove the second-to-last tag (the one before the last)
                  overflowedTags = [
                    ...allOverflowed.take(allOverflowed.length - 2),
                    allOverflowed.last, // Keep the last tag (fading)
                  ];
                } else {
                  // If only one or zero tags, just use what we have
                  overflowedTags = allOverflowed;
                }
              }
            }
          }
        }

        // Fallback: if we couldn't calculate and there's overflow,
        // show the last tag (which is the one that's fading/overflowing)
        if (overflowedTags.isEmpty && _hasOverflow && widget.tags.isNotEmpty) {
          // Show the last tag since it's the one that's overflowing
          overflowedTags = [widget.tags.last];
        }

        if (overflowedTags.isEmpty) {
          return [
            PopupMenuItem<db.Tag>(
              enabled: false,
              child: Text('no_more_tags'.tr()),
            ),
          ];
        }

        return overflowedTags.map((tag) {
          final isSelected = widget.selectedTagIds.contains(tag.id);
          return PopupMenuItem<db.Tag>(
            value: tag,
            child: Row(
              children: [
                Checkbox(value: isSelected, onChanged: null),
                const SizedBox(width: 8),
                Expanded(child: Text(tag.name)),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (tag) async {
        final newSelectedIds = Set<int>.from(widget.selectedTagIds);
        if (widget.selectedTagIds.contains(tag.id)) {
          newSelectedIds.remove(tag.id);
        } else {
          newSelectedIds.add(tag.id);
        }
        final tagIdsString = newSelectedIds.isEmpty
            ? null
            : newSelectedIds.map((id) => id.toString()).join(',');
        await widget.filterByTagsNotifier.setHabitFilterByTags(tagIdsString);
        widget.onTagsChanged();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the width available for tags (excluding button and padding)
        const buttonPadding = 8.0;
        final availableWidthForTags = _hasOverflow
            ? constraints.maxWidth - widget.buttonWidth - buttonPadding
            : constraints.maxWidth;

        // Get text direction for RTL support
        // Check locale to determine if RTL (Arabic, Hebrew, etc.)
        final locale = context.locale;
        final isRTL =
            locale.languageCode == 'ar' ||
            locale.languageCode == 'he' ||
            locale.languageCode == 'fa';

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Clip tags to available width and apply fade
            ClipRect(
              child: SizedBox(
                width: availableWidthForTags,
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    // Fade from 80% to 100% of the available width
                    // This creates a smooth fade starting before the edge
                    // Respect RTL layout - fade should occur at the edge where button is
                    if (isRTL) {
                      // RTL: Button is on left, fade from right (opaque) to left (transparent at button)
                      return LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.white.withValues(
                            alpha: 0.0,
                          ), // Fully transparent at left edge (button side)
                        ],
                        stops: const [
                          0.0,
                          0.8,
                          1.0,
                        ], // Fade in the last 20% (from left)
                      ).createShader(bounds);
                    } else {
                      // LTR: Button is on right, fade from left (opaque) to right (transparent at button)
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.white.withValues(
                            alpha: 0.0,
                          ), // Fully transparent at right edge (button side)
                        ],
                        stops: const [
                          0.0,
                          0.8,
                          1.0,
                        ], // Fade in the last 20% (from right)
                      ).createShader(bounds);
                    }
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    // Use NeverScrollableScrollPhysics to prevent scrolling but keep fade effect
                    physics: const NeverScrollableScrollPhysics(),
                    child: IntrinsicWidth(
                      // Ensures the Row takes only the space its children need
                      child: Row(
                        key: _rowKey,
                        mainAxisSize:
                            MainAxisSize.min, // Essential for IntrinsicWidth
                        children: widget.tags.asMap().entries.map((entry) {
                          final index = entry.key;
                          final tag = entry.value;
                          final isSelected = widget.selectedTagIds.contains(
                            tag.id,
                          );
                          // Disable the last tag in the list if there's overflow
                          final isLastTag = index == widget.tags.length - 1;
                          final isDisabled = _hasOverflow && isLastTag;
                          return _buildTagChip(
                            tag,
                            isSelected,
                            isDisabled: isDisabled,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // "+" button positioned at the end (right in LTR, left in RTL) when there's overflow
            if (_hasOverflow)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildPlusButton(),
                ),
              ),
          ],
        );
      },
    );
  }
}
