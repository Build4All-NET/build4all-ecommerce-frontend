import 'excel_product_preview.dart';

class ExcelValidationResult {
  final bool valid;
  final List<String> errors;
  final List<String> warnings;

  final int categories;
  final int itemTypes;
  final int products;
  final int taxRules;
  final int shippingMethods;
  final int coupons;

  /// The product rows themselves, in file order, so the owner can review what is
  /// about to be created and give each one a picture.
  final List<ExcelProductPreview> productPreviews;

  const ExcelValidationResult({
    required this.valid,
    required this.errors,
    required this.warnings,
    required this.categories,
    required this.itemTypes,
    required this.products,
    required this.taxRules,
    required this.shippingMethods,
    required this.coupons,
    this.productPreviews = const [],
  });
}
