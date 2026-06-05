import 'dart:io';

import 'package:dio/dio.dart';
import 'package:build4front/core/network/api_client.dart';
import 'package:build4front/core/config/env.dart';

class TaxApiService {
  final Dio _dio;
  TaxApiService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  String get _baseUrl => '${Env.apiBaseUrl}/api/tax';

  Options _auth(String token) {
    final t = token.trim();
    // Avoid "Bearer Bearer xxx"
    final value = t.toLowerCase().startsWith('bearer ') ? t : 'Bearer $t';
    return Options(headers: {'Authorization': value});
  }

  String _friendlyDioError(DioException e) {
    final isSocket = e.error is SocketException;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.type == DioExceptionType.unknown && isSocket)) {
      return isSocket
          ? ‘No internet connection.’
          : "Can’t reach the server. Check your internet and try again.";
    }

    if (e.type == DioExceptionType.cancel) return ‘Request cancelled.’;

    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (status != null && status >= 500) return ‘Server error. Please try later.’;

    if (data is Map) {
      final err = data[‘error’] ?? data[‘message’];
      if (err != null && err.toString().trim().isNotEmpty) return err.toString().trim();
    }

    if (data is String && data.trim().isNotEmpty && status != null && status < 500) {
      return data.trim();
    }

    if (status == 401) return ‘Session expired. Please login again.’;
    if (status == 403) return ‘You don\’t have permission to do this.’;
    if (status == 404) return ‘Not found.’;
    if (status != null) return ‘Request failed.’;

    return "Can’t reach the server. Check your internet and try again.";
  }

  Future<List<dynamic>> listRules({required String authToken}) async {
    try {
      final resp = await _dio.get(
        '$_baseUrl/rules',
        options: _auth(authToken),
      );
      return resp.data as List<dynamic>;
    } on DioException catch (e) {
      throw _friendlyDioError(e); // ✅ throw string => UI gets clean message
    }
  }

  Future<Map<String, dynamic>> getRule({
    required int id,
    required String authToken,
  }) async {
    try {
      final resp = await _dio.get(
        '$_baseUrl/rules/$id',
        options: _auth(authToken),
      );
      return (resp.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw _friendlyDioError(e);
    }
  }

  Future<Map<String, dynamic>> createRule({
    required Map<String, dynamic> body,
    required String authToken,
  }) async {
    try {
      final resp = await _dio.post(
        '$_baseUrl/rules',
        data: body,
        options: _auth(authToken),
      );
      return (resp.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw _friendlyDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateRule({
    required int id,
    required Map<String, dynamic> body,
    required String authToken,
  }) async {
    try {
      final resp = await _dio.put(
        '$_baseUrl/rules/$id',
        data: body,
        options: _auth(authToken),
      );
      return (resp.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw _friendlyDioError(e);
    }
  }

  /// ✅ Backend now returns {message:"Tax rule deleted"} (NOT empty 204).
  Future<Map<String, dynamic>> deleteRule({
    required int id,
    required String authToken,
  }) async {
    try {
      final resp = await _dio.delete(
        '$_baseUrl/rules/$id',
        options: _auth(authToken),
      );

      // If backend returns JSON message:
      if (resp.data is Map) {
        return (resp.data as Map).cast<String, dynamic>();
      }

      // Fallback:
      return {'message': 'Deleted'};
    } on DioException catch (e) {
      throw _friendlyDioError(e);
    }
  }

  Future<Map<String, dynamic>> previewTax({
    required Map<String, dynamic> body,
    required String authToken,
  }) async {
    try {
      final res = await _dio.post(
        '$_baseUrl/preview',
        data: body,
        options: _auth(authToken),
      );
      return (res.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw _friendlyDioError(e);
    }
  }
}
