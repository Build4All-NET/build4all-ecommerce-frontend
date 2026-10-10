/// An AI token pack an owner can buy (GET /api/ai/apps/me/plans).
class AiTokenPack {
  final String code;
  final String name;
  final int tokensPerPeriod;
  final double price;
  final String currency;
  final String billingCycle; // MONTHLY / YEARLY
  final bool popular;
  final String? description;

  const AiTokenPack({
    required this.code,
    required this.name,
    required this.tokensPerPeriod,
    required this.price,
    required this.currency,
    required this.billingCycle,
    this.popular = false,
    this.description,
  });

  factory AiTokenPack.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;
    int i(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? 0}') ?? 0;
    return AiTokenPack(
      code: (j['code'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      tokensPerPeriod: i(j['tokensPerPeriod']),
      price: d(j['price']),
      currency: (j['currency'] ?? 'USD').toString(),
      billingCycle: (j['billingCycle'] ?? 'MONTHLY').toString(),
      popular: j['popular'] == true,
      description: j['description']?.toString(),
    );
  }
}
