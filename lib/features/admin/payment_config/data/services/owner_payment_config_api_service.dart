import 'package:dio/dio.dart';

class OwnerPaymentConfigApiService {
  final Dio dio;
  final String baseUrl;

  OwnerPaymentConfigApiService({required this.dio, required this.baseUrl});

  String _cleanToken(String token) {
    final t = token.trim();
    return t.toLowerCase().startsWith('bearer ') ? t.substring(7).trim() : t;
  }

  String _apiRoot() {
    var b = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    b = b.replaceAll('/api/api', '/api');
    if (!b.endsWith('/api')) b = '$b/api';
    return b;
  }

  Options _auth(String token) =>
      Options(headers: {'Authorization': 'Bearer ${_cleanToken(token)}'});

  Future<List<dynamic>> listMethods({
    required String token,
  }) async {
    final url = '${_apiRoot()}/owner/projects/payment/methods';
    final res = await dio.get(url, options: _auth(token));
    if (res.data is List) return res.data as List;
    return [];
  }

  Future<void> saveMethodConfig({
    required String token,
    required String methodName,
    required bool enabled,
    required Map<String, Object?> configValues,
  }) async {
    final url = '${_apiRoot()}/owner/projects/payment/methods/$methodName';

    await dio.put(
      url,
      data: {'enabled': enabled, 'configValues': configValues},
      options: _auth(token),
    );
  }
}