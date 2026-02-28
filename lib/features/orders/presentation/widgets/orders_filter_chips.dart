import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';

class OrdersFilterChips extends StatelessWidget {
  const OrdersFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final spacing = tokens.spacing;
    final colors = tokens.colors;

    return BlocBuilder<OrdersBloc, OrdersState>(
      buildWhen: (p, c) => p.filter != c.filter,
      builder: (context, state) {
        Widget chip(String label, OrdersFilter f) {
          final selected = state.filter == f;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) =>
                context.read<OrdersBloc>().add(OrdersFilterChanged(f)),
            selectedColor: colors.primary.withOpacity(0.18),
            labelStyle: tokens.typography.bodySmall.copyWith(
              color: selected ? colors.primary : colors.body,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            shape: StadiumBorder(
              side: BorderSide(color: colors.border.withOpacity(0.35)),
            ),
            backgroundColor: colors.surface,
          );
        }

        return Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            chip(l10n.ordersFilterAll, OrdersFilter.all),
            chip(l10n.ordersFilterPending, OrdersFilter.pending),
            chip(l10n.ordersFilterCompleted, OrdersFilter.completed),
            chip(l10n.ordersFilterCanceled, OrdersFilter.canceled),
          ],
        );
      },
    );
  }
}