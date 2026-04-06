// lib/core/payments/stripe_payment_sheet.dart
//
// Stripe PaymentSheet helper.
//
// Multi-tenant note:
// - Backend returns publishableKey (pk_...) and clientSecret per checkout.
// - So we initialize Stripe right before presenting the PaymentSheet.

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:build4front/core/exceptions/app_exception.dart';

enum StripePayStatus { paid, canceled }

class StripePaymentSheet {
  static String?
      _lastPk; // remember the last applied pk_ to avoid redundant applySettings()

  static Future<StripePayStatus> pay({
    required String publishableKey,
    required String clientSecret,
    required String merchantName,
  }) async {
    final pk = publishableKey.trim();
    final cs = clientSecret.trim();

    if (pk.isEmpty) {
      throw AppException('Stripe publishableKey is missing (pk_...)');
    }
    if (cs.isEmpty) {
      throw AppException('Stripe clientSecret is missing');
    }

    if (_lastPk != pk) {
      Stripe.publishableKey = pk;
      await Stripe.instance.applySettings();
      _lastPk = pk;
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: cs,
          merchantDisplayName: merchantName,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      return StripePayStatus.paid;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return StripePayStatus.canceled;
      }

      throw AppException(
        e.error.message ?? 'Stripe payment failed',
        original: e,
      );
    }
  }
}