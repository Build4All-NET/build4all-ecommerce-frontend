import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:build4front/core/exceptions/app_exception.dart';
import 'package:build4front/core/exceptions/auth_exception.dart';
import 'package:build4front/core/exceptions/network_exception.dart';
import 'package:build4front/core/network/globals.dart' as g;
import 'package:build4front/core/utils/jwt_utils.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';
import 'package:build4front/features/auth/data/services/auth_token_store.dart';

class AuthRefreshCoordinator {
  AuthRefreshCoordinator._();

  static final AuthRefreshCoordinator instance = AuthRefreshCoordinator._();

  final AuthTokenStore _userStore = const AuthTokenStore();
  final AdminTokenStore _adminStore = const AdminTokenStore();

  Completer<String>? _userRefreshing;
  Completer<String>? _adminRefreshing;

  Dio _plain() {
    return Dio(
      BaseOptions(
        baseUrl: g.appServerRoot,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }

  String _stripBearer(String? token) {
    final v = (token ?? '').trim();
    if (v.toLowerCase().startsWith('bearer ')) {
      return v.substring(7).trim();
    }
    return v;
  }

  bool shouldClearAfterRefreshFailure(Object e) {
    if (e is AuthException) {
      final code = (e.code ?? '').trim().toUpperCase();
      return code == 'NO_USER_REFRESH' ||
          code == 'NO_ADMIN_REFRESH' ||
          code == 'BAD_REFRESH' ||
          code == 'BAD_REFRESH_RESPONSE';
    }

    if (e is DioException) {
      final s = e.response?.statusCode ?? 0;
      if (s == 401 || s == 403) return true;
    }

    if (e is AppException) {
      final code = (e.code ?? '').trim().toUpperCase();
      return code == 'NO_USER_REFRESH' ||
          code == 'NO_ADMIN_REFRESH' ||
          code == 'BAD_REFRESH' ||
          code == 'BAD_REFRESH_RESPONSE';
    }

    return false;
  }

  Future<String> refreshUser({String? tenantId}) async {
    if (_userRefreshing != null) return _userRefreshing!.future;

    final completer = Completer<String>();
    _userRefreshing = completer;

    try {
      final refresh = (await _userStore.getRefreshToken())?.trim() ?? '';
      if (refresh.isEmpty) {
        throw AuthException(
          'No refresh token available.',
          code: 'NO_USER_REFRESH',
        );
      }

      final res = await _plain().post(
        '/api/auth/refresh',
        data: {'refreshToken': refresh},
      );

      final data = (res.data is Map)
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};

      final newAccess = (data['token'] ?? '').toString().trim();
      final newRefresh = (data['refreshToken'] ?? '').toString().trim();

      if (newAccess.isEmpty || newRefresh.isEmpty) {
        throw AuthException(
          'Invalid refresh response.',
          code: 'BAD_REFRESH_RESPONSE',
        );
      }

      await _userStore.saveToken(
        token: newAccess,
        wasInactive: false,
        refreshToken: newRefresh,
        tenantId: tenantId,
      );

      g.setAuthToken(newAccess);

      completer.complete(newAccess);
      return newAccess;
    } on DioException catch (e, st) {
      final status = e.response?.statusCode;
      final payload = _readPayload(e.response?.data);

      final mapped = _mapRefreshDioError(
        e,
        status: status,
        payload: payload,
      );

      completer.completeError(mapped, st);
      throw mapped;
    } catch (e, st) {
      if (e is AppException) {
        completer.completeError(e, st);
        rethrow;
      }

      final wrapped = AppException('Refresh failed.', original: e);
      completer.completeError(wrapped, st);
      throw wrapped;
    } finally {
      _userRefreshing = null;
    }
  }

  Future<String> refreshAdmin({String? tenantId}) async {
    if (_adminRefreshing != null) return _adminRefreshing!.future;

    final completer = Completer<String>();
    _adminRefreshing = completer;

    try {
      final refresh = (await _adminStore.getRefreshToken())?.trim() ?? '';
      if (refresh.isEmpty) {
        throw AuthException(
          'No refresh token available.',
          code: 'NO_ADMIN_REFRESH',
        );
      }

      final res = await _plain().post(
        '/api/auth/refresh',
        data: {'refreshToken': refresh},
      );

      final data = (res.data is Map)
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};

      final newAccess = (data['token'] ?? '').toString().trim();
      final newRefresh = (data['refreshToken'] ?? '').toString().trim();

      if (newAccess.isEmpty || newRefresh.isEmpty) {
        throw AuthException(
          'Invalid refresh response.',
          code: 'BAD_REFRESH_RESPONSE',
        );
      }

      final role = (await _adminStore.getRole()) ?? '';

      await _adminStore.save(
        token: newAccess,
        role: role,
        refreshToken: newRefresh,
        tenantId: tenantId,
      );

      g.setAuthToken(newAccess);

      completer.complete(newAccess);
      return newAccess;
    } on DioException catch (e, st) {
      final status = e.response?.statusCode;
      final payload = _readPayload(e.response?.data);

      final mapped = _mapRefreshDioError(
        e,
        status: status,
        payload: payload,
      );

      completer.completeError(mapped, st);
      throw mapped;
    } catch (e, st) {
      if (e is AppException) {
        completer.completeError(e, st);
        rethrow;
      }

      final wrapped = AppException('Refresh failed.', original: e);
      completer.completeError(wrapped, st);
      throw wrapped;
    } finally {
      _adminRefreshing = null;
    }
  }

  Future<String?> refreshUserIfNeeded({
    required String? tokenStored,
    required bool userWasInactive,
    String? tenantId,
  }) async {
    if (userWasInactive) return null;

    final refresh = (await _userStore.getRefreshToken())?.trim() ?? '';
    if (refresh.isEmpty) return null;

    final raw = _stripBearer(tokenStored);
    if (raw.isNotEmpty && !JwtUtils.isExpired(raw)) {
      return raw;
    }

    try {
      return await refreshUser(tenantId: tenantId);
    } catch (e) {
      if (shouldClearAfterRefreshFailure(e)) {
        await _userStore.clear();
      }
      return null;
    }
  }

  Future<String?> refreshAdminIfNeeded({
    required String? tokenStored,
    String? tenantId,
  }) async {
    final refresh = (await _adminStore.getRefreshToken())?.trim() ?? '';
    if (refresh.isEmpty) return null;

    final raw = _stripBearer(tokenStored);
    if (raw.isNotEmpty && !JwtUtils.isExpired(raw)) {
      return raw;
    }

    try {
      return await refreshAdmin(tenantId: tenantId);
    } catch (e) {
      if (shouldClearAfterRefreshFailure(e)) {
        await _adminStore.clear();
      }
      return null;
    }
  }

  _BackendPayload _readPayload(dynamic data) {
    String? code;
    String? message;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      final rawCode = map['code'];
      if (rawCode != null && rawCode.toString().trim().isNotEmpty) {
        code = rawCode.toString().trim();
      }

      for (final key in const ['error', 'message', 'detail', 'msg', 'title']) {
        final value = map[key];
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) {
          message = text;
          break;
        }
      }
    } else if (data is String) {
      final text = data.trim();
      if (text.isNotEmpty) {
        message = text;
      }
    }

    return _BackendPayload(
      code: code,
      message: (message == null || message.isEmpty) ? null : message,
    );
  }

  AppException _mapRefreshDioError(
    DioException e, {
    required int? status,
    required _BackendPayload payload,
  }) {
    final isSocket = e.error is SocketException;

    final isNetworkFailure =
        e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            (e.type == DioExceptionType.unknown && isSocket);

    if (isNetworkFailure) {
      return NetworkException(
        isSocket
            ? 'No internet connection.'
            : (payload.message ??
                "Can't reach the server. Check your internet and try again."),
        original: e,
      );
    }

    if (status == 401 || status == 403) {
      return AuthException(
        payload.message ?? 'Session expired. Please log in again.',
        code: payload.code ?? 'BAD_REFRESH',
        original: e,
      );
    }

    if (status != null) {
      return ServerException(
        payload.message ??
            ((status >= 500)
                ? 'Server error. Please try later.'
                : 'Refresh failed.'),
        statusCode: status,
        code: payload.code,
        original: e,
      );
    }

    return AppException(
      payload.message ?? 'Refresh failed.',
      code: payload.code,
      original: e,
    );
  }
}

class _BackendPayload {
  final String? code;
  final String? message;

  const _BackendPayload({
    this.code,
    this.message,
  });
}