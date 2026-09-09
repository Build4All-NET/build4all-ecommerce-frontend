import 'package:equatable/equatable.dart';

import '../../domain/entities/excel_import_result.dart';
import '../../domain/entities/picked_excel_file.dart';
import '../../domain/entities/excel_product_preview.dart';
import '../../domain/entities/description_job.dart';
import '../../domain/entities/excel_validation_result.dart';
import '../../domain/entities/sheet_mapping.dart';

/// Where the owner's products are coming from.
///
/// The two are genuinely different jobs -- one fills in a workbook we designed,
/// the other hands us a file written for another system -- and asking once, up
/// front, keeps the owner from being shown steps that are not theirs.
enum ExcelImportSource { ownFile, template }

class ExcelImportState extends Equatable {
  final bool picking;
  final bool validating;
  final bool importing;

  /// True while the server is working out what the owner's own file holds.
  final bool readingOwnFile;

  final bool downloadingTemplate;

  final PickedExcelFile? file;
  final ExcelValidationResult? validation;
  final ExcelImportResult? result;

  final bool replace;
  final String replaceScope; // TENANT | FULL

  final String? templateFilePath;

  final String? errorMessage;

  /// Gallery image chosen for each product row: row number to (id, url).
  ///
  /// Held here rather than folded into the preview objects because the previews
  /// are what the server said and these are what the owner decided; keeping them
  /// apart means re-validating the file never silently discards their choices.
  final Map<int, ExcelRowImage> rowImages;

  final ExcelImportSource source;

  /// Every sheet of the owner's file that could hold products, as the server
  /// read it -- and as the owner has since corrected it.
  final List<SheetMapping> sheets;

  /// Which of those sheets is being imported.
  final String? selectedSheetName;

  /// The group products fall under when the file has no category column.
  final String foreignCategoryName;

  /// What to do with products whose code the owner already has.
  final String matchMode;

  /// Whether products are waiting to be described, and how far the
  /// assistant has got with them.
  final DescriptionJob descriptions;

  const ExcelImportState({
    required this.picking,
    required this.validating,
    required this.importing,
    required this.downloadingTemplate,
    required this.file,
    required this.validation,
    required this.result,
    required this.replace,
    required this.replaceScope,
    required this.templateFilePath,
    required this.errorMessage,
    this.rowImages = const {},
    this.readingOwnFile = false,
    this.source = ExcelImportSource.ownFile,
    this.sheets = const [],
    this.selectedSheetName,
    this.foreignCategoryName = '',
    this.matchMode = matchModeUpdate,
    this.descriptions = DescriptionJob.none,
  });

  /// Overwrite the product a repeated code names -- what an owner re-exporting
  /// their catalogue after a price change expects.
  static const String matchModeUpdate = 'ADD_AND_UPDATE';

  /// Leave the product a repeated code names exactly as it is.
  static const String matchModeKeep = 'ADD_ONLY';

  factory ExcelImportState.initial() => const ExcelImportState(
        picking: false,
        validating: false,
        importing: false,
        downloadingTemplate: false,
        file: null,
        validation: null,
        result: null,
        replace: false,
        replaceScope: 'TENANT',
        templateFilePath: null,
        errorMessage: null,
      );

  ExcelImportState copyWith({
    bool? picking,
    bool? validating,
    bool? importing,
    bool? readingOwnFile,
    ExcelImportSource? source,
    List<SheetMapping>? sheets,
    String? selectedSheetName,
    String? foreignCategoryName,
    String? matchMode,
    DescriptionJob? descriptions,
    bool? downloadingTemplate,
    PickedExcelFile? file,
    ExcelValidationResult? validation,
    ExcelImportResult? result,
    bool? replace,
    String? replaceScope,
    String? templateFilePath,
    String? errorMessage,
    Map<int, ExcelRowImage>? rowImages,
    bool clearError = false,
    bool clearValidation = false,
    bool clearResult = false,
    bool clearTemplatePath = false,
    bool clearRowImages = false,
    bool clearSheets = false,
  }) {
    return ExcelImportState(
      picking: picking ?? this.picking,
      validating: validating ?? this.validating,
      importing: importing ?? this.importing,
      readingOwnFile: readingOwnFile ?? this.readingOwnFile,
      downloadingTemplate: downloadingTemplate ?? this.downloadingTemplate,
      file: file ?? this.file,
      validation: clearValidation ? null : (validation ?? this.validation),
      result: clearResult ? null : (result ?? this.result),
      replace: replace ?? this.replace,
      replaceScope: replaceScope ?? this.replaceScope,
      templateFilePath: clearTemplatePath
          ? null
          : (templateFilePath ?? this.templateFilePath),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      rowImages: clearRowImages ? const {} : (rowImages ?? this.rowImages),
      source: source ?? this.source,
      sheets: clearSheets ? const [] : (sheets ?? this.sheets),
      selectedSheetName:
          clearSheets ? null : (selectedSheetName ?? this.selectedSheetName),
      foreignCategoryName: foreignCategoryName ?? this.foreignCategoryName,
      matchMode: matchMode ?? this.matchMode,
      descriptions: descriptions ?? this.descriptions,
    );
  }

  List<ExcelProductPreview> get previews =>
      validation?.productPreviews ?? const [];

  /// How many reviewed products the owner has given a picture to, counting both
  /// their gallery choices and links that were already in the file.
  int get productsWithImage => previews
      .where((p) =>
          rowImages.containsKey(p.row) ||
          (p.imageUrl != null && p.imageUrl!.trim().isNotEmpty))
      .length;

  /// The payload the import call needs: row number to gallery image id.
  Map<int, int> get imageAssignments =>
      rowImages.map((row, image) => MapEntry(row, image.id));

  /// The sheet the owner chose, or the only one there is.
  SheetMapping? get selectedSheet {
    if (sheets.isEmpty) return null;

    for (final sheet in sheets) {
      if (sheet.sheetName == selectedSheetName) return sheet;
    }
    return sheets.first;
  }

  /// Columns the server was unsure about, which is what the owner should look at
  /// before anything is written.
  List<ColumnGuess> get columnsToCheck =>
      selectedSheet?.columns.where((c) => c.needsAttention).toList() ?? const [];

  bool get canReadOwnFile => file != null && !readingOwnFile && !importing;

  bool get canImportOwnFile =>
      file != null &&
      selectedSheet != null &&
      selectedSheet!.hasName &&
      !importing &&
      !readingOwnFile;

  bool get canValidate => file != null && !validating && !importing;
  bool get canImport =>
      file != null &&
      validation != null &&
      validation!.valid &&
      !importing &&
      !validating;

  @override
  List<Object?> get props => [
        picking,
        validating,
        importing,
        downloadingTemplate,
        file?.name,
        validation,
        result,
        replace,
        replaceScope,
        templateFilePath,
        errorMessage,
        rowImages,
        readingOwnFile,
        source,
        sheets,
        selectedSheetName,
        foreignCategoryName,
        matchMode,
        descriptions,
      ];
}

/// A gallery image the owner attached to a row, kept as both parts: the id is
/// what the server needs, the url is what the review list has to draw.
class ExcelRowImage extends Equatable {
  final int id;
  final String url;

  const ExcelRowImage({required this.id, required this.url});

  @override
  List<Object?> get props => [id, url];
}
