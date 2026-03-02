import '../entities/payment_method_config_item.dart';
import '../repositories/owner_payment_config_repository.dart';

class GetOwnerPaymentMethods {
  final OwnerPaymentConfigRepository repo;
  GetOwnerPaymentMethods(this.repo);

  Future<List<PaymentMethodConfigItem>> call() {
    return repo.listMethods();
  }
}