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

  /// An image address written in the file, if the owner used that column.
  final String? imageUrl;

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
    this.valid = true,
    this.issues = const [],
    this.notes = const [],
  });
}
