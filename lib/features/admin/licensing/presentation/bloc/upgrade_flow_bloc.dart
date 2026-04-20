import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:build4front/features/admin/licensing/domain/usecases/confirm_upgrade_payment.dart';
import 'package:build4front/features/admin/licensing/domain/usecases/get_available_payment_methods.dart';
import 'package:build4front/features/admin/licensing/domain/usecases/get_available_upgrade_plans.dart';
import 'package:build4front/features/admin/licensing/domain/usecases/initiate_upgrade_payment.dart';
import 'package:build4front/features/admin/licensing/domain/usecases/refresh_owner_subscription.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'upgrade_flow_event.dart';
import 'upgrade_flow_state.dart';

class UpgradeFlowBloc extends Bloc<UpgradeFlowEvent, UpgradeFlowState> {
  final GetAvailableUpgradePlans getPlansUc;
  final GetAvailablePaymentMethods getPaymentMethodsUc;
  final InitiateUpgradePayment initiatePaymentUc;
  final ConfirmUpgradePayment confirmPaymentUc;
  final RefreshOwnerSubscription refreshSubscriptionUc;

  UpgradeFlowBloc({
    required this.getPlansUc,
    required this.getPaymentMethodsUc,
    required this.initiatePaymentUc,
    required this.confirmPaymentUc,
    required this.refreshSubscriptionUc,
  }) : super(UpgradeFlowState.initial()) {
    on<UpgradePlansRequested>(_onPlansRequested);
    on<UpgradePlanSelected>(_onPlanSelected);
    on<UpgradeBillingCycleSelected>(_onCycleSelected);
    on<UpgradePaymentMethodSelected>(_onPaymentMethodSelected);
    on<UpgradePaymentRequested>(_onPaymentRequested);
    on<UpgradePaymentSucceeded>(_onPaymentSucceeded);
    on<UpgradePaymentFailed>(_onPaymentFailed);
    on<UpgradeFlowReset>(_onReset);
    on<UpgradeFlowMessagesCleared>(_onMessagesCleared);
  }

  Future<void> _onPlansRequested(
    UpgradePlansRequested event,
    Emitter<UpgradeFlowState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: UpgradeFlowStatus.loadingPlans,
        errorMessage: null,
        lastMessage: null,
      ));

      final results = await Future.wait([
        getPlansUc(),
        getPaymentMethodsUc(),
      ]);

      final plans = results[0] as dynamic;
      final methods = results[1] as dynamic;

      final autoSelected = (methods.length == 1)
          ? (methods.first.selectionCode as String)
          : null;

      emit(state.copyWith(
        status: UpgradeFlowStatus.plansReady,
        plans: plans,
        availablePaymentMethods: methods,
        selectedPaymentMethodCode: autoSelected,
        errorMessage: null,
        lastMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UpgradeFlowStatus.plansError,
        errorMessage: ExceptionMapper.toMessage(e),
        lastMessage: null,
      ));
    }
  }

  void _onPlanSelected(
    UpgradePlanSelected event,
    Emitter<UpgradeFlowState> emit,
  ) {
    emit(state.copyWith(selectedPlan: event.planCode));
  }

  void _onCycleSelected(
    UpgradeBillingCycleSelected event,
    Emitter<UpgradeFlowState> emit,
  ) {
    emit(state.copyWith(billingCycle: event.cycle));
  }

  void _onPaymentMethodSelected(
    UpgradePaymentMethodSelected event,
    Emitter<UpgradeFlowState> emit,
  ) {
    emit(state.copyWith(selectedPaymentMethodCode: event.code));
  }

  Future<void> _onPaymentRequested(
    UpgradePaymentRequested event,
    Emitter<UpgradeFlowState> emit,
  ) async {
    print('[UpgradeFlowBloc] UpgradePaymentRequested received. '
        'state.selectedPlan=${state.selectedPlan} '
        'state.methodCode=${state.selectedPaymentMethodCode} '
        'state.billingCycle=${state.billingCycle}');

    final plan = state.selectedPlan;
    if (plan == null) {
      emit(state.copyWith(
        status: UpgradeFlowStatus.error,
        errorMessage: 'Please select a plan.',
        lastMessage: null,
      ));
      return;
    }

    final methodCode = state.selectedPaymentMethodCode;
    if (methodCode == null || methodCode.isEmpty) {
      emit(state.copyWith(
        status: UpgradeFlowStatus.error,
        errorMessage: 'Please select a payment method.',
        lastMessage: null,
      ));
      return;
    }

    try {
      emit(state.copyWith(
        status: UpgradeFlowStatus.initiatingPayment,
        errorMessage: null,
        lastMessage: null,
        clearPaymentIntent: true,
        clearPaymentReceipt: true,
        clearConfirmedAccess: true,
      ));

      final intent = await initiatePaymentUc(
        InitiateUpgradePaymentParams(
          planCode: plan,
          billingCycle: state.billingCycle,
          paymentMethodCode: methodCode,
        ),
      );

      print('[UpgradeFlowBloc] initiatePaymentUc OK: '
          'provider=${intent.provider} id=${intent.paymentIntentId}');

      // ✅ Unified flow:
      // Stripe and manual providers both move to awaitingPayment.
      // The sheet decides what to do based on intent.provider.
      emit(state.copyWith(
        status: UpgradeFlowStatus.awaitingPayment,
        paymentIntent: intent,
        errorMessage: null,
        lastMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UpgradeFlowStatus.error,
        errorMessage: ExceptionMapper.toMessage(e),
        lastMessage: null,
      ));
    }
  }

  Future<void> _onPaymentSucceeded(
    UpgradePaymentSucceeded event,
    Emitter<UpgradeFlowState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: UpgradeFlowStatus.confirmingPayment,
        errorMessage: null,
        lastMessage: null,
      ));

      final receipt = await confirmPaymentUc(
        paymentIntentId: event.paymentIntentId,
      );

      emit(state.copyWith(
        status: UpgradeFlowStatus.success,
        paymentReceipt: receipt,
        confirmedAccess: receipt.access,
        errorMessage: null,
        lastMessage: 'upgrade_payment_success',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UpgradeFlowStatus.error,
        errorMessage: ExceptionMapper.toMessage(e),
        lastMessage: null,
      ));
    }
  }

  void _onPaymentFailed(
    UpgradePaymentFailed event,
    Emitter<UpgradeFlowState> emit,
  ) {
    emit(state.copyWith(
      status: UpgradeFlowStatus.error,
      errorMessage: event.message,
      lastMessage: null,
    ));
  }

  void _onReset(
    UpgradeFlowReset event,
    Emitter<UpgradeFlowState> emit,
  ) {
    emit(UpgradeFlowState.initial());
  }

  void _onMessagesCleared(
    UpgradeFlowMessagesCleared event,
    Emitter<UpgradeFlowState> emit,
  ) {
    emit(state.copyWith(
      errorMessage: null,
      lastMessage: null,
    ));
  }
}