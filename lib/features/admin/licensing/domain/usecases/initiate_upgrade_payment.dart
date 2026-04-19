import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/domain/entities/billing_cycle.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_payment_intent.dart';
import 'package:build4front/features/admin/licensing/domain/repositories/i_licensing_repository.dart';

class InitiateUpgradePaymentParams {
  final PlanCode planCode;
  final BillingCycle billingCycle;
  final int? usersAllowedOverride;

  const InitiateUpgradePaymentParams({
    required this.planCode,
    required this.billingCycle,
    this.usersAllowedOverride,
  });
}

class InitiateUpgradePayment {
  final ILicensingRepository repo;
  InitiateUpgradePayment(this.repo);

  Future<UpgradePaymentIntent> call(InitiateUpgradePaymentParams p) {
    return repo.initiateUpgradePayment(
      planCode: p.planCode,
      billingCycle: p.billingCycle,
      usersAllowedOverride: p.usersAllowedOverride,
    );
  }
}
