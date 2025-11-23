import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adati/core/services/preferences_service.dart';

void main() {
  setUp(() async {
    // Clear shared preferences before each test
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();
  });

  tearDown(() async {
    // Clear shared preferences after each test
    await PreferencesService.clear();
  });

  group('PreferencesService - Theme Mode', () {
    test('getThemeMode returns null initially', () {
      final mode = PreferencesService.getThemeMode();
      expect(mode, isNull);
    });

    test('setThemeMode and getThemeMode work correctly', () async {
      await PreferencesService.setThemeMode('dark');
      final mode = PreferencesService.getThemeMode();
      expect(mode, equals('dark'));
    });

    test('setThemeMode updates existing value', () async {
      await PreferencesService.setThemeMode('light');
      await PreferencesService.setThemeMode('dark');
      final mode = PreferencesService.getThemeMode();
      expect(mode, equals('dark'));
    });
  });

  group('PreferencesService - Language', () {
    test('getLanguage returns null initially', () {
      final lang = PreferencesService.getLanguage();
      expect(lang, isNull);
    });

    test('setLanguage and getLanguage work correctly', () async {
      await PreferencesService.setLanguage('ar');
      final lang = PreferencesService.getLanguage();
      expect(lang, equals('ar'));
    });
  });

  group('PreferencesService - Bad Habit Logic Mode', () {
    test('getBadHabitLogicMode returns default value', () {
      final mode = PreferencesService.getBadHabitLogicMode();
      expect(mode, equals('positive')); // Default from preferences_service.dart
    });

    test('setBadHabitLogicMode and getBadHabitLogicMode work correctly', () async {
      await PreferencesService.setBadHabitLogicMode('negative');
      final mode = PreferencesService.getBadHabitLogicMode();
      expect(mode, equals('negative'));
    });

    test('setBadHabitLogicMode updates existing value', () async {
      await PreferencesService.setBadHabitLogicMode('positive');
      await PreferencesService.setBadHabitLogicMode('negative');
      final mode = PreferencesService.getBadHabitLogicMode();
      expect(mode, equals('negative'));
    });
  });

  group('PreferencesService - Timeline Days', () {
    test('getTimelineDays returns default value', () {
      final days = PreferencesService.getTimelineDays();
      expect(days, equals(100)); // Default value
    });

    test('setTimelineDays and getTimelineDays work correctly', () async {
      await PreferencesService.setTimelineDays(50);
      final days = PreferencesService.getTimelineDays();
      expect(days, equals(50));
    });
  });

  group('PreferencesService - Notifications', () {
    test('getNotificationsEnabled returns default value', () {
      final enabled = PreferencesService.getNotificationsEnabled();
      expect(enabled, equals(true)); // Default value
    });

    test('setNotificationsEnabled and getNotificationsEnabled work correctly', () async {
      await PreferencesService.setNotificationsEnabled(false);
      final enabled = PreferencesService.getNotificationsEnabled();
      expect(enabled, equals(false));
    });
  });

  group('PreferencesService - Reset', () {
    test('resetAllSettings clears all preferences', () async {
      // Set some preferences
      await PreferencesService.setThemeMode('dark');
      await PreferencesService.setLanguage('ar');
      await PreferencesService.setTimelineDays(50);

      // Reset
      final success = await PreferencesService.resetAllSettings();
      expect(success, isTrue);

      // Verify all are cleared
      expect(PreferencesService.getThemeMode(), isNull);
      expect(PreferencesService.getLanguage(), isNull);
      expect(PreferencesService.getTimelineDays(), equals(100)); // Back to default
    });
  });
}

