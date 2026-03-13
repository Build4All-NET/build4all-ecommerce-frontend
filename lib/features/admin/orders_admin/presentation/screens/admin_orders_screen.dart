import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/l10n/app_localizations.dart';

import '../../domain/entities/admin_order_entities.dart';
import '../bloc/admin_orders_bloc.dart';
import '../bloc/admin_orders_event.dart';
import '../bloc/admin_orders_state.dart';
import 'admin_order_details_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  DateTimeRange? _range;
  int? _quickDaysSelected; // 7 / 30 / null

  void _toast(String msg, {bool error = false}) {
    if (msg.trim().isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppToast.error(context, msg);
    });
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange:
          _range ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );

    if (picked != null && mounted) {
      setState(() {
        _range = picked;
        _quickDaysSelected = null;
      });
    }
  }

  void _quickRange(int days) {
    final now = DateTime.now();
    setState(() {
      _quickDaysSelected = days;
      _range = DateTimeRange(
        start: now.subtract(Duration(days: days)),
        end: now,
      );
    });
  }

  void _clearAllFilters() {
    setState(() {
      _range = null;
      _quickDaysSelected = null;
    });

    context.read<AdminOrdersBloc>().add(
          AdminOrdersStatusChanged(null),
        );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AdminOrdersBloc, AdminOrdersState>(
      listenWhen: (p, c) => p.error != c.error,
      listener: (context, state) {
        if (state.error != null && state.error!.trim().isNotEmpty) {
          _toast(state.error!, error: true);
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          title: Text(
            l10n.adminOrdersTitle,
            style: tokens.typography.titleMedium.copyWith(
              color: colors.label,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: BlocBuilder<AdminOrdersBloc, AdminOrdersState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final statusFiltered = state.orders;
            final filteredOrders = _applyRangeFilter(statusFiltered, _range);

            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminOrdersBloc>().add(
                      const AdminOrdersRefreshRequested(),
                    );
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(spacing.md),
                children: [
                  AdminOrdersAnalyticsHeader(
                    orders: filteredOrders,
                    range: _range,
                    quickDaysSelected: _quickDaysSelected,
                    onPickRange: () => _pickRange(context),
                    onQuick7: () => _quickRange(7),
                    onQuick30: () => _quickRange(30),
                    onClear: _clearAllFilters,
                  ),
                  SizedBox(height: spacing.md),
                  _StatusChips(
                    selected: state.statusFilter, // null => ALL
                    onChanged: (value) {
                      final mapped = (value == 'ALL') ? null : value;
                      context.read<AdminOrdersBloc>().add(
                            AdminOrdersStatusChanged(mapped),
                          );
                    },
                  ),
                  SizedBox(height: spacing.md),
                  if (filteredOrders.isEmpty)
                    _EmptyState(
                      title: l10n.adminNoOrders,
                      subtitle: l10n.adminNoOrdersHint,
                    ),
                  ...filteredOrders.map(
                    (o) => Padding(
                      padding: EdgeInsets.only(bottom: spacing.md),
                      child: _OrderHeaderCard(
                        row: o,
                        onTap: () async {
                          final changed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminOrderDetailsScreen(orderId: o.id),
                            ),
                          );

                          if (changed == true && context.mounted) {
                            context.read<AdminOrdersBloc>().add(
                                  const AdminOrdersRefreshRequested(),
                                );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<OrderHeaderRow> _applyRangeFilter(
    List<OrderHeaderRow> orders,
    DateTimeRange? range,
  ) {
    if (range == null) return orders;

    DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
    final start = day(range.start);
    final end = day(range.end);

    return orders.where((o) {
      final dt = o.orderDate;
      if (dt == null) return false;
      final x = day(dt.toLocal());
      return !x.isBefore(start) && !x.isAfter(end);
    }).toList();
  }
}

/* ===================== Analytics header ===================== */

class AdminOrdersAnalyticsHeader extends StatelessWidget {
  final List<OrderHeaderRow> orders;
  final DateTimeRange? range;
  final int? quickDaysSelected;

  final VoidCallback? onPickRange;
  final VoidCallback? onQuick7;
  final VoidCallback? onQuick30;
  final VoidCallback? onClear;

  const AdminOrdersAnalyticsHeader({
    super.key,
    required this.orders,
    this.range,
    this.quickDaysSelected,
    this.onPickRange,
    this.onQuick7,
    this.onQuick30,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final l10n = AppLocalizations.of(context)!;

    final stats = _computeStats(orders);

    final locale = Localizations.localeOf(context).toString();
    final money = NumberFormat('#,##0.00', locale);

    final screenW = MediaQuery.sizeOf(context).width;
    final kpiW = screenW < 380 ? 160.0 : 180.0;

    bool quickSelected(int d) => quickDaysSelected == d;

    Widget quickChip({
      required String label,
      required bool selected,
      required VoidCallback? onTap,
    }) {
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap?.call(),
        selectedColor: colors.primary.withOpacity(0.16),
        backgroundColor: colors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: (selected ? colors.primary : colors.border).withOpacity(0.35),
          ),
        ),
        labelStyle: tokens.typography.bodySmall.copyWith(
          color: selected ? colors.primary : colors.muted,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
        ),
      );
    }

    Widget clearChip() {
      return ActionChip(
        label: Text(l10n.adminClear),
        onPressed: onClear,
        backgroundColor: colors.surface,
        labelStyle: tokens.typography.bodySmall.copyWith(
          color: colors.muted,
          fontWeight: FontWeight.w900,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: colors.border.withOpacity(0.35),
          ),
        ),
      );
    }

    Widget kpi({
      required String title,
      required String value,
      required String sub,
      required IconData icon,
      required Color accent,
    }) {
      return Container(
        width: kpiW,
        padding: EdgeInsets.all(spacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(tokens.card.radius),
          border: Border.all(color: colors.border.withOpacity(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 18),
                SizedBox(width: spacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: tokens.typography.bodySmall.copyWith(
                      color: colors.muted,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.xs),
            Text(
              value,
              style: tokens.typography.titleMedium.copyWith(
                color: colors.label,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: spacing.xs),
            Text(
              sub,
              style: tokens.typography.bodySmall.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    final maxRev = stats.last7Days.fold<double>(
      0.0,
      (m, e) => e.revenue > m ? e.revenue : m,
    );

    final pending = stats.statusCounts['PENDING'] ?? 0;
    final completed = stats.statusCounts['COMPLETED'] ?? 0;
    final canceled = stats.statusCounts['CANCELED'] ?? 0;

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(tokens.card.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    range == null ? l10n.adminAllTime : _fmtRange(range!),
                    style: tokens.typography.bodySmall.copyWith(
                      color: colors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: spacing.xs),
          Wrap(
            spacing: spacing.xs,
            runSpacing: spacing.xs,
            children: [
              quickChip(
                label: l10n.adminLast7Days,
                selected: quickSelected(7),
                onTap: onQuick7,
              ),
              quickChip(
                label: l10n.adminLast30Days,
                selected: quickSelected(30),
                onTap: onQuick30,
              ),
              clearChip(),
            ],
          ),
          SizedBox(height: spacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                kpi(
                  title: l10n.adminKpiOrders,
                  value: '${stats.ordersCount}',
                  sub: 'Pending $pending • Completed $completed',
                  icon: Icons.receipt_long,
                  accent: colors.primary,
                ),
                SizedBox(width: spacing.sm),
                kpi(
                  title: l10n.adminKpiGrossSales,
                  value: money.format(stats.grossSales),
                  sub:
                      'Paid ${money.format(stats.paidRevenue)} • Out ${money.format(stats.outstanding)}',
                  icon: Icons.trending_up,
                  accent: colors.label,
                ),
                SizedBox(width: spacing.sm),
                kpi(
                  title: l10n.adminKpiPaid,
                  value: money.format(stats.paidRevenue),
                  sub: 'Fully paid ${stats.fullyPaidCount}/${stats.ordersCount}',
                  icon: Icons.payments_outlined,
                  accent: colors.success,
                ),
                SizedBox(width: spacing.sm),
                kpi(
                  title: l10n.adminKpiOutstanding,
                  value: money.format(stats.outstanding),
                  sub: 'Canceled $canceled • Remaining on orders',
                  icon: Icons.hourglass_bottom,
                  accent: colors.danger,
                ),
                SizedBox(width: spacing.sm),
                kpi(
                  title: l10n.adminKpiAvgOrder,
                  value: money.format(stats.avgOrderValue),
                  sub: 'Avg from ${stats.ordersCount} orders',
                  icon: Icons.calculate_outlined,
                  accent: colors.muted,
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.md),
          Row(
            children: [
              Text(
                l10n.adminFullyPaidPercent(
                  (stats.fullyPaidRate * 100).toStringAsFixed(0),
                ),
                style: tokens.typography.bodySmall.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${stats.fullyPaidCount}/${stats.ordersCount}',
                style: tokens.typography.bodySmall.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: stats.fullyPaidRate,
              minHeight: 8,
              backgroundColor: colors.border.withOpacity(0.25),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          SizedBox(height: spacing.md),
          Text(
            l10n.adminPaidRevenueLast7Days,
            style: tokens.typography.bodyMedium.copyWith(
              color: colors.label,
              fontWeight: FontWeight.w900,
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
                          color: colors.primary.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      SizedBox(height: spacing.xs),
                      Text(
                        label,
                        style: tokens.typography.bodySmall.copyWith(
                          color: colors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  _OrdersStats _computeStats(List<OrderHeaderRow> orders) {
    final statusCounts = <String, int>{};

    double gross = 0;
    double paid = 0;
    double outstanding = 0;
    int fullyPaidCount = 0;

    DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
    final now = DateTime.now();
    final days = List.generate(7, (idx) {
      final d = now.subtract(Duration(days: 6 - idx));
      return day(d);
    });
    final revByDay = {for (final d in days) d: 0.0};

    for (final o in orders) {
      final total =
          (o.payment.orderTotal <= 0) ? o.totalPrice : o.payment.orderTotal;
      gross += total;

      final st = o.status.toUpperCase();
      statusCounts[st] = (statusCounts[st] ?? 0) + 1;

      paid += o.payment.paidAmount;

      final rem = (o.payment.remainingAmount > 0)
          ? o.payment.remainingAmount
          : (total - o.payment.paidAmount);
      outstanding += rem < 0 ? 0 : rem;

      final fp = o.fullyPaid || o.payment.paymentState.toUpperCase() == 'PAID';
      if (fp) fullyPaidCount++;

      final dt = o.orderDate;
      if (dt != null) {
        final dk = day(dt.toLocal());
        if (revByDay.containsKey(dk)) {
          revByDay[dk] = (revByDay[dk] ?? 0) + o.payment.paidAmount;
        }
      }
    }

    final count = orders.length;
    final avg = count == 0 ? 0.0 : gross / count;
    final last7 = days.map((d) => _RevenueDay(d, revByDay[d] ?? 0)).toList();

    return _OrdersStats(
      ordersCount: count,
      grossSales: gross,
      paidRevenue: paid,
      outstanding: outstanding,
      avgOrderValue: avg,
      fullyPaidCount: fullyPaidCount,
      statusCounts: statusCounts,
      last7Days: last7,
    );
  }

  static String _fmtRange(DateTimeRange r) {
    String two(int v) => v.toString().padLeft(2, '0');
    final a = r.start.toLocal();
    final b = r.end.toLocal();
    return '${a.year}-${two(a.month)}-${two(a.day)} → ${b.year}-${two(b.month)}-${two(b.day)}';
  }
}

class _OrdersStats {
  final int ordersCount;
  final double grossSales;
  final double paidRevenue;
  final double outstanding;
  final double avgOrderValue;
  final int fullyPaidCount;
  final Map<String, int> statusCounts;
  final List<_RevenueDay> last7Days;

  const _OrdersStats({
    required this.ordersCount,
    required this.grossSales,
    required this.paidRevenue,
    required this.outstanding,
    required this.avgOrderValue,
    required this.fullyPaidCount,
    required this.statusCounts,
    required this.last7Days,
  });

  double get fullyPaidRate =>
      ordersCount == 0 ? 0 : (fullyPaidCount / ordersCount).clamp(0, 1);
}

class _RevenueDay {
  final DateTime day;
  final double revenue;

  const _RevenueDay(this.day, this.revenue);
}

/* ===================== Status chips ===================== */

class _StatusChips extends StatelessWidget {
  final String? selected; // null => ALL
  final ValueChanged<String> onChanged;

  const _StatusChips({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final l10n = AppLocalizations.of(context)!;

    final sel = (selected ?? 'ALL').toUpperCase();

    Widget chip(String label, String value) {
      final isSel = sel == value;
      return ChoiceChip(
        label: Text(label),
        selected: isSel,
        onSelected: (_) => onChanged(value),
        selectedColor: colors.primary.withOpacity(0.16),
        backgroundColor: colors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: (isSel ? colors.primary : colors.border).withOpacity(0.35),
          ),
        ),
        labelStyle: tokens.typography.bodySmall.copyWith(
          color: isSel ? colors.primary : colors.body,
          fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
        ),
      );
    }

    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        chip(l10n.adminFilterAll, 'ALL'),
        chip(l10n.adminOrderStatusPending, 'PENDING'),
        chip(l10n.adminOrderStatusCompleted, 'COMPLETED'),
        chip(l10n.adminOrderStatusRejected, 'REJECTED'),
      ],
    );
  }
}

/* ===================== Card ===================== */

class _OrderHeaderCard extends StatelessWidget {
  final OrderHeaderRow row;
  final VoidCallback onTap;

  const _OrderHeaderCard({
    required this.row,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final card = tokens.card;
    final l10n = AppLocalizations.of(context)!;

    Color statusColor() {
      final s = row.status.toUpperCase();
      if (s == 'COMPLETED') return colors.success;
      if (s == 'CANCELED' || s == 'REJECTED' || s == 'REFUNDED') {
        return colors.danger;
      }
      if (s == 'CANCEL_REQUESTED') return colors.primary;
      return colors.muted;
    }

    Color payColor() {
      final p = row.payment.paymentState.toUpperCase();
      if (p == 'PAID') return colors.success;
      if (p == 'PARTIAL') return colors.primary;
      if (p == 'UNPAID') return colors.danger;
      return colors.muted;
    }

    final total =
        (row.payment.orderTotal <= 0) ? row.totalPrice : row.payment.orderTotal;
    final paid = row.payment.paidAmount;
    final progress = total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);

    final statusC = statusColor();
    final payC = payColor();

    final code = (row.orderCode ?? '').trim();
    final seq = row.orderSeq;
    final title =
        code.isNotEmpty ? 'Order $code' : l10n.adminOrderCardTitle(row.id);

    return InkWell(
      borderRadius: BorderRadius.circular(card.radius),
      onTap: onTap,
      child: Ink(
        padding: EdgeInsets.all(card.padding),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(card.radius),
          border: Border.all(color: colors.border.withOpacity(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: tokens.typography.titleMedium.copyWith(
                          color: colors.label,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (code.isNotEmpty) ...[
                        SizedBox(height: spacing.xs),
                        Text(
                          '#${row.id}${seq != null ? ' • Seq $seq' : ''}',
                          style: tokens.typography.bodySmall.copyWith(
                            color: colors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _Badge(
                  text: row.statusUi.isNotEmpty ? row.statusUi : row.status,
                  fg: statusC,
                  bg: statusC.withOpacity(0.12),
                  border: statusC.withOpacity(0.35),
                ),
              ],
            ),
            SizedBox(height: spacing.xs),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: colors.muted),
                SizedBox(width: spacing.xs),
                Expanded(
                  child: Text(
                    _fmtDate(row.orderDate),
                    style: tokens.typography.bodySmall.copyWith(
                      color: colors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  l10n.adminItemsShort(row.itemsCount),
                  style: tokens.typography.bodySmall.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sm),
            Row(
              children: [
                _Badge(
                  text: row.payment.paymentState,
                  fg: payC,
                  bg: payC.withOpacity(0.12),
                  border: payC.withOpacity(0.35),
                ),
                const Spacer(),
                Text(
                  total.toStringAsFixed(2),
                  style: tokens.typography.bodySmall.copyWith(
                    color: colors.label,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colors.border.withOpacity(0.25),
              ),
            ),
            SizedBox(height: spacing.xs),
            Row(
              children: [
                Text(
                  l10n.adminPaidShort(paid.toStringAsFixed(2)),
                  style: tokens.typography.bodySmall.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (!row.fullyPaid)
                  Text(
                    l10n.adminRemainingShort(
                      row.payment.remainingAmount.toStringAsFixed(2),
                    ),
                    style: tokens.typography.bodySmall.copyWith(
                      color: colors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  Text(
                    l10n.adminFullyPaid,
                    style: tokens.typography.bodySmall.copyWith(
                      color: colors.success,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  final Color border;

  const _Badge({
    required this.text,
    required this.fg,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: tokens.typography.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;

    return Padding(
      padding: EdgeInsets.only(top: spacing.lg),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 42, color: colors.muted),
          SizedBox(height: spacing.sm),
          Text(
            title,
            style: tokens.typography.titleMedium.copyWith(
              color: colors.label,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: tokens.typography.bodyMedium.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}