import 'package:flutter/material.dart';

/// Helper class for creating responsive dialogs that work on all screen sizes
class ResponsiveDialog {
  /// Get responsive dialog width based on screen size
  /// 
  /// - Phone (< 600px): 90% width, max 400px, min 280px
  /// - Tablet (600-1024px): 70% width, max 600px, min 400px
  /// - Desktop (> 1024px): 50% width, max 800px, min 600px
  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      // Phone: 90% width, max 400px, min 280px
      return (screenWidth * 0.9).clamp(280.0, 400.0);
    } else if (screenWidth < 1024) {
      // Tablet: 70% width, max 600px, min 400px
      return (screenWidth * 0.7).clamp(400.0, 600.0);
    } else {
      // Desktop: 50% width, max 800px, min 600px
      return (screenWidth * 0.5).clamp(600.0, 800.0);
    }
  }

  /// Get adaptive grid cross-axis count based on screen size
  /// 
  /// - Phone (< 600px): 2 columns
  /// - Tablet (600-1024px): 3 columns
  /// - Desktop (> 1024px): 4 columns
  /// 
  /// Can optionally specify itemCount to adjust columns for very large grids
  static int getGridCrossAxisCount(
    BuildContext context, {
    int itemCount = 13,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      // Phone: 2 columns
      return 2;
    } else if (screenWidth < 1024) {
      // Tablet: 3 columns
      return 3;
    } else {
      // Desktop: 4 columns (can be 5-6 for very large screens and many items)
      if (screenWidth > 1400 && itemCount > 12) {
        return 5;
      } else if (screenWidth > 1600 && itemCount > 15) {
        return 6;
      }
      return 4;
    }
  }

  /// Get responsive content padding based on screen size
  static EdgeInsets getContentPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return const EdgeInsets.all(16.0);
    } else if (screenWidth < 1024) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  /// Get responsive dialog max height based on screen size
  static double? getMaxHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 600) {
      // Very small screens: 80% of height
      return screenHeight * 0.8;
    } else if (screenHeight < 1024) {
      // Medium screens: 70% of height
      return screenHeight * 0.7;
    } else {
      // Large screens: 60% of height, max 600px
      return (screenHeight * 0.6).clamp(400.0, 600.0);
    }
  }

  /// Check if screen is in landscape mode
  static bool isLandscape(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width > mediaQuery.size.height;
  }

  /// Check if screen is a phone (width < 600px)
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if screen is a tablet (600px <= width < 1024px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  /// Check if screen is a desktop (width >= 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Create a responsive AlertDialog with proper constraints
  static Widget responsiveAlertDialog({
    required BuildContext context,
    required Widget title,
    required Widget content,
    List<Widget>? actions,
    bool scrollable = false,
  }) {
    final dialogWidth = getDialogWidth(context);
    final maxHeight = getMaxHeight(context);
    final contentPadding = getContentPadding(context);

    Widget contentWidget = scrollable
        ? SingleChildScrollView(
            child: Padding(
              padding: contentPadding,
              child: content,
            ),
          )
        : Padding(
            padding: contentPadding,
            child: content,
          );

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

  /// Create a responsive Dialog (full custom) with proper constraints
  static Widget responsiveDialog({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
  }) {
    final dialogWidth = getDialogWidth(context);
    final maxHeight = getMaxHeight(context);
    final contentPadding = padding ?? getContentPadding(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: Padding(
          padding: contentPadding,
          child: child,
        ),
      ),
    );
  }

  /// Check if split-screen layout should be used
  /// Returns true if device is in landscape mode
  static bool shouldUseSplitScreen(BuildContext context) {
    return isLandscape(context);
  }

  /// Check if a dialog method name indicates it's a confirmation dialog
  /// Confirmation dialogs should always show as modals, even in landscape
  static bool isConfirmationDialog(String dialogMethodName) {
    final confirmationKeywords = [
      'reset',
      'clear',
      'delete',
      'remove',
      'optimize',
      'confirm',
      'warning',
      'danger',
    ];
    
    final lowerName = dialogMethodName.toLowerCase();
    return confirmationKeywords.any((keyword) => lowerName.contains(keyword));
  }
}

