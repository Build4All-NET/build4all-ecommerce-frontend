import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/network/globals.dart' as g;
import 'package:dio/dio.dart';

class OwnerAnnouncementApiService {
  final Future<String?> Function() getToken;

  OwnerAnnouncementApiService({
    required this.getToken,
  });

  Dio get _dio => g.appDio ?? g.dio();

  int get _ownerProjectLinkId {
    return int.tryParse(Env.ownerProjectLinkId) ?? 0;
  }

  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String message,
    required String announcementType,
    int? targetId,
    String? imagePath,
  }) async {
    final ownerProjectLinkId = _ownerProjectLinkId;

    if (ownerProjectLinkId <= 0) {
      throw Exception('ownerProjectLinkId is missing');
    }

    if (message.trim().isEmpty) {
      throw Exception('Message is required');
    }

    final formData = FormData.fromMap({
      'ownerProjectLinkId': ownerProjectLinkId,
      'title': title.trim().isEmpty ? 'Announcement' : title.trim(),
      'message': message.trim(),
      'announcementType': announcementType.trim().isEmpty
          ? 'GENERAL'
          : announcementType.trim().toUpperCase(),
      if (targetId != null) 'targetId': targetId,
      if (imagePath != null && imagePath.trim().isNotEmpty)
        'image': await MultipartFile.fromFile(imagePath),
    });

    final response = await _dio.post(
      '/api/front/owner/announcements',
      data: formData,
      options: Options(
        headers: {
          ...await _headers(),
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    return _asMap(response.data);
  }

  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final ownerProjectLinkId = _ownerProjectLinkId;

    if (ownerProjectLinkId <= 0) {
      throw Exception('ownerProjectLinkId is missing');
    }

    final response = await _dio.get(
      '/api/front/owner/announcements',
      queryParameters: {
        'ownerProjectLinkId': ownerProjectLinkId,
      },
      options: Options(headers: await _headers()),
    );

    final data = _asMap(response.data);
    final list = data['data'];

    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }

  Future<void> deleteAnnouncement(int announcementId) async {
    final ownerProjectLinkId = _ownerProjectLinkId;

    if (ownerProjectLinkId <= 0) {
      throw Exception('ownerProjectLinkId is missing');
    }

    await _dio.delete(
      '/api/front/owner/announcements/$announcementId',
      queryParameters: {
        'ownerProjectLinkId': ownerProjectLinkId,
      },
      options: Options(headers: await _headers()),
    );
  }

  Future<Map<String, String>> _headers() async {
    final token = (await getToken())?.trim() ?? '';

    return {
      if (token.isNotEmpty)
        'Authorization':
            token.toLowerCase().startsWith('bearer ') ? token : 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }
}