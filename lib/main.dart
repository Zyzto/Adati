import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'core/services/preferences_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/logging_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone
  tz.initializeTimeZones();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    LoggingService.warning('No .env file found, continuing without it');
  }

  // Initialize localization
  await EasyLocalization.ensureInitialized();

  // Initialize services
  await PreferencesService.init();

  // Initialize notifications (non-blocking - app continues even if it fails)
  try {
    await NotificationService.init();
    await NotificationService.requestPermissions();
  } catch (e, stackTrace) {
    LoggingService.error(
      'Notification initialization failed, continuing without notifications',
      e,
      stackTrace,
    );
  }

  // Get saved language from preferences
  final savedLanguage = PreferencesService.getLanguage();
  final startLocale = savedLanguage != null
      ? Locale(savedLanguage)
      : const Locale('en');

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
