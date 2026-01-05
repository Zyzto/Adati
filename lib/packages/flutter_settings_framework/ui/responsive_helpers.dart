/// Flutter Settings Framework
/// Responsive UI helpers for adaptive layouts.
///
/// These helpers enable creating settings UIs that adapt to different
/// screen sizes and orientations.
library;

import 'package:flutter/material.dart';

/// Screen size breakpoints.
enum ScreenSize {
  /// Phone: width < 600px
  phone,

  /// Tablet: 600px <= width < 1024px
  tablet,

  /// Desktop: width >= 1024px
  desktop,
}

/// Responsive layout helper.
///
/// Provides utilities for creating adaptive layouts based on screen size.
class ResponsiveLayout {
  /// Get the current screen size category.
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return ScreenSize.phone;
    if (width < 1024) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  /// Check if the screen is a phone.
  static bool isPhone(BuildContext context) =>
      getScreenSize(context) == ScreenSize.phone;

  /// Check if the screen is a tablet.
  static bool isTablet(BuildContext context) =>
      getScreenSize(context) == ScreenSize.tablet;

  /// Check if the screen is a desktop.
  static bool isDesktop(BuildContext context) =>
      getScreenSize(context) == ScreenSize.desktop;

  /// Check if the screen is in landscape orientation.
  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height;
  }

  /// Check if the screen is in portrait orientation.
  static bool isPortrait(BuildContext context) => !isLandscape(context);

  /// Check if split-screen layout should be used.
  ///
  /// Returns true for landscape tablet/desktop screens.
  static bool shouldUseSplitScreen(BuildContext context) {
    final screenSize = getScreenSize(context);
    return isLandscape(context) &&
        (screenSize == ScreenSize.tablet || screenSize == ScreenSize.desktop);
  }

  /// Get the number of grid columns based on screen size.
  static int getGridColumns(BuildContext context, {int? itemCount}) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2;
    if (width < 1024) return 3;
    if (width > 1400 && (itemCount ?? 0) > 12) return 5;
    if (width > 1600 && (itemCount ?? 0) > 15) return 6;
    return 4;
  }

  /// Get responsive padding based on screen size.
  static EdgeInsets getPadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.phone:
        return const EdgeInsets.all(16);
      case ScreenSize.tablet:
        return const EdgeInsets.all(20);
      case ScreenSize.desktop:
        return const EdgeInsets.all(24);
    }
  }

  /// Get responsive dialog width.
  static double getDialogWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return (width * 0.9).clamp(280, 400);
    } else if (width < 1024) {
      return (width * 0.7).clamp(400, 600);
    } else {
      return (width * 0.5).clamp(600, 800);
    }
  }

  /// Get responsive dialog max height.
  static double? getDialogMaxHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    if (height < 600) {
      return height * 0.8;
    } else if (height < 1024) {
      return height * 0.7;
    } else {
      return (height * 0.6).clamp(400, 600);
    }
  }

  /// Build a responsive value based on screen size.
  static T value<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.phone:
        return phone;
      case ScreenSize.tablet:
        return tablet ?? phone;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? phone;
    }
  }
}

/// Responsive dialog helper.
///
/// Creates dialogs that adapt to different screen sizes.
class SettingsDialog {
  /// Show a responsive alert dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget title,
    required Widget content,
    List<Widget>? actions,
    bool scrollable = false,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _buildResponsiveDialog(
        context: context,
        title: title,
        content: content,
        actions: actions,
        scrollable: scrollable,
      ),
    );
  }

  /// Show a confirmation dialog.
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDangerous = false,
  }) async {
    final result = await show<bool>(
      context: context,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText ?? 'Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDangerous
              ? TextButton.styleFrom(foregroundColor: Colors.red)
              : null,
          child: Text(confirmText ?? 'Confirm'),
        ),
      ],
    );
    return result ?? false;
  }

  /// Show a selection dialog.
  static Future<T?> select<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required Widget Function(T option) itemBuilder,
    T? selectedValue,
  }) {
    return show<T>(
      context: context,
      title: Text(title),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option == selectedValue;
          return ListTile(
            leading: isSelected
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : const SizedBox(width: 24),
            title: itemBuilder(option),
            onTap: () => Navigator.of(context).pop(option),
          );
        }).toList(),
      ),
    );
  }

  /// Show a slider dialog for numeric values.
  static Future<double?> slider({
    required BuildContext context,
    required String title,
    required double value,
    required double min,
    required double max,
    int? divisions,
    String? label,
    String Function(double)? valueLabel,
  }) async {
    double currentValue = value;

    return show<double>(
      context: context,
      title: Text(title),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: currentValue,
                min: min,
                max: max,
                divisions: divisions,
                label: valueLabel?.call(currentValue) ?? currentValue.toStringAsFixed(1),
                onChanged: (v) => setState(() => currentValue = v),
              ),
              if (label != null)
                Text(
                  '$label: ${valueLabel?.call(currentValue) ?? currentValue.toStringAsFixed(1)}',
                ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(currentValue),
          child: const Text('OK'),
        ),
      ],
    );
  }

  /// Show a color picker dialog.
  static Future<Color?> colorPicker({
    required BuildContext context,
    required String title,
    required Color currentColor,
    List<Color>? colors,
    bool allowCustom = true,
  }) async {
    final defaultColors = colors ??
        [
          Colors.green,
          Colors.blue,
          Colors.purple,
          Colors.orange,
          Colors.red,
          Colors.teal,
          Colors.indigo,
          Colors.amber,
          Colors.cyan,
          Colors.pink,
          Colors.brown,
          Colors.grey,
        ];

    // Calculate cross axis count based on color count
    final crossAxisCount = _getColorGridColumns(context, defaultColors.length);

    return show<Color>(
      context: context,
      title: Text(title),
      scrollable: true,
      content: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: defaultColors.length,
        itemBuilder: (context, index) {
          final color = defaultColors[index];
          final isSelected = color.toARGB32() == currentColor.toARGB32();
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(color),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.transparent,
                  width: 3,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }

  /// Calculate optimal grid columns for color picker.
  static int _getColorGridColumns(BuildContext context, int itemCount) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 4;
    if (width < 600) return 5;
    if (width < 900) return 6;
    return 8;
  }

  static Widget _buildResponsiveDialog({
    required BuildContext context,
    required Widget title,
    required Widget content,
    List<Widget>? actions,
    bool scrollable = false,
  }) {
    final dialogWidth = ResponsiveLayout.getDialogWidth(context);
    final maxHeight = ResponsiveLayout.getDialogMaxHeight(context);
    final padding = ResponsiveLayout.getPadding(context);

    Widget contentWidget = scrollable
        ? SingleChildScrollView(
            child: Padding(padding: padding, child: content),
          )
        : Padding(padding: padding, child: content);

    return AlertDialog(
      title: title,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: contentWidget,
      ),
      actions: actions,
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// Split-screen layout for settings.
///
/// Shows a list on the left and detail pane on the right.
class SplitScreenLayout extends StatelessWidget {
  /// The list/navigation pane.
  final Widget listPane;

  /// The detail pane (null shows empty state).
  final Widget? detailPane;

  /// Title for the detail pane.
  final String? detailTitle;

  /// Callback when detail pane should close.
  final VoidCallback? onCloseDetail;

  /// Flex ratio for list pane (default 4).
  final int listFlex;

  /// Flex ratio for detail pane (default 6).
  final int detailFlex;

  /// Empty state widget for detail pane.
  final Widget? emptyState;

  const SplitScreenLayout({
    super.key,
    required this.listPane,
    this.detailPane,
    this.detailTitle,
    this.onCloseDetail,
    this.listFlex = 4,
    this.detailFlex = 6,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // List pane
        Expanded(
          flex: listFlex,
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                right: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: listPane,
          ),
        ),
        // Detail pane
        Expanded(
          flex: detailFlex,
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: detailPane != null
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
        if (detailTitle != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    detailTitle!,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onCloseDetail != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCloseDetail,
                  ),
              ],
            ),
          ),
        Expanded(child: detailPane!),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    if (emptyState != null) return emptyState!;

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

