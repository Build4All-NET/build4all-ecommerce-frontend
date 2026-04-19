import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/features/admin/licensing/domain/entities/billing_cycle.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BillingCycleSelector extends StatelessWidget {
  final BillingCycle value;
  final ValueChanged<BillingCycle> onChanged;

  const BillingCycleSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border.withOpacity(.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segment(
              context: context,
              colors: colors,
              textTheme: textTheme,
              label: l10n.billingCycleMonthly,
              isActive: value == BillingCycle.MONTHLY,
              onTap: () => onChanged(BillingCycle.MONTHLY),
            ),
          ),
          Expanded(
            child: _segment(
              context: context,
              colors: colors,
              textTheme: textTheme,
              label: l10n.billingCycleYearly,
              isActive: value == BillingCycle.YEARLY,
              onTap: () => onChanged(BillingCycle.YEARLY),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required BuildContext context,
    required dynamic colors,
    required TextTheme textTheme,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: isActive ? colors.onPrimary : colors.label,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
