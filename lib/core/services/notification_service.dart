import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'platform_utils.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin? _notifications = kIsWeb
      ? null
      : FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static GoRouter? _router;

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
          // Try to navigate using GoRouter if available
          if (_router != null) {
            // Use post-frame callback to ensure navigation happens after widget tree is built
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                _router!.go('/timeline');
                Log.info('Navigated to timeline from notification tap');
              } catch (e, stackTrace) {
                Log.error(
                  'Failed to navigate using GoRouter',
                  error: e,
                  stackTrace: stackTrace,
                );
              }
            });
          } else {
            Log.warning('Cannot navigate: GoRouter is not set. Call NotificationService.setRouter() during app initialization.');
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
  }

  /// Set the GoRouter instance for navigation
  static void setRouter(GoRouter router) {
    _router = router;
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

  /// Check if notification permissions are granted
  /// Returns true if permissions are granted, false otherwise
  static Future<bool> checkPermissions() async {
    if (kIsWeb) {
      // Web permissions are checked separately
      return await _getWebNotificationPermission() == 'granted';
    }

    if (_notifications == null || !_initialized) {
      return false;
    }

    try {
      final androidPlugin = _notifications!
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        if (enabled == false) {
          Log.info('Android notifications are not enabled');
          return false;
        }
      }

      // For iOS, we can't directly check permissions, but if initialized
      // and no errors occurred, assume permissions are granted
      // Desktop platforms don't require explicit permissions
      return true;
    } catch (e, stackTrace) {
      Log.error(
        'Failed to check notification permissions',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
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
      Log.warning(
        'Notifications not available - _notifications: ${_notifications != null}, _initialized: $_initialized',
      );
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

  /// Schedule a precise notification for a specific date and time
  /// Uses exact alarms on Android (if permission granted) and scheduled notifications on iOS
  /// Returns true if scheduled successfully, false otherwise
  static Future<bool> schedulePreciseNotification({
    required int id,
    required DateTime scheduledDate,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      Log.warning('Precise notifications not supported on web');
      return false;
    }

    if (_notifications == null || !_initialized) {
      Log.warning('Notifications not available for scheduling');
      return false;
    }

    try {
      // Convert to timezone-aware datetime
      final scheduledTz = tz.TZDateTime.from(scheduledDate, tz.local);
      final nowTz = tz.TZDateTime.now(tz.local);

      // Don't schedule if the time is in the past (with 30 second buffer)
      if (scheduledTz.isBefore(nowTz.subtract(const Duration(seconds: 30)))) {
        Log.warning(
          'Cannot schedule notification in the past: $scheduledTz (now: $nowTz)',
        );
        return false;
      }

      // For very short delays (< 2 minutes), use immediate notification instead
      // Some platforms don't handle very short scheduled notifications well
      final delay = scheduledTz.difference(nowTz);
      if (delay.inSeconds < 120) {
        Log.info(
          'Notification scheduled for less than 2 minutes away ($delay), '
          'using immediate notification with delay instead',
        );
        
        // Use Future.delayed for very short delays
        Future.delayed(delay, () async {
          try {
            await showNotification(
              id: id,
              title: title,
              body: body,
              payload: payload,
            );
            Log.info('Immediate delayed notification shown: $title');
          } catch (e, stackTrace) {
            Log.error(
              'Failed to show immediate delayed notification',
              error: e,
              stackTrace: stackTrace,
            );
          }
        });
        return true;
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

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification
      await _notifications!.zonedSchedule(
        id,
        title,
        body,
        scheduledTz,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      Log.info(
        'Scheduled precise notification (ID: $id) for ${scheduledTz.toString()} '
        '(in ${delay.inMinutes} minutes)',
      );
      return true;
    } catch (e, stackTrace) {
      // On some platforms (like desktop), zonedSchedule may not be supported
      if (e is UnimplementedError) {
        Log.info(
          'Precise scheduling not supported on this platform, notification will not be scheduled',
        );
        return false;
      }
      Log.error(
        'Failed to schedule precise notification',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Cancel a scheduled notification by ID
  /// [silent] - If true, suppresses debug logging (useful when canceling many notifications)
  static Future<void> cancelScheduledNotification(int id, {bool silent = false}) async {
    if (kIsWeb || _notifications == null || !_initialized) {
      return;
    }

    try {
      await _notifications!.cancel(id);
      if (!silent) {
        Log.debug('Cancelled scheduled notification: $id');
      }
    } catch (e, stackTrace) {
      // Only log errors, not debug messages for silent cancellations
      if (!silent) {
        Log.error(
          'Failed to cancel scheduled notification: $id',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }
}
