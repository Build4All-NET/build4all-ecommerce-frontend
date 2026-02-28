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
      throw DioException(
        requestOptions: RequestOptions(path: '/api/orders'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/orders'),
          statusCode: 401,
          data: {'error': 'No token found. Please login again.'},
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final t = token.trim();
    final bearer = t.toLowerCase().startsWith('bearer ') ? t : 'Bearer $t';
    return {'Authorization': bearer};
  }

  String _extractError(dynamic data, {int? statusCode}) {
    if (data is Map) {
      final err = data['error'] ?? data['message'];
      final reqId = data['requestId'];
      if (err != null && reqId != null) {
        return '${err.toString()} (requestId: ${reqId.toString()})';
      }
      if (err != null) return err.toString();
    }
    return 'Request failed${statusCode != null ? " (HTTP $statusCode)" : ""}.';
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

  /// ✅ Order Details: tries multiple possible backend routes.
  /// IMPORTANT: this expects an actual ORDER ID (like 81), NOT a line id (like 116).
  Future<Map<String, dynamic>> getOrderDetailsRaw(int orderId) async {
    final headers = await _authHeaders();

    // try multiple common detail routes (first that returns 200 wins)
    final candidates = <String>[
      '/api/orders/$orderId',
      '/api/orders/details/$orderId',
      '/api/orders/myorders/details/$orderId',
      // fallback to your current one (if backend actually supports it)
      '/api/orders/myorders/$orderId',
    ];

    DioException? lastDioError;
    for (final path in candidates) {
      try {
        final res = await _dio.get(
          path,
          options: Options(
            headers: headers,
            // ✅ so we can inspect 404/400 and continue trying
            validateStatus: (_) => true,
          ),
        );

        final sc = res.statusCode ?? 0;

        if (sc >= 200 && sc < 300) {
          final data = res.data;
          if (data is Map) return data.cast<String, dynamic>();
          // if backend returns non-map, still return something sane
          return {'data': data};
        }

        // If it's 404, try next candidate
        if (sc == 404) continue;

        // If it's 401/403, stop immediately (auth issue)
        if (sc == 401 || sc == 403) {
          throw Exception(_extractError(res.data, statusCode: sc));
        }

        // If it's 500, keep a meaningful error but still try others
        if (sc >= 500) {
          lastDioError = DioException(
            requestOptions: res.requestOptions,
            response: res,
            type: DioExceptionType.badResponse,
            message: _extractError(res.data, statusCode: sc),
          );
          continue;
        }

        // other 4xx
        throw Exception(_extractError(res.data, statusCode: sc));
      } catch (e) {
        if (e is DioException) {
          lastDioError = e;
          continue;
        }
        // non-dio error (rare)
        throw Exception(e.toString());
      }
    }

    // nothing worked
    if (lastDioError != null) {
      final data = lastDioError!.response?.data;
      throw Exception(_extractError(data, statusCode: lastDioError!.response?.statusCode));
    }

    throw Exception('Order details endpoint not found (no matching route).');
  }
}