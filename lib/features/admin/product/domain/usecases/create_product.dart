import '../entities/product.dart';
import '../repositories/product_repository.dart';

class CreateProduct {
  final ProductRepository repo;

  CreateProduct(this.repo);

  Future<Product> call({
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
    String? externalUrl,
    String? buttonText,
    double? salePrice,
    DateTime? saleStart,
    DateTime? saleEnd,
    Map<String, String>? attributes,
  }) {
    return repo.createProduct(
      itemTypeId: itemTypeId,
      currencyId: currencyId,
      name: name,
      description: description,
      price: price,
      stock: stock,
      statusCode: statusCode,
      imageUrl: imageUrl,
      sku: sku,
      productType: productType,
      virtualProduct: virtualProduct,
      externalUrl: externalUrl,
      buttonText: buttonText,
      salePrice: salePrice,
      saleStart: saleStart,
      saleEnd: saleEnd,
      attributes: attributes,
    );
  }
}