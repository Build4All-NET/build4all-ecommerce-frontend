import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/domain/entities/plan_pricing.dart';

class UpgradePlan {
  final PlanCode code;
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
