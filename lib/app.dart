import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'features/habits/presentation/pages/habit_detail_page.dart';
import 'features/habits/presentation/pages/habit_form_page.dart';
import 'features/timeline/presentation/pages/day_detail_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'features/main/presentation/pages/main_shell_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/timeline',
    routes: [
      GoRoute(
        path: '/timeline',
        builder: (context, state) => const MainShellPage(),
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
        path: '/habits/new',
        builder: (context, state) => const HabitFormPage(),
      ),
      GoRoute(
        path: '/habits/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return HabitDetailPage(habitId: id);
        },
      ),
      GoRoute(
        path: '/habits/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return HabitFormPage(habitId: id);
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

    return MaterialApp.router(
      title: 'Adati',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: router,
    );
  }
}
