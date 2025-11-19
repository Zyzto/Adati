import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../core/database/app_database.dart' as db;

class TagFilterRow extends StatelessWidget {
  final List<db.Tag> tags;
  final Set<int> selectedTagIds;
  final dynamic filterByTagsNotifier;
  final double buttonWidth;
  final bool hasOverflow;
  final GlobalKey rowKey;
  final VoidCallback onTagsChanged;
  final Widget Function(db.Tag tag, bool isSelected, {bool isDisabled}) buildTagChip;
  final Widget Function() buildPlusButton;

  const TagFilterRow({
    super.key,
    required this.tags,
    required this.selectedTagIds,
    required this.filterByTagsNotifier,
    required this.buttonWidth,
    required this.hasOverflow,
    required this.rowKey,
    required this.onTagsChanged,
    required this.buildTagChip,
    required this.buildPlusButton,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the width available for tags (excluding button and padding)
        const buttonPadding = 8.0;
        final availableWidthForTags = hasOverflow
            ? constraints.maxWidth - buttonWidth - buttonPadding
            : constraints.maxWidth;

        // Get text direction for RTL support
        final locale = context.locale;
        final isRTL =
            locale.languageCode == 'ar' ||
            locale.languageCode == 'he' ||
            locale.languageCode == 'fa';

        return SizedBox(
          height: 40, // Fixed height to prevent intrinsic dimension calculations
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Clip tags to available width and apply fade
              ClipRect(
                child: SizedBox(
                  width: availableWidthForTags,
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      // Fade from 80% to 100% of the available width
                      if (isRTL) {
                        // RTL: Button is on left, fade from right (opaque) to left (transparent at button)
                        return LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.8, 1.0],
                        ).createShader(bounds);
                      } else {
                        // LTR: Button is on right, fade from left (opaque) to right (transparent at button)
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.8, 1.0],
                        ).createShader(bounds);
                      }
                    },
                    blendMode: BlendMode.dstIn,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: IntrinsicWidth(
                        child: Row(
                          key: rowKey,
                          mainAxisSize: MainAxisSize.min,
                          children: tags.asMap().entries.map((entry) {
                            final index = entry.key;
                            final tag = entry.value;
                            final isSelected = selectedTagIds.contains(tag.id);
                            final isLastTag = index == tags.length - 1;
                            final isDisabled = hasOverflow && isLastTag;
                            return buildTagChip(
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
              // "+" button positioned at the end when there's overflow
              if (hasOverflow)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: buildPlusButton(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

