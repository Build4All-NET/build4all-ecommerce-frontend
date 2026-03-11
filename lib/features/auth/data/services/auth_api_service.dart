import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/network/globals.dart' as g;

// Exceptions
import 'package:build4front/core/exceptions/app_exception.dart';
import 'package:build4front/core/exceptions/network_exception.dart';
import 'package:build4front/core/exceptions/auth_exception.dart';
import 'package:build4front/features/auth/data/models/AdminLoginResponse.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import 'auth_token_store.dart';

class AuthApiService {
  final http.Client _client;
  final AuthTokenStore _tokenStore;


  //  NEW
  bool _lastWasDeletedUser = false;
  bool _lastCanRestoreDeletedUser = false;
  //  NEW (resume complete profile after already-verified pending)
int? _lastResumePendingId;

int? get lastResumePendingId => _lastResumePendingId;

int? consumeLastResumePendingId() {
  final v = _lastResumePendingId;
  _lastResumePendingId = null;
  return v;
}

  AuthApiService({http.Client? client, required AuthTokenStore tokenStore})
      : _client = client ?? http.Client(),
        _tokenStore = tokenStore;

  String get _base => Env.apiBaseUrl;
  Uri _uri(String path) => Uri.parse('$_base$path');

  // ========================== INIT FROM STORAGE ==========================

Future<void> initFromStorage() async {
  final saved = (await _tokenStore.getToken())?.trim() ?? '';
  if (saved.isEmpty) return;

  final raw = saved.toLowerCase().startsWith('bearer ')
      ? saved.substring(7).trim()
      : saved;

  if (raw.isNotEmpty) g.setAuthToken(raw);
}

  int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

int? _extractPendingId(Map<String, dynamic> decoded) {
  // direct
  final direct = _asInt(decoded['pendingId']);
  if (direct != null) return direct;

  // nested in details
  final details = decoded['details'];
  if (details is Map) {
    final p1 = _asInt(details['pendingId']);
    if (p1 != null) return p1;

    final p2 = _asInt(details['id']); // fallback if backend uses id
    if (p2 != null) return p2;
  }

  return null;
}

  // ===================== SEND VERIFICATION CODE =========================

  Future<void> sendVerificationCode({
  String? email,
  String? phoneNumber,
  required String password,
  required int ownerProjectLinkId,
}) async {
  final uri = _uri('/api/auth/send-verification');

  // ✅ reset previous resume state before new attempt
  _lastResumePendingId = null;

  final body = <String, dynamic>{
    'password': password,
    'ownerProjectLinkId': ownerProjectLinkId,
    if (email != null && email.isNotEmpty) 'email': email,
    if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
  };

  try {
    final resp = await _safePost(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final decoded = _safeJson(resp.body);

    if (resp.statusCode >= 400) {
      _throwAuthFromHttp(
        resp,
        decoded,
        fallback: 'Failed to send verification',
      );
    }
  } on AppException {
    rethrow;
  } catch (e) {
    throw AppException('Failed to send verification', original: e);
  }
}
  // ========================= VERIFY EMAIL CODE ==========================

  Future<int> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final uri = _uri('/api/auth/verify-email-code');

    try {
      final resp = await _safePost(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      final decoded = _safeJson(resp.body);

      if (resp.statusCode >= 400) {
        _throwAuthFromHttp(
          resp,
          decoded,
          fallback: 'Invalid verification code',
        );
      }

     final user = decoded['user'] as Map<String, dynamic>? ?? {};
final id = decoded['pendingId'] ?? user['id'];
if (id == null) throw AppException('No pending/user id returned');
return (id as num).toInt();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Failed to verify email code', original: e);
    }
  }

  // ========================= VERIFY PHONE CODE ==========================

  Future<int> verifyPhoneCode({
    required String phoneNumber,
    required String code,
  }) async {
    final uri = _uri('/api/auth/user/verify-phone-code');

    try {
      final resp = await _safePost(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber, 'code': code}),
      );

      final decoded = _safeJson(resp.body);

      if (resp.statusCode >= 400) {
        _throwAuthFromHttp(
          resp,
          decoded,
          fallback: 'Invalid verification code',
        );
      }

      final user = decoded['user'] as Map<String, dynamic>? ?? {};
final id = decoded['pendingId'] ?? user['id'];
if (id == null) throw AppException('No pending/user id returned');
return (id as num).toInt();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Failed to verify phone code', original: e);
    }
  }


Future<void> logoutRemote() async {
  final access = (await _tokenStore.getToken())?.trim() ?? '';
  final refresh = (await _tokenStore.getRefreshToken())?.trim() ?? '';
  if (access.isEmpty) return;

  final auth = access.toLowerCase().startsWith('bearer ')
      ? access
      : 'Bearer $access';

  final uri = _uri('/api/auth/logout');

  try {
    await _safePost(
      uri,
      headers: {
        'Authorization': auth,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'refreshToken': refresh}), // ✅ NEW
    );
  } catch (_) {}
}
  // ======================= COMPLETE USER PROFILE ========================

  Future<UserModel> completeUserProfile({
    required int pendingId,
    required String username,
    required String firstName,
    required String lastName,
    required bool isPublicProfile,
    required int ownerProjectLinkId,
    String? profileImagePath,
  }) async {
    final uri = _uri('/api/auth/complete-profile');

    final request = http.MultipartRequest('POST', uri)
      ..fields['pendingId'] = pendingId.toString()
      ..fields['username'] = username
      ..fields['firstName'] = firstName
      ..fields['lastName'] = lastName
      ..fields['isPublicProfile'] = isPublicProfile.toString()
      ..fields['ownerProjectLinkId'] = ownerProjectLinkId.toString();

    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', profileImagePath),
      );
    }

    try {
      final resp = await _safeSend(request);
      debugPrint('👤 COMPLETE PROFILE → ${resp.statusCode}');
      debugPrint('BODY: ${resp.body}');

      final decoded = _safeJson(resp.body);

      if (resp.statusCode >= 400) {
        _throwAuthFromHttp(
          resp,
          decoded,
          fallback: 'Failed to complete profile',
        );
      }

      return UserModel.fromLoginJson(decoded);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Failed to complete profile', original: e);
    }
  }

  // ========================= USER LOGIN - EMAIL =========================

  Future<UserModel> loginWithEmail({
  required String email,
  required String password,
  required int ownerProjectLinkId,
}) async {
  final uri = _uri('/api/auth/user/login');

  debugPrint('🔐 LOGIN REQUEST (EMAIL) → $uri');
  debugPrint('BODY: email=$email, ownerProjectLinkId=$ownerProjectLinkId');

  // ✅ reset stale values before a new login attempt
  _lastWasDeletedUser = false;
  _lastCanRestoreDeletedUser = false;

  try {
    final resp = await _safePost(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'ownerProjectLinkId': ownerProjectLinkId.toString(),
      }),
    );

    debugPrint('🔐 LOGIN RESPONSE (EMAIL) → ${resp.statusCode}');
    debugPrint('BODY: ${resp.body}');

    final decoded = _safeJson(resp.body);

    // ✅ capture special restore flags from backend success response
    _lastWasDeletedUser = decoded['wasDeleted'] == true;
    _lastCanRestoreDeletedUser = decoded['canRestoreDeleted'] == true;

    if (resp.statusCode >= 400) {
      _throwAuthFromLogin(resp, decoded);
    }

   await _storeAuthFromLogin(decoded, tenantId: ownerProjectLinkId.toString());
    return UserModel.fromLoginJson(decoded);
  } on AppException {
    rethrow;
  } catch (e) {
    throw AppException('Failed to login with email', original: e);
  }
}
  // ========================= USER LOGIN - PHONE =========================

 Future<UserModel> loginWithPhone({
  required String phoneNumber,
  required String password,
  required int ownerProjectLinkId,
}) async {
  final uri = _uri('/api/auth/user/login-phone');

  debugPrint('🔐 LOGIN REQUEST (PHONE) → $uri');
  debugPrint(
    'BODY: phoneNumber=$phoneNumber, ownerProjectLinkId=$ownerProjectLinkId',
  );

  // ✅ reset stale values before a new login attempt
  _lastWasDeletedUser = false;
  _lastCanRestoreDeletedUser = false;

  try {
    final resp = await _safePost(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'password': password,
        'ownerProjectLinkId': ownerProjectLinkId.toString(),
      }),
    );

    debugPrint('🔐 LOGIN RESPONSE (PHONE) → ${resp.statusCode}');
    debugPrint('BODY: ${resp.body}');

    final decoded = _safeJson(resp.body);

    // ✅ capture special restore flags from backend success response
    _lastWasDeletedUser = decoded['wasDeleted'] == true;
    _lastCanRestoreDeletedUser = decoded['canRestoreDeleted'] == true;

    if (resp.statusCode >= 400) {
      _throwAuthFromLogin(resp, decoded);
    }

    await _storeAuthFromLogin(decoded, tenantId: ownerProjectLinkId.toString());
    return UserModel.fromLoginJson(decoded);
  } on AppException {
    rethrow;
  } catch (e) {
    throw AppException('Failed to login with phone', original: e);
  }
}
  // ========================= USER REACTIVATION =========================

  Future<void> reactivateUser() async {
  final uri = _uri('/api/auth/reactivate');

  
  final access = (await _tokenStore.getToken())?.trim() ?? '';
  if (access.isEmpty) {
    throw AuthException('Missing session token for reactivation', code: 'NO_TOKEN');
  }

  final auth = access.toLowerCase().startsWith('bearer ')
      ? access
      : 'Bearer $access';

  try {
    final resp = await _safePost(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': auth, // ✅ THIS IS THE FIX
      },
      body: jsonEncode({}), // ✅ no id, no ownerProjectLinkId
    );

    debugPrint('♻️ REACTIVATE USER → ${resp.statusCode}');
    debugPrint('BODY: ${resp.body}');

    final decoded = _safeJson(resp.body);

    if (resp.statusCode >= 400) {
      _throwAuthFromHttp(
        resp,
        decoded,
        fallback: 'Failed to reactivate account',
      );
    }

    // ✅ backend returns: token + refreshToken
    await _storeAuthFromLogin({
      'token': decoded['token'],
      'refreshToken': decoded['refreshToken'],
      'wasInactive': false,
      'wasDeleted': false,
    });

    // ✅ clear flags
    _lastWasDeletedUser = false;
    _lastCanRestoreDeletedUser = false;

  } on AppException {
    rethrow;
  } catch (e) {
    throw AppException('Failed to reactivate account', original: e);
  }
}

  // ========================= ADMIN LOGIN =========================

  Future<AdminLoginResponse> adminLogin({
    required String usernameOrEmail,
    required String password,
    int? ownerProjectId,
  }) async {
    final uri = _uri('/api/auth/admin/login/front');

    final payload = {
      'usernameOrEmail': usernameOrEmail,
      'password': password,
      if (ownerProjectId != null) 'ownerProjectId': ownerProjectId,
    };

    final resp = await _safePost(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final decoded = _safeJson(resp.body);
    if (resp.statusCode >= 400) _throwAdminFromLogin(resp, decoded);

    return AdminLoginResponse.fromJson(decoded);
  }

  // ============================= TOKEN HELPERS ==========================
Future<void> _storeAuthFromLogin(Map<String, dynamic> json, {String? tenantId}) async {
  final token = json['token'] as String?;
  final refresh = (json['refreshToken'] ?? '').toString();
  final wasInactive = json['wasInactive'] as bool? ?? false;
  final wasDeleted = json['wasDeleted'] == true;

  final user = (json['user'] as Map?)?.cast<String, dynamic>();

  if (token != null && token.isNotEmpty) {
    final safeRefresh = (wasInactive || wasDeleted) ? '' : refresh;

    await _tokenStore.saveToken(
      token: token,
      wasInactive: wasInactive,
      refreshToken: safeRefresh,
      tenantId: (tenantId ?? '').trim().isNotEmpty ? tenantId : Env.ownerProjectLinkId,
    );

    g.setAuthToken(token);
  }

  if (user != null && user.isNotEmpty) {
    await _tokenStore.saveUserJson(user);
    final id = user['id'];
    if (id is num) await _tokenStore.saveUserId(id.toInt());
    if (id is String) await _tokenStore.saveUserId(int.tryParse(id) ?? 0);
  }
}


   

Future<void> refreshSession() async {
  final refresh = (await _tokenStore.getRefreshToken())?.trim() ?? '';
  if (refresh.isEmpty) throw AppException('No refresh token');

  final uri = _uri('/api/auth/refresh');

  final resp = await _safePost(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'refreshToken': refresh}),
  );

  final decoded = _safeJson(resp.body);
  if (resp.statusCode >= 400) {
    throw AuthException('Refresh failed');
  }

  final newAccess = (decoded['token'] ?? '').toString();
  final newRefresh = (decoded['refreshToken'] ?? '').toString();

  if (newAccess.isEmpty || newRefresh.isEmpty) {
    throw AuthException('Refresh response missing tokens');
  }

  await _tokenStore.saveToken(
  token: newAccess,
  wasInactive: false,
  refreshToken: newRefresh,
  tenantId: Env.ownerProjectLinkId, 
);

  g.setAuthToken(newAccess);
}
  Future<String?> getSavedToken() => _tokenStore.getToken();
  Future<bool> getWasInactive() => _tokenStore.getWasInactive();
  Future<bool> getWasDeletedUser() async => _lastWasDeletedUser;
Future<bool> getCanRestoreDeletedUser() async => _lastCanRestoreDeletedUser;

Future<void> clearAuth() async {
  await _tokenStore.clear();
  g.setAuthToken('');
  _lastWasDeletedUser = false;
  _lastCanRestoreDeletedUser = false;
  debugPrint('🔓 Auth cleared: token removed from storage and globals');
}

Future<void> clearUserSession() async {
  await _tokenStore.clear();
  g.setAuthToken('');
  _lastWasDeletedUser = false;
  _lastCanRestoreDeletedUser = false;
}
  // ============================ HELPERS ================================

  Map<String, dynamic> _safeJson(String body) {
    if (body.isEmpty) return {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  /// ✅ upgraded: gets best message from backend without assuming structure
  String? _extractBackendMessage(Map<String, dynamic> json) {
    dynamic v;

    // common keys
    for (final key in ['message', 'error', 'detail', 'title']) {
      v = json[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }

    // errors can be List or Map
    v = json['errors'];

    // errors: [".."]
    if (v is List && v.isNotEmpty) {
      final first = v.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();

      // errors: [{field: [".."]}]
      if (first is Map) {
        for (final entry in first.entries) {
          final val = entry.value;
          if (val is String && val.trim().isNotEmpty) return val.trim();
          if (val is List && val.isNotEmpty && val.first is String) {
            return (val.first as String).trim();
          }
        }
      }
    }

    // errors: { field: [".."] }
    if (v is Map) {
      for (final entry in v.entries) {
        final val = entry.value;
        if (val is String && val.trim().isNotEmpty) return val.trim();
        if (val is List && val.isNotEmpty && val.first is String) {
          return (val.first as String).trim();
        }
      }
    }

    return null;
  }

Future<http.Response> _safePost(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
}) async {
  Future<http.Response> doPost(Map<String, String>? h) async {
    return await _client
        .post(uri, headers: h, body: body)
        .timeout(const Duration(seconds: 30));
  }

  try {
    final resp = await doPost(headers);
    return resp;
  } on SocketException catch (e) {
    throw NetworkException('No internet connection', original: e);
  } on TimeoutException catch (e) {
    throw NetworkException('Request timed out', original: e);
  } on http.ClientException catch (e) {
    throw NetworkException('Network error', original: e);
  }
}
  Future<http.Response> _safeSend(http.BaseRequest request) async {
    try {
      final streamed =
          await _client.send(request).timeout(const Duration(seconds: 60));
      return await http.Response.fromStream(streamed);
    } on SocketException catch (e) {
      throw NetworkException('No internet connection', original: e);
    } on TimeoutException catch (e) {
      throw NetworkException('Request timed out', original: e);
    } on http.ClientException catch (e) {
      throw NetworkException('Network error', original: e);
    }
  }

  // ✅ IMPORTANT: this returns codes so UI can show l10n messages
  Never _throwAuthFromHttp(
    http.Response resp,
    Map<String, dynamic> decoded, {
    required String fallback,
  }) {
    final status = resp.statusCode;
    final backendMsg = _extractBackendMessage(decoded);
    final msg = (backendMsg?.trim().isNotEmpty ?? false)
        ? backendMsg!.trim()
        : fallback;

    final m = msg.toLowerCase();
    bool hasAny(List<String> needles) => needles.any((n) => m.contains(n));

    final isAlreadyExists =
        hasAny(['already', 'exists', 'in use', 'taken', 'duplicate']);
    final mentionsUsername = hasAny(['username']);
    final mentionsEmail = hasAny(['email']);
    final mentionsPhone =
        hasAny(['phone', 'phone number', 'phonenumber', 'mobile']);

        final backendCodeRaw = decoded['code']?.toString().trim();
final backendCode = (backendCodeRaw != null && backendCodeRaw.isNotEmpty)
    ? backendCodeRaw
    : null;

//  If backend explicitly sends a code, preserve it.
// Especially important for PENDING_ALREADY_VERIFIED + details.pendingId
if (backendCode != null) {
  if (backendCode == 'PENDING_ALREADY_VERIFIED') {
    _lastResumePendingId = _extractPendingId(decoded);
  }
  throw AuthException(msg, code: backendCode, original: resp);
}

    final isConflictStatus = (status == 409 || status == 400 || status == 422);

    // --- specific conflicts first (best UX) ---
    if (isConflictStatus && isAlreadyExists && mentionsUsername) {
      throw AuthException(msg, code: 'USERNAME_TAKEN', original: resp);
    }
    if (isConflictStatus && isAlreadyExists && mentionsEmail) {
      throw AuthException(msg, code: 'EMAIL_ALREADY_EXISTS', original: resp);
    }
    if (isConflictStatus && isAlreadyExists && mentionsPhone) {
      throw AuthException(msg, code: 'PHONE_ALREADY_EXISTS', original: resp);
    }

    // --- generic classification ---
    if (status == 400 || status == 422) {
      throw AuthException(msg, code: 'VALIDATION_ERROR', original: resp);
    }
    if (status == 401) {
      throw AuthException(msg, code: 'UNAUTHORIZED', original: resp);
    }
    if (status == 403) {
      throw AuthException(msg, code: 'FORBIDDEN', original: resp);
    }
    if (status == 404) {
      throw AuthException(msg, code: 'NOT_FOUND', original: resp);
    }
    if (status == 409) {
      throw AuthException(msg, code: 'CONFLICT', original: resp);
    }
    if (status >= 500) {
      throw AuthException(msg, code: 'SERVER_ERROR', original: resp);
    }

    throw AuthException(msg, code: 'HTTP_ERROR', original: resp);
  }

  // ✅ IMPORTANT: login now gives specific codes (not everything = INVALID_CREDENTIALS)
  Never _throwAuthFromLogin(http.Response resp, Map<String, dynamic> decoded) {
    final status = resp.statusCode;
    final rawMsg =
        _extractBackendMessage(decoded) ?? 'Login failed. Please try again.';
    final m = rawMsg.toLowerCase();

    bool hasAny(List<String> needles) => needles.any((n) => m.contains(n));

    final isAlreadyExists =
        hasAny(['already', 'exists', 'in use', 'taken', 'duplicate']);
    final mentionsEmail = hasAny(['email']);
    final mentionsPhone =
        hasAny(['phone', 'phone number', 'phonenumber', 'mobile']);
    final mentionsUsername = hasAny(['username']);

    // if backend sends already-exists even in login, classify it correctly
    if ((status == 400 || status == 409 || status == 422) &&
        isAlreadyExists &&
        mentionsEmail) {
      throw AuthException(rawMsg, code: 'EMAIL_ALREADY_EXISTS', original: resp);
    }
    if ((status == 400 || status == 409 || status == 422) &&
        isAlreadyExists &&
        mentionsPhone) {
      throw AuthException(rawMsg, code: 'PHONE_ALREADY_EXISTS', original: resp);
    }
    if ((status == 400 || status == 409 || status == 422) &&
        isAlreadyExists &&
        mentionsUsername) {
      throw AuthException(rawMsg, code: 'USERNAME_TAKEN', original: resp);
    }

    // user not found
    if (status == 404 || hasAny(['user not found', 'not found', 'no user'])) {
      throw AuthException(rawMsg, code: 'USER_NOT_FOUND', original: resp);
    }

   // login locked
// login locked
if (status == 423 ||
    hasAny(['too many failed login attempts', 'login locked', 'retry later'])) {
  throw AuthException(rawMsg, code: 'LOGIN_LOCKED', original: resp);
}

// inactive account
if (hasAny(['inactive', 'disabled'])) {
  throw AuthException(rawMsg, code: 'INACTIVE', original: resp);
}

// invalid email format
if ((status == 400 || status == 422) &&
    hasAny(['invalid email format', 'email format'])) {
  throw AuthException(rawMsg, code: 'INVALID_EMAIL_FORMAT', original: resp);
}

    // wrong password vs invalid creds
    if (status == 400 || status == 401) {
      if (hasAny(['wrong password', 'incorrect password']) ||
          hasAny(['password'])) {
        throw AuthException(rawMsg, code: 'WRONG_PASSWORD', original: resp);
      }
      throw AuthException(rawMsg, code: 'INVALID_CREDENTIALS', original: resp);
    }

    throw AuthException(rawMsg, code: 'AUTH_ERROR', original: resp);
  }

  Never _throwAdminFromLogin(http.Response resp, Map<String, dynamic> decoded) {
    final status = resp.statusCode;
    final backendMsg = _extractBackendMessage(decoded)?.toLowerCase() ?? '';

    if (status == 401 &&
        (backendMsg.contains('invalid credentials') ||
            backendMsg.contains('incorrect password'))) {
      throw AuthException(
        'Invalid credentials',
        code: 'ADMIN_INVALID_CREDENTIALS',
        original: resp,
      );
    }

    if (status == 401 && backendMsg.contains('access denied')) {
      throw AuthException(
        'Access denized',
        code: 'ADMIN_ACCESS_DENIED',
        original: resp,
      );
    }

    final msg = _extractBackendMessage(decoded) ??
        'Admin login failed. Please try again.';
    throw AuthException(msg, code: 'ADMIN_AUTH_ERROR', original: resp);
  }
}
