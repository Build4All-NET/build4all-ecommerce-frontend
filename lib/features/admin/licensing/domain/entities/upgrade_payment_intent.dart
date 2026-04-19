class UpgradePaymentIntent {
  final String paymentIntentId;
  final String? clientSecret;
  final String? publishableKey;
  final String provider;
  final double amount;
  final String currency;
  final String? checkoutUrl;
  final Map<String, dynamic> providerData;

  const UpgradePaymentIntent({
    required this.paymentIntentId,
    required this.clientSecret,
    required this.publishableKey,
    required this.provider,
    required this.amount,
    required this.currency,
    required this.checkoutUrl,
    required this.providerData,
  });
}
