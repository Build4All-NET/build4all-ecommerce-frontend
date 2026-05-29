import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';

import 'package:build4front/core/config/env.dart';
import 'package:build4front/features/notifications/data/services/notifications_api_service.dart';

class FrontFirebasePushService {
  // Lazy: accessing FirebaseMessaging.instance requires Firebase to be
  // initialized. Using `late` defers that until first use, so simply
  // constructing this service on a stub build (Firebase disabled) is safe.
  late final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationsApiService _api = NotificationsApiService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initAndSyncToken({
    required int ownerProjectLinkId,
  }) async {
    // No Firebase on stub/test builds — bail out before touching messaging.
    if (!Env.requireFirebase) {
      debugPrint('Push disabled (REQUIRE_FIREBASE=false) — skipping FCM setup');
      return;
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final packageInfo = await PackageInfo.fromPlatform();
    final appId = packageInfo.packageName;

    debugPrint('FRONT APP ID => $appId');

    final token = await _messaging.getToken();
    debugPrint('FRONT FCM TOKEN => $token');

    if (token != null && token.isNotEmpty) {
      await _api.registerFrontFcmToken(
        ownerProjectLinkId: ownerProjectLinkId,
        fcmToken: token,
        platform: Platform.isIOS ? 'IOS' : 'ANDROID',
        packageName: Platform.isAndroid ? appId : null,
        bundleId: Platform.isIOS ? appId : null,
        deviceId: null,
      );
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FRONT FCM TOKEN REFRESH => $newToken');

      await _api.registerFrontFcmToken(
        ownerProjectLinkId: ownerProjectLinkId,
        fcmToken: newToken,
        platform: Platform.isIOS ? 'IOS' : 'ANDROID',
        packageName: Platform.isAndroid ? appId : null,
        bundleId: Platform.isIOS ? appId : null,
        deviceId: null,
      );
    });

    // 🔴 ADD THIS NEW CODE:
    // Initialize local notifications for showing on lock screen
    await _initializeLocalNotifications();

    // Setup message listeners
    _setupMessageHandlers();
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );

      final InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      debugPrint('✅ Local notifications initialized');
    } catch (e) {
      debugPrint('❌ Local notifications error: $e');
    }
  }

  /// Setup message handlers for all states
  void _setupMessageHandlers() {
    // FOREGROUND: App is open
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 FOREGROUND message: ${message.notification?.title}');

      showLocalNotification(
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        payload: jsonEncode(message.data),
      );
    });

    // BACKGROUND: App open but not focused
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 BACKGROUND message tapped: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // TERMINATED: App is closed
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔔 TERMINATED message: ${message.data}');
        Future.delayed(
          const Duration(seconds: 1),
          () => _handleNotificationTap(message.data),
        );
      }
    });

    debugPrint('✅ Message handlers setup complete');
  }

  /// Show notification on lock screen
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'default_channel',
        'Notifications',
        channelDescription: 'General push notifications',
        importance: Importance.max,
        priority: Priority.high,
      );

      final DarwinNotificationDetails iosDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );

      debugPrint('✅ Local notification shown');
    } catch (e) {
      debugPrint('❌ Show notification error: $e');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('📲 Notification tapped: $data');
    // TODO: Navigate based on notification data
  }

  /// iOS callback
  Future<void> _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    debugPrint('🔔 Local notification callback: $title - $body');
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        _handleNotificationTap(data);
      } catch (e) {
        debugPrint('⚠️ Parse payload error: $e');
      }
    }
  }

  /// Tap response handler
  Future<void> _onNotificationTapped(
    NotificationResponse response,
  ) async {
    debugPrint('🔔 Notification tapped from center');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationTap(data);
      } catch (e) {
        debugPrint('⚠️ Parse response error: $e');
      }
    }
  }
}