import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/domain/repositories/i_licensing_repository.dart';

class RefreshOwnerSubscription {
  final ILicensingRepository repo;
  RefreshOwnerSubscription(this.repo);

  Future<OwnerAppAccessResponse> call() => repo.refreshOwnerSubscription();
}
