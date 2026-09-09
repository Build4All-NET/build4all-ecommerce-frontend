import '../entities/picked_excel_file.dart';
import '../entities/excel_import_result.dart';
import '../entities/excel_validation_result.dart';
import '../entities/description_job.dart';
import '../entities/sheet_mapping.dart';

abstract class ExcelImportRepository {
  Future<ExcelValidationResult> validate(PickedExcelFile file);

  Future<ExcelImportResult> importFile({
    required PickedExcelFile file,
    required bool replace,
    required String replaceScope,

    /// Gallery image id chosen for each product, keyed by its row in the sheet.
    Map<int, int> imageAssignments,
  });

  /// What the owner's own file appears to contain, one guess per column.
  ///
  /// A proposal only: nothing is created until the owner confirms it.
  Future<List<SheetMapping>> suggestMapping(PickedExcelFile file);

  /// Imports the owner's own file, read the way they confirmed.
  Future<ExcelImportResult> importForeignFile({
    required PickedExcelFile file,
    required String sheetName,
    required Map<int, String> columns,
    String? categoryName,
    required String matchMode,
    Map<int, int> imageAssignments,
  });

  /// How many products have nothing written about them, and whether the
  /// assistant is already writing.
  Future<DescriptionJob> descriptionsStatus();

  /// Starts writing them, and answers with the job as it stands.
  Future<DescriptionJob> startDescriptions(DescriptionJob current);

  /// The blank workbook, or null when the server could not provide it.
  Future<List<int>?> downloadTemplate();
}
