import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

import '../../domain/entities/order_entities.dart';

class OrderGroupCard extends StatelessWidget {
  final List<OrderLine> lines;
  final VoidCallback? onTap;

  const OrderGroupCard({
    super.key,
    required this.lines,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    assert(lines.isNotEmpty, 'OrderGroupCard requires at least one line');

    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;

    final first = lines.first;

    final orderId = _orderId(first);
    final orderDate = _orderDate(first);

    final rawStatus = ((first.orderStatus.trim().isNotEmpty)
            ? first.orderStatus
            : _safeGet<String>(() => (first.order as dynamic).status) ?? '')
        .trim()
        .toUpperCase();

    final prettyStatus = _prettyStatus(rawStatus);

    final totalQty = lines.fold<int>(0, (sum, line) => sum + line.quantity);
    final lineCount = lines.length;

    final totalPrice = _orderTotal(first) ?? _sumLinesTotal(lines);
    final previewTitle = _previewTitle(lines);

    final paidAll = lines.every((e) => e.wasPaid);
    final paidAny = lines.any((e) => e.wasPaid);

    Color statusColor() {
      if (rawStatus == 'PENDING' || rawStatus == 'CANCEL_REQUESTED') {
        return colors.muted;
      }
      if (rawStatus == 'COMPLETED') return colors.success;
      if (rawStatus == 'CANCELED' || rawStatus == 'CANCELLED') {
        return colors.danger;
      }
      return colors.muted;
    }

    Color payColor() {
      if (paidAll) return colors.success;
      if (paidAny) return colors.muted; // keep safe if no warning color in tokens
      return colors.muted;
    }

    String payLabel() {
      if (paidAll) return l10n.ordersPaid;
      if (paidAny) return 'Partially Paid';
      return l10n.ordersUnpaid;
    }

    Widget badge(String text, Color c) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.withOpacity(0.35)),
        ),
        child: Text(
          text,
          style: tokens.typography.bodySmall.copyWith(
            color: c,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(tokens.card.radius),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(tokens.card.radius),
          border: Border.all(color: colors.border.withOpacity(0.25)),
          boxShadow: tokens.card.showShadow
              ? [
                  BoxShadow(
                    blurRadius: tokens.card.elevation,
                    offset: const Offset(0, 2),
                    color: Colors.black.withOpacity(0.06),
                  ),
                ]
              : null,
        ),
        padding: EdgeInsets.all(tokens.card.padding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImageBox(url: first.item.imageUrl),
            SizedBox(width: spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order number + arrow
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          orderId != null ? 'Order #$orderId' : 'Order',
                          style: tokens.typography.titleMedium.copyWith(
                            color: colors.label,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: spacing.sm),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.muted,
                      ),
                    ],
                  ),

                  SizedBox(height: spacing.xs),

                  // Preview first item
                  Text(
                    previewTitle,
                    style: tokens.typography.bodyMedium.copyWith(
                      color: colors.body,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: spacing.sm),

                  // Status + payment badges
                  Wrap(
                    spacing: spacing.sm,
                    runSpacing: spacing.sm,
                    children: [
                      if (prettyStatus.isNotEmpty)
                        badge(prettyStatus, statusColor()),
                      badge(payLabel(), payColor()),
                    ],
                  ),

                  SizedBox(height: spacing.sm),

                  // Summary line: count • total • date
                  Wrap(
                    spacing: spacing.xs,
                    runSpacing: spacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '$totalQty ${totalQty == 1 ? "item" : "items"}'
                        '${lineCount != totalQty ? " ($lineCount lines)" : ""}',
                        style: tokens.typography.bodySmall.copyWith(
                          color: colors.body,
                        ),
                      ),
                      Text(
                        '•',
                        style: tokens.typography.bodySmall.copyWith(
                          color: colors.muted,
                        ),
                      ),
                      Text(
                        totalPrice != null ? _money(totalPrice) : '--',
                        style: tokens.typography.bodySmall.copyWith(
                          color: colors.body,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (orderDate != null) ...[
                        Text(
                          '•',
                          style: tokens.typography.bodySmall.copyWith(
                            color: colors.muted,
                          ),
                        ),
                        Text(
                          _formatDateTime(orderDate),
                          style: tokens.typography.bodySmall.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // Helpers
  // -------------------------

  String _previewTitle(List<OrderLine> lines) {
    final rawName = lines.first.item.itemName.trim();
    final firstName = rawName.isEmpty ? 'Item' : rawName;

    if (lines.length == 1) return firstName;
    return '$firstName + ${lines.length - 1} more';
    // Example: Pizza + 2 more
  }

  String _prettyStatus(String raw) {
    final s = raw.trim().toUpperCase();
    if (s.isEmpty) return '';
    if (s == 'CANCEL_REQUESTED') return 'Cancel Requested';
    if (s == 'CANCELED') return 'Canceled';
    if (s == 'CANCELLED') return 'Cancelled';
    return s.substring(0, 1) + s.substring(1).toLowerCase();
  }

  int? _orderId(OrderLine line) {
    final dynamic order = line.order;
    final v = _safeGet<dynamic>(() => order.id);
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  DateTime? _orderDate(OrderLine line) {
    final dynamic order = line.order;

    final d1 = _toDate(_safeGet<dynamic>(() => order.createdAt));
    if (d1 != null) return d1;

    final d2 = _toDate(_safeGet<dynamic>(() => order.orderDate));
    if (d2 != null) return d2;

    final d3 = _toDate(_safeGet<dynamic>(() => order.createdDate));
    if (d3 != null) return d3;

    return null;
  }

  double? _orderTotal(OrderLine line) {
    final dynamic order = line.order;

    final t1 = _toDouble(_safeGet<dynamic>(() => order.totalPrice));
    if (t1 != null) return t1;

    final t2 = _toDouble(_safeGet<dynamic>(() => order.totalAmount));
    if (t2 != null) return t2;

    final t3 = _toDouble(_safeGet<dynamic>(() => order.grandTotal));
    if (t3 != null) return t3;

    return null;
  }

  double? _sumLinesTotal(List<OrderLine> lines) {
    double total = 0;
    bool hasAny = false;

    for (final line in lines) {
      // Try line total first
      final lineTotal =
          _toDouble(_safeGet<dynamic>(() => (line as dynamic).totalPrice)) ??
              _toDouble(_safeGet<dynamic>(() => (line as dynamic).lineTotal)) ??
              _toDouble(_safeGet<dynamic>(() => (line as dynamic).subtotal));

      if (lineTotal != null) {
        total += lineTotal;
        hasAny = true;
        continue;
      }

      // Try unit price * qty
      final unitPrice =
          _toDouble(_safeGet<dynamic>(() => (line.item as dynamic).price)) ??
              _toDouble(_safeGet<dynamic>(() => (line.item as dynamic).itemPrice));

      if (unitPrice != null) {
        total += unitPrice * line.quantity;
        hasAny = true;
      }
    }

    return hasAny ? total : null;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.trim().isNotEmpty) {
      return DateTime.tryParse(v.trim());
    }
    return null;
  }

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  T? _safeGet<T>(T Function() getter) {
    try {
      return getter();
    } catch (_) {
      return null;
    }
  }
}

class _ImageBox extends StatelessWidget {
  final String? url;
  const _ImageBox({required this.url});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 76,
        height: 76,
        color: colors.background,
        child: (url == null || url!.trim().isEmpty)
            ? Icon(Icons.receipt_long_outlined, color: colors.muted)
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.broken_image_outlined, color: colors.muted),
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: progress.expectedTotalBytes == null
                            ? null
                            : progress.cumulativeBytesLoaded /
                                (progress.expectedTotalBytes ?? 1),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}