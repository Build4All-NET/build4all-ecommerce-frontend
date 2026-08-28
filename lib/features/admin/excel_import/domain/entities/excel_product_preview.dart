/// One product row as the server read it, ready to be shown back to the owner.
///
/// A count of "42 products" tells an owner nothing about whether their file is
/// right. Handing back the rows themselves — with each row's own problems
/// attached — is what lets them check the import before it happens, and it is
/// where they attach a picture, which the file itself cannot carry.
class ExcelProductPreview {
  /// Row number in the sheet, matching what Excel shows in its margin.
  final int row;

  final String name;
  final String? sku;
  final double? price;
  final int? stock;
  final String? categoryName;
  final String? itemTypeName;

  /// An image address written in the file.
  ///
  /// The template no longer offers this column — pictures come from the gallery
  /// — but a workbook filled in against the old one still carries it.
  final String? imageUrl;

  /// True when this row is a digital product the buyer downloads.
  final bool downloadable;

  /// True when this row needs no shipping.
  final bool virtualProduct;

  final bool valid;
  final List<String> issues;
  final List<String> notes;

  const ExcelProductPreview({
    required this.row,
    required this.name,
    this.sku,
    this.price,
    this.stock,
    this.categoryName,
    this.itemTypeName,
    this.imageUrl,
    this.downloadable = false,
    this.virtualProduct = false,
    this.valid = true,
    this.issues = const [],
    this.notes = const [],
  });
}
