import 'package:flutter/material.dart';

/// Utility function to create IconData from a code point string.
///
/// This is used for dynamic icons stored as strings in the database.
/// Note: This cannot be const because the icon code comes from runtime data,
/// which prevents tree shaking. However, it centralizes the icon creation logic.
IconData createIconDataFromString(String iconCode) {
  return IconData(int.parse(iconCode), fontFamily: 'MaterialIcons');
}
