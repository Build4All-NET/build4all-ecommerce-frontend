import 'package:flutter/material.dart';

/// A standard post-payment result screen: a clear outcome, the amount and
/// reference on success, and a reason with a Retry option on failure. Used by
/// both the shop checkout and the subscription/AI-pack flows so every payment
/// ends the same way.
///
/// Pops `true` when the user asks to retry (failure only), otherwise `false`.
class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final String title;
  final String? message;

  /// Preformatted, e.g. "USD 29.99". Shown prominently on success.
  final String? amountText;

  /// Order/transaction reference to keep.
  final String? reference;

  final String primaryLabel;
  final bool showRetry;

  const PaymentResultScreen._({
    required this.success,
    required this.title,
    this.message,
    this.amountText,
    this.reference,
    this.primaryLabel = 'Done',
    this.showRetry = false,
  });

  factory PaymentResultScreen.success({
    String title = 'Payment successful',
    String? message,
    String? amountText,
    String? reference,
    String primaryLabel = 'Done',
  }) =>
      PaymentResultScreen._(
        success: true,
        title: title,
        message: message,
        amountText: amountText,
        reference: reference,
        primaryLabel: primaryLabel,
      );

  factory PaymentResultScreen.failure({
    String title = 'Payment not completed',
    String? message,
    String? reference,
    bool showRetry = true,
  }) =>
      PaymentResultScreen._(
        success: false,
        title: title,
        message: message ??
            'Your payment was not completed and you have not been charged, '
                'or the charge was reversed.',
        reference: reference,
        primaryLabel: 'Close',
        showRetry: showRetry,
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = success ? const Color(0xFF1A7F4B) : cs.error;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      success ? Icons.check_rounded : Icons.close_rounded,
                      size: 44,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                  ),
                  if (amountText != null && amountText!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      amountText!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                  if (message != null && message!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                  ],
                  if (reference != null && reference!.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text('Reference',
                              style:
                                  Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        letterSpacing: 0.4,
                                      )),
                          const SizedBox(height: 3),
                          SelectableText(
                            reference!.trim(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Keep this reference for your records.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            )),
                  ],
                  const SizedBox(height: 28),
                  if (showRetry) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Try again'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(primaryLabel),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(primaryLabel),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
