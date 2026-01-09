import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'core/services/preferences_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/reminder_service.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'core/services/auto_backup_service.dart';
import 'core/services/workmanager_dispatcher.dart';
import 'core/services/platform_utils.dart';
import 'features/habits/habit_repository.dart';
import 'features/habits/providers/habit_providers.dart';
import 'features/settings/providers/settings_framework_providers.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up error handlers FIRST - before any initialization that might fail
  // This ensures we can catch and log errors during initialization
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Use LoggingService directly here since Log helper might not be available yet
    LoggingService.severe(
      'Flutter framework error: ${details.exception}',
      component: 'CrashHandler',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Handle async errors (uncaught exceptions in async code)
  PlatformDispatcher.instance.onError = (error, stack) {
    LoggingService.severe(
      'Uncaught async error: $error',
      component: 'CrashHandler',
      error: error,
      stackTrace: stack,
    );
    return true; // Prevent default error handling
  };

  // Initialize logging service (critical - needed for all other logging)
  try {
    await LoggingService.init(
      LoggingConfig(
        appName: 'Adati',
        logFileName: 'adati.log',
        crashLogFileName: 'adati_crashes.log',
      ),
    );
  } catch (e) {
    // If logging service fails, we can't log it, but we should still try to continue
    // The service will fall back to console logging
    // Note: We don't capture stackTrace here since we can't log it anyway
  }

  // Initialize timezone data (required for notifications and date handling)
  try {
    tz.initializeTimeZones();
    Log.debug('Timezone initialized successfully');
  } catch (e, stackTrace) {
    Log.error(
      'Failed to initialize timezone data, some features may not work correctly',
      error: e,
      stackTrace: stackTrace,
    );
    // Continue - app can function without timezone data, but notifications may fail
  }

  // Initialize localization (required for i18n support)
  // If this fails, app will use default locale (English)
  try {
    await EasyLocalization.ensureInitialized();
    Log.debug('Localization initialized successfully');
  } catch (e, stackTrace) {
    Log.error(
      'Failed to initialize localization service, app will use default locale (en). Error: $e',
      error: e,
      stackTrace: stackTrace,
    );
    // Continue with default locale - app can still function
  }

  // Initialize preferences service (critical - stores user settings)
  // If this fails, app may not function correctly but we'll try to continue
  try {
    await PreferencesService.init();
    Log.debug('PreferencesService initialized successfully');
  } catch (e, stackTrace) {
    Log.error(
      'Failed to initialize PreferencesService - user preferences will not be saved. Error: $e',
      error: e,
      stackTrace: stackTrace,
    );
    // This is critical - if preferences fail, app may not function correctly
    // But we'll continue and let the app handle it gracefully
  }

  // Initialize notifications (non-critical - app continues even if it fails)
  // Notifications are optional and failure should not prevent app startup
  try {
    await NotificationService.init();
    await NotificationService.requestPermissions();
    Log.debug('NotificationService initialized successfully');
  } catch (e, stackTrace) {
    Log.error(
      'Failed to initialize NotificationService - notifications will not be available. Error: $e',
      error: e,
      stackTrace: stackTrace,
    );
    // Continue without notifications - this is acceptable
  }

  // Initialize WorkManager for background reminder checks (Android/iOS only)
  // Desktop will use app-level periodic checks instead
  if (!kIsWeb && !isDesktop) {
    // Only initialize WorkManager on mobile platforms (Android/iOS)
    try {
      await Workmanager().initialize(callbackDispatcher);
      Log.debug('WorkManager initialized successfully');
    } catch (e, stackTrace) {
      Log.error(
        'Failed to initialize WorkManager - background reminders may not work. Error: $e',
        error: e,
        stackTrace: stackTrace,
      );
      // Continue - app can function without WorkManager
    }
  } else {
    Log.debug('WorkManager skipped (not available on web/desktop platforms)');
  }

  // Initialize reminder service and reschedule all reminders
  // This ensures reminders are up-to-date after app updates or timezone changes
  HabitRepository? habitRepository;
  try {
    // Use shared database instance to avoid multiple database warnings
    final database = getDatabase();
    habitRepository = HabitRepository(database);
    ReminderService.init(habitRepository);

    // Reschedule reminders in background to not block app startup
    // This will register WorkManager task for mobile, or do nothing for desktop
    ReminderService.rescheduleAllReminders().catchError((e, stackTrace) {
      Log.error(
        'Failed to reschedule reminders on startup',
        error: e,
        stackTrace: stackTrace,
      );
    });
    Log.debug('ReminderService initialized and rescheduling started');
  } catch (e, stackTrace) {
    Log.error(
      'Failed to initialize ReminderService - reminders may not be up-to-date. Error: $e',
      error: e,
      stackTrace: stackTrace,
    );
    // Continue - app can function without reminder rescheduling
  }

  // Initialize auto-backup service (non-critical - app continues even if it fails)
  if (habitRepository != null) {
    try {
      AutoBackupService.init(habitRepository);

      // Check if backup is due on app startup
      if (PreferencesService.getAutoBackupEnabled()) {
        // Check if backup is due (run in background to not block app startup)
        AutoBackupService.checkAndCreateBackupIfDue().catchError((
          e,
          stackTrace,
        ) {
          Log.error(
            'Failed to check/create backup on startup',
            error: e,
            stackTrace: stackTrace,
          );
        });
      }

      Log.debug('AutoBackupService initialized successfully');
    } catch (e, stackTrace) {
      Log.error(
        'Failed to initialize AutoBackupService - auto-backups will not be available. Error: $e',
        error: e,
        stackTrace: stackTrace,
      );
      // Continue - app can function without auto-backups
    }
  }

  // Get saved language from preferences (with fallback if service failed)
  Locale startLocale;
  try {
    final savedLanguage = PreferencesService.getLanguage();
    startLocale = savedLanguage != null
        ? Locale(savedLanguage)
        : const Locale('en');
    Log.info('Starting app with locale: ${startLocale.languageCode}');
  } catch (e, stackTrace) {
    Log.error(
      'Failed to get saved language from preferences, using default locale. Error: $e',
      error: e,
      stackTrace: stackTrace,
    );
    startLocale = const Locale('en');
    Log.info('Using default locale: en (fallback due to preferences error)');
  }

  // Initialize settings framework
  SettingsProviders? settingsProviders;
  try {
    settingsProviders = await initializeAdatiSettings();
    Log.debug('Settings framework initialized successfully');
  } catch (e, stackTrace) {
    Log.error(
      'Failed to initialize settings framework. Error: $e',
      error: e,
      stackTrace: stackTrace,
    );
    // Continue - settings page will show error but app can function
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: startLocale,
      child: ProviderScope(
        overrides: [
          if (settingsProviders != null) ...[
            adatiSettingsControllerProvider.overrideWithValue(
              settingsProviders.controller,
            ),
            adatiSettingsSearchIndexProvider.overrideWithValue(
              settingsProviders.searchIndex,
            ),
            adatiSettingsProvider.overrideWithValue(settingsProviders),
          ],
        ],
        child: const App(),
      ),
    ),
  );
}

final navigatorKey = GlobalKey<NavigatorState>();
