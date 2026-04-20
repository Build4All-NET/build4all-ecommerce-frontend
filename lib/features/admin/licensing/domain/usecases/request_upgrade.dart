import 'package:build4front/features/admin/licensing/domain/entities/billing_cycle.dart';
import 'package:build4front/features/admin/licensing/domain/entities/plan_code.dart';
import 'package:build4front/features/admin/licensing/domain/repositories/i_licensing_repository.dart';

class RequestUpgradeParams {
  final PlanCode planCode;
  final BillingCycle billingCycle;
  final int? usersAllowedOverride;

  const RequestUpgradeParams({
    required this.planCode,
    required this.billingCycle,
    this.usersAllowedOverride,
  });
}

class RequestUpgrade {
  final ILicensingRepository repo;
  RequestUpgrade(this.repo);

  Future<void> call(RequestUpgradeParams p) {
    return repo.requestUpgrade(
      planCode: p.planCode,
      billingCycle: p.billingCycle,
      usersAllowedOverride: p.usersAllowedOverride,
    );
  }
}
