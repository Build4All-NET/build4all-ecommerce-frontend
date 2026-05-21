import 'package:build4front/features/admin/licensing/domain/entities/plan_pricing.dart';

class UpgradePlan {
  /// Raw plan code as returned by the backend (e.g. PRO_HOSTEDB, DEDICATED,
  /// or any custom code defined in the plan_catalog table). Used verbatim
  /// as the selection identity and when initiating a payment.
  final String code;
  final String? title;
  final String? description;
  final PlanPricing pricing;
  final bool available;
  final String? unavailableReason;

  const UpgradePlan({
    required this.code,
    required this.title,
    required this.description,
    required this.pricing,
    required this.available,
    required this.unavailableReason,
  });
}
