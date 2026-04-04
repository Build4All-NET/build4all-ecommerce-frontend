import 'package:dio/dio.dart';
import 'package:build4front/core/network/globals.dart' as g;

class AdminOrdersApiService {
  final Dio _dio;
  final Future<String?> Function() getToken;

  AdminOrdersApiService({Dio? dio, required this.getToken})
      : _dio = dio ?? g.dio();

  String _cleanToken(String token) {
    final t = token.trim();
    return t.toLowerCase().startsWith('bearer ')
        ? t.substring(7).trim()
        : t;
  }

  Options _auth(String token) =>
      Options(headers: {'Authorization': 'Bearer ${_cleanToken(token)}'});

  RequestOptions _req(String path) => RequestOptions(path: path);

  Future<String> _requireToken() async {
    final token = await getToken();
    if (token == null || token.trim().isEmpty) {
      throw DioException(
        requestOptions: _req('/api/orders/owner/orders'),
        response: Response(
          requestOptions: _req('/api/orders/owner/orders'),
          statusCode: 401,
          data: {
            'code': 'AUTH',
            'error': 'Session expired. Please login again.',
          },
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return token;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return data.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    return const <dynamic>[];
  }

  Future<List<dynamic>> getOrdersRaw({String? status}) async {
    final token = await _requireToken();
    const base = '/api/orders/owner/orders';

    if (status == null || status.trim().isEmpty) {
      final res = await _dio.get(base, options: _auth(token));
      return _asList(res.data);
    }

    final s = status.trim().toUpperCase();
    final res = await _dio.get('$base/status/$s', options: _auth(token));
    return _asList(res.data);
  }

  Future<Map<String, dynamic>> getOrderDetailsRaw({
    required int orderId,
  }) async {
    final token = await _requireToken();
    final path = '/api/orders/owner/orders/$orderId';

    final res = await _dio.get(path, options: _auth(token));
    return _asMap(res.data);
  }

  Future<void> updateOrderStatusRaw({
    required int orderId,
    required String status,
  }) async {
    final token = await _requireToken();
    final path = '/api/orders/owner/orders/$orderId/status';

    await _dio.put(
      path,
      options: _auth(token),
      data: {'status': status.trim().toUpperCase()},
    );
  }

  Future<Map<String, dynamic>> editOrderRaw({
    required int orderId,
    required Map<String, dynamic> body,
  }) async {
    final token = await _requireToken();
    final path = '/api/orders/owner/orders/$orderId/edit';

    final res = await _dio.put(
      path,
      options: _auth(token),
      data: body,
    );

    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> markCashPaidRaw({
    required int orderId,
  }) async {
    final token = await _requireToken();
    final path = '/api/orders/owner/orders/$orderId/cash/mark-paid';

    final res = await _dio.put(path, options: _auth(token));
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> resetCashToUnpaidRaw({
    required int orderId,
  }) async {
    final token = await _requireToken();
    final path = '/api/orders/owner/orders/$orderId/cash/reset-to-unpaid';

    final res = await _dio.put(path, options: _auth(token));
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> reopenOrderRaw({
    required int orderId,
  }) async {
    final token = await _requireToken();
    final path = '/api/orders/owner/orders/$orderId/reopen';

    final res = await _dio.put(path, options: _auth(token));
    return _asMap(res.data);
  }
}