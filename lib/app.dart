import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/services/preferences_service.dart';
import 'core/services/log_helper.dart';
import 'features/timeline/pages/day_detail_page.dart';
import 'features/settings/pages/settings_page.dart';
import 'features/settings/providers/settings_providers.dart';
import 'features/timeline/pages/main_timeline_page.dart';
import 'features/onboarding/pages/onboarding_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isFirstLaunch = PreferencesService.isFirstLaunch();
  Log.debug('Router initialized, first launch: $isFirstLaunch');
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
          final date = DateTime.parse(dateStr);
          return DayDetailPage(date: date);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);
    final cardElevation = ref.watch(cardElevationProvider);
    final cardBorderRadius = ref.watch(cardBorderRadiusProvider);
    final fontSizeScale = ref.watch(fontSizeScaleProvider);

    Log.debug(
      'App build: themeMode=$themeMode, themeColor=$themeColor, cardElevation=$cardElevation, cardBorderRadius=$cardBorderRadius, fontSizeScale=$fontSizeScale',
    );

    return MaterialApp.router(
      title: 'app_name'.tr(),
      debugShowCheckedModeBanner: false,
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
}
