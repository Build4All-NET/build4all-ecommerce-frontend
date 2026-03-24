import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

import '../../domain/entities/product.dart';

class AdminProductCard extends StatelessWidget {
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
    final sym = (currencySymbol ?? '').trim();
    final amount = value.toDouble().toStringAsFixed(decimals);
    return sym.isNotEmpty ? '$sym$amount' : amount;
  }

  int get _safeStock => product.stock ?? 0;

  bool get _isOutOfStock => _safeStock <= 0;
  bool get _isLowStock => !_isOutOfStock && _safeStock <= 5;

  String get _statusCode {
    final raw = (product.statusCode ?? '').trim().toUpperCase();
    if (raw.isNotEmpty) return raw;

    final legacy = (product.statusName ?? '').trim().toUpperCase();
    if (legacy.isNotEmpty) return legacy;

    return 'UNKNOWN';
  }

  String get _statusLabel {
    final rawName = (product.statusName ?? '').trim();
    if (rawName.isNotEmpty) return rawName;

    switch (_statusCode) {
      case 'DRAFT':
        return 'Draft';
      case 'UPCOMING':
        return 'Upcoming';
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
    switch (product.productType.toUpperCase()) {
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

  bool _hasText(String? value) => (value ?? '').trim().isNotEmpty;

  Color _statusBg(dynamic colors) {
    switch (_statusCode) {
      case 'DRAFT':
        return _warningColor.withOpacity(0.12);
      case 'UPCOMING':
        return colors.primary.withOpacity(0.12);
      case 'PUBLISHED':
        return colors.success.withOpacity(0.12);
      case 'ARCHIVED':
        return colors.muted.withOpacity(0.16);
      default:
        return colors.primary.withOpacity(0.10);
    }
  }

  Color _statusFg(dynamic colors) {
    switch (_statusCode) {
      case 'DRAFT':
        return _warningColor;
      case 'UPCOMING':
        return colors.primary;
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

  TextStyle _compactTitleStyle(TextStyle base) {
    final baseSize = (base.fontSize ?? 16).toDouble();
    final compactSize = baseSize > 13 ? baseSize - 2 : baseSize;
    return base.copyWith(fontSize: compactSize);
  }

  TextStyle _compactBodyStyle(TextStyle base) {
    final baseSize = (base.fontSize ?? 14).toDouble();
    final compactSize = baseSize > 11 ? baseSize - 1.5 : baseSize;
    return base.copyWith(fontSize: compactSize);
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
                  width: 42,
                  height: 4,
                  margin: EdgeInsets.only(bottom: spacing.md),
                  decoration: BoxDecoration(
                    color: colors.muted.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined, color: colors.primary),
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
                    child: Text(l10n.commonCancel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == 'edit' && onEdit != null) {
      onEdit!();
    } else if (action == 'delete' && onDelete != null) {
      onDelete!();
    }
  }

  Widget _buildImagePlaceholder(dynamic colors) {
    return Container(
      color: colors.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(14),
      child: Image.asset(
        'assets/branding/product_placeholder.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildPill({
    required dynamic tokens,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: 5,
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
    );
  }

  Widget _buildMiniChip({
    required dynamic tokens,
    required IconData icon,
    required String label,
    required Color fg,
    required Color bg,
    double? maxWidth,
  }) {
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          SizedBox(width: spacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkuBox({
    required dynamic tokens,
    required String sku,
    required bool compact,
  }) {
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? spacing.xs : spacing.sm,
        vertical: compact ? spacing.xs : spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.qr_code_2_outlined,
            size: compact ? 14 : 16,
            color: colors.label,
          ),
          SizedBox(width: spacing.xs),
          Expanded(
            child: SizedBox(
              height: compact ? 16 : 18,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'SKU: ${sku.trim()}',
                  maxLines: 1,
                  softWrap: false,
                  style: text.bodySmall.copyWith(
                    color: colors.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required dynamic tokens,
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    required bool compact,
  }) {
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    final valueStyle = (compact
            ? _compactTitleStyle(text.titleMedium)
            : text.titleMedium)
        .copyWith(
      color: valueColor,
      fontWeight: FontWeight.w800,
    );

    return Container(
      padding: EdgeInsets.all(compact ? spacing.xs : spacing.sm),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withOpacity(0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: compact ? 13 : 15, color: colors.muted),
              SizedBox(width: spacing.xs),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          SizedBox(
            width: double.infinity,
            height: compact ? 18 : 22,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: valueStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required dynamic tokens,
    required bool primary,
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
  }) {
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: primary ? colors.onPrimary : colors.danger,
        ),
        SizedBox(width: spacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall.copyWith(
              color: primary ? colors.onPrimary : colors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    if (primary) {
      return SizedBox(
        height: 38,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: EdgeInsets.zero,
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: colors.danger.withOpacity(0.35),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;
    final card = tokens.card;

    final imageUrl = _resolveImageUrl(product.imageUrl);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 185;

        final imageHeight = compact ? 104.0 : 120.0;
        final horizontalPad = compact ? spacing.sm : spacing.md;
        final verticalPad = compact ? spacing.sm : spacing.md;

        final titleStyle = (compact
                ? _compactTitleStyle(text.titleMedium)
                : text.titleMedium)
            .copyWith(
          color: colors.label,
          fontWeight: FontWeight.w800,
          height: compact ? 1.04 : 1.10,
        );

        final bodyStyle = (compact
                ? _compactBodyStyle(text.bodySmall)
                : text.bodySmall)
            .copyWith(
          color: colors.muted,
          height: compact ? 1.05 : 1.12,
        );

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(card.radius),
            border: Border.all(color: colors.border.withOpacity(0.28)),
            boxShadow: [
              BoxShadow(
                color: colors.label.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(card.radius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: imageHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildImagePlaceholder(colors),
                            )
                          : _buildImagePlaceholder(colors),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: spacing.sm,
                        top: spacing.sm,
                        right: 44,
                        child: Wrap(
                          spacing: spacing.xs,
                          runSpacing: spacing.xs,
                          children: [
                            _buildPill(
                              tokens: tokens,
                              label: _statusLabel,
                              bg: _statusBg(colors),
                              fg: _statusFg(colors),
                            ),
                            _buildPill(
                              tokens: tokens,
                              label: _stockLabel,
                              bg: _stockBg(colors),
                              fg: _stockFg(colors),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: spacing.xs,
                        right: spacing.xs,
                        child: Material(
                          color: Colors.black.withOpacity(0.36),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _showActionsSheet(context),
                            child: const SizedBox(
                              width: 34,
                              height: 34,
                              child: Icon(
                                Icons.more_horiz,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (currencyLoading && product.currencyId != null)
                        Positioned(
                          bottom: spacing.xs,
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
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPad,
                      vertical: verticalPad,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        SizedBox(height: compact ? 4 : spacing.xs),
                        Text(
                          _hasText(product.description)
                              ? product.description!.trim()
                              : _productTypeLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: bodyStyle,
                        ),
                        SizedBox(height: compact ? spacing.xs : spacing.sm),
                        _buildMiniChip(
                          tokens: tokens,
                          icon: Icons.widgets_outlined,
                          label: _productTypeLabel,
                          fg: colors.primary,
                          bg: colors.primary.withOpacity(0.10),
                          maxWidth: compact ? 82 : 108,
                        ),
                        if (_hasText(product.sku)) ...[
                          SizedBox(height: spacing.xs),
                          _buildSkuBox(
                            tokens: tokens,
                            sku: product.sku!,
                            compact: compact,
                          ),
                        ],
                        SizedBox(height: spacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricBox(
                                tokens: tokens,
                                icon: Icons.sell_outlined,
                                label: 'Price',
                                value: _moneyStrict(product.effectivePrice),
                                valueColor: colors.primary,
                                compact: compact,
                              ),
                            ),
                            SizedBox(width: spacing.sm),
                            Expanded(
                              child: _buildMetricBox(
                                tokens: tokens,
                                icon: Icons.inventory_2_outlined,
                                label: 'Stock',
                                value: '$_safeStock',
                                valueColor: _isOutOfStock
                                    ? colors.danger
                                    : _isLowStock
                                        ? _warningColor
                                        : colors.success,
                                compact: compact,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                tokens: tokens,
                                primary: false,
                                onPressed: onDelete,
                                icon: Icons.delete_outline,
                                label: 'Delete',
                              ),
                            ),
                            SizedBox(width: spacing.sm),
                            Expanded(
                              child: _buildActionButton(
                                tokens: tokens,
                                primary: true,
                                onPressed: onEdit,
                                icon: Icons.edit_outlined,
                                label: 'Edit',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}