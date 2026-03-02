import '../../domain/entities/payment_method_config_item.dart';

class OwnerPaymentConfigState {
  final bool loading;
  final String? error;
  final List<PaymentMethodConfigItem> items;
  final Set<String> savingCodes;

  const OwnerPaymentConfigState({
    required this.loading,
    required this.items,
    required this.savingCodes,
    this.error,
  });

  factory OwnerPaymentConfigState.initial() => const OwnerPaymentConfigState(
        loading: false,
        items: [],
        savingCodes: {},
        error: null,
      );

  OwnerPaymentConfigState copyWith({
    bool? loading,
    String? error,
    List<PaymentMethodConfigItem>? items,
    Set<String>? savingCodes,
  }) {
    return OwnerPaymentConfigState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
      savingCodes: savingCodes ?? this.savingCodes,
    );
  }
}