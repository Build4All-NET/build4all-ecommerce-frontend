import 'gallery_image.dart';

/// One page of the gallery, plus whether there is more behind it.
class GalleryPage {
  final List<GalleryImage> items;
  final int page;
  final int totalElements;
  final bool hasMore;

  const GalleryPage({
    required this.items,
    required this.page,
    required this.totalElements,
    required this.hasMore,
  });

  static const empty = GalleryPage(
    items: [],
    page: 0,
    totalElements: 0,
    hasMore: false,
  );
}
