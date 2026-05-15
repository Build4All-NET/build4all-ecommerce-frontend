import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:build4front/core/exceptions/app_exception.dart';
import 'package:build4front/core/exceptions/auth_exception.dart';
import 'package:build4front/core/exceptions/network_exception.dart';
import 'package:build4front/core/network/globals.dart' as g;

/// Admin profile API.
///
/// Previously this service used the `http` package directly, which meant the
/// shared `RefreshTokenInterceptor` never saw the responses. When the admin
/// access token expired (e.g. while sitting on the dashboard), every call from
/// here came back as 401 with no refresh attempt, and the dashboard ended up
/// stuck "loading" or threw a session-expired error.
///
/// This implementation uses the shared app Dio (`g.appDio`) so:
///   1. The refresh interceptor automatically refreshes an expired token and
///      retries the request transparently.
///   2. The token is read at *call time* (and the retry path is wired through
///      `extra['retryRequest']`) so the freshly refreshed token is used.
class AdminUserApiService {
  final Future<String?> Function() getToken;

  AdminUserApiService({required this.getToken});

  Dio get _dio => g.appDio ?? g.dio();

  Future<String> _requireBearer() async {
    final token = (await getToken())?.trim() ?? '';
    if (token.isEmpty) {
      throw AuthException(
        'Session expired. Please log in again.',
        code: 'MISSING_AUTH_TOKEN',
      );
    }
    if (token.toLowerCase().startsWith('bearer ')) return token;
    return 'Bearer $token';
  }

  Future<Map<String, dynamic>> getMyProfileJson() async {
    Future<Response<dynamic>> doCall(String bearer) {
      return _dio.get(
        '/api/admin/users/me',
        options: Options(
          headers: {
            'Authorization': bearer,
            'Accept': 'application/json',
          },
        ),
      );
    }

    try {
      final auth = await _requireBearer();

      final res = await _dio.get(
        '/api/admin/users/me',
        options: Options(
          headers: {
            'Authorization': auth,
            'Accept': 'application/json',
          },
          extra: {'retryRequest': doCall},
        ),
      );

      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      if (body is Map) return Map<String, dynamic>.from(body);

      throw AppException('Invalid server response.');
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Unexpected error.', original: e);
    }
  }

  // -----------------------------------------------------------------------
  // Error mapping
  // -----------------------------------------------------------------------

  AppException _mapDioError(DioException e) {
    final isSocket = e.error is SocketException;

    final isNetworkFailure = e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.type == DioExceptionType.unknown && isSocket);

    if (isNetworkFailure) {
      return NetworkException(
        isSocket
            ? 'No internet connection.'
            : "Can't reach the server. Check your internet and try again.",
        original: e,
      );
    }

    final status = e.response?.statusCode;
    final payload = _readPayload(e.response?.data);

    if (status == 401 || status == 403) {
      return AuthException(
        payload.message ?? 'Session expired. Please log in again.',
        code: payload.code,
        original: e,
      );
    }

    if (status != null) {
      return ServerException(
        payload.message ?? _fallbackForStatus(status),
        statusCode: status,
        code: payload.code,
        original: e,
      );
    }

    return AppException(
      payload.message ?? 'Request failed.',
      code: payload.code,
      original: e,
    );
  }

  _BackendPayload _readPayload(dynamic data) {
    if (data == null) return const _BackendPayload();

    try {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);

        String? code;
        String? message;

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

        final errors = map['errors'];
        if ((message == null || message.isEmpty) && errors is Map) {
          final parts = <String>[];
          errors.forEach((_, value) {
            if (value is List) {
              for (final item in value) {
                final text = item?.toString().trim() ?? '';
                if (text.isNotEmpty) parts.add(text);
              }
            } else {
              final text = value?.toString().trim() ?? '';
              if (text.isNotEmpty) parts.add(text);
            }
          });

          if (parts.isNotEmpty) {
            message = parts.join(', ');
          }
        }

        return _BackendPayload(
          code: code,
          message: (message == null || message.isEmpty) ? null : message,
        );
      }

      if (data is String) {
        final text = data.trim();
        if (text.isNotEmpty) return _BackendPayload(message: text);
      }
    } catch (_) {
      // ignore — fall through to empty payload
    }

    return const _BackendPayload();
  }

  String _fallbackForStatus(int status) {
    switch (status) {
      case 400:
      case 422:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You don’t have permission to do this.';
      case 404:
        return 'Not found.';
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