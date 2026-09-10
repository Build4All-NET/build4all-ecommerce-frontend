import '../entities/excel_product_preview.dart';
import '../repositories/excel_import_repository.dart';

/// Asks the assistant to describe rows the owner has not imported yet.
class DraftDescriptions {
  final ExcelImportRepository repo;

  DraftDescriptions(this.repo);

  Future<Map<int, String>> call(List<ExcelProductPreview> rows) =>
      repo.draftDescriptions(rows);
}
