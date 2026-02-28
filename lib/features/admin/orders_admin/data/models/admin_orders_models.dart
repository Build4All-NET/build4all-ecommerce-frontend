import 'dart:convert';

import 'package:build4front/core/config/env.dart';
import '../../domain/entities/admin_order_entities.dart';

DateTime? _tryParseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
  return null;
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

String? _toNullableString(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty || s.toLowerCase() == 'null') return null;
  return s;
}

String? _firstNonEmpty(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final s = _toNullableString(json[k]);
    if (s != null) return s;
  }
  return null;
}

String? _normalizeUrl(String? raw) {
  final s = _toNullableString(raw);
  if (s == null) return null;

  // already absolute
  if (s.startsWith('http://') || s.startsWith('https://') || s.startsWith('data:')) {
    return s;
  }

  // protocol-relative URL
  if (s.startsWith('//')) {
    return 'https:$s';
  }

  // relative path -> resolve against backend base URL
  try {
    final base = Uri.parse(Env.apiBaseUrl);
    return base.resolve(s).toString();
  } catch (_) {
    // fallback (safe string concat)
    final base = Env.apiBaseUrl.endsWith('/')
        ? Env.apiBaseUrl.substring(0, Env.apiBaseUrl.length - 1)
        : Env.apiBaseUrl;
    final path = s.startsWith('/') ? s : '/$s';
    return '$base$path';
  }
}

String? _extractImageUrl(Map<String, dynamic> json) {
  // Common direct keys
  final direct = _firstNonEmpty(json, const [
    'imageUrl',
    'imageURL',
    'image',
    'itemImage',
    'thumbnailUrl',
    'thumbnail',
    'photoUrl',
    'photo',
    'coverImage',
    'cover',
  ]);
  if (direct != null) return _normalizeUrl(direct);

  // Nested image object: { image: { url: ... } }
  final imageObj = json['image'];
  if (imageObj is Map) {
    final m = imageObj.cast<String, dynamic>();
    final nested = _firstNonEmpty(m, const [
      'url',
      'imageUrl',
      'path',
      'src',
      'thumbnailUrl',
    ]);
    if (nested != null) return _normalizeUrl(nested);
  }

  // List images: [{url:...}] or ["..."]
  final images = json['images'];
  if (images is List && images.isNotEmpty) {
    final first = images.first;
    if (first is String) return _normalizeUrl(first);
    if (first is Map) {
      final m = first.cast<String, dynamic>();
      final nested = _firstNonEmpty(m, const [
        'url',
        'imageUrl',
        'path',
        'src',
        'thumbnailUrl',
      ]);
      if (nested != null) return _normalizeUrl(nested);
    }
  }

  return null;
}

class PaymentSummaryModel {
  final double orderTotal;
  final double paidAmount;
  final double remainingAmount;
  final bool fullyPaid;
  final String paymentState;

  PaymentSummaryModel({
    required this.orderTotal,
    required this.paidAmount,
    required this.remainingAmount,
    required this.fullyPaid,
    required this.paymentState,
  });

  factory PaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    return PaymentSummaryModel(
      orderTotal: _toDouble(json['orderTotal']),
      paidAmount: _toDouble(json['paidAmount']),
      remainingAmount: _toDouble(json['remainingAmount']),
      fullyPaid: json['fullyPaid'] == true,
      paymentState: (json['paymentState'] ?? '').toString(),
    );
  }

  PaymentSummary toEntity() => PaymentSummary(
        orderTotal: orderTotal,
        paidAmount: paidAmount,
        remainingAmount: remainingAmount,
        fullyPaid: fullyPaid,
        paymentState: paymentState,
      );
}

class OrderHeaderRowModel {
  final int id;
  final DateTime? orderDate;
  final double totalPrice;
  final String status;
  final String statusUi;
  final int itemsCount;
  final bool fullyPaid;
  final PaymentSummaryModel payment;

  final String? phone;
  final String? addressLine;

  // ✅ NEW
  final String? orderCode;
  final int? orderSeq;

  OrderHeaderRowModel({
    required this.id,
    required this.orderDate,
    required this.totalPrice,
    required this.status,
    required this.statusUi,
    required this.itemsCount,
    required this.fullyPaid,
    required this.payment,
    this.phone,
    this.addressLine,

    // ✅ NEW
    this.orderCode,
    this.orderSeq,
  });

  factory OrderHeaderRowModel.fromJson(Map<String, dynamic> json) {
    return OrderHeaderRowModel(
      id: _toInt(json['id']),
      orderDate: _tryParseDate(json['orderDate']),
      totalPrice: _toDouble(json['totalPrice']),
      status: (json['status'] ?? '').toString(),
      statusUi: (json['statusUi'] ?? '').toString(),
      itemsCount: _toInt(json['itemsCount']),
      fullyPaid: json['fullyPaid'] == true,
      payment: PaymentSummaryModel.fromJson(
        (json['payment'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      phone: _firstNonEmpty(json, const ['phone', 'shippingPhone']),
      addressLine: _firstNonEmpty(json, const [
        'addressline',
        'addressLine',
        'shippingAddress',
        'shippingAddressLine',
      ]),

      // ✅ NEW
      orderCode: json['orderCode']?.toString(),
      orderSeq: json['orderSeq'] == null ? null : _toInt(json['orderSeq']),
    );
  }

  OrderHeaderRow toEntity() => OrderHeaderRow(
        id: id,
        orderDate: orderDate,
        totalPrice: totalPrice,
        status: status,
        statusUi: statusUi,
        itemsCount: itemsCount,
        fullyPaid: fullyPaid,
        payment: payment.toEntity(),
        phone: phone,
        addressLine: addressLine,

        // ✅ NEW
        orderCode: orderCode,
        orderSeq: orderSeq,
      );
}

 

class CurrencyMiniModel {
  final String? code;
  final String? symbol;

  CurrencyMiniModel({this.code, this.symbol});

  factory CurrencyMiniModel.fromJson(Map<String, dynamic> json) {
    return CurrencyMiniModel(
      code: json['code']?.toString(),
      symbol: json['symbol']?.toString(),
    );
  }

  CurrencyMini toEntity() => CurrencyMini(code: code, symbol: symbol);
}

class UserMiniModel {
  final int id;
  final String? username;
  final String? firstName;
  final String? lastName;

  UserMiniModel({
    required this.id,
    this.username,
    this.firstName,
    this.lastName,
  });
factory UserMiniModel.fromJson(Map<String, dynamic> json) {
  String? pick(List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
    }
    return null;
  }

  final fullNameRaw = pick([
    'fullName',
    'full_name',
    'name',
    'customerName',
    'customer_name',
  ]);

  String? first = pick(['firstName', 'first_name']);
  String? last = pick(['lastName', 'last_name']);
  String? usern = pick(['username', 'userName', 'login']);

  // If backend sends one full name only, split it softly
  if (fullNameRaw != null && ((first == null || first.isEmpty) && (last == null || last.isEmpty))) {
    final parts = fullNameRaw.split(RegExp(r'\s+')).where((e) => e.trim().isNotEmpty).toList();
    if (parts.isNotEmpty) {
      first = parts.first;
      if (parts.length > 1) {
        last = parts.sublist(1).join(' ');
      }
    }
    usern ??= fullNameRaw;
  }

  return UserMiniModel(
    id: _toInt(json['id']),
    username: usern,
    firstName: first,
    lastName: last,
  );
}

  UserMini toEntity() => UserMini(
        id: id,
        username: username,
        firstName: firstName,
        lastName: lastName,
      );
}

class ItemMiniDetailsModel {
  final int id;
  final String itemName;
  final String? imageUrl;
  final String? location;
  final DateTime? startDatetime;

  ItemMiniDetailsModel({
    required this.id,
    required this.itemName,
    this.imageUrl,
    this.location,
    this.startDatetime,
  });

  factory ItemMiniDetailsModel.fromJson(Map<String, dynamic> json) {
    return ItemMiniDetailsModel(
      id: _toInt(json['id']),
      itemName: _firstNonEmpty(json, const ['itemName', 'name', 'title']) ?? '',
      imageUrl: _extractImageUrl(json), // ✅ robust image parsing
      location: _firstNonEmpty(json, const ['location', 'address', 'place']),
      startDatetime: _tryParseDate(
        json['startDatetime'] ?? json['startDateTime'] ?? json['startDate'],
      ),
    );
  }

  ItemMiniDetails toEntity() => ItemMiniDetails(
        id: id,
        itemName: itemName,
        imageUrl: imageUrl,
        location: location,
        startDatetime: startDatetime,
      );
}

class OrderDetailsItemModel {
  final int orderItemId;
  final int quantity;
  final double price;
  final ItemMiniDetailsModel item;
  final UserMiniModel user;

  OrderDetailsItemModel({
    required this.orderItemId,
    required this.quantity,
    required this.price,
    required this.item,
    required this.user,
  });

  factory OrderDetailsItemModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailsItemModel(
      orderItemId: _toInt(json['orderItemId']),
      quantity: _toInt(json['quantity']),
      price: _toDouble(json['price']),
      item: ItemMiniDetailsModel.fromJson(
        (json['item'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      user: UserMiniModel.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  OrderDetailsItem toEntity() => OrderDetailsItem(
        orderItemId: orderItemId,
        quantity: quantity,
        price: price,
        item: item.toEntity(),
        user: user.toEntity(),
      );
}

class OrderDetailsHeaderModel {
  final int id;
  final DateTime? orderDate;
  final double totalPrice;

  final String status;
  final String statusUi;

  final String? paymentMethod;
  final CurrencyMiniModel? currency;

  final String? shippingCity;
  final String? shippingPostalCode;
  final String? shippingFullName;

  final String? shippingPhone;
  final String? shippingAddress;

  final int? shippingMethodId;
  final String? shippingMethodName;
  final double? shippingTotal;
  final double? itemTaxTotal;
  final double? shippingTaxTotal;
  final String? couponCode;
  final double? couponDiscount;
final String? orderCode;
  final int? orderSeq;
  final bool fullyPaid;
  final PaymentSummaryModel payment;
  

  OrderDetailsHeaderModel({
    required this.id,
    required this.orderDate,
    required this.totalPrice,
    required this.status,
    required this.statusUi,
    required this.orderCode,
    required this.orderSeq,

    this.shippingFullName,
    this.paymentMethod,
    this.currency,
    this.shippingCity,
    this.shippingPostalCode,
    this.shippingPhone,
    this.shippingAddress,
    this.shippingMethodId,
    this.shippingMethodName,
    this.shippingTotal,
    this.itemTaxTotal,
    this.shippingTaxTotal,
    this.couponCode,
    this.couponDiscount,
    required this.fullyPaid,
    required this.payment,
  });

  factory OrderDetailsHeaderModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailsHeaderModel(
      id: _toInt(json['id']),
      orderDate: _tryParseDate(json['orderDate']),
      totalPrice: _toDouble(json['totalPrice']),
      status: (json['status'] ?? '').toString(),
      statusUi: (json['statusUi'] ?? '').toString(),
      

      paymentMethod: json['paymentMethod']?.toString(),
      currency: (json['currency'] is Map)
          ? CurrencyMiniModel.fromJson(
              (json['currency'] as Map).cast<String, dynamic>(),
            )
          : null,

      shippingCity: _firstNonEmpty(json, const ['shippingCity', 'city']),
      shippingPostalCode:
          _firstNonEmpty(json, const ['shippingPostalCode', 'postalCode']),

      // ✅ supports multiple backend naming styles
      shippingPhone: _firstNonEmpty(json, const ['shippingPhone', 'phone']),
      shippingAddress: _firstNonEmpty(json, const [
        'shippingAddress',
        'shippingAddressLine',
        'addressLine',
        'addressline',
        'address',
      ]),

      shippingFullName: _firstNonEmpty(json, const [
  'shippingFullName',
  'fullName',
  'customerName',
]),

      shippingMethodId: json['shippingMethodId'] == null
          ? null
          : _toInt(json['shippingMethodId']),
      shippingMethodName: json['shippingMethodName']?.toString(),
      shippingTotal: json['shippingTotal'] == null
          ? null
          : _toDouble(json['shippingTotal']),
      itemTaxTotal:
          json['itemTaxTotal'] == null ? null : _toDouble(json['itemTaxTotal']),
      shippingTaxTotal: json['shippingTaxTotal'] == null
          ? null
          : _toDouble(json['shippingTaxTotal']),
      couponCode: json['couponCode']?.toString(),
      couponDiscount: json['couponDiscount'] == null
          ? null
          : _toDouble(json['couponDiscount']),

      fullyPaid: json['fullyPaid'] == true,
      payment: PaymentSummaryModel.fromJson(
        (json['payment'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
       orderCode: json['orderCode']?.toString(),
      orderSeq: json['orderSeq'] == null ? null : _toInt(json['orderSeq']),
    );
  }

OrderDetailsHeader toEntity() => OrderDetailsHeader(
  id: id,
  orderDate: orderDate,
  totalPrice: totalPrice,
  status: status,
  statusUi: statusUi,
  orderCode: orderCode,
  orderSeq: orderSeq,
  paymentMethod: paymentMethod,
  currency: currency?.toEntity(),
  shippingCity: shippingCity,
  shippingPostalCode: shippingPostalCode,
  shippingPhone: shippingPhone,
  shippingAddress: shippingAddress,

  // ✅ ADD THIS LINE
  shippingFullName: shippingFullName,

  shippingMethodId: shippingMethodId,
  shippingMethodName: shippingMethodName,
  shippingTotal: shippingTotal,
  itemTaxTotal: itemTaxTotal,
  shippingTaxTotal: shippingTaxTotal,
  couponCode: couponCode,
  couponDiscount: couponDiscount,
  fullyPaid: fullyPaid,
  payment: payment.toEntity(),
);
}

class OrderDetailsResponseModel {
  final OrderDetailsHeaderModel order;
  final int itemsCount;
  final List<OrderDetailsItemModel> items;

  OrderDetailsResponseModel({
    required this.order,
    required this.itemsCount,
    required this.items,
  });

  factory OrderDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailsResponseModel(
      order: OrderDetailsHeaderModel.fromJson(
        (json['order'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      itemsCount: _toInt(json['itemsCount']),
      items: (json['items'] is List)
          ? (json['items'] as List)
              .whereType<Map>()
              .map((m) => OrderDetailsItemModel.fromJson(m.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }

  OrderDetailsResponse toEntity() => OrderDetailsResponse(
        order: order.toEntity(),
        itemsCount: itemsCount,
        items: items.map((e) => e.toEntity()).toList(),
      );
}