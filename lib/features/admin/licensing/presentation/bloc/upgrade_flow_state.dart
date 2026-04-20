import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/domain/entities/available_payment_method.dart';
import 'package:build4front/features/admin/licensing/domain/entities/billing_cycle.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_payment_confirmation.dart';
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
  final List<AvailablePaymentMethod> availablePaymentMethods;
  final String? selectedPaymentMethodCode;
  final UpgradePaymentIntent? paymentIntent;
  final UpgradePaymentConfirmation? paymentReceipt;
  final OwnerAppAccessResponse? confirmedAccess;
  final String? errorMessage;
  final String? lastMessage;

  const UpgradeFlowState({
    required this.status,
    required this.plans,
    required this.selectedPlan,
    required this.billingCycle,
    required this.availablePaymentMethods,
    required this.selectedPaymentMethodCode,
    required this.paymentIntent,
    required this.paymentReceipt,
    required this.confirmedAccess,
    required this.errorMessage,
    required this.lastMessage,
  });

  factory UpgradeFlowState.initial() => const UpgradeFlowState(
        status: UpgradeFlowStatus.idle,
        plans: [],
        selectedPlan: null,
        billingCycle: BillingCycle.MONTHLY,
        availablePaymentMethods: [],
        selectedPaymentMethodCode: null,
        paymentIntent: null,
        paymentReceipt: null,
        confirmedAccess: null,
        errorMessage: null,
        lastMessage: null,
      );

  /// Ready to tap Pay Now — owner has picked both a plan and a payment method.
  bool get hasSelection =>
      selectedPlan != null &&
      selectedPaymentMethodCode != null &&
      selectedPaymentMethodCode!.isNotEmpty;

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

  /// Amount currently shown on the CTA / preview, derived from the selected
  /// plan + cycle. Returns `null` when no plan is selected.
  double? get displayedAmount {
    final details = selectedPlanDetails;
    if (details == null) return null;
    return billingCycle == BillingCycle.YEARLY
        ? details.pricing.effectiveYearlyPrice
        : details.pricing.monthlyPrice;
  }

  String? get displayedCurrency => selectedPlanDetails?.pricing.currency;

  UpgradeFlowState copyWith({
    UpgradeFlowStatus? status,
    List<UpgradePlan>? plans,
    PlanCode? selectedPlan,
    bool clearSelectedPlan = false,
    BillingCycle? billingCycle,
    List<AvailablePaymentMethod>? availablePaymentMethods,
    String? selectedPaymentMethodCode,
    bool clearSelectedPaymentMethod = false,
    UpgradePaymentIntent? paymentIntent,
    bool clearPaymentIntent = false,
    UpgradePaymentConfirmation? paymentReceipt,
    bool clearPaymentReceipt = false,
    OwnerAppAccessResponse? confirmedAccess,
    bool clearConfirmedAccess = false,
    String? errorMessage,
    String? lastMessage,
  }) {
    return UpgradeFlowState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      selectedPlan:
          clearSelectedPlan ? null : (selectedPlan ?? this.selectedPlan),
      billingCycle: billingCycle ?? this.billingCycle,
      availablePaymentMethods:
          availablePaymentMethods ?? this.availablePaymentMethods,
      selectedPaymentMethodCode: clearSelectedPaymentMethod
          ? null
          : (selectedPaymentMethodCode ?? this.selectedPaymentMethodCode),
      paymentIntent:
          clearPaymentIntent ? null : (paymentIntent ?? this.paymentIntent),
      paymentReceipt:
          clearPaymentReceipt ? null : (paymentReceipt ?? this.paymentReceipt),
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
        availablePaymentMethods,
        selectedPaymentMethodCode,
        paymentIntent,
        paymentReceipt,
        confirmedAccess,
        errorMessage,
        lastMessage,
      ];
}
