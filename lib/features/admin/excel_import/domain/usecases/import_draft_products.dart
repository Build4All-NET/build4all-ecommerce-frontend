import '../entities/excel_import_result.dart';
import '../repositories/excel_import_repository.dart';

/// Creates the products the owner assembled with no file behind them.
class ImportDraftProducts {
  final ExcelImportRepository repo;

  ImportDraftProducts(this.repo);

  Future<ExcelImportResult> call({
    required List<Map<String, Object?>> products,
    String? categoryName,
    required String matchMode,
  }) {
    return repo.importDrafts(
      products: products,
      categoryName: categoryName,
      matchMode: matchMode,
    );
  }
}
