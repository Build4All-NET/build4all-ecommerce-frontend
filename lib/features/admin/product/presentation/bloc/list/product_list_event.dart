import 'package:equatable/equatable.dart';

abstract class ProductListEvent extends Equatable {
  const ProductListEvent();
  @override
  List<Object?> get props => [];
}

class LoadProductsForOwner extends ProductListEvent {
 
  final int? itemTypeId;
  final int? categoryId;

  const LoadProductsForOwner(
  {
    this.itemTypeId,
    this.categoryId,
  });

  @override
  List<Object?> get props => [ itemTypeId, categoryId];
}
