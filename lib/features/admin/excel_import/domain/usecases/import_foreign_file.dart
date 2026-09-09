import '../entities/excel_import_result.dart';
import '../entities/picked_excel_file.dart';
import '../repositories/excel_import_repository.dart';

/// Imports the owner's own file, read the way they confirmed on the review screen.
class ImportForeignFile {
  final ExcelImportRepository repo;

  ImportForeignFile(this.repo);

  Future<ExcelImportResult> call({
    required PickedExcelFile file,
    required String sheetName,
    required Map<int, String> columns,
    String? categoryName,
    required String matchMode,
    Map<int, Map<String, Object>> rowEdits = const {},
    Map<int, int> imageAssignments = const {},
  }) {
    return repo.importForeignFile(
      file: file,
      sheetName: sheetName,
      columns: columns,
      categoryName: categoryName,
      matchMode: matchMode,
      rowEdits: rowEdits,
      imageAssignments: imageAssignments,
    );
  }
}
