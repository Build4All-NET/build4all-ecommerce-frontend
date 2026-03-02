import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({
   
    int? itemTypeId,
    int? categoryId,
  });

  Future<List<Product>> getNewArrivals({
    
    int? days,
  });

  Future<List<Product>> getBestSellers({
    
    int? limit,
  });

  Future<List<Product>> getDiscounted({required int ownerProjectId});

  Future<Product> getById(int id);

  Future<Product> createProduct({
    
    required int itemTypeId,
    required int? currencyId,

    required String name,
    String? description,
    required double price,
    int? stock,

    String? imageUrl, // ✅ ADD

    String? sku,

    String productType,
    bool virtualProduct,
    bool downloadable,
    String? downloadUrl,

    String? externalUrl,
    String? buttonText,

    double? salePrice,
    DateTime? saleStart,
    DateTime? saleEnd,

    Map<String, String>? attributes,
  });

  /// ✅ new: create with file
  Future<Product> createProductWithImage({
    required Map<String, dynamic> body,
    required String imagePath,
  });

  Future<Product> updateProduct(
    int id, {
    String? name,
    String? description,
    double? price,
    int? stock,
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
  });

  /// ✅ new: update with file
  Future<Product> updateProductWithImage({
    required int id,
    required Map<String, dynamic> body,
    required String imagePath,
  });

  Future<void> deleteProduct(int id);
}
