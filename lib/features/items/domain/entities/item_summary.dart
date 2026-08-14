enum ItemKind { activity, product, service, unknown }

/// What the primary call-to-action on an item should do.
///
/// The entity resolves the *action*; the presentation layer maps it to a
/// localized label (`openLabel` / `downloadLabel` /
/// `adminButtonTextDefaultAddToCart`). Domain code stays free of l10n.
enum ItemActionKind { open, download, addToCart }

class ItemSummary {
  final int id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? location;
  final DateTime? start;

  final num? price;
  final num? salePrice;
  final DateTime? saleStart;
  final DateTime? saleEnd;
  final num? effectivePrice;
  final bool onSale;

  final int? stock;
  final String? sku;

  final int? statusId;
  final String? statusCode;
  final String? statusName;

  final ItemKind kind;
  final int? categoryId;

  final String? productType;
  final bool downloadable;
  final String? downloadUrl;
  final String? externalUrl;
  final String? buttonText;

  const ItemSummary({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.location,
    this.start,
    this.price,
    this.salePrice,
    this.saleStart,
    this.saleEnd,
    this.effectivePrice,
    this.onSale = false,
    this.stock,
    this.sku,
    this.statusId,
    this.statusCode,
    this.statusName,
    this.kind = ItemKind.unknown,
    this.categoryId,
    this.productType,
    this.downloadable = false,
    this.downloadUrl,
    this.externalUrl,
    this.buttonText,
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

  bool get isStockTracked => stock != null;

  bool get isOutOfStock => isStockTracked && stock! <= 0;

  bool get isLowStock => isStockTracked && stock! > 0 && stock! <= 10;

  String get computedAvailabilityStatus {
    if (isOutOfStock) return 'OUT_OF_STOCK';
    if (isLowStock) return 'LOW_STOCK';
    return 'IN_STOCK';
  }

  String get normalizedStatusCode => (statusCode ?? '').trim().toUpperCase();
  String get normalizedStatusName => (statusName ?? '').trim().toUpperCase();

  bool get isPublished =>
      normalizedStatusCode == 'PUBLISHED' ||
      normalizedStatusName == 'PUBLISHED';

  bool get isDraft =>
      normalizedStatusCode == 'DRAFT' ||
      normalizedStatusName == 'DRAFT';

  bool get isUpcoming =>
      normalizedStatusCode == 'UPCOMING' ||
      normalizedStatusName == 'UPCOMING';

  bool get isArchived =>
      normalizedStatusCode == 'ARCHIVED' ||
      normalizedStatusName == 'ARCHIVED';

  /// Technical status code for the UI to localize: PUBLISHED / DRAFT /
  /// UPCOMING / ARCHIVED / UNKNOWN. Never a display string.
  String get displayStatusCode {
    switch (normalizedStatusCode) {
      case 'PUBLISHED':
      case 'DRAFT':
      case 'UPCOMING':
      case 'ARCHIVED':
        return normalizedStatusCode;
      default:
        return 'UNKNOWN';
    }
  }

  /// The backend-provided status name when the owner set one, otherwise the
  /// technical code — the presentation layer localizes the code via
  /// `productStatus*` keys.
  String get displayStatus {
    final name = (statusName ?? '').trim();
    if (name.isNotEmpty) return name;
    return displayStatusCode;
  }

  String get normalizedProductType => (productType ?? '').trim().toUpperCase();

  bool get isExternalProduct => normalizedProductType == 'EXTERNAL';

  bool get hasExternalUrl => (externalUrl ?? '').trim().isNotEmpty;

  bool get hasDownloadUrl => (downloadUrl ?? '').trim().isNotEmpty;

  bool get isVisibleForUser {
    if (kind == ItemKind.product) {
      return isPublished || isUpcoming;
    }
    return true;
  }

  bool get isAvailableForPurchase {
    if (kind == ItemKind.product) {
      if (isExternalProduct) return hasExternalUrl;
      return isPublished && !isOutOfStock;
    }
    return true;
  }

  /// Owner-configured button text, when they set one. It is their own copy, so
  /// it is passed through untranslated.
  String? get customButtonText {
    final t = (buttonText ?? '').trim();
    return t.isEmpty ? null : t;
  }

  /// Fallback action when the owner set no custom text. The UI turns this into a
  /// localized label.
  ItemActionKind get resolvedActionKind {
    if (isExternalProduct) return ItemActionKind.open;
    if (downloadable) return ItemActionKind.download;
    return ItemActionKind.addToCart;
  }
}