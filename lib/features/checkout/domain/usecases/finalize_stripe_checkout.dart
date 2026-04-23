import 'package:build4front/features/checkout/data/models/checkout_summary_model.dart';
import 'package:build4front/features/checkout/domain/entities/checkout_entities.dart';
import 'package:build4front/features/checkout/domain/repositories/checkout_repository.dart';

/// Step 2 of the Stripe prepare-then-finalize flow. After the Stripe
/// sheet returns "paid", this creates the Order and empties the cart.
class FinalizeStripeCheckout {
  final CheckoutRepository repo;
  FinalizeStripeCheckout(this.repo);

  Future<CheckoutSummaryModel> call({
    required String paymentIntentId,
    required int ownerProjectId,
    required int currencyId,
    required String paymentMethod,
    String? couponCode,
    required int shippingMethodId,
    required String shippingMethodName,
    required ShippingAddress shippingAddress,
    required List<CartLine> lines,
    String? destinationAccountId,
  }) {
    return repo.finalizeStripeCheckout(
      paymentIntentId: paymentIntentId,
      ownerProjectId: ownerProjectId,
      currencyId: currencyId,
      paymentMethod: paymentMethod,
      couponCode: couponCode,
      shippingMethodId: shippingMethodId,
      shippingMethodName: shippingMethodName,
      shippingAddress: shippingAddress,
      lines: lines,
      destinationAccountId: destinationAccountId,
    );
  }
}
