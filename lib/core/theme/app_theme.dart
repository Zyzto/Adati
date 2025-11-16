import 'package:flutter/material.dart';
import '../services/log_helper.dart';

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

  static ThemeData lightTheme({
    Color? seedColor,
    double? cardElevation,
    double? cardBorderRadius,
    Locale? locale,
  }) {
    Log.debug('AppTheme.lightTheme(seedColor=$seedColor, cardElevation=$cardElevation, cardBorderRadius=$cardBorderRadius, locale=${locale?.languageCode})');
    final baseSeedColor = seedColor ?? Colors.deepPurple;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: baseSeedColor,
      brightness: Brightness.light,
    );

    final fontFamily = _getFontFamily(locale);
    
    // Create base text theme
    final baseTextTheme = ThemeData.light().textTheme;
    
    // Apply font family to text theme only if needed
    // This ensures Material Icons and emojis use system fonts
    final textTheme = fontFamily != null
        ? baseTextTheme.apply(fontFamily: fontFamily)
        : null;

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
  }) {
    Log.debug('AppTheme.darkTheme(seedColor=$seedColor, cardElevation=$cardElevation, cardBorderRadius=$cardBorderRadius, locale=${locale?.languageCode})');
    final baseSeedColor = seedColor ?? Colors.deepPurple;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: baseSeedColor,
      brightness: Brightness.dark,
    );

    final fontFamily = _getFontFamily(locale);
    
    // Create base text theme
    final baseTextTheme = ThemeData.dark().textTheme;
    
    // Apply font family to text theme only if needed
    // This ensures Material Icons and emojis use system fonts
    final textTheme = fontFamily != null
        ? baseTextTheme.apply(fontFamily: fontFamily)
        : null;

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

