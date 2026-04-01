class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String notificationType;
  final String? payloadJson;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
    this.payloadJson,
    this.readAt,
  });

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == 'true' || v == '1' || v == 'yes';
    }

    return false;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: ((json['id'] ?? json['notification_id'] ?? json['notificationId']) as num)
          .toInt(),
      title: (json['title'] ?? '').toString().trim(),
      body: (json['body'] ?? json['message'] ?? '').toString().trim(),
      notificationType: (json['notificationType'] ?? json['notification_type'] ?? '')
          .toString()
          .trim(),
      payloadJson: json['payloadJson']?.toString() ?? json['payload_json']?.toString(),
      isRead: _parseBool(
        json['isRead'] ??
            json['is_read'] ??
            json['read'] ??
            json['readStatus'],
      ),
      createdAt: DateTime.parse(
        (json['createdAt'] ?? json['created_at']).toString(),
      ),
      readAt: (json['readAt'] ?? json['read_at']) != null
          ? DateTime.tryParse((json['readAt'] ?? json['read_at']).toString())
          : null,
    );
  }
}