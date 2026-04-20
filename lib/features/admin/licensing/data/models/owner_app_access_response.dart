import 'package:build4front/features/admin/licensing/domain/entities/owner_app_access.dart';
import 'package:build4front/features/admin/licensing/domain/entities/plan_code.dart';
import 'package:build4front/features/admin/licensing/domain/entities/subscription_status.dart';

// Re-export the domain entities so existing data-layer call sites that
// rely on `PlanCode` / `SubscriptionStatus` / `OwnerAppAccess` via this
// model file keep compiling. Domain and presentation code should import
// the domain entities directly, not this file.
export 'package:build4front/features/admin/licensing/domain/entities/owner_app_access.dart';
export 'package:build4front/features/admin/licensing/domain/entities/plan_code.dart';
export 'package:build4front/features/admin/licensing/domain/entities/subscription_status.dart';

/// Data-layer JSON wrapper for [OwnerAppAccess]. Keeps `fromJson` out of
/// the domain layer — domain code should depend on [OwnerAppAccess] only.
class OwnerAppAccessResponse extends OwnerAppAccess {
  const OwnerAppAccessResponse({
    required super.canAccessDashboard,
    required super.blockingReason,
    required super.planCode,
    required super.planName,
    required super.subscriptionStatus,
    required super.periodEnd,
    required super.daysLeft,
    required super.usersAllowed,
    required super.activeUsers,
    required super.usersRemaining,
    required super.requiresDedicatedServer,
    required super.dedicatedInfraReady,
    required super.upgradeRequestStatus,
    required super.upgradeRequestedPlan,
    required super.upgradeRequestedAt,
    required super.upgradeDecisionNote,
  });

  factory OwnerAppAccessResponse.fromJson(Map<String, dynamic> j) {
    final upPlanRaw = j['upgradeRequestedPlan']?.toString();
    return OwnerAppAccessResponse(
      canAccessDashboard: j['canAccessDashboard'] == true,
      blockingReason: j['blockingReason'] as String?,
      planCode: j['planCode'] != null
          ? planCodeFromString(j['planCode'].toString())
          : null,
      planName: j['planName'] as String?,
      subscriptionStatus: j['subscriptionStatus'] != null
          ? subscriptionStatusFromString(j['subscriptionStatus'].toString())
          : null,
      periodEnd: j['periodEnd']?.toString(),
      daysLeft: (j['daysLeft'] ?? 0) is int
          ? (j['daysLeft'] ?? 0)
          : int.tryParse('${j['daysLeft']}') ?? 0,
      usersAllowed: j['usersAllowed'] as int?,
      activeUsers: (j['activeUsers'] ?? 0) is int
          ? (j['activeUsers'] ?? 0)
          : int.tryParse('${j['activeUsers']}') ?? 0,
      usersRemaining: j['usersRemaining'] == null
          ? null
          : (j['usersRemaining'] as num).toInt(),
      requiresDedicatedServer: j['requiresDedicatedServer'] == true,
      dedicatedInfraReady: j['dedicatedInfraReady'] == true,
      upgradeRequestStatus: j['upgradeRequestStatus']?.toString(),
      upgradeRequestedPlan: (upPlanRaw == null || upPlanRaw.isEmpty)
          ? null
          : planCodeFromString(upPlanRaw),
      upgradeRequestedAt: j['upgradeRequestedAt']?.toString(),
      upgradeDecisionNote: j['upgradeDecisionNote']?.toString(),
    );
  }
}
