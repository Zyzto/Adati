import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme({
    Color? seedColor,
    double? cardElevation,
    double? cardBorderRadius,
  }) {
    final baseSeedColor = seedColor ?? Colors.deepPurple;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: baseSeedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
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
  }) {
    final baseSeedColor = seedColor ?? Colors.deepPurple;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: baseSeedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
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

