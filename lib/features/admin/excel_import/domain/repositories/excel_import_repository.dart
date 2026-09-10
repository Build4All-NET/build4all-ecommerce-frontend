import '../entities/picked_excel_file.dart';
import '../entities/excel_import_result.dart';
import '../entities/excel_validation_result.dart';
import '../entities/description_job.dart';
import '../entities/excel_product_preview.dart';
import '../entities/foreign_preview.dart';
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

  /// What importing the owner's own file would create, without creating it.
  Future<ForeignPreview> previewForeignFile({
    required PickedExcelFile file,
    required String sheetName,
    required Map<int, String> columns,
    String? categoryName,
  });

  /// Imports the owner's own file, read the way they confirmed.
  Future<ExcelImportResult> importForeignFile({
    required PickedExcelFile file,
    required String sheetName,
    required Map<int, String> columns,
    String? categoryName,
    required String matchMode,

    /// Prices and quantities the owner typed on the review screen, by row.
    Map<int, Map<String, Object>> rowEdits,

    /// Gallery image id chosen for each product, by row.
    Map<int, int> imageAssignments,
  });

  /// How many products have nothing written about them, and whether the
  /// assistant is already writing.
  Future<DescriptionJob> descriptionsStatus();

  /// Descriptions for rows that are not products yet, keyed by row.
  ///
  /// Nothing is saved: the owner keeps or changes the text on the review screen.
  Future<Map<int, String>> draftDescriptions(List<ExcelProductPreview> rows);

  /// Starts writing them, and answers with the job as it stands.
  Future<DescriptionJob> startDescriptions(DescriptionJob current);

  /// The blank workbook, or null when the server could not provide it.
  Future<List<int>?> downloadTemplate();
}
