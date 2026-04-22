import 'package:build4front/features/checkout/domain/repositories/checkout_repository.dart';

/// Fires the synchronous "client payment succeeded → verify with provider →
/// flip ledger to PAID" round-trip for a just-placed order. Used by the
/// checkout bloc immediately after the Stripe PaymentSheet reports success
/// (and similarly for PayPal once that UI lands).
class ConfirmPayment {
  final CheckoutRepository repo;
  ConfirmPayment(this.repo);

  Future<void> call({required int orderId}) {
    return repo.confirmPayment(orderId: orderId);
  }
}
