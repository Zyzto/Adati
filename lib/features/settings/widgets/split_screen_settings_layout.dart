import 'package:flutter/material.dart';

/// Split-screen layout for settings page in landscape mode
/// Shows settings list on left and detail pane on right
class SplitScreenSettingsLayout extends StatelessWidget {
  final Widget settingsList;
  final Widget? detailContent;
  final String? detailTitle;
  final VoidCallback? onCloseDetail;

  const SplitScreenSettingsLayout({
    super.key,
    required this.settingsList,
    this.detailContent,
    this.detailTitle,
    this.onCloseDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDetail = detailContent != null;

    return Row(
      children: [
        // Left pane: Settings list (40% width)
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints.expand(),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                right: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: SizedBox.expand(child: settingsList),
          ),
        ),

        // Right pane: Detail view (60% width)
        Expanded(
          flex: 6,
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: hasDetail
                ? _buildDetailPane(context, theme)
                : _buildEmptyState(context, theme),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailPane(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Detail header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: Row(
            children: [
              if (detailTitle != null)
                Expanded(
                  child: Text(
                    detailTitle!,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Detail content (scrollable)
        Expanded(child: detailContent!),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a setting to view details',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
