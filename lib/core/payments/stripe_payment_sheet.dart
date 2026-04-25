// lib/core/payments/stripe_payment_sheet.dart
//
// Stripe PaymentSheet helper.
//
// Multi-tenant note:
// - Backend returns publishableKey (pk_...) and clientSecret per checkout.
// - So we initialize Stripe right before presenting the PaymentSheet.
//
// Return URL (deep link) note:
// - Some payment methods leave the app to a hosted page (Stripe Link OTP,
//   Cash App Pay, bank redirect, Klarna, ...). After auth they redirect to
//   `<applicationId>://stripe-redirect`. iOS works without a registered
//   scheme because flutter_stripe uses ASWebAuthenticationSession which
//   auto-returns. Android opens the page in a Custom Tab and REQUIRES an
//   <intent-filter> for that scheme — see AndroidManifest.xml.
// - Each tenant build has its own applicationId / bundleId, so the scheme
//   is per-app-unique and two B4A apps on the same device don't collide.

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:build4front/core/exceptions/app_exception.dart';

enum StripePayStatus { paid, canceled }

class StripePaymentSheet {
  static String?
      _lastPk; // remember the last applied pk_ to avoid redundant applySettings()
  static String? _cachedReturnUrl;

  /// Builds the Stripe redirect URL using the platform's package name /
  /// bundle id. Cached after the first lookup since it cannot change at
  /// runtime.
  static Future<String> _stripeReturnUrl() async {
    final cached = _cachedReturnUrl;
    if (cached != null) return cached;
    final info = await PackageInfo.fromPlatform();
    final scheme = info.packageName.trim();
    final url = '$scheme://stripe-redirect';
    _cachedReturnUrl = url;
    return url;
  }

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

    final returnUrl = await _stripeReturnUrl();

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: cs,
          merchantDisplayName: merchantName,
          returnURL: returnUrl,
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