/// Owner AI balance (GET /api/ai/apps/me/wallet).
class AiWallet {
  final String? planCode;
  final String? planName;
  final int tokensAllowance;
  final int tokensUsed;
  final int tokensRemaining;
  final String? periodStart;
  final String? periodEnd;
  final String status;       // NONE / ACTIVE / EXPIRED
  final bool aiEnabled;
  final String? blockingReason;

  const AiWallet({
    this.planCode,
    this.planName,
    this.tokensAllowance = 0,
    this.tokensUsed = 0,
    this.tokensRemaining = 0,
    this.periodStart,
    this.periodEnd,
    this.status = 'NONE',
    this.aiEnabled = false,
    this.blockingReason,
  });

  factory AiWallet.fromJson(Map<String, dynamic> j) {
    int i(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? 0}') ?? 0;
    return AiWallet(
      planCode: j['planCode']?.toString(),
      planName: j['planName']?.toString(),
      tokensAllowance: i(j['tokensAllowance']),
      tokensUsed: i(j['tokensUsed']),
      tokensRemaining: i(j['tokensRemaining']),
      periodStart: j['periodStart']?.toString(),
      periodEnd: j['periodEnd']?.toString(),
      status: (j['status'] ?? 'NONE').toString(),
      aiEnabled: j['aiEnabled'] == true,
      blockingReason: j['blockingReason']?.toString(),
    );
  }
}
