import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/domain/entities/billing_cycle.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_payment_intent.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_plan.dart';
import 'package:equatable/equatable.dart';

enum UpgradeFlowStatus {
  idle,
  loadingPlans,
  plansReady,
  plansError,
  initiatingPayment,
  awaitingPayment,
  confirmingPayment,
  success,
  error,
}

class UpgradeFlowState extends Equatable {
  final UpgradeFlowStatus status;
  final List<UpgradePlan> plans;
  final PlanCode? selectedPlan;
  final BillingCycle billingCycle;
  final UpgradePaymentIntent? paymentIntent;
  final OwnerAppAccessResponse? confirmedAccess;
  final String? errorMessage;
  final String? lastMessage;

  const UpgradeFlowState({
    required this.status,
    required this.plans,
    required this.selectedPlan,
    required this.billingCycle,
    required this.paymentIntent,
    required this.confirmedAccess,
    required this.errorMessage,
    required this.lastMessage,
  });

  factory UpgradeFlowState.initial() => const UpgradeFlowState(
        status: UpgradeFlowStatus.idle,
        plans: [],
        selectedPlan: null,
        billingCycle: BillingCycle.MONTHLY,
        paymentIntent: null,
        confirmedAccess: null,
        errorMessage: null,
        lastMessage: null,
      );

  bool get hasSelection => selectedPlan != null;

  bool get isBusy =>
      status == UpgradeFlowStatus.loadingPlans ||
      status == UpgradeFlowStatus.initiatingPayment ||
      status == UpgradeFlowStatus.awaitingPayment ||
      status == UpgradeFlowStatus.confirmingPayment;

  UpgradePlan? get selectedPlanDetails {
    if (selectedPlan == null) return null;
    for (final p in plans) {
      if (p.code == selectedPlan) return p;
    }
    return null;
  }

  UpgradeFlowState copyWith({
    UpgradeFlowStatus? status,
    List<UpgradePlan>? plans,
    PlanCode? selectedPlan,
    bool clearSelectedPlan = false,
    BillingCycle? billingCycle,
    UpgradePaymentIntent? paymentIntent,
    bool clearPaymentIntent = false,
    OwnerAppAccessResponse? confirmedAccess,
    bool clearConfirmedAccess = false,
    String? errorMessage,
    String? lastMessage,
  }) {
    return UpgradeFlowState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      selectedPlan: clearSelectedPlan ? null : (selectedPlan ?? this.selectedPlan),
      billingCycle: billingCycle ?? this.billingCycle,
      paymentIntent:
          clearPaymentIntent ? null : (paymentIntent ?? this.paymentIntent),
      confirmedAccess: clearConfirmedAccess
          ? null
          : (confirmedAccess ?? this.confirmedAccess),
      errorMessage: errorMessage,
      lastMessage: lastMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        plans,
        selectedPlan,
        billingCycle,
        paymentIntent,
        confirmedAccess,
        errorMessage,
        lastMessage,
      ];
}
