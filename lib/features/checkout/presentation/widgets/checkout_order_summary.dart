// lib/features/checkout/presentation/widgets/checkout_order_summary.dart

import 'package:build4front/features/catalog/cubit/money.dart';
import 'package:build4front/features/checkout/data/models/checkout_summary_model.dart';
import 'package:build4front/features/checkout/domain/entities/checkout_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

class CheckoutOrderSummary extends StatelessWidget {
  final CheckoutCart cart;
  final ShippingQuote? selectedShipping;
  final TaxPreview? tax;

  /// ✅ NEW: backend quote result (source of truth)
  final CheckoutSummaryModel? quote;

  const CheckoutOrderSummary({
    super.key,
    required this.cart,
    required this.selectedShipping,
    required this.tax,
    this.quote,
  });

  double _itemsSubtotalLocal() {
    return cart.items.fold<double>(0.0, (sum, it) => sum + it.lineTotal);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final spacing = tokens.spacing;
    final colors = tokens.colors;
    final t = Theme.of(context).textTheme;

    final itemsSubtotalLocal = _itemsSubtotalLocal();
    final shippingLocal = selectedShipping?.price ?? 0.0;
    final taxLocal = (tax?.itemsTaxTotal ?? 0.0) + (tax?.shippingTaxTotal ?? 0.0);

    final q = quote;

    final itemsSubtotal = q?.itemsSubtotal ?? itemsSubtotalLocal;
    final shippingTotal = q?.shippingTotal ?? shippingLocal;

    final taxTotal = q != null
        ? (q.itemTaxTotal + q.shippingTaxTotal)
        : taxLocal;

    final couponCode = (q?.couponCode ?? '').trim();
    final couponDiscount = q?.couponDiscount ?? 0.0;
    final showCoupon = couponCode.isNotEmpty && couponDiscount > 0;

    // ✅ grand total from backend quote is best
    final total = q?.grandTotal ??
        (itemsSubtotal + shippingTotal + taxTotal - couponDiscount);

    return Column(
      children: [
        _row(context, l10n.itemsSubtotalLabel, money(context, itemsSubtotal)),
        SizedBox(height: spacing.sm),

        _row(context, l10n.shippingLabel, money(context, shippingTotal)),
        SizedBox(height: spacing.sm),

        _row(context, l10n.taxClassLabel, money(context, taxTotal)),

        if (showCoupon) ...[
          SizedBox(height: spacing.sm),
          _row(
            context,
            l10n.orderDetailsCouponLine(couponCode),
            '-${money(context, couponDiscount)}',
            rightColor: colors.success,
          ),
        ],

        SizedBox(height: spacing.md),
        Divider(color: colors.border.withOpacity(0.2)),
        SizedBox(height: spacing.md),

        Row(
          children: [
            Expanded(
              child: Text(
                l10n.totalLabel,
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.label,
                ),
              ),
            ),
            Text(
              money(context, total),
              style: t.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: colors.label,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String left,
    String right, {
    Color? rightColor,
  }) {
    final tokens = context.read<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final t = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(left, style: t.bodyMedium?.copyWith(color: colors.body)),
        ),
        Text(
          right,
          style: t.bodyMedium?.copyWith(
            color: rightColor ?? colors.label,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}