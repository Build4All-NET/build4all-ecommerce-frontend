import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:build4front/features/auth/data/services/auth_token_store.dart';
import 'package:build4front/core/network/globals.dart' as g;

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

  String _extractError(dynamic data, {int? statusCode}) {
    if (data == null) {
      return 'Request failed${statusCode != null ? " (HTTP $statusCode)" : ""}.';
    }

    if (data is String) {
      final s = data.trim();

      if (s.isEmpty) {
        return 'Request failed${statusCode != null ? " (HTTP $statusCode)" : ""}.';
      }

      if ((s.startsWith('{') && s.endsWith('}')) ||
          (s.startsWith('[') && s.endsWith(']'))) {
        try {
          final decoded = json.decode(s);
          return _extractError(decoded, statusCode: statusCode);
        } catch (_) {
          return s;
        }
      }

      return s;
    }

    if (data is Map) {
      final err = data['error'] ?? data['message'] ?? data['detail'];
      final reqId = data['requestId'];

      if (err != null && reqId != null) {
        return '${err.toString()} (requestId: ${reqId.toString()})';
      }
      if (err != null) return err.toString();

      final code = data['code'];
      if (code != null) return code.toString();
    }

    return 'Request failed${statusCode != null ? " (HTTP $statusCode)" : ""}.';
  }

  String _fallbackByStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
      case 422:
        return 'Invalid request.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You do not have permission to do this.';
      case 404:
        return 'Order not found.';
      default:
        if ((statusCode ?? 0) >= 500) {
          return 'Server error. Please try again later.';
        }
        return 'Request failed.';
    }
  }

  String _extractDioMessage(DioException e, {String? fallback}) {
    final sc = e.response?.statusCode;
    final extracted = _extractError(
      e.response?.data,
      statusCode: sc,
    ).trim();

    if (extracted.isNotEmpty &&
        !extracted.toLowerCase().startsWith('request failed')) {
      return extracted;
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Try again.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }

    return fallback ?? _fallbackByStatus(sc);
  }

  String _extractUnknownMessage(Object e, {String? fallback}) {
    final raw = e.toString().trim();

    if (raw.isEmpty) {
      return fallback ?? 'Something went wrong. Please try again.';
    }

    final cleaned = raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^DioException:\s*'), '')
        .replaceFirst(RegExp(r'^Bad state:\s*'), '')
        .trim();

    if (cleaned.isEmpty) {
      return fallback ?? 'Something went wrong. Please try again.';
    }

    return cleaned;
  }

  Future<List<dynamic>> getMyOrdersRaw() async {
    final headers = await _authHeaders();

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
        if (data is Map) return data.cast<String, dynamic>();
        return {'data': data};
      } on DioException catch (e) {
        final sc = e.response?.statusCode ?? 0;

        if (sc == 404) continue;

        if (sc == 401 || sc == 403) {
          rethrow;
        }

        if (sc >= 500) {
          lastDioError = e;
          continue;
        }

        throw Exception(
          _extractDioMessage(
            e,
            fallback: 'Failed to load order details.',
          ),
        );
      } catch (e) {
        throw Exception(
          _extractUnknownMessage(
            e,
            fallback: 'Failed to load order details.',
          ),
        );
      }
    }

    if (lastDioError != null) {
      throw Exception(
        _extractDioMessage(
          lastDioError!,
          fallback: 'Server error. Please try again later.',
        ),
      );
    }

    throw Exception('Order details were not found.');
  }
}