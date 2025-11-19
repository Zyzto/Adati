import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Advanced settings section (reset, clear data, logs)
class AdvancedSectionContent extends ConsumerWidget {
  final Function(BuildContext, WidgetRef) showResetHabitsDialog;
  final Function(BuildContext, WidgetRef) showResetSettingsDialog;
  final Function(BuildContext, WidgetRef) showClearAllDataDialog;
  final Function(BuildContext, WidgetRef) showLogsDialog;
  final Function(BuildContext) returnToOnboarding;

  const AdvancedSectionContent({
    super.key,
    required this.showResetHabitsDialog,
    required this.showResetSettingsDialog,
    required this.showClearAllDataDialog,
    required this.showLogsDialog,
    required this.returnToOnboarding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.delete_sweep),
          title: Text('reset_all_habits'.tr()),
          subtitle: Text('reset_all_habits_description'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showResetHabitsDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.settings_backup_restore),
          title: Text('reset_all_settings'.tr()),
          subtitle: Text('reset_all_settings_description'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showResetSettingsDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever),
          title: Text('clear_all_data'.tr()),
          subtitle: Text('clear_all_data_description'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showClearAllDataDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: Text('logs'.tr()),
          subtitle: Text('logs_description'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLogsDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.school),
          title: Text('return_to_onboarding'.tr()),
          subtitle: Text('return_to_onboarding_description'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => returnToOnboarding(context),
        ),
      ],
    );
  }
}

