import '../entities/gallery_upload_result.dart';
import '../entities/picked_image.dart';
import '../repositories/gallery_repository.dart';

class UploadGalleryImages {
  final GalleryRepository repo;

  const UploadGalleryImages(this.repo);

  Future<GalleryUploadResult> call(List<PickedImage> images) => repo.upload(images);
}
