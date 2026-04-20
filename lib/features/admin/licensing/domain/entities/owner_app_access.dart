import 'plan_code.dart';
import 'subscription_status.dart';

/// Pure domain entity describing an owner's current license / access
/// snapshot. JSON parsing lives in the data layer —
/// see `data/models/owner_app_access_response.dart`.
class OwnerAppAccess {
  final bool canAccessDashboard;
  final String? blockingReason;

  final PlanCode? planCode;
  final String? planName;

  final SubscriptionStatus? subscriptionStatus;
  final String? periodEnd;
  final int daysLeft;

  final int? usersAllowed;
  final int activeUsers;
  final int? usersRemaining;

  final bool requiresDedicatedServer;
  final bool dedicatedInfraReady;

  // Upgrade request state (latest request)
  final String? upgradeRequestStatus; // PENDING / APPROVED / REJECTED / null
  final PlanCode? upgradeRequestedPlan;
  final String? upgradeRequestedAt;
  final String? upgradeDecisionNote;

  const OwnerAppAccess({
    required this.canAccessDashboard,
    required this.blockingReason,
    required this.planCode,
    required this.planName,
    required this.subscriptionStatus,
    required this.periodEnd,
    required this.daysLeft,
    required this.usersAllowed,
    required this.activeUsers,
    required this.usersRemaining,
    required this.requiresDedicatedServer,
    required this.dedicatedInfraReady,
    required this.upgradeRequestStatus,
    required this.upgradeRequestedPlan,
    required this.upgradeRequestedAt,
    required this.upgradeDecisionNote,
  });

  bool get hasPendingUpgradeRequest =>
      (upgradeRequestStatus ?? '').toUpperCase() == 'PENDING';
}
