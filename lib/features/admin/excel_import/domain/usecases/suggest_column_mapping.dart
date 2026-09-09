import '../entities/picked_excel_file.dart';
import '../entities/sheet_mapping.dart';
import '../repositories/excel_import_repository.dart';

/// Asks what the owner's own file appears to contain, so they can confirm it.
class SuggestColumnMapping {
  final ExcelImportRepository repo;

  SuggestColumnMapping(this.repo);

  Future<List<SheetMapping>> call(PickedExcelFile file) => repo.suggestMapping(file);
}
