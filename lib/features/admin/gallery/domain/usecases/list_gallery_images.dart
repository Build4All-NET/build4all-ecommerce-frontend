import '../entities/gallery_page.dart';
import '../repositories/gallery_repository.dart';

class ListGalleryImages {
  final GalleryRepository repo;

  const ListGalleryImages(this.repo);

  Future<GalleryPage> call({int page = 0, int size = 60}) =>
      repo.list(page: page, size: size);
}
