/// Adati Settings Framework Providers
///
/// This file provides Riverpod integration for the settings framework.
/// It creates providers for all settings defined in settings_definitions.dart.
///
/// Usage:
/// ```dart
/// // Initialize in main.dart
/// final settingsProviders = await initializeAdatiSettings();
///
/// // Use in widgets
/// final themeMode = ref.watch(settingsProviders.provider(themeModeSettingDef));
/// ```
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart';
import '../settings_definitions.dart';

// =============================================================================
// GLOBAL PROVIDERS
// =============================================================================

/// Provider for the settings controller.
/// Override this in your ProviderScope.
final adatiSettingsControllerProvider = Provider<SettingsController>((ref) {
  throw UnimplementedError(
    'adatiSettingsControllerProvider must be overridden. '
    'Call initializeAdatiSettings() and add override to ProviderScope.',
  );
});

/// Provider for the search index.
final adatiSettingsSearchIndexProvider = Provider<SearchIndex>((ref) {
  throw UnimplementedError(
    'adatiSettingsSearchIndexProvider must be overridden. '
    'Call initializeAdatiSettings() and add override to ProviderScope.',
  );
});

/// Provider for the settings providers container.
final adatiSettingsProvider = Provider<SettingsProviders>((ref) {
  throw UnimplementedError(
    'adatiSettingsProvider must be overridden. '
    'Call initializeAdatiSettings() and add override to ProviderScope.',
  );
});

// =============================================================================
// INITIALIZATION
// =============================================================================

/// Initialize the Adati settings framework.
///
/// Call this in main.dart before runApp:
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await EasyLocalization.ensureInitialized();
///
///   final settings = await initializeAdatiSettings();
///
///   runApp(
///     EasyLocalization(
///       supportedLocales: [...],
///       path: 'assets/translations',
///       child: ProviderScope(
///         overrides: [
///           adatiSettingsControllerProvider.overrideWithValue(settings.controller),
///           adatiSettingsSearchIndexProvider.overrideWithValue(settings.searchIndex),
///           adatiSettingsProvider.overrideWithValue(settings),
///         ],
///         child: const AdatiApp(),
///       ),
///     ),
///   );
/// }
/// ```
Future<SettingsProviders> initializeAdatiSettings({
  BuildContext? context,
}) async {
  final registry = createAdatiSettingsRegistry();
  final storage = SharedPreferencesStorage();

  LocalizationProvider? localizationProvider;
  if (context != null) {
    localizationProvider = AdatiLocalizationProvider(context);
  }

  return initializeSettings(
    registry: registry,
    storage: storage,
    localizationProvider: localizationProvider,
  );
}

/// Adati-specific localization provider using easy_localization.
class AdatiLocalizationProvider implements LocalizationProvider {
  /// Create a localization provider for Adati.
  AdatiLocalizationProvider(BuildContext context);

  @override
  List<Locale> get supportedLocales => [
        const Locale('en'),
        const Locale('ar'),
      ];

  @override
  String translate(String key, {required Locale locale}) {
    // Try to translate using easy_localization
    try {
      return key.tr();
    } catch (_) {
      return key;
    }
  }

  @override
  bool get isReady => true;
}

// =============================================================================
// CONVENIENCE PROVIDERS FOR COMMON SETTINGS
// =============================================================================

/// Theme mode provider using new framework.
final themeModeSettingProvider = Provider<String>((ref) {
  final settings = ref.watch(adatiSettingsProvider);
  return ref.watch(settings.provider(themeModeSettingDef));
});

/// Language setting provider.
final languageSettingProvider = Provider<String>((ref) {
  final settings = ref.watch(adatiSettingsProvider);
  return ref.watch(settings.provider(languageSettingDef));
});

/// Theme color provider.
final themeColorSettingProvider = Provider<int>((ref) {
  final settings = ref.watch(adatiSettingsProvider);
  return ref.watch(settings.provider(themeColorSettingDef));
});

/// Timeline days provider.
final timelineDaysSettingProvider = Provider<int>((ref) {
  final settings = ref.watch(adatiSettingsProvider);
  return ref.watch(settings.provider(timelineDaysSettingDef));
});

/// Card elevation provider.
final cardElevationSettingProvider = Provider<double>((ref) {
  final settings = ref.watch(adatiSettingsProvider);
  return ref.watch(settings.provider(cardElevationSettingDef));
});

/// Card border radius provider.
final cardBorderRadiusSettingProvider = Provider<double>((ref) {
  final settings = ref.watch(adatiSettingsProvider);
  return ref.watch(settings.provider(cardBorderRadiusSettingDef));
});

/// Notifications enabled provider.
final notificationsEnabledSettingProvider = Provider<bool>((ref) {
  final settings = ref.watch(adatiSettingsProvider);
  return ref.watch(settings.provider(notificationsEnabledSettingDef));
});

/// Show descriptions provider.
final showDescriptionsSettingProvider = Provider<bool>((ref) {
  final settings = ref.watch(adatiSettingsProvider);
  return ref.watch(settings.provider(showDescriptionsSettingDef));
});

/// Habits layout mode provider.
final habitsLayoutModeSettingProvider = Provider<String>((ref) {
  final settings = ref.watch(adatiSettingsProvider);
  return ref.watch(settings.provider(habitsLayoutModeSettingDef));
});

/// Default view provider.
final defaultViewSettingProvider = Provider<String>((ref) {
  final settings = ref.watch(adatiSettingsProvider);
  return ref.watch(settings.provider(defaultViewSettingDef));
});

// =============================================================================
// SEARCH PROVIDER
// =============================================================================

/// Provider for searching settings.
final settingsSearchResultsProvider =
    Provider.family<List<SearchResult>, String>((ref, query) {
  if (query.isEmpty) return [];
  final index = ref.watch(adatiSettingsSearchIndexProvider);
  return index.search(query);
});

// =============================================================================
// HELPER EXTENSIONS
// =============================================================================

/// Extension for convenient setting access.
extension AdatiSettingsRef on WidgetRef {
  /// Get the settings providers container.
  SettingsProviders get settings => read(adatiSettingsProvider);

  /// Watch a setting value.
  T watchSetting<T>(SettingDefinition<T> setting) {
    return watch(settings.provider(setting));
  }

  /// Read a setting value without watching.
  T readSetting<T>(SettingDefinition<T> setting) {
    return read(settings.provider(setting));
  }

  /// Update a setting value.
  Future<bool> updateSetting<T>(SettingDefinition<T> setting, T value) {
    return read(settings.provider(setting).notifier).set(value);
  }

  /// Reset a setting to default.
  Future<bool> resetSetting<T>(SettingDefinition<T> setting) {
    return read(settings.provider(setting).notifier).reset();
  }
}

