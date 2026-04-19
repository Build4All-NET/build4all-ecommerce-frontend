import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/domain/entities/billing_cycle.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_plan.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlanSelectionCard extends StatelessWidget {
  final UpgradePlan plan;
  final bool selected;
  final BillingCycle cycle;
  final VoidCallback? onTap;

  const PlanSelectionCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.cycle,
    required this.onTap,
  });

  String _fmt(double n) {
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(2);
  }

  String _titleFor(AppLocalizations l10n, PlanCode code) {
    switch (code) {
      case PlanCode.FREE:
        return l10n.planFree;
      case PlanCode.PRO_HOSTEDB:
        return l10n.planProHostedDb;
      case PlanCode.DEDICATED:
        return l10n.planDedicated;
    }
  }

  String _descFor(AppLocalizations l10n, PlanCode code) {
    switch (code) {
      case PlanCode.FREE:
        return '';
      case PlanCode.PRO_HOSTEDB:
        return l10n.planProHostedDbDesc;
      case PlanCode.DEDICATED:
        return l10n.planDedicatedDesc;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final title = (plan.title?.isNotEmpty ?? false)
        ? plan.title!
        : _titleFor(l10n, plan.code);
    final description = (plan.description?.isNotEmpty ?? false)
        ? plan.description!
        : _descFor(l10n, plan.code);

    final pricing = plan.pricing;
    final isYearly = cycle == BillingCycle.YEARLY;
    final price =
        isYearly ? pricing.effectiveYearlyPrice : pricing.monthlyPrice;
    final currency = pricing.currency;
    final disabled = !plan.available || onTap == null;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? colors.primary.withOpacity(.08) : colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? colors.primary.withOpacity(.35)
                  : colors.border.withOpacity(.20),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? colors.primary : colors.body,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.label,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: textTheme.bodySmall?.copyWith(color: colors.body),
                      ),
                    ],
                    if (!plan.available && plan.unavailableReason != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        plan.unavailableReason!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_fmt(price)} $currency',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.label,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (isYearly && pricing.hasYearlyDiscount)
                    Text(
                      '${_fmt(pricing.yearlyPrice)} $currency',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.body,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
