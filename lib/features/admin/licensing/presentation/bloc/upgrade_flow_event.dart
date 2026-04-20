import 'package:build4front/features/admin/licensing/domain/entities/plan_code.dart';
import 'package:build4front/features/admin/licensing/domain/entities/billing_cycle.dart';
import 'package:equatable/equatable.dart';

abstract class UpgradeFlowEvent extends Equatable {
  const UpgradeFlowEvent();

  @override
  List<Object?> get props => [];
}

class UpgradePlansRequested extends UpgradeFlowEvent {
  const UpgradePlansRequested();
}

class UpgradePlanSelected extends UpgradeFlowEvent {
  final PlanCode planCode;
  const UpgradePlanSelected(this.planCode);

  @override
  List<Object?> get props => [planCode];
}

class UpgradeBillingCycleSelected extends UpgradeFlowEvent {
  final BillingCycle cycle;
  const UpgradeBillingCycleSelected(this.cycle);

  @override
  List<Object?> get props => [cycle];
}

class UpgradePaymentMethodSelected extends UpgradeFlowEvent {
  final String code;
  const UpgradePaymentMethodSelected(this.code);

  @override
  List<Object?> get props => [code];
}

class UpgradePaymentRequested extends UpgradeFlowEvent {
  const UpgradePaymentRequested();
}

class UpgradePaymentSucceeded extends UpgradeFlowEvent {
  final String paymentIntentId;
  const UpgradePaymentSucceeded(this.paymentIntentId);

  @override
  List<Object?> get props => [paymentIntentId];
}

class UpgradePaymentFailed extends UpgradeFlowEvent {
  final String message;
  const UpgradePaymentFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class UpgradeFlowReset extends UpgradeFlowEvent {
  const UpgradeFlowReset();
}

class UpgradeFlowMessagesCleared extends UpgradeFlowEvent {
  const UpgradeFlowMessagesCleared();
}
