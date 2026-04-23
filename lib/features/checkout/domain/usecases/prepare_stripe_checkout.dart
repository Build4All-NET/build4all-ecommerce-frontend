import 'package:build4front/features/checkout/data/models/checkout_summary_model.dart';
import 'package:build4front/features/checkout/domain/entities/checkout_entities.dart';
import 'package:build4front/features/checkout/domain/repositories/checkout_repository.dart';

/// Step 1 of the Stripe prepare-then-finalize flow. Creates a Stripe
/// PaymentIntent on the backend; does NOT create an order or touch the
/// cart. Returns clientSecret + publishableKey for the Stripe sheet.
class PrepareStripeCheckout {
  final CheckoutRepository repo;
  PrepareStripeCheckout(this.repo);

  Future<CheckoutSummaryModel> call({
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
    return repo.prepareStripePayment(
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
