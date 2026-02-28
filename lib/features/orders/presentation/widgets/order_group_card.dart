import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

import '../../domain/entities/order_entities.dart';

class OrderGroupCard extends StatelessWidget {
  final OrderCard order;
  final VoidCallback? onTap;

  const OrderGroupCard({
    super.key,
    required this.order,
    this.onTap,
  });

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;

    final rawStatus = order.orderStatus.trim().toUpperCase();
    final prettyStatus = (order.orderStatusUi?.trim().isNotEmpty == true)
        ? order.orderStatusUi!.trim()
        : (rawStatus.isEmpty
            ? ''
            : rawStatus.substring(0, 1) + rawStatus.substring(1).toLowerCase());

    final paidAll = order.fullyPaid == true;

    final displayCode =
        (order.orderCode != null && order.orderCode!.trim().isNotEmpty)
            ? order.orderCode!.trim()
            : '#${order.orderId}';

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

    Widget badge(String text, Color c) {
      return Container(
        padding:
            EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order + code + chevron
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order $displayCode',
                    style: tokens.typography.titleMedium.copyWith(
                      color: colors.label,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.muted),
              ],
            ),

            SizedBox(height: spacing.xs),

            // Item name
            Text(
              (order.previewItemName ?? 'Item').toString(),
              style: tokens.typography.bodyMedium.copyWith(
                color: colors.body,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: spacing.sm),

            // Badges row
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                if (prettyStatus.isNotEmpty) badge(prettyStatus, statusColor()),
                badge(
                  paidAll ? l10n.ordersPaid : l10n.ordersUnpaid,
                  paidAll ? colors.success : colors.muted,
                ),
              ],
            ),

            SizedBox(height: spacing.sm),

            // Info row (count • total • date)
            Wrap(
              spacing: spacing.xs,
              runSpacing: spacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${order.itemsCount} ${order.itemsCount == 1 ? "item" : "items"}'
                  '${order.linesCount != order.itemsCount ? " (${order.linesCount} lines)" : ""}',
                  style: tokens.typography.bodySmall.copyWith(color: colors.body),
                ),
                Text('•',
                    style:
                        tokens.typography.bodySmall.copyWith(color: colors.muted)),
                Text(
                  _money(order.totalPrice),
                  style: tokens.typography.bodySmall.copyWith(
                    color: colors.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (order.orderDate != null) ...[
                  Text('•',
                      style: tokens.typography.bodySmall
                          .copyWith(color: colors.muted)),
                  Text(
                    _formatDateTime(order.orderDate!),
                    style:
                        tokens.typography.bodySmall.copyWith(color: colors.muted),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}