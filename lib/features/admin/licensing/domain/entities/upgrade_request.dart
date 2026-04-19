import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/domain/entities/billing_cycle.dart';

enum UpgradeRequestStatus { pending, approved, rejected, canceled, unknown }

UpgradeRequestStatus upgradeRequestStatusFromString(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'PENDING':
      return UpgradeRequestStatus.pending;
    case 'APPROVED':
      return UpgradeRequestStatus.approved;
    case 'REJECTED':
      return UpgradeRequestStatus.rejected;
    case 'CANCELED':
    case 'CANCELLED':
      return UpgradeRequestStatus.canceled;
    default:
      return UpgradeRequestStatus.unknown;
  }
}

class UpgradeRequest {
  final int? id;
  final PlanCode? requestedPlan;
  final BillingCycle? billingCycle;
  final UpgradeRequestStatus status;
  final String? requestedAt;
  final String? decidedAt;
  final String? decisionNote;
  final int? usersAllowedOverride;
  final String? paymentIntentId;
  final double? amount;
  final String? currency;

  const UpgradeRequest({
    required this.id,
    required this.requestedPlan,
    required this.billingCycle,
    required this.status,
    required this.requestedAt,
    required this.decidedAt,
    required this.decisionNote,
    required this.usersAllowedOverride,
    required this.paymentIntentId,
    required this.amount,
    required this.currency,
  });
}
