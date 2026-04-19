import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/common/widgets/primary_button.dart';
import 'package:build4front/core/payments/stripe_payment_sheet.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/domain/entities/billing_cycle.dart';
import 'package:build4front/features/admin/licensing/domain/entities/plan_pricing.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_plan.dart';
import 'package:build4front/features/admin/licensing/presentation/bloc/upgrade_flow_bloc.dart';
import 'package:build4front/features/admin/licensing/presentation/bloc/upgrade_flow_event.dart';
import 'package:build4front/features/admin/licensing/presentation/bloc/upgrade_flow_state.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'billing_cycle_selector.dart';
import 'plan_selection_card.dart';

/// Returns the [OwnerAppAccessResponse] produced after a successful payment,
/// or `null` if the sheet was dismissed / cancelled.
Future<OwnerAppAccessResponse?> showUpgradeRequestSheet({
  required BuildContext context,
  required UpgradeFlowBloc bloc,
}) {
  return showModalBottomSheet<OwnerAppAccessResponse?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: const _UpgradeRequestSheet(),
    ),
  );
}

class _UpgradeRequestSheet extends StatefulWidget {
  const _UpgradeRequestSheet();

  @override
  State<_UpgradeRequestSheet> createState() => _UpgradeRequestSheetState();
}

class _UpgradeRequestSheetState extends State<_UpgradeRequestSheet> {
  @override
  void initState() {
    super.initState();
    context.read<UpgradeFlowBloc>().add(const UpgradePlansRequested());
  }

  double _bottomInset(BuildContext context) {
    final media = MediaQuery.of(context);
    final safe = media.viewPadding.bottom;
    final keyboard = media.viewInsets.bottom;
    return keyboard > 0 ? keyboard : safe;
  }

  Future<void> _handlePayment(UpgradeFlowState state) async {
    final l10n = AppLocalizations.of(context)!;
    final intent = state.paymentIntent;
    if (intent == null) return;

    final provider = intent.provider.toLowerCase();

    if (provider == 'stripe') {
      final pk = (intent.publishableKey ?? '').trim();
      final cs = (intent.clientSecret ?? '').trim();
      if (pk.isEmpty || cs.isEmpty) {
        context
            .read<UpgradeFlowBloc>()
            .add(UpgradePaymentFailed(l10n.upgradePaymentMissingConfig));
        return;
      }

      try {
        final result = await StripePaymentSheet.pay(
          publishableKey: pk,
          clientSecret: cs,
          merchantName: l10n.appTitle,
        );
        if (!mounted) return;
        if (result == StripePayStatus.paid) {
          context
              .read<UpgradeFlowBloc>()
              .add(UpgradePaymentSucceeded(intent.paymentIntentId));
        } else {
          context
              .read<UpgradeFlowBloc>()
              .add(UpgradePaymentFailed(l10n.upgradePaymentCanceled));
        }
      } catch (e) {
        if (!mounted) return;
        context
            .read<UpgradeFlowBloc>()
            .add(UpgradePaymentFailed(e.toString()));
      }
      return;
    }

    // Unsupported provider — surface a clear error so the backend team knows.
    context
        .read<UpgradeFlowBloc>()
        .add(UpgradePaymentFailed(l10n.upgradePaymentUnsupportedProvider));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final textTheme = Theme.of(context).textTheme;
    final inset = _bottomInset(context);

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: inset),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: BlocConsumer<UpgradeFlowBloc, UpgradeFlowState>(
              listenWhen: (prev, next) =>
                  prev.status != next.status ||
                  prev.errorMessage != next.errorMessage ||
                  prev.lastMessage != next.lastMessage,
              listener: (ctx, state) {
                if (state.status == UpgradeFlowStatus.awaitingPayment &&
                    state.paymentIntent != null) {
                  _handlePayment(state);
                }
                if (state.status == UpgradeFlowStatus.success &&
                    state.confirmedAccess != null) {
                  AppToast.success(ctx, l10n.upgradePaymentSuccess);
                  Navigator.of(ctx).pop(state.confirmedAccess);
                }
                if (state.errorMessage != null &&
                    state.errorMessage!.isNotEmpty) {
                  AppToast.error(ctx, state.errorMessage!);
                  ctx
                      .read<UpgradeFlowBloc>()
                      .add(const UpgradeFlowMessagesCleared());
                }
              },
              builder: (ctx, state) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Handle(colors: colors),
                      const SizedBox(height: 14),
                      _Header(
                        colors: colors,
                        textTheme: textTheme,
                        title: l10n.upgradeSheetTitle,
                        subtitle: l10n.upgradeSheetSubtitle,
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPlansSection(ctx, state, l10n),
                              const SizedBox(height: 14),
                              _SectionLabel(
                                text: l10n.upgradeBillingCycleLabel,
                                colors: colors,
                                textTheme: textTheme,
                              ),
                              const SizedBox(height: 8),
                              BillingCycleSelector(
                                value: state.billingCycle,
                                onChanged: (c) => ctx
                                    .read<UpgradeFlowBloc>()
                                    .add(UpgradeBillingCycleSelected(c)),
                              ),
                              const SizedBox(height: 14),
                              if (state.selectedPlanDetails != null)
                                _PricePreview(
                                  pricing:
                                      state.selectedPlanDetails!.pricing,
                                  cycle: state.billingCycle,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildCta(ctx, state, l10n),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: state.isBusy
                              ? null
                              : () => Navigator.pop(context, null),
                          child: Text(l10n.cancelLabel),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlansSection(
    BuildContext ctx,
    UpgradeFlowState state,
    AppLocalizations l10n,
  ) {
    if (state.status == UpgradeFlowStatus.loadingPlans) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (state.status == UpgradeFlowStatus.plansError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          state.errorMessage ?? l10n.upgradePlansLoadError,
          textAlign: TextAlign.center,
        ),
      );
    }
    if (state.plans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          l10n.noUpgradeAvailable,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        for (final UpgradePlan plan in state.plans)
          PlanSelectionCard(
            plan: plan,
            selected: state.selectedPlan == plan.code,
            cycle: state.billingCycle,
            onTap: plan.available
                ? () => ctx
                    .read<UpgradeFlowBloc>()
                    .add(UpgradePlanSelected(plan.code))
                : null,
          ),
      ],
    );
  }

  Widget _buildCta(
    BuildContext ctx,
    UpgradeFlowState state,
    AppLocalizations l10n,
  ) {
    final label = state.hasSelection ? l10n.payNowLabel : l10n.sendRequestLabel;
    final busy = state.isBusy;
    final canTap = state.hasSelection &&
        !busy &&
        state.status != UpgradeFlowStatus.success;

    return PrimaryButton(
      label: label,
      isLoading: busy,
      onPressed: canTap
          ? () => ctx.read<UpgradeFlowBloc>().add(const UpgradePaymentRequested())
          : null,
    );
  }
}

class _Handle extends StatelessWidget {
  final dynamic colors;
  const _Handle({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      width: 40,
      decoration: BoxDecoration(
        color: colors.border.withOpacity(0.5),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final dynamic colors;
  final TextTheme textTheme;
  final String title;
  final String subtitle;

  const _Header({
    required this.colors,
    required this.textTheme,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(.10),
                shape: BoxShape.circle,
                border: Border.all(color: colors.primary.withOpacity(.18)),
              ),
              child: Icon(Icons.upgrade, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.label,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(color: colors.body),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final dynamic colors;
  final TextTheme textTheme;

  const _SectionLabel({
    required this.text,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        style: textTheme.bodySmall?.copyWith(
          color: colors.body,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _PricePreview extends StatelessWidget {
  final PlanPricing pricing;
  final BillingCycle cycle;

  const _PricePreview({required this.pricing, required this.cycle});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final isYearly = cycle == BillingCycle.YEARLY;
    final currency = pricing.currency;
    final amount = isYearly ? pricing.effectiveYearlyPrice : pricing.monthlyPrice;
    final period = isYearly ? l10n.perYearSuffix : l10n.perMonthSuffix;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withOpacity(.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.upgradePriceLabel,
            style: textTheme.bodySmall?.copyWith(
              color: colors.body,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fmt(amount)} $currency',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.label,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  period,
                  style: textTheme.bodyMedium?.copyWith(color: colors.body),
                ),
              ),
            ],
          ),
          if (isYearly && pricing.hasYearlyDiscount) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${_fmt(pricing.yearlyPrice)} $currency',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.body,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.success.withOpacity(.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.success.withOpacity(.4)),
                  ),
                  child: Text(
                    pricing.discountLabel ??
                        (pricing.discountPercent != null
                            ? '-${pricing.discountPercent}%'
                            : l10n.upgradeYearlyDiscountBadge),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(double n) {
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(2);
  }
}
