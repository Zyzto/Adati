import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_providers.dart';
import '../../utils/settings_formatters.dart';

/// Date & Time settings section
class DateTimeSectionContent extends ConsumerWidget {
  final Function(BuildContext, WidgetRef) showDateFormatDialog;
  final Function(BuildContext, WidgetRef) showFirstDayOfWeekDialog;

  const DateTimeSectionContent({
    super.key,
    required this.showDateFormatDialog,
    required this.showFirstDayOfWeekDialog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = ref.watch(dateFormatProvider);
    final firstDayOfWeek = ref.watch(firstDayOfWeekProvider);

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text('date_format'.tr()),
          subtitle: Text(SettingsFormatters.getDateFormatName(dateFormat)),
          onTap: () => showDateFormatDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.view_week),
          title: Text('first_day_of_week'.tr()),
          subtitle: Text(SettingsFormatters.getFirstDayOfWeekName(firstDayOfWeek)),
          onTap: () => showFirstDayOfWeekDialog(context, ref),
        ),
      ],
    );
  }
}

