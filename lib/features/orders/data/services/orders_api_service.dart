import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:build4front/features/auth/data/services/auth_token_store.dart';
import 'package:build4front/core/network/globals.dart' as g;
import 'package:build4front/core/exceptions/app_exception.dart';
import 'package:build4front/core/exceptions/auth_exception.dart';
import 'package:build4front/core/exceptions/network_exception.dart';

class OrdersApiService {
  final Dio _dio;
  final AuthTokenStore tokenStore;

  OrdersApiService({Dio? dio, required this.tokenStore})
      : _dio = dio ?? g.dio();

  Future<Map<String, String>> _authHeaders() async {
    final token = await tokenStore.getToken();

    if (token == null || token.trim().isEmpty) {
      return {};
    }

    final t = token.trim();
    final bearer = t.toLowerCase().startsWith('bearer ') ? t : 'Bearer $t';
    return {'Authorization': bearer};
  }

  _BackendPayload _readPayload(dynamic data) {
    String? code;
    String? message;

    if (data is String) {
      final s = data.trim();
      if (s.isNotEmpty) {
        if ((s.startsWith('{') && s.endsWith('}')) ||
            (s.startsWith('[') && s.endsWith(']'))) {
          try {
            final decoded = json.decode(s);
            return _readPayload(decoded);
          } catch (_) {
            message = s;
          }
        } else {
          message = s;
        }
      }
    } else if (data is Map) {
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

      final reqId = map['requestId']?.toString().trim();
      if (message != null &&
          message.isNotEmpty &&
          reqId != null &&
          reqId.isNotEmpty) {
        message = '$message (requestId: $reqId)';
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
    }

    return _BackendPayload(
      code: code,
      message: (message == null || message.isEmpty) ? null : message,
    );
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

  String _fallbackForStatus(int? statusCode, {String? notFoundMessage}) {
    switch (statusCode) {
      case 400:
      case 422:
        return 'Invalid request.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You do not have permission to do this.';
      case 404:
        return notFoundMessage ?? 'Not found.';
      case 409:
        return 'Conflict. This already exists or can’t be done now.';
      default:
        if ((statusCode ?? 0) >= 500) {
          return 'Server error. Please try again later.';
        }
        return 'Request failed.';
    }
  }

  Never _throwMappedDio(
    DioException e, {
    String? notFoundMessage,
    String? genericFallback,
  }) {
    final status = e.response?.statusCode;
    final payload = _readPayload(e.response?.data);
    final isSocket = e.error is SocketException;

    if (_isNetworkFailure(e)) {
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

    if (status == 401 || status == 403) {
      throw AuthException(
        payload.message ?? 'Session expired. Please log in again.',
        code: payload.code,
        original: e,
      );
    }

    throw ServerException(
      payload.message ??
          genericFallback ??
          _fallbackForStatus(
            status,
            notFoundMessage: notFoundMessage,
          ),
      statusCode: status ?? 0,
      code: payload.code,
      original: e,
    );
  }

  Future<List<dynamic>> getMyOrdersRaw() async {
    final headers = await _authHeaders();

    try {
      final res = await _dio.get(
        '/api/orders/myorders',
        options: Options(headers: headers),
      );

      final data = res.data;

      if (data is List) return data;

      if (data is Map) {
        final orders = data['orders'];
        if (orders is List) return orders;

        final inner = data['data'];
        if (inner is Map && inner['orders'] is List) {
          return inner['orders'] as List;
        }
      }

      return const [];
    } on DioException catch (e) {
      _throwMappedDio(
        e,
        genericFallback: 'Failed to load orders.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        'Failed to load orders.',
        original: e,
      );
    }
  }

  Future<Map<String, dynamic>> getOrderDetailsRaw(int orderId) async {
    final headers = await _authHeaders();

    final candidates = <String>[
      '/api/orders/myorders/$orderId',
    ];

    DioException? lastDioError;

    for (final path in candidates) {
      try {
        final res = await _dio.get(
          path,
          options: Options(headers: headers),
        );

        final data = res.data;
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        return {'data': data};
      } on DioException catch (e) {
        final sc = e.response?.statusCode ?? 0;

        if (sc == 404) {
          continue;
        }

        if (sc == 401 || sc == 403) {
          _throwMappedDio(
            e,
            notFoundMessage: 'Order details were not found.',
            genericFallback: 'Failed to load order details.',
          );
        }

        if (sc >= 500) {
          lastDioError = e;
          continue;
        }

        _throwMappedDio(
          e,
          notFoundMessage: 'Order details were not found.',
          genericFallback: 'Failed to load order details.',
        );
      } catch (e) {
        if (e is AppException) rethrow;
        throw AppException(
          'Failed to load order details.',
          original: e,
        );
      }
    }

    if (lastDioError != null) {
      _throwMappedDio(
        lastDioError!,
        notFoundMessage: 'Order details were not found.',
        genericFallback: 'Server error. Please try again later.',
      );
    }

    throw ServerException(
      'Order details were not found.',
      statusCode: 404,
    );
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