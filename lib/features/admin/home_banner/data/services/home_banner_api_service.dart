import 'dart:io';
import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/network/api_client.dart';
import 'package:dio/dio.dart';

class HomeBannerApiService {
  final Dio _dio;

  HomeBannerApiService([Dio? dio]) : _dio = dio ?? ApiClient.instance.dio;

  String get _baseUrl => '${Env.apiBaseUrl}/api/home-banners';

  // ✅ tenant comes from token
  Future<List<dynamic>> listActivePublic({
    required String authToken,
  }) async {
    final res = await _dio.get(
      _baseUrl,
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
    return (res.data as List);
  }

  // ✅ tenant comes from token
  Future<List<dynamic>> listForAdmin({
    required String authToken,
  }) async {
    final res = await _dio.get(
      '$_baseUrl/app',
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
    return (res.data as List);
  }

  Future<Map<String, dynamic>> createWithImage({
    required Map<String, dynamic> body,
    required String authToken,
    required String imagePath,
  }) async {
    final form = FormData.fromMap({
      ...body,
      'image': await MultipartFile.fromFile(
        imagePath,
        filename: File(imagePath).path.split('/').last,
      ),
    });

    final res = await _dio.post(
      '$_baseUrl/with-image',
      data: form,
      options: Options(
        headers: {'Authorization': 'Bearer $authToken'},
        contentType: 'multipart/form-data',
      ),
    );

    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> updateWithImage({
    required int id,
    required Map<String, dynamic> body,
    required String authToken,
    String? imagePath,
  }) async {
    final map = {...body};

    if (imagePath != null && imagePath.isNotEmpty) {
      map['image'] = await MultipartFile.fromFile(
        imagePath,
        filename: File(imagePath).path.split('/').last,
      );
    }

    final form = FormData.fromMap(map);

    final res = await _dio.put(
      '$_baseUrl/$id/with-image',
      data: form,
      options: Options(
        headers: {'Authorization': 'Bearer $authToken'},
        contentType: 'multipart/form-data',
      ),
    );

    return Map<String, dynamic>.from(res.data);
  }

  Future<void> delete({
    required int id,
    required String authToken,
  }) async {
    await _dio.delete(
      '$_baseUrl/$id',
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
  }
}