import 'product_image.dart';

class Product {
  final int id;
  final int ownerProjectId;
  final int? itemTypeId;
  final int? currencyId;
  final int? categoryId;

  final String name;
  final String? description;
  final double price;
  final int? stock;

  final int? statusId;
  final String? statusCode;
  final String? statusName;

  /// old main image field from backend
  final String? imageUrl;

  /// new gallery field from backend
  final List<ProductImage> images;

  final String? sku;
  final String productType; // SIMPLE / VARIABLE / GROUPED / EXTERNAL

  final bool virtualProduct;
  final bool downloadable;
  final String? downloadUrl;
  final String? externalUrl;
  final String? buttonText;

  final double? salePrice;
  final DateTime? saleStart;
  final DateTime? saleEnd;

  final double effectivePrice;
  final bool onSale;

  final Map<String, String> attributes;

  const Product({
    required this.id,
    required this.ownerProjectId,
    this.itemTypeId,
    this.currencyId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.stock,
    this.statusId,
    this.statusCode,
    this.statusName,
    this.imageUrl,
    this.images = const [],
    this.sku,
    required this.productType,
    required this.virtualProduct,
    required this.downloadable,
    this.downloadUrl,
    this.externalUrl,
    this.buttonText,
    this.salePrice,
    this.saleStart,
    this.saleEnd,
    required this.effectivePrice,
    required this.onSale,
    required this.attributes,
  });

  int get safeStock => stock ?? 0;

  bool get isOutOfStock => safeStock <= 0;

  bool get isPublished => statusCode == 'PUBLISHED';
  bool get isDraft => statusCode == 'DRAFT';
  bool get isUpcoming => statusCode == 'UPCOMING';
  bool get isArchived => statusCode == 'ARCHIVED';

  bool get isAvailableForPurchase => isPublished && !isOutOfStock;

  String get computedAvailabilityStatus =>
      isOutOfStock ? 'OUT_OF_STOCK' : 'IN_STOCK';

  String get displayStatus => statusName ?? statusCode ?? 'UNKNOWN';

  List<ProductImage> get galleryImages {
    if (images.isNotEmpty) return images;

    final fallback = imageUrl?.trim();
    if (fallback == null || fallback.isEmpty) return const [];

    return const [];
  }

  ProductImage? get mainImage {
    if (images.isNotEmpty) {
      for (final image in images) {
        if (image.isMain) return image;
      }
      return images.first;
    }

    final fallback = imageUrl?.trim();
    if (fallback == null || fallback.isEmpty) return null;

    return ProductImage(
      id: null,
      imageUrl: fallback,
      sortOrder: 0,
      isMain: true,
    );
  }

  String? get displayImageUrl => mainImage?.imageUrl ?? imageUrl;
}