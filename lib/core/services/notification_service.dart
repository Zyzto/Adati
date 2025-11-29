import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'log_helper.dart';
import 'platform_utils.dart';
import '../../main.dart' show navigatorKey;

class NotificationService {
  static final FlutterLocalNotificationsPlugin? _notifications = kIsWeb
      ? null
      : FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static Function(String?)? _onNotificationTapCallback;

  static Future<void> init() async {
    if (kIsWeb) {
      // Web notifications are handled separately
      _initialized = true;
      Log.info('NotificationService initialized for web (using browser API)');
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

      // Desktop notification settings
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );
      const macOsSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      // Windows notifications require app identification
      const windowsSettings = WindowsInitializationSettings(
        appName: 'Adati',
        appUserModelId: 'com.adati.app',
        guid: 'adati-habit-tracker',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        linux: linuxSettings,
        macOS: macOsSettings,
        windows: windowsSettings,
      );

      await _notifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channel (required for Android 8.0+)
      // Note: Channel name/description are set when creating notifications,
      // but we create the channel here to ensure it exists
      if (!kIsWeb) {
        final androidPlugin = _notifications!
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          try {
            // Use translated strings for channel name and description
            // Fallback to English if localization isn't ready yet
            String channelName;
            String channelDescription;
            try {
              channelName = 'habit_reminders'.tr();
              channelDescription = 'habit_reminders_description'.tr();
            } catch (e) {
              // Localization not ready, use English fallback
              channelName = 'Habit Reminders';
              channelDescription = 'Notifications for habit reminders';
            }
            
            final androidChannel = AndroidNotificationChannel(
              'habit_reminders',
              channelName,
              description: channelDescription,
              importance: Importance.high,
              enableVibration: true,
              enableLights: true,
              playSound: true,
              showBadge: true,
            );
            await androidPlugin.createNotificationChannel(androidChannel);
            Log.info('Android notification channel created');
          } catch (e, stackTrace) {
            Log.warning(
              'Failed to create Android notification channel',
              error: e,
              stackTrace: stackTrace,
            );
            // Continue - channel might already exist or be created automatically
          }
        }
      }

      _initialized = true;
      Log.info('NotificationService initialized');
    } catch (e, stackTrace) {
      Log.error(
        'Failed to initialize NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      _initialized = false;
      // Don't throw - allow app to continue without notifications
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    Log.info('Notification tapped: ${response.payload}');
    
    // Handle navigation
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final habitId = int.tryParse(payload);
        if (habitId != null) {
          // Navigate to timeline (could be enhanced to navigate to specific habit)
          final context = navigatorKey.currentContext;
          if (context != null) {
            // Navigate to timeline - user can see the habit there
            context.go('/timeline');
            Log.info('Navigated to timeline from notification tap');
          } else {
            Log.warning('Cannot navigate: navigator context is null');
          }
        }
      } catch (e, stackTrace) {
        Log.error(
          'Failed to handle notification tap navigation',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    
    // Call custom callback if set
    _onNotificationTapCallback?.call(payload);
  }

  /// Set a custom callback for notification taps
  static void setNotificationTapCallback(Function(String?)? callback) {
    _onNotificationTapCallback = callback;
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) {
      // Web notifications use browser API
      return await _requestWebPermissions();
    }

    if (_notifications == null || !_initialized) {
      return false;
    }

    try {
      final androidPlugin = _notifications!
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
      
      bool? androidPermission;
      if (androidPlugin != null) {
        // Check current permission status first
        final currentPermission = await androidPlugin.areNotificationsEnabled();
        Log.info('Android notifications enabled: $currentPermission');
        
        if (currentPermission == false) {
          // Request permission
          androidPermission = await androidPlugin.requestNotificationsPermission();
          Log.info('Android notification permission requested: $androidPermission');
        } else {
          androidPermission = true;
        }
      }

      final ios = await _notifications!
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      // Desktop platforms don't require explicit permission requests
      // They use system notification settings
      if (isDesktop) {
        return true; // Assume available on desktop
      }

      // Check exact alarm permission on Android (Android 12+)
      // Note: Exact alarm permission must be granted by user in system settings
      // We can only check if it's granted, not request it programmatically
      if (androidPlugin != null) {
        try {
          final canScheduleExact = await androidPlugin.canScheduleExactNotifications();
          if (canScheduleExact == false) {
            Log.info(
              'Exact alarm permission not granted. '
              'Notifications will use inexact scheduling (may be less precise). '
              'User can grant exact alarm permission in system settings.',
            );
          }
        } catch (e) {
          // Ignore errors checking exact alarm permission
          Log.debug('Could not check exact alarm permission: $e');
        }
      }

      final result = androidPermission ?? ios ?? false;
      Log.info('Notification permissions result: $result');
      return result;
    } catch (e, stackTrace) {
      Log.error(
        'Failed to request notification permissions',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Request web notification permissions using browser API
  static Future<bool> _requestWebPermissions() async {
    if (!kIsWeb) {
      return false;
    }

    try {
      // Check if browser supports notifications
      if (!_isWebNotificationSupported()) {
        Log.warning('Browser does not support notifications');
        return false;
      }

      // Check current permission status
      final permission = await _getWebNotificationPermission();
      if (permission == 'granted') {
        return true;
      }

      if (permission == 'denied') {
        Log.warning('Notification permission denied by user');
        return false;
      }

      // Request permission (permission == 'default')
      // Note: This requires user interaction (e.g., button click)
      // We can't request it programmatically without user action
      Log.info('Notification permission needs to be requested by user');
      return false;
    } catch (e, stackTrace) {
      Log.error(
        'Failed to request web notification permissions',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Check if web notifications are supported
  static bool _isWebNotificationSupported() {
    if (!kIsWeb) return false;
    // This will be implemented using dart:html or js interop
    // For now, return true and handle at runtime
    return true;
  }

  /// Get current web notification permission status
  static Future<String> _getWebNotificationPermission() async {
    if (!kIsWeb) return 'denied';
    // Web notification permission checking requires dart:html
    // For now, return 'default' - actual implementation would use:
    // import 'dart:html' as html;
    // return html.window.Notification.permission;
    return 'default';
  }

  /// Show a web notification immediately
  static Future<void> _showWebNotification(
    String title,
    String body,
    String? payload,
  ) async {
    if (!kIsWeb) return;

    try {
      // Web notifications require dart:html
      // Actual implementation would be:
      // import 'dart:html' as html;
      // if (html.window.Notification.permission == 'granted') {
      //   final notification = html.Notification(title, body: body, tag: payload);
      //   notification.onClick.listen((_) {
      //     _onNotificationTapped(NotificationResponse(payload: payload));
      //   });
      // }
      Log.info('Web notification: $title - $body (payload: $payload)');
      Log.info(
        'Note: Full web notification support requires dart:html. '
        'Scheduled notifications on web need a service worker implementation.',
      );
    } catch (e, stackTrace) {
      Log.error(
        'Failed to show web notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if notifications are available on the current platform
  static bool isAvailable() {
    if (kIsWeb) {
      // Web notifications depend on browser support
      return true; // Will be checked at runtime
    }
    return _initialized && _notifications != null;
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (kIsWeb) {
      // Web notifications require service worker for scheduled notifications
      // For now, we can only show immediate notifications
      // Scheduled notifications on web would need a service worker implementation
      final now = DateTime.now();
      if (scheduledDate.isBefore(now) || scheduledDate.difference(now).inSeconds < 1) {
        // Show immediate notification if time has passed or is very soon
        await _showWebNotification(title, body, payload);
      } else {
        Log.info(
          'Web scheduled notifications require service worker. Notification for $scheduledDate will not be scheduled.',
        );
      }
      return;
    }

    if (_notifications == null || !_initialized) {
      Log.info('Notifications not available on this platform');
      return;
    }

    // Platform-specific notification details
    final androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'habit_reminders'.tr(),
      channelDescription: 'habit_reminders_description'.tr(),
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      channelShowBadge: true,
      playSound: true,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Desktop notification details
    final linuxDetails = LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.normal,
    );
    const macOsDetails = DarwinNotificationDetails();
    const windowsDetails = WindowsNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      linux: linuxDetails,
      macOS: macOsDetails,
      windows: windowsDetails,
    );

    try {
      // Desktop platforms may not support zonedSchedule, use show() for immediate notifications
      // or handle scheduled notifications differently
      if (isDesktop) {
        // On desktop, check if notification is in the near future
        final now = DateTime.now();
        final timeUntilNotification = scheduledDate.difference(now);
        
        if (timeUntilNotification.inSeconds <= 0) {
          // Show immediately if time has passed
          await _notifications!.show(
            id,
            title,
            body,
            notificationDetails,
            payload: payload,
          );
        } else if (timeUntilNotification.inSeconds <= 60) {
          // For notifications within 60 seconds, show immediately
          // Desktop platforms typically don't support scheduled notifications
          await _notifications!.show(
            id,
            title,
            body,
            notificationDetails,
            payload: payload,
          );
          Log.info(
            'Desktop platform: Showing notification immediately (scheduled notifications not fully supported)',
          );
        } else {
          // For future notifications on desktop, zonedSchedule is not implemented
          // Show immediately with a note that scheduled notifications aren't supported
          Log.warning(
            'Desktop platform: Scheduled notifications are not fully supported. '
            'Notification scheduled for $scheduledDate will be shown immediately.',
          );
          await _notifications!.show(
            id,
            title,
            body,
            notificationDetails,
            payload: payload,
          );
        }
      } else {
        // Mobile platforms support zonedSchedule
        // Try exact scheduling first, fall back to inexact if exact alarms aren't permitted
        try {
          // Check if exact alarms are permitted (Android 12+)
          final androidPlugin = _notifications!
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
          
          bool canScheduleExact = true;
          if (androidPlugin != null) {
            try {
              canScheduleExact = await androidPlugin.canScheduleExactNotifications() ?? true;
            } catch (e) {
              // If check fails, assume we can't schedule exact alarms
              canScheduleExact = false;
              Log.warning('Could not check exact alarm permission: $e');
            }
          }

          // Use appropriate scheduling mode
          final scheduleMode = canScheduleExact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle;

          await _notifications!.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime.from(scheduledDate, tz.local),
            notificationDetails,
            androidScheduleMode: scheduleMode,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: payload,
          );
        } catch (e) {
          // Handle PlatformException for exact alarms not permitted
          if (e is PlatformException && 
              (e.code == 'exact_alarms_not_permitted' || 
               e.message?.contains('exact') == true)) {
            Log.warning(
              'Exact alarms not permitted. Falling back to inexact scheduling.',
            );
            try {
              // Fall back to inexact scheduling
              await _notifications!.zonedSchedule(
                id,
                title,
                body,
                tz.TZDateTime.from(scheduledDate, tz.local),
                notificationDetails,
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                matchDateTimeComponents: DateTimeComponents.time,
                payload: payload,
              );
            } catch (fallbackError) {
              // If inexact also fails, show immediately
              Log.warning(
                'Inexact scheduling also failed. Showing notification immediately.',
              );
              await _notifications!.show(
                id,
                title,
                body,
                notificationDetails,
                payload: payload,
              );
            }
          } else if (e is UnimplementedError) {
            // If zonedSchedule is not implemented (e.g., on some desktop platforms),
            // fall back to showing immediately
            Log.warning(
              'zonedSchedule() not implemented on this platform. '
              'Showing notification immediately instead.',
            );
            await _notifications!.show(
              id,
              title,
              body,
              notificationDetails,
              payload: payload,
            );
          } else {
            // Re-throw if it's a different error
            rethrow;
          }
        }
      }
    } catch (e, stackTrace) {
      // Handle any remaining errors
      if (e is UnimplementedError) {
        Log.warning(
          'Scheduled notifications not implemented on this platform. '
          'Showing notification immediately instead.',
        );
        try {
          // Fallback: show notification immediately
          await _notifications!.show(
            id,
            title,
            body,
            notificationDetails,
            payload: payload,
          );
        } catch (showError, showStackTrace) {
          Log.error(
            'Failed to show notification as fallback',
            error: showError,
            stackTrace: showStackTrace,
          );
        }
      } else {
        Log.error('Failed to schedule notification', error: e, stackTrace: stackTrace);
      }
    }
  }

  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) {
      // Web notifications cancellation will be handled separately
      return;
    }

    if (_notifications == null || !_initialized) {
      return;
    }
    try {
      await _notifications!.cancel(id);
    } catch (e, stackTrace) {
      Log.error('Failed to cancel notification', error: e, stackTrace: stackTrace);
    }
  }

  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) {
      // Web notifications cancellation will be handled separately
      return;
    }

    if (_notifications == null || !_initialized) {
      return;
    }
    try {
      await _notifications!.cancelAll();
    } catch (e, stackTrace) {
      Log.error('Failed to cancel all notifications', error: e, stackTrace: stackTrace);
    }
  }

  /// Show an immediate notification (for testing or instant notifications)
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      await _showWebNotification(title, body, payload);
      return;
    }

    if (_notifications == null || !_initialized) {
      Log.info('Notifications not available on this platform');
      return;
    }

    try {
      // Platform-specific notification details
      final androidDetails = AndroidNotificationDetails(
        'habit_reminders',
        'habit_reminders'.tr(),
        channelDescription: 'habit_reminders_description'.tr(),
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        channelShowBadge: true,
        playSound: true,
      );

      final iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Desktop notification details
      final linuxDetails = LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.normal,
      );
      const macOsDetails = DarwinNotificationDetails();
      const windowsDetails = WindowsNotificationDetails();

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        linux: linuxDetails,
        macOS: macOsDetails,
        windows: windowsDetails,
      );

      await _notifications!.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      Log.info('Notification shown: $title');
    } catch (e, stackTrace) {
      Log.error('Failed to show notification', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
