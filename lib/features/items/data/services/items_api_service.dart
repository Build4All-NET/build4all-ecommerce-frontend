import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/network/api_fetch.dart';
import 'package:build4front/core/network/api_methods.dart';
import 'package:build4front/core/exceptions/app_exception.dart';
import 'package:build4front/core/exceptions/network_exception.dart';

class ItemsApiService {
  final ApiFetch _fetch;

  ItemsApiService({ApiFetch? fetch}) : _fetch = fetch ?? ApiFetch();

  int _ownerId() => int.tryParse(Env.ownerProjectLinkId) ?? 0;

  String get _appType => (Env.appType ?? '').toUpperCase().trim();
  bool get _isEcommerce => _appType == 'ECOMMERCE' || _appType == 'PRODUCTS';
  String get _base => _isEcommerce ? '/api/products' : '/api/items';

  Map<String, String>? _authHeaders(String? token) {
    final raw = token?.trim();
    if (raw == null || raw.isEmpty) return null;
    return {'Authorization': raw.startsWith('Bearer ') ? raw : 'Bearer $raw'};
  }

  void _requireTokenForEcommerce(String? token, String context) {
    if (!_isEcommerce) return;
    final raw = token?.trim();
    if (raw == null || raw.isEmpty) {
      throw AppException('Auth token is required for products ($context).');
    }
  }

  List<dynamic> _readListResponse(dynamic data, int? statusCode, String context) {
    if (data is! List) {
      throw ServerException(
        'Invalid response format for $context',
        statusCode: statusCode ?? 200,
      );
    }
    return List<dynamic>.from(data);
  }

  Future<List<dynamic>> _getProductsFallback({
    int? categoryId,
    int? limit,
    String? token,
  }) async {
    final ownerId = _ownerId();

    final query = <String, dynamic>{
      'ownerProjectId': ownerId,
      if (categoryId != null) 'categoryId': categoryId,
    };

    final res = await _fetch.fetch(
      HttpMethod.get,
      _base, // /api/products
      headers: _authHeaders(token),
      data: query,
    );

    final list = _readListResponse(
      res.data,
      res.statusCode,
      'fallback products list',
    );

    if (limit != null && list.length > limit) {
      return list.take(limit).toList();
    }
    return list;
  }

  Future<List<dynamic>> getUpcomingGuest({int? typeId, String? token}) async {
    final ownerId = _ownerId();

    if (_isEcommerce) {
      _requireTokenForEcommerce(token, 'getUpcomingGuest/products list');
      try {
        return await _getProductsFallback(
          categoryId: typeId,
          token: token,
        );
      } on AppException {
        rethrow;
      } catch (e) {
        throw AppException('Failed to load products list', original: e);
      }
    }

    final query = <String, dynamic>{
      'ownerProjectLinkId': ownerId,
      if (typeId != null) 'typeId': typeId,
    };

    try {
      final res = await _fetch.fetch(
        HttpMethod.get,
        '$_base/guest/upcoming',
        headers: _authHeaders(token),
        data: query,
      );

      return _readListResponse(
        res.data,
        res.statusCode,
        'upcoming items',
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Failed to load upcoming items', original: e);
    }
  }

  Future<List<dynamic>> getByType(int typeId, {String? token}) async {
    final ownerId = _ownerId();

    if (_isEcommerce) {
      _requireTokenForEcommerce(token, 'getByType/products');
      try {
        return await _getProductsFallback(
          categoryId: typeId,
          token: token,
        );
      } on AppException {
        rethrow;
      } catch (e) {
        throw AppException('Failed to load items by type', original: e);
      }
    }

    final query = <String, dynamic>{
      'ownerProjectLinkId': ownerId,
    };

    try {
      final res = await _fetch.fetch(
        HttpMethod.get,
        '$_base/by-type/$typeId',
        headers: _authHeaders(token),
        data: query,
      );

      return _readListResponse(
        res.data,
        res.statusCode,
        'items by type',
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Failed to load items by type', original: e);
    }
  }

  Future<Map<String, dynamic>> getById(int id, {String? token}) async {
    final ownerId = _ownerId();
    final path = '$_base/$id';

    final query = <String, dynamic>{};
    if (_isEcommerce) {
      _requireTokenForEcommerce(token, 'getById/products');
      query['ownerProjectId'] = ownerId;
    } else {
      query['ownerProjectLinkId'] = ownerId;
    }

    try {
      final res = await _fetch.fetch(
        HttpMethod.get,
        path,
        headers: _authHeaders(token),
        data: query,
      );

      final data = res.data;
      if (data is! Map) {
        throw ServerException(
          'Invalid response format for item details',
          statusCode: res.statusCode ?? 200,
        );
      }

      return Map<String, dynamic>.from(data as Map);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Failed to load item details', original: e);
    }
  }

  Future<Map<String, dynamic>> getDetails(int id, {String? token}) async {
    return getById(id, token: token);
  }

  Future<List<dynamic>> getInterestBased({
    required int userId,
    required String token,
  }) async {
    final ownerId = _ownerId();
    final headers = _authHeaders(token) ?? <String, String>{};

    if (_isEcommerce) {
      // ✅ DO NOT depend on broken /best-sellers for home recommended/popular
      try {
        return await _getProductsFallback(
          limit: 20,
          token: token,
        );
      } on AppException {
        rethrow;
      } catch (e) {
        throw AppException('Failed to load interest-based items', original: e);
      }
    }

    final query = <String, dynamic>{
      'ownerProjectLinkId': ownerId,
    };

    try {
      final res = await _fetch.fetch(
        HttpMethod.get,
        '$_base/category-based/$userId',
        headers: headers,
        data: query,
      );

      return _readListResponse(
        res.data,
        res.statusCode,
        'interest-based items',
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Failed to load interest-based items', original: e);
    }
  }

  Future<List<dynamic>> getNewArrivals({
    int? categoryId,
    int? days,
    String? token,
  }) async {
    final ownerId = _ownerId();

    if (_isEcommerce) {
      _requireTokenForEcommerce(token, 'getNewArrivals/products');

      final query = <String, dynamic>{
        'ownerProjectId': ownerId,
        if (categoryId != null) 'categoryId': categoryId,
        if (days != null) 'days': days,
      };

      try {
        final res = await _fetch.fetch(
          HttpMethod.get,
          '$_base/new-arrivals',
          headers: _authHeaders(token),
          data: query,
        );

        return _readListResponse(
          res.data,
          res.statusCode,
          'new arrivals',
        );
      } catch (_) {
        // ✅ fallback so Home still shows products
        return await _getProductsFallback(
          categoryId: categoryId,
          token: token,
        );
      }
    }

    final query = <String, dynamic>{
      'ownerProjectLinkId': ownerId,
    };

    try {
      final res = await _fetch.fetch(
        HttpMethod.get,
        '$_base/guest/upcoming',
        headers: _authHeaders(token),
        data: query,
      );

      return _readListResponse(
        res.data,
        res.statusCode,
        'new arrivals',
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Failed to load new arrivals', original: e);
    }
  }

  Future<List<dynamic>> getBestSellers({
    int? categoryId,
    int limit = 20,
    String? token,
  }) async {
    final ownerId = _ownerId();

    if (_isEcommerce) {
      _requireTokenForEcommerce(token, 'getBestSellers/products');

      final query = <String, dynamic>{
        'ownerProjectId': ownerId,
        'limit': limit,
        if (categoryId != null) 'categoryId': categoryId,
      };

      try {
        final res = await _fetch.fetch(
          HttpMethod.get,
          '$_base/best-sellers',
          headers: _authHeaders(token),
          data: query,
        );

        return _readListResponse(
          res.data,
          res.statusCode,
          'best-sellers',
        );
      } catch (_) {
        // ✅ backend broken? use main products list so UI still works
        return await _getProductsFallback(
          categoryId: categoryId,
          limit: limit,
          token: token,
        );
      }
    }

    final query = <String, dynamic>{
      'ownerProjectLinkId': ownerId,
    };

    try {
      final res = await _fetch.fetch(
        HttpMethod.get,
        '$_base/guest/upcoming',
        headers: _authHeaders(token),
        data: query,
      );

      return _readListResponse(
        res.data,
        res.statusCode,
        'best-sellers',
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Failed to load best-sellers', original: e);
    }
  }

  Future<List<dynamic>> getDiscounted({
    int? categoryId,
    String? token,
  }) async {
    final ownerId = _ownerId();

    if (_isEcommerce) {
      _requireTokenForEcommerce(token, 'getDiscounted/products');

      final query = <String, dynamic>{
        'ownerProjectId': ownerId,
        if (categoryId != null) 'categoryId': categoryId,
      };

      try {
        final res = await _fetch.fetch(
          HttpMethod.get,
          '$_base/discounted',
          headers: _authHeaders(token),
          data: query,
        );

        return _readListResponse(
          res.data,
          res.statusCode,
          'discounted items',
        );
      } on AppException {
        rethrow;
      } catch (e) {
        throw AppException('Failed to load discounted items', original: e);
      }
    }

    final query = <String, dynamic>{
      'ownerProjectLinkId': ownerId,
    };

    try {
      final res = await _fetch.fetch(
        HttpMethod.get,
        '$_base/guest/upcoming',
        headers: _authHeaders(token),
        data: query,
      );

      return _readListResponse(
        res.data,
        res.statusCode,
        'discounted items',
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Failed to load discounted items', original: e);
    }
  }
}