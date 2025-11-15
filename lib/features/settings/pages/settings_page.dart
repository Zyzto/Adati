import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animations/animations.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/database/app_database.dart' as db;
import '../providers/settings_providers.dart';
import '../../habits/widgets/checkbox_style_widget.dart';
import '../../habits/providers/habit_providers.dart';
import '../../habits/widgets/tag_management_widget.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  // Helper method to build radio list item
  Widget _buildRadioListItem<T>({
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

  // Default values
  static const double defaultCardElevation = 2.0;
  static const double defaultCardBorderRadius = 12.0;
  static const String defaultDaySquareSize = 'large';
  static const int defaultTimelineDays = 100;
  static const int defaultModalTimelineDays = 200;

  String _getLanguageName(String? code) {
    switch (code) {
      case 'en':
        return 'english'.tr();
      case 'ar':
        return 'arabic'.tr();
      default:
        return 'english'.tr();
    }
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light'.tr();
      case ThemeMode.dark:
        return 'dark'.tr();
      case ThemeMode.system:
        return 'system'.tr();
    }
  }

  String _getDaySquareSizeName(String size) {
    switch (size) {
      case 'small':
        return 'small'.tr();
      case 'medium':
        return 'medium'.tr();
      case 'large':
        return 'large'.tr();
      default:
        return 'medium'.tr();
    }
  }

  String _getDateFormatName(String format) {
    switch (format) {
      case 'yyyy-MM-dd':
        return 'YYYY-MM-DD';
      case 'MM/dd/yyyy':
        return 'MM/DD/YYYY';
      case 'dd/MM/yyyy':
        return 'DD/MM/YYYY';
      case 'dd.MM.yyyy':
        return 'DD.MM.YYYY';
      default:
        return format;
    }
  }

  String _getFirstDayOfWeekName(int day) {
    return day == 0 ? 'sunday'.tr() : 'monday'.tr();
  }

  Future<void> _showExportDialog(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(habitRepositoryProvider);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      // Fetch all data
      final habits = await repository.getAllHabits();
      final entries = <db.TrackingEntry>[];
      final streaks = <db.Streak>[];
      
      for (final habit in habits) {
        final habitEntries = await repository.getEntriesByHabit(habit.id);
        entries.addAll(habitEntries);
        
        final streak = await repository.getStreakByHabit(habit.id);
        if (streak != null) {
          streaks.add(streak);
        }
      }
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        
        // Show format selection
        final format = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('export_data'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: Text('export_as_csv'.tr()),
                  subtitle: Text('export_csv_description'.tr()),
                  onTap: () => Navigator.pop(context, 'csv'),
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: Text('export_as_json'.tr()),
                  subtitle: Text('export_json_description'.tr()),
                  onTap: () => Navigator.pop(context, 'json'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr()),
              ),
            ],
          ),
        );
        
        if (format != null && context.mounted) {
          String? filePath;
          if (format == 'csv') {
            filePath = await ExportService.exportToCSV(habits, entries, streaks);
          } else {
            filePath = await ExportService.exportToJSON(habits, entries, streaks);
          }
          
          if (context.mounted) {
            if (filePath != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('export_success'.tr()),
                  action: SnackBarAction(
                    label: 'ok'.tr(),
                    onPressed: () {},
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('export_cancelled'.tr()),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'export_error'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLanguage = PreferencesService.getLanguage() ?? 'en';
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('select_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('english'.tr()),
              value: 'en',
              groupValue: currentLanguage,
              onChanged: (value) async {
                if (value != null) {
                  await PreferencesService.setLanguage(value);
                  if (dialogContext.mounted) {
                    await dialogContext.setLocale(Locale(value));
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('arabic'.tr()),
              value: 'ar',
              groupValue: currentLanguage,
              onChanged: (value) async {
                if (value != null) {
                  await PreferencesService.setLanguage(value);
                  if (dialogContext.mounted) {
                    await dialogContext.setLocale(Locale(value));
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('select_theme'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<ThemeMode>(
              context: dialogContext,
              title: Text('light'.tr()),
              value: ThemeMode.light,
              groupValue: currentTheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setThemeMode(value);
                  ref.invalidate(themeModeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<ThemeMode>(
              context: dialogContext,
              title: Text('dark'.tr()),
              value: ThemeMode.dark,
              groupValue: currentTheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setThemeMode(value);
                  ref.invalidate(themeModeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<ThemeMode>(
              context: dialogContext,
              title: Text('system'.tr()),
              value: ThemeMode.system,
              groupValue: currentTheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setThemeMode(value);
                  ref.invalidate(themeModeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showThemeColorDialog(BuildContext context, WidgetRef ref) {
    final currentColor = ref.watch(themeColorProvider);
    final notifier = ref.read(themeColorNotifierProvider);
    final navigator = Navigator.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isLandscape = screenWidth > mediaQuery.size.height;
    final maxWidth = 600.0; // Same as settings list max width
    final contentWidth = isLandscape ? maxWidth : screenWidth * 0.5;
    final colors = [
      Colors.deepPurple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.brown,
      Colors.purple,
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('select_theme_color'.tr()),
        content: SizedBox(
          width: contentWidth,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              final colorValue = color.toARGB32();
              final isSelected = colorValue == currentColor;
              return GestureDetector(
                onTap: () async {
                  await notifier.setThemeColor(colorValue);
                  ref.invalidate(themeColorNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                },
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
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showCardStyleDialog(BuildContext context, WidgetRef ref) {
    final initialElevation = ref.watch(cardElevationProvider);
    final initialBorderRadius = ref.watch(cardBorderRadiusProvider);
    final cardStyleNotifier = ref.read(cardStyleNotifierProvider);

    showDialog(
      context: context,
      builder: (context) {
        return _CardStyleDialogContent(
          initialElevation: initialElevation,
          initialBorderRadius: initialBorderRadius,
          cardStyleNotifier: cardStyleNotifier,
          ref: ref,
        );
      },
    );
  }

  void _showDaySquareSizeDialog(BuildContext context, WidgetRef ref) {
    final currentSize = ref.watch(daySquareSizeProvider);
    final notifier = ref.read(daySquareSizeNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('day_square_size'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('small'.tr()),
              value: 'small',
              groupValue: currentSize,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setDaySquareSize(value);
                  ref.invalidate(daySquareSizeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('medium'.tr()),
              value: 'medium',
              groupValue: currentSize,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setDaySquareSize(value);
                  ref.invalidate(daySquareSizeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('large'.tr()),
              value: 'large',
              groupValue: currentSize,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setDaySquareSize(value);
                  ref.invalidate(daySquareSizeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDateFormatDialog(BuildContext context, WidgetRef ref) {
    final currentFormat = ref.watch(dateFormatProvider);
    final notifier = ref.read(dateFormatNotifierProvider);
    final navigator = Navigator.of(context);
    final formats = ['yyyy-MM-dd', 'MM/dd/yyyy', 'dd/MM/yyyy', 'dd.MM.yyyy'];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('date_format'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats.map((format) {
            return _buildRadioListItem<String>(
              context: dialogContext,
              title: Text(_getDateFormatName(format)),
              subtitle: Text(DateTime.now().toString().split(' ')[0]),
              value: format,
              groupValue: currentFormat,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setDateFormat(value);
                  ref.invalidate(dateFormatNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showFirstDayOfWeekDialog(BuildContext context, WidgetRef ref) {
    final currentDay = ref.watch(firstDayOfWeekProvider);
    final notifier = ref.read(firstDayOfWeekNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('first_day_of_week'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<int>(
              context: dialogContext,
              title: Text('sunday'.tr()),
              value: 0,
              groupValue: currentDay,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setFirstDayOfWeek(value);
                  ref.invalidate(firstDayOfWeekNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<int>(
              context: dialogContext,
              title: Text('monday'.tr()),
              value: 1,
              groupValue: currentDay,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setFirstDayOfWeek(value);
                  ref.invalidate(firstDayOfWeekNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showHabitCheckboxStyleDialog(BuildContext context, WidgetRef ref) {
    final currentStyle = ref.watch(habitCheckboxStyleProvider);
    final notifier = ref.read(habitCheckboxStyleNotifierProvider);
    final navigator = Navigator.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isLandscape = screenWidth > mediaQuery.size.height;
    final maxWidth = 600.0; // Same as settings list max width
    final contentWidth = isLandscape ? maxWidth : screenWidth * 0.5;

    final styles = HabitCheckboxStyle.values;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('habit_checkbox_style'.tr()),
        content: SizedBox(
          width: contentWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: styles.map((style) {
              final styleString = habitCheckboxStyleToString(style);
              return _buildRadioListItem<String>(
                context: dialogContext,
                title: Row(
                  children: [
                    Text(_getCheckboxStyleName(styleString)),
                    const SizedBox(width: 16),
                    // Preview: completed state
                    buildCheckboxWidget(style, true, 24, null),
                    const SizedBox(width: 8),
                    // Preview: uncompleted state
                    buildCheckboxWidget(style, false, 24, null),
                  ],
                ),
                value: styleString,
                groupValue: currentStyle,
                onChanged: (value) async {
                  if (value != null) {
                    await notifier.setHabitCheckboxStyle(value);
                    ref.invalidate(habitCheckboxStyleNotifierProvider);
                    if (dialogContext.mounted) {
                      navigator.pop();
                    }
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  String _getCheckboxStyleName(String style) {
    switch (style) {
      case 'square':
        return 'Square';
      case 'bordered':
        return 'Bordered';
      case 'circle':
        return 'Circle';
      case 'radio':
        return 'Radio';
      case 'task':
        return 'Task';
      case 'verified':
        return 'Verified';
      case 'taskAlt':
        return 'Task Alt';
      default:
        return style;
    }
  }

  Future<void> _revertCardStyle(BuildContext context, WidgetRef ref) async {
    final cardStyleNotifier = ref.read(cardStyleNotifierProvider);
    await cardStyleNotifier.setElevation(defaultCardElevation);
    await cardStyleNotifier.setBorderRadius(defaultCardBorderRadius);
    ref.invalidate(cardStyleNotifierProvider);
  }

  Future<void> _revertDaySquareSize(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(daySquareSizeNotifierProvider);
    await notifier.setDaySquareSize(defaultDaySquareSize);
    ref.invalidate(daySquareSizeNotifierProvider);
  }

  Future<void> _revertTimelineDays(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(timelineDaysNotifierProvider);
    await notifier.setTimelineDays(defaultTimelineDays);
    ref.invalidate(timelineDaysNotifierProvider);
  }

  Future<void> _revertModalTimelineDays(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(modalTimelineDaysNotifierProvider);
    await notifier.setModalTimelineDays(defaultModalTimelineDays);
    ref.invalidate(modalTimelineDaysNotifierProvider);
  }

  void _showTimelineDaysDialog(BuildContext context, WidgetRef ref) {
    final currentDays = ref.watch(timelineDaysProvider);
    final notifier = ref.read(timelineDaysNotifierProvider);
    final navigator = Navigator.of(context);
    final controller = TextEditingController(text: currentDays.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('timeline_days'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'number_of_days_to_show'.tr(),
                hintText: 'enter_number_of_days'.tr(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final days = int.tryParse(controller.text);
              if (days != null && days > 0) {
                await notifier.setTimelineDays(days);
                ref.invalidate(timelineDaysNotifierProvider);
                if (dialogContext.mounted) {
                  navigator.pop();
                }
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  void _showModalTimelineDaysDialog(BuildContext context, WidgetRef ref) {
    final currentDays = ref.watch(modalTimelineDaysProvider);
    final notifier = ref.read(modalTimelineDaysNotifierProvider);
    final navigator = Navigator.of(context);
    final controller = TextEditingController(text: currentDays.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('modal_timeline_days'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'number_of_days_to_show'.tr(),
                hintText: 'enter_number_of_days'.tr(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final days = int.tryParse(controller.text);
              if (days != null && days > 0) {
                await notifier.setModalTimelineDays(days);
                ref.invalidate(modalTimelineDaysNotifierProvider);
                if (dialogContext.mounted) {
                  navigator.pop();
                }
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  // Display Preferences Helper Methods
  String _getIconSizeName(String size) {
    switch (size) {
      case 'small':
        return 'small'.tr();
      case 'medium':
        return 'medium'.tr();
      case 'large':
        return 'large'.tr();
      default:
        return 'medium'.tr();
    }
  }

  String _getProgressIndicatorStyleName(String style) {
    switch (style) {
      case 'circular':
        return 'circular'.tr();
      case 'linear':
        return 'linear'.tr();
      default:
        return 'circular'.tr();
    }
  }

  String _getStreakColorSchemeName(String scheme) {
    switch (scheme) {
      case 'default':
        return 'default'.tr();
      case 'vibrant':
        return 'vibrant'.tr();
      case 'subtle':
        return 'subtle'.tr();
      case 'monochrome':
        return 'monochrome'.tr();
      default:
        return 'default'.tr();
    }
  }

  String _getFontSizeScaleName(String scale) {
    switch (scale) {
      case 'small':
        return 'small'.tr();
      case 'normal':
        return 'normal'.tr();
      case 'large':
        return 'large'.tr();
      case 'extra_large':
        return 'extra_large'.tr();
      default:
        return 'normal'.tr();
    }
  }

  String _getDefaultViewName(String view) {
    switch (view) {
      case 'habits':
        return 'habits'.tr();
      case 'timeline':
        return 'timeline'.tr();
      default:
        return 'habits'.tr();
    }
  }

  // Display Preferences Dialog Methods
  void _showTimelineSpacingDialog(BuildContext context, WidgetRef ref) {
    final currentSpacing = ref.watch(timelineSpacingProvider);
    final notifier = ref.read(timelineSpacingNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          double spacing = currentSpacing;
          return AlertDialog(
            title: Text('timeline_spacing'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${spacing.toStringAsFixed(1)}px'),
                Slider(
                  value: spacing,
                  min: 4.0,
                  max: 12.0,
                  divisions: 16,
                  onChanged: (value) {
                    setDialogState(() {
                      spacing = value;
                    });
                    notifier.setTimelineSpacing(value);
                    ref.invalidate(timelineSpacingNotifierProvider);
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

  void _showIconSizeDialog(BuildContext context, WidgetRef ref) {
    final currentSize = ref.watch(iconSizeProvider);
    final notifier = ref.read(iconSizeNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('icon_size'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('small'.tr()),
              value: 'small',
              groupValue: currentSize,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setIconSize(value);
                  ref.invalidate(iconSizeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('medium'.tr()),
              value: 'medium',
              groupValue: currentSize,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setIconSize(value);
                  ref.invalidate(iconSizeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('large'.tr()),
              value: 'large',
              groupValue: currentSize,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setIconSize(value);
                  ref.invalidate(iconSizeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showProgressIndicatorStyleDialog(BuildContext context, WidgetRef ref) {
    final currentStyle = ref.watch(progressIndicatorStyleProvider);
    final notifier = ref.read(progressIndicatorStyleNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('progress_indicator_style'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('circular'.tr()),
              value: 'circular',
              groupValue: currentStyle,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setProgressIndicatorStyle(value);
                  ref.invalidate(progressIndicatorStyleNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('linear'.tr()),
              value: 'linear',
              groupValue: currentStyle,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setProgressIndicatorStyle(value);
                  ref.invalidate(progressIndicatorStyleNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showCompletionColorDialog(BuildContext context, WidgetRef ref) {
    final currentColor = ref.watch(completionColorProvider);
    final notifier = ref.read(completionColorNotifierProvider);
    final navigator = Navigator.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isLandscape = screenWidth > mediaQuery.size.height;
    final maxWidth = 600.0;
    final contentWidth = isLandscape ? maxWidth : screenWidth * 0.5;
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.pink,
      Colors.brown,
      Colors.grey,
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('completion_color'.tr()),
        content: SizedBox(
          width: contentWidth,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              final colorValue = color.toARGB32();
              final isSelected = colorValue == currentColor;
              return GestureDetector(
                onTap: () async {
                  await notifier.setCompletionColor(colorValue);
                  ref.invalidate(completionColorNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                },
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
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showStreakColorSchemeDialog(BuildContext context, WidgetRef ref) {
    final currentScheme = ref.watch(streakColorSchemeProvider);
    final notifier = ref.read(streakColorSchemeNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('streak_color_scheme'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('default'.tr()),
              value: 'default',
              groupValue: currentScheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setStreakColorScheme(value);
                  ref.invalidate(streakColorSchemeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('vibrant'.tr()),
              value: 'vibrant',
              groupValue: currentScheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setStreakColorScheme(value);
                  ref.invalidate(streakColorSchemeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('subtle'.tr()),
              value: 'subtle',
              groupValue: currentScheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setStreakColorScheme(value);
                  ref.invalidate(streakColorSchemeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('monochrome'.tr()),
              value: 'monochrome',
              groupValue: currentScheme,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setStreakColorScheme(value);
                  ref.invalidate(streakColorSchemeNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showFontSizeScaleDialog(BuildContext context, WidgetRef ref) {
    final currentScale = ref.watch(fontSizeScaleProvider);
    final notifier = ref.read(fontSizeScaleNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('font_size_scale'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('small'.tr()),
              value: 'small',
              groupValue: currentScale,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setFontSizeScale(value);
                  ref.invalidate(fontSizeScaleNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('normal'.tr()),
              value: 'normal',
              groupValue: currentScale,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setFontSizeScale(value);
                  ref.invalidate(fontSizeScaleNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('large'.tr()),
              value: 'large',
              groupValue: currentScale,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setFontSizeScale(value);
                  ref.invalidate(fontSizeScaleNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('extra_large'.tr()),
              value: 'extra_large',
              groupValue: currentScale,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setFontSizeScale(value);
                  ref.invalidate(fontSizeScaleNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showCardSpacingDialog(BuildContext context, WidgetRef ref) {
    final currentSpacing = ref.watch(cardSpacingProvider);
    final notifier = ref.read(cardSpacingNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          double spacing = currentSpacing;
          return AlertDialog(
            title: Text('card_spacing'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${spacing.toStringAsFixed(1)}px'),
                Slider(
                  value: spacing,
                  min: 8.0,
                  max: 24.0,
                  divisions: 32,
                  onChanged: (value) {
                    setDialogState(() {
                      spacing = value;
                    });
                    notifier.setCardSpacing(value);
                    ref.invalidate(cardSpacingNotifierProvider);
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

  void _showDefaultViewDialog(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(defaultViewProvider);
    final notifier = ref.read(defaultViewNotifierProvider);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('default_view'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('habits'.tr()),
              value: 'habits',
              groupValue: currentView,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setDefaultView(value);
                  ref.invalidate(defaultViewNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            _buildRadioListItem<String>(
              context: dialogContext,
              title: Text('timeline'.tr()),
              value: 'timeline',
              groupValue: currentView,
              onChanged: (value) async {
                if (value != null) {
                  await notifier.setDefaultView(value);
                  ref.invalidate(defaultViewNotifierProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = PreferencesService.getLanguage() ?? 'en';
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);
    final cardElevation = ref.watch(cardElevationProvider);
    final cardBorderRadius = ref.watch(cardBorderRadiusProvider);
    final daySquareSize = ref.watch(daySquareSizeProvider);
    final dateFormat = ref.watch(dateFormatProvider);
    final firstDayOfWeek = ref.watch(firstDayOfWeekProvider);
    final timelineDays = ref.watch(timelineDaysProvider);
    final modalTimelineDays = ref.watch(modalTimelineDaysProvider);
    final habitCheckboxStyle = ref.watch(habitCheckboxStyleProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final notificationsNotifier = ref.read(
      notificationsEnabledNotifierProvider,
    );
    // Display Preferences
    final showStreakBorders = ref.watch(showStreakBordersProvider);
    final timelineCompactMode = ref.watch(timelineCompactModeProvider);
    final showWeekMonthHighlights = ref.watch(showWeekMonthHighlightsProvider);
    final timelineSpacing = ref.watch(timelineSpacingProvider);
    final showStreakNumbers = ref.watch(showStreakNumbersProvider);
    final showDescriptions = ref.watch(showDescriptionsProvider);
    final compactCards = ref.watch(compactCardsProvider);
    final iconSize = ref.watch(iconSizeProvider);
    final progressIndicatorStyle = ref.watch(progressIndicatorStyleProvider);
    final completionColor = ref.watch(completionColorProvider);
    final streakColorScheme = ref.watch(streakColorSchemeProvider);
    final showPercentage = ref.watch(showPercentageProvider);
    final fontSizeScale = ref.watch(fontSizeScaleProvider);
    final cardSpacing = ref.watch(cardSpacingProvider);
    final showStatisticsCard = ref.watch(showStatisticsCardProvider);
    final defaultView = ref.watch(defaultViewProvider);
    final showStreakOnCard = ref.watch(showStreakOnCardProvider);

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
    final maxWidth = 600.0; // Maximum width for the centered content

    final settingsList = ListView(
      children: [
        // General Section
        _buildSectionHeader('general'.tr()),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text('language'.tr()),
          subtitle: Text(_getLanguageName(currentLanguage)),
          onTap: () => _showLanguageDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: Text('theme'.tr()),
          subtitle: Text(_getThemeName(themeMode)),
          onTap: () => _showThemeDialog(context, ref),
        ),

        // Appearance Section
        _buildSectionHeader('appearance'.tr()),
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
          onTap: () => _showThemeColorDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.style),
          title: Text('card_style'.tr()),
          subtitle: Text(
            '${'elevation'.tr()}: ${cardElevation.toStringAsFixed(1)}, ${'border_radius'.tr()}: ${cardBorderRadius.toStringAsFixed(1)}',
          ),
          trailing:
              (cardElevation != defaultCardElevation ||
                  cardBorderRadius != defaultCardBorderRadius)
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'reset_to_default'.tr(),
                  onPressed: () => _revertCardStyle(context, ref),
                )
              : null,
          onTap: () => _showCardStyleDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.square),
          title: Text('day_square_size'.tr()),
          subtitle: Text(_getDaySquareSizeName(daySquareSize)),
          trailing: daySquareSize != defaultDaySquareSize
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'reset_to_default'.tr(),
                  onPressed: () => _revertDaySquareSize(context, ref),
                )
              : null,
          onTap: () => _showDaySquareSizeDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.check_box),
          title: Text('habit_checkbox_style'.tr()),
          subtitle: Text(_getCheckboxStyleName(habitCheckboxStyle)),
          onTap: () => _showHabitCheckboxStyleDialog(context, ref),
        ),

        // Display Section
        _buildSectionHeader('display'.tr()),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text('date_format'.tr()),
          subtitle: Text(_getDateFormatName(dateFormat)),
          onTap: () => _showDateFormatDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.view_week),
          title: Text('first_day_of_week'.tr()),
          subtitle: Text(_getFirstDayOfWeekName(firstDayOfWeek)),
          onTap: () => _showFirstDayOfWeekDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_view_week),
          title: Text('timeline_days'.tr()),
          subtitle: Text('$timelineDays ${'days'.tr()}'),
          trailing: timelineDays != defaultTimelineDays
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'reset_to_default'.tr(),
                  onPressed: () => _revertTimelineDays(context, ref),
                )
              : null,
          onTap: () => _showTimelineDaysDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.view_timeline),
          title: Text('modal_timeline_days'.tr()),
          subtitle: Text('$modalTimelineDays ${'days'.tr()}'),
          trailing: modalTimelineDays != defaultModalTimelineDays
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'reset_to_default'.tr(),
                  onPressed: () => _revertModalTimelineDays(context, ref),
                )
              : null,
          onTap: () => _showModalTimelineDaysDialog(context, ref),
        ),

        // Display Preferences Section
        _buildSectionHeader('display_preferences'.tr()),
        SwitchListTile(
          secondary: const Icon(Icons.border_color),
          title: Text('show_streak_borders'.tr()),
          subtitle: Text('show_streak_borders_description'.tr()),
          value: showStreakBorders,
          onChanged: (value) async {
            final notifier = ref.read(showStreakBordersNotifierProvider);
            await notifier.setShowStreakBorders(value);
            ref.invalidate(showStreakBordersNotifierProvider);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.compress),
          title: Text('timeline_compact_mode'.tr()),
          subtitle: Text('timeline_compact_mode_description'.tr()),
          value: timelineCompactMode,
          onChanged: (value) async {
            final notifier = ref.read(timelineCompactModeNotifierProvider);
            await notifier.setTimelineCompactMode(value);
            ref.invalidate(timelineCompactModeNotifierProvider);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.highlight),
          title: Text('show_week_month_highlights'.tr()),
          subtitle: Text('show_week_month_highlights_description'.tr()),
          value: showWeekMonthHighlights,
          onChanged: (value) async {
            final notifier = ref.read(showWeekMonthHighlightsNotifierProvider);
            await notifier.setShowWeekMonthHighlights(value);
            ref.invalidate(showWeekMonthHighlightsNotifierProvider);
          },
        ),
        ListTile(
          leading: const Icon(Icons.space_bar),
          title: Text('timeline_spacing'.tr()),
          subtitle: Text('${timelineSpacing.toStringAsFixed(1)}px'),
          onTap: () => _showTimelineSpacingDialog(context, ref),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.numbers),
          title: Text('show_streak_numbers'.tr()),
          subtitle: Text('show_streak_numbers_description'.tr()),
          value: showStreakNumbers,
          onChanged: (value) async {
            final notifier = ref.read(showStreakNumbersNotifierProvider);
            await notifier.setShowStreakNumbers(value);
            ref.invalidate(showStreakNumbersNotifierProvider);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.description),
          title: Text('show_descriptions'.tr()),
          subtitle: Text('show_descriptions_description'.tr()),
          value: showDescriptions,
          onChanged: (value) async {
            final notifier = ref.read(showDescriptionsNotifierProvider);
            await notifier.setShowDescriptions(value);
            ref.invalidate(showDescriptionsNotifierProvider);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.view_compact),
          title: Text('compact_cards'.tr()),
          subtitle: Text('compact_cards_description'.tr()),
          value: compactCards,
          onChanged: (value) async {
            final notifier = ref.read(compactCardsNotifierProvider);
            await notifier.setCompactCards(value);
            ref.invalidate(compactCardsNotifierProvider);
          },
        ),
        ListTile(
          leading: const Icon(Icons.image),
          title: Text('icon_size'.tr()),
          subtitle: Text(_getIconSizeName(iconSize)),
          onTap: () => _showIconSizeDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.trending_up),
          title: Text('progress_indicator_style'.tr()),
          subtitle: Text(_getProgressIndicatorStyleName(progressIndicatorStyle)),
          onTap: () => _showProgressIndicatorStyleDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: Text('completion_color'.tr()),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(completionColor),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
          ),
          onTap: () => _showCompletionColorDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.color_lens),
          title: Text('streak_color_scheme'.tr()),
          subtitle: Text(_getStreakColorSchemeName(streakColorScheme)),
          onTap: () => _showStreakColorSchemeDialog(context, ref),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.percent),
          title: Text('show_percentage'.tr()),
          subtitle: Text('show_percentage_description'.tr()),
          value: showPercentage,
          onChanged: (value) async {
            final notifier = ref.read(showPercentageNotifierProvider);
            await notifier.setShowPercentage(value);
            ref.invalidate(showPercentageNotifierProvider);
          },
        ),
        ListTile(
          leading: const Icon(Icons.text_fields),
          title: Text('font_size_scale'.tr()),
          subtitle: Text(_getFontSizeScaleName(fontSizeScale)),
          onTap: () => _showFontSizeScaleDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.format_line_spacing),
          title: Text('card_spacing'.tr()),
          subtitle: Text('${cardSpacing.toStringAsFixed(1)}px'),
          onTap: () => _showCardSpacingDialog(context, ref),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.bar_chart),
          title: Text('show_statistics_card'.tr()),
          subtitle: Text('show_statistics_card_description'.tr()),
          value: showStatisticsCard,
          onChanged: (value) async {
            final notifier = ref.read(showStatisticsCardNotifierProvider);
            await notifier.setShowStatisticsCard(value);
            ref.invalidate(showStatisticsCardNotifierProvider);
          },
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: Text('default_view'.tr()),
          subtitle: Text(_getDefaultViewName(defaultView)),
          onTap: () => _showDefaultViewDialog(context, ref),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.local_fire_department),
          title: Text('show_streak_on_card'.tr()),
          subtitle: Text('show_streak_on_card_description'.tr()),
          value: showStreakOnCard,
          onChanged: (value) async {
            final notifier = ref.read(showStreakOnCardNotifierProvider);
            await notifier.setShowStreakOnCard(value);
            ref.invalidate(showStreakOnCardNotifierProvider);
          },
        ),

        // Notifications Section
        _buildSectionHeader('notifications'.tr()),
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
        // Tags Section
        _buildSectionHeader('tags'.tr()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TagManagementWidget(),
        ),
        // Data & Export Section
        _buildSectionHeader('data_export'.tr()),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: Text('export_data'.tr()),
          subtitle: Text('export_habit_data_description'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showExportDialog(context, ref),
        ),
      ],
    );

    final bodyContent = isLandscape
        ? Center(
            key: const ValueKey('landscape'),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: settingsList,
            ),
          )
        : Container(key: const ValueKey('portrait'), child: settingsList);

    if (isLandscape) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                AppBar(
                  title: Text('settings'.tr()),
                  automaticallyImplyLeading: true,
                ),
                Expanded(
                  child: PageTransitionSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (
                          Widget child,
                          Animation<double> primaryAnimation,
                          Animation<double> secondaryAnimation,
                        ) {
                          return SharedAxisTransition(
                            animation: primaryAnimation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.horizontal,
                            fillColor: Colors.transparent,
                            child: child,
                          );
                        },
                    child: bodyContent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder:
            (
              Widget child,
              Animation<double> primaryAnimation,
              Animation<double> secondaryAnimation,
            ) {
              return SharedAxisTransition(
                animation: primaryAnimation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.horizontal,
                fillColor: Colors.transparent,
                child: child,
              );
            },
        child: bodyContent,
      ),
    );
  }
}

class _CardStyleDialogContent extends StatefulWidget {
  final double initialElevation;
  final double initialBorderRadius;
  final dynamic cardStyleNotifier;
  final dynamic ref;

  const _CardStyleDialogContent({
    required this.initialElevation,
    required this.initialBorderRadius,
    required this.cardStyleNotifier,
    required this.ref,
  });

  @override
  State<_CardStyleDialogContent> createState() =>
      _CardStyleDialogContentState();
}

class _CardStyleDialogContentState extends State<_CardStyleDialogContent> {
  late double _elevation;
  late double _borderRadius;

  @override
  void initState() {
    super.initState();
    _elevation = widget.initialElevation;
    _borderRadius = widget.initialBorderRadius;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('card_style'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${'elevation'.tr()}: ${_elevation.toStringAsFixed(1)}'),
          Slider(
            value: _elevation,
            min: 0,
            max: 8,
            divisions: 16,
            onChanged: (value) {
              setState(() {
                _elevation = value;
              });
              widget.cardStyleNotifier.setElevation(value);
              widget.ref.invalidate(cardStyleNotifierProvider);
            },
          ),
          const SizedBox(height: 16),
          Text('${'border_radius'.tr()}: ${_borderRadius.toStringAsFixed(1)}'),
          Slider(
            value: _borderRadius,
            min: 0,
            max: 24,
            divisions: 48,
            onChanged: (value) {
              setState(() {
                _borderRadius = value;
              });
              widget.cardStyleNotifier.setBorderRadius(value);
              widget.ref.invalidate(cardStyleNotifierProvider);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('done'.tr()),
        ),
      ],
    );
  }
}
