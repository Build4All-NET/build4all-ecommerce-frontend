import '../entities/gallery_page.dart';
import '../entities/gallery_upload_result.dart';
import '../entities/picked_image.dart';

abstract class GalleryRepository {
  Future<GalleryPage> list({required int page, required int size});

  Future<GalleryUploadResult> upload(List<PickedImage> images);

  Future<void> delete(int imageId);
}
