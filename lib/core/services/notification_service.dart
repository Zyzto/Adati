import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/logging_service.dart';
import 'platform_utils.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin? _notifications = kIsWeb
      ? null
      : FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (kIsWeb) {
      LoggingService.info('NotificationService skipped on web');
      _initialized = true;
      return;
    }

    // Skip notifications on desktop platforms (Linux, Windows, macOS)
    // as they may not be fully supported
    if (isDesktop) {
      LoggingService.info('NotificationService skipped on desktop platform');
      _initialized = true;
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      LoggingService.info('NotificationService initialized');
    } catch (e, stackTrace) {
      LoggingService.error(
        'Failed to initialize NotificationService',
        e,
        stackTrace,
      );
      _initialized = false;
      // Don't throw - allow app to continue without notifications
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    LoggingService.info('Notification tapped: ${response.payload}');
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb || _notifications == null || !_initialized || isDesktop) {
      return false;
    }

    try {
      final android = await _notifications!
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      final ios = await _notifications!
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      return android ?? ios ?? false;
    } catch (e, stackTrace) {
      LoggingService.error(
        'Failed to request notification permissions',
        e,
        stackTrace,
      );
      return false;
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (kIsWeb || _notifications == null || !_initialized || isDesktop) {
      LoggingService.info('Notifications not available on this platform');
      return;
    }

    try {
      await _notifications!.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            channelDescription: 'Notifications for habit reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (e, stackTrace) {
      LoggingService.error('Failed to schedule notification', e, stackTrace);
    }
  }

  static Future<void> cancelNotification(int id) async {
    if (kIsWeb || _notifications == null || !_initialized || isDesktop) {
      return;
    }
    try {
      await _notifications!.cancel(id);
    } catch (e, stackTrace) {
      LoggingService.error('Failed to cancel notification', e, stackTrace);
    }
  }

  static Future<void> cancelAllNotifications() async {
    if (kIsWeb || _notifications == null || !_initialized || isDesktop) {
      return;
    }
    try {
      await _notifications!.cancelAll();
    } catch (e, stackTrace) {
      LoggingService.error('Failed to cancel all notifications', e, stackTrace);
    }
  }
}
