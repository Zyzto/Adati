import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/habit_providers.dart';
import '../../../settings/providers/settings_framework_providers.dart';
import '../../../settings/settings_definitions.dart';

// Filter type constants
const String _filterTypeGood = 'good';
const String _filterTypeBad = 'bad';

class HabitsSortMenu extends ConsumerWidget {
  const HabitsSortMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(adatiSettingsProvider);
    final sortOrder = ref.watch(settings.provider(habitSortOrderSettingDef));
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
          await ref.read(settings.provider(habitSortOrderSettingDef).notifier).set(value.substring(5));
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
}

