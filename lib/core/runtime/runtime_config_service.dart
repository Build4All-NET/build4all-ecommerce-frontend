import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:build4front/core/exceptions/app_exception.dart';
import 'package:build4front/core/exceptions/auth_exception.dart';
import 'package:build4front/core/exceptions/network_exception.dart';

class RuntimeConfigService {
  final Dio dio;

  RuntimeConfigService(this.dio);

  Future<Map<String, dynamic>> fetchByLinkId({
    required String apiBaseUrl,
    required String linkId,
  }) async {
    final url = '$apiBaseUrl/api/public/runtime-config/by-link?linkId=$linkId';

    try {
      final resp = await dio.get(url);

      final data = resp.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);

      if (data is String) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }

      throw AppException('Invalid server response.');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final payload = _readPayload(e.response?.data);
      final isSocket = e.error is SocketException;

      final isNetworkFailure =
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          (e.type == DioExceptionType.unknown && isSocket);

      if (isNetworkFailure) {
        throw NetworkException(
          isSocket
              ? 'No internet connection.'
              : (payload.message ??
                  "Can't reach the server. Check your internet and try again."),
          original: e,
        );
      }

      if (status == 401 || status == 403) {
        throw AuthException(
          payload.message ?? 'Session expired. Please log in again.',
          code: payload.code,
          original: e,
        );
      }

      throw ServerException(
        payload.message ?? _fallbackForStatus(status),
        statusCode: status ?? 500,
        code: payload.code,
        original: e,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'Failed to load runtime configuration.',
        original: e,
      );
    }
  }

  _BackendPayload _readPayload(dynamic data) {
    String? code;
    String? message;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      final rawCode = map['code'];
      if (rawCode != null && rawCode.toString().trim().isNotEmpty) {
        code = rawCode.toString().trim();
      }

      for (final key in const ['error', 'message', 'detail', 'msg', 'title']) {
        final value = map[key];
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) {
          message = text;
          break;
        }
      }
    } else if (data is String) {
      final text = data.trim();
      if (text.isNotEmpty) {
        message = text;
      }
    }

    return _BackendPayload(
      code: code,
      message: (message == null || message.isEmpty) ? null : message,
    );
  }

  String _fallbackForStatus(int? status) {
    if (status == null) return 'Failed to load runtime configuration.';

    switch (status) {
      case 400:
      case 422:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You don’t have permission to do this.';
      case 404:
        return 'Runtime configuration was not found.';
      case 409:
        return 'Conflict. This already exists or can’t be done now.';
      default:
        if (status >= 500) return 'Server error. Please try later.';
        return 'Request failed.';
    }
  }
}

class _BackendPayload {
  final String? code;
  final String? message;

  const _BackendPayload({
    this.code,
    this.message,
  });
}