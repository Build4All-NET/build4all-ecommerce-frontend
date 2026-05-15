import 'package:build4front/core/network/globals.dart' as g;
import 'package:build4front/features/admin/licensing/data/models/available_payment_method_model.dart';
import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/data/models/upgrade_payment_confirmation_model.dart';
import 'package:build4front/features/admin/licensing/data/models/upgrade_payment_intent_model.dart';
import 'package:build4front/features/admin/licensing/data/models/upgrade_plan_model.dart';
import 'package:build4front/features/admin/licensing/data/models/upgrade_request_model.dart';
import 'package:dio/dio.dart';

/// Frontend gateway for every licensing / upgrade / subscription endpoint.
///
/// IMPORTANT:
/// This service uses the shared application Dio (`g.appDio`) so every request
/// goes through `RefreshTokenInterceptor`. When the access token expires the
/// interceptor will refresh it and retry the request transparently — without
/// kicking the admin back to the login screen.
///
/// Previously this service built its own private Dio, which bypassed the
/// interceptor and caused the dashboard to fail with "session expired" while
/// the admin was just waiting on `getCurrentLicensePlan()` to load.
class LicensingApiService {
  final Future<String?> Function() getToken;

  LicensingApiService({required this.getToken});

  /// Shared Dio with interceptors (refresh + owner injector).
  Dio get _dio => g.appDio ?? g.dio();

  Future<String> _requireBearer() async {
    final token = (await getToken())?.trim() ?? '';
    if (token.isEmpty) {
      throw Exception('Missing token');
    }
    if (token.toLowerCase().startsWith('bearer ')) return token;
    return 'Bearer $token';
  }

  /// Builds Options with:
  /// - fresh Authorization header (read at call time)
  /// - a `retryRequest` callback so the refresh interceptor can transparently
  ///   retry with the new token (works for both JSON and FormData payloads).
  Future<Options> _authOptions(
    Future<Response<dynamic>> Function(String newBearer) retry,
  ) async {
    final auth = await _requireBearer();
    return Options(
      headers: {'Authorization': auth},
      extra: {'retryRequest': retry},
    );
  }

  // =======================================================================
  // OWNER routes (tenant is inferred from the JWT)
  // =======================================================================

  /// Returns the current license / subscription snapshot for the owner.
  ///
  /// Endpoint: `GET /api/licensing/apps/me/access`
  Future<OwnerAppAccessResponse> getCurrentLicensePlan() async {
    Future<Response<dynamic>> doCall(String bearer) {
      return _dio.get(
        '/api/licensing/apps/me/access',
        options: Options(headers: {'Authorization': bearer}),
      );
    }

    final res = await _dio.get(
      '/api/licensing/apps/me/access',
      options: await _authOptions(doCall),
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
    Future<Response<dynamic>> doCall(String bearer) {
      return _dio.get(
        '/api/licensing/apps/me/upgrade-plans',
        options: Options(headers: {'Authorization': bearer}),
      );
    }

    final res = await _dio.get(
      '/api/licensing/apps/me/upgrade-plans',
      options: await _authOptions(doCall),
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

  /// Returns the payment methods the owner can pick from on the Pay Now
  /// popup (filtered server-side to only active, SUPER_ADMIN-configured
  /// methods).
  ///
  /// Endpoint: `GET /api/licensing/apps/me/payment-methods`
  Future<List<AvailablePaymentMethodModel>> getAvailablePaymentMethods() async {
    Future<Response<dynamic>> doCall(String bearer) {
      return _dio.get(
        '/api/licensing/apps/me/payment-methods',
        options: Options(headers: {'Authorization': bearer}),
      );
    }

    final res = await _dio.get(
      '/api/licensing/apps/me/payment-methods',
      options: await _authOptions(doCall),
    );

    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => AvailablePaymentMethodModel.fromJson(
                e.cast<String, dynamic>(),
              ))
          .toList();
    }
    return const [];
  }

  /// Creates a server-side payment intent for the chosen plan + billing cycle.
  ///
  /// Endpoint: `POST /api/licensing/apps/me/upgrade/payment-intent`
  Future<UpgradePaymentIntentModel> initiateUpgradePayment({
    required String planCode,
    required String billingCycle,
    required String paymentMethodCode,
    int? usersAllowedOverride,
  }) async {
    final body = {
      'planCode': planCode,
      'billingCycle': billingCycle,
      'paymentMethodCode': paymentMethodCode,
      'usersAllowedOverride': usersAllowedOverride,
    };

    Future<Response<dynamic>> doCall(String bearer) {
      return _dio.post(
        '/api/licensing/apps/me/upgrade/payment-intent',
        data: body,
        options: Options(headers: {'Authorization': bearer}),
      );
    }

    final res = await _dio.post(
      '/api/licensing/apps/me/upgrade/payment-intent',
      data: body,
      options: await _authOptions(doCall),
    );
    return UpgradePaymentIntentModel.fromJson(
      Map<String, dynamic>.from(res.data),
    );
  }

  /// Notifies the backend that the client-side payment step has succeeded.
  ///
  /// Endpoint: `POST /api/licensing/apps/me/upgrade/payment-confirm`
  Future<UpgradePaymentConfirmationModel> confirmUpgradePayment({
    required String paymentIntentId,
  }) async {
    final body = {'paymentIntentId': paymentIntentId};

    Future<Response<dynamic>> doCall(String bearer) {
      return _dio.post(
        '/api/licensing/apps/me/upgrade/payment-confirm',
        data: body,
        options: Options(headers: {'Authorization': bearer}),
      );
    }

    final res = await _dio.post(
      '/api/licensing/apps/me/upgrade/payment-confirm',
      data: body,
      options: await _authOptions(doCall),
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
    final body = {
      'planCode': planCode,
      'usersAllowedOverride': usersAllowedOverride,
      if (billingCycle != null) 'billingCycle': billingCycle,
    };

    Future<Response<dynamic>> doCall(String bearer) {
      return _dio.post(
        '/api/licensing/apps/me/upgrade-request',
        data: body,
        options: Options(headers: {'Authorization': bearer}),
      );
    }

    await _dio.post(
      '/api/licensing/apps/me/upgrade-request',
      data: body,
      options: await _authOptions(doCall),
    );
  }

  /// Typed version of the historical `listMyUpgradeRequests` call.
  ///
  /// Endpoint: `GET /api/licensing/apps/me/upgrade-requests`
  Future<List<UpgradeRequestModel>> listUpgradeRequests() async {
    Future<Response<dynamic>> doCall(String bearer) {
      return _dio.get(
        '/api/licensing/apps/me/upgrade-requests',
        options: Options(headers: {'Authorization': bearer}),
      );
    }

    final res = await _dio.get(
      '/api/licensing/apps/me/upgrade-requests',
      options: await _authOptions(doCall),
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
    Future<Response<dynamic>> doCall(String bearer) {
      return _dio.get(
        '/api/licensing/apps/$aupId/access',
        options: Options(headers: {'Authorization': bearer}),
      );
    }

    final res = await _dio.get(
      '/api/licensing/apps/$aupId/access',
      options: await _authOptions(doCall),
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
    final body = {
      'planCode': planCode,
      'usersAllowedOverride': usersAllowedOverride,
      if (billingCycle != null) 'billingCycle': billingCycle,
    };

    Future<Response<dynamic>> doCall(String bearer) {
      return _dio.post(
        '/api/licensing/apps/$aupId/upgrade-request',
        data: body,
        options: Options(headers: {'Authorization': bearer}),
      );
    }

    await _dio.post(
      '/api/licensing/apps/$aupId/upgrade-request',
      data: body,
      options: await _authOptions(doCall),
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