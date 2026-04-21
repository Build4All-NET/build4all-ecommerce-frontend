abstract class OwnerPaymentConfigEvent {}

class OwnerPaymentConfigLoad extends OwnerPaymentConfigEvent {
  OwnerPaymentConfigLoad();
}

class OwnerPaymentConfigSave extends OwnerPaymentConfigEvent {
  final String methodName;
  final bool enabled;
  final Map<String, Object?> configValues;

  OwnerPaymentConfigSave({
    required this.methodName,
    required this.enabled,
    required this.configValues,
  });
}

class OwnerPaymentConfigTest extends OwnerPaymentConfigEvent {
  final String methodName;
  final Map<String, Object?> configValues;

  OwnerPaymentConfigTest({
    required this.methodName,
    required this.configValues,
  });
}

class OwnerPaymentConfigTestResultCleared extends OwnerPaymentConfigEvent {
  final String methodName;
  OwnerPaymentConfigTestResultCleared(this.methodName);
}