import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum NotificationPriority { low, normal, high, urgent }

class NotificationSchedulerService {
  static final NotificationSchedulerService _instance =
      NotificationSchedulerService._internal();

  factory NotificationSchedulerService() => _instance;

  NotificationSchedulerService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('NotificationService: Local timezone set to $timeZoneName');
    } catch (e) {
      debugPrint('NotificationService: Failed to get/set local timezone: $e');
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      debugPrint('NotificationService: Fallback timezone set to Europe/Istanbul');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    bool? androidGranted;
    if (androidPlugin != null) {
      androidGranted = await androidPlugin.requestNotificationsPermission();
      debugPrint('NotificationService: Android notifications permission granted: $androidGranted');
      
      try {
        // Check for exact alarm permission on Android 12+
        final status = await Permission.scheduleExactAlarm.status;
        if (status.isDenied) {
          debugPrint('NotificationService: Requesting scheduleExactAlarm permission');
          // We can't request this permission directly, we should guide user to settings
          // But some devices might allow requesting it via intent if not strictly denied
          // For now, let's log it.
        } else {
          debugPrint('NotificationService: scheduleExactAlarm permission status: $status');
        }
      } catch (e) {
        debugPrint('NotificationService: Error checking scheduleExactAlarm permission: $e');
      }
    }

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    bool? iosGranted;
    if (iosPlugin != null) {
      iosGranted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('NotificationService: iOS permissions granted: $iosGranted');
    }

    return androidGranted ?? iosGranted ?? false;
  }

  Future<bool> checkAndroidScheduleExactAlarmPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    
    // Android 12+ (API 31+) requires this permission
    // But we need to check device version first to avoid errors on older versions
    // permission_handler handles version checks internally mostly, but let's be safe
    try {
       final status = await Permission.scheduleExactAlarm.status;
       debugPrint('NotificationService: Exact alarm permission status: $status');
       return status.isGranted;
    } catch (e) {
      debugPrint('NotificationService: Error checking exact alarm permission: $e');
      return true; // Assume true on error or older versions
    }
  }

  Future<void> requestAndroidScheduleExactAlarmPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Permission.scheduleExactAlarm.request();
      // On Android 12+, this might not show a dialog but we can redirect to settings
      // if the status is still denied.
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied || status.isPermanentlyDenied) {
         debugPrint('NotificationService: Redirecting to settings for exact alarm');
         await openAppSettings();
      }
    } catch (e) {
      debugPrint('NotificationService: Error requesting exact alarm permission: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    List<AndroidNotificationAction>? actions,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'general_notifications',
      'General Notifications',
      channelDescription: 'General app notifications and reminders',
      importance: _getImportance(priority),
      priority: Priority.high,
      actions: actions,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> schedulePeriodicNotification({
    required int id,
    required String title,
    required String body,
    required RepeatInterval interval,
    TimeOfDay? timeOfDay,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'periodic_notifications_v2',
      'Periodic Notifications',
      channelDescription: 'Daily and weekly summaries',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (timeOfDay != null) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
      
      debugPrint('NotificationService: Scheduling periodic notification (ID: $id)');
      debugPrint('NotificationService: Current time: $now');
      debugPrint('NotificationService: Initial scheduled time: $scheduledDate');

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        debugPrint('NotificationService: Adjusted scheduled time (next day): $scheduledDate');
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: _getDateTimeComponents(interval),
      );
      debugPrint('NotificationService: Notification scheduled successfully');
    } else {
      await _notifications.periodicallyShow(
        id,
        title,
        body,
        interval,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    List<AndroidNotificationAction>? actions,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'instant_notifications',
      'Instant Notifications',
      channelDescription: 'Immediate notifications',
      importance: _getImportance(priority),
      priority: Priority.high,
      actions: actions,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }

  DateTimeComponents? _getDateTimeComponents(RepeatInterval interval) {
    switch (interval) {
      case RepeatInterval.daily:
        return DateTimeComponents.time;
      case RepeatInterval.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      default:
        return null;
    }
  }
}
