import 'package:equatable/equatable.dart';

import '../../domain/entities/excel_import_result.dart';
import '../../domain/entities/picked_excel_file.dart';
import '../../domain/entities/excel_product_preview.dart';
import '../../domain/entities/excel_validation_result.dart';

class ExcelImportState extends Equatable {
  final bool picking;
  final bool validating;
  final bool importing;

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
  });

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
  }) {
    return ExcelImportState(
      picking: picking ?? this.picking,
      validating: validating ?? this.validating,
      importing: importing ?? this.importing,
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
