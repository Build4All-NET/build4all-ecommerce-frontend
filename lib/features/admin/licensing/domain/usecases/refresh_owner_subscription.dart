import 'package:build4front/features/admin/licensing/domain/entities/owner_app_access.dart';
import 'package:build4front/features/admin/licensing/domain/repositories/i_licensing_repository.dart';

class RefreshOwnerSubscription {
  final ILicensingRepository repo;
  RefreshOwnerSubscription(this.repo);

  Future<OwnerAppAccess> call() => repo.refreshOwnerSubscription();
}
