import 'gallery_image.dart';

/// The outcome of one bulk upload.
///
/// Failures are carried alongside the successes rather than thrown, because a
/// single unreadable file out of thirty should not read to the owner as "the
/// upload failed".
class GalleryUploadResult {
  final List<GalleryImage> uploaded;
  final List<String> failed;

  const GalleryUploadResult({
    required this.uploaded,
    required this.failed,
  });
}
