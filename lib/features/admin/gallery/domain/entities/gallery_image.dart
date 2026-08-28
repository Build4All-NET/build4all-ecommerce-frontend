/// One picture the owner has uploaded into their app's gallery.
///
/// The id is what gets attached to a product; the url is only for showing it.
/// They are kept apart on purpose: a private bucket signs a fresh url on every
/// read, so a url must never be treated as the identity of an image.
class GalleryImage {
  final int id;
  final String url;
  final String? fileName;
  final int? sizeBytes;

  const GalleryImage({
    required this.id,
    required this.url,
    this.fileName,
    this.sizeBytes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is GalleryImage && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
