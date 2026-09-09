/// What one column of an owner's own file was read as.
///
/// Mirrors the fields the server accepts. Kept as an enum with an explicit wire
/// name rather than raw strings so a rename here cannot quietly stop matching
/// what the backend understands.
enum ProductField {
  name('NAME'),
  sku('SKU'),
  price('PRICE'),
  stock('STOCK'),
  description('DESCRIPTION'),
  category('CATEGORY'),
  imageUrl('IMAGE_URL'),
  ignore('IGNORE');

  final String wireName;

  const ProductField(this.wireName);

  /// The field the server named, falling back to ignoring the column.
  ///
  /// A field this app does not know is a backend that has moved ahead of it;
  /// leaving that column out is safer than failing the whole read.
  static ProductField fromWire(String? value) {
    if (value == null) return ProductField.ignore;

    final normalized = value.trim().toUpperCase();
    for (final field in ProductField.values) {
      if (field.wireName == normalized) return field;
    }
    return ProductField.ignore;
  }

  /// The fields an owner can choose between, in the order they matter to them.
  static const List<ProductField> choices = [
    ProductField.name,
    ProductField.price,
    ProductField.stock,
    ProductField.sku,
    ProductField.category,
    ProductField.description,
    ProductField.imageUrl,
    ProductField.ignore,
  ];
}
