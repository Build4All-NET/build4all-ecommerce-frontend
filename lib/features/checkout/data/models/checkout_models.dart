// lib/features/checkout/data/models/checkout_models.dart
import 'dart:convert';

/// Data-layer models (parsing backend JSON).
/// These are mapped into domain entities in the repository.

class CheckoutCartModel {
  final int cartId;
  final String status;
  final double totalPrice;
  final String? currencySymbol;
  final List<CheckoutCartItemModel> items;

  CheckoutCartModel({
    required this.cartId,
    required this.status,
    required this.totalPrice,
    required this.items,
    this.currencySymbol,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory CheckoutCartModel.fromJson(Map<String, dynamic> json) {
    return CheckoutCartModel(
      cartId: (json['cartId'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '').toString(),
      totalPrice: _toDouble(json['totalPrice']),
      currencySymbol: json['currencySymbol']?.toString(),
      items: (json['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => CheckoutCartItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class CheckoutCartItemModel {
  final int cartItemId;
  final int itemId;
  final String? itemName;
  final String? imageUrl;
  final int quantity;

  /// selling/effective unit
  final double unitPrice;

  /// line total
  final double lineTotal;

  CheckoutCartItemModel({
    required this.cartItemId,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.itemName,
    this.imageUrl,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory CheckoutCartItemModel.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toInt() ?? 0;

    // base unit price (original)
    final baseUnit = _toDouble(json['unitPrice']);

    // selling/effective unit price if backend provides it
    final effectiveUnit = _toDouble(
      json['effectiveUnitPrice'] ??
          json['sellingUnitPrice'] ??
          json['discountedUnitPrice'] ??
          json['finalUnitPrice'] ??
          json['displayUnitPrice'],
    );

    final unit = (effectiveUnit > 0) ? effectiveUnit : baseUnit;

    // line total from backend (if present)
    final backendLine = _toDouble(
      json['lineTotal'] ??
          json['lineSubtotal'] ??
          json['total'] ??
          json['subtotal'],
    );

    final computedLine = (backendLine > 0) ? backendLine : (unit * qty);

    return CheckoutCartItemModel(
      cartItemId: (json['cartItemId'] as num?)?.toInt() ?? 0,
      itemId: (json['itemId'] as num?)?.toInt() ?? 0,
      itemName: json['itemName']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      quantity: qty,
      unitPrice: unit,
      lineTotal: computedLine,
    );
  }
}

class ShippingQuoteModel {
  final int? methodId;
  final String methodName;
  final double price;
  final String? currencySymbol;

  ShippingQuoteModel({
    required this.methodName,
    required this.price,
    this.methodId,
    this.currencySymbol,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory ShippingQuoteModel.fromJson(Map<String, dynamic> json) {
    return ShippingQuoteModel(
      methodId: (json['methodId'] as num?)?.toInt(),
      methodName: (json['methodName'] ?? '').toString(),
      price: _toDouble(json['price']),
      currencySymbol: json['currencySymbol']?.toString(),
    );
  }
}

class TaxPreviewModel {
  final double itemsTaxTotal;
  final double shippingTaxTotal;
  final double totalTax;

  TaxPreviewModel({
    required this.itemsTaxTotal,
    required this.shippingTaxTotal,
    required this.totalTax,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory TaxPreviewModel.fromJson(Map<String, dynamic> json) {
    final items = _toDouble(json['itemsTaxTotal']);
    final ship = _toDouble(json['shippingTaxTotal']);
    final total = _toDouble(json['totalTax']);
    return TaxPreviewModel(
      itemsTaxTotal: items,
      shippingTaxTotal: ship,
      totalTax: total == 0 ? (items + ship) : total,
    );
  }
}

class PaymentMethodModel {
  final int? id;
  final String code;
  final String name;
  final bool enabled;

  /// Backend config_json parsed to Map
  final Map<String, dynamic>? configMap;

  PaymentMethodModel({
    this.id,
    required this.code,
    required this.name,
    required this.enabled,
    this.configMap,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> j) {
    String pick(dynamic v) => (v ?? '').toString().trim();

    // Buyer-facing label. Backend now returns `displayName` from the
    // gateway plugin (e.g. MPGS → "Card", STRIPE → "Stripe"). Older
    // responses only had `name` (= the technical code), so fall back
    // through `name` / `label` so old clients hitting a new backend
    // and new clients hitting an old backend both keep working.
    final name = pick(j['displayName'] ?? j['name'] ?? j['label']);
    final code = pick(j['code'] ?? j['paymentMethod'] ?? j['method'] ?? name).toUpperCase();

    final enabled = (j['enabled'] is bool) ? (j['enabled'] as bool) : true;

    // config can come as Map or JSON string
    Map<String, dynamic>? cfg;
    final rawCfg = j['config'] ?? j['configMap'] ?? j['config_json'] ?? j['configJson'];
    if (rawCfg is Map) {
      cfg = Map<String, dynamic>.from(rawCfg);
    } else if (rawCfg is String && rawCfg.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(rawCfg);
        if (decoded is Map) cfg = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    return PaymentMethodModel(
      id: (j['id'] as num?)?.toInt(),
      name: name.isEmpty ? (code.isEmpty ? 'Unknown' : code) : name,
      code: code.isEmpty ? name.toUpperCase() : code,
      enabled: enabled,
      configMap: cfg,
    );
  }
}
