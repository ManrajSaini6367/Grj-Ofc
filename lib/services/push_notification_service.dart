import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:grjoffice_apps/firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles FCM setup and shows system notifications (including foreground).
class PushNotificationService {
  PushNotificationService._();

  static const channelId = 'grj_push_notifications';
  static const channelName = 'GRJ Notifications';
  static const channelDescription = 'Push notifications from GRJ Office';

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[FCM] Background message: ${message.messageId}');
    // Android shows notification payload automatically when app is backgrounded.
    // For data-only messages, show a local notification.
    if (message.notification == null && message.data.isNotEmpty) {
      await _ensureLocalNotificationsReady();
      await showRemoteMessage(message);
    }
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    await _ensureLocalNotificationsReady();
    await _requestPermissions();

    // iOS: show banners while app is in foreground.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // iOS Simulators do not receive an APNs token.  FCM therefore throws when
    // asking for an FCM token, but that must not prevent the app UI from
    // starting.
    try {
      final token = await _messaging.getToken();
      debugPrint('====================================');
      debugPrint('FCM TOKEN :');
      debugPrint(token);
      debugPrint('====================================');
      debugPrint(
        '[FCM] Tip: Firebase Console → Messaging → "Send test message" '
        'and paste this token. Campaigns may not reach debug devices instantly.',
      );
    } catch (error) {
      debugPrint('[FCM] Token unavailable: $error');
    }

    // Topic makes broadcast tests easier from Firebase Console.
    try {
      await _messaging.subscribeToTopic('grj_office');
      debugPrint('[FCM] Subscribed to topic: grj_office');
    } catch (e) {
      debugPrint('[FCM] Topic subscribe failed: $e');
    }

    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed: $newToken');
    });

    // Foreground: FCM does not auto-display on Android — show locally.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
      showRemoteMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Opened from notification: ${message.messageId}');
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] Launched from notification: ${initial.messageId}');
    }

    _initialized = true;
  }

  static Future<void> _ensureLocalNotificationsReady() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[FCM] Local notification tapped: ${response.payload}');
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      ),
    );
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
  }

  static Future<void> showRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ??
        message.data['title']?.toString() ??
        'GRJ Office';
    final body = notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        '';

    if (title.trim().isEmpty && body.trim().isEmpty) return;

    final id = message.hashCode & 0x7fffffff;
    final payload = jsonEncode(message.data);

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }
}
