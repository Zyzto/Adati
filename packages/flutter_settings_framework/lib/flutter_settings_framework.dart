// Flutter Settings Framework
// A state-management agnostic settings framework for Flutter apps.
//
// See README.md for documentation and usage examples.

// Core
export 'src/core/setting_definition.dart';
export 'src/core/settings_registry.dart';
export 'src/core/settings_storage.dart';
export 'src/core/settings_controller.dart';
export 'src/core/search_index.dart';

// Storage implementations
export 'src/storage/shared_preferences_storage.dart';

// Adapters
export 'src/adapters/riverpod_adapter.dart';

// UI Components
export 'src/ui/responsive_helpers.dart';
export 'src/ui/settings_tile.dart';
export 'src/ui/settings_section.dart';
export 'src/ui/snackbar_helper.dart';

// Localization
export 'src/localization/easy_localization_adapter.dart';
