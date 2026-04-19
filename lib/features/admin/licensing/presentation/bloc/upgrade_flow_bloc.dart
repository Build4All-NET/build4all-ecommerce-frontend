import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:build4front/features/admin/licensing/domain/usecases/confirm_upgrade_payment.dart';
import 'package:build4front/features/admin/licensing/domain/usecases/get_available_upgrade_plans.dart';
import 'package:build4front/features/admin/licensing/domain/usecases/initiate_upgrade_payment.dart';
import 'package:build4front/features/admin/licensing/domain/usecases/refresh_owner_subscription.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'upgrade_flow_event.dart';
import 'upgrade_flow_state.dart';

class UpgradeFlowBloc extends Bloc<UpgradeFlowEvent, UpgradeFlowState> {
  final GetAvailableUpgradePlans getPlansUc;
  final InitiateUpgradePayment initiatePaymentUc;
  final ConfirmUpgradePayment confirmPaymentUc;
  final RefreshOwnerSubscription refreshSubscriptionUc;

  UpgradeFlowBloc({
    required this.getPlansUc,
    required this.initiatePaymentUc,
    required this.confirmPaymentUc,
    required this.refreshSubscriptionUc,
  }) : super(UpgradeFlowState.initial()) {
    on<UpgradePlansRequested>(_onPlansRequested);
    on<UpgradePlanSelected>(_onPlanSelected);
    on<UpgradeBillingCycleSelected>(_onCycleSelected);
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
      final plans = await getPlansUc();
      emit(state.copyWith(
        status: UpgradeFlowStatus.plansReady,
        plans: plans,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UpgradeFlowStatus.plansError,
        errorMessage: ExceptionMapper.toMessage(e),
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

  Future<void> _onPaymentRequested(
    UpgradePaymentRequested event,
    Emitter<UpgradeFlowState> emit,
  ) async {
    final plan = state.selectedPlan;
    if (plan == null) {
      emit(state.copyWith(
        status: UpgradeFlowStatus.error,
        errorMessage: 'Please select a plan.',
      ));
      return;
    }

    try {
      emit(state.copyWith(
        status: UpgradeFlowStatus.initiatingPayment,
        errorMessage: null,
        lastMessage: null,
      ));

      final intent = await initiatePaymentUc(
        InitiateUpgradePaymentParams(
          planCode: plan,
          billingCycle: state.billingCycle,
        ),
      );

      emit(state.copyWith(
        status: UpgradeFlowStatus.awaitingPayment,
        paymentIntent: intent,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UpgradeFlowStatus.error,
        errorMessage: ExceptionMapper.toMessage(e),
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
      ));

      final access = await confirmPaymentUc(
        paymentIntentId: event.paymentIntentId,
      );

      emit(state.copyWith(
        status: UpgradeFlowStatus.success,
        confirmedAccess: access,
        lastMessage: 'upgrade_payment_success',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UpgradeFlowStatus.error,
        errorMessage: ExceptionMapper.toMessage(e),
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
    emit(state.copyWith(errorMessage: null, lastMessage: null));
  }
}
