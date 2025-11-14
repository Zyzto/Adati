import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/preferences_service.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  String _getLanguageName(String? code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLanguage = PreferencesService.getLanguage() ?? 'en';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: currentLanguage,
              onChanged: (value) async {
                if (value != null) {
                  await PreferencesService.setLanguage(value);
                  if (context.mounted) {
                    await context.setLocale(Locale(value));
                    Navigator.pop(context);
                  }
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('العربية'),
              value: 'ar',
              groupValue: currentLanguage,
              onChanged: (value) async {
                if (value != null) {
                  await PreferencesService.setLanguage(value);
                  if (context.mounted) {
                    await context.setLocale(Locale(value));
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeNotifierProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentTheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setThemeMode(value);
                  ref.invalidate(themeModeNotifierProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentTheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setThemeMode(value);
                  ref.invalidate(themeModeNotifierProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: currentTheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setThemeMode(value);
                  ref.invalidate(themeModeNotifierProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTimelineDaysDialog(BuildContext context, WidgetRef ref) {
    final currentDays = ref.watch(timelineDaysProvider);
    final notifier = ref.read(timelineDaysNotifierProvider);
    final controller = TextEditingController(text: currentDays.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timeline Days'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of days to show',
                hintText: 'Enter number of days',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final days = int.tryParse(controller.text);
              if (days != null && days > 0) {
                await notifier.setTimelineDays(days);
                ref.invalidate(timelineDaysNotifierProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = PreferencesService.getLanguage() ?? 'en';
    final themeMode = ref.watch(themeModeProvider);
    final timelineDays = ref.watch(timelineDaysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(_getLanguageName(currentLanguage)),
            onTap: () => _showLanguageDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Theme'),
            subtitle: Text(_getThemeName(themeMode)),
            onTap: () => _showThemeDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_view_week),
            title: const Text('Timeline Days'),
            subtitle: Text('$timelineDays days'),
            onTap: () => _showTimelineDaysDialog(context, ref),
          ),
        ],
      ),
    );
  }
}

