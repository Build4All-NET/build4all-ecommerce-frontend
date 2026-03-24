import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:build4front/core/utils/upload_safe_image_normalizer.dart';
import 'create_product_request.dart';

class UpdateProductRequest {
  final String? name;
  final String? description;
  final double? price;
  final int? stock;

  final String? statusCode;
  final String? sku;

  final ProductTypeDto? productType;

  final bool? virtualProduct;
  final bool? downloadable;
  final String? downloadUrl;
  final String? externalUrl;
  final String? buttonText;

  final double? salePrice;
  final String? saleStart;
  final String? saleEnd;

  final List<AttributeValueDto>? attributes;

  final int? itemTypeId;
  final int? categoryId;
  final int? currencyId;

  final XFile? image;

  UpdateProductRequest({
    this.name,
    this.description,
    this.price,
    this.stock,
    this.statusCode,
    this.sku,
    this.productType,
    this.virtualProduct,
    this.downloadable,
    this.downloadUrl,
    this.externalUrl,
    this.buttonText,
    this.salePrice,
    this.saleStart,
    this.saleEnd,
    this.attributes,
    this.itemTypeId,
    this.categoryId,
    this.currencyId,
    this.image,
  });

  String? get attributesJson => (attributes == null || attributes!.isEmpty)
      ? null
      : jsonEncode(attributes!.map((e) => e.toJson()).toList());

  Future<FormData> toFormData() async {
    final map = <String, dynamic>{
      if (itemTypeId != null) 'itemTypeId': itemTypeId,
      if (categoryId != null) 'categoryId': categoryId,
      if (currencyId != null) 'currencyId': currencyId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (stock != null) 'stock': stock,
      if (statusCode != null) 'statusCode': statusCode,
      if (sku != null) 'sku': sku,
      if (productType != null) 'productType': productTypeDtoToApi(productType!),
      if (virtualProduct != null) 'virtualProduct': virtualProduct,
      if (downloadable != null) 'downloadable': downloadable,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
      if (externalUrl != null) 'externalUrl': externalUrl,
      if (buttonText != null) 'buttonText': buttonText,
      if (salePrice != null) 'salePrice': salePrice,
      if (saleStart != null) 'saleStart': saleStart,
      if (saleEnd != null) 'saleEnd': saleEnd,
      if (attributesJson != null) 'attributesJson': attributesJson,
    };

    final form = FormData.fromMap(map);

    if (image != null) {
      final safeImagePath = await UploadSafeImageNormalizer.normalizeImagePath(
        image!.path,
        preferredName: 'product_update_upload',
      );
      form.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            safeImagePath,
            filename: File(safeImagePath).uri.pathSegments.last,
          ),
        ),
      );
    }

    return form;
  }
}