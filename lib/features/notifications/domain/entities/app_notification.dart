// lib/features/notifications/domain/entities/app_notification.dart

import 'dart:convert';

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

  Map<String, dynamic> get payloadMap {
    final raw = (payloadJson ?? '').trim();

    if (raw.isEmpty || raw.toLowerCase() == 'null') {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  bool get isAnnouncement {
    final type = notificationType.trim().toUpperCase();

    final event = (payloadMap['event'] ?? '').toString().trim().toUpperCase();

    return type == 'ANNOUNCEMENT' ||
        type == 'OWNER_ANNOUNCEMENT' ||
        type == 'USER_ANNOUNCEMENT' ||
        type.contains('ANNOUNCEMENT') ||
        event == 'ANNOUNCEMENT';
  }

  String? get announcementImageUrl {
    if (!isAnnouncement) {
      return null;
    }

    final map = payloadMap;

    final possibleValues = [
      map['imageUrl'],
      map['image_url'],
      map['announcementImageUrl'],
      map['notificationImageUrl'],
      map['thumbnailUrl'],
    ];

    for (final value in possibleValues) {
      final clean = (value ?? '').toString().trim();

      if (clean.isNotEmpty && clean.toLowerCase() != 'null') {
        return clean;
      }
    }

    return null;
  }

  int? get announcementId {
    final value = payloadMap['announcementId'] ?? payloadMap['announcement_id'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse((value ?? '').toString());
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