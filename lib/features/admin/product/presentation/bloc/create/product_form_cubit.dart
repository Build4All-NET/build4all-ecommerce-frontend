import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/features/admin/product/domain/entities/product.dart';
import 'package:build4front/features/admin/product/domain/usecases/create_product.dart';
import 'product_form_state.dart';

class ProductFormCubit extends Cubit<ProductFormState> {
  final CreateProduct createProduct;

  ProductFormCubit({required this.createProduct})
    : super(ProductFormState.initial());

  Future<void> submit({
   
    required int itemTypeId,
    required int? currencyId,

    required String name,
    String? description,
    required double price,
    int? stock,

    String? imageUrl,
    String? sku,

    // ✅ New fields
    String productType = 'SIMPLE', // SIMPLE / VARIABLE / GROUPED / EXTERNAL
    bool virtualProduct = false,
    bool downloadable = false,
    String? downloadUrl,

    String? externalUrl,
    String? buttonText,

    double? salePrice,
    DateTime? saleStart,
    DateTime? saleEnd,

    /// attributes as code -> value
    Map<String, String>? attributes,
  }) async {
    // Reset old success + error
    emit(
      state.copyWith(
        isSubmitting: true,
        clearCreatedProduct: true,
        clearError: true,
      ),
    );

    try {
      final Product p = await createProduct(
        
        itemTypeId: itemTypeId,
        currencyId: currencyId,

        name: name,
        description: description,
        price: price,
        stock: stock,

        imageUrl: imageUrl,
        sku: sku,

        productType: productType,
        virtualProduct: virtualProduct,
        downloadable: downloadable,
        downloadUrl: downloadUrl,
        externalUrl: externalUrl,
        buttonText: buttonText,

        salePrice: salePrice,
        saleStart: saleStart,
        saleEnd: saleEnd,

        attributes: attributes,
      );

      emit(
        state.copyWith(
          isSubmitting: false,
          createdProduct: p,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          clearCreatedProduct: true,
          error: e.toString(),
        ),
      );
    }
  }

  void reset() {
    emit(ProductFormState.initial());
  }
}
