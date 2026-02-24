import 'package:build4front/features/orders/presentation/widgets/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/common/widgets/primary_button.dart';

import '../../domain/entities/order_entities.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';
import '../widgets/orders_filter_chips.dart';
import '../widgets/order_group_card.dart';


class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersBloc>().add(const OrdersStarted());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final spacing = tokens.spacing;
    final colors = tokens.colors;

    return BlocListener<OrdersBloc, OrdersState>(
      listenWhen: (p, c) => p.error != c.error,
      listener: (context, state) {
        final err = state.error;
        if (err != null && err.trim().isNotEmpty) {
          AppToast.show(context, err, isError: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.ordersTitle)),
        body: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (context, state) {
            if (state.loading) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(spacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      SizedBox(height: spacing.md),
                      Text(
                        l10n.ordersLoading,
                        style: tokens.typography.bodyMedium.copyWith(
                          color: colors.body,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // NOTE: state.filtered is line-level list (OrderLine)
            final lines = state.filtered;

            if (state.orders.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(spacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 46,
                        color: colors.muted,
                      ),
                      SizedBox(height: spacing.sm),
                      Text(
                        l10n.ordersEmptyTitle,
                        style: tokens.typography.titleMedium.copyWith(
                          color: colors.label,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing.xs),
                      Text(
                        l10n.ordersEmptyBody,
                        style: tokens.typography.bodyMedium.copyWith(
                          color: colors.body,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing.lg),
                      PrimaryButton(
                        label: l10n.ordersReload,
                        onPressed: () => context.read<OrdersBloc>().add(
                          const OrdersStarted(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ✅ Group line items into orders (UI-only fix)
            final groupedOrders = _groupLinesByOrder(lines);

            return RefreshIndicator(
              onRefresh: () async {
                context.read<OrdersBloc>().add(const OrdersRefreshRequested());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(spacing.md),
                children: [
                  const OrdersFilterChips(),
                  SizedBox(height: spacing.md),

                  if (groupedOrders.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: spacing.lg),
                      child: Center(
                        child: Text(
                          l10n.ordersNoResultsForFilter,
                          style: tokens.typography.bodyMedium.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      ),
                    ),

                  ...groupedOrders.map(
                    (groupLines) => Padding(
                      padding: EdgeInsets.only(bottom: spacing.md),
                      child: OrderGroupCard(
                        lines: groupLines,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => OrderDetailsScreen(
                                lines: groupLines,
                              ),
                            ),
                          );
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

  // -------------------------
  // Group helpers (UI-only fix)
  // -------------------------

  List<List<OrderLine>> _groupLinesByOrder(List<OrderLine> lines) {
    final map = <String, List<OrderLine>>{};

    for (final line in lines) {
      final key = _orderKey(line);
      (map[key] ??= []).add(line);
    }

    final groups = map.values.toList();

    // Sort groups by order date DESC, then order id DESC
    groups.sort((a, b) {
      final aDate = _orderDate(a.first);
      final bDate = _orderDate(b.first);

      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      if (aDate != null) return -1;
      if (bDate != null) return 1;

      final aId = _orderId(a.first) ?? 0;
      final bId = _orderId(b.first) ?? 0;
      return bId.compareTo(aId);
    });

    return groups;
  }

  String _orderKey(OrderLine line) {
    final id = _orderId(line);
    if (id != null) return 'id_$id';

    final orderNumber = _safeGet<dynamic>(
      () => (line.order as dynamic).orderNumber,
    );
    if (orderNumber != null && orderNumber.toString().trim().isNotEmpty) {
      return 'num_${orderNumber.toString().trim()}';
    }

    // Fallback (not ideal, but prevents crashes)
    return 'line_${line.id}';
  }

  int? _orderId(OrderLine line) {
    final dynamic order = line.order;

    final v1 = _safeGet<dynamic>(() => order.id);
    if (v1 is int) return v1;
    if (v1 is num) return v1.toInt();
    if (v1 is String) return int.tryParse(v1);

    return null;
  }

  DateTime? _orderDate(OrderLine line) {
    final dynamic order = line.order;

    final d1 = _safeGet<dynamic>(() => order.createdAt);
    final parsed1 = _toDate(d1);
    if (parsed1 != null) return parsed1;

    final d2 = _safeGet<dynamic>(() => order.orderDate);
    final parsed2 = _toDate(d2);
    if (parsed2 != null) return parsed2;

    final d3 = _safeGet<dynamic>(() => order.createdDate);
    final parsed3 = _toDate(d3);
    if (parsed3 != null) return parsed3;

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

  T? _safeGet<T>(T Function() getter) {
    try {
      return getter();
    } catch (_) {
      return null;
    }
  }
}