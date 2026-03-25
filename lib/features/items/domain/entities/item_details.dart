class ItemAttribute {
  final String code;
  final String value;

  const ItemAttribute({
    required this.code,
    required this.value,
  });
}

class ItemDetails {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;

  /// New gallery field for product details
  final List<String> imageUrls;

  final num? price;
  final num? salePrice;
  final DateTime? saleStart;
  final DateTime? saleEnd;
  final num? effectivePrice;
  final bool onSale;

  final int? stock;
  final String? sku;

  final bool taxable;
  final String? taxClass;

  final num? weightKg;
  final num? widthCm;
  final num? heightCm;
  final num? lengthCm;

  final List<ItemAttribute> attributes;

  final int? statusId;
  final String? statusCode;
  final String? statusName;

  final String? productType;
  final bool downloadable;
  final String? downloadUrl;
  final String? externalUrl;
  final String? buttonText;

  final bool canDownload;
  final String? accessMessage;

  const ItemDetails({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.imageUrls = const [],
    this.price,
    this.salePrice,
    this.saleStart,
    this.saleEnd,
    this.effectivePrice,
    this.onSale = false,
    this.stock,
    this.sku,
    this.taxable = false,
    this.taxClass,
    this.weightKg,
    this.widthCm,
    this.heightCm,
    this.lengthCm,
    this.attributes = const [],
    this.statusId,
    this.statusCode,
    this.statusName,
    this.productType,
    this.downloadable = false,
    this.downloadUrl,
    this.externalUrl,
    this.buttonText,
    this.canDownload = false,
    this.accessMessage,
  });

  bool get isSaleActiveNow {
    if (!onSale) return false;
    final now = DateTime.now();

    if (saleStart == null && saleEnd == null) return true;
    if (saleStart != null && saleEnd == null) return !now.isBefore(saleStart!);
    if (saleStart == null && saleEnd != null) return !now.isAfter(saleEnd!);

    return !now.isBefore(saleStart!) && !now.isAfter(saleEnd!);
  }

  num? get displayPrice {
    if (isSaleActiveNow) {
      return effectivePrice ?? salePrice ?? price;
    }
    return price;
  }

  num? get oldPriceIfDiscounted {
    final cur = displayPrice;
    if (!isSaleActiveNow) return null;
    if (price == null || cur == null) return null;
    if (price! <= cur) return null;
    return price;
  }

  String get normalizedStatusCode => (statusCode ?? '').trim().toUpperCase();
  String get normalizedStatusName => (statusName ?? '').trim().toUpperCase();

  bool get isUpcoming =>
      normalizedStatusCode == 'UPCOMING' ||
      normalizedStatusName == 'UPCOMING';

  String get normalizedProductType => (productType ?? '').trim().toUpperCase();

  bool get isExternalProduct => normalizedProductType == 'EXTERNAL';

  bool get hasExternalUrl => (externalUrl ?? '').trim().isNotEmpty;

  bool get hasDownloadUrl => (downloadUrl ?? '').trim().isNotEmpty;

  bool get isDownloadReady => downloadable && canDownload;

  String get resolvedButtonText {
    final t = (buttonText ?? '').trim();
    if (t.isNotEmpty) return t;
    if (isExternalProduct) return 'Open';
    if (isDownloadReady) return 'Download';
    return 'Add to cart';
  }

  List<String> get galleryImageUrls {
    final cleaned = imageUrls
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (cleaned.isNotEmpty) return cleaned;

    final fallback = (imageUrl ?? '').trim();
    if (fallback.isNotEmpty) return [fallback];

    return const [];
  }

  String? get displayImageUrl =>
      galleryImageUrls.isNotEmpty ? galleryImageUrls.first : null;
}