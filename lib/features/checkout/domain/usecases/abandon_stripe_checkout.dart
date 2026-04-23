import 'package:build4front/features/checkout/domain/entities/checkout_entities.dart';
import 'package:build4front/features/checkout/domain/repositories/checkout_repository.dart';

/// Cancels a prepared-but-unpaid Stripe PaymentIntent when the user
/// closes the Stripe sheet without paying. Best-effort — failures are
/// swallowed by the repository impl.
class AbandonStripeCheckout {
  final CheckoutRepository repo;
  AbandonStripeCheckout(this.repo);

  Future<void> call({
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
    return repo.abandonStripeCheckout(
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
