import 'dart:convert';

enum ProductTypeDto { simple, variable, grouped, external }

String productTypeDtoToApi(ProductTypeDto t) {
  switch (t) {
    case ProductTypeDto.simple:
      return 'SIMPLE';
    case ProductTypeDto.variable:
      return 'VARIABLE';
    case ProductTypeDto.grouped:
      return 'GROUPED';
    case ProductTypeDto.external:
      return 'EXTERNAL';
  }
}

class AttributeValueDto {
  final String code;
  final String value;

  AttributeValueDto({required this.code, required this.value});

  Map<String, dynamic> toJson() => {
        'code': code,
        'value': value,
      };
}

class CreateProductRequest {
  final int? itemTypeId;
  final int? categoryId;
  final int? currencyId;

  final String name;
  final String? description;
  final double price;
  final int? stock;

  // ✅ new backend field
  final String? statusCode;
  final String? sku;

  final ProductTypeDto productType;

  final bool virtualProduct;
  final bool downloadable;
  final String? downloadUrl;
  final String? externalUrl;
  final String? buttonText;

  final double? salePrice;
  final String? saleStart;
  final String? saleEnd;

  final List<AttributeValueDto> attributes;

  CreateProductRequest({
    this.itemTypeId,
    this.categoryId,
    this.currencyId,
    required this.name,
    this.description,
    required this.price,
    this.stock,
    this.statusCode,
    this.sku,
    required this.productType,
    this.virtualProduct = false,
    this.downloadable = false,
    this.downloadUrl,
    this.externalUrl,
    this.buttonText,
    this.salePrice,
    this.saleStart,
    this.saleEnd,
    this.attributes = const [],
  }) : assert(
          itemTypeId != null || categoryId != null,
          'Either itemTypeId or categoryId must be provided',
        );

  Map<String, dynamic> toJson() {
    return {
      if (itemTypeId != null) 'itemTypeId': itemTypeId,
      if (categoryId != null) 'categoryId': categoryId,
      if (currencyId != null) 'currencyId': currencyId,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      if (stock != null) 'stock': stock,
      if (statusCode != null) 'statusCode': statusCode,
      if (sku != null) 'sku': sku,
      'productType': productTypeDtoToApi(productType),
      'virtualProduct': virtualProduct,
      'downloadable': downloadable,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
      if (externalUrl != null) 'externalUrl': externalUrl,
      if (buttonText != null) 'buttonText': buttonText,
      if (salePrice != null) 'salePrice': salePrice,
      if (saleStart != null) 'saleStart': saleStart,
      if (saleEnd != null) 'saleEnd': saleEnd,
      if (attributes.isNotEmpty)
        'attributes': attributes.map((e) => e.toJson()).toList(),
    };
  }

  String toJsonString() => jsonEncode(toJson());
}