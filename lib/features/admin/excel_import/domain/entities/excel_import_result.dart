class ExcelImportResult {
  final bool success;
  final String message;

  final int projectId;

  final String slug;

  final int insertedCategories;
  final int insertedItemTypes;
  final int insertedProducts;

  /// Rows that matched a code the owner already had and overwrote that product.
  final int updatedProducts;

  /// Rows left alone because the owner asked not to touch what they already had.
  final int skippedProducts;
  final int insertedTaxRules;
  final int insertedShippingMethods;
  final int insertedCoupons;

  final List<String> errors;
  final List<String> warnings;

  const ExcelImportResult({
    required this.success,
    required this.message,
    required this.projectId,
   
    required this.slug,
    required this.insertedCategories,
    required this.insertedItemTypes,
    required this.insertedProducts,
    this.updatedProducts = 0,
    this.skippedProducts = 0,
    required this.insertedTaxRules,
    required this.insertedShippingMethods,
    required this.insertedCoupons,
    required this.errors,
    required this.warnings,
  });
}
