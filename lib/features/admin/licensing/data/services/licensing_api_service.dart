import 'package:build4front/core/config/env.dart';
import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/data/models/upgrade_payment_confirmation_model.dart';
import 'package:build4front/features/admin/licensing/data/models/upgrade_payment_intent_model.dart';
import 'package:build4front/features/admin/licensing/data/models/upgrade_plan_model.dart';
import 'package:build4front/features/admin/licensing/data/models/upgrade_request_model.dart';
import 'package:dio/dio.dart';

/// Frontend gateway for every licensing / upgrade / subscription endpoint.
///
/// Error handling convention (matches every other *_api_service.dart in
/// the project): methods return typed models on success and rely on Dio
/// to throw on non-2xx responses. Callers (repositories / BLoCs) map the
/// raised exception to a user-facing message through `ExceptionMapper`.
class LicensingApiService {
  final Future<String?> Function() getToken;
  late final Dio _dio;

  LicensingApiService({required this.getToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _normalizeBaseUrl(Env.apiBaseUrl),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
  }

  /// Ensures:
  /// - no trailing slash
  /// - baseUrl ends with /api
  static String _normalizeBaseUrl(String raw) {
    var base = raw.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    if (base.endsWith('/api')) return base;
    return '$base/api';
  }

  Future<String> _requireBearer() async {
    final token = (await getToken())?.trim() ?? '';
    if (token.isEmpty) {
      throw Exception('Missing token');
    }
    if (token.toLowerCase().startsWith('bearer ')) return token;
    return 'Bearer $token';
  }

  Future<Options> _authOptions() async {
    final auth = await _requireBearer();
    return Options(headers: {'Authorization': auth});
  }

  // =======================================================================
  // OWNER routes (tenant is inferred from the JWT)
  // =======================================================================

  /// Returns the current license / subscription snapshot for the owner.
  ///
  /// Endpoint: `GET /api/licensing/apps/me/access`
  Future<OwnerAppAccessResponse> getCurrentLicensePlan() async {
    final res = await _dio.get(
      '/licensing/apps/me/access',
      options: await _authOptions(),
    );
    return OwnerAppAccessResponse.fromJson(
      Map<String, dynamic>.from(res.data),
    );
  }

  /// Alias of [getCurrentLicensePlan] — semantically indicates a "refresh"
  /// triggered after a payment or user action, not the initial load.
  ///
  /// Endpoint: `GET /api/licensing/apps/me/access`
  Future<OwnerAppAccessResponse> refreshOwnerSubscription() =>
      getCurrentLicensePlan();

  /// Plans the owner can upgrade to, with dynamic pricing supplied by the
  /// super-admin through the backend (supports monthlyPrice, yearlyPrice,
  /// yearlyDiscountedPrice, currency, discountPercent, discountLabel).
  ///
  /// Endpoint: `GET /api/licensing/apps/me/upgrade-plans`
  Future<List<UpgradePlanModel>> getAvailableUpgradePlans() async {
    final res = await _dio.get(
      '/licensing/apps/me/upgrade-plans',
      options: await _authOptions(),
    );

    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => UpgradePlanModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    if (data is Map && data['plans'] is List) {
      return (data['plans'] as List)
          .whereType<Map>()
          .map((e) => UpgradePlanModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  /// Creates a server-side payment intent for the chosen plan + billing cycle.
  /// The returned intent carries everything the client needs to present the
  /// provider's payment sheet (publishable key, client secret for Stripe, or
  /// `checkoutUrl` for redirect-based providers).
  ///
  /// Endpoint: `POST /api/licensing/apps/me/upgrade/payment-intent`
  Future<UpgradePaymentIntentModel> initiateUpgradePayment({
    required String planCode,
    required String billingCycle,
    int? usersAllowedOverride,
  }) async {
    final res = await _dio.post(
      '/licensing/apps/me/upgrade/payment-intent',
      data: {
        'planCode': planCode,
        'billingCycle': billingCycle,
        'usersAllowedOverride': usersAllowedOverride,
      },
      options: await _authOptions(),
    );
    return UpgradePaymentIntentModel.fromJson(
      Map<String, dynamic>.from(res.data),
    );
  }

  /// Notifies the backend that the client-side payment step has succeeded.
  /// The backend verifies the intent with the provider before activating
  /// the plan and returns the refreshed subscription state alongside
  /// receipt metadata.
  ///
  /// Endpoint: `POST /api/licensing/apps/me/upgrade/payment-confirm`
  Future<UpgradePaymentConfirmationModel> confirmUpgradePayment({
    required String paymentIntentId,
  }) async {
    final res = await _dio.post(
      '/licensing/apps/me/upgrade/payment-confirm',
      data: {'paymentIntentId': paymentIntentId},
      options: await _authOptions(),
    );
    return UpgradePaymentConfirmationModel.fromJson(
      Map<String, dynamic>.from(res.data),
    );
  }

  /// Submits a non-paid upgrade request (legacy flow — super-admin manually
  /// approves). Kept for backward compatibility; the primary flow should be
  /// [initiateUpgradePayment] + [confirmUpgradePayment].
  ///
  /// Endpoint: `POST /api/licensing/apps/me/upgrade-request`
  Future<void> requestUpgradeMe({
    required String planCode, // PRO_HOSTEDB / DEDICATED
    int? usersAllowedOverride,
    String? billingCycle, // MONTHLY / YEARLY
  }) async {
    await _dio.post(
      '/licensing/apps/me/upgrade-request',
      data: {
        'planCode': planCode,
        'usersAllowedOverride': usersAllowedOverride,
        if (billingCycle != null) 'billingCycle': billingCycle,
      },
      options: await _authOptions(),
    );
  }

  /// Typed version of the historical `listMyUpgradeRequests` call.
  ///
  /// Endpoint: `GET /api/licensing/apps/me/upgrade-requests`
  Future<List<UpgradeRequestModel>> listUpgradeRequests() async {
    final res = await _dio.get(
      '/licensing/apps/me/upgrade-requests',
      options: await _authOptions(),
    );

    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => UpgradeRequestModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    if (data is Map && data['requests'] is List) {
      return (data['requests'] as List)
          .whereType<Map>()
          .map((e) => UpgradeRequestModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  // =======================================================================
  // SUPER_ADMIN routes (act-as via aupId)
  // =======================================================================

  /// Same as [getCurrentLicensePlan] but for a specific owner/project link,
  /// callable by a SUPER_ADMIN account.
  ///
  /// Endpoint: `GET /api/licensing/apps/{aupId}/access`
  Future<OwnerAppAccessResponse> getAccessAsSuperAdmin(int aupId) async {
    final res = await _dio.get(
      '/licensing/apps/$aupId/access',
      options: await _authOptions(),
    );
    return OwnerAppAccessResponse.fromJson(
      Map<String, dynamic>.from(res.data),
    );
  }

  /// Legacy "request upgrade" on behalf of a specific owner.
  ///
  /// Endpoint: `POST /api/licensing/apps/{aupId}/upgrade-request`
  Future<void> requestUpgradeAsSuperAdmin({
    required int aupId,
    required String planCode,
    int? usersAllowedOverride,
    String? billingCycle,
  }) async {
    await _dio.post(
      '/licensing/apps/$aupId/upgrade-request',
      data: {
        'planCode': planCode,
        'usersAllowedOverride': usersAllowedOverride,
        if (billingCycle != null) 'billingCycle': billingCycle,
      },
      options: await _authOptions(),
    );
  }

  // =======================================================================
  // Deprecated aliases — kept so existing callers continue to compile.
  // Prefer the explicit names above in new code.
  // =======================================================================

  @Deprecated('Use getCurrentLicensePlan() instead.')
  Future<OwnerAppAccessResponse> getAccessMe() => getCurrentLicensePlan();

  @Deprecated('Use listUpgradeRequests() instead.')
  Future<List<UpgradeRequestModel>> listMyUpgradeRequests() =>
      listUpgradeRequests();
}
