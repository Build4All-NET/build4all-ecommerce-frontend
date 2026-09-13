import 'package:build4front/core/network/globals.dart' as g;
import 'package:dio/dio.dart';

/// Reads the owner's audience statistics from the backend.
///
/// The endpoint is tenant-scoped server-side: the owner's token decides which
/// app's users come back, so nothing here needs to pass a project id.
class OwnerStatisticsApiService {
  static const String _path = '/api/users/owner/statistics';

  final Future<String?> Function() getToken;
  final Dio? _dio;

  OwnerStatisticsApiService({
    required this.getToken,
    Dio? dio,
  }) : _dio = dio;

  Dio get _client => _dio ?? g.appDio ?? g.dio();

  Future<Map<String, dynamic>> getStatisticsJson() async {
    final response = await _get(tokenOverride: null);

    final data = response.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  /// Returns the raw response so the same call can serve as the refresh
  /// interceptor's replay callback, which hands back whatever it resolves.
  Future<Response<dynamic>> _get({required String? tokenOverride}) async {
    return _client.get(
      _path,
      options: Options(
        headers: await _headers(tokenOverride: tokenOverride),
        extra: {
          'retryRequest': (String newToken) => _get(tokenOverride: newToken),
        },
      ),
    );
  }

  Future<Map<String, String>> _headers({required String? tokenOverride}) async {
    final token = (tokenOverride ?? await getToken())?.trim() ?? '';

    if (token.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: _path),
        response: Response(
          requestOptions: RequestOptions(path: _path),
          statusCode: 401,
          data: const {
            'code': 'AUTH',
            'error': 'Session expired. Please login again.',
          },
        ),
        type: DioExceptionType.badResponse,
      );
    }

    return {
      'Authorization':
          token.toLowerCase().startsWith('bearer ') ? token : 'Bearer $token',
      'Accept': 'application/json',
    };
  }
}
