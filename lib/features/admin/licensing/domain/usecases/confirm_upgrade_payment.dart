import 'package:build4front/features/admin/licensing/domain/entities/upgrade_payment_confirmation.dart';
import 'package:build4front/features/admin/licensing/domain/repositories/i_licensing_repository.dart';

class ConfirmUpgradePayment {
  final ILicensingRepository repo;
  ConfirmUpgradePayment(this.repo);

  Future<UpgradePaymentConfirmation> call({
    required String paymentIntentId,
  }) {
    return repo.confirmUpgradePayment(paymentIntentId: paymentIntentId);
  }
}
