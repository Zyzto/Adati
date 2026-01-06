/// Flutter Settings Framework
///
/// A state-management agnostic settings framework for Flutter apps.
///
/// This framework provides:
/// - Declarative setting definitions with minimal boilerplate
/// - Multi-language search across all supported locales
/// - State management adapters (Riverpod, Provider, Bloc, etc.)
/// - Reusable UI components for settings pages
/// - Local storage via SharedPreferences (or custom backends)
///
/// ## Quick Start
///
/// 1. Define your settings:
/// ```dart
/// final themeMode = EnumSetting(
///   'theme_mode',
///   defaultValue: 'system',
///   titleKey: 'theme',
///   options: ['system', 'light', 'dark'],
///   searchTerms: {
///     'en': ['theme', 'dark', 'light', 'appearance'],
///     'ar': ['المظهر', 'داكن', 'فاتح'],
///   },
/// );
/// ```
///
/// 2. Create a registry:
/// ```dart
/// final registry = SettingsRegistry.withSettings(
///   sections: [generalSection, appearanceSection],
///   settings: [themeMode, language, ...],
/// );
/// ```
///
/// 3. Initialize with your state management:
/// ```dart
/// // With Riverpod
/// final settings = await initializeSettings(
///   registry: registry,
///   storage: SharedPreferencesStorage(),
/// );
///
/// runApp(
///   ProviderScope(
///     overrides: [...],
///     child: MyApp(),
///   ),
/// );
/// ```
///
/// 4. Use in widgets:
/// ```dart
/// final theme = ref.watch(settings.provider(themeMode));
/// ref.read(settings.provider(themeMode).notifier).set('dark');
/// ```
library;

// Core
export 'core/setting_definition.dart';
export 'core/settings_registry.dart';
export 'core/settings_storage.dart';
export 'core/settings_controller.dart';
export 'core/search_index.dart';

// Storage implementations
export 'storage/shared_preferences_storage.dart';

// Adapters
export 'adapters/riverpod_adapter.dart';

// UI Components
export 'ui/responsive_helpers.dart';
export 'ui/settings_tile.dart';
export 'ui/settings_section.dart';
export 'ui/snackbar_helper.dart';

// Localization
export 'localization/easy_localization_adapter.dart';

