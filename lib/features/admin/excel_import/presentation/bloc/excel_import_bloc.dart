import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/exceptions/exception_mapper.dart';
import '../../data/services/template_saver.dart';
import '../../domain/entities/picked_excel_file.dart';
import '../../domain/usecases/download_excel_template.dart';
import '../../domain/usecases/import_foreign_file.dart';
import '../../domain/usecases/suggest_column_mapping.dart';
import '../../domain/usecases/import_excel_file.dart';
import '../../domain/usecases/validate_excel_file.dart';
import 'excel_import_event.dart';
import 'excel_import_state.dart';

class ExcelImportBloc extends Bloc<ExcelImportEvent, ExcelImportState> {
  final ValidateExcelFile validateUc;
  final ImportExcelFile importUc;
  final DownloadExcelTemplate? downloadTemplateUc;
  final SuggestColumnMapping? suggestMappingUc;
  final ImportForeignFile? importForeignUc;

  ExcelImportBloc({
    required this.validateUc,
    required this.importUc,
    this.downloadTemplateUc,
    this.suggestMappingUc,
    this.importForeignUc,
  }) : super(ExcelImportState.initial()) {
    on<ExcelPickFilePressed>(_pickFile);
    on<ExcelValidatePressed>(_validate);
    on<ExcelImportPressed>(_import);
    on<ExcelReplaceToggled>(_toggleReplace);
    on<ExcelReplaceScopeChanged>(_changeScope);
    on<ExcelDownloadTemplatePressed>(_downloadTemplate);
    on<ExcelProductImageAssigned>(_assignImage);
    on<ExcelProductImageCleared>(_clearImage);
    on<ExcelSourceChanged>(_changeSource);
    on<ExcelReadOwnFilePressed>(_readOwnFile);
    on<ExcelSheetSelected>(_selectSheet);
    on<ExcelColumnFieldChanged>(_changeColumnField);
    on<ExcelForeignCategoryChanged>(_changeForeignCategory);
    on<ExcelMatchModeChanged>(_changeMatchMode);
    on<ExcelForeignImportPressed>(_importForeign);
  }

  Future<void> _pickFile(
    ExcelPickFilePressed event,
    Emitter<ExcelImportState> emit,
  ) async {
    emit(state.copyWith(picking: true, clearError: true));

    try {
      // withData so the bytes come back on every platform. The browser never
      // exposes a path for a picked file, and reading one there throws.
      // CSV as well as xlsx: a till or accounting package exports whichever
      // its own author picked, and refusing one of them at the file picker is a
      // dead end the owner cannot work around.
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'csv'],
        withData: true,
      );

      final picked = (res == null || res.files.isEmpty) ? null : res.files.first;
      final bytes = picked?.bytes;

      if (picked == null || bytes == null) {
        emit(state.copyWith(picking: false));
        return;
      }

      emit(state.copyWith(
        picking: false,
        file: PickedExcelFile(name: picked.name, bytes: bytes),
        clearValidation: true,
        clearResult: true,
        // Row numbers and column guesses only mean something against the file
        // they came from.
        clearRowImages: true,
        clearSheets: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        picking: false,
        errorMessage: ExceptionMapper.toMessage(e),
      ));
    }
  }

  Future<void> _validate(
    ExcelValidatePressed event,
    Emitter<ExcelImportState> emit,
  ) async {
    if (state.file == null) return;

    emit(state.copyWith(
      validating: true,
      clearError: true,
      clearResult: true,
    ));

    try {
      final vr = await validateUc(state.file!);
      emit(state.copyWith(validating: false, validation: vr));
    } catch (e) {
      emit(state.copyWith(
        validating: false,
        errorMessage: ExceptionMapper.toMessage(e),
      ));
    }
  }

  Future<void> _import(
    ExcelImportPressed event,
    Emitter<ExcelImportState> emit,
  ) async {
    if (!state.canImport) return;

    emit(state.copyWith(importing: true, clearError: true));

    try {
      final r = await importUc(
        file: state.file!,
        replace: state.replace,
        replaceScope: state.replaceScope,
        imageAssignments: state.imageAssignments,
      );
      emit(state.copyWith(importing: false, result: r));
    } catch (e) {
      emit(state.copyWith(
        importing: false,
        errorMessage: ExceptionMapper.toMessage(e),
      ));
    }
  }

  void _toggleReplace(
    ExcelReplaceToggled event,
    Emitter<ExcelImportState> emit,
  ) {
    emit(state.copyWith(replace: event.value));
  }

  void _changeScope(
    ExcelReplaceScopeChanged event,
    Emitter<ExcelImportState> emit,
  ) {
    emit(state.copyWith(replaceScope: event.scope));
  }

  Future<void> _downloadTemplate(
    ExcelDownloadTemplatePressed event,
    Emitter<ExcelImportState> emit,
  ) async {
    emit(state.copyWith(
      downloadingTemplate: true,
      clearError: true,
      clearTemplatePath: true,
    ));

    try {
      // The server's copy is generated from the same columns the importer reads,
      // so it is preferred; the bundled asset is only there for an owner who is
      // offline or on a backend that predates the endpoint.
      final fromServer = await downloadTemplateUc?.call();

      final bytes = fromServer != null
          ? Uint8List.fromList(fromServer)
          : (await rootBundle.load('assets/templates/Template.xlsx'))
              .buffer
              .asUint8List();

      // Null on web: the browser downloads the file itself and gives back no
      // path, so there is nothing to show or reopen there.
      final savedPath = await saveTemplate(bytes, 'Build4All_Template.xlsx');

      emit(state.copyWith(
        downloadingTemplate: false,
        templateFilePath: savedPath,
      ));
    } catch (e) {
      emit(state.copyWith(
        downloadingTemplate: false,
        errorMessage: ExceptionMapper.toMessage(e),
      ));
    }
  }

  void _assignImage(
    ExcelProductImageAssigned event,
    Emitter<ExcelImportState> emit,
  ) {
    emit(state.copyWith(rowImages: {
      ...state.rowImages,
      event.row: ExcelRowImage(id: event.imageId, url: event.imageUrl),
    }));
  }

  void _clearImage(
    ExcelProductImageCleared event,
    Emitter<ExcelImportState> emit,
  ) {
    final next = Map<int, ExcelRowImage>.from(state.rowImages)..remove(event.row);
    emit(state.copyWith(rowImages: next));
  }

  void _changeSource(
    ExcelSourceChanged event,
    Emitter<ExcelImportState> emit,
  ) {
    if (event.source == state.source) return;

    // Everything read so far belongs to the other way of working; keeping it
    // would leave the owner looking at a review of a file they are no longer
    // importing.
    emit(state.copyWith(
      source: event.source,
      clearSheets: true,
      clearValidation: true,
      clearResult: true,
      clearError: true,
    ));
  }

  Future<void> _readOwnFile(
    ExcelReadOwnFilePressed event,
    Emitter<ExcelImportState> emit,
  ) async {
    if (!state.canReadOwnFile || suggestMappingUc == null) return;

    emit(state.copyWith(
      readingOwnFile: true,
      clearError: true,
      clearResult: true,
      clearSheets: true,
    ));

    try {
      final sheets = await suggestMappingUc!(state.file!);

      emit(state.copyWith(
        readingOwnFile: false,
        sheets: sheets,
        selectedSheetName: sheets.isEmpty ? null : sheets.first.sheetName,
        // The sheet's own name is the likeliest group for its products: in a
        // file kept by hand the tab is usually already the category.
        foreignCategoryName: sheets.isEmpty ? '' : sheets.first.sheetName,
      ));
    } catch (e) {
      emit(state.copyWith(
        readingOwnFile: false,
        errorMessage: ExceptionMapper.toMessage(e),
      ));
    }
  }

  void _selectSheet(
    ExcelSheetSelected event,
    Emitter<ExcelImportState> emit,
  ) {
    emit(state.copyWith(
      selectedSheetName: event.sheetName,
      foreignCategoryName: event.sheetName,
    ));
  }

  void _changeColumnField(
    ExcelColumnFieldChanged event,
    Emitter<ExcelImportState> emit,
  ) {
    final selected = state.selectedSheet;
    if (selected == null) return;

    final corrected = selected.copyWithColumn(event.columnIndex, event.field);

    emit(state.copyWith(sheets: [
      for (final sheet in state.sheets)
        if (sheet.sheetName == selected.sheetName) corrected else sheet,
    ]));
  }

  void _changeForeignCategory(
    ExcelForeignCategoryChanged event,
    Emitter<ExcelImportState> emit,
  ) {
    emit(state.copyWith(foreignCategoryName: event.categoryName));
  }

  void _changeMatchMode(
    ExcelMatchModeChanged event,
    Emitter<ExcelImportState> emit,
  ) {
    emit(state.copyWith(matchMode: event.matchMode));
  }

  Future<void> _importForeign(
    ExcelForeignImportPressed event,
    Emitter<ExcelImportState> emit,
  ) async {
    if (!state.canImportOwnFile || importForeignUc == null) return;

    final sheet = state.selectedSheet!;

    emit(state.copyWith(importing: true, clearError: true));

    try {
      final result = await importForeignUc!(
        file: state.file!,
        sheetName: sheet.sheetName,
        columns: sheet.wireColumns,
        categoryName: state.foreignCategoryName,
        matchMode: state.matchMode,
        imageAssignments: state.imageAssignments,
      );

      emit(state.copyWith(importing: false, result: result));
    } catch (e) {
      emit(state.copyWith(
        importing: false,
        errorMessage: ExceptionMapper.toMessage(e),
      ));
    }
  }
}
