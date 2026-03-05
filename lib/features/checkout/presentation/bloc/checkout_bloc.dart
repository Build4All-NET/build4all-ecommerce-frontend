// lib/features/checkout/presentation/bloc/checkout_bloc.dart

import 'dart:async';

import 'package:build4front/features/checkout/domain/errors/checkout_blocked_failure.dart';
import 'package:build4front/features/checkout/domain/usecases/get_last_shipping_address.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentMethod;

import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/payments/stripe_payment_sheet.dart';

import 'package:build4front/features/checkout/data/models/checkout_summary_model.dart';
import 'package:build4front/features/checkout/domain/entities/checkout_entities.dart';
import 'package:build4front/features/checkout/domain/usecases/get_checkout_cart.dart';
import 'package:build4front/features/checkout/domain/usecases/get_payment_methods.dart';
import 'package:build4front/features/checkout/domain/usecases/get_shipping_quotes.dart';
import 'package:build4front/features/checkout/domain/usecases/place_order.dart';
import 'package:build4front/features/checkout/domain/usecases/preview_tax.dart';
import 'package:build4front/features/checkout/domain/usecases/quote_from_cart.dart';

import 'checkout_event.dart';
import 'checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final GetCheckoutCart getCart;
  final GetPaymentMethods getPaymentMethods;
  final GetShippingQuotes getShippingQuotes;
  final GetLastShippingAddress getLastShippingAddress;
  final PreviewTax previewTax;
  final PlaceOrder placeOrder;

  // ✅ quote endpoint (includes coupon discount, grandTotal, etc.)
  final QuoteFromCart quoteFromCart;

  final int ownerProjectId;
  final int? currencyId;

  Timer? _quoteDebounce;
  String? _lastQuoteSig;

  CheckoutBloc({
    required this.getCart,
    required this.getPaymentMethods,
    required this.getShippingQuotes,
    required this.previewTax,
    required this.placeOrder,
    required this.ownerProjectId,
    required this.currencyId,
    required this.getLastShippingAddress,
    required this.quoteFromCart,
  }) : super(CheckoutState.initial()) {
    on<CheckoutStarted>(_onStarted);
    on<CheckoutAddressChanged>(_onAddressChanged);
    on<CheckoutShippingSelected>(_onShippingSelected);

    // ✅ NEW: coupon draft vs apply
    on<CheckoutCouponDraftChanged>(_onCouponDraftChanged);
    on<CheckoutCouponApplied>(_onCouponApplied);

    on<CheckoutPaymentSelected>(_onPaymentSelected);
    on<CheckoutRefreshRequested>(_onRefresh);
    on<CheckoutPlaceOrderPressed>(_onPlaceOrder);
  }

  @override
  Future<void> close() {
    _quoteDebounce?.cancel();
    return super.close();
  }

  int _resolvedCurrencyId() => (currencyId ?? int.tryParse(Env.currencyId) ?? 1);

  List<CartLine> _linesFromCart(CheckoutCart cart) {
    return cart.items
        .where((x) => x.itemId != 0 && x.quantity > 0)
        .map((x) => CartLine(
              itemId: x.itemId,
              quantity: x.quantity,
              unitPrice: 0.0, // server ignores
            ))
        .toList();
  }

  bool _addressReadyForQuotes(ShippingAddress a) {
    return a.countryId != null &&
        a.regionId != null &&
        (a.city ?? '').trim().isNotEmpty &&
        (a.addressLine ?? '').trim().isNotEmpty;
  }

  String? _stripeAccountIdFromPaymentMethod(PaymentMethod pm) {
    final cfg = pm.configMap;
    if (cfg == null) return null;

    final raw = cfg['stripeAccountId'] ??
        cfg['stripe_account_id'] ??
        cfg['accountId'] ??
        cfg['connectedAccountId'] ??
        cfg['destinationAccountId'];

    final s = (raw ?? '').toString().trim();
    return s.isEmpty ? null : s;
  }

  String _quoteSignature({
    required ShippingAddress addr,
    required int? shipId,
    required String shipName,
    required String coupon,
    required int currencyId,
    required List<CartLine> lines,
  }) {
    // anything that can change totals belongs here
    return [
      currencyId.toString(),
      coupon.trim(),
      (shipId?.toString() ?? 'null'),
      shipName.trim(),
      (addr.countryId?.toString() ?? ''),
      (addr.regionId?.toString() ?? ''),
      (addr.city ?? '').trim(),
      (addr.postalCode ?? '').trim(),
      (addr.addressLine ?? '').trim(),
      lines.map((l) => '${l.itemId}:${l.quantity}').join(','),
    ].join('|');
  }

  void _scheduleQuote({
    required CheckoutCart cart,
    required int? shippingMethodId,
    required String shippingMethodName,
  }) {
    if (!_addressReadyForQuotes(state.address)) {
      emit(state.copyWith(clearQuote: true, quoting: false));
      return;
    }

    final lines = _linesFromCart(cart);
    final curId = _resolvedCurrencyId();

    // ✅ IMPORTANT: quote uses APPLIED coupon only (NOT draft)
    final coupon = state.coupon.trim();

    // if shipping options exist but no shipping selected -> don’t quote
    if (state.shippingQuotes.isNotEmpty && shippingMethodId == null) {
      emit(state.copyWith(clearQuote: true, quoting: false));
      return;
    }

    final sig = _quoteSignature(
      addr: state.address,
      shipId: shippingMethodId,
      shipName: shippingMethodName,
      coupon: coupon,
      currencyId: curId,
      lines: lines,
    );

    if (sig == _lastQuoteSig) return;

    _quoteDebounce?.cancel();
    _quoteDebounce = Timer(const Duration(milliseconds: 350), () async {
      _lastQuoteSig = sig;

      emit(state.copyWith(
        quoting: true,
        clearError: true,
        clearCouponError: true,
      ));

      try {
        final q = await quoteFromCart(
          currencyId: curId,
          couponCode: coupon.isEmpty ? null : coupon,
          shippingMethodId: shippingMethodId,
          shippingMethodName: shippingMethodName,
          shippingAddress: state.address,
        );

        emit(state.copyWith(
          quoting: false,
          quote: q,
          clearError: true,
          clearCouponError: true,
        ));
      } catch (err) {
        // ✅ If a coupon was applied, show it inline (not toast)
        final applied = state.coupon.trim();
        final friendly = _friendlyError(err);

        emit(state.copyWith(
          quoting: false,
          clearQuote: true,
          couponError: applied.isNotEmpty ? friendly : null,
          clearError: true, // keep general errors quiet here
        ));
      }
    });
  }

  Future<void> _loadQuotesTaxAndQuote(
    CheckoutCart cart, {
    int? preferMethodId,
  }) async {
    final lines = _linesFromCart(cart);

    final quotes = await getShippingQuotes(
      ownerProjectId: ownerProjectId,
      address: state.address,
      lines: lines,
    );

    ShippingQuote? chosen;
    if (quotes.isNotEmpty) {
      final pref = preferMethodId ?? state.selectedShippingMethodId;
      chosen = quotes.firstWhere(
        (q) => q.methodId != null && q.methodId == pref,
        orElse: () => quotes.first,
      );
    }

    final tax = await previewTax(
      ownerProjectId: ownerProjectId,
      address: state.address,
      lines: lines,
      shippingTotal: chosen?.price ?? 0.0,
    );

    emit(
      state.copyWith(
        shippingQuotes: quotes,
        selectedShippingMethodId: chosen?.methodId,
        selectedQuote: chosen,
        tax: tax,
        clearError: true,
      ),
    );

    // ✅ quote totals (includes APPLIED coupon only)
    _scheduleQuote(
      cart: cart,
      shippingMethodId: chosen?.methodId,
      shippingMethodName: chosen?.methodName ?? 'Shipping',
    );
  }

  Future<void> _onStarted(CheckoutStarted e, Emitter<CheckoutState> emit) async {
    emit(state.copyWith(
      loading: true,
      clearError: true,
      clearOrderId: true,
      clearOrderSummary: true,
      clearQuote: true,
      quoting: false,
      clearCouponError: true,
    ));

    try {
      final cart = await getCart();
      final pms = await getPaymentMethods();

      ShippingAddress lastAddr = const ShippingAddress();
      try {
        lastAddr = await getLastShippingAddress();
      } catch (_) {}

      final prevIndex = state.selectedPaymentIndex;
      final nextIndex =
          (prevIndex != null && prevIndex >= 0 && prevIndex < pms.length)
              ? prevIndex
              : null;

      // keep draft synced (nice UX when reopening screen)
      final appliedCoupon = state.coupon.trim();

      emit(state.copyWith(
        cart: cart,
        paymentMethods: pms,
        selectedPaymentIndex: nextIndex,
        address: lastAddr,
        loading: false,
        clearError: true,
        couponDraft: appliedCoupon,
        clearCouponError: true,
      ));

      if (!cart.isEmpty) {
        if (_addressReadyForQuotes(lastAddr)) {
          await _loadQuotesTaxAndQuote(
            cart,
            preferMethodId: state.selectedShippingMethodId,
          );
        } else {
          emit(state.copyWith(
            shippingQuotes: const [],
            clearSelectedShipping: true,
            clearTax: true,
            clearQuote: true,
            quoting: false,
          ));
        }
      }
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onAddressChanged(
    CheckoutAddressChanged e,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(address: e.address, clearError: true));

    final cart = state.cart;
    if (cart == null || cart.isEmpty) return;

    if (!_addressReadyForQuotes(e.address)) {
      emit(state.copyWith(
        shippingQuotes: const [],
        clearSelectedShipping: true,
        clearTax: true,
        clearQuote: true,
        quoting: false,
        clearError: true,
      ));
      return;
    }

    try {
      await _loadQuotesTaxAndQuote(
        cart,
        preferMethodId: state.selectedShippingMethodId,
      );
    } catch (err) {
      emit(state.copyWith(error: err.toString()));
    }
  }

  Future<void> _onShippingSelected(
    CheckoutShippingSelected e,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(selectedShippingMethodId: e.methodId, clearError: true));

    final cart = state.cart;
    if (cart == null || cart.isEmpty) return;

    try {
      await _loadQuotesTaxAndQuote(cart, preferMethodId: e.methodId);
    } catch (err) {
      emit(state.copyWith(error: err.toString()));
    }
  }

  // ✅ Draft typing = no API
  void _onCouponDraftChanged(
    CheckoutCouponDraftChanged e,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(
      couponDraft: e.draft,
      clearCouponError: true,
      clearError: true,
    ));
  }

  // ✅ Apply coupon = triggers quote API once
  void _onCouponApplied(
    CheckoutCouponApplied e,
    Emitter<CheckoutState> emit,
  ) {
    final cart = state.cart;
    final applied = e.coupon.trim();

    // sync draft with whatever user applied
    emit(state.copyWith(
      coupon: applied,
      couponDraft: e.coupon,
      clearCouponError: true,
      clearError: true,
    ));

    if (cart == null || cart.isEmpty) return;

    _scheduleQuote(
      cart: cart,
      shippingMethodId:
          state.selectedQuote?.methodId ?? state.selectedShippingMethodId,
      shippingMethodName: state.selectedQuote?.methodName ?? 'Shipping',
    );
  }

  void _onPaymentSelected(CheckoutPaymentSelected e, Emitter<CheckoutState> emit) {
    emit(state.copyWith(selectedPaymentIndex: e.index, clearError: true));
  }

  Future<void> _onRefresh(
    CheckoutRefreshRequested e,
    Emitter<CheckoutState> emit,
  ) async {
    final cart = state.cart;
    if (cart == null || cart.isEmpty) return;

    try {
      if (_addressReadyForQuotes(state.address)) {
        await _loadQuotesTaxAndQuote(
          cart,
          preferMethodId: state.selectedShippingMethodId,
        );
      } else {
        emit(state.copyWith(
          shippingQuotes: const [],
          clearSelectedShipping: true,
          clearTax: true,
          clearQuote: true,
          quoting: false,
        ));
      }
    } catch (err) {
      emit(state.copyWith(error: err.toString()));
    }
  }

  Future<void> _onPlaceOrder(
    CheckoutPlaceOrderPressed e,
    Emitter<CheckoutState> emit,
  ) async {
    if (state.placing) return;

    final cart = state.cart;
    if (cart == null || cart.isEmpty) {
      emit(state.copyWith(error: 'Cart is empty'));
      return;
    }

    final idx = state.selectedPaymentIndex;
    if (idx == null || idx < 0 || idx >= state.paymentMethods.length) {
      emit(state.copyWith(error: 'Select a payment method'));
      return;
    }

    final selectedPm = state.paymentMethods[idx];
    final pmCode = selectedPm.code.trim().toUpperCase();
    if (pmCode.isEmpty) {
      emit(state.copyWith(error: 'Payment method code is missing'));
      return;
    }

    final addr = state.address;

    if (addr.countryId == null) {
      emit(state.copyWith(error: 'Select a country'));
      return;
    }
    if (addr.regionId == null) {
      emit(state.copyWith(error: 'Select a region'));
      return;
    }
    if ((addr.city ?? '').trim().isEmpty) {
      emit(state.copyWith(error: 'Enter city'));
      return;
    }
    if ((addr.addressLine ?? '').trim().isEmpty) {
      emit(state.copyWith(error: 'Enter address'));
      return;
    }
    if ((addr.phone ?? '').trim().isEmpty) {
      emit(state.copyWith(error: 'Enter phone'));
      return;
    }

    final quote = state.selectedQuote;
    final shipId = quote?.methodId ?? state.selectedShippingMethodId;
    final shipName = quote?.methodName ?? 'Shipping';

    if (state.shippingQuotes.isNotEmpty && shipId == null) {
      emit(state.copyWith(error: 'Select a shipping method'));
      return;
    }
    if (shipId == null) {
      emit(state.copyWith(error: 'Shipping method is missing'));
      return;
    }

    emit(state.copyWith(placing: true, clearError: true));

    try {
      final lines = _linesFromCart(cart);

      final destinationAccountId =
          (pmCode == 'STRIPE') ? _stripeAccountIdFromPaymentMethod(selectedPm) : null;

      final CheckoutSummaryModel summary = await placeOrder(
        ownerProjectId: ownerProjectId,
        currencyId: _resolvedCurrencyId(),
        paymentMethod: pmCode,

        // ✅ IMPORTANT: use APPLIED coupon only
        couponCode: state.coupon.trim().isEmpty ? null : state.coupon.trim(),

        stripePaymentId: null,
        destinationAccountId: destinationAccountId,
        shippingMethodId: shipId,
        shippingMethodName: shipName,
        shippingAddress: addr,
        lines: lines,
      );

      final provider =
          (summary.paymentProviderCode ?? pmCode).toString().trim().toUpperCase();

      if (provider == 'STRIPE') {
        final clientSecret = (summary.clientSecret ?? '').toString().trim();
        final publishableKey = (summary.publishableKey ?? '').toString().trim();

        if (clientSecret.isEmpty) {
          throw Exception('Checkout did not return Stripe clientSecret');
        }
        if (publishableKey.isEmpty) {
          throw Exception('Checkout did not return Stripe publishableKey (pk_...)');
        }

        try {
          await StripePaymentSheet.pay(
            publishableKey: publishableKey,
            clientSecret: clientSecret,
            merchantName: Env.appName,
          );
        } on StripeException catch (se) {
          final msg = se.error.message ?? 'Stripe payment canceled';
          throw Exception(msg);
        }
      }

      emit(state.copyWith(
        placing: false,
        orderId: summary.orderId,
        orderSummary: summary,
        clearError: true,
      ));
    } catch (err) {
      if (err is CheckoutBlockedFailure) {
        final msg = err.blockingErrors.isNotEmpty
            ? err.blockingErrors.join('\n')
            : err.message;

        emit(state.copyWith(placing: false, error: msg));
        return;
      }

      emit(state.copyWith(placing: false, error: _friendlyError(err)));
    }
  }

  String _friendlyError(Object err) {
    final s = err.toString();
    return s.replaceAll('Exception:', '').trim();
  }
}