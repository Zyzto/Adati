import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animations/animations.dart';
import '../../../../core/services/preferences_service.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  // Default values
  static const double defaultCardElevation = 2.0;
  static const double defaultCardBorderRadius = 12.0;
  static const String defaultDaySquareSize = 'large';
  static const int defaultTimelineDays = 50;

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

  String _getDaySquareSizeName(String size) {
    switch (size) {
      case 'small':
        return 'Small';
      case 'medium':
        return 'Medium';
      case 'large':
        return 'Large';
      default:
        return 'Medium';
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
    return day == 0 ? 'Sunday' : 'Monday';
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
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ignore: deprecated_member_use
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              // ignore: deprecated_member_use
              groupValue: currentLanguage,
              // ignore: deprecated_member_use
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
            // ignore: deprecated_member_use
            RadioListTile<String>(
              title: const Text('العربية'),
              value: 'ar',
              // ignore: deprecated_member_use
              groupValue: currentLanguage,
              // ignore: deprecated_member_use
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
            child: const Text('Cancel'),
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
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ignore: deprecated_member_use
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              // ignore: deprecated_member_use
              groupValue: currentTheme,
              // ignore: deprecated_member_use
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
            // ignore: deprecated_member_use
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              // ignore: deprecated_member_use
              groupValue: currentTheme,
              // ignore: deprecated_member_use
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
            // ignore: deprecated_member_use
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              // ignore: deprecated_member_use
              groupValue: currentTheme,
              // ignore: deprecated_member_use
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
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showThemeColorDialog(BuildContext context, WidgetRef ref) {
    final currentColor = ref.watch(themeColorProvider);
    final notifier = ref.read(themeColorNotifierProvider);
    final navigator = Navigator.of(context);
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
        title: const Text('Select Theme Color'),
        content: SizedBox(
          width: double.maxFinite,
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
            child: const Text('Cancel'),
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
        title: const Text('Day Square Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ignore: deprecated_member_use
            RadioListTile<String>(
              title: const Text('Small'),
              value: 'small',
              // ignore: deprecated_member_use
              groupValue: currentSize,
              // ignore: deprecated_member_use
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
            // ignore: deprecated_member_use
            RadioListTile<String>(
              title: const Text('Medium'),
              value: 'medium',
              // ignore: deprecated_member_use
              groupValue: currentSize,
              // ignore: deprecated_member_use
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
            // ignore: deprecated_member_use
            RadioListTile<String>(
              title: const Text('Large'),
              value: 'large',
              // ignore: deprecated_member_use
              groupValue: currentSize,
              // ignore: deprecated_member_use
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
            child: const Text('Cancel'),
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
        title: const Text('Date Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats.map((format) {
            // ignore: deprecated_member_use
            return RadioListTile<String>(
              title: Text(_getDateFormatName(format)),
              subtitle: Text(DateTime.now().toString().split(' ')[0]),
              value: format,
              // ignore: deprecated_member_use
              groupValue: currentFormat,
              // ignore: deprecated_member_use
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
            child: const Text('Cancel'),
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
        title: const Text('First Day of Week'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ignore: deprecated_member_use
            RadioListTile<int>(
              title: const Text('Sunday'),
              value: 0,
              // ignore: deprecated_member_use
              groupValue: currentDay,
              // ignore: deprecated_member_use
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
            // ignore: deprecated_member_use
            RadioListTile<int>(
              title: const Text('Monday'),
              value: 1,
              // ignore: deprecated_member_use
              groupValue: currentDay,
              // ignore: deprecated_member_use
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
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
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

  void _showTimelineDaysDialog(BuildContext context, WidgetRef ref) {
    final currentDays = ref.watch(timelineDaysProvider);
    final notifier = ref.read(timelineDaysNotifierProvider);
    final navigator = Navigator.of(context);
    final controller = TextEditingController(text: currentDays.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
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
    final themeColor = ref.watch(themeColorProvider);
    final cardElevation = ref.watch(cardElevationProvider);
    final cardBorderRadius = ref.watch(cardBorderRadiusProvider);
    final daySquareSize = ref.watch(daySquareSizeProvider);
    final dateFormat = ref.watch(dateFormatProvider);
    final firstDayOfWeek = ref.watch(firstDayOfWeekProvider);
    final timelineDays = ref.watch(timelineDaysProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final notificationsNotifier = ref.read(
      notificationsEnabledNotifierProvider,
    );

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
    final maxWidth = 600.0; // Maximum width for the centered content

    final settingsList = ListView(
      children: [
        // General Section
        _buildSectionHeader('General'),
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

        // Appearance Section
        _buildSectionHeader('Appearance'),
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Theme Color'),
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
          title: const Text('Card Style'),
          subtitle: Text(
            'Elevation: ${cardElevation.toStringAsFixed(1)}, Radius: ${cardBorderRadius.toStringAsFixed(1)}',
          ),
          trailing:
              (cardElevation != defaultCardElevation ||
                  cardBorderRadius != defaultCardBorderRadius)
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reset to default',
                  onPressed: () => _revertCardStyle(context, ref),
                )
              : null,
          onTap: () => _showCardStyleDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.square),
          title: const Text('Day Square Size'),
          subtitle: Text(_getDaySquareSizeName(daySquareSize)),
          trailing: daySquareSize != defaultDaySquareSize
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reset to default',
                  onPressed: () => _revertDaySquareSize(context, ref),
                )
              : null,
          onTap: () => _showDaySquareSizeDialog(context, ref),
        ),

        // Display Section
        _buildSectionHeader('Display'),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Date Format'),
          subtitle: Text(_getDateFormatName(dateFormat)),
          onTap: () => _showDateFormatDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.view_week),
          title: const Text('First Day of Week'),
          subtitle: Text(_getFirstDayOfWeekName(firstDayOfWeek)),
          onTap: () => _showFirstDayOfWeekDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_view_week),
          title: const Text('Timeline Days'),
          subtitle: Text('$timelineDays days'),
          trailing: timelineDays != defaultTimelineDays
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reset to default',
                  onPressed: () => _revertTimelineDays(context, ref),
                )
              : null,
          onTap: () => _showTimelineDaysDialog(context, ref),
        ),

        // Notifications Section
        _buildSectionHeader('Notifications'),
        SwitchListTile(
          secondary: const Icon(Icons.notifications),
          title: const Text('Enable Notifications'),
          subtitle: const Text('Receive habit reminders'),
          value: notificationsEnabled,
          onChanged: (value) async {
            await notificationsNotifier.setNotificationsEnabled(value);
            ref.invalidate(notificationsEnabledNotifierProvider);
          },
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
                  title: const Text('Settings'),
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
      appBar: AppBar(title: const Text('Settings')),
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
      title: const Text('Card Style'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Elevation: ${_elevation.toStringAsFixed(1)}'),
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
          Text('Border Radius: ${_borderRadius.toStringAsFixed(1)}'),
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
          child: const Text('Done'),
        ),
      ],
    );
  }
}
