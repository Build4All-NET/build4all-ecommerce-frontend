import '../models/product_model.dart';
import '../services/product_api_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductApiService api;
  final Future<String?> Function() getToken;

  ProductRepositoryImpl({
    required this.api,
    required this.getToken,
  });

  Future<String> _requireToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Missing auth token');
    }
    return token;
  }

  @override
  Future<List<Product>> getProducts({
    required int ownerProjectId,
    int? itemTypeId,
    int? categoryId,
  }) async {
    final token = await _requireToken();
    final list = await api.getProducts(
      ownerProjectId: ownerProjectId,
      itemTypeId: itemTypeId,
      categoryId: categoryId,
      authToken: token,
    );

    return list
        .cast<Map<String, dynamic>>()
        .map((j) => ProductModel.fromJson(j))
        .toList();
  }

  @override
  Future<List<Product>> getNewArrivals({
    int? days,
  }) async {
    final token = await _requireToken();
    final list = await api.getNewArrivals(
      days: days,
      authToken: token,
    );

    return list
        .cast<Map<String, dynamic>>()
        .map((j) => ProductModel.fromJson(j))
        .toList();
  }

  @override
  Future<List<Product>> getBestSellers({
    int? limit,
  }) async {
    final token = await _requireToken();
    final list = await api.getBestSellers(
      limit: limit,
      authToken: token,
    );

    return list
        .cast<Map<String, dynamic>>()
        .map((j) => ProductModel.fromJson(j))
        .toList();
  }

  @override
  Future<List<Product>> getDiscounted({required int ownerProjectId}) async {
    final token = await _requireToken();
    final list = await api.getDiscounted(
      authToken: token,
    );

    return list
        .cast<Map<String, dynamic>>()
        .map((j) => ProductModel.fromJson(j))
        .toList();
  }

  @override
  Future<Product> getById(int id) async {
    final token = await _requireToken();
    final json = await api.getById(id: id, authToken: token);
    return ProductModel.fromJson(json);
  }

  @override
  Future<Product> createProduct({
    required int itemTypeId,
    required int? currencyId,
    required String name,
    String? description,
    required double price,
    int? stock,
    String? statusCode,
    String? imageUrl,
    String? sku,
    String productType = 'SIMPLE',
    bool virtualProduct = false,
    bool downloadable = false,
    String? downloadUrl,
    String? externalUrl,
    String? buttonText,
    double? salePrice,
    DateTime? saleStart,
    DateTime? saleEnd,
    Map<String, String>? attributes,
  }) async {
    final token = await _requireToken();

    final body = <String, dynamic>{
      'itemTypeId': itemTypeId,
      'currencyId': currencyId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'statusCode': statusCode,
      'sku': sku,
      'productType': productType,
      'virtualProduct': virtualProduct,
      'downloadable': downloadable,
      'downloadUrl': downloadUrl,
      'externalUrl': externalUrl,
      'buttonText': buttonText,
      'salePrice': salePrice,
      'saleStart': saleStart?.toIso8601String(),
      'saleEnd': saleEnd?.toIso8601String(),
      if (attributes != null)
        'attributes': attributes.entries
            .map((e) => {'code': e.key, 'value': e.value})
            .toList(),
    };

    final json = await api.create(body: body, authToken: token);
    return ProductModel.fromJson(json);
  }

  @override
  Future<Product> createProductWithImage({
    required Map<String, dynamic> body,
    required String imagePath,
  }) async {
    final token = await _requireToken();
    final json = await api.createWithImage(
      body: body,
      imagePath: imagePath,
      authToken: token,
    );
    return ProductModel.fromJson(json);
  }

  @override
  Future<Product> updateProduct(
    int id, {
    String? name,
    String? description,
    double? price,
    int? stock,
    String? statusCode,
    String? sku,
    String? productType,
    bool? virtualProduct,
    bool? downloadable,
    String? downloadUrl,
    String? externalUrl,
    String? buttonText,
    double? salePrice,
    DateTime? saleStart,
    DateTime? saleEnd,
    Map<String, String>? attributes,
  }) async {
    final token = await _requireToken();

    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (stock != null) 'stock': stock,
      if (statusCode != null) 'statusCode': statusCode,
      if (sku != null) 'sku': sku,
      if (productType != null) 'productType': productType,
      if (virtualProduct != null) 'virtualProduct': virtualProduct,
      if (downloadable != null) 'downloadable': downloadable,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
      if (externalUrl != null) 'externalUrl': externalUrl,
      if (buttonText != null) 'buttonText': buttonText,
      if (salePrice != null) 'salePrice': salePrice,
      if (saleStart != null) 'saleStart': saleStart.toIso8601String(),
      if (saleEnd != null) 'saleEnd': saleEnd.toIso8601String(),
      if (attributes != null)
        'attributes': attributes.entries
            .map((e) => {'code': e.key, 'value': e.value})
            .toList(),
    };

    final json = await api.update(id: id, body: body, authToken: token);
    return ProductModel.fromJson(json);
  }

  @override
  Future<Product> updateProductWithImage({
    required int id,
    required Map<String, dynamic> body,
    required String imagePath,
  }) async {
    final token = await _requireToken();
    final json = await api.updateWithImage(
      id: id,
      body: body,
      imagePath: imagePath,
      authToken: token,
    );
    return ProductModel.fromJson(json);
  }

  @override
  Future<void> deleteProduct(int id) async {
    final token = await _requireToken();
    await api.delete(id: id, authToken: token);
  }
}