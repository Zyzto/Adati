import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'core/services/preferences_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/logging_service.dart';
import 'core/services/log_helper.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging service first
  await LoggingService.init();

  // Set up error handlers for crash reporting
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    LoggingService.severe(
      'Flutter framework error: ${details.exception}',
      component: 'CrashHandler',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Handle async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    LoggingService.severe(
      'Async error: $error',
      component: 'CrashHandler',
      error: error,
      stackTrace: stack,
    );
    return true; // Prevent default error handling
  };

  // Initialize timezone
  tz.initializeTimeZones();
  Log.debug('Timezone initialized');

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    Log.debug('Environment variables loaded');
  } catch (e) {
    Log.warning('No .env file found, continuing without it');
  }

  // Initialize localization
  await EasyLocalization.ensureInitialized();
  Log.debug('Localization initialized');

  // Initialize services
  await PreferencesService.init();
  Log.debug('PreferencesService initialized');

  // Initialize notifications (non-blocking - app continues even if it fails)
  try {
    await NotificationService.init();
    await NotificationService.requestPermissions();
    Log.debug('NotificationService initialized');
  } catch (e, stackTrace) {
    Log.error(
      'Notification initialization failed, continuing without notifications',
      error: e,
      stackTrace: stackTrace,
    );
  }

  // Get saved language from preferences
  final savedLanguage = PreferencesService.getLanguage();
  final startLocale = savedLanguage != null
      ? Locale(savedLanguage)
      : const Locale('en');
  Log.info('Starting app with locale: ${startLocale.languageCode}');

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: startLocale,
      child: const ProviderScope(child: App()),
    ),
  );
}

final navigatorKey = GlobalKey<NavigatorState>();
