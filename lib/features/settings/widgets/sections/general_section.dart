import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_providers.dart';
import '../../utils/settings_formatters.dart';
import '../../../../core/services/preferences_service.dart';

/// General settings section widget
class GeneralSectionContent extends ConsumerWidget {
  final Function(BuildContext) showLanguageDialog;
  final Function(BuildContext, WidgetRef) showThemeDialog;
  final Function(BuildContext, WidgetRef) showThemeColorDialog;

  const GeneralSectionContent({
    super.key,
    required this.showLanguageDialog,
    required this.showThemeDialog,
    required this.showThemeColorDialog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = PreferencesService.getLanguage() ?? 'en';
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.language),
          title: Text('language'.tr()),
          subtitle: Text(SettingsFormatters.getLanguageName(currentLanguage)),
          onTap: () => showLanguageDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: Text('theme'.tr()),
          subtitle: Text(SettingsFormatters.getThemeName(themeMode)),
          onTap: () => showThemeDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: Text('select_theme_color'.tr()),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(themeColor),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
          ),
          onTap: () => showThemeColorDialog(context, ref),
        ),
      ],
    );
  }
}
