import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../forms/habit_form_modal.dart';
import '../filters/habits_sort_menu.dart';
import '../filters/habits_view_options.dart';

class HabitsSectionHeader extends ConsumerWidget {
  final bool showSearch;
  final VoidCallback onSearchToggle;
  final bool showQuickActions;
  final VoidCallback onQuickActionsToggle;
  final String cardLayout;
  final bool showTags;
  final bool showDescriptions;
  final bool compactCards;
  final bool showTagFilter;
  final ValueChanged<String> onCardLayoutChanged;
  final ValueChanged<bool> onShowTagsChanged;
  final ValueChanged<bool> onShowDescriptionsChanged;
  final ValueChanged<bool> onCompactCardsChanged;
  final ValueChanged<bool> onShowTagFilterChanged;

  const HabitsSectionHeader({
    super.key,
    required this.showSearch,
    required this.onSearchToggle,
    required this.showQuickActions,
    required this.onQuickActionsToggle,
    required this.cardLayout,
    required this.showTags,
    required this.showDescriptions,
    required this.compactCards,
    required this.showTagFilter,
    required this.onCardLayoutChanged,
    required this.onShowTagsChanged,
    required this.onShowDescriptionsChanged,
    required this.onCompactCardsChanged,
    required this.onShowTagFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const HabitsSortMenu(),
              const SizedBox(width: 8),
              HabitsViewOptions(
                cardLayout: cardLayout,
                showTags: showTags,
                showDescriptions: showDescriptions,
                compactCards: compactCards,
                showTagFilter: showTagFilter,
                onCardLayoutChanged: onCardLayoutChanged,
                onShowTagsChanged: onShowTagsChanged,
                onShowDescriptionsChanged: onShowDescriptionsChanged,
                onCompactCardsChanged: onCompactCardsChanged,
                onShowTagFilterChanged: onShowTagFilterChanged,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(showQuickActions ? Icons.flash_off : Icons.flash_on),
                onPressed: onQuickActionsToggle,
                tooltip: showQuickActions
                    ? 'hide_quick_actions'.tr()
                    : 'show_quick_actions'.tr(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(showSearch ? Icons.search_off : Icons.search),
                onPressed: onSearchToggle,
                tooltip: showSearch ? 'hide_search'.tr() : 'search'.tr(),
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
}

