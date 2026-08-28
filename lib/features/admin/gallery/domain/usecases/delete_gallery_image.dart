import '../repositories/gallery_repository.dart';

class DeleteGalleryImage {
  final GalleryRepository repo;

  const DeleteGalleryImage(this.repo);

  Future<void> call(int imageId) => repo.delete(imageId);
}
