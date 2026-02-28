// lib/features/checkout/domain/usecases/quote_from_cart.dart

import 'package:build4front/features/checkout/data/models/checkout_summary_model.dart';
import '../entities/checkout_entities.dart';
import '../repositories/checkout_repository.dart';

class QuoteFromCart {
  final CheckoutRepository repo;
  QuoteFromCart(this.repo);

  Future<CheckoutSummaryModel> call({
    required int currencyId,
    String? couponCode,
    required int? shippingMethodId,
    required String shippingMethodName,
    required ShippingAddress shippingAddress,
  }) {
    return repo.quoteFromCart(
      currencyId: currencyId,
      couponCode: couponCode,
      shippingMethodId: shippingMethodId,
      shippingMethodName: shippingMethodName,
      shippingAddress: shippingAddress,
    );
  }
}