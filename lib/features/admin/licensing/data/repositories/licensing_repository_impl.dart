import 'package:build4front/core/config/env.dart';
import 'package:build4front/features/admin/licensing/data/services/licensing_api_service.dart';
import 'package:build4front/features/admin/licensing/domain/entities/available_payment_method.dart';
import 'package:build4front/features/admin/licensing/domain/entities/billing_cycle.dart';
import 'package:build4front/features/admin/licensing/domain/entities/owner_app_access.dart';
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

  Future<OwnerAppAccess> _loadAccess() async {
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
  Future<OwnerAppAccess> getCurrentLicensePlan() => _loadAccess();

  @override
  Future<OwnerAppAccess> refreshOwnerSubscription() => _loadAccess();

  @override
  Future<List<UpgradePlan>> getAvailableUpgradePlans() async {
    // The backend already filters out the owner's current plan and returns
    // every other plan from `plan_catalog` with active pricing from
    // `license_plan_pricing`. We pass it through verbatim — no client-side
    // allowlist, no default-pricing fallback.
    final models = await api.getAvailableUpgradePlans();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<AvailablePaymentMethod>> getAvailablePaymentMethods() async {
    final models = await api.getAvailablePaymentMethods();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<UpgradePaymentIntent> initiateUpgradePayment({
    required String planCode,
    required BillingCycle billingCycle,
    required String paymentMethodCode,
    int? usersAllowedOverride,
  }) async {
    final model = await api.initiateUpgradePayment(
      planCode: planCode,
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
    required String planCode,
    required BillingCycle billingCycle,
    int? usersAllowedOverride,
  }) async {
    final role = await _role();
    final cycleStr = billingCycleToString(billingCycle);

    if (role == 'OWNER') {
      await api.requestUpgradeMe(
        planCode: planCode,
        usersAllowedOverride: usersAllowedOverride,
        billingCycle: cycleStr,
      );
    } else if (role == 'SUPER_ADMIN') {
      await api.requestUpgradeAsSuperAdmin(
        aupId: _aupIdFromEnv(),
        planCode: planCode,
        usersAllowedOverride: usersAllowedOverride,
        billingCycle: cycleStr,
      );
    } else {
      throw Exception('Unsupported role for upgrade request: $role');
    }
  }
}
