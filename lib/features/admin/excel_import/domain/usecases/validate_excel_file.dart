import '../entities/picked_excel_file.dart';
import '../entities/excel_validation_result.dart';
import '../repositories/excel_import_repository.dart';

class ValidateExcelFile {
  final ExcelImportRepository repo;
  ValidateExcelFile(this.repo);

  Future<ExcelValidationResult> call(PickedExcelFile file) => repo.validate(file);
}
