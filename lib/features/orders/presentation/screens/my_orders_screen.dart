import 'package:build4front/features/orders/presentation/screens/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/common/widgets/primary_button.dart';

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

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
    super.build(context);

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

            final orders = state.filtered;

            if (state.orders.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(spacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 46, color: colors.muted),
                      SizedBox(height: spacing.sm),
                      Text(
                        l10n.ordersEmptyTitle,
                        style: tokens.typography.titleMedium
                            .copyWith(color: colors.label),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing.xs),
                      Text(
                        l10n.ordersEmptyBody,
                        style: tokens.typography.bodyMedium
                            .copyWith(color: colors.body),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing.lg),
                      PrimaryButton(
                        label: l10n.ordersReload,
                        onPressed: () => context
                            .read<OrdersBloc>()
                            .add(const OrdersStarted()),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<OrdersBloc>()
                    .add(const OrdersRefreshRequested());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(spacing.md),
                children: [
                  const OrdersFilterChips(),
                  SizedBox(height: spacing.md),
                  if (orders.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: spacing.lg),
                      child: Center(
                        child: Text(
                          l10n.ordersNoResultsForFilter,
                          style: tokens.typography.bodyMedium
                              .copyWith(color: colors.muted),
                        ),
                      ),
                    ),
                  ...orders.map(
                    (o) => Padding(
                      padding: EdgeInsets.only(bottom: spacing.md),
                      child: OrderGroupCard(
                        order: o,
                        onTap: () {
                          // ✅ Safety: never call details with 0
                          if (o.orderId <= 0) {
                            AppToast.show(
                              context,
                              'Order details not available (missing orderId from API).',
                              isError: true,
                            );
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  OrderDetailsScreen(orderId: o.orderId),
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
}