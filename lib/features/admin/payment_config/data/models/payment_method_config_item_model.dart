import '../../domain/entities/payment_method_config_item.dart';

class PaymentMethodConfigItemModel extends PaymentMethodConfigItem {
  const PaymentMethodConfigItemModel({
    required super.name,
    required super.platformEnabled,
    required super.projectEnabled,
    required super.configSchema,
    required super.configValues,
  });

  factory PaymentMethodConfigItemModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodConfigItemModel(
      name: (json['name'] ?? '').toString(),
      platformEnabled: (json['platformEnabled'] == true),
      projectEnabled: (json['projectEnabled'] == true),
      configSchema: (json['configSchema'] is Map<String, dynamic>)
          ? (json['configSchema'] as Map<String, dynamic>)
          : <String, dynamic>{},
      configValues: (json['configValues'] is Map<String, dynamic>)
          ? (json['configValues'] as Map<String, dynamic>)
          : <String, dynamic>{},
    );
  }
}