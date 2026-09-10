import '../../domain/entities/photographed_product.dart';

/// Reads what the server made of a batch of photographs.
class PhotographedProductModel {
  const PhotographedProductModel._();

  static List<PhotographedProduct> listFromJson(dynamic json) {
    if (json is! List) return const [];

    return json.whereType<Map>().map((raw) {
      final photo = raw.cast<String, dynamic>();

      return PhotographedProduct(
        photoIndex: photo['photoIndex'] is num
            ? (photo['photoIndex'] as num).toInt()
            : 0,
        mediaId: photo['mediaId'] is num ? (photo['mediaId'] as num).toInt() : null,
        imageUrl: photo['imageUrl']?.toString(),
        name: photo['name']?.toString().trim() ?? '',
        category: photo['category']?.toString().trim(),
      );
    }).toList();
  }
}
