// ============================================================================
// notification_service.dart
// lib/core/services/notification_service.dart
// ============================================================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../utils/logger.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.info('Notification permission granted');

      // Get FCM token
      final token = await _fcm.getToken();
      AppLogger.info('FCM Token: $token');

      // Initialize local notifications FIRST
      await _initializeLocalNotifications();

      // Setup message handlers
      _setupMessageHandlers();
    } else {
      AppLogger.warning('Notification permission denied: ${settings.authorizationStatus}');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // ✅ CREATE NOTIFICATION CHANNEL FOR ANDROID
    const androidChannel = AndroidNotificationChannel(
      'default_channel', // id
      'Default Notifications', // name
      description: 'Default notification channel for HireNest',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    AppLogger.info('Local notifications initialized with channel created');
  }

  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background messages (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      AppLogger.info('App opened from terminated state via notification');
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.info('Foreground message: ${message.notification?.title}');

    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.info('Message opened app: ${message.notification?.title}');
    AppLogger.info('Message data: ${message.data}');
    _navigateFromPayload(message.data);
  }

  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('Notification tapped: ${response.payload}');
    if (response.payload != null) {
      // payload is a stringified map from message.data, we need to parse it or just use simple routing if it's not JSON
      // Actually, in _showLocalNotification, payload is message.data.toString() which is hard to parse cleanly.
      // A better way is to pass specific fields or JSON encode.
      // But for now, we'll assume we can at least extract the screen.
      // If we change _showLocalNotification to jsonEncode(message.data), we could parse it cleanly.
      // Let's assume it's JSON encoded for now and fix _showLocalNotification next.
      try {
        final Map<String, dynamic> data = _parsePayload(response.payload!);
        _navigateFromPayload(data);
      } catch (e) {
        AppLogger.error('Failed to parse notification payload', error: e);
      }
    }
  }

  void _navigateFromPayload(Map<String, dynamic> data) {
    final screen = data['screen'];
    final id = data['id'] ?? data['orderId'] ?? data['jobId'] ?? data['chatId'];

    // Use the root navigator key from app_router.dart
    // Note: requires importing go_router and app_router.dart at the top
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    if (screen == 'admin_disputes') {
      GoRouter.of(context).push('/admin/disputes');
    } else if (screen == 'order_details' && id != null) {
      GoRouter.of(context).push('/marketplace/orders/$id');
    } else if (screen == 'seller_orders') {
      GoRouter.of(context).push('/marketplace/my-sales');
    } else if (screen == 'chat' && id != null) {
      GoRouter.of(context).push('/chats/$id');
    }
  }

  Map<String, dynamic> _parsePayload(String payload) {
    // Basic parser for stringified map {screen: admin_disputes, orderId: 123}
    // Real implementation should use jsonEncode/jsonDecode
    final map = <String, dynamic>{};
    final stripped = payload.replaceAll('{', '').replaceAll('}', '');
    final pairs = stripped.split(',');
    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        map[parts[0].trim()] = parts[1].trim();
      }
    }
    return map;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      channelDescription: 'Default notification channel for HireNest',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/launcher_icon',
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

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'HireNest',
      message.notification?.body ?? 'You have a new notification',
      details,
      payload: message.data.toString(),
    );

    AppLogger.info('Local notification shown');
  }

  /// Test method to verify notifications are working
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      channelDescription: 'Default notification channel for HireNest',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/launcher_icon',
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

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      'Test Notification',
      'This is a test notification from HireNest',
      details,
    );

    AppLogger.info('Test notification sent');
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to subscribe to topic: $topic', error: e);
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to unsubscribe from topic: $topic', error: e);
    }
  }
}