import 'package:build4front/features/checkout/domain/entities/checkout_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

class CheckoutPaymentMethods extends StatelessWidget {
  final List<PaymentMethod> methods;

  // ✅ select ONE by index (unique)
  final int? selectedIndex;
  final ValueChanged<int> onSelectIndex;

  const CheckoutPaymentMethods({
    super.key,
    required this.methods,
    required this.selectedIndex,
    required this.onSelectIndex,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final spacing = tokens.spacing;
    final colors = tokens.colors;

    final themed = Theme.of(context).copyWith(
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return colors.primary;
          return colors.muted;
        }),
      ),
      unselectedWidgetColor: colors.muted,
    );

    // ✅ DB only: no fallback CASH
    if (methods.isEmpty) {
      return Text(
        l10n.checkoutSelectPayment,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.muted),
      );
    }

    return Column(
      children: [
        ...List.generate(methods.length, (i) {
          final m = methods[i];
          final selected = (i == selectedIndex);

          return Container(
            margin: EdgeInsets.only(bottom: spacing.xs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? colors.primary.withOpacity(0.55)
                    : colors.border.withOpacity(0.2),
              ),
            ),
            child: Theme(
              data: themed,
              child: RadioListTile<int>(
                value: i, // ✅ unique
                groupValue: selectedIndex,
                onChanged: (v) {
                  if (v != null) onSelectIndex(v);
                },
                // m.name now carries the buyer-facing displayName from the
                // gateway plugin (e.g. MPGS → "Card"). The technical code
                // (m.code) is intentionally not shown — it's developer
                // jargon and confused buyers seeing "MPGS / MPGS".
                title: Text(m.name),
                contentPadding: EdgeInsets.symmetric(horizontal: spacing.sm),
                dense: true,
              ),
            ),
          );
        }),
        SizedBox(height: spacing.sm),
        Text(
          l10n.checkoutStripeNote,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}
