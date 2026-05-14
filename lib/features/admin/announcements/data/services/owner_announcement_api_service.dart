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

    final response = await _sendCreateAnnouncementRequest(
      ownerProjectLinkId: ownerProjectLinkId,
      title: title,
      message: message,
      announcementType: announcementType,
      targetId: targetId,
      imagePath: imagePath,
      tokenOverride: null,
    );

    return _asMap(response.data);
  }

  Future<Response<dynamic>> _sendCreateAnnouncementRequest({
    required int ownerProjectLinkId,
    required String title,
    required String message,
    required String announcementType,
    required int? targetId,
    required String? imagePath,
    required String? tokenOverride,
  }) async {
    final formData = await _buildCreateAnnouncementFormData(
      ownerProjectLinkId: ownerProjectLinkId,
      title: title,
      message: message,
      announcementType: announcementType,
      targetId: targetId,
      imagePath: imagePath,
    );

    return _dio.post(
      '/api/front/owner/announcements',
      data: formData,
      options: Options(
        headers: await _headers(tokenOverride: tokenOverride),
        extra: {
          'retryRequest': (String newToken) {
            return _sendCreateAnnouncementRequest(
              ownerProjectLinkId: ownerProjectLinkId,
              title: title,
              message: message,
              announcementType: announcementType,
              targetId: targetId,
              imagePath: imagePath,
              tokenOverride: newToken,
            );
          },
        },
      ),
    );
  }

  Future<FormData> _buildCreateAnnouncementFormData({
    required int ownerProjectLinkId,
    required String title,
    required String message,
    required String announcementType,
    required int? targetId,
    required String? imagePath,
  }) async {
    final Map<String, dynamic> body = {
      'ownerProjectLinkId': ownerProjectLinkId.toString(),
      'title': title.trim().isEmpty ? 'Announcement' : title.trim(),
      'message': message.trim(),
      'announcementType': announcementType.trim().isEmpty
          ? 'GENERAL'
          : announcementType.trim().toUpperCase(),
    };

    if (targetId != null) {
      body['targetId'] = targetId.toString();
    }

    if (imagePath != null && imagePath.trim().isNotEmpty) {
      final cleanPath = imagePath.trim();

      body['image'] = await MultipartFile.fromFile(
        cleanPath,
        filename: cleanPath.split('/').last,
      );
    }

    return FormData.fromMap(body);
  }

  Future<List<Map<String, dynamic>>> getAnnouncements({
    String? tokenOverride,
  }) async {
    final ownerProjectLinkId = _ownerProjectLinkId;

    if (ownerProjectLinkId <= 0) {
      throw Exception('ownerProjectLinkId is missing');
    }

    final response = await _dio.get(
      '/api/front/owner/announcements',
      queryParameters: {
        'ownerProjectLinkId': ownerProjectLinkId,
      },
      options: Options(
        headers: await _headers(tokenOverride: tokenOverride),
        extra: {
          'retryRequest': (String newToken) {
            return getAnnouncements(tokenOverride: newToken);
          },
        },
      ),
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

  Future<void> deleteAnnouncement(
    int announcementId, {
    String? tokenOverride,
  }) async {
    final ownerProjectLinkId = _ownerProjectLinkId;

    if (ownerProjectLinkId <= 0) {
      throw Exception('ownerProjectLinkId is missing');
    }

    await _dio.delete(
      '/api/front/owner/announcements/$announcementId',
      queryParameters: {
        'ownerProjectLinkId': ownerProjectLinkId,
      },
      options: Options(
        headers: await _headers(tokenOverride: tokenOverride),
        extra: {
          'retryRequest': (String newToken) {
            return deleteAnnouncement(
              announcementId,
              tokenOverride: newToken,
            );
          },
        },
      ),
    );
  }

  Future<Map<String, String>> _headers({
    String? tokenOverride,
  }) async {
    final token = (tokenOverride ?? await getToken())?.trim() ?? '';

    print(
      'ANNOUNCEMENT TOKEN => ${token.isEmpty ? "EMPTY" : "len=${token.length}"}',
    );

    if (token.isEmpty) {
      throw Exception('Owner token is missing. Please login again.');
    }

    return {
      'Authorization':
          token.toLowerCase().startsWith('bearer ') ? token : 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{};
  }
}