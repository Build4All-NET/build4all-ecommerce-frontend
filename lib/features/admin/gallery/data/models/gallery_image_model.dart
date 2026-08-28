import '../../domain/entities/gallery_image.dart';

class GalleryImageModel extends GalleryImage {
  const GalleryImageModel({
    required super.id,
    required super.url,
    super.fileName,
    super.sizeBytes,
  });

  static GalleryImageModel? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    final url = json['url']?.toString();

    // An image with no id cannot be attached and one with no url cannot be
    // shown, so it is dropped rather than rendered as a broken tile.
    if (id == null || url == null || url.trim().isEmpty) return null;

    return GalleryImageModel(
      id: id,
      url: url.trim(),
      fileName: json['originalFilename']?.toString(),
      sizeBytes: _asInt(json['sizeBytes']),
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
