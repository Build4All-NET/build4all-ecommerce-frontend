// lib/core/payments/paypal_approval_flow.dart
//
// External-payment-page helper for the customer checkout flow.
//
// Used for any provider that asks the buyer to leave the app to complete
// payment — currently PayPal (approval URL) and MPGS (hosted card form).
// Flow:
//   1) Open the URL in the system browser.
//   2) Show a non-dismissible dialog asking the buyer to confirm once
//      they've finished the payment.
//   3) Resolve to `true` if the buyer tapped "I've paid", `false` if
//      they tapped "Cancel" or dismissed.
//
// Whoever calls [PaypalApprovalFlow.run] is responsible for telling the
// backend whether to capture (true) or abandon (false) afterwards.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PaypalApprovalFlow {
  /// [providerLabel] is the human-readable name shown in the dialog
  /// title and body. Defaults to "PayPal" for the historical caller;
  /// MPGS callers pass "card" so the buyer sees "Complete card payment".
  static Future<bool> run({
    required BuildContext context,
    required String approvalUrl,
    String providerLabel = 'PayPal',
  }) async {
    final url = approvalUrl.trim();
    if (url.isEmpty) return false;

    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // Fall through — still offer the confirm/cancel dialog so the
        // user has a way out if the launcher couldn't open the browser.
      }
    }

    if (!context.mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Complete $providerLabel payment'),
          content: Text(
            "We've opened the $providerLabel payment page in your browser. "
            'After you finish paying there, come back and tap "I\'ve paid" '
            'so we can place your order.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("I've paid"),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }
}
