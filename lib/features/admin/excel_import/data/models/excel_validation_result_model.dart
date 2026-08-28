import '../../domain/entities/excel_product_preview.dart';

class ExcelValidationResultModel {
  final bool valid;
  final List<String> errors;
  final List<String> warnings;

  final int categories;
  final int itemTypes;
  final int products;
  final int taxRules;
  final int shippingMethods;
  final int coupons;

  final List<ExcelProductPreview> productPreviews;

  ExcelValidationResultModel({
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

  factory ExcelValidationResultModel.fromJson(Map<String, dynamic> json) {
    List<String> list(String k) {
      final v = json[k];
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    int count(String k) => (json[k] is num) ? (json[k] as num).toInt() : 0;

    return ExcelValidationResultModel(
      valid: json['valid'] == true,
      errors: list('errors'),
      warnings: list('warnings'),
      categories: count('categories'),
      itemTypes: count('itemTypes'),
      products: count('products'),
      taxRules: count('taxRules'),
      shippingMethods: count('shippingMethods'),
      coupons: count('coupons'),
      productPreviews: _previews(json['productPreviews']),
    );
  }

  static List<ExcelProductPreview> _previews(dynamic raw) {
    if (raw is! List) return const [];

    final out = <ExcelProductPreview>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final m = entry.cast<String, dynamic>();

      final name = m['name']?.toString().trim() ?? '';
      // A row with no name was never a product; the server skipped it too.
      if (name.isEmpty) continue;

      out.add(ExcelProductPreview(
        row: _int(m['row']) ?? 0,
        name: name,
        sku: _text(m['sku']),
        price: _double(m['price']),
        stock: _int(m['stock']),
        categoryName: _text(m['categoryName']),
        itemTypeName: _text(m['itemTypeName']),
        imageUrl: _text(m['imageUrl']),
        virtualProduct: m['virtualProduct'] == true,
        valid: m['valid'] != false,
        issues: _strings(m['issues']),
        notes: _strings(m['notes']),
      ));
    }
    return out;
  }

  static List<String> _strings(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }

  static String? _text(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _double(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
