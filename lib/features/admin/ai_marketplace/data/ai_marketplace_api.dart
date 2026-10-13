import 'package:build4front/core/network/globals.dart' as g;
import 'package:dio/dio.dart';

import 'models/ai_feature.dart';

/// Owner AI Marketplace client. Features are installed by default; the owner
/// installs/uninstalls per app. Everything is DB-driven on the backend.
class AiMarketplaceApi {
  Dio get _dio => g.appDio ?? g.dio();

  Map<String, dynamic> _map(dynamic d) =>
      d is Map<String, dynamic> ? d : Map<String, dynamic>.from(d as Map? ?? {});

  /// Paged list of AI features with this app's install state.
  Future<AiFeaturePage> getFeatures({
    String query = '',
    int page = 0,
    int size = 4,
  }) async {
    final res = await _dio.get('/api/ai/apps/me/features', queryParameters: {
      if (query.trim().isNotEmpty) 'query': query.trim(),
      'page': page,
      'size': size,
    });
    return AiFeaturePage.fromJson(_map(res.data));
  }

  /// Install (true) or uninstall (false) one feature. Returns the new state.
  Future<bool> setInstalled(String code, bool installed) async {
    final res = await _dio.put(
      '/api/ai/apps/me/features/$code',
      data: {'installed': installed},
    );
    return _map(res.data)['installed'] == true;
  }
}
