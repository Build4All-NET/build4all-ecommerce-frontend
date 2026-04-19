import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/domain/entities/billing_cycle.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_request.dart';

/// Mirrors the backend DTO exposed by
/// `GET /api/licensing/apps/{me|{aupId}}/upgrade-requests`.
///
/// Field aliases are tolerant of camelCase / snake_case and of both
/// `billingCycle`/`cycle` naming so evolving the contract doesn't
/// require a frontend change.
class UpgradeRequestModel {
  final int? id;
  final String? requestedPlan;
  final String? billingCycle;
  final String? status;
  final String? requestedAt;
  final String? decidedAt;
  final String? decisionNote;
  final int? usersAllowedOverride;
  final String? paymentIntentId;
  final double? amount;
  final String? currency;

  const UpgradeRequestModel({
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

  static int? _iNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _dNullable(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory UpgradeRequestModel.fromJson(Map<String, dynamic> j) {
    return UpgradeRequestModel(
      id: _iNullable(j['id']),
      requestedPlan:
          (j['requestedPlan'] ?? j['planCode'] ?? j['plan'])?.toString(),
      billingCycle:
          (j['billingCycle'] ?? j['cycle'])?.toString(),
      status: j['status']?.toString(),
      requestedAt:
          (j['requestedAt'] ?? j['createdAt'])?.toString(),
      decidedAt:
          (j['decidedAt'] ?? j['decidedOn'] ?? j['resolvedAt'])?.toString(),
      decisionNote: j['decisionNote']?.toString(),
      usersAllowedOverride: _iNullable(j['usersAllowedOverride']),
      paymentIntentId: j['paymentIntentId']?.toString(),
      amount: _dNullable(j['amount']),
      currency: j['currency']?.toString(),
    );
  }

  UpgradeRequest toEntity() {
    PlanCode? plan;
    final pc = (requestedPlan ?? '').toUpperCase();
    switch (pc) {
      case 'FREE':
        plan = PlanCode.FREE;
        break;
      case 'PRO_HOSTEDB':
        plan = PlanCode.PRO_HOSTEDB;
        break;
      case 'DEDICATED':
        plan = PlanCode.DEDICATED;
        break;
      default:
        plan = null;
    }

    return UpgradeRequest(
      id: id,
      requestedPlan: plan,
      billingCycle: billingCycle == null
          ? null
          : billingCycleFromString(billingCycle),
      status: upgradeRequestStatusFromString(status),
      requestedAt: requestedAt,
      decidedAt: decidedAt,
      decisionNote: decisionNote,
      usersAllowedOverride: usersAllowedOverride,
      paymentIntentId: paymentIntentId,
      amount: amount,
      currency: currency,
    );
  }
}
