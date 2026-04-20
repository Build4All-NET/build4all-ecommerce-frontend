import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/core/payments/stripe_payment_sheet.dart';
import 'package:build4front/features/admin/licensing/domain/entities/owner_app_access.dart';
import 'package:build4front/features/admin/licensing/presentation/bloc/upgrade_flow_bloc.dart';
import 'package:build4front/features/admin/licensing/presentation/bloc/upgrade_flow_event.dart';
import 'package:build4front/features/admin/licensing/presentation/bloc/upgrade_flow_state.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'upgrade_popup.dart';


/// Re-export the raw popup for call sites that want to use it directly
/// without the BLoC orchestration layer.
export 'upgrade_popup.dart' show UpgradePopup, showUpgradePopup;

/// Opens the upgrade popup wired to the provided [UpgradeFlowBloc].
/// Returns the refreshed [OwnerAppAccess] after a successful payment,
/// or `null` if the sheet was dismissed.
Future<OwnerAppAccess?> showUpgradeRequestSheet({
  required BuildContext context,
  required UpgradeFlowBloc bloc,
}) {
  return showModalBottomSheet<OwnerAppAccess?>(
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

    // Any other provider (cash / bank transfer / paypal / …) is a manual
    // request — the server has already created a PlanUpgradeRequest in
    // PENDING state. Tell the owner to wait for approval and close the
    // sheet so the dashboard refreshes.
    AppToast.success(context, l10n.upgradeRequestSent);
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<UpgradeFlowBloc, UpgradeFlowState>(
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
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          AppToast.error(ctx, state.errorMessage!);
          ctx
              .read<UpgradeFlowBloc>()
              .add(const UpgradeFlowMessagesCleared());
        }
      },
      builder: (ctx, state) {
        final isLoading = state.status == UpgradeFlowStatus.loadingPlans;
        final isProcessing = state.isBusy && !isLoading;
        final inlineError = state.status == UpgradeFlowStatus.plansError
            ? (state.errorMessage ?? l10n.upgradePlansLoadError)
            : null;

        return UpgradePopup(
          isLoading: isLoading,
          isProcessing: isProcessing,
          plans: state.plans,
          initialSelectedPlan: state.selectedPlan,
          initialBillingCycle: state.billingCycle,
          paymentMethods: state.availablePaymentMethods,
          selectedPaymentMethodCode: state.selectedPaymentMethodCode,
          errorMessage: inlineError,
          onSelectionChanged: (plan, cycle) {
            if (cycle != state.billingCycle) {
              ctx
                  .read<UpgradeFlowBloc>()
                  .add(UpgradeBillingCycleSelected(cycle));
            }
            if (plan != null && plan != state.selectedPlan) {
              ctx.read<UpgradeFlowBloc>().add(UpgradePlanSelected(plan));
            }
          },
          onPaymentMethodSelected: (code) => ctx
              .read<UpgradeFlowBloc>()
              .add(UpgradePaymentMethodSelected(code)),
          onPayNow: (_, __) => ctx
              .read<UpgradeFlowBloc>()
              .add(const UpgradePaymentRequested()),
          onClose: () => Navigator.of(ctx).pop(null),
        );
      },
    );
  }
}

