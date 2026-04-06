import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/get_products.dart';
import 'product_list_event.dart';
import 'product_list_state.dart';

class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  final GetProducts getProducts;

  ProductListBloc({required this.getProducts})
      : super(ProductListState.initial()) {
    on<LoadProductsForOwner>(_onLoadProducts);
  }

  Future<void> _onLoadProducts(
    LoadProductsForOwner event,
    Emitter<ProductListState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final products = await getProducts(
        ownerProjectId: event.ownerProjectId,
        itemTypeId: event.itemTypeId,
        categoryId: event.categoryId,
      );

      emit(state.copyWith(
        isLoading: false,
        products: products,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: ExceptionMapper.toMessage(e),
      ));
    }
  }
}