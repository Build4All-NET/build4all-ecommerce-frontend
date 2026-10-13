/// One AI feature in the owner's AI Marketplace, with this app's install state.
/// (GET /api/ai/apps/me/features)
class AiFeature {
  final String code;
  final String name;
  final String description;
  final String locationLabel;
  final String iconKey;
  final bool installed;

  const AiFeature({
    required this.code,
    required this.name,
    this.description = '',
    this.locationLabel = '',
    this.iconKey = '',
    this.installed = true,
  });

  AiFeature copyWith({bool? installed}) => AiFeature(
        code: code,
        name: name,
        description: description,
        locationLabel: locationLabel,
        iconKey: iconKey,
        installed: installed ?? this.installed,
      );

  factory AiFeature.fromJson(Map<String, dynamic> j) => AiFeature(
        code: (j['code'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        locationLabel: (j['locationLabel'] ?? '').toString(),
        iconKey: (j['iconKey'] ?? '').toString(),
        installed: j['installed'] == true,
      );
}

/// A page of marketplace features plus the counts for search, paging and the
/// "{installedTotal} of {featuresTotal} installed" summary.
class AiFeaturePage {
  final List<AiFeature> items;
  final int page;
  final int size;
  final int total;
  final int totalPages;
  final int installedTotal;
  final int featuresTotal;

  const AiFeaturePage({
    this.items = const [],
    this.page = 0,
    this.size = 4,
    this.total = 0,
    this.totalPages = 1,
    this.installedTotal = 0,
    this.featuresTotal = 0,
  });

  static int _i(dynamic v, [int d = 0]) {
    if (v == null) return d;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? d;
  }

  factory AiFeaturePage.fromJson(Map<String, dynamic> j) => AiFeaturePage(
        items: ((j['items'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => AiFeature.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        page: _i(j['page']),
        size: _i(j['size'], 4),
        total: _i(j['total']),
        totalPages: _i(j['totalPages'], 1),
        installedTotal: _i(j['installedTotal']),
        featuresTotal: _i(j['featuresTotal']),
      );
}
