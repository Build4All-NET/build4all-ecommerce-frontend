import 'dart:io';

import 'package:dio/dio.dart';
import 'package:build4front/core/network/globals.dart' as g;
import 'package:build4front/core/network/api_methods.dart';

import 'package:build4front/core/exceptions/app_exception.dart';
import 'package:build4front/core/exceptions/network_exception.dart';
import 'package:build4front/core/exceptions/auth_exception.dart';

class ApiFetch {
  final Dio _dio;
  CancelToken? _token;

  ApiFetch([Dio? dio])
      : _dio = dio ??
            g.appDio ??
            (throw StateError(
              'ERROR: appDio is NULL — did you call makeDefaultDio()?',
            ));

  void cancel() {
    _token?.cancel('Cancelled');
    _token = null;
  }

  String _query(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return '';
    final q = params.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent('${e.value}')}',
        )
        .join('&');
    return '?$q';
  }

  Map<String, dynamic>? _asQuery(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    throw ArgumentError(
      'GET query data must be Map<String, dynamic> or null. Got: ${data.runtimeType}',
    );
  }

  Future<Response> fetch(
    String method,
    String url, {
    dynamic data,
    Map<String, String>? headers,
    Duration? receiveTimeoutOverride,
    ResponseType? responseType,
  }) async {
    final opts = Options(
      headers: headers,
      receiveTimeout: receiveTimeoutOverride,
      responseType: responseType,
    );

    try {
      Response res;

      switch (method) {
        case HttpMethod.get:
          res = await _dio.get(
            '$url${_query(_asQuery(data))}',
            options: opts,
          );
          break;

        case HttpMethod.post:
          res = await _dio.post(url, data: data, options: opts);
          break;

        case HttpMethod.put:
          res = await _dio.put(url, data: data, options: opts);
          break;

        case HttpMethod.delete:
          res = await _dio.delete(url, data: data, options: opts);
          break;

        case HttpMethod.patch:
          _token = CancelToken();
          res = await _dio.patch(
            url,
            data: data,
            options: opts,
            cancelToken: _token,
          );
          break;

        default:
          throw ArgumentError('Invalid HTTP method: $method');
      }

      g.connectionCubit?.setOnline();
      return res;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final payload = _readBackendPayload(e.response?.data);
      final isSocket = e.error is SocketException;

      if (_isNetworkFailure(e)) {
        if (!isSocket) {
          g.connectionCubit?.setServerDown(
            payload.message ?? 'Server is not responding',
          );
        }

        throw NetworkException(
          isSocket
              ? 'No internet connection.'
              : (payload.message ??
                  "Can't reach the server. Check your internet and try again."),
          original: e,
        );
      }

      if (e.type == DioExceptionType.cancel) {
        throw AppException(
          'Request cancelled.',
          code: 'REQUEST_CANCELLED',
          original: e,
        );
      }

      if (status == null) {
        throw AppException(
          payload.message ?? 'Unexpected error.',
          code: payload.code,
          original: e,
        );
      }

      if (status >= 500) {
        g.connectionCubit?.setServerDown(
          payload.message ?? 'Server is not responding',
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
        statusCode: status,
        original: e,
        code: payload.code,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Unexpected error.', original: e);
    }
  }

  bool _isNetworkFailure(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }

    if (e.type == DioExceptionType.unknown && e.error is SocketException) {
      return true;
    }

    return false;
  }

  _BackendPayload _readBackendPayload(dynamic data) {
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
        if (value != null && value.toString().trim().isNotEmpty) {
          message = value.toString().trim();
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