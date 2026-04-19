import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/domain/repositories/i_licensing_repository.dart';

class GetCurrentLicensePlan {
  final ILicensingRepository repo;
  GetCurrentLicensePlan(this.repo);

  Future<OwnerAppAccessResponse> call() => repo.getCurrentLicensePlan();
}
