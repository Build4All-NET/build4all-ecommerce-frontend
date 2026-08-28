import '../entities/picked_excel_file.dart';
import '../entities/excel_import_result.dart';
import '../repositories/excel_import_repository.dart';

class ImportExcelFile {
  final ExcelImportRepository repo;
  ImportExcelFile(this.repo);

  Future<ExcelImportResult> call({
    required PickedExcelFile file,
    required bool replace,
    required String replaceScope,
    Map<int, int> imageAssignments = const {},
  }) {
    return repo.importFile(
      file: file,
      replace: replace,
      replaceScope: replaceScope,
      imageAssignments: imageAssignments,
    );
  }
}
