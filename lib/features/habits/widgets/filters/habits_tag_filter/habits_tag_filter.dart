import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/habit_providers.dart';
import 'tag_overflow_detector.dart';

class HabitsTagFilter extends ConsumerWidget {
  const HabitsTagFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const buttonWidth = 40.0;
              final availableWidth = constraints.maxWidth;

              return TagOverflowDetector(
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
}

