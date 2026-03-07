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

  // ✅ new backend status shape
  final int? statusId;
  final String? statusCode;
  final String? statusName;

  final String? imageUrl;

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

  final Map<String, String> attributes; // code -> value

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

  /// real purchasable backend lifecycle status
  bool get isPublished => statusCode == 'PUBLISHED';

  bool get isDraft => statusCode == 'DRAFT';

  bool get isUpcoming => statusCode == 'UPCOMING';

  bool get isArchived => statusCode == 'ARCHIVED';

  /// product can be bought only if published and has stock
  bool get isAvailableForPurchase => isPublished && !isOutOfStock;

  /// UI-only availability label, NOT backend status
  String get computedAvailabilityStatus =>
      isOutOfStock ? 'OUT_OF_STOCK' : 'IN_STOCK';

  /// display label for lifecycle status
  String get displayStatus => statusName ?? statusCode ?? 'UNKNOWN';
}