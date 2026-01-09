import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create settings registry
  final registry = createExampleRegistry();

  // Initialize settings framework
  final settings = await initializeSettings(
    registry: registry,
    storage: SharedPreferencesStorage(),
  );

  runApp(
    ProviderScope(
      overrides: [
        settingsControllerProvider.overrideWithValue(settings.controller),
        settingsSearchIndexProvider.overrideWithValue(settings.searchIndex),
      ],
      child: MyApp(settings: settings),
    ),
  );
}

// =============================================================================
// SETTING DEFINITIONS
// =============================================================================

/// General settings section
const generalSection = SettingSection(
  key: 'general',
  titleKey: 'General',
  icon: Icons.settings,
  order: 0,
);

/// Appearance settings section
const appearanceSection = SettingSection(
  key: 'appearance',
  titleKey: 'Appearance',
  icon: Icons.palette,
  order: 1,
);

/// Theme mode setting
const themeModeSetting = EnumSetting(
  'theme_mode',
  defaultValue: 'system',
  titleKey: 'Theme Mode',
  options: ['system', 'light', 'dark'],
  section: 'general',
  searchTerms: {
    'en': ['theme', 'dark', 'light', 'mode', 'appearance'],
  },
);

/// Notifications setting
const notificationsSetting = BoolSetting(
  'notifications_enabled',
  defaultValue: true,
  titleKey: 'Enable Notifications',
  icon: Icons.notifications,
  section: 'general',
  searchTerms: {
    'en': ['notifications', 'alerts', 'notify'],
  },
);

/// Theme color setting
const themeColorSetting = ColorSetting(
  'theme_color',
  defaultValue: 0xFF6200EE,
  titleKey: 'Theme Color',
  section: 'appearance',
  searchTerms: {
    'en': ['color', 'theme', 'accent'],
  },
);

/// Card elevation setting
const cardElevationSetting = DoubleSetting(
  'card_elevation',
  defaultValue: 2.0,
  min: 0.0,
  max: 8.0,
  step: 0.5,
  titleKey: 'Card Elevation',
  section: 'appearance',
  searchTerms: {
    'en': ['elevation', 'shadow', 'card'],
  },
);

/// Font size scale setting
const fontSizeScaleSetting = EnumSetting(
  'font_size_scale',
  defaultValue: 'normal',
  titleKey: 'Font Size',
  options: ['small', 'normal', 'large', 'extra_large'],
  section: 'appearance',
  searchTerms: {
    'en': ['font', 'size', 'text', 'scale'],
  },
);

/// Create the settings registry
SettingsRegistry createExampleRegistry() {
  return SettingsRegistry.withSettings(
    sections: [generalSection, appearanceSection],
    settings: [
      themeModeSetting,
      notificationsSetting,
      themeColorSetting,
      cardElevationSetting,
      fontSizeScaleSetting,
    ],
  );
}

// =============================================================================
// APP
// =============================================================================

class MyApp extends ConsumerWidget {
  final SettingsProviders settings;

  const MyApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode setting
    final themeModeStr = ref.watch(settings.provider(themeModeSetting));
    final themeMode = _parseThemeMode(themeModeStr);

    return MaterialApp(
      title: 'Settings Framework Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      home: SettingsExamplePage(settings: settings),
    );
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

// =============================================================================
// SETTINGS PAGE
// =============================================================================

class SettingsExamplePage extends ConsumerStatefulWidget {
  final SettingsProviders settings;

  const SettingsExamplePage({super.key, required this.settings});

  @override
  ConsumerState<SettingsExamplePage> createState() =>
      _SettingsExamplePageState();
}

class _SettingsExamplePageState extends ConsumerState<SettingsExamplePage> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = widget.settings.searchIndex.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings Framework Example'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search settings...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _performSearch,
                autofocus: true,
              ),
            ),
          Expanded(
            child: _isSearching && _searchResults.isNotEmpty
                ? _buildSearchResults()
                : _buildSettingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(result.setting.titleKey),
            subtitle: Text('Match: "${result.matchedTerm}" (score: ${result.score.toStringAsFixed(2)})'),
            trailing: _buildSettingValue(result.setting),
          ),
        );
      },
    );
  }

  Widget _buildSettingsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // General Section
        _buildSectionHeader('General'),
        const SizedBox(height: 8),
        _buildSettingTile(themeModeSetting),
        _buildSettingTile(notificationsSetting),
        const SizedBox(height: 24),

        // Appearance Section
        _buildSectionHeader('Appearance'),
        const SizedBox(height: 8),
        _buildSettingTile(themeColorSetting),
        _buildSettingTile(cardElevationSetting),
        _buildSettingTile(fontSizeScaleSetting),
        const SizedBox(height: 24),

        // Current Values Display
        _buildSectionHeader('Current Values'),
        const SizedBox(height: 8),
        _buildValueCard('Theme Mode', ref.watch(widget.settings.provider(themeModeSetting))),
        _buildValueCard('Notifications', ref.watch(widget.settings.provider(notificationsSetting)).toString()),
        _buildValueCard('Theme Color', '#${ref.watch(widget.settings.provider(themeColorSetting)).toRadixString(16).toUpperCase()}'),
        _buildValueCard('Card Elevation', ref.watch(widget.settings.provider(cardElevationSetting)).toString()),
        _buildValueCard('Font Size', ref.watch(widget.settings.provider(fontSizeScaleSetting))),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSettingTile(SettingDefinition setting) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: _buildSettingContent(setting),
    );
  }

  Widget _buildSettingContent(SettingDefinition setting) {
    if (setting is BoolSetting) {
      return SwitchSettingsTile.fromSetting(
        setting: setting,
        title: setting.titleKey,
        value: ref.watch(widget.settings.provider(setting)),
        onChanged: (value) {
          ref.read(widget.settings.provider(setting).notifier).set(value);
        },
      );
    } else if (setting is EnumSetting) {
      return SelectSettingsTile.fromEnumSetting(
        setting: setting,
        title: setting.titleKey,
        value: ref.watch(widget.settings.provider(setting)),
        labelBuilder: (opt) => opt.replaceAll('_', ' ').toUpperCase(),
        onChanged: (value) {
          if (value != null) {
            ref.read(widget.settings.provider(setting).notifier).set(value);
          }
        },
      );
    } else if (setting is ColorSetting) {
      return ColorSettingsTile.fromSetting(
        setting: setting,
        title: setting.titleKey,
        value: ref.watch(widget.settings.provider(setting)),
        onChanged: (value) {
          ref.read(widget.settings.provider(setting).notifier).set(value);
        },
      );
    } else if (setting is DoubleSetting) {
      return SliderSettingsTile.fromDoubleSetting(
        setting: setting,
        title: setting.titleKey,
        value: ref.watch(widget.settings.provider(setting)),
        onChanged: (value) {
          ref.read(widget.settings.provider(setting).notifier).set(value);
        },
      );
    } else {
      return ListTile(
        title: Text(setting.titleKey),
        subtitle: Text(_buildSettingValue(setting).toString()),
      );
    }
  }

  Widget _buildSettingValue(SettingDefinition setting) {
    if (setting is BoolSetting) {
      final value = ref.watch(widget.settings.provider(setting));
      return Text(value.toString());
    } else if (setting is EnumSetting) {
      final value = ref.watch(widget.settings.provider(setting));
      return Text(value);
    } else if (setting is ColorSetting) {
      final color = ref.watch(widget.settings.provider(setting));
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Color(color),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      );
    } else if (setting is DoubleSetting) {
      final value = ref.watch(widget.settings.provider(setting));
      return Text(value.toStringAsFixed(1));
    }
    return const SizedBox.shrink();
  }

  Widget _buildValueCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
