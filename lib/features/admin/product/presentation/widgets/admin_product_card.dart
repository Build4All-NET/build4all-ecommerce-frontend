import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

import '../../domain/entities/product.dart';

class AdminProductCard extends StatefulWidget {
  final Product product;
  final String? currencySymbol;
  final bool currencyLoading;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AdminProductCard({
    super.key,
    required this.product,
    this.currencySymbol,
    this.currencyLoading = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<AdminProductCard> createState() => _AdminProductCardState();
}

class _AdminProductCardState extends State<AdminProductCard> {
  static const Color _warningColor = Color(0xFFF59E0B);

  String? _resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return '${Env.apiBaseUrl}$trimmed';
  }

  String _moneyStrict(num value, {int decimals = 2}) {
    final sym = (widget.currencySymbol ?? '').trim();
    final amount = value.toDouble().toStringAsFixed(decimals);

    if (sym.isNotEmpty) return '$sym$amount';
    return '…$amount';
  }

  int get _safeStock => widget.product.stock ?? 0;

  bool get _isOutOfStock => _safeStock <= 0;
  bool get _isLowStock => !_isOutOfStock && _safeStock <= 5;

  String get _statusCode {
    final raw = (widget.product.statusCode ?? '').trim().toUpperCase();
    if (raw.isNotEmpty) return raw;

    final legacy = (widget.product.statusName ?? '').trim().toUpperCase();
    if (legacy.isNotEmpty) return legacy;

    return 'UNKNOWN';
  }

  String get _statusLabel {
    final rawName = (widget.product.statusName ?? '').trim();
    if (rawName.isNotEmpty) return rawName;

    switch (_statusCode) {
      case 'DRAFT':
        return 'Draft';
      case 'PUBLISHED':
        return 'Published';
      case 'ARCHIVED':
        return 'Archived';
      default:
        return 'Unknown';
    }
  }

  String get _stockLabel {
    if (_isOutOfStock) return 'Out of stock';
    if (_isLowStock) return 'Low stock';
    return 'In stock';
  }

  String get _productTypeLabel {
    switch (widget.product.productType.toUpperCase()) {
      case 'VARIABLE':
        return 'Variable';
      case 'GROUPED':
        return 'Grouped';
      case 'EXTERNAL':
        return 'External';
      case 'SIMPLE':
      default:
        return 'Simple';
    }
  }

  Color _statusBg(dynamic colors) {
    switch (_statusCode) {
      case 'DRAFT':
        return _warningColor.withOpacity(0.12);
      case 'PUBLISHED':
        return colors.success.withOpacity(0.12);
      case 'ARCHIVED':
        return colors.muted.withOpacity(0.18);
      default:
        return colors.primary.withOpacity(0.10);
    }
  }

  Color _statusFg(dynamic colors) {
    switch (_statusCode) {
      case 'DRAFT':
        return _warningColor;
      case 'PUBLISHED':
        return colors.success;
      case 'ARCHIVED':
        return colors.muted;
      default:
        return colors.primary;
    }
  }

  Color _stockBg(dynamic colors) {
    if (_isOutOfStock) return colors.danger.withOpacity(0.12);
    if (_isLowStock) return _warningColor.withOpacity(0.12);
    return colors.success.withOpacity(0.12);
  }

  Color _stockFg(dynamic colors) {
    if (_isOutOfStock) return colors.danger;
    if (_isLowStock) return _warningColor;
    return colors.success;
  }

  Future<void> _showActionsSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.read<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.card.radius),
        ),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).padding.bottom;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.md,
              spacing.md,
              spacing.md,
              spacing.md + bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: spacing.md),
                  decoration: BoxDecoration(
                    color: colors.muted.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit, color: colors.primary),
                  title: Text(
                    'Edit product',
                    style: text.bodyMedium.copyWith(color: colors.label),
                  ),
                  onTap: () => Navigator.of(ctx).pop('edit'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline, color: colors.danger),
                  title: Text(
                    'Delete product',
                    style: text.bodyMedium.copyWith(color: colors.danger),
                  ),
                  onTap: () => Navigator.of(ctx).pop('delete'),
                ),
                SizedBox(height: spacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: spacing.sm),
                    ),
                    child: Text(l10n.commonCancel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == 'edit' && widget.onEdit != null) {
      widget.onEdit!();
    } else if (action == 'delete' && widget.onDelete != null) {
      widget.onDelete!();
    }
  }

  Widget _buildChip({
    required dynamic tokens,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 78),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.xs,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodySmall.copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final card = tokens.card;
    final text = tokens.typography;

    final imageUrl = _resolveImageUrl(widget.product.imageUrl);

    Widget imagePlaceholder() {
      return Container(
        color: colors.muted.withOpacity(0.08),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_outlined,
          color: colors.muted.withOpacity(0.7),
          size: 24,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 175;
        final imageHeight = compact ? 84.0 : 98.0;
        final contentPad = compact ? 7.0 : 9.0;
        final smallGap = compact ? 2.0 : 3.0;
        final nameLines = 2;

        return ClipRRect(
          borderRadius: BorderRadius.circular(card.radius),
          child: Material(
            color: colors.surface,
            child: InkWell(
              onTap: () => _showActionsSheet(context),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(card.radius),
                  border: Border.all(color: colors.border.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      imagePlaceholder(),
                                )
                              : imagePlaceholder(),
                          Positioned(
                            left: spacing.xs,
                            top: spacing.xs,
                            right: widget.currencyLoading ? 44.0 : spacing.xs,
                            child: Wrap(
                              spacing: spacing.xs,
                              runSpacing: spacing.xs,
                              children: [
                                _buildChip(
                                  tokens: tokens,
                                  label: _statusLabel,
                                  bg: _statusBg(colors),
                                  fg: _statusFg(colors),
                                ),
                                _buildChip(
                                  tokens: tokens,
                                  label: _stockLabel,
                                  bg: _stockBg(colors),
                                  fg: _stockFg(colors),
                                ),
                              ],
                            ),
                          ),
                          if (widget.currencyLoading &&
                              widget.product.currencyId != null)
                            Positioned(
                              top: spacing.xs,
                              right: spacing.xs,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const SizedBox(
                                  width: 11,
                                  height: 11,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(contentPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.product.name,
                            maxLines: nameLines,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium.copyWith(
                              color: colors.label,
                              fontWeight: FontWeight.w700,
                              height: 1.08,
                            ),
                          ),
                          SizedBox(height: smallGap),
                          Text(
                            'Type: $_productTypeLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall.copyWith(
                              color: colors.muted,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: smallGap),
                          Text(
                            'Stock: $_safeStock',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall.copyWith(
                              color: _isOutOfStock
                                  ? colors.danger
                                  : _isLowStock
                                      ? _warningColor
                                      : colors.body,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: compact ? 6.0 : 8.0),
                          Text(
                            _moneyStrict(widget.product.effectivePrice),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          if (widget.product.onSale) ...[
                            SizedBox(height: 2.0),
                            Text(
                              _moneyStrict(widget.product.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall.copyWith(
                                color: colors.muted,
                                decoration: TextDecoration.lineThrough,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}