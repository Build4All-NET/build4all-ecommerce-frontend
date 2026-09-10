import '../entities/photographed_product.dart';
import '../entities/picked_photo.dart';
import '../repositories/excel_import_repository.dart';

/// Stores a batch of photographs and asks what each one is.
class ReadProductPhotos {
  final ExcelImportRepository repo;

  ReadProductPhotos(this.repo);

  Future<List<PhotographedProduct>> call(List<PickedPhoto> photos) =>
      repo.readPhotos(photos);
}
