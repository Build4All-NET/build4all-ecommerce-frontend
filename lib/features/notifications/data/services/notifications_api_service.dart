// lib/features/notifications/data/datasources/notifications_api_service.dart

import 'package:dio/dio.dart';
import 'package:build4front/core/network/globals.dart' as g;

import '../models/notification_model.dart';

class NotificationsApiService {
  final Dio _dio;

  NotificationsApiService() : _dio = g.dio();

  Future<List<NotificationModel>> getMyNotifications() async {
    final resp = await _dio.get('/api/notifications');
    final data = resp.data;

    if (data is List) {
      return data
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
    final resp = await _dio.get('/api/notifications/unread-count');
    final data = resp.data;
    if (data is int) return data;
    if (data is num) return data.toInt();
    return int.tryParse(data.toString()) ?? 0;
  }

  Future<void> markAsRead(int id) async {
    await _dio.put('/api/notifications/$id/read');
  }

  Future<void> deleteNotification(int id) async {
    await _dio.delete('/api/notifications/$id');
  }

  // Optional (you already have backend endpoint)
  Future<void> updateUserFcmToken(String fcmToken) async {
    await _dio.put(
      '/api/notifications/user/fcm-token',
      data: {'fcmToken': fcmToken},
    );
  }
}
