import '../../domain/entities/owner_announcement.dart';

class OwnerAnnouncementModel extends OwnerAnnouncement {
  const OwnerAnnouncementModel({
    required super.id,
    required super.ownerProjectLinkId,
    required super.ownerId,
    required super.title,
    required super.message,
    required super.announcementType,
    required super.targetId,
    required super.imageUrl,
    required super.status,
    required super.sentCount,
    required super.createdAt,
  });

  factory OwnerAnnouncementModel.fromJson(Map<String, dynamic> json) {
    return OwnerAnnouncementModel(
      id: _toInt(json['id']),
      ownerProjectLinkId: _toInt(json['ownerProjectLinkId']),
      ownerId: _toInt(json['ownerId']),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      announcementType: (json['announcementType'] ?? 'GENERAL').toString(),
      targetId: json['targetId'] == null ? null : _toInt(json['targetId']),
      imageUrl: _toNullableString(json['imageUrl']),
      status: (json['status'] ?? 'ACTIVE').toString(),
      sentCount: _toInt(json['sentCount']),
      createdAt: _toDate(json['createdAt']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '0').toString()) ?? 0;
  }

  static String? _toNullableString(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') return null;
    return raw;
  }

  static DateTime? _toDate(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}