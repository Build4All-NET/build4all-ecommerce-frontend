import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

class OwnerOrdersStats {
  final int ordersCount;
  final double grossSales;
  final double paidRevenue;
  final double outstanding;
  final double avgOrderValue;
  final int fullyPaidCount;

  final Map<String, int> statusCounts;
  final Map<String, int> paymentStateCounts;

  final List<_RevenueDay> last7Days;

  const OwnerOrdersStats({
    required this.ordersCount,
    required this.grossSales,
    required this.paidRevenue,
    required this.outstanding,
    required this.avgOrderValue,
    required this.fullyPaidCount,
    required this.statusCounts,
    required this.paymentStateCounts,
    required this.last7Days,
  });

  double get fullyPaidRate =>
      ordersCount == 0 ? 0 : (fullyPaidCount / ordersCount).clamp(0, 1);
}

class _RevenueDay {
  final DateTime day;
  final double revenue; // paidRevenue per day (or gross if you want)
  const _RevenueDay(this.day, this.revenue);
}

double _d(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

DateTime? _dt(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  // Handles ISO like "2025-12-22T10:30:00"
  return DateTime.tryParse(s);
}

String _normKey(String? s) {
  final x = (s ?? '').trim();
  return x.isEmpty ? 'Unknown' : x;
}

/// Compute stats from the OWNER orders list.
/// Expected order map shape (from your backend owner/orders):
/// {
///   id, orderDate, totalPrice, status, statusUi, itemsCount,
///   fullyPaid, payment: { paidAmount, remainingAmount, paymentState, ...}
/// }
OwnerOrdersStats computeOwnerOrdersStats(
  List<Map<String, dynamic>> orders, {
  DateTimeRange? range,
}) {
  final filtered = range == null
      ? orders
      : orders.where((o) {
          final d = _dt(o['orderDate']);
          if (d == null) return false;
          final day = DateTime(d.year, d.month, d.day);
          final start = DateTime(
            range.start.year,
            range.start.month,
            range.start.day,
          );
          final end = DateTime(range.end.year, range.end.month, range.end.day);
          return !day.isBefore(start) && !day.isAfter(end);
        }).toList();

  final statusCounts = <String, int>{};
  final paymentStateCounts = <String, int>{};

  double grossSales = 0;
  double paidRevenue = 0;
  double outstanding = 0;
  int fullyPaidCount = 0;

  // last 7 days revenue (paid) buckets
  final now = DateTime.now();
  final days = List.generate(7, (idx) {
    final d = now.subtract(Duration(days: 6 - idx));
    return DateTime(d.year, d.month, d.day);
  });
  final revenueByDay = {for (final d in days) d: 0.0};

  for (final o in filtered) {
    grossSales += _d(o['totalPrice']);

    final st = _normKey(o['statusUi']?.toString() ?? o['status']?.toString());
    statusCounts[st] = (statusCounts[st] ?? 0) + 1;

    final payment = (o['payment'] is Map) ? (o['payment'] as Map) : null;
    final paid = payment == null ? 0.0 : _d(payment['paidAmount']);
    final remain = payment == null ? 0.0 : _d(payment['remainingAmount']);
    final payState = _normKey(
      payment == null ? null : payment['paymentState']?.toString(),
    );

    paidRevenue += paid;
    outstanding += remain;

    paymentStateCounts[payState] = (paymentStateCounts[payState] ?? 0) + 1;

    final fp =
        (o['fullyPaid'] == true) ||
        (payment != null && (payment['fullyPaid'] == true)) ||
        (payState.toUpperCase() == 'PAID');
    if (fp) fullyPaidCount++;

    final od = _dt(o['orderDate']);
    if (od != null) {
      final dayKey = DateTime(od.year, od.month, od.day);
      if (revenueByDay.containsKey(dayKey)) {
        // choose paid (more realistic) — switch to gross if you want
        revenueByDay[dayKey] = (revenueByDay[dayKey] ?? 0) + paid;
      }
    }
  }

  final ordersCount = filtered.length;
  final avgOrderValue = ordersCount == 0 ? 0.0 : grossSales / ordersCount;

  final last7 = days.map((d) => _RevenueDay(d, revenueByDay[d] ?? 0)).toList();

  return OwnerOrdersStats(
    ordersCount: ordersCount,
    grossSales: grossSales,
    paidRevenue: paidRevenue,
    outstanding: outstanding,
    avgOrderValue: avgOrderValue,
    fullyPaidCount: fullyPaidCount,
    statusCounts: statusCounts,
    paymentStateCounts: paymentStateCounts,
    last7Days: last7,
  );
}

class OwnerOrdersAnalyticsHeader extends StatelessWidget {
  final List<Map<String, dynamic>> orders; // owner orders list
  final DateTimeRange? range;
  final VoidCallback? onPickRange;

  const OwnerOrdersAnalyticsHeader({
    super.key,
    required this.orders,
    this.range,
    this.onPickRange,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final l10n = AppLocalizations.of(context)!;

    final stats = computeOwnerOrdersStats(orders, range: range);

    Widget kpi(String title, String value, IconData icon) {
      return Container(
        width: 170,
        padding: EdgeInsets.all(spacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(tokens.card.radius),
          border: Border.all(color: colors.border.withOpacity(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.muted, size: 18),
            SizedBox(height: spacing.sm),
            Text(
              title,
              style: tokens.typography.bodySmall.copyWith(color: colors.muted),
            ),
            SizedBox(height: spacing.xs),
            Text(
              value,
              style: tokens.typography.titleMedium.copyWith(
                color: colors.label,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    final maxRev = stats.last7Days.fold<double>(
      0.0,
      (m, e) => e.revenue > m ? e.revenue : m,
    );

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(tokens.card.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.adminDashboard,
                  style: tokens.typography.titleMedium.copyWith(
                    color: colors.label,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (onPickRange != null)
                TextButton.icon(
                  onPressed: onPickRange,
                  icon: Icon(Icons.date_range, size: 18, color: colors.muted),
                  label: Text(
                    range == null
                        ? l10n.adminLast30Days
                        : '${range!.start.year}-${range!.start.month.toString().padLeft(2, '0')}-${range!.start.day.toString().padLeft(2, '0')} → '
                              '${range!.end.year}-${range!.end.month.toString().padLeft(2, '0')}-${range!.end.day.toString().padLeft(2, '0')}',
                    style: tokens.typography.bodySmall.copyWith(
                      color: colors.muted,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: spacing.sm),

          // KPI row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                kpi(l10n.adminKpiOrders, '${stats.ordersCount}', Icons.receipt_long),
                SizedBox(width: spacing.sm),
                kpi(
                  l10n.adminKpiGrossSales,
                  stats.grossSales.toStringAsFixed(2),
                  Icons.trending_up,
                ),
                SizedBox(width: spacing.sm),
                kpi(
                  l10n.adminKpiPaid,
                  stats.paidRevenue.toStringAsFixed(2),
                  Icons.payments,
                ),
                SizedBox(width: spacing.sm),
                kpi(
                  l10n.adminKpiOutstanding,
                  stats.outstanding.toStringAsFixed(2),
                  Icons.hourglass_bottom,
                ),
                SizedBox(width: spacing.sm),
                kpi(
                  l10n.adminKpiAvgOrder,
                  stats.avgOrderValue.toStringAsFixed(2),
                  Icons.calculate,
                ),
              ],
            ),
          ),

          SizedBox(height: spacing.md),

          // Fully paid rate
          Row(
            children: [
              Text(
                l10n.adminFullyPaidPercent((stats.fullyPaidRate * 100).toStringAsFixed(0)),
                style: tokens.typography.bodySmall.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${stats.fullyPaidCount}/${stats.ordersCount}',
                style: tokens.typography.bodySmall.copyWith(
                  color: colors.muted,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: stats.fullyPaidRate,
              minHeight: 8,
              backgroundColor: colors.border.withOpacity(0.25),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),

          SizedBox(height: spacing.md),

          // Status breakdown chips
          Text(
            l10n.adminStatusBreakdown,
            style: tokens.typography.bodyMedium.copyWith(
              color: colors.label,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: spacing.xs),
          Wrap(
            spacing: spacing.xs,
            runSpacing: spacing.xs,
            children: stats.statusCounts.entries.map((e) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.sm,
                  vertical: spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.border.withOpacity(0.22)),
                ),
                child: Text(
                  '${e.key}: ${e.value}',
                  style: tokens.typography.bodySmall.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: spacing.md),

          // Revenue last 7 days (mini bars)
          Text(
            l10n.adminPaidRevenueLast7Days,
            style: tokens.typography.bodyMedium.copyWith(
              color: colors.label,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: spacing.sm),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: stats.last7Days.map((p) {
              final h = maxRev <= 0
                  ? 6.0
                  : (60.0 * (p.revenue / maxRev)).clamp(6.0, 60.0);
              final label = '${p.day.month}/${p.day.day}';
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.xs),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: h,
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      SizedBox(height: spacing.xs),
                      Text(
                        label,
                        style: tokens.typography.bodySmall.copyWith(
                          color: colors.muted,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: spacing.sm),
          Text(
            l10n.adminDashboardRevenueNote,
            style: tokens.typography.bodySmall.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
