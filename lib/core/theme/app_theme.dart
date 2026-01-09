import 'package:flutter/material.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

class AppTheme {
  // Helper method to get font family based on locale
  static String? _getFontFamily(Locale? locale) {
    if (locale == null) return null;
    // Use Almarai only for Arabic
    if (locale.languageCode == 'ar') {
      return 'Almarai';
    }
    // Return null to use system default for other languages
    return null;
  }

  // Helper method to get text scale factor from font size scale setting
  static double _getTextScaleFactor(String? fontSizeScale) {
    switch (fontSizeScale) {
      case 'small':
        return 0.85;
      case 'normal':
        return 1.0;
      case 'large':
        return 1.15;
      case 'extra_large':
        return 1.3;
      default:
        return 1.0;
    }
  }

  // Helper method to scale text theme
  static TextTheme _scaleTextTheme(TextTheme baseTextTheme, double scaleFactor) {
    return TextTheme(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: (baseTextTheme.displayLarge?.fontSize ?? 57) * scaleFactor,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: (baseTextTheme.displayMedium?.fontSize ?? 45) * scaleFactor,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: (baseTextTheme.displaySmall?.fontSize ?? 36) * scaleFactor,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: (baseTextTheme.headlineLarge?.fontSize ?? 32) * scaleFactor,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: (baseTextTheme.headlineMedium?.fontSize ?? 28) * scaleFactor,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: (baseTextTheme.headlineSmall?.fontSize ?? 24) * scaleFactor,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: (baseTextTheme.titleLarge?.fontSize ?? 22) * scaleFactor,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: (baseTextTheme.titleMedium?.fontSize ?? 16) * scaleFactor,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: (baseTextTheme.titleSmall?.fontSize ?? 14) * scaleFactor,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: (baseTextTheme.bodyLarge?.fontSize ?? 16) * scaleFactor,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: (baseTextTheme.bodyMedium?.fontSize ?? 14) * scaleFactor,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: (baseTextTheme.bodySmall?.fontSize ?? 12) * scaleFactor,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: (baseTextTheme.labelLarge?.fontSize ?? 14) * scaleFactor,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: (baseTextTheme.labelMedium?.fontSize ?? 12) * scaleFactor,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: (baseTextTheme.labelSmall?.fontSize ?? 11) * scaleFactor,
      ),
    );
  }

  static ThemeData lightTheme({
    Color? seedColor,
    double? cardElevation,
    double? cardBorderRadius,
    Locale? locale,
    String? fontSizeScale,
  }) {
    Log.debug('AppTheme.lightTheme(seedColor=$seedColor, cardElevation=$cardElevation, cardBorderRadius=$cardBorderRadius, locale=${locale?.languageCode}, fontSizeScale=$fontSizeScale)');
    final baseSeedColor = seedColor ?? Colors.deepPurple;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: baseSeedColor,
      brightness: Brightness.light,
    );

    final fontFamily = _getFontFamily(locale);
    final textScaleFactor = _getTextScaleFactor(fontSizeScale);
    
    // Create base text theme
    final baseTextTheme = ThemeData.light().textTheme;
    
    // Apply font family to text theme only if needed
    // This ensures Material Icons and emojis use system fonts
    final textThemeWithFont = fontFamily != null
        ? baseTextTheme.apply(fontFamily: fontFamily)
        : baseTextTheme;
    
    // Apply font size scale
    final textTheme = _scaleTextTheme(textThemeWithFont, textScaleFactor);

    return ThemeData(
      useMaterial3: true,
      // Don't set fontFamily globally - only apply to text theme
      // This allows Material Icons and emojis to use system fonts
      textTheme: textTheme,
      colorScheme: colorScheme.copyWith(
        // Ensure better contrast for surfaces
        surface: Colors.white,
        surfaceContainerHighest: Colors.grey[100]!,
        onSurface: Colors.grey[900]!,
        onSurfaceVariant: Colors.grey[700]!,
        // Better contrast for borders and dividers
        outline: Colors.grey[400]!,
        outlineVariant: Colors.grey[300]!,
        // Ensure primary has good contrast
        primary: baseSeedColor,
        onPrimary: Colors.white,
        // Secondary colors with better contrast
        secondary: baseSeedColor.withValues(alpha: 0.8),
        onSecondary: Colors.white,
        // Error colors with proper contrast
        error: Colors.red[700]!,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: cardElevation ?? 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius ?? 12),
        ),
        color: colorScheme.surface,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[300]!,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseSeedColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[700]!),
        ),
      ),
      iconTheme: IconThemeData(
        color: Colors.grey[800]!,
      ),
    );
  }

  static ThemeData darkTheme({
    Color? seedColor,
    double? cardElevation,
    double? cardBorderRadius,
    Locale? locale,
    String? fontSizeScale,
  }) {
    Log.debug('AppTheme.darkTheme(seedColor=$seedColor, cardElevation=$cardElevation, cardBorderRadius=$cardBorderRadius, locale=${locale?.languageCode}, fontSizeScale=$fontSizeScale)');
    final baseSeedColor = seedColor ?? Colors.deepPurple;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: baseSeedColor,
      brightness: Brightness.dark,
    );

    final fontFamily = _getFontFamily(locale);
    final textScaleFactor = _getTextScaleFactor(fontSizeScale);
    
    // Create base text theme
    final baseTextTheme = ThemeData.dark().textTheme;
    
    // Apply font family to text theme only if needed
    // This ensures Material Icons and emojis use system fonts
    final textThemeWithFont = fontFamily != null
        ? baseTextTheme.apply(fontFamily: fontFamily)
        : baseTextTheme;
    
    // Apply font size scale
    final textTheme = _scaleTextTheme(textThemeWithFont, textScaleFactor);

    return ThemeData(
      useMaterial3: true,
      // Don't set fontFamily globally - only apply to text theme
      // This allows Material Icons and emojis to use system fonts
      textTheme: textTheme,
      colorScheme: colorScheme.copyWith(
        // Ensure better contrast for surfaces
        surface: Colors.grey[900]!,
        surfaceContainerHighest: Colors.grey[800]!,
        onSurface: Colors.grey[100]!,
        onSurfaceVariant: Colors.grey[300]!,
        // Better contrast for borders and dividers
        outline: Colors.grey[600]!,
        outlineVariant: Colors.grey[700]!,
        // Ensure primary has good contrast
        primary: baseSeedColor,
        onPrimary: Colors.white,
        // Secondary colors with better contrast
        secondary: baseSeedColor.withValues(alpha: 0.8),
        onSecondary: Colors.white,
        // Error colors with proper contrast
        error: Colors.red[400]!,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: cardElevation ?? 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius ?? 12),
        ),
        color: colorScheme.surface,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[700]!,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseSeedColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
      ),
      iconTheme: IconThemeData(
        color: Colors.grey[200]!,
      ),
    );
  }
}

