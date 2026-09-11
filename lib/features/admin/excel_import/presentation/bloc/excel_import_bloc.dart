import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/exceptions/exception_mapper.dart';
import '../../data/services/template_saver.dart';
import '../../domain/entities/photographed_product.dart';
import '../../domain/entities/picked_excel_file.dart';
import '../../domain/entities/picked_photo.dart';
import '../../domain/usecases/download_excel_template.dart';
import '../../domain/usecases/draft_descriptions.dart';
import '../../domain/usecases/draft_photo_descriptions.dart';
import '../../domain/usecases/get_descriptions_status.dart';
import '../../domain/usecases/import_draft_products.dart';
import '../../domain/usecases/import_foreign_file.dart';
import '../../domain/usecases/read_product_photos.dart';
import '../../domain/usecases/preview_foreign_file.dart';
import '../../domain/usecases/write_missing_descriptions.dart';
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
  final PreviewForeignFile? previewForeignUc;
  final DraftDescriptions? draftDescriptionsUc;
  final DraftPhotoDescriptions? draftPhotoDescriptionsUc;
  final ReadProductPhotos? readPhotosUc;
  final ImportDraftProducts? importDraftsUc;
  final GetDescriptionsStatus? descriptionsStatusUc;
  final WriteMissingDescriptions? writeDescriptionsUc;

  ExcelImportBloc({
    required this.validateUc,
    required this.importUc,
    this.downloadTemplateUc,
    this.suggestMappingUc,
    this.importForeignUc,
    this.previewForeignUc,
    this.draftDescriptionsUc,
    this.draftPhotoDescriptionsUc,
    this.readPhotosUc,
    this.importDraftsUc,
    this.descriptionsStatusUc,
    this.writeDescriptionsUc,
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
    on<ExcelPreviewForeignPressed>(_previewForeign);
    on<ExcelRowPriceChanged>(_changeRowPrice);
    on<ExcelRowStockChanged>(_changeRowStock);
    on<ExcelPreviewFilterChanged>(_changePreviewFilter);
    on<ExcelPreviewSearchChanged>(_changePreviewSearch);
    on<ExcelRowDescriptionChanged>(_changeRowDescription);
    on<ExcelDraftDescriptionsPressed>(_draftDescriptions);
    on<ExcelPhotosCaptured>(_capturePhotos);
    on<ExcelPhotoNameChanged>(_changePhotoName);
    on<ExcelPhotoRemoved>(_removePhoto);
    on<ExcelPhotosImportPressed>(_importPhotos);
    on<ExcelPhotoDraftDescriptionsPressed>(_draftPhotoDescriptions);
    on<ExcelDescriptionsChecked>(_checkDescriptions);
    on<ExcelWriteDescriptionsPressed>(_writeDescriptions);
  }

  /// How often the assistant's progress is read back.
  ///
  /// Slow enough not to hammer the server over a job that takes minutes,
  /// often enough that the owner sees the count move.
  static const Duration _descriptionPollInterval = Duration(seconds: 5);

  /// How long to keep watching before leaving it to the owner to refresh.
  ///
  /// A job that outlives this is still running on the server; only this
  /// screen stops following it.
  static const Duration _descriptionPollLimit = Duration(minutes: 20);

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
      clearPreview: true,
      clearPhotos: true,
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

    // The preview was built from the old reading, so it no longer describes what
    // an import would create. The owner asks for it again.
    emit(state.copyWith(
      sheets: [
        for (final sheet in state.sheets)
          if (sheet.sheetName == selected.sheetName) corrected else sheet,
      ],
      clearPreview: true,
    ));
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
        rowEdits: state.rowEditPayload,
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

  Future<void> _checkDescriptions(
    ExcelDescriptionsChecked event,
    Emitter<ExcelImportState> emit,
  ) async {
    if (descriptionsStatusUc == null) return;

    try {
      emit(state.copyWith(descriptions: await descriptionsStatusUc!()));
    } catch (_) {
      // Not being able to offer this is not worth an error over the import the
      // owner just completed successfully.
    }
  }

  Future<void> _writeDescriptions(
    ExcelWriteDescriptionsPressed event,
    Emitter<ExcelImportState> emit,
  ) async {
    if (writeDescriptionsUc == null || state.descriptions.running) return;

    try {
      emit(state.copyWith(
        descriptions: await writeDescriptionsUc!(state.descriptions),
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: ExceptionMapper.toMessage(e)));
      return;
    }

    await _followDescriptions(emit);
  }

  /// Reads the assistant's progress back until it finishes.
  ///
  /// The work runs on the server and does not need this screen; watching it only
  /// means the owner can see the count move instead of guessing.
  Future<void> _followDescriptions(Emitter<ExcelImportState> emit) async {
    if (descriptionsStatusUc == null) return;

    final startedAt = DateTime.now();

    while (state.descriptions.running && !isClosed && !emit.isDone) {
      if (DateTime.now().difference(startedAt) > _descriptionPollLimit) return;

      await Future<void>.delayed(_descriptionPollInterval);
      if (isClosed || emit.isDone) return;

      try {
        emit(state.copyWith(descriptions: await descriptionsStatusUc!()));
      } catch (_) {
        // One unanswered poll is not a reason to stop watching a job that is
        // still running perfectly well on the server.
      }
    }
  }

  Future<void> _previewForeign(
    ExcelPreviewForeignPressed event,
    Emitter<ExcelImportState> emit,
  ) async {
    if (!state.canPreviewOwnFile || previewForeignUc == null) return;

    final sheet = state.selectedSheet!;

    emit(state.copyWith(previewing: true, clearError: true, clearResult: true));

    try {
      final preview = await previewForeignUc!(
        file: state.file!,
        sheetName: sheet.sheetName,
        columns: sheet.wireColumns,
        categoryName: state.foreignCategoryName,
      );

      emit(state.copyWith(previewing: false, preview: preview));
    } catch (e) {
      emit(state.copyWith(
        previewing: false,
        errorMessage: ExceptionMapper.toMessage(e),
      ));
    }
  }

  void _changeRowPrice(
    ExcelRowPriceChanged event,
    Emitter<ExcelImportState> emit,
  ) {
    emit(state.copyWith(rowEdits: {
      ...state.rowEdits,
      event.row: (state.rowEdits[event.row] ?? const RowEdit())
          .copyWith(price: event.price),
    }));
  }

  void _changeRowStock(
    ExcelRowStockChanged event,
    Emitter<ExcelImportState> emit,
  ) {
    emit(state.copyWith(rowEdits: {
      ...state.rowEdits,
      event.row: (state.rowEdits[event.row] ?? const RowEdit())
          .copyWith(stock: event.stock),
    }));
  }

  void _changePreviewFilter(
    ExcelPreviewFilterChanged event,
    Emitter<ExcelImportState> emit,
  ) {
    emit(state.copyWith(previewIssuesOnly: event.issuesOnly));
  }

  void _changePreviewSearch(
    ExcelPreviewSearchChanged event,
    Emitter<ExcelImportState> emit,
  ) {
    emit(state.copyWith(previewQuery: event.query));
  }

  void _changeRowDescription(
    ExcelRowDescriptionChanged event,
    Emitter<ExcelImportState> emit,
  ) {
    emit(state.copyWith(rowEdits: {
      ...state.rowEdits,
      event.row: (state.rowEdits[event.row] ?? const RowEdit())
          .copyWith(description: event.description),
    }));
  }

  Future<void> _draftDescriptions(
    ExcelDraftDescriptionsPressed event,
    Emitter<ExcelImportState> emit,
  ) async {
    if (draftDescriptionsUc == null || state.draftingDescriptions) return;

    // Only the ones with nothing said about them. A description the owner wrote,
    // or their old system did, is not ours to replace.
    final rows = state.visibleWithoutDescription;
    if (rows.isEmpty) return;

    emit(state.copyWith(draftingDescriptions: true, clearError: true));

    try {
      final written = await draftDescriptionsUc!(rows);

      final edits = Map<int, RowEdit>.from(state.rowEdits);
      written.forEach((row, description) {
        edits[row] = (edits[row] ?? const RowEdit()).copyWith(description: description);
      });

      emit(state.copyWith(draftingDescriptions: false, rowEdits: edits));
    } catch (e) {
      emit(state.copyWith(
        draftingDescriptions: false,
        errorMessage: ExceptionMapper.toMessage(e),
      ));
    }
  }

  /// How much a photograph is scaled down before it is sent.
  ///
  /// Big enough for the assistant to tell a bag from a wallet, small enough that
  /// a dozen of them go up over a shop's connection rather than timing out on it.
  static const double _photoMaxWidth = 1280;
  static const int _photoQuality = 80;

  Future<void> _capturePhotos(
    ExcelPhotosCaptured event,
    Emitter<ExcelImportState> emit,
  ) async {
    if (readPhotosUc == null || state.readingPhotos) return;

    final picker = ImagePicker();

    try {
      final taken = <XFile>[];

      if (event.fromCamera) {
        // One shot per press: the camera hands back a single picture, and an
        // owner walking a shelf presses again rather than choosing a count first.
        final shot = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: _photoMaxWidth,
          imageQuality: _photoQuality,
        );
        if (shot != null) taken.add(shot);
      } else {
        taken.addAll(await picker.pickMultiImage(
          maxWidth: _photoMaxWidth,
          imageQuality: _photoQuality,
        ));
      }

      if (taken.isEmpty) return;

      final photos = <PickedPhoto>[];
      for (final shot in taken) {
        photos.add(PickedPhoto(name: shot.name, bytes: await shot.readAsBytes()));
      }

      emit(state.copyWith(readingPhotos: true, clearError: true, clearResult: true));

      final read = await readPhotosUc!(photos);

      // Appended, not replaced: an owner photographs a shelf at a time and the
      // batch before it is still theirs.
      final existing = state.photos;
      emit(state.copyWith(
        readingPhotos: false,
        photos: [
          ...existing,
          for (final product in read)
            PhotographedProduct(
              // Renumbered onto the end of what they already have, so a
              // correction lands on the product they are looking at.
              photoIndex: existing.length + product.photoIndex,
              mediaId: product.mediaId,
              imageUrl: product.imageUrl,
              name: product.name,
              category: product.category,
            ),
        ],
      ));
    } catch (e) {
      emit(state.copyWith(
        readingPhotos: false,
        errorMessage: ExceptionMapper.toMessage(e),
      ));
    }
  }

  void _changePhotoName(
    ExcelPhotoNameChanged event,
    Emitter<ExcelImportState> emit,
  ) {
    emit(state.copyWith(photos: [
      for (final photo in state.photos)
        if (photo.photoIndex == event.photoIndex)
          PhotographedProduct(
            photoIndex: photo.photoIndex,
            mediaId: photo.mediaId,
            imageUrl: photo.imageUrl,
            name: event.name,
            category: photo.category,
          )
        else
          photo,
    ]));
  }

  void _removePhoto(
    ExcelPhotoRemoved event,
    Emitter<ExcelImportState> emit,
  ) {
    final kept = state.photos
        .where((photo) => photo.photoIndex != event.photoIndex)
        .toList();

    // The removed product's price and description go with it, or they would land
    // on whichever photograph takes its place.
    final edits = Map<int, RowEdit>.from(state.rowEdits)..remove(event.photoIndex);

    emit(state.copyWith(photos: kept, rowEdits: edits));
  }

  Future<void> _importPhotos(
    ExcelPhotosImportPressed event,
    Emitter<ExcelImportState> emit,
  ) async {
    if (!state.canImportPhotos || importDraftsUc == null) return;

    emit(state.copyWith(importing: true, clearError: true));

    try {
      final result = await importDraftsUc!(
        products: state.photoDraftPayload,
        matchMode: state.matchMode,
      );

      emit(state.copyWith(importing: false, result: result, clearPhotos: true));
    } catch (e) {
      emit(state.copyWith(
        importing: false,
        errorMessage: ExceptionMapper.toMessage(e),
      ));
    }
  }

  Future<void> _draftPhotoDescriptions(
    ExcelPhotoDraftDescriptionsPressed event,
    Emitter<ExcelImportState> emit,
  ) async {
    if (draftPhotoDescriptionsUc == null || state.draftingDescriptions) return;

    // Only the ones with a name and nothing said about them: one with no name
    // is not a product yet, and one the owner already described is not ours to
    // replace.
    final photos = state.photosWithoutDescription;
    if (photos.isEmpty) return;

    emit(state.copyWith(draftingDescriptions: true, clearError: true));

    try {
      final written = await draftPhotoDescriptionsUc!(photos);

      final edits = Map<int, RowEdit>.from(state.rowEdits);
      written.forEach((photoIndex, description) {
        edits[photoIndex] =
            (edits[photoIndex] ?? const RowEdit()).copyWith(description: description);
      });

      emit(state.copyWith(draftingDescriptions: false, rowEdits: edits));
    } catch (e) {
      emit(state.copyWith(
        draftingDescriptions: false,
        errorMessage: ExceptionMapper.toMessage(e),
      ));
    }
  }
}
