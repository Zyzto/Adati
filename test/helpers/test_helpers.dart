import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adati/core/services/preferences_service.dart';
import 'localization_helpers.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

// Initialize EasyLocalization once for all tests
bool _easyLocalizationInitialized = false;

/// Sets up the test environment with necessary providers and localization
/// This should be called in setUpAll before any widget tests
Future<void> setupTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await PreferencesService.init();
  LoggingService.disableFileLogging(); // Add this line
  await initializeTestLocalization();
}

/// Sets up the test environment with necessary providers and localization
Widget createTestWidget({required Widget child, List<Object>? overrides}) {
  // Ensure SharedPreferences is mocked for tests BEFORE EasyLocalization uses it
  if (!_easyLocalizationInitialized) {
    SharedPreferences.setMockInitialValues({});
    _easyLocalizationInitialized = true;
  }

  // Use the test-specific localization helper
  return createLocalizedTestWidget(
    locale: const Locale('en'),
    child: ProviderScope(
      // Cast to List<Override> - Override is not exported but ProviderScope accepts it
      // ignore: avoid_dynamic_calls
      overrides: overrides?.cast() ?? [],
      child: MaterialApp(
        localizationsDelegates: const [],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: Scaffold(body: child),
      ),
    ),
  );
}

/// Pumps a widget with all necessary test setup
/// Use this for widgets that don't have animations or infinite async loops
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget widget, {
  List<Object>? overrides,
}) async {
  await tester.pumpWidget(
    createTestWidget(child: widget, overrides: overrides),
  );
  // Pump multiple times to allow EasyLocalization and providers to initialize
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
  // Don't use pumpAndSettle for widgets with async operations - it can timeout
  // Instead, use explicit pumps
}

/// Waits for async operations to complete
Future<void> waitForAsync(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}
