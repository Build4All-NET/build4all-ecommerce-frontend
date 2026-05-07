// lib/features/checkout/domain/entities/checkout_entities.dart

/// Domain entities used by UI + Bloc.
/// Keep them lightweight and stable (don’t depend on data-layer models).

class CheckoutCart {
  final int cartId;
  final String status;
  final double totalPrice;
  final String? currencySymbol;
  final List<CheckoutCartItem> items;

  const CheckoutCart({
    required this.cartId,
    required this.status,
    required this.totalPrice,
    required this.items,
    this.currencySymbol,
  });

  bool get isEmpty => items.isEmpty;
}

class CheckoutCartItem {
  final int cartItemId;
  final int itemId;
  final String? itemName;
  final String? imageUrl;
  final int quantity;

  /// Selling/effective unit price (prefer discounted price if backend returns it)
  final double unitPrice;

  /// Line total (should match unitPrice * qty in final selling logic)
  final double lineTotal;

  const CheckoutCartItem({
    required this.cartItemId,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.itemName,
    this.imageUrl,
  });
}

class CartLine {
  final int itemId;
  final int quantity;
  final double unitPrice;

  const CartLine({
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}

class ShippingAddress {
  final int? countryId;
  final int? regionId;
  final String? city;
  final String? postalCode;

  // ✅ shipping fields
  final String? addressLine; // street + building etc.
  final String? phone; // receiver phone
  final String? fullName; // receiver name (optional)
  final String? notes; // optional delivery notes

  const ShippingAddress({
    this.countryId,
    this.regionId,
    this.city,
    this.postalCode,
    this.addressLine,
    this.phone,
    this.fullName,
    this.notes,
  });

  // ---------------------------
  // Helpers (safe parsing)
  // ---------------------------
  static String? _s(dynamic v) {
    if (v == null) return null;
    final t = v.toString().trim();
    return t.isEmpty ? null : t;
  }

  static int? _i(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// ✅ KEY FIX:
  /// Backend sends: "address"
  /// App uses: "addressLine"
  /// So we accept BOTH.
  factory ShippingAddress.fromJson(Map<String, dynamic> j) {
    return ShippingAddress(
      countryId: _i(j['countryId']),
      regionId: _i(j['regionId']),
      city: _s(j['city']),
      postalCode: _s(j['postalCode']),
      addressLine: _s(j['addressLine'] ?? j['address']),
      phone: _s(j['phone']),
      fullName: _s(j['fullName'] ?? j['name']), // allow backend variants
      notes: _s(j['notes']),
    );
  }

  /// ✅ When sending to backend, send "address" because that’s what your backend uses.
  /// Keeping addressLine too is harmless (backward compatible).
  Map<String, dynamic> toJson() => {
        'countryId': countryId,
        'regionId': regionId,
        'city': city,
        'postalCode': postalCode,
        'address': addressLine,
        'addressLine': addressLine,
        'phone': phone,
        'fullName': fullName,
        'notes': notes,
      };

  /// ✅ copyWith that supports CLEARING fields
  /// Because current one can’t set a value to null (null means "keep old").
  ShippingAddress copyWith({
    int? countryId,
    int? regionId,
    String? city,
    String? postalCode,
    String? addressLine,
    String? phone,
    String? fullName,
    String? notes,

    // 👇 these flags let you intentionally clear fields
    bool clearCity = false,
    bool clearPostalCode = false,
    bool clearAddressLine = false,
    bool clearPhone = false,
    bool clearFullName = false,
    bool clearNotes = false,
    bool clearRegionId = false,
  }) {
    return ShippingAddress(
      countryId: countryId ?? this.countryId,
      regionId: clearRegionId ? null : (regionId ?? this.regionId),
      city: clearCity ? null : (city ?? this.city),
      postalCode: clearPostalCode ? null : (postalCode ?? this.postalCode),
      addressLine: clearAddressLine ? null : (addressLine ?? this.addressLine),
      phone: clearPhone ? null : (phone ?? this.phone),
      fullName: clearFullName ? null : (fullName ?? this.fullName),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  bool get isMeaningfullyFilled {
    // adjust if you want strict validation
    return countryId != null &&
        _s(addressLine) != null &&
        _s(phone) != null;
  }
}

class ShippingQuote {
  final int? methodId;
  final String methodName;
  final double price;
  final String? currencySymbol;

  const ShippingQuote({
    required this.methodName,
    required this.price,
    this.methodId,
    this.currencySymbol,
  });

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int? _i(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static String _s(dynamic v, {String def = ''}) =>
      (v == null) ? def : v.toString();

  factory ShippingQuote.fromJson(Map<String, dynamic> j) {
    return ShippingQuote(
      methodId: _i(j['methodId']),
      methodName: _s(j['methodName'], def: 'Shipping'),
      price: _d(j['price'] ?? j['cost']),
      currencySymbol: j['currencySymbol']?.toString(),
    );
  }
}

class TaxPreview {
  final double itemsTaxTotal;
  final double shippingTaxTotal;
  final double totalTax;

  const TaxPreview({
    required this.itemsTaxTotal,
    required this.shippingTaxTotal,
    required this.totalTax,
  });

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory TaxPreview.fromJson(Map<String, dynamic> j) => TaxPreview(
        itemsTaxTotal: _d(j['itemsTaxTotal']),
        shippingTaxTotal: _d(j['shippingTaxTotal']),
        totalTax: _d(j['totalTax']),
      );
}

/// IMPORTANT:
/// PaymentMethod must carry optional configMap (for Stripe Connect acct_... etc).
/// UI uses name+code, Bloc may use configMap.
class PaymentMethod {
  final int? id;
  final String code;
  final String name;

  /// Optional payment configuration returned by backend
  /// Example for Stripe Connect:
  /// { "stripeAccountId": "acct_..." }
  final Map<String, dynamic>? configMap;

  const PaymentMethod({
    this.id,
    required this.code,
    required this.name,
    this.configMap,
  });

  PaymentMethod copyWith({
    int? id,
    String? code,
    String? name,
    Map<String, dynamic>? configMap,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      configMap: configMap ?? this.configMap,
    );
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> j) {
    // Buyer-facing label comes from the backend's gateway plugin
    // (`displayName`). Older backends only sent `name` (the technical
    // code), so we fall through to keep both directions compatible.
    final display = (j['displayName'] ?? j['name'] ?? '').toString();
    return PaymentMethod(
      id: (j['id'] is num) ? (j['id'] as num).toInt() : int.tryParse('${j['id']}'),
      code: (j['code'] ?? '').toString(),
      name: display,
      configMap: (j['configMap'] is Map)
          ? Map<String, dynamic>.from(j['configMap'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'configMap': configMap,
      };
}
