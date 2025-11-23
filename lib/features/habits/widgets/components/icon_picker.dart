import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'icon_constants.dart';

/// Reusable icon picker widget for habit and tag forms
class IconPickerWidget extends StatefulWidget {
  final String? selectedIcon;
  final ValueChanged<String?> onIconSelected;
  final String searchQuery; // Search query from parent

  const IconPickerWidget({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
    this.searchQuery = '',
  });

  @override
  State<IconPickerWidget> createState() => _IconPickerWidgetState();
}

class _IconPickerWidgetState extends State<IconPickerWidget> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<IconData> _getFilteredIcons() {
    if (widget.searchQuery.isEmpty) {
      return IconConstants.commonIcons;
    }
    return IconConstants.commonIcons
        .where((icon) => IconConstants.matchesSearch(icon, widget.searchQuery))
        .toList();
  }

  bool _shouldShowNoIconOption() {
    if (widget.searchQuery.isEmpty) return true;
    // "no icon" matches if search contains "no" or "icon" or "block"
    final query = widget.searchQuery.toLowerCase();
    return query.contains('no') ||
        query.contains('icon') ||
        query.contains('block') ||
        query.contains('none') ||
        query.contains('empty');
  }

  @override
  Widget build(BuildContext context) {
    final filteredIcons = _getFilteredIcons();
    final showNoIcon = _shouldShowNoIconOption();
    final itemCount = filteredIcons.length + (showNoIcon ? 1 : 0);

    return SizedBox(
      height: 140,
      child: itemCount == 0
          ? Center(
              child: Text(
                'no_icons_found'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    // Handle "no icon" option
                    if (showNoIcon && index == 0) {
                      final isSelected = widget.selectedIcon == null;
                      return GestureDetector(
                        onTap: () => widget.onIconSelected(null),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.secondary
                                      .withValues(alpha: 0.15)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.block,
                                size: 28,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 6),
                              Flexible(
                                child: Text(
                                  'no_icon'.tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.secondary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Handle regular icons
                    final iconIndex = showNoIcon ? index - 1 : index;
                    if (iconIndex < 0 || iconIndex >= filteredIcons.length) {
                      return const SizedBox.shrink();
                    }
                    final icon = filteredIcons[iconIndex];
                    final iconCode = icon.codePoint.toString();
                    final isSelected = widget.selectedIcon == iconCode;

                    return GestureDetector(
                      onTap: () => widget.onIconSelected(iconCode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.secondary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
