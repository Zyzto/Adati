import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Utility class for formatting setting values to display names
class SettingsFormatters {
  /// Format language code to display name
  static String getLanguageName(String? code) {
    switch (code) {
      case 'en':
        return 'english'.tr();
      case 'ar':
        return 'arabic'.tr();
      default:
        return 'english'.tr();
    }
  }

  /// Format theme mode to display name
  static String getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light'.tr();
      case ThemeMode.dark:
        return 'dark'.tr();
      case ThemeMode.system:
        return 'system'.tr();
    }
  }

  /// Format day square size to display name
  static String getDaySquareSizeName(String size) {
    switch (size) {
      case 'small':
        return 'small'.tr();
      case 'medium':
        return 'medium'.tr();
      case 'large':
        return 'large'.tr();
      default:
        return 'medium'.tr();
    }
  }

  /// Format date format string to display name
  static String getDateFormatName(String format) {
    switch (format) {
      case 'yyyy-MM-dd':
        return 'date_format_yyyy_mm_dd'.tr();
      case 'MM/dd/yyyy':
        return 'date_format_mm_dd_yyyy'.tr();
      case 'dd/MM/yyyy':
        return 'date_format_dd_mm_yyyy'.tr();
      case 'dd.MM.yyyy':
        return 'date_format_dd_mm_yyyy_dots'.tr();
      default:
        return 'date_format_yyyy_mm_dd'.tr();
    }
  }

  /// Format first day of week to display name
  static String getFirstDayOfWeekName(int day) {
    return day == 0 ? 'sunday'.tr() : 'monday'.tr();
  }

  /// Format checkbox style to display name
  static String getCheckboxStyleName(String style) {
    switch (style) {
      case 'square':
        return 'square'.tr();
      case 'bordered':
        return 'bordered'.tr();
      case 'circle':
        return 'circle'.tr();
      case 'radio':
        return 'radio'.tr();
      case 'task':
        return 'task'.tr();
      case 'verified':
        return 'verified'.tr();
      case 'taskAlt':
        return 'task_alt'.tr();
      default:
        return 'square'.tr();
    }
  }

  /// Format icon size to display name
  static String getIconSizeName(String size) {
    switch (size) {
      case 'small':
        return 'small'.tr();
      case 'medium':
        return 'medium'.tr();
      case 'large':
        return 'large'.tr();
      default:
        return 'medium'.tr();
    }
  }

  /// Format progress indicator style to display name
  static String getProgressIndicatorStyleName(String style) {
    switch (style) {
      case 'circular':
        return 'circular'.tr();
      case 'linear':
        return 'linear'.tr();
      default:
        return 'circular'.tr();
    }
  }

  /// Format streak color scheme to display name
  static String getStreakColorSchemeName(String scheme) {
    switch (scheme) {
      case 'default':
        return 'default'.tr();
      case 'vibrant':
        return 'vibrant'.tr();
      case 'subtle':
        return 'subtle'.tr();
      case 'monochrome':
        return 'monochrome'.tr();
      default:
        return 'default'.tr();
    }
  }

  /// Format font size scale to display name
  static String getFontSizeScaleName(String scale) {
    switch (scale) {
      case 'small':
        return 'small'.tr();
      case 'normal':
        return 'normal'.tr();
      case 'large':
        return 'large'.tr();
      case 'extra_large':
        return 'extra_large'.tr();
      default:
        return 'normal'.tr();
    }
  }
}

