import '../../domain/entities/product.dart';
import '../../domain/entities/product_image.dart';

class ProductModel extends Product {
  ProductModel({
    required super.id,
    required super.ownerProjectId,
    super.itemTypeId,
    super.currencyId,
    super.categoryId,
    required super.name,
    super.description,
    required super.price,
    super.stock,
    super.statusId,
    super.statusCode,
    super.statusName,
    super.imageUrl,
    super.images,
    super.sku,
    required super.productType,
    required super.virtualProduct,
    required super.downloadable,
    super.downloadUrl,
    super.externalUrl,
    super.buttonText,
    super.salePrice,
    super.saleStart,
    super.saleEnd,
    required super.effectivePrice,
    required super.onSale,
    required super.attributes,
  });

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim());
  }

  static bool _toBool(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static Map<String, String> _parseAttrs(dynamic raw) {
    final out = <String, String>{};

    if (raw == null) return out;

    if (raw is Map) {
      raw.forEach((k, v) {
        final key = k.toString().trim();
        final val = (v ?? '').toString().trim();
        if (key.isNotEmpty && val.isNotEmpty) {
          out[key] = val;
        }
      });
      return out;
    }

    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          final code = (e['code'] ?? e['key'] ?? '').toString().trim();
          final value = (e['value'] ?? '').toString().trim();
          if (code.isNotEmpty && value.isNotEmpty) {
            out[code] = value;
          }
        }
      }
    }

    return out;
  }

  static List<ProductImage> _parseImages(dynamic raw, String? fallbackImageUrl) {
    final out = <ProductImage>[];

    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          final url = (e['imageUrl'] ?? '').toString().trim();
          if (url.isEmpty) continue;

          out.add(
            ProductImage(
              id: _toInt(e['id']),
              imageUrl: url,
              sortOrder: _toInt(e['sortOrder']) ?? 0,
              isMain: _toBool(
                e['mainImage'] ?? e['isMainImage'] ?? e['isMain'],
                fallback: false,
              ),
            ),
          );
        }
      }
    }

    if (out.isEmpty) {
      final fallback = fallbackImageUrl?.trim();
      if (fallback != null && fallback.isNotEmpty) {
        out.add(
          ProductImage(
            id: null,
            imageUrl: fallback,
            sortOrder: 0,
            isMain: true,
          ),
        );
      }
    }

    out.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return out;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final nestedCurrency = json['currency'];
    final nestedCurrencyId =
        (nestedCurrency is Map) ? _toInt(nestedCurrency['id']) : null;

    final parsedCurrencyId =
        _toInt(json['currencyId']) ??
        _toInt(json['currency_id']) ??
        nestedCurrencyId;

    final price = _toDouble(json['price']) ?? 0.0;
    final salePrice = _toDouble(json['salePrice']);
    final effectivePrice =
        _toDouble(json['effectivePrice']) ?? salePrice ?? price;

    final parsedStock = _toInt(json['stock']);
    final parsedStatusId = _toInt(json['statusId']);
    final parsedStatusCode = json['statusCode']?.toString().trim();
    final parsedStatusName = json['statusName']?.toString().trim();
    final parsedImageUrl = json['imageUrl']?.toString();

    return ProductModel(
      id: _toInt(json['id']) ?? 0,
      ownerProjectId:
          _toInt(json['ownerProjectId']) ??
          _toInt(json['ownerProjectLinkId']) ??
          0,
      itemTypeId: _toInt(json['itemTypeId']),
      currencyId: parsedCurrencyId,
      categoryId: _toInt(json['categoryId']),
      name: (json['name'] ?? json['itemName'] ?? '').toString(),
      description: json['description']?.toString(),
      price: price,
      stock: parsedStock,
      statusId: parsedStatusId,
      statusCode: parsedStatusCode,
      statusName: parsedStatusName,
      imageUrl: parsedImageUrl,
      images: _parseImages(json['images'], parsedImageUrl),
      sku: json['sku']?.toString(),
      productType: (json['productType'] ?? 'SIMPLE').toString(),
      virtualProduct: _toBool(json['virtualProduct'], fallback: false),
      downloadable: _toBool(json['downloadable'], fallback: false),
      downloadUrl: json['downloadUrl']?.toString(),
      externalUrl: json['externalUrl']?.toString(),
      buttonText: json['buttonText']?.toString(),
      salePrice: salePrice,
      saleStart: _toDate(json['saleStart']),
      saleEnd: _toDate(json['saleEnd']),
      effectivePrice: effectivePrice,
      onSale: _toBool(json['onSale'], fallback: false),
      attributes: _parseAttrs(json['attributes']),
    );
  }
}