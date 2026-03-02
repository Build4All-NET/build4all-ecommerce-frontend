import '../entities/payment_method_config_item.dart';

abstract class OwnerPaymentConfigRepository {
  Future<List<PaymentMethodConfigItem>> listMethods();

  Future<void> saveMethodConfig({
    required String methodName,
    required bool enabled,
    required Map<String, Object?> configValues,
  });
}