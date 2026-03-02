import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:build4front/core/network/globals.dart' as g;
import 'package:build4front/core/config/env.dart';

class UserProfileService {
  final Dio _dio = g.appDio!;

  String _cleanToken(String token) {
    final t = token.trim();
    return t.toLowerCase().startsWith('bearer ') ? t.substring(7).trim() : t;
  }

  String get _apiRoot {
    final raw = g.appServerRoot.trim().isNotEmpty
        ? g.appServerRoot.trim()
        : Env.apiBaseUrl.trim();

    final noTrail = raw.replaceFirst(RegExp(r'/+$'), '');
    final noApi = noTrail.replaceFirst(RegExp(r'/api$'), '');
    return '$noApi/api';
  }

  String get _base => '$_apiRoot/users';

  // ---------- helpers ----------

  String _extractMessage(dynamic data) {
    if (data is Map) {
      final m = data.cast<String, dynamic>();
      return (m['error'] ?? m['message'] ?? m['detail'] ?? m['msg'] ?? '')
          .toString();
    }
    if (data is String) {
      final s = data.trim();
      if (s.isEmpty) return '';
      if (s.startsWith('{') || s.startsWith('[')) {
        try {
          final decoded = jsonDecode(s);
          return _extractMessage(decoded);
        } catch (_) {
          return s;
        }
      }
      return s;
    }
    return '';
  }

  void _throwBadResponse(Response res) {
    final code = res.statusCode ?? 0;
    final msg = _extractMessage(res.data);
    final fallback = 'Request failed ($code)';

    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      type: DioExceptionType.badResponse,
      message: msg.isNotEmpty ? msg : fallback,
    );
  }

  // ---------- API ----------

  /// ✅ GET /api/users/{id}
  /// Tenant inferred from JWT in backend
  Future<Map<String, dynamic>> fetchProfileMap({
    required String token,
    required int userId,
  }) async {
    final res = await _dio.get(
      '$_base/$userId',
      options: Options(
        headers: {'Authorization': 'Bearer ${_cleanToken(token)}'},
        responseType: ResponseType.json,
        receiveDataWhenStatusError: true,
        validateStatus: (s) => s != null && s >= 200 && s < 500,
      ),
    );

    if ((res.statusCode ?? 0) < 200 || (res.statusCode ?? 0) >= 300) {
      _throwBadResponse(res);
    }

    final data = res.data;
    if (data is Map) return data.cast<String, dynamic>();

    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      type: DioExceptionType.unknown,
      message: 'Invalid profile response: expected JSON object',
    );
  }

  /// ✅ PUT /api/users/profile-visibility?isPublic=true
  /// NOTE: NO /{id} in path in your backend
  Future<void> updateVisibility({
    required String token,
    required bool isPublic,
  }) async {
    final res = await _dio.put(
      '$_base/profile-visibility',
      queryParameters: {'isPublic': isPublic},
      data: const {},
      options: Options(
        headers: {'Authorization': 'Bearer ${_cleanToken(token)}'},
        responseType: ResponseType.plain,
        receiveDataWhenStatusError: true,
        validateStatus: (s) => s != null && s >= 200 && s < 500,
      ),
    );

    if ((res.statusCode ?? 0) < 200 || (res.statusCode ?? 0) >= 300) {
      _throwBadResponse(res);
    }
  }

  /// ✅ PUT /api/users/{id}/status
  /// Tenant inferred from JWT in backend
  Future<void> updateStatus({
    required String token,
    required int userId,
    required String status,
    String? password,
  }) async {
    final body = <String, dynamic>{'status': status};

    if (status.toUpperCase() == 'INACTIVE' && (password?.isNotEmpty ?? false)) {
      body['password'] = password;
    }

    final res = await _dio.put(
      '$_base/$userId/status',
      data: body,
      options: Options(
        headers: {'Authorization': 'Bearer ${_cleanToken(token)}'},
        responseType: ResponseType.plain,
        receiveDataWhenStatusError: true,
        validateStatus: (s) => s != null && s >= 200 && s < 500,
      ),
    );

    if ((res.statusCode ?? 0) < 200 || (res.statusCode ?? 0) >= 300) {
      _throwBadResponse(res);
    }
  }
}