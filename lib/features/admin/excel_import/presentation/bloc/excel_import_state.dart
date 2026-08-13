import 'package:equatable/equatable.dart';

import '../../domain/entities/excel_import_result.dart';
import '../../domain/entities/picked_excel_file.dart';
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
    bool clearError = false,
    bool clearValidation = false,
    bool clearResult = false,
    bool clearTemplatePath = false,
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
    );
  }

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
      ];
}
