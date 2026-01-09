/// Flutter Settings Framework
/// Riverpod adapter for reactive settings management.
///
/// This adapter integrates the settings framework with Riverpod,
/// providing reactive providers for each setting.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/setting_definition.dart';
import '../core/settings_controller.dart';
import '../core/settings_registry.dart';
import '../core/settings_storage.dart';
import '../core/search_index.dart';

/// Provider for the settings controller.
///
/// This must be overridden in your app to provide the actual controller:
/// ```dart
/// final settingsControllerProvider = Provider<SettingsController>((ref) {
///   throw UnimplementedError('Override this provider');
/// });
/// ```
///
/// Or use [createSettingsProviders] to generate all providers at once.
final settingsControllerProvider = Provider<SettingsController>((ref) {
  throw UnimplementedError(
    'settingsControllerProvider must be overridden. '
    'Use createSettingsProviders() or override manually.',
  );
});

/// Provider for the search index.
final settingsSearchIndexProvider = Provider<SearchIndex>((ref) {
  throw UnimplementedError(
    'settingsSearchIndexProvider must be overridden. '
    'Use createSettingsProviders() or override manually.',
  );
});

/// Notifier for a single setting value.
///
/// This notifier wraps a [SettingDefinition] and provides reactive
/// access to its value through Riverpod.
class SettingNotifier<T> extends Notifier<T> {
  final SettingDefinition<T> setting;
  final SettingsController Function() getController;
  StreamSubscription? _subscription;

  SettingNotifier({required this.setting, required this.getController});

  @override
  T build() {
    // Subscribe to changes
    _subscription?.cancel();
    _subscription = getController().stream(setting).listen((value) {
      state = value;
    });

    // Clean up on dispose
    ref.onDispose(() {
      _subscription?.cancel();
    });

    return getController().get(setting);
  }

  /// Set the setting value.
  Future<bool> set(T value) async {
    final success = await getController().set(setting, value);
    if (success) {
      state = value;
    }
    return success;
  }

  /// Reset to default value.
  Future<bool> reset() async {
    return set(setting.defaultValue);
  }
}

/// Type alias for a setting provider.
typedef SettingProvider<T> = NotifierProvider<SettingNotifier<T>, T>;

/// Creates a provider for a single setting.
///
/// Example:
/// ```dart
/// final themeProvider = createSettingProvider(themeModeSetting);
///
/// // In a widget:
/// final theme = ref.watch(themeProvider);
/// ref.read(themeProvider.notifier).set('dark');
/// ```
NotifierProvider<SettingNotifier<T>, T> createSettingProvider<T>(
  SettingDefinition<T> setting,
  SettingsController Function() getController,
) {
  return NotifierProvider<SettingNotifier<T>, T>(() {
    return SettingNotifier<T>(setting: setting, getController: getController);
  });
}

/// Settings providers container.
///
/// This class holds all the providers for a settings registry.
/// It provides a convenient way to access setting providers by definition.
class SettingsProviders {
  final SettingsController controller;
  final SettingsRegistry registry;
  final SearchIndex searchIndex;
  final Map<String, Object> _providers = {};

  /// Provider for undo availability.
  late final StreamProvider<bool> canUndoProvider;

  SettingsProviders._({
    required this.controller,
    required this.registry,
    required this.searchIndex,
  }) {
    canUndoProvider = StreamProvider<bool>((ref) {
      // Create a stream that emits initial value then continues with updates
      return _createUndoStream();
    });
  }

  /// Create a stream that starts with current canUndo value.
  Stream<bool> _createUndoStream() async* {
    // Emit initial value
    yield controller.canUndo;
    // Then forward all stream updates
    await for (final value in controller.canUndoStream) {
      yield value;
    }
  }

  /// Get or create a provider for a setting.
  NotifierProvider<SettingNotifier<T>, T> provider<T>(
    SettingDefinition<T> setting,
  ) {
    // Always create a new provider with the correct type to avoid type mismatches
    // The provider is lightweight and Riverpod will handle caching internally
    return createSettingProvider<T>(setting, () => controller);
  }

  /// Get a provider by key.
  Object? providerByKey(String key) => _providers[key];

  /// Check if a provider exists for a setting.
  bool hasProvider(String key) => _providers.containsKey(key);

  /// Whether there are changes that can be undone.
  bool get canUndo => controller.canUndo;

  /// Undo the last setting change.
  Future<bool> undo() => controller.undo();

  /// Clear the undo history.
  void clearUndoHistory() => controller.clearUndoHistory();
}

/// Initialize the settings framework for Riverpod.
///
/// Returns a [SettingsProviders] instance containing all providers.
///
/// Example:
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   final settings = await initializeSettings(
///     registry: myRegistry,
///     storage: SharedPreferencesStorage(),
///   );
///
///   runApp(
///     ProviderScope(
///       overrides: [
///         settingsControllerProvider.overrideWithValue(settings.controller),
///         settingsSearchIndexProvider.overrideWithValue(settings.searchIndex),
///       ],
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
Future<SettingsProviders> initializeSettings({
  required SettingsRegistry registry,
  required SettingsStorage storage,
  LocalizationProvider? localizationProvider,
}) async {
  // Initialize storage
  await storage.init();

  // Create controller
  final controller = SettingsController(registry: registry, storage: storage);
  await controller.init();

  // Create search index
  final searchIndex = SearchIndex(
    registry: registry,
    localizationProvider: localizationProvider,
  );
  await searchIndex.build();

  return SettingsProviders._(
    controller: controller,
    registry: registry,
    searchIndex: searchIndex,
  );
}

/// Extension methods for convenient access to settings in widgets.
extension SettingsRefExtension on WidgetRef {
  /// Watch a setting value.
  T watchSetting<T>(SettingsProviders settings, SettingDefinition<T> setting) {
    return watch(settings.provider(setting));
  }

  /// Read a setting value (without watching).
  T readSetting<T>(SettingsProviders settings, SettingDefinition<T> setting) {
    return read(settings.provider(setting));
  }

  /// Update a setting value.
  Future<bool> updateSetting<T>(
    SettingsProviders settings,
    SettingDefinition<T> setting,
    T value,
  ) {
    return read(settings.provider(setting).notifier).set(value);
  }

  /// Reset a setting to its default value.
  Future<bool> resetSetting<T>(
    SettingsProviders settings,
    SettingDefinition<T> setting,
  ) {
    return read(settings.provider(setting).notifier).reset();
  }
}

/// Provider for search results.
///
/// Use this with a family provider for the search query:
/// ```dart
/// final settingsSearchProvider = Provider.family<List<SearchResult>, String>((ref, query) {
///   final index = ref.watch(settingsSearchIndexProvider);
///   return index.search(query);
/// });
/// ```
Provider<List<SearchResult>> createSearchProvider(
  SearchIndex searchIndex,
  String query,
) {
  return Provider<List<SearchResult>>((ref) {
    if (query.isEmpty) return [];
    return searchIndex.search(query);
  });
}

/// Creates an auto-dispose provider for a setting.
///
/// Use this for settings that are only accessed in specific screens
/// and don't need to persist in memory.
///
/// Note: This uses a regular NotifierProvider. For true auto-dispose behavior,
/// consider using ref.keepAlive() selectively in your notifiers.
NotifierProvider<SettingNotifier<T>, T> createAutoDisposeSettingProvider<T>(
  SettingDefinition<T> setting,
  SettingsController Function() getController,
) {
  return createSettingProvider(setting, getController);
}

/// Helper class for bulk provider creation.
///
/// Use this when you have many settings and want to create providers
/// for all of them at once:
/// ```dart
/// final providers = SettingsProviderFactory(controller);
///
/// // Create providers for specific settings
/// final themeProvider = providers.create(themeModeSetting);
/// final languageProvider = providers.create(languageSetting);
/// ```
class SettingsProviderFactory {
  final SettingsController controller;
  final Map<String, Object> _cache = {};

  SettingsProviderFactory(this.controller);

  /// Create a provider for a setting.
  NotifierProvider<SettingNotifier<T>, T> create<T>(
    SettingDefinition<T> setting,
  ) {
    return _cache.putIfAbsent(
          setting.key,
          () => createSettingProvider(setting, () => controller),
        )
        as NotifierProvider<SettingNotifier<T>, T>;
  }

  /// Create an auto-dispose provider for a setting.
  NotifierProvider<SettingNotifier<T>, T> createAutoDispose<T>(
    SettingDefinition<T> setting,
  ) {
    return createAutoDisposeSettingProvider(setting, () => controller);
  }
}
