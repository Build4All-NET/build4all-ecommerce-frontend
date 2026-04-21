import '../../domain/entities/payment_method_config_item.dart';

class TestOutcome {
  final bool ok;
  final String? error;
  const TestOutcome({required this.ok, this.error});
}

class OwnerPaymentConfigState {
  final bool loading;
  final String? error;
  final List<PaymentMethodConfigItem> items;
  final Set<String> savingCodes;
  final Set<String> testingCodes;
  final Map<String, TestOutcome> testResults;

  const OwnerPaymentConfigState({
    required this.loading,
    required this.items,
    required this.savingCodes,
    required this.testingCodes,
    required this.testResults,
    this.error,
  });

  factory OwnerPaymentConfigState.initial() => const OwnerPaymentConfigState(
        loading: false,
        items: [],
        savingCodes: {},
        testingCodes: {},
        testResults: {},
        error: null,
      );

  OwnerPaymentConfigState copyWith({
    bool? loading,
    String? error,
    List<PaymentMethodConfigItem>? items,
    Set<String>? savingCodes,
    Set<String>? testingCodes,
    Map<String, TestOutcome>? testResults,
  }) {
    return OwnerPaymentConfigState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
      savingCodes: savingCodes ?? this.savingCodes,
      testingCodes: testingCodes ?? this.testingCodes,
      testResults: testResults ?? this.testResults,
    );
  }
}