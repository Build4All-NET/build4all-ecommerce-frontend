import 'package:build4front/features/admin/licensing/domain/entities/upgrade_plan.dart';
import 'package:build4front/features/admin/licensing/domain/repositories/i_licensing_repository.dart';

class GetAvailableUpgradePlans {
  final ILicensingRepository repo;
  GetAvailableUpgradePlans(this.repo);

  Future<List<UpgradePlan>> call() => repo.getAvailableUpgradePlans();
}
