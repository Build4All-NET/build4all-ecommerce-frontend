import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/core/payments/stripe_payment_sheet.dart';
import 'package:build4front/features/admin/licensing/domain/entities/owner_app_access.dart';
import 'package:build4front/features/admin/licensing/presentation/bloc/upgrade_flow_bloc.dart';
import 'package:build4front/features/admin/licensing/presentation/bloc/upgrade_flow_event.dart';
import 'package:build4front/features/admin/licensing/presentation/bloc/upgrade_flow_state.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'upgrade_popup.dart';

export 'upgrade_popup.dart' show UpgradePopup, showUpgradePopup;

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
  bool _manualRequestHandled = false;
  bool _stripeHandled = false;
  bool _paypalHandled = false;
  bool _pendingHandled = false;
  bool _successHandled = false;

  @override
  void initState() {
    super.initState();
    context.read<UpgradeFlowBloc>().add(const UpgradePlansRequested());
  }

  Future<void> _closeWithRefresh({
    required String toastMessage,
    bool isErrorToast = false,
  }) async {
    final bloc = context.read<UpgradeFlowBloc>();

    try {
      final refreshed = await bloc.refreshSubscriptionUc();
      if (!mounted) return;

      if (isErrorToast) {
        AppToast.error(context, toastMessage);
      } else {
        AppToast.success(context, toastMessage);
      }

      Navigator.of(context).pop(refreshed);
    } catch (_) {
      if (!mounted) return;

      if (isErrorToast) {
        AppToast.error(context, toastMessage);
      } else {
        AppToast.success(context, toastMessage);
      }

      Navigator.of(context).pop(null);
    }
  }

  Future<void> _handleStripePayment(UpgradeFlowState state) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<UpgradeFlowBloc>();
    final intent = state.paymentIntent;

    if (intent == null) return;
    if (_stripeHandled) return;
    _stripeHandled = true;

    final pk = (intent.publishableKey ?? '').trim();
    final cs = (intent.clientSecret ?? '').trim();

    if (pk.isEmpty || cs.isEmpty) {
      bloc.add(UpgradePaymentFailed(l10n.upgradePaymentMissingConfig));
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
        bloc.add(UpgradePaymentSucceeded(intent.paymentIntentId));
      } else {
        bloc.add(UpgradePaymentFailed(l10n.upgradePaymentCanceled));
      }
    } catch (e) {
      if (!mounted) return;
      bloc.add(UpgradePaymentFailed(e.toString()));
    }
  }

  Future<void> _handlePaypalPayment(UpgradeFlowState state) async {
    if (_paypalHandled) return;
    _paypalHandled = true;

    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<UpgradeFlowBloc>();
    final intent = state.paymentIntent;

    if (intent == null) return;

    final approval = (intent.checkoutUrl ?? '').trim();
    if (approval.isEmpty) {
      bloc.add(UpgradePaymentFailed(l10n.upgradePaymentMissingConfig));
      return;
    }

    // Open PayPal approval URL in the external browser. Then prompt the
    // owner to confirm once they've completed the PayPal flow so we can
    // capture the order server-side.
    final uri = Uri.tryParse(approval);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // Fall through to the dialog — the user may still have another
        // way to open it, and we still want to offer confirm/cancel.
      }
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Complete PayPal payment'),
          content: const Text(
              "We've opened PayPal in your browser. "
              'After you finish paying, come back here and tap '
              '"I\'ve paid" so we can activate your plan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("I've paid"),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmed == true) {
      bloc.add(UpgradePaymentSucceeded(intent.paymentIntentId));
    } else {
      bloc.add(UpgradePaymentFailed(l10n.upgradePaymentCanceled));
    }
  }

  Future<void> _handleManualSuccess() async {
    if (_manualRequestHandled) return;
    _manualRequestHandled = true;

    final l10n = AppLocalizations.of(context)!;
    await _closeWithRefresh(
      toastMessage: l10n.upgradeRequestSent,
    );
  }

  Future<void> _handleAlreadyPending() async {
    if (_pendingHandled) return;
    _pendingHandled = true;

    final l10n = AppLocalizations.of(context)!;
    await _closeWithRefresh(
      toastMessage: l10n.upgradeRequestPending,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<UpgradeFlowBloc, UpgradeFlowState>(
      listenWhen: (prev, next) =>
          prev.status != next.status ||
          prev.errorMessage != next.errorMessage ||
          prev.lastMessage != next.lastMessage ||
          prev.paymentIntent != next.paymentIntent ||
          prev.confirmedAccess != next.confirmedAccess,
      listener: (ctx, state) async {
        final provider = state.paymentIntent?.provider.toLowerCase().trim();

        // 1) Stripe payment sheet
        if (state.status == UpgradeFlowStatus.awaitingPayment &&
            state.paymentIntent != null &&
            provider == 'stripe') {
          await _handleStripePayment(state);
          return;
        }

        // 2) PayPal approval URL → external browser → "I've paid" confirm
        if (state.status == UpgradeFlowStatus.awaitingPayment &&
            state.paymentIntent != null &&
            provider == 'paypal') {
          await _handlePaypalPayment(state);
          return;
        }

        // 3) Manual provider reached awaitingPayment
        if (state.status == UpgradeFlowStatus.awaitingPayment &&
            state.paymentIntent != null &&
            provider != null &&
            provider != 'stripe' &&
            provider != 'paypal') {
          await _handleManualSuccess();
          return;
        }

        // 4) Manual provider reached success without confirmedAccess
        if (state.status == UpgradeFlowStatus.success &&
            provider != null &&
            provider != 'stripe' &&
            provider != 'paypal' &&
            state.confirmedAccess == null) {
          await _handleManualSuccess();
          return;
        }

        // 5) Paid-provider success after confirm (Stripe or PayPal)
        if (state.status == UpgradeFlowStatus.success &&
            state.confirmedAccess != null) {
          if (_successHandled) return;
          _successHandled = true;

          AppToast.success(ctx, l10n.upgradePaymentSuccess);
          Navigator.of(ctx).pop(state.confirmedAccess);
          return;
        }

        // 5) Backend says request/payment already pending
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          final msg = state.errorMessage!.toLowerCase().trim();

          if (msg.contains('already pending')) {
            await _handleAlreadyPending();
            ctx.read<UpgradeFlowBloc>().add(const UpgradeFlowMessagesCleared());
            return;
          }

          AppToast.error(ctx, state.errorMessage!);
          ctx.read<UpgradeFlowBloc>().add(const UpgradeFlowMessagesCleared());
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
          onPaymentMethodSelected: (code) {
            ctx
                .read<UpgradeFlowBloc>()
                .add(UpgradePaymentMethodSelected(code));
          },
          onPayNow: (_, __) {
            ctx.read<UpgradeFlowBloc>().add(const UpgradePaymentRequested());
          },
          onClose: () => Navigator.of(ctx).pop(null),
        );
      },
    );
  }
}