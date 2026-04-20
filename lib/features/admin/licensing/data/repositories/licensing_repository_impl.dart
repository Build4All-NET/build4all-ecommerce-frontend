import 'package:build4front/core/config/env.dart';
import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/data/models/plan_pricing_model.dart';
import 'package:build4front/features/admin/licensing/data/models/upgrade_plan_model.dart';
import 'package:build4front/features/admin/licensing/data/services/licensing_api_service.dart';
import 'package:build4front/features/admin/licensing/domain/entities/available_payment_method.dart';
import 'package:build4front/features/admin/licensing/domain/entities/billing_cycle.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_payment_confirmation.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_payment_intent.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_plan.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_request.dart';
import 'package:build4front/features/admin/licensing/domain/repositories/i_licensing_repository.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';

class LicensingRepositoryImpl implements ILicensingRepository {
  final LicensingApiService api;
  final AdminTokenStore tokenStore;

  LicensingRepositoryImpl({
    required this.api,
    required this.tokenStore,
  });

  Future<String> _role() async =>
      (await tokenStore.getRole())?.toUpperCase() ?? '';

  int _aupIdFromEnv() => int.tryParse(Env.ownerProjectLinkId) ?? 0;

  Future<OwnerAppAccessResponse> _loadAccess() async {
    final role = await _role();
    if (role == 'OWNER') {
      return api.getCurrentLicensePlan();
    }
    if (role == 'SUPER_ADMIN') {
      return api.getAccessAsSuperAdmin(_aupIdFromEnv());
    }
    throw Exception('Unsupported role for licensing: $role');
  }

  @override
  Future<OwnerAppAccessResponse> getCurrentLicensePlan() => _loadAccess();

  @override
  Future<OwnerAppAccessResponse> refreshOwnerSubscription() => _loadAccess();

  @override
  Future<List<UpgradePlan>> getAvailableUpgradePlans() async {
    List<UpgradePlanModel> models = const [];
    try {
      models = await api.getAvailableUpgradePlans();
    } catch (_) {
      // Backend endpoint may not be deployed yet — fall back to built-in plans
      // with default pricing so the UI still works.
      models = const [];
    }

    final access = await _loadAccess();
    final current = access.planCode ?? PlanCode.FREE;

    final allowed = <PlanCode>[];
    if (current == PlanCode.FREE) {
      allowed.addAll([PlanCode.PRO_HOSTEDB, PlanCode.DEDICATED]);
    } else if (current == PlanCode.PRO_HOSTEDB) {
      allowed.add(PlanCode.DEDICATED);
    }

    return allowed.map((code) {
      final codeStr = _planCodeToApiString(code);
      final match = models.where((m) => m.code.toUpperCase() == codeStr);
      final model = match.isNotEmpty
          ? match.first
          : UpgradePlanModel(
              code: codeStr,
              title: null,
              description: null,
              available: true,
              unavailableReason: null,
              pricing: PlanPricingModel.defaults(),
            );
      return model.toEntity(code);
    }).toList();
  }

  @override
  Future<List<AvailablePaymentMethod>> getAvailablePaymentMethods() async {
    final models = await api.getAvailablePaymentMethods();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<UpgradePaymentIntent> initiateUpgradePayment({
    required PlanCode planCode,
    required BillingCycle billingCycle,
    required String paymentMethodCode,
    int? usersAllowedOverride,
  }) async {
    final model = await api.initiateUpgradePayment(
      planCode: _planCodeToApiString(planCode),
      billingCycle: billingCycleToString(billingCycle),
      paymentMethodCode: paymentMethodCode,
      usersAllowedOverride: usersAllowedOverride,
    );
    return model.toEntity();
  }

  @override
  Future<UpgradePaymentConfirmation> confirmUpgradePayment({
    required String paymentIntentId,
  }) async {
    final model =
        await api.confirmUpgradePayment(paymentIntentId: paymentIntentId);
    return model.toEntity();
  }

  @override
  Future<List<UpgradeRequest>> listUpgradeRequests() async {
    final models = await api.listUpgradeRequests();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> requestUpgrade({
    required PlanCode planCode,
    required BillingCycle billingCycle,
    int? usersAllowedOverride,
  }) async {
    final role = await _role();
    final codeStr = _planCodeToApiString(planCode);
    final cycleStr = billingCycleToString(billingCycle);

    if (role == 'OWNER') {
      await api.requestUpgradeMe(
        planCode: codeStr,
        usersAllowedOverride: usersAllowedOverride,
        billingCycle: cycleStr,
      );
    } else if (role == 'SUPER_ADMIN') {
      await api.requestUpgradeAsSuperAdmin(
        aupId: _aupIdFromEnv(),
        planCode: codeStr,
        usersAllowedOverride: usersAllowedOverride,
        billingCycle: cycleStr,
      );
    } else {
      throw Exception('Unsupported role for upgrade request: $role');
    }
  }

  static String _planCodeToApiString(PlanCode code) {
    switch (code) {
      case PlanCode.FREE:
        return 'FREE';
      case PlanCode.PRO_HOSTEDB:
        return 'PRO_HOSTEDB';
      case PlanCode.DEDICATED:
        return 'DEDICATED';
    }
  }
}
