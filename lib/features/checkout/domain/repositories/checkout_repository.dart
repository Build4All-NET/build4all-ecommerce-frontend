// lib/features/checkout/domain/repositories/checkout_repository.dart

import 'package:build4front/features/checkout/data/models/checkout_summary_model.dart';
import '../entities/checkout_entities.dart';

abstract class CheckoutRepository {
  Future<CheckoutCart> getMyCart();
  Future<List<PaymentMethod>> getEnabledPaymentMethods();

  Future<List<ShippingQuote>> getShippingQuotes({
    required int ownerProjectId,
    required ShippingAddress address,
    required List<CartLine> lines,
  });

  Future<TaxPreview> previewTax({
    required int ownerProjectId,
    required ShippingAddress address,
    required List<CartLine> lines,
    required double shippingTotal,
  });

  /// ✅ NEW: quote totals using backend pricing engine (no order created)
  Future<CheckoutSummaryModel> quoteFromCart({
    required int currencyId,
    String? couponCode,
    required int? shippingMethodId,
    required String shippingMethodName,
    required ShippingAddress shippingAddress,
  });

  Future<CheckoutSummaryModel> checkout({
    required int ownerProjectId,
    required int currencyId,
    required String paymentMethod,
    String? stripePaymentId,
    String? couponCode,
    required int shippingMethodId,
    required String shippingMethodName,
    required ShippingAddress shippingAddress,
    required List<CartLine> lines,
    String? destinationAccountId,
  });

  /// Tells the backend the mobile SDK has completed the provider payment
  /// (Stripe PaymentSheet success / PayPal approval). The server verifies
  /// with the provider and flips the local ledger row to PAID.
  ///
  /// No webhook involved. Fires per-order.
  Future<void> confirmPayment({required int orderId});

  Future<ShippingAddress> getMyLastShippingAddress();
}