import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initializes EasyLocalization for tests
/// This must be called before any widget tests that use EasyLocalization
Future<void> initializeTestLocalization() async {
  // Mock SharedPreferences before EasyLocalization tries to use it
  SharedPreferences.setMockInitialValues({});
  
  // Ensure test binding is initialized
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Try to initialize EasyLocalization, but catch any device locale errors
  try {
    await EasyLocalization.ensureInitialized();
  } catch (e) {
    // If initialization fails due to device locale, that's okay for tests
    // We'll use a fallback approach
  }
}

/// Creates a test widget with EasyLocalization that handles initialization errors
Widget createLocalizedTestWidget({
  required Widget child,
  Locale? locale,
}) {
  // Ensure SharedPreferences is mocked
  SharedPreferences.setMockInitialValues({});
  
  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('ar')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    useOnlyLangCode: true,
    useFallbackTranslations: true,
    startLocale: locale ?? const Locale('en'),
    saveLocale: false,
    child: child,
  );
}

