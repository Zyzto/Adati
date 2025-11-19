import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../core/database/app_database.dart' as db;
import 'tag_filter_row.dart';

/// Widget that detects tag overflow and shows only visible tags with a "+" button for overflowed ones
class TagOverflowDetector extends StatefulWidget {
  final List<db.Tag> tags;
  final Set<int> selectedTagIds;
  final dynamic filterByTagsNotifier;
  final double availableWidth;
  final double buttonWidth;
  final VoidCallback onTagsChanged;

  const TagOverflowDetector({
    super.key,
    required this.tags,
    required this.selectedTagIds,
    required this.filterByTagsNotifier,
    required this.availableWidth,
    required this.buttonWidth,
    required this.onTagsChanged,
  });

  @override
  State<TagOverflowDetector> createState() => _TagOverflowDetectorState();
}

class _TagOverflowDetectorState extends State<TagOverflowDetector> {
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
  void didUpdateWidget(TagOverflowDetector oldWidget) {
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
              final averageTagWidth = rowWidth / widget.tags.length;
              final estimatedVisibleCount =
                  (availableWidthForTags / averageTagWidth).floor().clamp(
                    0,
                    widget.tags.length,
                  );

              final overflowStartIndex = estimatedVisibleCount.clamp(
                0,
                widget.tags.length,
              );

              if (overflowStartIndex < widget.tags.length) {
                final allOverflowed = widget.tags.sublist(overflowStartIndex);
                if (allOverflowed.length > 1) {
                  overflowedTags = [
                    ...allOverflowed.take(allOverflowed.length - 2),
                    allOverflowed.last,
                  ];
                } else {
                  overflowedTags = allOverflowed;
                }
              }
            }
          }
        }

        // Fallback: if we couldn't calculate and there's overflow,
        // show the last tag (which is the one that's fading/overflowing)
        if (overflowedTags.isEmpty && _hasOverflow && widget.tags.isNotEmpty) {
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
    return TagFilterRow(
      tags: widget.tags,
      selectedTagIds: widget.selectedTagIds,
      filterByTagsNotifier: widget.filterByTagsNotifier,
      buttonWidth: widget.buttonWidth,
      hasOverflow: _hasOverflow,
      rowKey: _rowKey,
      onTagsChanged: widget.onTagsChanged,
      buildTagChip: _buildTagChip,
      buildPlusButton: _buildPlusButton,
    );
  }
}

