import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/habit_providers.dart';
import '../../../../core/database/app_database.dart' as db;
import 'habit_card.dart';
import 'quick_actions_widget.dart';
import 'habit_form_modal.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../settings/providers/settings_providers.dart';

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
              _buildTagFilterRow(context, ref),
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
            _buildTagFilterRow(context, ref),
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
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    final isSelected = selectedTagIds.contains(tag.id);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(tag.name),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (selected) async {
                          final newSelectedIds = Set<int>.from(selectedTagIds);
                          if (selected) {
                            newSelectedIds.add(tag.id);
                          } else {
                            newSelectedIds.remove(tag.id);
                          }
                          final tagIdsString = newSelectedIds.isEmpty
                              ? null
                              : newSelectedIds
                                    .map((id) => id.toString())
                                    .join(',');
                          await filterByTagsNotifier.setHabitFilterByTags(
                            tagIdsString,
                          );
                          ref.invalidate(habitFilterByTagsNotifierProvider);
                        },
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
              // "+" button to show all tags in popup menu
              PopupMenuButton<db.Tag>(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                tooltip: 'more_tags'.tr(),
                itemBuilder: (context) => tags.map((tag) {
                  final isSelected = selectedTagIds.contains(tag.id);
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
                }).toList(),
                onSelected: (tag) async {
                  final newSelectedIds = Set<int>.from(selectedTagIds);
                  if (selectedTagIds.contains(tag.id)) {
                    newSelectedIds.remove(tag.id);
                  } else {
                    newSelectedIds.add(tag.id);
                  }
                  final tagIdsString = newSelectedIds.isEmpty
                      ? null
                      : newSelectedIds.map((id) => id.toString()).join(',');
                  await filterByTagsNotifier.setHabitFilterByTags(tagIdsString);
                  ref.invalidate(habitFilterByTagsNotifierProvider);
                },
              ),
            ],
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
              Text('sort_by_name'.tr()),
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
              Text('sort_by_name_desc'.tr()),
              if (sortOrder == 'name_desc') ...[
                const Spacer(),
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
              Text('sort_by_streak'.tr()),
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
              Text('sort_by_streak_desc'.tr()),
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
              Text('sort_by_created'.tr()),
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
              Text('sort_by_created_desc'.tr()),
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
              Text('no_grouping'.tr()),
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
              Text('group_by_type'.tr()),
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
              Text('all_habits'.tr()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'filter_type:good',
          child: Row(
            children: [
              Icon(
                Icons.thumb_up,
                size: 20,
                color: filterByType == 'good'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text('good_habits_only'.tr()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'filter_type:bad',
          child: Row(
            children: [
              Icon(
                Icons.thumb_down,
                size: 20,
                color: filterByType == 'bad'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text('bad_habits_only'.tr()),
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
          }
        });
      },
      itemBuilder: (context) => [
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
              Text('list_view'.tr()),
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
              Text('grid_view'.tr()),
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
              Text(
                (sessionOptions.showTags ?? _showTags)
                    ? 'hide_tags'.tr()
                    : 'show_tags'.tr(),
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
              Text(
                (sessionOptions.showDescriptions ?? _showDescriptions)
                    ? 'hide_descriptions'.tr()
                    : 'show_descriptions'.tr(),
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
              Text(
                (sessionOptions.compactCards ?? _compactCards)
                    ? 'normal_cards'.tr()
                    : 'compact_cards'.tr(),
              ),
            ],
          ),
        ),
      ],
    );
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
