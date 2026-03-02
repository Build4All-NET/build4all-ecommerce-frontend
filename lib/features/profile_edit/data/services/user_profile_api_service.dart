// lib/features/profile_edit/data/services/user_profile_api_service.dart
import 'dart:io';
import 'package:dio/dio.dart';

class UserProfileApiService {
  final Dio dio;
  final String baseUrl;

  UserProfileApiService({required this.dio, required this.baseUrl});

  String _cleanToken(String token) {
    final t = token.trim();
    return t.toLowerCase().startsWith('bearer ') ? t.substring(7).trim() : t;
  }

  String _apiRoot() {
    var b = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    b = b.replaceAll('/api/api', '/api');
    if (!b.endsWith('/api')) b = '$b/api';
    return b;
  }

  Options _authJson(String token) => Options(
        headers: {'Authorization': 'Bearer ${_cleanToken(token)}'},
        validateStatus: (s) => s != null && s >= 200 && s < 500,
      );

  Options _authMultipart(String token) => Options(
        headers: {'Authorization': 'Bearer ${_cleanToken(token)}'},
        contentType: Headers.multipartFormDataContentType,
        validateStatus: (s) => s != null && s >= 200 && s < 500,
      );

  String _readErrorMessage(dynamic data, {int? statusCode}) {
    if (data is Map) {
      final map = data.cast<dynamic, dynamic>();
      final candidates = [map['error'], map['message'], map['details'], map['msg']];
      for (final c in candidates) {
        final text = c?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
    }
    if (data is String) {
      final text = data.trim();
      if (text.isNotEmpty) return text;
    }
    return 'Request failed (${statusCode ?? 'unknown'})';
  }

  void _throwIfFailed(Response res) {
    final code = res.statusCode;
    if (code == null || code >= 400) {
      throw Exception(_readErrorMessage(res.data, statusCode: code));
    }
  }

  Future<Map<String, dynamic>> getUserById({
    required String token,
    required int userId,
  }) async {
    final res = await dio.get(
      '${_apiRoot()}/users/$userId',
      options: _authJson(token),
    );

    _throwIfFailed(res);

    if (res.data is Map) {
      return (res.data as Map).cast<String, dynamic>();
    }
    throw Exception('Invalid server response while loading profile');
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required int userId,
    required String firstName,
    required String lastName,
    String? username,
    String? email,
    bool? isPublicProfile,
    String? imageFilePath,
    bool imageRemoved = false,
  }) async {
    final form = FormData.fromMap({
      'firstName': firstName,
      'lastName': lastName,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (isPublicProfile != null) 'isPublicProfile': isPublicProfile.toString(),
      'imageRemoved': imageRemoved.toString(),
      if (imageFilePath != null)
        'profileImage': await MultipartFile.fromFile(
          imageFilePath,
          filename: File(imageFilePath).uri.pathSegments.last,
        ),
    });

    final res = await dio.put(
      '${_apiRoot()}/users/$userId/profile',
      data: form,
      options: _authMultipart(token),
    );

    _throwIfFailed(res);

    if (res.data is Map) {
      return (res.data as Map).cast<String, dynamic>();
    }

    return {'message': res.data?.toString() ?? 'Profile updated'};
  }

  Future<void> verifyEmailChange({
    required String token,
    required int userId,
    required String code,
  }) async {
    final res = await dio.post(
      '${_apiRoot()}/users/$userId/email-change/verify',
      data: {'code': code},
      options: _authJson(token),
    );
    _throwIfFailed(res);
  }

  Future<void> resendEmailChange({
    required String token,
    required int userId,
  }) async {
    final res = await dio.post(
      '${_apiRoot()}/users/$userId/email-change/resend',
      options: _authJson(token),
    );
    _throwIfFailed(res);
  }

  Future<void> deleteUser({
    required String token,
    required int userId,
    required String password,
  }) async {
    final res = await dio.delete(
      '${_apiRoot()}/users/$userId',
      data: {'password': password},
      options: Options(
        headers: {'Authorization': 'Bearer ${_cleanToken(token)}'},
        responseType: ResponseType.plain,
        validateStatus: (s) => s != null && s >= 200 && s < 500,
      ),
    );

    final text = (res.data ?? '').toString().trim();
    if (res.statusCode == null || res.statusCode! >= 400) {
      throw Exception(text.isNotEmpty ? text : 'Delete failed (${res.statusCode})');
    }
  }
}