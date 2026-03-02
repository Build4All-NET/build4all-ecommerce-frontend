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