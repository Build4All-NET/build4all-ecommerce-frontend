import '../entities/photographed_product.dart';
import '../repositories/excel_import_repository.dart';

/// Asks the assistant to describe photographed products, the same way
/// [DraftDescriptions] does for rows a file named.
class DraftPhotoDescriptions {
  final ExcelImportRepository repo;

  DraftPhotoDescriptions(this.repo);

  Future<Map<int, String>> call(List<PhotographedProduct> photos) =>
      repo.draftPhotoDescriptions(photos);
}
