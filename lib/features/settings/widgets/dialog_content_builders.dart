import 'package:flutter/material.dart';
import 'responsive_dialog.dart';

/// Builders for dialog content that can be used in both modal and split-screen contexts
class DialogContentBuilders {
  /// Build a color grid picker content
  static Widget buildColorGridContent({
    required BuildContext context,
    required List<Color> colors,
    required int currentColor,
    required Function(int) onColorSelected,
    int? crossAxisCount,
  }) {
    final effectiveCrossAxisCount = crossAxisCount ??
        ResponsiveDialog.getGridCrossAxisCount(
          context,
          itemCount: colors.length,
        );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: effectiveCrossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final colorValue = color.toARGB32();
        final isSelected = colorValue == currentColor;
        return GestureDetector(
          onTap: () => onColorSelected(colorValue),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 3,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build a radio list content using RadioGroup (replaces deprecated groupValue)
  static Widget buildRadioListContent<T>({
    required BuildContext context,
    required List<RadioOption<T>> options,
    required T currentValue,
    required Function(T?) onChanged,
  }) {
    return RadioGroup<T>(
      groupValue: currentValue,
      onChanged: onChanged,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          return RadioListTile<T>(
            title: Text(option.label),
            subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
            value: option.value,
          );
        }).toList(),
      ),
    );
  }

  /// Build a slider content
  static Widget buildSliderContent({
    required BuildContext context,
    required double currentValue,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) valueFormatter,
    required Function(double) onChanged,
    required ValueNotifier<double> valueNotifier,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<double>(
          valueListenable: valueNotifier,
          builder: (context, value, _) {
            return Text(
              valueFormatter(value),
              style: Theme.of(context).textTheme.titleMedium,
            );
          },
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<double>(
          valueListenable: valueNotifier,
          builder: (context, value, _) {
            return Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (newValue) {
                valueNotifier.value = newValue;
                onChanged(newValue);
              },
            );
          },
        ),
      ],
    );
  }

  /// Build a text input content
  static Widget buildTextInputContent({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  /// Build a list of selectable items (for export/import options)
  static Widget buildSelectableListContent({
    required BuildContext context,
    required List<SelectableItem> items,
    required Function(String) onItemSelected,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) {
        return ListTile(
          leading: item.icon,
          title: Text(item.title),
          subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
          onTap: () => onItemSelected(item.value),
        );
      }).toList(),
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

/// Model for selectable list items
class SelectableItem {
  final String value;
  final String title;
  final String? subtitle;
  final Widget? icon;

  const SelectableItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
  });
}

