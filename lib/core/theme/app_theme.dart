import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme({
    Color? seedColor,
    double? cardElevation,
    double? cardBorderRadius,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor ?? Colors.deepPurple,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: cardElevation ?? 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius ?? 12),
        ),
      ),
    );
  }

  static ThemeData darkTheme({
    Color? seedColor,
    double? cardElevation,
    double? cardBorderRadius,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor ?? Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: cardElevation ?? 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius ?? 12),
        ),
      ),
    );
  }
}

