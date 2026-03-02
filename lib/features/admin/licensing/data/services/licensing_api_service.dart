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
  }

  /// Ensures:
  /// - no trailing slash
  /// - baseUrl ends with /api
  static String _normalizeBaseUrl(String raw) {
    var base = raw.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    if (base.endsWith('/api')) return base;
    return '$base/api';
  }

  Future<String> _requireBearer() async {
    final token = (await getToken())?.trim() ?? '';
    if (token.isEmpty) throw Exception('Missing token');

    // accept if already "Bearer ..."
    if (token.toLowerCase().startsWith('bearer ')) return token;
    return 'Bearer $token';
  }

  Never _throwDio(String prefix, DioException e) {
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

    throw Exception('$prefix failed: $msg');
  }

  // ================= OWNER (tenant from token ONLY) =================

  Future<OwnerAppAccessResponse> getAccessMe() async {
    final auth = await _requireBearer();

    try {
      final res = await _dio.get(
        '/licensing/apps/me/access',
        options: Options(headers: {'Authorization': auth}),
      );

      return OwnerAppAccessResponse.fromJson(
        Map<String, dynamic>.from(res.data),
      );
    } on DioException catch (e) {
      _throwDio('Licensing getAccessMe', e);
    }
  }

  Future<void> requestUpgradeMe({
    required String planCode, // PRO_HOSTEDB / DEDICATED
    int? usersAllowedOverride,
  }) async {
    final auth = await _requireBearer();

    try {
      await _dio.post(
        '/licensing/apps/me/upgrade-request',
        data: {
          'planCode': planCode,
          'usersAllowedOverride': usersAllowedOverride,
        },
        options: Options(headers: {'Authorization': auth}),
      );
    } on DioException catch (e) {
      _throwDio('Licensing requestUpgradeMe', e);
    }
  }

  Future<List<dynamic>> listMyUpgradeRequests() async {
    final auth = await _requireBearer();

    try {
      final res = await _dio.get(
        '/licensing/apps/me/upgrade-requests',
        options: Options(headers: {'Authorization': auth}),
      );
      return (res.data as List);
    } on DioException catch (e) {
      _throwDio('Licensing listMyUpgradeRequests', e);
    }
  }

  // ================= SUPER_ADMIN (act-as via aupId) =================

  Future<OwnerAppAccessResponse> getAccessAsSuperAdmin(int aupId) async {
    final auth = await _requireBearer();

    try {
      final res = await _dio.get(
        '/licensing/apps/$aupId/access',
        options: Options(headers: {'Authorization': auth}),
      );

      return OwnerAppAccessResponse.fromJson(
        Map<String, dynamic>.from(res.data),
      );
    } on DioException catch (e) {
      _throwDio('Licensing getAccessAsSuperAdmin', e);
    }
  }

  Future<void> requestUpgradeAsSuperAdmin({
    required int aupId,
    required String planCode,
    int? usersAllowedOverride,
  }) async {
    final auth = await _requireBearer();

    try {
      await _dio.post(
        '/licensing/apps/$aupId/upgrade-request',
        data: {
          'planCode': planCode,
          'usersAllowedOverride': usersAllowedOverride,
        },
        options: Options(headers: {'Authorization': auth}),
      );
    } on DioException catch (e) {
      _throwDio('Licensing requestUpgradeAsSuperAdmin', e);
    }
  }
}