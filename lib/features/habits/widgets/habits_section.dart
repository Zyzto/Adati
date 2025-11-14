import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/habit_providers.dart';
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
        final allHabitsAsync = ref.watch(habitsProvider);
        final hasHabits = allHabitsAsync.maybeWhen(
          data: (allHabits) => allHabits.isNotEmpty,
          orElse: () => false,
        );

        if (!hasHabits) {
          return EmptyStateWidget(
            icon: Icons.check_circle_outline,
            title: 'no_habits'.tr(),
            message: 'create_first_habit'.tr(),
            action: ElevatedButton.icon(
              onPressed: () => HabitFormModal.show(context),
              icon: const Icon(Icons.add),
              label: Text('create_habit'.tr()),
            ),
          );
        }

        if (habits.isEmpty && (filterQuery != null && filterQuery.isNotEmpty)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ref),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: _showSearch
                    ? _buildSearchBar(context, ref)
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
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
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _showSearch
                  ? _buildSearchBar(context, ref)
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _showQuickActions
                  ? const QuickActionsWidget(key: ValueKey('quick_actions'))
                  : const SizedBox.shrink(key: ValueKey('empty_qa')),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                return HabitCard(habit: habits[index]);
              },
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text('${'error'.tr()}: $error'),
        ),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortButton(context, ref),
              const SizedBox(width: 8),
              _buildQuickActionsToggle(context),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_showSearch ? Icons.search_off : Icons.search),
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      // Clear search when hiding
                      ref.read(habitFilterQueryNotifierProvider).setHabitFilterQuery(null);
                    }
                  });
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
        },
        decoration: InputDecoration(
          hintText: 'search_habits'.tr(),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: filterQuery != null && filterQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    notifier.setHabitFilterQuery(null);
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }

  Widget _buildSortButton(BuildContext context, WidgetRef ref) {
    final sortOrder = ref.watch(habitSortOrderProvider);
    final notifier = ref.read(habitSortOrderNotifierProvider);

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
      onSelected: (value) {
        notifier.setHabitSortOrder(value);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'name',
          child: Row(
            children: [
              Icon(
                Icons.sort_by_alpha,
                size: 20,
                color: sortOrder == 'name'
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              const SizedBox(width: 12),
              Text('sort_by_name'.tr()),
              if (sortOrder == 'name') ...[
                const Spacer(),
                const Icon(Icons.check, size: 16),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: 'name_desc',
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
          value: 'created',
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 20,
                color: sortOrder == 'created'
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              const SizedBox(width: 12),
              Text('sort_by_created'.tr()),
              if (sortOrder == 'created') ...[
                const Spacer(),
                const Icon(Icons.check, size: 16),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: 'created_desc',
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 20,
                color: sortOrder == 'created_desc'
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              const SizedBox(width: 12),
              Text('sort_by_created_desc'.tr()),
              if (sortOrder == 'created_desc') ...[
                const Spacer(),
                const Icon(Icons.check, size: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsToggle(BuildContext context) {
    return IconButton(
      icon: Icon(_showQuickActions ? Icons.flash_off : Icons.flash_on),
      tooltip: _showQuickActions ? 'hide_quick_actions'.tr() : 'show_quick_actions'.tr(),
      onPressed: () {
        setState(() {
          _showQuickActions = !_showQuickActions;
        });
      },
    );
  }
}

