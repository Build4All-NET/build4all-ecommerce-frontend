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
    if (token.isEmpty) {
      throw Exception('Missing token');
    }

    if (token.toLowerCase().startsWith('bearer ')) return token;
    return 'Bearer $token';
  }

  // ================= OWNER (tenant from token ONLY) =================

  Future<OwnerAppAccessResponse> getAccessMe() async {
    final auth = await _requireBearer();

    final res = await _dio.get(
      '/licensing/apps/me/access',
      options: Options(headers: {'Authorization': auth}),
    );

    return OwnerAppAccessResponse.fromJson(
      Map<String, dynamic>.from(res.data),
    );
  }

  Future<void> requestUpgradeMe({
    required String planCode, // PRO_HOSTEDB / DEDICATED
    int? usersAllowedOverride,
  }) async {
    final auth = await _requireBearer();

    await _dio.post(
      '/licensing/apps/me/upgrade-request',
      data: {
        'planCode': planCode,
        'usersAllowedOverride': usersAllowedOverride,
      },
      options: Options(headers: {'Authorization': auth}),
    );
  }

  Future<List<dynamic>> listMyUpgradeRequests() async {
    final auth = await _requireBearer();

    final res = await _dio.get(
      '/licensing/apps/me/upgrade-requests',
      options: Options(headers: {'Authorization': auth}),
    );

    return (res.data as List);
  }

  // ================= SUPER_ADMIN (act-as via aupId) =================

  Future<OwnerAppAccessResponse> getAccessAsSuperAdmin(int aupId) async {
    final auth = await _requireBearer();

    final res = await _dio.get(
      '/licensing/apps/$aupId/access',
      options: Options(headers: {'Authorization': auth}),
    );

    return OwnerAppAccessResponse.fromJson(
      Map<String, dynamic>.from(res.data),
    );
  }

  Future<void> requestUpgradeAsSuperAdmin({
    required int aupId,
    required String planCode,
    int? usersAllowedOverride,
  }) async {
    final auth = await _requireBearer();

    await _dio.post(
      '/licensing/apps/$aupId/upgrade-request',
      data: {
        'planCode': planCode,
        'usersAllowedOverride': usersAllowedOverride,
      },
      options: Options(headers: {'Authorization': auth}),
    );
  }
}