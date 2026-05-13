import 'package:build4front/core/network/globals.dart' as net;
import 'package:dio/dio.dart';

class PublicAnnouncementPopupService {
  Dio get _dio => net.appDio ?? net.dio();

  Future<List<PublicAnnouncementPopupItem>> getPublicAnnouncements({
    required int ownerProjectLinkId,
  }) async {
    if (ownerProjectLinkId <= 0) {
      return [];
    }

    final response = await _dio.get(
      '/api/front/announcements',
      queryParameters: {
        'ownerProjectLinkId': ownerProjectLinkId,
      },
    );

    final data = response.data;

    List<dynamic> rawList = [];

    if (data is Map) {
      final value = data['data'];
      if (value is List) {
        rawList = value;
      }
    } else if (data is List) {
      rawList = data;
    }

    final items = <PublicAnnouncementPopupItem>[];

    for (final item in rawList) {
      if (item is! Map) continue;

      final json = Map<String, dynamic>.from(item);
      final parsed = PublicAnnouncementPopupItem.fromJson(json);

      if (parsed.id > 0) {
        items.add(parsed);
      }
    }

    return items;
  }
}

class PublicAnnouncementPopupItem {
  final int id;
  final String title;
  final String message;
  final String announcementType;
  final int? targetId;
  final String? imageUrl;
  final DateTime? createdAt;

  const PublicAnnouncementPopupItem({
    required this.id,
    required this.title,
    required this.message,
    required this.announcementType,
    required this.targetId,
    required this.imageUrl,
    required this.createdAt,
  });

  factory PublicAnnouncementPopupItem.fromJson(Map<String, dynamic> json) {
    return PublicAnnouncementPopupItem(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      message: _asString(json['message']),
      announcementType: _asString(json['announcementType']),
      targetId: _asNullableInt(json['targetId']),
      imageUrl: _asNullableString(json['imageUrl']),
      createdAt: _asDate(json['createdAt']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String _asString(dynamic value) {
    return (value ?? '').toString().trim();
  }

  static String? _asNullableString(dynamic value) {
    final text = _asString(value);
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }

  static DateTime? _asDate(dynamic value) {
    final text = _asString(value);
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}