// lib/features/support/data/services/support_api_service.dart
import 'package:dio/dio.dart';
import 'package:build4front/core/network/globals.dart' as g;
import 'package:build4front/core/config/env.dart';
import 'package:build4front/features/support/domain/support_info.dart';

class OwnerSupportService {
  final Dio _dio = g.appDio!;

  String _cleanToken(String token) {
    final t = token.trim();
    return t.toLowerCase().startsWith('bearer ') ? t.substring(7).trim() : t;
  }

  String get _apiRoot {
    final serverRoot = (g.appServerRoot ?? '').trim();
    final raw = serverRoot.isNotEmpty ? serverRoot : Env.apiBaseUrl.trim();
    final noTrail = raw.replaceFirst(RegExp(r'/+$'), '');
    final noApi = noTrail.replaceFirst(RegExp(r'/api$'), '');
    return '$noApi/api';
  }

  SupportInfo _parseSupport(dynamic data, RequestOptions ro) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      // ✅ backend returns linkId in payload
      final linkId = (map['linkId'] is num)
          ? (map['linkId'] as num).toInt()
          : int.tryParse('${map['linkId']}') ?? 0;

      return SupportInfo.fromJson(map, linkId);
    }

    throw DioException(
      requestOptions: ro,
      message: 'Invalid support response: expected JSON object',
    );
  }

  Future<SupportInfo> fetchSupportInfo({required String token}) async {
    final tk = token.trim();
    if (tk.isEmpty) {
      throw Exception('Missing token (support endpoint is secured)');
    }

    final res = await _dio.get(
      '$_apiRoot/apps/support',
      options: Options(
        headers: {'Authorization': 'Bearer ${_cleanToken(tk)}'},
        responseType: ResponseType.json,
        validateStatus: (s) => s != null && s >= 200 && s < 500,
      ),
    );

    if (res.statusCode == null || res.statusCode! >= 400) {
      final msg = (res.data is Map)
          ? ((res.data['error'] ?? res.data['message'])?.toString() ?? 'Support request failed')
          : (res.data?.toString() ?? 'Support request failed');
      throw Exception(msg);
    }

    return _parseSupport(res.data, res.requestOptions);
  }
}