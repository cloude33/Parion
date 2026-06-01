import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_scheduler_service.dart';
import 'notification_service.dart';
import '../models/app_notification.dart' as models;

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationSchedulerService _notificationService = NotificationSchedulerService();
  final NotificationService _notificationStore = NotificationService();

  static const String _tokenKey = 'fcm_token';

  String? _currentToken;
  String? get currentToken => _currentToken;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _requestPermission();
      await _getToken();
      _setupForegroundHandler();
      _setupBackgroundHandler();
      _setupTokenRefreshHandler();
      _initialized = true;
      debugPrint('FcmService: Initialized successfully');
    } catch (e) {
      debugPrint('FcmService: Initialization error: $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      debugPrint('FcmService: Permission granted: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('FcmService: Permission request error: $e');
    }
  }

  Future<void> _getToken() async {
    try {
      _currentToken = await _messaging.getToken();
      await _saveToken(_currentToken);
      debugPrint('FcmService: Token: $_currentToken');
    } catch (e) {
      debugPrint('FcmService: Get token error: $e');
    }
  }

  Future<String?> getToken() async {
    if (_currentToken == null) {
      await _getToken();
    }
    return _currentToken;
  }

  Future<void> _saveToken(String? token) async {
    if (token == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  void _setupTokenRefreshHandler() {
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('FcmService: Token refreshed: $token');
      _currentToken = token;
      _saveToken(token);
    });
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _setupBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('FcmService: Foreground message: ${message.messageId}');

    final data = message.data;
    final notification = message.notification;

    if (notification != null) {
      final type = _parseNotificationType(data['type']);
      final appNotification = models.AppNotification(
        id: message.messageId ?? '${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        title: notification.title ?? 'Parion',
        message: notification.body ?? '',
        createdAt: DateTime.now(),
        data: data,
      );

      await _notificationStore.addNotification(appNotification);

      await _notificationService.showNotification(
        id: _hashMessageId(message.messageId),
        title: notification.title ?? 'Parion',
        body: notification.body ?? '',
        payload: json.encode(data),
      );
    } else if (data.isNotEmpty) {
      final title = data['title'] ?? 'Parion';
      final body = data['body'] ?? '';

      final type = _parseNotificationType(data['type']);
      final appNotification = models.AppNotification(
        id: message.messageId ?? '${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        title: title,
        message: body,
        createdAt: DateTime.now(),
        data: data,
      );

      await _notificationStore.addNotification(appNotification);

      await _notificationService.showNotification(
        id: _hashMessageId(message.messageId),
        title: title,
        body: body,
        payload: json.encode(data),
      );
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    debugPrint('FcmService: Background message: ${message.messageId}');
  }

  models.NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'backup_error':
        return models.NotificationType.fcmBackupError;
      case 'campaign':
        return models.NotificationType.fcmCampaign;
      case 'transaction_alert':
        return models.NotificationType.fcmTransactionAlert;
      case 'limit_warning':
        return models.NotificationType.fcmLimitWarning;
      default:
        return models.NotificationType.general;
    }
  }

  int _hashMessageId(String? messageId) {
    if (messageId == null) return DateTime.now().millisecondsSinceEpoch.hashCode;
    return messageId.hashCode;
  }

  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _currentToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      debugPrint('FcmService: Token deleted');
    } catch (e) {
      debugPrint('FcmService: Delete token error: $e');
    }
  }
}
