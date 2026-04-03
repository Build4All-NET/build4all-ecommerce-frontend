// lib/features/notifications/domain/entities/app_notification.dart

class AppNotification {
  final int id;
  final String title;
  final String body;
  final String notificationType;
  final String? payloadJson;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
    this.payloadJson,
    this.readAt,
  });

  String get message {
    if (title.trim().isEmpty) return body;
    if (body.trim().isEmpty) return title;
    return '$title\n$body';
  }

  AppNotification copyWith({
    String? title,
    String? body,
    String? notificationType,
    String? payloadJson,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      notificationType: notificationType ?? this.notificationType,
      payloadJson: payloadJson ?? this.payloadJson,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}