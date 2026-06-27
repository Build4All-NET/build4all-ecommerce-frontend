import 'dart:io';

import '../../domain/entities/excel_import_result.dart';
import '../../domain/entities/excel_validation_result.dart';
import '../../domain/repositories/excel_import_repository.dart';
import '../models/excel_import_result_model.dart';
import '../models/excel_validation_result_model.dart';
import '../services/excel_import_api_service.dart';

class ExcelImportRepositoryImpl implements ExcelImportRepository {
  final ExcelImportApiService api;

  ExcelImportRepositoryImpl({required this.api});

  @override
  Future<ExcelValidationResult> validate(File file) async {
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
    );
  }

  @override
  Future<ExcelImportResult> importFile({
    required File file,
    required bool replace,
    required String replaceScope,
  }) async {
    final raw = await api.importExcel(
      file: file,
      replace: replace,
      replaceScope: replaceScope,
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
      insertedTaxRules: m.insertedTaxRules,
      insertedShippingMethods: m.insertedShippingMethods,
      insertedCoupons: m.insertedCoupons,
      errors: m.errors,
      warnings: m.warnings,
    );
  }
}
