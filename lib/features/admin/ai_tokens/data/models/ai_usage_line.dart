/// One "used this period" breakdown row (GET /api/ai/apps/me/usage).
class AiUsageLine {
  final String feature;
  final int tokens;
  const AiUsageLine({required this.feature, required this.tokens});
  factory AiUsageLine.fromJson(Map<String, dynamic> j) => AiUsageLine(
        feature: (j['feature'] ?? 'ai').toString(),
        tokens: j['tokens'] is num ? (j['tokens'] as num).toInt() : int.tryParse('${j['tokens'] ?? 0}') ?? 0,
      );
}
