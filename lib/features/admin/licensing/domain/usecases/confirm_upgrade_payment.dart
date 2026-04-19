import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/domain/repositories/i_licensing_repository.dart';

class ConfirmUpgradePayment {
  final ILicensingRepository repo;
  ConfirmUpgradePayment(this.repo);

  Future<OwnerAppAccessResponse> call({required String paymentIntentId}) {
    return repo.confirmUpgradePayment(paymentIntentId: paymentIntentId);
  }
}
