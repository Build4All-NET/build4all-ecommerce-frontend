class PaymentMethodConfigItem {
  final String name; // STRIPE, CASH...
  final bool platformEnabled;
  final bool projectEnabled;
  final Map<String, dynamic> configSchema; // {title, fields: [...]}
  final Map<String, dynamic> configValues; // saved values (may include secrets)

  const PaymentMethodConfigItem({
    required this.name,
    required this.platformEnabled,
    required this.projectEnabled,
    required this.configSchema,
    required this.configValues,
  });

  PaymentMethodConfigItem copyWith({
    bool? projectEnabled,
    Map<String, dynamic>? configValues,
    Map<String, dynamic>? configSchema,
  }) {
    return PaymentMethodConfigItem(
      name: name,
      platformEnabled: platformEnabled,
      projectEnabled: projectEnabled ?? this.projectEnabled,
      configSchema: configSchema ?? this.configSchema,
      configValues: configValues ?? this.configValues,
    );
  }
}