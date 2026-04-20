import 'package:build4front/features/admin/licensing/domain/entities/available_payment_method.dart';
import 'package:build4front/features/admin/licensing/domain/repositories/i_licensing_repository.dart';

class GetAvailablePaymentMethods {
  final ILicensingRepository repo;
  GetAvailablePaymentMethods(this.repo);

  Future<List<AvailablePaymentMethod>> call() =>
      repo.getAvailablePaymentMethods();
}
