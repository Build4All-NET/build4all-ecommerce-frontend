import 'dart:async';

import 'package:build4front/common/widgets/app_toast.dart';
import 'package:flutter/material.dart';

import '../../data/ai_marketplace_api.dart';
import '../../data/models/ai_feature.dart';

/// Owner "AI Marketplace": every AI feature, installed by default, each with a
/// checkbox to install/uninstall it for this app. Search + paging; each toggle
/// persists immediately to the backend.
class AiMarketplaceScreen extends StatefulWidget {
  const AiMarketplaceScreen({super.key});

  @override
  State<AiMarketplaceScreen> createState() => _AiMarketplaceScreenState();
}

class _AiMarketplaceScreenState extends State<AiMarketplaceScreen> {
  final AiMarketplaceApi _api = AiMarketplaceApi();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  String _query = '';
  int _pageIndex = 0;

  List<AiFeature> _items = const [];
  int _installedTotal = 0;
  int _featuresTotal = 0;
  int _totalPages = 1;
  final Set<String> _busy = {};

  static const int _pageSize = 4;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getFeatures(
        query: _query,
        page: page ?? _pageIndex,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items = res.items;
        _installedTotal = res.installedTotal;
        _featuresTotal = res.featuresTotal;
        _totalPages = res.totalPages;
        _pageIndex = res.page;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {}); // reflect the clear (✕) button immediately
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _query = value.trim();
      _pageIndex = 0;
      _load(page: 0);
    });
  }

  Future<void> _toggle(AiFeature f) async {
    if (_busy.contains(f.code)) return;
    final bool next = !f.installed;

    // Optimistic update.
    setState(() {
      _busy.add(f.code);
      _items = _items
          .map((x) => x.code == f.code ? x.copyWith(installed: next) : x)
          .toList();
      _installedTotal += next ? 1 : -1;
    });

    try {
      await _api.setInstalled(f.code, next);
    } catch (e) {
      if (!mounted) return;
      // Revert on failure.
      setState(() {
        _items = _items
            .map((x) => x.code == f.code ? x.copyWith(installed: f.installed) : x)
            .toList();
        _installedTotal += next ? -1 : 1;
      });
      AppToast.error(context, 'Could not update ${f.name}. $e');
    } finally {
      if (mounted) setState(() => _busy.remove(f.code));
    }
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'import':
        return Icons.file_upload_outlined;
      case 'camera':
        return Icons.photo_camera_outlined;
      case 'pencil':
        return Icons.edit_outlined;
      case 'reply':
        return Icons.reply_rounded;
      case 'search':
        return Icons.search_rounded;
      case 'tag':
        return Icons.sell_outlined;
      case 'box':
        return Icons.inventory_2_outlined;
      case 'globe':
        return Icons.language_outlined;
      case 'wand':
        return Icons.auto_fix_high_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Marketplace'),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$_installedTotal of $_featuresTotal installed',
                style: TextStyle(
                    color: cs.primary, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _intro(cs),
            const SizedBox(height: 14),
            _searchField(cs),
            const SizedBox(height: 14),
            ..._listBody(cs),
          ],
        ),
      ),
    );
  }

  Widget _intro(ColorScheme cs) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Every AI feature is installed by default. Uncheck any you don’t '
                'want in your app. Your shoppers use them for free — you’re billed '
                'from your AI token balance, so uninstalling one also stops it '
                'spending tokens.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      );

  Widget _searchField(ColorScheme cs) => TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search AI features',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchCtrl.clear();
                    _query = '';
                    _pageIndex = 0;
                    _load(page: 0);
                    setState(() {});
                  },
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      );

  List<Widget> _listBody(ColorScheme cs) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_error != null) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Text('Could not load AI features.\n$_error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.error, fontSize: 13)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => _load(), child: const Text('Retry')),
            ],
          ),
        ),
      ];
    }
    if (_items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Text(
              _query.isEmpty
                  ? 'No AI features yet.'
                  : 'No AI features match “$_query”.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ),
      ];
    }
    return [
      ..._items.map((f) => _featureCard(cs, f)),
      if (_totalPages > 1) ...[
        const SizedBox(height: 10),
        _pager(cs),
      ],
      const SizedBox(height: 14),
      Text(
        'Uninstalled features disappear for your shoppers and stop spending '
        'tokens. Install them again anytime.',
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
      ),
    ];
  }

  Widget _featureCard(ColorScheme cs, AiFeature f) {
    final busy = _busy.contains(f.code);
    return Opacity(
      opacity: f.installed ? 1 : 0.62,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: busy ? null : () => _toggle(f),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: f.installed
                        ? cs.primary.withValues(alpha: 0.12)
                        : cs.onSurface.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconFor(f.iconKey),
                      size: 22,
                      color: f.installed ? cs.primary : cs.onSurfaceVariant),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(f.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                          const SizedBox(width: 8),
                          _statePill(cs, f.installed),
                        ],
                      ),
                      if (f.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(f.description,
                            style: TextStyle(
                                fontSize: 13, color: cs.onSurfaceVariant)),
                      ],
                      if (f.locationLabel.isNotEmpty) ...[
                        const SizedBox(height: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(f.locationLabel,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: Padding(
                          padding: EdgeInsets.all(2),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Checkbox(
                        value: f.installed,
                        onChanged: (_) => _toggle(f),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statePill(ColorScheme cs, bool installed) {
    final color = installed ? const Color(0xFF1E9E5A) : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        installed ? 'INSTALLED' : 'INSTALL',
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: color),
      ),
    );
  }

  Widget _pager(ColorScheme cs) {
    final buttons = <Widget>[];
    buttons.add(_pageButton(cs, '‹', _pageIndex - 1, _pageIndex == 0));
    for (var i = 0; i < _totalPages; i++) {
      buttons.add(_pageButton(cs, '${i + 1}', i, false, current: i == _pageIndex));
    }
    buttons.add(_pageButton(cs, '›', _pageIndex + 1, _pageIndex == _totalPages - 1));
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: buttons,
    );
  }

  Widget _pageButton(ColorScheme cs, String label, int target, bool disabled,
      {bool current = false}) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: (disabled || _loading || current)
            ? null
            : () => _load(page: target),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(36, 36),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: current ? cs.primary : null,
          foregroundColor: current ? cs.onPrimary : cs.onSurface,
          side: BorderSide(
              color: current ? cs.primary : cs.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}
