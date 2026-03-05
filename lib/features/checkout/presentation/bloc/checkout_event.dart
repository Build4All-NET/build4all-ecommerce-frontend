// lib/features/checkout/presentation/bloc/checkout_event.dart

import 'package:build4front/features/checkout/domain/entities/checkout_entities.dart';

abstract class CheckoutEvent {
  const CheckoutEvent();
}

class CheckoutStarted extends CheckoutEvent {
  const CheckoutStarted();
}

class CheckoutAddressChanged extends CheckoutEvent {
  final ShippingAddress address;
  const CheckoutAddressChanged(this.address);
}

class CheckoutShippingSelected extends CheckoutEvent {
  final int? methodId;
  const CheckoutShippingSelected(this.methodId);
}

/// ✅ NEW: user typing only (NO API)
class CheckoutCouponDraftChanged extends CheckoutEvent {
  final String draft;
  const CheckoutCouponDraftChanged(this.draft);
}

/// ✅ NEW: user applies coupon (THIS triggers quote API)
class CheckoutCouponApplied extends CheckoutEvent {
  final String coupon;
  const CheckoutCouponApplied(this.coupon);
}

class CheckoutPaymentSelected extends CheckoutEvent {
  final int index;
  const CheckoutPaymentSelected(this.index);
}

class CheckoutRefreshRequested extends CheckoutEvent {
  const CheckoutRefreshRequested();
}

class CheckoutPlaceOrderPressed extends CheckoutEvent {
  const CheckoutPlaceOrderPressed();
}