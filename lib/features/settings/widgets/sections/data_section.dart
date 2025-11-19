import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings_section.dart';

/// Data Management settings section
class DataSectionContent extends ConsumerWidget {
  final Function(BuildContext, WidgetRef) showExportDialog;
  final Function(BuildContext, WidgetRef) showImportDialog;
  final Function(BuildContext, WidgetRef) showDatabaseStatsDialog;
  final Function(BuildContext, WidgetRef) optimizeDatabase;

  const DataSectionContent({
    super.key,
    required this.showExportDialog,
    required this.showImportDialog,
    required this.showDatabaseStatsDialog,
    required this.optimizeDatabase,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Export subsection
        SettingsSubsectionHeader(
          title: 'settings_section_data_export'.tr(),
          icon: Icons.file_download,
        ),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: Text('export_data'.tr()),
          subtitle: Text('export_habit_data_description'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showExportDialog(context, ref),
        ),
        // Import subsection
        SettingsSubsectionHeader(
          title: 'settings_section_data_import'.tr(),
          icon: Icons.file_upload,
        ),
        ListTile(
          leading: const Icon(Icons.file_upload),
          title: Text('import_data'.tr()),
          subtitle: Text('import_data_description'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showImportDialog(context, ref),
        ),
        // Database subsection
        SettingsSubsectionHeader(
          title: 'settings_section_data_database'.tr(),
          icon: Icons.storage,
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text('database_statistics'.tr()),
          subtitle: Text('view_database_stats'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showDatabaseStatsDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services),
          title: Text('optimize_database'.tr()),
          subtitle: Text('optimize_database_description'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => optimizeDatabase(context, ref),
        ),
      ],
    );
  }
}

