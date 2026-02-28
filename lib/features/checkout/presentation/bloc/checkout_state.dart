// lib/features/checkout/presentation/bloc/checkout_state.dart

import 'package:build4front/features/checkout/data/models/checkout_summary_model.dart';
import 'package:build4front/features/checkout/domain/entities/checkout_entities.dart';

class CheckoutState {
  final bool loading;
  final bool placing;

  // ✅ NEW: quoting state
  final bool quoting;
  final CheckoutSummaryModel? quote;

  final CheckoutCart? cart;
  final ShippingAddress address;

  final List<ShippingQuote> shippingQuotes;
  final int? selectedShippingMethodId;
  final ShippingQuote? selectedQuote;

  final TaxPreview? tax;

  final List<PaymentMethod> paymentMethods;
  final int? selectedPaymentIndex;

  final String coupon;
  final String? error;

  final int? orderId;
  final CheckoutSummaryModel? orderSummary;

  const CheckoutState({
    required this.loading,
    required this.placing,
    required this.quoting,
    required this.quote,
    required this.cart,
    required this.address,
    required this.shippingQuotes,
    required this.selectedShippingMethodId,
    required this.selectedQuote,
    required this.tax,
    required this.paymentMethods,
    required this.selectedPaymentIndex,
    required this.coupon,
    required this.error,
    required this.orderId,
    required this.orderSummary,
  });

  factory CheckoutState.initial() {
    return const CheckoutState(
      loading: false,
      placing: false,
      quoting: false,
      quote: null,
      cart: null,
      address: ShippingAddress(),
      shippingQuotes: [],
      selectedShippingMethodId: null,
      selectedQuote: null,
      tax: null,
      paymentMethods: [],
      selectedPaymentIndex: null,
      coupon: '',
      error: null,
      orderId: null,
      orderSummary: null,
    );
  }

  CheckoutState copyWith({
    bool? loading,
    bool? placing,

    bool? quoting,
    CheckoutSummaryModel? quote,
    bool clearQuote = false,

    CheckoutCart? cart,
    ShippingAddress? address,

    List<ShippingQuote>? shippingQuotes,

    int? selectedShippingMethodId,
    ShippingQuote? selectedQuote,
    bool clearSelectedShipping = false,

    TaxPreview? tax,
    bool clearTax = false,

    List<PaymentMethod>? paymentMethods,
    int? selectedPaymentIndex,

    String? coupon,

    String? error,
    bool clearError = false,

    int? orderId,
    bool clearOrderId = false,

    CheckoutSummaryModel? orderSummary,
    bool clearOrderSummary = false,
  }) {
    return CheckoutState(
      loading: loading ?? this.loading,
      placing: placing ?? this.placing,

      quoting: quoting ?? this.quoting,
      quote: clearQuote ? null : (quote ?? this.quote),

      cart: cart ?? this.cart,
      address: address ?? this.address,

      shippingQuotes: shippingQuotes ?? this.shippingQuotes,

      selectedShippingMethodId: clearSelectedShipping
          ? null
          : (selectedShippingMethodId ?? this.selectedShippingMethodId),

      selectedQuote: clearSelectedShipping ? null : (selectedQuote ?? this.selectedQuote),

      tax: clearTax ? null : (tax ?? this.tax),

      paymentMethods: paymentMethods ?? this.paymentMethods,
      selectedPaymentIndex: selectedPaymentIndex ?? this.selectedPaymentIndex,

      coupon: coupon ?? this.coupon,

      error: clearError ? null : (error ?? this.error),

      orderId: clearOrderId ? null : (orderId ?? this.orderId),
      orderSummary: clearOrderSummary ? null : (orderSummary ?? this.orderSummary),
    );
  }
}