import 'package:equatable/equatable.dart';

import '../../domain/entities/excel_import_result.dart';
import '../../domain/entities/picked_excel_file.dart';
import '../../domain/entities/excel_product_preview.dart';
import '../../domain/entities/description_job.dart';
import '../../domain/entities/excel_validation_result.dart';
import '../../domain/entities/foreign_preview.dart';
import '../../domain/entities/photographed_product.dart';
import '../../domain/entities/sheet_mapping.dart';

/// Where the owner's products are coming from.
///
/// Three genuinely different jobs: filling in a workbook we designed, handing us
/// a file written for another system, and photographing a shop that has nothing
/// written down at all. Asking once, up front, keeps each owner from reading
/// past steps that are not theirs.
///
/// In the order the screen offers them, which is the order of what an owner is
/// most likely to already have.
enum ExcelImportSource { template, ownFile, photos }

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

  /// Null until the owner picks one.
  ///
  /// Nothing is preselected: a default would have them reading the steps of a
  /// way in they never chose, and the question at the top is the whole point of
  /// the screen.
  final ExcelImportSource? source;

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

  /// True while the server is working out what the import would create.
  final bool previewing;

  /// What the import would create, as the owner is reviewing it.
  final ForeignPreview preview;

  /// Prices and quantities the owner typed, by row.
  ///
  /// Held apart from the preview because the preview is what the server said and
  /// these are what the owner decided: asking for the preview again never
  /// discards their corrections.
  final Map<int, RowEdit> rowEdits;

  /// Whether the list is narrowed to the products with something missing.
  final bool previewIssuesOnly;

  /// What the owner is searching the list for.
  final String previewQuery;

  /// True while the assistant is describing the products on screen.
  final bool draftingDescriptions;

  /// True while photographs are being stored and read.
  final bool readingPhotos;

  /// The products photographed so far, in the order they were taken.
  final List<PhotographedProduct> photos;

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
    this.source,
    this.sheets = const [],
    this.selectedSheetName,
    this.foreignCategoryName = '',
    this.matchMode = matchModeUpdate,
    this.descriptions = DescriptionJob.none,
    this.previewing = false,
    this.preview = ForeignPreview.empty,
    this.rowEdits = const {},
    this.previewIssuesOnly = false,
    this.previewQuery = '',
    this.draftingDescriptions = false,
    this.readingPhotos = false,
    this.photos = const [],
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
    bool? previewing,
    ForeignPreview? preview,
    Map<int, RowEdit>? rowEdits,
    bool? previewIssuesOnly,
    String? previewQuery,
    bool? draftingDescriptions,
    bool? readingPhotos,
    List<PhotographedProduct>? photos,
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
    bool clearPreview = false,
    bool clearPhotos = false,
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
      previewing: previewing ?? this.previewing,
      preview: clearPreview
          ? ForeignPreview.empty
          : (preview ?? this.preview),
      rowEdits: clearPreview ? const {} : (rowEdits ?? this.rowEdits),
      previewIssuesOnly: previewIssuesOnly ?? this.previewIssuesOnly,
      previewQuery: previewQuery ?? this.previewQuery,
      draftingDescriptions: draftingDescriptions ?? this.draftingDescriptions,
      readingPhotos: readingPhotos ?? this.readingPhotos,
      photos: clearPhotos ? const [] : (photos ?? this.photos),
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

  bool get canReadOwnFile => file != null && !readingOwnFile && !importing;

  /// Photographed products still waiting to be named. Nothing can be created
  /// with a blank name, so this is what stands between the owner and the button.
  List<PhotographedProduct> get photosNeedingName =>
      photos.where((photo) => photo.needsName).toList();

  bool get canImportPhotos =>
      photos.isNotEmpty &&
      photosNeedingName.isEmpty &&
      !importing &&
      !readingPhotos;

  /// The photographed products in the shape the create call sends them.
  List<Map<String, Object?>> get photoDraftPayload {
    return [
      for (final photo in photos)
        if (!photo.needsName)
          {
            'name': photo.name.trim(),
            'category': photo.category,
            'mediaId': photo.mediaId,
            if (priceForPhoto(photo).trim().isNotEmpty)
              'price': priceForPhoto(photo).trim(),
            if (stockForPhoto(photo).trim().isNotEmpty)
              'stock': stockForPhoto(photo).trim(),
            if (descriptionForPhoto(photo).trim().isNotEmpty)
              'description': descriptionForPhoto(photo).trim(),
          },
    ];
  }

  /// Photographed products carry their edits under their own position, the same
  /// way a spreadsheet's rows carry theirs under a row number.
  String priceForPhoto(PhotographedProduct photo) =>
      rowEdits[photo.photoIndex]?.price ?? '';

  String stockForPhoto(PhotographedProduct photo) =>
      rowEdits[photo.photoIndex]?.stock ?? '';

  String descriptionForPhoto(PhotographedProduct photo) =>
      rowEdits[photo.photoIndex]?.description ?? '';

  bool get canPreviewOwnFile =>
      file != null &&
      selectedSheet != null &&
      selectedSheet!.hasName &&
      !previewing &&
      !importing;

  /// Only once the owner has seen what they are about to create.
  bool get canImportOwnFile =>
      file != null &&
      selectedSheet != null &&
      selectedSheet!.hasName &&
      !preview.isEmpty &&
      !importing &&
      !previewing &&
      !readingOwnFile;

  /// The products the review list should show, after the filter and the search.
  List<ExcelProductPreview> get visiblePreviewProducts {
    final query = previewQuery.trim().toLowerCase();

    return preview.products.where((product) {
      if (previewIssuesOnly && product.valid) return false;
      if (query.isEmpty) return true;

      return product.name.toLowerCase().contains(query) ||
          (product.sku ?? '').toLowerCase().contains(query);
    }).toList();
  }

  /// The price for a row as it stands: what the owner typed, else what the file
  /// said.
  String priceFor(ExcelProductPreview product) {
    final edited = rowEdits[product.row]?.price;
    if (edited != null) return edited;

    return product.price == null ? '' : _plain(product.price!);
  }

  String stockFor(ExcelProductPreview product) {
    final edited = rowEdits[product.row]?.stock;
    if (edited != null) return edited;

    return product.stock == null ? '' : product.stock.toString();
  }

  String descriptionFor(ExcelProductPreview product) {
    final edited = rowEdits[product.row]?.description;
    if (edited != null) return edited;

    return product.description ?? '';
  }

  /// The products on screen that still have nothing said about them -- what the
  /// assistant would be asked to write.
  List<ExcelProductPreview> get visibleWithoutDescription => visiblePreviewProducts
      .where((product) => descriptionFor(product).trim().isEmpty)
      .toList();

  /// The corrections in the shape the import call sends them.
  Map<int, Map<String, Object>> get rowEditPayload {
    final payload = <int, Map<String, Object>>{};

    rowEdits.forEach((row, edit) {
      final fields = <String, Object>{};
      if (edit.price != null && edit.price!.trim().isNotEmpty) {
        fields['price'] = edit.price!.trim();
      }
      if (edit.stock != null && edit.stock!.trim().isNotEmpty) {
        fields['stock'] = edit.stock!.trim();
      }
      if (edit.description != null && edit.description!.trim().isNotEmpty) {
        fields['description'] = edit.description!.trim();
      }
      if (fields.isNotEmpty) payload[row] = fields;
    });

    return payload;
  }

  /// Trailing zeros off a whole price, so a field the owner has not touched
  /// reads "25" rather than "25.0".
  static String _plain(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();

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
        previewing,
        preview,
        rowEdits,
        previewIssuesOnly,
        previewQuery,
        draftingDescriptions,
        readingPhotos,
        photos,
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

/// What the owner typed for one row of the review list.
///
/// Text rather than numbers: a field the owner is halfway through typing is not
/// a number yet, and turning "25." into 25 while their cursor is still in it is
/// how a price field fights back.
class RowEdit extends Equatable {
  final String? price;
  final String? stock;

  /// What the product says about itself: typed by the owner, or written by the
  /// assistant and left in place by them. Theirs either way by the time it is
  /// sent.
  final String? description;

  const RowEdit({this.price, this.stock, this.description});

  RowEdit copyWith({String? price, String? stock, String? description}) => RowEdit(
        price: price ?? this.price,
        stock: stock ?? this.stock,
        description: description ?? this.description,
      );

  @override
  List<Object?> get props => [price, stock, description];
}
