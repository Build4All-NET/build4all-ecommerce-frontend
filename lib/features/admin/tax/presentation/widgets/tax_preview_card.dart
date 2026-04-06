import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/core/exceptions/exception_mapper.dart';

import 'package:build4front/features/admin/tax/data/services/tax_api_service.dart';
import 'package:build4front/features/auth/data/services/auth_token_store.dart';

class TaxPreviewCard extends StatefulWidget {
  final int ownerProjectId;
  final Map<String, dynamic> address;
  final List<Map<String, dynamic>> lines;
  final num shippingTotal;

  const TaxPreviewCard({
    super.key,
    required this.ownerProjectId,
    required this.address,
    required this.lines,
    required this.shippingTotal,
  });

  @override
  State<TaxPreviewCard> createState() => _TaxPreviewCardState();
}

class _TaxPreviewCardState extends State<TaxPreviewCard> {
  final _api = TaxApiService();
  final _tokenStore = const AuthTokenStore();

  bool _loading = true;
  String? _error;

  double _itemsTax = 0;
  double _shippingTax = 0;
  double _totalTax = 0;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void didUpdateWidget(covariant TaxPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final changed =
        oldWidget.ownerProjectId != widget.ownerProjectId ||
        oldWidget.shippingTotal != widget.shippingTotal ||
        oldWidget.lines.length != widget.lines.length ||
        oldWidget.address.toString() != widget.address.toString();

    if (changed) _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await _tokenStore.getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing auth token';
      });
      return;
    }

    try {
      final body = {
        'ownerProjectId': widget.ownerProjectId,
        'address': widget.address,
        'lines': widget.lines,
        'shippingTotal': widget.shippingTotal,
      };

      final res = await _api.previewTax(body: body, authToken: token);

      double toDouble(dynamic v) =>
          v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

      setState(() {
        _itemsTax = toDouble(res['itemsTaxTotal']);
        _shippingTax = toDouble(res['shippingTaxTotal']);
        _totalTax = toDouble(res['totalTax']);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = ExceptionMapper.toMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;
    final l = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        border: Border.all(color: c.border.withOpacity(0.2)),
      ),
      child: _loading
          ? Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.primary,
                  ),
                ),
                SizedBox(width: spacing.sm),
                Text(
                  l.taxPreviewLoading ?? 'Calculating tax...',
                  style: text.bodySmall.copyWith(color: c.muted),
                ),
              ],
            )
          : _error != null
              ? Text(_error!, style: text.bodySmall.copyWith(color: c.danger))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.taxPreviewTitle ?? 'Tax',
                      style: text.titleMedium.copyWith(color: c.label),
                    ),
                    SizedBox(height: spacing.sm),
                    _row(l.itemsTaxLabel ?? 'Items tax', _itemsTax, context),
                    SizedBox(height: spacing.xs),
                    _row(
                      l.shippingTaxLabel ?? 'Shipping tax',
                      _shippingTax,
                      context,
                    ),
                    Divider(
                      height: spacing.lg * 1.6,
                      color: c.border.withOpacity(0.15),
                    ),
                    _row(
                      l.totalTaxLabel ?? 'Total tax',
                      _totalTax,
                      context,
                      bold: true,
                    ),
                  ],
                ),
    );
  }

  Widget _row(
    String label,
    double value,
    BuildContext context, {
    bool bold = false,
  }) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final text = tokens.typography;

    final style = bold ? text.bodySmall : text.bodyMedium;

    return Row(
      children: [
        Expanded(
          child: Text(label, style: style.copyWith(color: c.muted)),
        ),
        Text(value.toStringAsFixed(2), style: style.copyWith(color: c.label)),
      ],
    );
  }
}