import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProducts {
  final ProductRepository repo;
  GetProducts(this.repo);

  Future<List<Product>> call({
   
    int? itemTypeId,
    int? categoryId,
  }) {
    return repo.getProducts(
     
      itemTypeId: itemTypeId,
      categoryId: categoryId,
    );
  }
}
