// lib/core/payments/paypal_approval_flow.dart
//
// PayPal approval-URL helper for the customer checkout flow.
//
// Mobile cannot host the PayPal approval page in-app, so the flow is:
//   1) Open the approval URL in the system browser.
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
  static Future<bool> run({
    required BuildContext context,
    required String approvalUrl,
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
          title: const Text('Complete PayPal payment'),
          content: const Text(
            "We've opened PayPal in your browser. After you finish "
            'paying there, come back and tap "I\'ve paid" so we can '
            'place your order.',
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
