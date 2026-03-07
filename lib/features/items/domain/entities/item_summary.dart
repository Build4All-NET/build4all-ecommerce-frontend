enum ItemKind { activity, product, service, unknown }

class ItemSummary {
  final int id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? location;
  final DateTime? start;

  /// base price
  final num? price;

  /// product sale fields
  final num? salePrice;
  final DateTime? saleStart;
  final DateTime? saleEnd;
  final num? effectivePrice;
  final bool onSale;

  /// extra useful summary fields
  final int? stock;
  final String? sku;

  /// ✅ NEW: backend lifecycle status
  final int? statusId;
  final String? statusCode;
  final String? statusName;

  final ItemKind kind;

  /// category id of this item (for filtering chips)
  final int? categoryId;

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
  });

  // =========================
  // Sale helpers
  // =========================

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

  // =========================
  // Stock helpers
  // =========================

  int get safeStock => stock ?? 0;

  bool get isOutOfStock => safeStock <= 0;

  bool get isLowStock => !isOutOfStock && safeStock <= 10;

  String get computedAvailabilityStatus {
    if (isOutOfStock) return 'OUT_OF_STOCK';
    if (isLowStock) return 'LOW_STOCK';
    return 'IN_STOCK';
  }

  // =========================
  // Lifecycle status helpers
  // =========================

  // =========================
  // Lifecycle status helpers
  // =========================

  String get normalizedStatusCode =>
      (statusCode ?? '').trim().toUpperCase();

  String get normalizedStatusName =>
      (statusName ?? '').trim().toUpperCase();

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

  String get displayStatus {
    final name = (statusName ?? '').trim();
    if (name.isNotEmpty) return name;

    switch (normalizedStatusCode) {
      case 'PUBLISHED':
        return 'Published';
      case 'DRAFT':
        return 'Draft';
      case 'UPCOMING':
        return 'Upcoming';
      case 'ARCHIVED':
        return 'Archived';
      default:
        return 'Unknown';
    }
  }

  // =========================
  // User-side visibility rules
  // =========================

  /// Products can be visible if published OR upcoming.
  /// Upcoming means visible preview but not purchasable yet.
  bool get isVisibleForUser {
    if (kind == ItemKind.product) {
      return isPublished || isUpcoming;
    }
    return true;
  }

  /// Product can be bought only if published and in stock.
  bool get isAvailableForPurchase {
    if (kind == ItemKind.product) {
      return isPublished && !isOutOfStock;
    }
    return true;
  }


}