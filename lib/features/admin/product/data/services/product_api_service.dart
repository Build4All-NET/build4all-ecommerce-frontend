import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:build4front/core/network/api_client.dart';
import 'package:build4front/core/config/env.dart';

class ProductApiService {
  final Dio _dio;

  ProductApiService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  String get _baseUrl => '${Env.apiBaseUrl}/api/products';

  Options _auth(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  // ---------------- GET LISTS ----------------

  Future<List<dynamic>> getProducts({
    int? itemTypeId,
    int? categoryId,
    required String authToken,
  }) async {
    final resp = await _dio.get(
      _baseUrl,
      queryParameters: {
        if (itemTypeId != null) 'itemTypeId': itemTypeId,
        if (categoryId != null) 'categoryId': categoryId,
      },
      options: _auth(authToken),
    );
    return resp.data as List<dynamic>;
  }

  Future<List<dynamic>> getNewArrivals({
    int? days,
    required String authToken,
  }) async {
    final resp = await _dio.get(
      '$_baseUrl/new-arrivals',
      queryParameters: {
        if (days != null) 'days': days,
      },
      options: _auth(authToken),
    );
    return resp.data as List<dynamic>;
  }

  Future<List<dynamic>> getBestSellers({
    int? limit,
    required String authToken,
  }) async {
    final resp = await _dio.get(
      '$_baseUrl/best-sellers',
      queryParameters: {
        if (limit != null) 'limit': limit,
      },
      options: _auth(authToken),
    );
    return resp.data as List<dynamic>;
  }

  Future<List<dynamic>> getDiscounted({
    required String authToken,
  }) async {
    final resp = await _dio.get(
      '$_baseUrl/discounted',
      options: _auth(authToken),
    );
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getById({
    required int id,
    required String authToken,
  }) async {
    final resp = await _dio.get('$_baseUrl/$id', options: _auth(authToken));
    return (resp.data as Map).cast<String, dynamic>();
  }

  // ---------------- HELPERS ----------------

  Map<String, dynamic> _normalizeBodyForMultipart(Map<String, dynamic> body) {
    final map = Map<String, dynamic>.from(body);

    // Convert attributes list -> attributesJson
    final attrs = map['attributes'];
    if (attrs is List) {
      map['attributesJson'] = jsonEncode(attrs);
      map.remove('attributes');
    }

    map.removeWhere((key, value) => value == null);
    return map;
  }

  Future<FormData> _buildFormData({
    required Map<String, dynamic> body,
    String? imagePath,
  }) async {
    final flat = _normalizeBodyForMultipart(body);

    final data = <String, dynamic>{...flat};

    if (imagePath != null && imagePath.isNotEmpty) {
      data['image'] = await MultipartFile.fromFile(imagePath);
    }

    return FormData.fromMap(data);
  }

  Options _multipartOptions(String token) =>
      _auth(token).copyWith(contentType: 'multipart/form-data');

  // ---------------- CREATE ----------------

  Future<Map<String, dynamic>> create({
    required Map<String, dynamic> body,
    required String authToken,
  }) async {
    final form = await _buildFormData(body: body);

    final resp = await _dio.post(
      '$_baseUrl/with-image',
      data: form,
      options: _multipartOptions(authToken),
    );

    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createWithImage({
    required Map<String, dynamic> body,
    required String imagePath,
    required String authToken,
  }) async {
    final form = await _buildFormData(body: body, imagePath: imagePath);

    final resp = await _dio.post(
      '$_baseUrl/with-image',
      data: form,
      options: _multipartOptions(authToken),
    );

    return (resp.data as Map).cast<String, dynamic>();
  }

  // ---------------- UPDATE ----------------

  Future<Map<String, dynamic>> update({
    required int id,
    required Map<String, dynamic> body,
    required String authToken,
  }) async {
    final form = await _buildFormData(body: body);

    final resp = await _dio.put(
      '$_baseUrl/$id',
      data: form,
      options: _multipartOptions(authToken),
    );

    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateWithImage({
    required int id,
    required Map<String, dynamic> body,
    required String imagePath,
    required String authToken,
  }) async {
    final form = await _buildFormData(body: body, imagePath: imagePath);

    final resp = await _dio.put(
      '$_baseUrl/$id',
      data: form,
      options: _multipartOptions(authToken),
    );

    return (resp.data as Map).cast<String, dynamic>();
  }

  // ---------------- DELETE ----------------

  Future<void> delete({required int id, required String authToken}) async {
    await _dio.delete('$_baseUrl/$id', options: _auth(authToken));
  }
}