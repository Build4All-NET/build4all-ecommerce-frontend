import 'package:build4front/features/admin/licensing/domain/entities/upgrade_request.dart';
import 'package:build4front/features/admin/licensing/domain/repositories/i_licensing_repository.dart';

class ListUpgradeRequests {
  final ILicensingRepository repo;
  ListUpgradeRequests(this.repo);

  Future<List<UpgradeRequest>> call() => repo.listUpgradeRequests();
}
