import 'package:dio/dio.dart';
import 'package:build4front/core/config/env.dart';

class ItemStatusApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  Future<List<dynamic>> getItemStatuses({
    required String authToken,
  }) async {
    final res = await _dio.get(
      '/api/item-statuses',
      options: Options(
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      ),
    );

    final data = res.data;
    if (data is List) return data;
    return const [];
  }
}