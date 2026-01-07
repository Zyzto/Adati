import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/services/preferences_service.dart';
import 'core/services/log_helper.dart';
import 'core/services/notification_service.dart';
import 'core/services/platform_utils.dart';
import 'core/services/reminder_checker.dart';
import 'features/habits/providers/habit_providers.dart';
import 'features/timeline/pages/day_detail_page.dart';
import 'features/settings/pages/settings_page_v2.dart';
import 'features/settings/providers/settings_framework_providers.dart';
import 'features/settings/settings_definitions.dart';
import 'features/timeline/pages/main_timeline_page.dart';
import 'features/onboarding/pages/onboarding_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Safely check if this is the first launch with fallback behavior
  // If PreferencesService isn't initialized, assume it's the first launch
  bool isFirstLaunch = true;
  try {
    isFirstLaunch = PreferencesService.isFirstLaunch();
    Log.debug('Router initialized, first launch: $isFirstLaunch');
  } catch (e, stackTrace) {
    Log.error(
      'Failed to check first launch status from PreferencesService, defaulting to onboarding. Error: $e',
      error: e,
      stackTrace: stackTrace,
    );
    // Default to true (first launch) if we can't determine - safer to show onboarding
    isFirstLaunch = true;
  }

  return GoRouter(
    initialLocation: isFirstLaunch ? '/onboarding' : '/timeline',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/timeline',
        builder: (context, state) => const MainTimelinePage(),
      ),
      GoRoute(
        path: '/timeline/day/:date',
        builder: (context, state) {
          final dateStr = state.pathParameters['date']!;
          try {
            final date = DateTime.parse(dateStr);
            return DayDetailPage(date: date);
          } catch (e, stackTrace) {
            Log.error(
              'Failed to parse date parameter in route: $dateStr',
              error: e,
              stackTrace: stackTrace,
            );
            // Redirect to timeline on invalid date
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.go('/timeline');
              }
            });
            // Return timeline page as fallback
            return const MainTimelinePage();
          }
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPageV2(),
      ),
    ],
  );
});

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  Timer? _reminderCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Start periodic reminder checks for desktop
    if (isDesktop) {
      _startReminderChecks();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reminderCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Only run reminder checks on desktop when app is in foreground
    if (isDesktop) {
      if (state == AppLifecycleState.resumed) {
        _startReminderChecks();
      } else {
        _stopReminderChecks();
      }
    }
  }

  void _startReminderChecks() {
    _reminderCheckTimer?.cancel();
    
    // Check reminders immediately, then every minute
    _checkReminders();
    _reminderCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkReminders();
    });
  }

  void _stopReminderChecks() {
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = null;
  }

  Future<void> _checkReminders() async {
    try {
      Log.debug('Desktop: Starting periodic reminder check');
      final repository = ref.read(habitRepositoryProvider);
      await ReminderChecker.checkAndShowDueReminders(repository);
      Log.debug('Desktop: Completed periodic reminder check');
    } catch (e, stackTrace) {
      Log.error(
        'Failed to check reminders in desktop periodic check',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    
    // Set router in NotificationService for navigation from notification taps
    NotificationService.setRouter(router);

    // Try to get settings from new framework, fall back to PreferencesService
    ThemeMode themeMode;
    int themeColor;
    double cardElevation;
    double cardBorderRadius;
    String fontSizeScale;

    try {
      final settings = ref.watch(adatiSettingsProvider);
      final themeModeStr = ref.watch(settings.provider(themeModeSettingDef));
      themeMode = _parseThemeMode(themeModeStr);
      themeColor = ref.watch(settings.provider(themeColorSettingDef));
      cardElevation = ref.watch(settings.provider(cardElevationSettingDef));
      cardBorderRadius = ref.watch(settings.provider(cardBorderRadiusSettingDef));
      fontSizeScale = ref.watch(settings.provider(fontSizeScaleSettingDef));
    } catch (e) {
      // Framework not initialized, use PreferencesService fallback
      Log.warning('Settings framework not initialized, using PreferencesService fallback');
      themeMode = _getThemeModeFromPrefs();
      themeColor = PreferencesService.getThemeColor();
      cardElevation = PreferencesService.getCardElevation();
      cardBorderRadius = PreferencesService.getCardBorderRadius();
      fontSizeScale = PreferencesService.getFontSizeScale();
    }

    Log.debug(
      'App build: themeMode=$themeMode, themeColor=$themeColor, cardElevation=$cardElevation, cardBorderRadius=$cardBorderRadius, fontSizeScale=$fontSizeScale',
    );

    return MaterialApp.router(
      title: context.locale.languageCode == 'ar' ? 'عادتي' : 'Adati',
      // Show Flutter's built-in debug banner in debug mode
      // This indicates it's a debug build and data is separate from release
      debugShowCheckedModeBanner: kDebugMode,
      // Custom scroll behavior enables mouse drag support on desktop platforms
      // (Linux, Windows, macOS). Without this, users cannot drag PageView or
      // other scrollable widgets with a mouse.
      scrollBehavior: AppScrollBehavior(),
      theme: AppTheme.lightTheme(
        seedColor: Color(themeColor),
        cardElevation: cardElevation,
        cardBorderRadius: cardBorderRadius,
        locale: context.locale,
        fontSizeScale: fontSizeScale,
      ),
      darkTheme: AppTheme.darkTheme(
        seedColor: Color(themeColor),
        cardElevation: cardElevation,
        cardBorderRadius: cardBorderRadius,
        locale: context.locale,
        fontSizeScale: fontSizeScale,
      ),
      themeMode: themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: router,
    );
  }

  ThemeMode _parseThemeMode(String themeModeStr) {
    switch (themeModeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  ThemeMode _getThemeModeFromPrefs() {
    final savedMode = PreferencesService.getThemeMode();
    if (savedMode == null) return ThemeMode.system;
    return _parseThemeMode(savedMode);
  }
}
