import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper class for creating settings dialogs
class SettingsDialogs {
  /// Shows a slider dialog for numeric values
  static void showSliderDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required double currentValue,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) valueFormatter,
    required Future<void> Function(double) onChanged,
    required dynamic provider,
  }) {
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          double value = currentValue;
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(valueFormatter(value)),
                Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: (newValue) {
                    setDialogState(() {
                      value = newValue;
                    });
                    onChanged(newValue);
                    ref.invalidate(provider);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(),
                child: Text('done'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Shows a radio list dialog for selecting one option from a list
  static Future<T?> showRadioDialog<T>({
    required BuildContext context,
    required String title,
    required T currentValue,
    required List<RadioOption<T>> options,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) {
        T tempValue = currentValue;
        return AlertDialog(
          title: Text(title),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((option) {
                  return RadioListTile<T>(
                    title: Text(option.label),
                    subtitle: option.subtitle != null
                        ? Text(option.subtitle!)
                        : null,
                    value: option.value,
                    groupValue: tempValue,
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          tempValue = value;
                        });
                      }
                    },
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempValue),
              child: Text('ok'.tr()),
            ),
          ],
        );
      },
    );
  }

  /// Shows a color picker dialog
  static Future<Color?> showColorPickerDialog({
    required BuildContext context,
    required String title,
    required Color currentColor,
  }) {
    // This is a placeholder - you would integrate with a color picker package
    return showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: const Text('Color picker not yet implemented'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
          ],
        );
      },
    );
  }

  /// Creates a custom radio list item widget
  static Widget buildRadioListItem<T>({
    required BuildContext context,
    required Widget title,
    Widget? subtitle,
    required T value,
    required T? groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    final isSelected = value == groupValue;
    final theme = Theme.of(context);
    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Material(
          shape: const CircleBorder(),
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onChanged(value),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  width: 2,
                ),
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
            ),
          ),
        ),
      ),
      onTap: () => onChanged(value),
    );
  }
}

/// Model for radio dialog options
class RadioOption<T> {
  final String label;
  final String? subtitle;
  final T value;

  const RadioOption({
    required this.label,
    this.subtitle,
    required this.value,
  });
}

