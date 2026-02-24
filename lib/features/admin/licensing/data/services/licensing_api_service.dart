import 'package:build4front/core/config/env.dart';
import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:dio/dio.dart';

class LicensingApiService {
  final Future<String?> Function() getToken;
  late final Dio _dio;

  LicensingApiService({required this.getToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _normalizeBaseUrl(Env.apiBaseUrl),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    // Optional debug:
    // _dio.interceptors.add(LogInterceptor(
    //   request: true,
    //   requestHeader: true,
    //   responseBody: true,
    //   error: true,
    // ));
  }

  /// Ensures:
  /// - no trailing slash
  /// - baseUrl ends with /api (because your backend endpoints are /api/...)
  static String _normalizeBaseUrl(String raw) {
    var base = raw.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);

    // If Env.apiBaseUrl is already ".../api" keep it.
    if (base.endsWith('/api')) return base;

    // If Env.apiBaseUrl is just "https://host.com" -> append /api
    return '$base/api';
  }

  Future<OwnerAppAccessResponse> getAccess(int aupId) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Missing admin token');
    }

    try {
    
      final res = await _dio.get(
        '/licensing/apps/$aupId/access',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return OwnerAppAccessResponse.fromJson(
        Map<String, dynamic>.from(res.data),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;

      String msg = 'HTTP $code';
      if (data is Map && data['message'] != null) {
        msg += ' | ${data['message']}';
      } else if (data is Map && data['error'] != null) {
        msg += ' | ${data['error']}';
      } else if (data != null) {
        msg += ' | $data';
      } else if (e.message != null) {
        msg += ' | ${e.message}';
      }

      throw Exception('Licensing getAccess failed: $msg');
    }
  }

  Future<void> requestUpgrade({
    required int aupId,
    required String planCode, // PRO_HOSTEDB / DEDICATED
    int? usersAllowedOverride,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Missing admin token');
    }

    try {
      // ✅ IMPORTANT: no leading "/" here too
      await _dio.post(
        '/licensing/apps/$aupId/upgrade-request',
        data: {
          'planCode': planCode,
          'usersAllowedOverride': usersAllowedOverride,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;

      String msg = 'HTTP $code';
      if (data is Map && data['message'] != null) {
        msg += ' | ${data['message']}';
      } else if (data is Map && data['error'] != null) {
        msg += ' | ${data['error']}';
      } else if (data != null) {
        msg += ' | $data';
      } else if (e.message != null) {
        msg += ' | ${e.message}';
      }

      throw Exception('Licensing requestUpgrade failed: $msg');
    }
  }
}