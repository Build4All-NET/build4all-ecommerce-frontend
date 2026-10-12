/// One AI-token purchase in the owner's history
/// (GET /api/ai/apps/me/payments).
class AiPayment {
  final DateTime? date;
  final String? planCode;
  final String? planName;
  final int? tokens;
  final double? amount;
  final String currency;
  final String? status;
  final String? provider;

  const AiPayment({
    this.date,
    this.planCode,
    this.planName,
    this.tokens,
    this.amount,
    this.currency = 'USD',
    this.status,
    this.provider,
  });

  factory AiPayment.fromJson(Map<String, dynamic> j) {
    double? d(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? i(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return AiPayment(
      date: j['date'] != null ? DateTime.tryParse(j['date'].toString()) : null,
      planCode: j['planCode']?.toString(),
      planName: j['planName']?.toString(),
      tokens: i(j['tokens']),
      amount: d(j['amount']),
      currency: (j['currency'] ?? 'USD').toString(),
      status: j['status']?.toString(),
      provider: j['provider']?.toString(),
    );
  }

  /// `YYYY-MM-DD` for display; empty when no date.
  String get dateLabel {
    final x = date;
    if (x == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${x.year}-${two(x.month)}-${two(x.day)}';
  }
}
