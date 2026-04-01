// lib/features/notifications/data/datasources/notifications_api_service.dart

import 'package:dio/dio.dart';
import 'package:build4front/core/network/globals.dart' as g;

import '../models/notification_model.dart';

class NotificationsApiService {
  final Dio _dio;

  NotificationsApiService() : _dio = g.dio();
Future<List<NotificationModel>> getMyNotifications() async {
  final resp = await _dio.get('/api/front/notifications');

  print('NOTIF STATUS => ${resp.statusCode}');
  print('NOTIF RAW DATA => ${resp.data}');

  final data = resp.data;

  if (data is List) {
    for (final item in data) {
      print('NOTIF ITEM => $item');
    }

    return data
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  if (data is Map<String, dynamic>) {
    final items = data['items'] ?? data['content'] ?? data['data'];

    print('NOTIF WRAPPED ITEMS => $items');

    if (items is List) {
      return items
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  return [];
}
  Future<void> registerFrontFcmToken({
    required int ownerProjectLinkId,
    required String fcmToken,
    required String platform,
    String? packageName,
    String? bundleId,
    String? deviceId,
  }) async {
    await _dio.put(
      '/api/front/device-token',
      data: {
        'ownerProjectLinkId': ownerProjectLinkId,
        'fcmToken': fcmToken,
        'platform': platform,
        'packageName': packageName,
        'bundleId': bundleId,
        'deviceId': deviceId,
      },
    );
  }

  Future<int> getUnreadCount() async {
    final resp = await _dio.get('/api/front/notifications/unread-count');
    final data = resp.data;

    if (data is int) return data;
    if (data is num) return data.toInt();

    if (data is Map<String, dynamic>) {
      final unread = data['unreadCount'];
      if (unread is int) return unread;
      if (unread is num) return unread.toInt();
      return int.tryParse((unread ?? '').toString()) ?? 0;
    }

    return int.tryParse(data.toString()) ?? 0;
  }

  Future<void> markAsRead(int id) async {
    await _dio.put('/api/front/notifications/$id/read');
  }

  Future<void> deleteNotification(int id) async {
    await _dio.delete('/api/front/notifications/$id');
  }

  // legacy - leave only if still needed elsewhere
  Future<void> updateUserFcmToken(String fcmToken) async {
    await _dio.put(
      '/api/notifications/user/fcm-token',
      data: {'fcmToken': fcmToken},
    );
  }
}