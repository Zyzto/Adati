import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adati/core/services/preferences_service.dart';
import 'package:adati/features/settings/providers/settings_providers.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();
  });

  tearDown(() async {
    await PreferencesService.clear();
  });

  group('Settings Providers', () {
    test('badHabitLogicModeProvider returns default value', () {
      final container = ProviderContainer();
      final mode = container.read(badHabitLogicModeProvider);
      
      expect(mode, equals('positive')); // Default value
      container.dispose();
    });

    test('badHabitLogicModeProvider updates when setting changes', () async {
      final container = ProviderContainer();
      
      // Change setting
      final notifier = container.read(badHabitLogicModeNotifierProvider);
      await notifier.setBadHabitLogicMode('negative');
      
      // Read updated value
      final mode = container.read(badHabitLogicModeProvider);
      expect(mode, equals('negative'));
      
      container.dispose();
    });

    test('notificationsEnabledProvider returns default value', () {
      final container = ProviderContainer();
      final enabled = container.read(notificationsEnabledProvider);
      
      expect(enabled, equals(true)); // Default value
      container.dispose();
    });

    test('notificationsEnabledProvider updates when setting changes', () async {
      final container = ProviderContainer();
      
      // Change setting
      final notifier = container.read(notificationsEnabledNotifierProvider);
      await notifier.setNotificationsEnabled(false);
      
      // Read updated value
      final enabled = container.read(notificationsEnabledProvider);
      expect(enabled, equals(false));
      
      container.dispose();
    });
  });
}

