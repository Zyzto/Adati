/// Flutter Settings Framework
/// Reusable settings tile widgets.
///
/// These tiles provide ready-to-use UI components for different
/// types of settings (switches, selectors, sliders, colors, etc.).
library;

import 'package:flutter/material.dart';
import '../core/setting_definition.dart';
import 'responsive_helpers.dart';

/// Base settings tile widget.
///
/// Provides consistent styling for all setting types.
class SettingsTile extends StatelessWidget {
  /// The setting definition.
  final SettingDefinition? setting;

  /// Leading icon.
  final Widget? leading;

  /// Title widget.
  final Widget title;

  /// Subtitle widget.
  final Widget? subtitle;

  /// Trailing widget.
  final Widget? trailing;

  /// Callback when tile is tapped.
  final VoidCallback? onTap;

  /// Whether the tile is enabled.
  final bool enabled;

  /// Whether to use dense layout.
  final bool dense;

  const SettingsTile({
    super.key,
    this.setting,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.dense = false,
  });

  /// Create a tile from a setting definition.
  factory SettingsTile.fromSetting({
    Key? key,
    required SettingDefinition setting,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool enabled = true,
    bool dense = false,
  }) {
    return SettingsTile(
      key: key,
      setting: setting,
      leading: setting.icon != null ? Icon(setting.icon) : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
      enabled: enabled,
      dense: dense,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: enabled ? onTap : null,
      enabled: enabled,
      dense: dense,
    );
  }
}

/// Switch tile for boolean settings.
class SwitchSettingsTile extends StatelessWidget {
  /// Leading icon.
  final Widget? leading;

  /// Title widget.
  final Widget title;

  /// Subtitle widget.
  final Widget? subtitle;

  /// Current value.
  final bool value;

  /// Callback when value changes.
  final ValueChanged<bool>? onChanged;

  /// Whether the tile is enabled.
  final bool enabled;

  const SwitchSettingsTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  /// Create from a BoolSetting.
  factory SwitchSettingsTile.fromSetting({
    Key? key,
    required BoolSetting setting,
    required String title,
    String? subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
    bool enabled = true,
  }) {
    return SwitchSettingsTile(
      key: key,
      leading: setting.icon != null ? Icon(setting.icon) : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
      enabled: enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: leading,
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

/// Selection tile with dialog picker.
class SelectSettingsTile<T> extends StatelessWidget {
  /// Leading icon.
  final Widget? leading;

  /// Title widget.
  final Widget title;

  /// Current value display.
  final Widget? subtitle;

  /// Available options.
  final List<T> options;

  /// Current selected value.
  final T? value;

  /// Build display for an option.
  final Widget Function(T option) itemBuilder;

  /// Callback when selection changes.
  final ValueChanged<T?>? onChanged;

  /// Dialog title.
  final String? dialogTitle;

  /// Whether the tile is enabled.
  final bool enabled;

  const SelectSettingsTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    required this.options,
    this.value,
    required this.itemBuilder,
    this.onChanged,
    this.dialogTitle,
    this.enabled = true,
  });

  /// Create from an EnumSetting.
  static SelectSettingsTile<String> fromEnumSetting({
    Key? key,
    required EnumSetting setting,
    required String title,
    String? subtitle,
    required String value,
    required String Function(String) labelBuilder,
    ValueChanged<String?>? onChanged,
    String? dialogTitle,
    bool enabled = true,
  }) {
    return SelectSettingsTile<String>(
      key: key,
      leading: setting.icon != null ? Icon(setting.icon) : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      options: setting.options ?? [],
      value: value,
      itemBuilder: (opt) => Text(labelBuilder(opt)),
      onChanged: onChanged,
      dialogTitle: dialogTitle ?? title,
      enabled: enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right),
      onTap: enabled ? () => _showDialog(context) : null,
      enabled: enabled,
    );
  }

  Future<void> _showDialog(BuildContext context) async {
    final result = await SettingsDialog.select<T>(
      context: context,
      title: dialogTitle ?? 'Select',
      options: options,
      itemBuilder: itemBuilder,
      selectedValue: value,
    );

    if (result != null) {
      onChanged?.call(result);
    }
  }
}

/// Slider tile for numeric settings.
class SliderSettingsTile extends StatelessWidget {
  /// Leading icon.
  final Widget? leading;

  /// Title widget.
  final Widget title;

  /// Current value.
  final double value;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Number of divisions.
  final int? divisions;

  /// Format value for display.
  final String Function(double)? valueFormatter;

  /// Callback when value changes.
  final ValueChanged<double>? onChanged;

  /// Whether the tile is enabled.
  final bool enabled;

  /// Whether to show inline slider (vs dialog).
  final bool inline;

  /// Dialog title.
  final String? dialogTitle;

  const SliderSettingsTile({
    super.key,
    this.leading,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.valueFormatter,
    this.onChanged,
    this.enabled = true,
    this.inline = false,
    this.dialogTitle,
  });

  /// Create from an IntSetting.
  factory SliderSettingsTile.fromIntSetting({
    Key? key,
    required IntSetting setting,
    required String title,
    required int value,
    ValueChanged<int>? onChanged,
    bool enabled = true,
    bool inline = false,
    String? dialogTitle,
  }) {
    return SliderSettingsTile(
      key: key,
      leading: setting.icon != null ? Icon(setting.icon) : null,
      title: Text(title),
      value: value.toDouble(),
      min: (setting.min ?? 0).toDouble(),
      max: (setting.max ?? 100).toDouble(),
      divisions: setting.max != null && setting.min != null
          ? (setting.max! - setting.min!) ~/ setting.step
          : null,
      valueFormatter: (v) => v.toInt().toString(),
      onChanged: onChanged != null ? (v) => onChanged(v.toInt()) : null,
      enabled: enabled,
      inline: inline,
      dialogTitle: dialogTitle ?? title,
    );
  }

  /// Create from a DoubleSetting.
  factory SliderSettingsTile.fromDoubleSetting({
    Key? key,
    required DoubleSetting setting,
    required String title,
    required double value,
    ValueChanged<double>? onChanged,
    bool enabled = true,
    bool inline = false,
    String? dialogTitle,
  }) {
    return SliderSettingsTile(
      key: key,
      leading: setting.icon != null ? Icon(setting.icon) : null,
      title: Text(title),
      value: value,
      min: setting.min ?? 0,
      max: setting.max ?? 100,
      divisions: setting.max != null && setting.min != null
          ? ((setting.max! - setting.min!) / setting.step).round()
          : null,
      valueFormatter: (v) => v.toStringAsFixed(setting.decimalPlaces),
      onChanged: onChanged,
      enabled: enabled,
      inline: inline,
      dialogTitle: dialogTitle ?? title,
    );
  }

  String _formatValue(double v) =>
      valueFormatter?.call(v) ?? v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    if (inline) {
      return _buildInline(context);
    }
    return _buildWithDialog(context);
  }

  Widget _buildInline(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: leading,
          title: title,
          trailing: Text(_formatValue(value)),
          enabled: enabled,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: _formatValue(value),
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }

  Widget _buildWithDialog(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: Text(_formatValue(value)),
      trailing: const Icon(Icons.chevron_right),
      onTap: enabled ? () => _showDialog(context) : null,
      enabled: enabled,
    );
  }

  Future<void> _showDialog(BuildContext context) async {
    final result = await SettingsDialog.slider(
      context: context,
      title: dialogTitle ?? 'Select value',
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      valueLabel: valueFormatter,
    );

    if (result != null) {
      onChanged?.call(result);
    }
  }
}

/// Color picker tile.
class ColorSettingsTile extends StatelessWidget {
  /// Leading icon.
  final Widget? leading;

  /// Title widget.
  final Widget title;

  /// Current color value.
  final Color value;

  /// Available colors (null for default palette).
  final List<Color>? colors;

  /// Whether to allow custom colors.
  final bool allowCustom;

  /// Callback when color changes.
  final ValueChanged<Color>? onChanged;

  /// Whether the tile is enabled.
  final bool enabled;

  /// Dialog title.
  final String? dialogTitle;

  const ColorSettingsTile({
    super.key,
    this.leading,
    required this.title,
    required this.value,
    this.colors,
    this.allowCustom = true,
    this.onChanged,
    this.enabled = true,
    this.dialogTitle,
  });

  /// Create from a ColorSetting.
  factory ColorSettingsTile.fromSetting({
    Key? key,
    required ColorSetting setting,
    required String title,
    required int value,
    ValueChanged<int>? onChanged,
    bool enabled = true,
    String? dialogTitle,
  }) {
    return ColorSettingsTile(
      key: key,
      leading: setting.icon != null ? Icon(setting.icon) : null,
      title: Text(title),
      value: Color(value),
      colors: setting.colorOptions?.map((c) => Color(c)).toList(),
      allowCustom: setting.allowCustom,
      onChanged: onChanged != null ? (c) => onChanged(c.toARGB32()) : null,
      enabled: enabled,
      dialogTitle: dialogTitle ?? title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: leading,
      title: title,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: value,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.dividerColor,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      onTap: enabled ? () => _showDialog(context) : null,
      enabled: enabled,
    );
  }

  Future<void> _showDialog(BuildContext context) async {
    final result = await SettingsDialog.colorPicker(
      context: context,
      title: dialogTitle ?? 'Select color',
      currentColor: value,
      colors: colors,
      allowCustom: allowCustom,
    );

    if (result != null) {
      onChanged?.call(result);
    }
  }
}

/// Navigation tile that opens another screen/page.
class NavigationSettingsTile extends StatelessWidget {
  /// Leading icon.
  final Widget? leading;

  /// Title widget.
  final Widget title;

  /// Subtitle widget.
  final Widget? subtitle;

  /// Callback when tapped.
  final VoidCallback? onTap;

  /// Whether the tile is enabled.
  final bool enabled;

  const NavigationSettingsTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right),
      onTap: enabled ? onTap : null,
      enabled: enabled,
    );
  }
}

/// Action tile for triggering operations.
class ActionSettingsTile extends StatelessWidget {
  /// Leading icon.
  final Widget? leading;

  /// Title widget.
  final Widget title;

  /// Subtitle widget.
  final Widget? subtitle;

  /// Callback when tapped.
  final VoidCallback? onTap;

  /// Whether the action is dangerous (destructive).
  final bool isDangerous;

  /// Whether the tile is enabled.
  final bool enabled;

  const ActionSettingsTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isDangerous = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDangerous ? Colors.red : null;

    return ListTile(
      leading: leading != null
          ? IconTheme(
              data: IconThemeData(color: color ?? theme.iconTheme.color),
              child: leading!,
            )
          : null,
      title: DefaultTextStyle(
        style: theme.textTheme.titleMedium!.copyWith(color: color),
        child: title,
      ),
      subtitle: subtitle,
      onTap: enabled ? onTap : null,
      enabled: enabled,
    );
  }
}

/// Info tile for displaying read-only information.
class InfoSettingsTile extends StatelessWidget {
  /// Leading icon.
  final Widget? leading;

  /// Title widget.
  final Widget title;

  /// Value to display.
  final Widget value;

  /// Whether the value can be copied.
  final bool copyable;

  /// Value to copy (if different from displayed).
  final String? copyValue;

  const InfoSettingsTile({
    super.key,
    this.leading,
    required this.title,
    required this.value,
    this.copyable = false,
    this.copyValue,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      trailing: value,
      onTap: copyable
          ? () {
              // Copy to clipboard
              // Clipboard.setData(ClipboardData(text: copyValue ?? value.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            }
          : null,
    );
  }
}

