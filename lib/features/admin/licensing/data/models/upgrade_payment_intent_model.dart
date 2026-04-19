import 'package:build4front/features/admin/licensing/domain/entities/upgrade_payment_intent.dart';

class UpgradePaymentIntentModel {
  final String paymentIntentId;
  final String? clientSecret;
  final String? publishableKey;
  final String provider;
  final double amount;
  final String currency;
  final String? checkoutUrl;
  final Map<String, dynamic> providerData;

  const UpgradePaymentIntentModel({
    required this.paymentIntentId,
    required this.clientSecret,
    required this.publishableKey,
    required this.provider,
    required this.amount,
    required this.currency,
    required this.checkoutUrl,
    required this.providerData,
  });

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  factory UpgradePaymentIntentModel.fromJson(Map<String, dynamic> j) {
    final providerRaw = j['providerData'] ?? j['metadata'];
    return UpgradePaymentIntentModel(
      paymentIntentId:
          (j['paymentIntentId'] ?? j['id'] ?? j['intentId'] ?? '').toString(),
      clientSecret:
          (j['clientSecret'] ?? j['client_secret'])?.toString(),
      publishableKey:
          (j['publishableKey'] ?? j['publishable_key'])?.toString(),
      provider: (j['provider'] ?? 'stripe').toString(),
      amount: _d(j['amount']),
      currency: (j['currency'] ?? 'USD').toString(),
      checkoutUrl: j['checkoutUrl']?.toString(),
      providerData: providerRaw is Map
          ? Map<String, dynamic>.from(providerRaw)
          : const {},
    );
  }

  UpgradePaymentIntent toEntity() => UpgradePaymentIntent(
        paymentIntentId: paymentIntentId,
        clientSecret: clientSecret,
        publishableKey: publishableKey,
        provider: provider,
        amount: amount,
        currency: currency,
        checkoutUrl: checkoutUrl,
        providerData: providerData,
      );
}
