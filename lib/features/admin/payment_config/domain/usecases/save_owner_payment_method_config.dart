import '../repositories/owner_payment_config_repository.dart';

class SaveOwnerPaymentMethodConfig {
  final OwnerPaymentConfigRepository repo;
  SaveOwnerPaymentMethodConfig(this.repo);

  Future<void> call({
    required String methodName,
    required bool enabled,
    required Map<String, Object?> configValues,
  }) {
    return repo.saveMethodConfig(
      methodName: methodName,
      enabled: enabled,
      configValues: configValues,
    );
  }
}