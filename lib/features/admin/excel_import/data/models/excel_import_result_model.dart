class ExcelImportResultModel {
  final bool success;
  final String message;

  final int projectId;
  
  final String slug;

  final int insertedCategories;
  final int insertedItemTypes;
  final int insertedProducts;
  final int insertedTaxRules;
  final int insertedShippingMethods;
  final int insertedCoupons;

  final List<String> errors;
  final List<String> warnings;

  ExcelImportResultModel({
    required this.success,
    required this.message,
    required this.projectId,
   
    required this.slug,
    required this.insertedCategories,
    required this.insertedItemTypes,
    required this.insertedProducts,
    required this.insertedTaxRules,
    required this.insertedShippingMethods,
    required this.insertedCoupons,
    required this.errors,
    required this.warnings,
  });

  factory ExcelImportResultModel.fromJson(Map<String, dynamic> json) {
    List<String> _list(String k) {
      final v = json[k];
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    int _i(String k) => (json[k] is num) ? (json[k] as num).toInt() : 0;

    return ExcelImportResultModel(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      projectId: _i('projectId'),
     
      slug: (json['slug'] ?? '').toString(),
      insertedCategories: _i('insertedCategories'),
      insertedItemTypes: _i('insertedItemTypes'),
      insertedProducts: _i('insertedProducts'),
      insertedTaxRules: _i('insertedTaxRules'),
      insertedShippingMethods: _i('insertedShippingMethods'),
      insertedCoupons: _i('insertedCoupons'),
      errors: _list('errors'),
      warnings: _list('warnings'),
    );
  }
}
