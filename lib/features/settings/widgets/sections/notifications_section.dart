import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_providers.dart';

/// Notifications & Behavior settings section
class NotificationsSectionContent extends ConsumerWidget {
  final Function(BuildContext, WidgetRef) showBadHabitLogicModeDialog;

  const NotificationsSectionContent({
    super.key,
    required this.showBadHabitLogicModeDialog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final notificationsNotifier = ref.read(notificationsEnabledNotifierProvider);
    final badHabitLogicMode = ref.watch(badHabitLogicModeProvider);

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications),
          title: Text('enable_notifications'.tr()),
          subtitle: Text('receive_habit_reminders'.tr()),
          value: notificationsEnabled,
          onChanged: (value) async {
            await notificationsNotifier.setNotificationsEnabled(value);
            ref.invalidate(notificationsEnabledNotifierProvider);
          },
        ),
        ListTile(
          leading: const Icon(Icons.psychology),
          title: Text('bad_habit_logic_mode'.tr()),
          subtitle: Text(
            badHabitLogicMode == 'negative'
                ? 'bad_habit_logic_mode_negative'.tr()
                : 'bad_habit_logic_mode_positive'.tr(),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showBadHabitLogicModeDialog(context, ref),
        ),
      ],
    );
  }
}

