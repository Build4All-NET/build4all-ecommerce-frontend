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

    String? imageUrl, // ✅ ADD

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
  }) {
    return repo.createProduct(
     
      itemTypeId: itemTypeId,
      currencyId: currencyId,

      name: name,
      description: description,
      price: price,
      stock: stock,

      imageUrl: imageUrl, // ✅ PASS

      sku: sku,

      productType: productType,
      virtualProduct: virtualProduct,
      downloadable: downloadable,
      downloadUrl: downloadUrl,

      externalUrl: externalUrl,
      buttonText: buttonText,

      salePrice: salePrice,
      saleStart: saleStart,
      saleEnd: saleEnd,

      attributes: attributes,
    );
  }
}
