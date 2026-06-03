import 'plan_code.dart';
import 'subscription_status.dart';

/// One purchased-but-not-yet-started paid plan in the owner's queue. Multiple
/// stacked upgrades (e.g. Basic then Smart) are listed soonest first.
class UpcomingPlan {
  final PlanCode? planCode;
  final String? planName;
  final String? periodStart;
  final String? periodEnd;

  const UpcomingPlan({
    this.planCode,
    this.planName,
    this.periodStart,
    this.periodEnd,
  });
}

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

  // Upcoming (stacked) plan scheduled to start when the current period ends.
  // Null when no plan is queued. (Legacy singular fields — first queued plan.)
  final PlanCode? upcomingPlanCode;
  final String? upcomingPlanName;
  final String? upcomingPlanStart;
  final String? upcomingPeriodEnd;

  // Full queue of purchased-but-not-yet-started paid plans, soonest first.
  final List<UpcomingPlan> upcomingPlans;

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
    this.upcomingPlanCode,
    this.upcomingPlanName,
    this.upcomingPlanStart,
    this.upcomingPeriodEnd,
    this.upcomingPlans = const [],
  });

  bool get hasPendingUpgradeRequest =>
      (upgradeRequestStatus ?? '').toUpperCase() == 'PENDING';

  /// The owner is locked out of the dashboard because they have no usable
  /// license (e.g. every license was canceled, or it expired). In this state
  /// the owner MUST be able to (re)start the pay/upgrade flow to resume — even
  /// if a stale upgrade request is still marked PENDING.
  ///
  /// Excludes "soft" blocks that paying a new plan doesn't resolve
  /// (user-limit reached, dedicated infra not yet assigned).
  bool get isLicenseBlocked {
    if (canAccessDashboard != false) return false;
    final r = (blockingReason ?? '').trim().toUpperCase();
    return r != 'USER_LIMIT_REACHED' && r != 'DEDICATED_SERVER_NOT_ASSIGNED';
  }

  bool get hasUpcomingPlan =>
      upcomingPlans.isNotEmpty ||
      upcomingPlanCode != null ||
      (upcomingPlanName ?? '').trim().isNotEmpty;
}
