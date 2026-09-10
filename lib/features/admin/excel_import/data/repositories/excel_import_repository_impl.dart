import '../../domain/entities/picked_excel_file.dart';

import '../../domain/entities/excel_import_result.dart';
import '../../domain/entities/excel_validation_result.dart';
import '../../domain/entities/description_job.dart';
import '../../domain/entities/excel_product_preview.dart';
import '../../domain/entities/foreign_preview.dart';
import '../../domain/entities/sheet_mapping.dart';
import '../../domain/repositories/excel_import_repository.dart';
import '../models/excel_import_result_model.dart';
import '../models/excel_validation_result_model.dart';
import '../models/description_job_model.dart';
import '../models/foreign_preview_model.dart';
import '../models/sheet_mapping_model.dart';
import '../services/excel_import_api_service.dart';

class ExcelImportRepositoryImpl implements ExcelImportRepository {
  final ExcelImportApiService api;

  ExcelImportRepositoryImpl({required this.api});

  @override
  Future<ExcelValidationResult> validate(PickedExcelFile file) async {
    final raw = await api.validateExcel(file);

    // The validate endpoint can fail BEFORE the file is ever parsed
    // (auth, subscription limit, owner-project not resolved, server/network
    // error). Those responses carry no counts, so building a result here would
    // silently show "0 everywhere" with no reason. Surface the server message
    // as an error instead so the user knows what actually happened.
    final status = raw['statusCode'] as int?;
    final httpOk = status == null || (status >= 200 && status < 300);
    final success = raw['success'] == true;
    if (!httpOk || !success) {
      final errs = raw['errors'];
      final firstErr = (errs is List && errs.isNotEmpty) ? errs.first.toString() : null;
      final msg = [
        raw['message']?.toString(),
        firstErr,
      ].firstWhere(
        (s) => s != null && s.trim().isNotEmpty,
        orElse: () => 'Validation failed. Please try again.',
      );
      throw Exception(msg);
    }

    final m = ExcelValidationResultModel.fromJson(raw);

    return ExcelValidationResult(
      valid: m.valid,
      errors: m.errors,
      warnings: m.warnings,
      categories: m.categories,
      itemTypes: m.itemTypes,
      products: m.products,
      taxRules: m.taxRules,
      shippingMethods: m.shippingMethods,
      coupons: m.coupons,
      productPreviews: m.productPreviews,
    );
  }

  @override
  Future<ExcelImportResult> importFile({
    required PickedExcelFile file,
    required bool replace,
    required String replaceScope,
    Map<int, int> imageAssignments = const {},
  }) async {
    final raw = await api.importExcel(
      file: file,
      replace: replace,
      replaceScope: replaceScope,
      imageAssignments: imageAssignments,
    );

    final m = ExcelImportResultModel.fromJson(raw);

    if (!m.success) {
      final statusCode = raw['statusCode'] as int?;
      if (statusCode == 409) {
        throw Exception(
          "Your data is currently in use (linked to orders or carts) and can't be replaced.",
        );
      }
      throw Exception(
        m.message.isNotEmpty ? m.message : 'Import failed. Please try again.',
      );
    }

    return ExcelImportResult(
      success: m.success,
      message: m.message,
      projectId: m.projectId,
      slug: m.slug,
      insertedCategories: m.insertedCategories,
      insertedItemTypes: m.insertedItemTypes,
      insertedProducts: m.insertedProducts,
      updatedProducts: m.updatedProducts,
      skippedProducts: m.skippedProducts,
      insertedTaxRules: m.insertedTaxRules,
      insertedShippingMethods: m.insertedShippingMethods,
      insertedCoupons: m.insertedCoupons,
      errors: m.errors,
      warnings: m.warnings,
    );
  }

  @override
  Future<List<SheetMapping>> suggestMapping(PickedExcelFile file) async {
    final raw = await api.suggestMapping(file);
    _throwIfFailed(raw, 'We could not read that file. Please try another one.');

    return SheetMappingModel.listFromJson(raw['sheets']);
  }

  @override
  Future<ForeignPreview> previewForeignFile({
    required PickedExcelFile file,
    required String sheetName,
    required Map<int, String> columns,
    String? categoryName,
  }) async {
    final raw = await api.previewForeign(
      file: file,
      sheetName: sheetName,
      columns: columns,
      categoryName: categoryName,
    );
    _throwIfFailed(raw, 'We could not read the products from that file.');

    return ForeignPreviewModel.fromJson(raw);
  }

  @override
  Future<ExcelImportResult> importForeignFile({
    required PickedExcelFile file,
    required String sheetName,
    required Map<int, String> columns,
    String? categoryName,
    required String matchMode,
    Map<int, Map<String, Object>> rowEdits = const {},
    Map<int, int> imageAssignments = const {},
  }) async {
    final raw = await api.importForeign(
      file: file,
      sheetName: sheetName,
      columns: columns,
      categoryName: categoryName,
      matchMode: matchMode,
      rowEdits: rowEdits,
      imageAssignments: imageAssignments,
    );

    final m = ExcelImportResultModel.fromJson(raw);
    if (!m.success) {
      throw Exception(
        m.message.isNotEmpty ? m.message : 'Import failed. Please try again.',
      );
    }

    return ExcelImportResult(
      success: m.success,
      message: m.message,
      projectId: m.projectId,
      slug: m.slug,
      insertedCategories: m.insertedCategories,
      insertedItemTypes: m.insertedItemTypes,
      insertedProducts: m.insertedProducts,
      updatedProducts: m.updatedProducts,
      skippedProducts: m.skippedProducts,
      insertedTaxRules: m.insertedTaxRules,
      insertedShippingMethods: m.insertedShippingMethods,
      insertedCoupons: m.insertedCoupons,
      errors: m.errors,
      warnings: m.warnings,
    );
  }

  @override
  Future<DescriptionJob> descriptionsStatus() async {
    final raw = await api.descriptionsStatus();

    // A failure here should not break the import screen: the offer simply is
    // not made, which is what "none" says.
    if (raw['success'] != true) return DescriptionJob.none;

    return DescriptionJobModel.fromJson(raw);
  }

  @override
  Future<Map<int, String>> draftDescriptions(List<ExcelProductPreview> rows) async {
    final raw = await api.draftDescriptions([
      for (final row in rows)
        {'row': row.row, 'name': row.name, 'category': row.categoryName},
    ]);
    _throwIfFailed(raw, 'The assistant could not write those descriptions.');

    final descriptions = raw['descriptions'];
    if (descriptions is! Map) return const {};

    final byRow = <int, String>{};
    descriptions.forEach((row, text) {
      final number = int.tryParse(row.toString());
      final description = text?.toString().trim() ?? '';
      if (number != null && description.isNotEmpty) byRow[number] = description;
    });

    return byRow;
  }

  @override
  Future<DescriptionJob> startDescriptions(DescriptionJob current) async {
    final raw = await api.startDescriptions();
    _throwIfFailed(raw, 'Could not start writing the descriptions.');

    return DescriptionJobModel.fromStartJson(raw, current);
  }

  @override
  Future<List<int>?> downloadTemplate() => api.downloadTemplate();

  /// Turns a failed call into the server's own message.
  ///
  /// A request can fail before the file is ever opened -- auth, plan limits, an
  /// unreachable server -- and those responses carry no content. Reading them as
  /// an empty answer would show the owner a file with no columns and no reason.
  void _throwIfFailed(Map<String, dynamic> raw, String fallback) {
    final status = raw['statusCode'] as int?;
    final httpOk = status == null || (status >= 200 && status < 300);
    if (httpOk && raw['success'] == true) return;

    final errors = raw['errors'];
    final firstError =
        (errors is List && errors.isNotEmpty) ? errors.first.toString() : null;

    final message = [raw['message']?.toString(), firstError].firstWhere(
      (s) => s != null && s.trim().isNotEmpty,
      orElse: () => fallback,
    );

    throw Exception(message);
  }
}
