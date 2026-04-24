import 'dart:async';

import 'package:build4front/core/exceptions/app_exception.dart';
import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:build4front/features/checkout/domain/errors/checkout_blocked_failure.dart';
import 'package:build4front/features/checkout/domain/usecases/get_last_shipping_address.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentMethod;

import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/payments/stripe_payment_sheet.dart';

import 'package:build4front/features/checkout/data/models/checkout_summary_model.dart';
import 'package:build4front/features/checkout/domain/entities/checkout_entities.dart';
import 'package:build4front/features/checkout/domain/usecases/abandon_stripe_checkout.dart';
import 'package:build4front/features/checkout/domain/usecases/confirm_payment.dart';
import 'package:build4front/features/checkout/domain/usecases/finalize_stripe_checkout.dart';
import 'package:build4front/features/checkout/domain/usecases/get_checkout_cart.dart';
import 'package:build4front/features/checkout/domain/usecases/get_payment_methods.dart';
import 'package:build4front/features/checkout/domain/usecases/get_shipping_quotes.dart';
import 'package:build4front/features/checkout/domain/usecases/place_order.dart';
import 'package:build4front/features/checkout/domain/usecases/prepare_stripe_checkout.dart';
import 'package:build4front/features/checkout/domain/usecases/preview_tax.dart';
import 'package:build4front/features/checkout/domain/usecases/quote_from_cart.dart';

import 'checkout_event.dart';
import 'checkout_state.dart';

/// Signature for the PayPal approval UX runner the page injects.
///
/// The bloc cannot show a dialog itself (no [BuildContext]). The page
/// supplies a runner that opens the approval URL externally and waits
/// for the user to come back and tap "I've paid" or "Cancel". Returns
/// `true` when the user confirmed payment, `false` otherwise.
typedef PaypalApprovalRunner = Future<bool> Function(String approvalUrl);

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final GetCheckoutCart getCart;
  final GetPaymentMethods getPaymentMethods;
  final GetShippingQuotes getShippingQuotes;
  final GetLastShippingAddress getLastShippingAddress;
  final PreviewTax previewTax;
  final PlaceOrder placeOrder;
  final ConfirmPayment confirmPayment;
  final PrepareStripeCheckout prepareStripeCheckout;
  final FinalizeStripeCheckout finalizeStripeCheckout;
  final AbandonStripeCheckout abandonStripeCheckout;
  final QuoteFromCart quoteFromCart;

  /// Called for PAYPAL place-order: launches the approval URL and waits
  /// for the user to confirm. May be null on hosts that don't render any
  /// PayPal payment method (it's only used when the buyer picks PayPal).
  final PaypalApprovalRunner? paypalApprovalRunner;

  final int ownerProjectId;
  final int? currencyId;

  Timer? _quoteDebounce;
  String? _lastQuoteSig;
  int _quoteOpId = 0;

  CheckoutBloc({
    required this.getCart,
    required this.getPaymentMethods,
    required this.getShippingQuotes,
    required this.previewTax,
    required this.placeOrder,
    required this.confirmPayment,
    required this.prepareStripeCheckout,
    required this.finalizeStripeCheckout,
    required this.abandonStripeCheckout,
    required this.ownerProjectId,
    required this.currencyId,
    required this.getLastShippingAddress,
    required this.quoteFromCart,
    this.paypalApprovalRunner,
  }) : super(CheckoutState.initial()) {
    on<CheckoutStarted>(_onStarted);
    on<CheckoutAddressChanged>(_onAddressChanged);
    on<CheckoutShippingSelected>(_onShippingSelected);
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

  void _invalidateQuoteWork() {
    _quoteDebounce?.cancel();
    _quoteOpId++;
    _lastQuoteSig = null;
  }

  List<CartLine> _linesFromCart(CheckoutCart cart) {
    return cart.items
        .where((x) => x.itemId != 0 && x.quantity > 0)
        .map(
          (x) => CartLine(
            itemId: x.itemId,
            quantity: x.quantity,
            unitPrice: 0.0,
          ),
        )
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
    return [
      currencyId.toString(),
      coupon.trim().toUpperCase(),
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

  bool _summaryRejectedCoupon(CheckoutSummaryModel summary) {
    final msg = (summary.message ?? '').trim().toLowerCase();
    return msg.contains('coupon was not applied');
  }

  void _scheduleQuote({
    required CheckoutCart cart,
    required int? shippingMethodId,
    required String shippingMethodName,
  }) {
    final addr = state.address;
    final lines = _linesFromCart(cart);
    final curId = _resolvedCurrencyId();
    final coupon = state.coupon.trim();

    if (!_addressReadyForQuotes(addr)) {
      _invalidateQuoteWork();
      emit(state.copyWith(clearQuote: true, quoting: false));
      return;
    }

    if (state.shippingQuotes.isNotEmpty && shippingMethodId == null) {
      _invalidateQuoteWork();
      emit(state.copyWith(clearQuote: true, quoting: false));
      return;
    }

    final sig = _quoteSignature(
      addr: addr,
      shipId: shippingMethodId,
      shipName: shippingMethodName,
      coupon: coupon,
      currencyId: curId,
      lines: lines,
    );

    if (sig == _lastQuoteSig) return;

    _quoteDebounce?.cancel();
    final opId = ++_quoteOpId;

    _quoteDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (isClosed || opId != _quoteOpId) return;

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
          shippingAddress: addr,
        );

        if (isClosed || opId != _quoteOpId) return;

        emit(state.copyWith(
          quoting: false,
          quote: q,
          clearError: true,
          clearCouponError: true,
        ));
      } catch (err) {
        if (isClosed || opId != _quoteOpId) return;

        _lastQuoteSig = null;

        emit(state.copyWith(
          quoting: false,
          clearQuote: true,
          couponError: state.lastCouponAttempt.trim().isNotEmpty
              ? _friendlyError(err)
              : null,
          clearError: true,
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

    _scheduleQuote(
      cart: cart,
      shippingMethodId: chosen?.methodId,
      shippingMethodName: chosen?.methodName ?? 'Shipping',
    );
  }

  Future<void> _onStarted(
    CheckoutStarted e,
    Emitter<CheckoutState> emit,
  ) async {
    _invalidateQuoteWork();

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

      final appliedCoupon = state.coupon.trim();

      emit(state.copyWith(
        cart: cart,
        paymentMethods: pms,
        selectedPaymentIndex: nextIndex,
        address: lastAddr,
        loading: false,
        clearError: true,
        couponDraft: appliedCoupon,
        lastCouponAttempt: appliedCoupon,
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
      emit(state.copyWith(
        loading: false,
        error: _friendlyError(err),
      ));
    }
  }

  Future<void> _onAddressChanged(
    CheckoutAddressChanged e,
    Emitter<CheckoutState> emit,
  ) async {
    _invalidateQuoteWork();

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
      emit(state.copyWith(error: _friendlyError(err)));
    }
  }

  Future<void> _onShippingSelected(
    CheckoutShippingSelected e,
    Emitter<CheckoutState> emit,
  ) async {
    _invalidateQuoteWork();

    emit(state.copyWith(
      selectedShippingMethodId: e.methodId,
      clearError: true,
    ));

    final cart = state.cart;
    if (cart == null || cart.isEmpty) return;

    try {
      await _loadQuotesTaxAndQuote(
        cart,
        preferMethodId: e.methodId,
      );
    } catch (err) {
      emit(state.copyWith(error: _friendlyError(err)));
    }
  }

  void _onCouponDraftChanged(
    CheckoutCouponDraftChanged e,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(
      couponDraft: e.draft,
      clearCouponError: true,
      clearError: true,
      clearOrderSummary: true,
    ));
  }

  void _onCouponApplied(
    CheckoutCouponApplied e,
    Emitter<CheckoutState> emit,
  ) {
    final cart = state.cart;
    final applied = e.coupon.trim();

    _invalidateQuoteWork();

    emit(state.copyWith(
      coupon: applied,
      couponDraft: e.coupon,
      lastCouponAttempt: applied,
      clearCouponError: true,
      clearError: true,
      clearOrderSummary: true,
      clearQuote: applied.isEmpty,
    ));

    if (cart == null || cart.isEmpty) return;

    _scheduleQuote(
      cart: cart,
      shippingMethodId:
          state.selectedQuote?.methodId ?? state.selectedShippingMethodId,
      shippingMethodName: state.selectedQuote?.methodName ?? 'Shipping',
    );
  }

  void _onPaymentSelected(
    CheckoutPaymentSelected e,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(
      selectedPaymentIndex: e.index,
      clearError: true,
    ));
  }

  Future<void> _onRefresh(
    CheckoutRefreshRequested e,
    Emitter<CheckoutState> emit,
  ) async {
    if (state.refreshingShipping || state.quoting) return;

    final cart = state.cart;
    if (cart == null || cart.isEmpty) return;

    _invalidateQuoteWork();

    emit(state.copyWith(
      refreshingShipping: true,
      clearError: true,
    ));

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
          clearError: true,
        ));
      }
    } catch (err) {
      emit(state.copyWith(
        error: _friendlyError(err),
      ));
    } finally {
      emit(state.copyWith(refreshingShipping: false));
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

    emit(state.copyWith(
      placing: true,
      clearError: true,
      clearOrderSummary: true,
    ));

    try {
      final lines = _linesFromCart(cart);

      final destinationAccountId =
          pmCode == 'STRIPE' ? _stripeAccountIdFromPaymentMethod(selectedPm) : null;

      CheckoutSummaryModel summary;

      if (pmCode == 'STRIPE') {
        // ---------- STRIPE prepare-then-finalize ----------
        // Nothing hits the DB yet: no Order, cart still intact. If the
        // user closes the sheet the cart is exactly where they left it.
        final prepared = await prepareStripeCheckout(
          ownerProjectId: ownerProjectId,
          currencyId: _resolvedCurrencyId(),
          paymentMethod: pmCode,
          couponCode: state.coupon.trim().isEmpty ? null : state.coupon.trim(),
          destinationAccountId: destinationAccountId,
          shippingMethodId: shipId,
          shippingMethodName: shipName,
          shippingAddress: addr,
          lines: lines,
        );

        final clientSecret = (prepared.clientSecret ?? '').toString().trim();
        final publishableKey = (prepared.publishableKey ?? '').toString().trim();
        final paymentIntentId =
            (prepared.providerPaymentId ?? '').toString().trim();

        if (clientSecret.isEmpty ||
            publishableKey.isEmpty ||
            paymentIntentId.isEmpty) {
          throw AppException(
            'Checkout could not prepare a Stripe payment. Please try again.',
          );
        }

        StripePayStatus sheetResult;
        try {
          sheetResult = await StripePaymentSheet.pay(
            publishableKey: publishableKey,
            clientSecret: clientSecret,
            merchantName: Env.appName,
          );
          // ignore: avoid_print
          print('[checkout] StripePaymentSheet result=$sheetResult');
        } on StripeException catch (se) {
          // User canceled or provider error. Abandon the intent; no order
          // was created so nothing else to roll back.
          await abandonStripeCheckout(
            paymentIntentId: paymentIntentId,
            ownerProjectId: ownerProjectId,
            currencyId: _resolvedCurrencyId(),
            paymentMethod: pmCode,
            couponCode: state.coupon.trim().isEmpty ? null : state.coupon.trim(),
            destinationAccountId: destinationAccountId,
            shippingMethodId: shipId,
            shippingMethodName: shipName,
            shippingAddress: addr,
            lines: lines,
          );
          final msg = se.error.message ?? 'Stripe payment canceled';
          throw AppException(msg, original: se);
        }

        if (sheetResult != StripePayStatus.paid) {
          // Sheet closed without paying. Best-effort cancel the intent
          // and bail out with a benign "canceled" state (no error toast).
          await abandonStripeCheckout(
            paymentIntentId: paymentIntentId,
            ownerProjectId: ownerProjectId,
            currencyId: _resolvedCurrencyId(),
            paymentMethod: pmCode,
            couponCode: state.coupon.trim().isEmpty ? null : state.coupon.trim(),
            destinationAccountId: destinationAccountId,
            shippingMethodId: shipId,
            shippingMethodName: shipName,
            shippingAddress: addr,
            lines: lines,
          );
          // Cart is still intact — leave the user on the checkout screen.
          emit(state.copyWith(placing: false, clearError: true));
          return;
        }

        // Paid. NOW ask the server to create the Order + empty the cart.
        summary = await finalizeStripeCheckout(
          paymentIntentId: paymentIntentId,
          ownerProjectId: ownerProjectId,
          currencyId: _resolvedCurrencyId(),
          paymentMethod: pmCode,
          couponCode: state.coupon.trim().isEmpty ? null : state.coupon.trim(),
          destinationAccountId: destinationAccountId,
          shippingMethodId: shipId,
          shippingMethodName: shipName,
          shippingAddress: addr,
          lines: lines,
        );
      } else if (pmCode == 'PAYPAL') {
        // ---------- PAYPAL prepare-then-finalize ----------
        // Mirrors the Stripe flow: nothing hits the DB until the buyer
        // returns from PayPal and we successfully capture. If they
        // close the browser the cart is exactly where they left it.
        if (paypalApprovalRunner == null) {
          throw AppException(
            'PayPal is not available in this app build.',
          );
        }

        final prepared = await prepareStripeCheckout(
          ownerProjectId: ownerProjectId,
          currencyId: _resolvedCurrencyId(),
          paymentMethod: pmCode,
          couponCode: state.coupon.trim().isEmpty ? null : state.coupon.trim(),
          destinationAccountId: destinationAccountId,
          shippingMethodId: shipId,
          shippingMethodName: shipName,
          shippingAddress: addr,
          lines: lines,
        );

        final approvalUrl = (prepared.redirectUrl ?? '').toString().trim();
        final paypalOrderId =
            (prepared.providerPaymentId ?? '').toString().trim();

        if (approvalUrl.isEmpty || paypalOrderId.isEmpty) {
          throw AppException(
            'Checkout could not prepare a PayPal payment. Please try again.',
          );
        }

        bool approved;
        try {
          approved = await paypalApprovalRunner!(approvalUrl);
        } catch (e) {
          // Treat any error from the approval UX as a cancel: best-effort
          // abandon (PayPal orders auto-expire anyway) and leave the cart
          // intact.
          await abandonStripeCheckout(
            paymentIntentId: paypalOrderId,
            ownerProjectId: ownerProjectId,
            currencyId: _resolvedCurrencyId(),
            paymentMethod: pmCode,
            couponCode: state.coupon.trim().isEmpty ? null : state.coupon.trim(),
            destinationAccountId: destinationAccountId,
            shippingMethodId: shipId,
            shippingMethodName: shipName,
            shippingAddress: addr,
            lines: lines,
          );
          rethrow;
        }

        if (!approved) {
          await abandonStripeCheckout(
            paymentIntentId: paypalOrderId,
            ownerProjectId: ownerProjectId,
            currencyId: _resolvedCurrencyId(),
            paymentMethod: pmCode,
            couponCode: state.coupon.trim().isEmpty ? null : state.coupon.trim(),
            destinationAccountId: destinationAccountId,
            shippingMethodId: shipId,
            shippingMethodName: shipName,
            shippingAddress: addr,
            lines: lines,
          );
          // Cart is still intact — leave the user on the checkout screen.
          emit(state.copyWith(placing: false, clearError: true));
          return;
        }

        // Buyer approved on PayPal. Capture + create the order.
        summary = await finalizeStripeCheckout(
          paymentIntentId: paypalOrderId,
          ownerProjectId: ownerProjectId,
          currencyId: _resolvedCurrencyId(),
          paymentMethod: pmCode,
          couponCode: state.coupon.trim().isEmpty ? null : state.coupon.trim(),
          destinationAccountId: destinationAccountId,
          shippingMethodId: shipId,
          shippingMethodName: shipName,
          shippingAddress: addr,
          lines: lines,
        );
      } else {
        // ---------- Legacy path (Cash / offline) ----------
        summary = await placeOrder(
          ownerProjectId: ownerProjectId,
          currencyId: _resolvedCurrencyId(),
          paymentMethod: pmCode,
          couponCode: state.coupon.trim().isEmpty ? null : state.coupon.trim(),
          stripePaymentId: null,
          destinationAccountId: destinationAccountId,
          shippingMethodId: shipId,
          shippingMethodName: shipName,
          shippingAddress: addr,
          lines: lines,
        );
      }

      final rejectedCoupon = _summaryRejectedCoupon(summary);

      emit(state.copyWith(
        placing: false,
        orderId: summary.orderId,
        orderSummary: summary,
        clearError: true,
        coupon: rejectedCoupon ? '' : state.coupon,
        couponDraft: rejectedCoupon ? '' : state.couponDraft,
        couponError: rejectedCoupon
            ? (summary.message ?? 'Coupon was not applied')
            : null,
        clearQuote: rejectedCoupon,
      ));
    } catch (err) {
      if (err is CheckoutBlockedFailure) {
        final msg = err.blockingErrors.isNotEmpty
            ? err.blockingErrors.join('\n')
            : err.message;

        emit(state.copyWith(
          placing: false,
          error: msg,
        ));
        return;
      }

      emit(state.copyWith(
        placing: false,
        error: _friendlyError(err),
      ));
    }
  }

  String _friendlyError(Object err) {
    return ExceptionMapper.toMessage(err).trim();
  }
}