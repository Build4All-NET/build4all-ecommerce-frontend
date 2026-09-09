import '../entities/foreign_preview.dart';
import '../entities/picked_excel_file.dart';
import '../repositories/excel_import_repository.dart';

/// Asks what the import would create, so the owner can look before it does.
class PreviewForeignFile {
  final ExcelImportRepository repo;

  PreviewForeignFile(this.repo);

  Future<ForeignPreview> call({
    required PickedExcelFile file,
    required String sheetName,
    required Map<int, String> columns,
    String? categoryName,
  }) {
    return repo.previewForeignFile(
      file: file,
      sheetName: sheetName,
      columns: columns,
      categoryName: categoryName,
    );
  }
}
