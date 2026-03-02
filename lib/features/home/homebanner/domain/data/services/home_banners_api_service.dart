import 'package:build4front/core/config/env.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class HomeBannersApiService {
  final Dio _dio;

  HomeBannersApiService(this._dio);

  factory HomeBannersApiService.create() {
    // Prefer using your global dio if you have it (recommended),
    // but keeping this structure for minimal change.
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return HomeBannersApiService(dio);
  }

  Future<List<Map<String, dynamic>>> fetchActiveBanners({
    required String token,
  }) async {
    try {
      final res = await _dio.get(
        '/api/home-banners',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (kDebugMode) {
        debugPrint('HomeBannersApiService: status=${res.statusCode}');
      }

      final data = res.data;
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return const [];
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'HomeBannersApiService DioException: status=${e.response?.statusCode}, data=${e.response?.data}',
        );
      }
      rethrow;
    }
  }
}