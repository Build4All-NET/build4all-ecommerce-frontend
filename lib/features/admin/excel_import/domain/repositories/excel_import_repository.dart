import '../entities/picked_excel_file.dart';
import '../entities/excel_import_result.dart';
import '../entities/excel_validation_result.dart';

abstract class ExcelImportRepository {
  Future<ExcelValidationResult> validate(PickedExcelFile file);
  Future<ExcelImportResult> importFile({
    required PickedExcelFile file,
    required bool replace,
    required String replaceScope,
  });
}
