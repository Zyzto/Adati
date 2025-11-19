import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/habit_providers.dart';

class HabitsViewOptions extends ConsumerWidget {
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

  const HabitsViewOptions({
    super.key,
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
    final sessionOptions = ref.watch(sessionViewOptionsProvider);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.tune),
      tooltip: 'view_options'.tr(),
      onSelected: (value) {
        switch (value) {
          case 'layout_list':
            onCardLayoutChanged('list');
            break;
          case 'layout_grid':
            onCardLayoutChanged('grid');
            break;
          case 'toggle_tags':
            final newValue = !showTags;
            onShowTagsChanged(newValue);
            updateSessionViewOptions(
              ref,
              sessionOptions.copyWith(showTags: newValue),
            );
            break;
          case 'toggle_descriptions':
            final newValue = !showDescriptions;
            onShowDescriptionsChanged(newValue);
            updateSessionViewOptions(
              ref,
              sessionOptions.copyWith(showDescriptions: newValue),
            );
            break;
          case 'toggle_compact':
            final newValue = !compactCards;
            onCompactCardsChanged(newValue);
            updateSessionViewOptions(
              ref,
              sessionOptions.copyWith(compactCards: newValue),
            );
            break;
          case 'toggle_tag_filter':
            onShowTagFilterChanged(!showTagFilter);
            break;
        }
      },
      itemBuilder: (context) => _buildMenuItems(context, sessionOptions),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
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
              color: cardLayout == 'list'
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
              color: cardLayout == 'grid'
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
              color: (sessionOptions.showTags ?? showTags)
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                (sessionOptions.showTags ?? showTags)
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
              color: (sessionOptions.showDescriptions ?? showDescriptions)
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                (sessionOptions.showDescriptions ?? showDescriptions)
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
              color: (sessionOptions.compactCards ?? compactCards)
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                (sessionOptions.compactCards ?? compactCards)
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
              color: showTagFilter
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                showTagFilter
                    ? 'hide_tag_filter'.tr()
                    : 'show_tag_filter'.tr(),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

