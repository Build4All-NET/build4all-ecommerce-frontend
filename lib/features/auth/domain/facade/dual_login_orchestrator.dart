import 'package:build4front/core/exceptions/app_exception.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';
import 'package:build4front/features/auth/data/services/auth_api_service.dart';
import 'package:build4front/features/auth/domain/entities/user_entity.dart';

/// Result object that tells us:
/// - did admin login succeed?
/// - did user login succeed?
/// - did the user login return "wasInactive" from backend?
import 'package:build4front/core/exceptions/app_exception.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';
import 'package:build4front/features/auth/data/services/auth_api_service.dart';
import 'package:build4front/features/auth/domain/entities/user_entity.dart';

/// Result object that tells us:
/// - did admin login succeed?
/// - did user login succeed?
/// - did the user login return "wasInactive" from backend?
/// - did the user login return deleted/restore flags?
class DualLoginResult {
  final bool adminOk;
  final bool userOk;

  /// True if backend returned wasInactive = true for the user login.
  final bool wasInactiveUser;

  /// ✅ True if backend returned wasDeleted = true
  final bool wasDeletedUser;

  /// ✅ True if backend returned canRestoreDeleted = true
  final bool canRestoreDeletedUser;

  final String? adminToken;
  final String? adminRole;
  final Map<String, dynamic>? adminData;

  final UserEntity? userEntity;
  final String? userToken;

  final String? error;

  const DualLoginResult({
    required this.adminOk,
    required this.userOk,
    required this.wasInactiveUser,
    this.wasDeletedUser = false,
    this.canRestoreDeletedUser = false,
    this.adminToken,
    this.adminRole,
    this.adminData,
    this.userEntity,
    this.userToken,
    this.error,
  });

  bool get both => adminOk && userOk;
  bool get none => !adminOk && !userOk;
}

/// Orchestrates dual login:
/// - Tries admin login (SUPER_ADMIN / OWNER / MANAGER)
/// - Tries user login (email or phone)
/// - Does NOT decide UI, only returns what worked.
class DualLoginOrchestrator {
  final AuthApiService authApi;
  final AdminTokenStore adminStore;

  DualLoginOrchestrator({
    required this.authApi,
    required this.adminStore,
  });

  Future<DualLoginResult> login({
    required String identifier, // email or phone (user), email/username (admin)
    required String password,
    required bool usePhoneForUser, // true → user login via phone endpoint
    required int ownerProjectLinkId,
  }) async {
    String? adminToken;
    String? adminRole;
    Map<String, dynamic>? adminData;

    UserEntity? userEntity;
    String? userToken;
    bool wasInactiveUser = false;

    // ✅ NEW
    bool wasDeletedUser = false;
    bool canRestoreDeletedUser = false;

    AppException? adminErr;
    AppException? userErr;

    // ===================== 1) Try ADMIN/OWNER/MANAGER =====================
    try {
      final adminRes = await authApi.adminLogin(
        usernameOrEmail: identifier,
        password: password,
        ownerProjectId: ownerProjectLinkId,
      );

      adminToken = adminRes.token;
      adminRole = adminRes.role;
      adminData = adminRes.admin;

      // Save admin token in dedicated store (NOT user token store)
      await adminStore.save(token: adminToken!, role: adminRole!);
    } catch (e) {
      adminErr = e is AppException ? e : AppException(e.toString());
    }

    // ========================== 2) Try USER ==========================
    try {
      final user = usePhoneForUser
          ? await authApi.loginWithPhone(
              phoneNumber: identifier,
              password: password,
              ownerProjectLinkId: ownerProjectLinkId,
            )
          : await authApi.loginWithEmail(
              email: identifier,
              password: password,
              ownerProjectLinkId: ownerProjectLinkId,
            );

      userEntity = user;
      userToken = await authApi.getSavedToken();

      // existing flag
      wasInactiveUser = await authApi.getWasInactive();

      // ✅ NEW flags
      wasDeletedUser = await authApi.getWasDeletedUser();
      canRestoreDeletedUser = await authApi.getCanRestoreDeletedUser();
    } catch (e) {
      userErr = e is AppException ? e : AppException(e.toString());

      // ✅ Optional but useful:
      // If AuthApiService captured deleted flags before throwing, we still read them here.
      try {
        wasDeletedUser = await authApi.getWasDeletedUser();
        canRestoreDeletedUser = await authApi.getCanRestoreDeletedUser();
      } catch (_) {}
    }

    final adminOk = adminToken != null && adminRole != null;
    final userOk = userEntity != null;

    if (!adminOk && !userOk) {
      return DualLoginResult(
        adminOk: false,
        userOk: false,
        wasInactiveUser: false,
        wasDeletedUser: false,
        canRestoreDeletedUser: false,
        error:
            (userErr ?? adminErr)?.message ?? 'Login failed. Please try again.',
      );
    }

    return DualLoginResult(
      adminOk: adminOk,
      userOk: userOk,
      wasInactiveUser: userOk ? wasInactiveUser : false,
      wasDeletedUser: userOk ? wasDeletedUser : false,
      canRestoreDeletedUser: userOk ? canRestoreDeletedUser : false,
      adminToken: adminToken,
      adminRole: adminRole,
      adminData: adminData,
      userEntity: userEntity,
      userToken: userToken,
    );
  }
}