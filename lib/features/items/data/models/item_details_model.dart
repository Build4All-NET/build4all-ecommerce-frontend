import 'package:build4front/features/items/domain/entities/item_details.dart';

class ItemDetailsModel {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;

  /// New gallery field
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

  ItemDetailsModel({
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

  factory ItemDetailsModel.fromJson(Map<String, dynamic> j) {
    DateTime? dt(dynamic v) => v == null ? null : DateTime.tryParse('$v');

    num? parseNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;

      final s = '$v'.trim();
      if (s.isEmpty) return null;

      final i = int.tryParse(s);
      if (i != null) return i;

      final d = double.tryParse(s);
      if (d != null) return d;

      return double.tryParse(s.replaceAll(',', '.'));
    }

    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      return '$v'.toLowerCase() == 'true';
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v');
    }

    List<String> parseImageUrls(dynamic raw, String? fallbackImageUrl) {
      final out = <String>[];

      if (raw is List) {
        for (final e in raw) {
          if (e is Map) {
            final url = (e['imageUrl'] ?? '').toString().trim();
            if (url.isNotEmpty) {
              out.add(url);
            }
          } else {
            final url = e.toString().trim();
            if (url.isNotEmpty) {
              out.add(url);
            }
          }
        }
      }

      if (out.isEmpty) {
        final fallback = (fallbackImageUrl ?? '').trim();
        if (fallback.isNotEmpty) {
          out.add(fallback);
        }
      }

      return out;
    }

    final attrsRaw = (j['attributes'] as List?) ?? const [];
    final attrs = attrsRaw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return ItemAttribute(
        code: (m['code'] ?? '').toString(),
        value: (m['value'] ?? '').toString(),
      );
    }).toList();

    final parsedImageUrl = j['imageUrl']?.toString();

    return ItemDetailsModel(
      id: j['id'] is int ? j['id'] as int : int.parse('${j['id']}'),
      name: (j['name'] ?? j['itemName'] ?? '').toString(),
      description: j['description']?.toString(),
      imageUrl: parsedImageUrl,
      imageUrls: parseImageUrls(j['images'], parsedImageUrl),
      price: parseNum(j['price']),
      salePrice: parseNum(j['salePrice']),
      saleStart: dt(j['saleStart']),
      saleEnd: dt(j['saleEnd']),
      effectivePrice: parseNum(j['effectivePrice']),
      onSale: parseBool(j['onSale']),
      stock: parseInt(j['stock']),
      sku: j['sku']?.toString(),
      taxable: parseBool(j['taxable']),
      taxClass: j['taxClass']?.toString(),
      weightKg: parseNum(j['weightKg']),
      widthCm: parseNum(j['widthCm']),
      heightCm: parseNum(j['heightCm']),
      lengthCm: parseNum(j['lengthCm']),
      attributes: attrs,
      statusId: parseInt(j['statusId']),
      statusCode: j['statusCode']?.toString(),
      statusName: j['statusName']?.toString(),
      productType: j['productType']?.toString(),
      downloadable: parseBool(j['downloadable']),
      downloadUrl: j['downloadUrl']?.toString(),
      externalUrl: j['externalUrl']?.toString(),
      buttonText: j['buttonText']?.toString(),
      canDownload: parseBool(j['canDownload']),
      accessMessage: j['accessMessage']?.toString() ?? j['message']?.toString(),
    );
  }

  ItemDetails toEntity() {
    return ItemDetails(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      price: price,
      salePrice: salePrice,
      saleStart: saleStart,
      saleEnd: saleEnd,
      effectivePrice: effectivePrice,
      onSale: onSale,
      stock: stock,
      sku: sku,
      taxable: taxable,
      taxClass: taxClass,
      weightKg: weightKg,
      widthCm: widthCm,
      heightCm: heightCm,
      lengthCm: lengthCm,
      attributes: attributes,
      statusId: statusId,
      statusCode: statusCode,
      statusName: statusName,
      productType: productType,
      downloadable: downloadable,
      downloadUrl: downloadUrl,
      externalUrl: externalUrl,
      buttonText: buttonText,
      canDownload: canDownload,
      accessMessage: accessMessage,
    );
  }
}