import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:build4front/core/network/globals.dart' as g;

class PublicAiStatusApiService {
  Future<bool?> fetchAiEnabled({required int linkId}) async {
    try {
      final Dio dio = g.dio();
      final baseUrl = g.appServerRoot;
      debugPrint('[AI-DEBUG] fetchAiEnabled: baseUrl=$baseUrl, linkId=$linkId');
      debugPrint('[AI-DEBUG] Calling GET $baseUrl/api/public/ai/status?linkId=$linkId');

      final res = await dio.get(
        '/api/public/ai/status',
        queryParameters: {'linkId': linkId},
      );

      debugPrint('[AI-DEBUG] AI status response: statusCode=${res.statusCode}, data=${res.data}');

      if (res.data is Map<String, dynamic>) {
        final map = res.data as Map<String, dynamic>;
        final v = map['aiEnabled'];
        debugPrint('[AI-DEBUG] aiEnabled raw value=$v (type: ${v.runtimeType})');
        if (v is bool) return v;
        if (v is num) return v != 0;
        if (v is String) {
          final s = v.toLowerCase().trim();
          if (s == 'true' || s == '1') return true;
          if (s == 'false' || s == '0') return false;
        }
      }

      debugPrint('[AI-DEBUG] Could not parse aiEnabled from response: ${res.data}');
      return null;
    } catch (e) {
      debugPrint('[AI-DEBUG] fetchAiEnabled failed: $e');
      return null;
    }
  }
}
