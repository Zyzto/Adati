import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../settings/providers/settings_providers.dart';

class HabitsSearchBar extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final bool autofocus;

  const HabitsSearchBar({
    super.key,
    required this.controller,
    this.autofocus = false,
  });

  @override
  ConsumerState<HabitsSearchBar> createState() => _HabitsSearchBarState();
}

class _HabitsSearchBarState extends ConsumerState<HabitsSearchBar> {
  @override
  Widget build(BuildContext context) {
    final filterQuery = ref.watch(habitFilterQueryProvider);
    final notifier = ref.read(habitFilterQueryNotifierProvider);

    return Padding(
      key: const ValueKey('search'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: widget.controller,
        autofocus: widget.autofocus,
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
                    widget.controller.clear();
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
}

