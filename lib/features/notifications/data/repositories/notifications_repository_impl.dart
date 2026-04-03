// lib/features/notifications/data/repositories/notifications_repository_impl.dart

import 'package:build4front/features/notifications/data/services/notifications_api_service.dart';
import 'package:build4front/features/notifications/domain/entities/app_notification.dart';
import 'package:build4front/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsApiService api;

  NotificationsRepositoryImpl(this.api);

  @override
  Future<List<AppNotification>> getMyNotifications() async {
    final models = await api.getMyNotifications();
    return models
        .map(
          (m) => AppNotification(
            id: m.id,
            title: m.title,
            body: m.body,
            notificationType: m.notificationType,
            payloadJson: m.payloadJson,
            isRead: m.isRead,
            createdAt: m.createdAt,
            readAt: m.readAt,
          ),
        )
        .toList();
  }

  @override
  Future<int> getUnreadCount() => api.getUnreadCount();

  @override
  Future<void> markAsRead(int id) => api.markAsRead(id);

  @override
  Future<void> deleteNotification(int id) => api.deleteNotification(id);
}