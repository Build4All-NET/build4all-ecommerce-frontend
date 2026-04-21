import '../repositories/owner_payment_config_repository.dart';

class TestOwnerPaymentMethodConfig {
  final OwnerPaymentConfigRepository repo;
  TestOwnerPaymentMethodConfig(this.repo);

  Future<({bool ok, String? error})> call({
    required String methodName,
    required Map<String, Object?> configValues,
  }) {
    return repo.testMethodConfig(
      methodName: methodName,
      configValues: configValues,
    );
  }
}
