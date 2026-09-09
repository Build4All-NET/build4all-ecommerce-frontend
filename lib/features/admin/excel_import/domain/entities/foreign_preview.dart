import 'package:equatable/equatable.dart';

import 'excel_product_preview.dart';

/// What the import would create, as the server read it, before it creates any
/// of it.
class ForeignPreview extends Equatable {
  final List<ExcelProductPreview> products;

  /// Rows carrying no name. They cannot become products, and there is nothing
  /// in them to show beyond the fact that they exist.
  final int skippedRows;

  const ForeignPreview({required this.products, required this.skippedRows});

  static const ForeignPreview empty =
      ForeignPreview(products: [], skippedRows: 0);

  bool get isEmpty => products.isEmpty;

  /// Products with something missing -- the ones the owner is here to fix.
  List<ExcelProductPreview> get needingAttention =>
      products.where((p) => !p.valid).toList();

  @override
  List<Object?> get props => [products, skippedRows];
}
