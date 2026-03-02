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
