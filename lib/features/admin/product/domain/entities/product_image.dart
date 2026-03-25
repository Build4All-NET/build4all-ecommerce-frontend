class ProductImage {
  final int? id;
  final String imageUrl;
  final int sortOrder;
  final bool isMain;

  const ProductImage({
    this.id,
    required this.imageUrl,
    required this.sortOrder,
    required this.isMain,
  });
}