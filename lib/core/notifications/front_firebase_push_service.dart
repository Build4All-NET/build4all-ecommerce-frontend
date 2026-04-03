import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:build4front/features/notifications/data/services/notifications_api_service.dart';

class FrontFirebasePushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationsApiService _api = NotificationsApiService();

  Future<void> initAndSyncToken({
    required int ownerProjectLinkId,
  }) async {
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
  }
}