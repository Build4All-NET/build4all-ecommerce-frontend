library globals;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/network/connecting(wifiORserver)/connection_cubit.dart';
import 'package:build4front/core/network/interceptors/auth_body_injector.dart';
import 'package:build4front/core/network/interceptors/refresh_token_interceptor.dart';

Dio? appDio;

/// Core server base, e.g. "http://192.168.1.5:8080"
late String appServerRoot;

// -------- Tokens (legacy compatibility) --------
String? authToken;
String? token;
String? userToken;
String? Token;

// -------- Owner / tenant wiring --------
String? ownerProjectLinkId;
String? ownerAttachMode;
String? projectId;
String? appRole;
String? wsPath;

// -------- Branding --------
String appName = 'Build4All — Client';
String appLogoUrl = '';

final ValueNotifier<bool> aiEnabledNotifier = ValueNotifier<bool>(false);

bool get aiEnabled => aiEnabledNotifier.value;
set aiEnabled(bool v) => aiEnabledNotifier.value = v;

// -------- Connection Cubit (for server / network status) --------
ConnectionCubit? connectionCubit;

void registerConnectionCubit(ConnectionCubit cubit) {
  connectionCubit = cubit;
}

/// Read current auth token from any legacy field.
String readAuthToken() {
  return (authToken ?? token ?? userToken ?? Token ?? '').toString();
}

/// Set auth token and update Dio default headers.
/// Accepts raw jwt OR "Bearer <jwt>".
void setAuthToken(String? raw) {
  final t = (raw ?? '').trim();

  if (t.isEmpty) {
    authToken = null;
    token = null;
    userToken = null;
    Token = null;

    appDio?.options.headers.remove('Authorization');
    return;
  }

  final normalized =
      t.toLowerCase().startsWith('bearer ') ? t : 'Bearer $t';

  authToken = normalized;
  token = normalized;
  userToken = normalized;
  Token = normalized;

  appDio?.options.headers['Authorization'] = normalized;
}

/// Base URL without "/api" suffix, used to resolve relative URLs.
String serverRootNoApi() {
  final base = appServerRoot;
  return base.replaceFirst(RegExp(r'/api/?$'), '');
}

/// Resolve relative path against server root.
String resolveUrl(String maybeRelative) {
  final s = maybeRelative.trim();
  if (s.isEmpty) return s;

  if (s.startsWith('http://') || s.startsWith('https://')) return s;

  final base = serverRootNoApi().replaceAll(RegExp(r'/+$'), '');
  final rel = s.startsWith('/') ? s : '/$s';
  return '$base$rel';
}

String get appLogoUrlResolved => resolveUrl(appLogoUrl);

Dio dio() {
  final existing = appDio;
  if (existing != null) return existing;

  if (appServerRoot.trim().isEmpty) {
    throw StateError(
      'ERROR: appDio is NULL and appServerRoot is not initialized. '
      'Call makeDefaultDio() first.',
    );
  }

  makeDefaultDio(appServerRoot);
  return appDio!;
}

/// Initialize Dio + interceptors.
/// Call once at app startup.
void makeDefaultDio(String baseUrl) {
  appServerRoot = baseUrl;

  // Copy Env → globals (interceptors rely on these)
  ownerProjectLinkId = Env.ownerProjectLinkId;
  ownerAttachMode = Env.ownerAttachMode;
  projectId = Env.projectId;
  appRole = Env.appRole;
  wsPath = Env.wsPath;
  appName = Env.appName;
  appLogoUrl = Env.appLogoUrl;

  final d = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  d.interceptors.clear();

  // Keep connection status sane even for code paths that use g.dio() directly.
  d.interceptors.add(_ConnectionStateInterceptor());

  // Refresh first for auth failures.
  d.interceptors.add(RefreshTokenInterceptor());

  // Then inject ownerProjectLinkId / auth header.
  d.interceptors.add(OwnerInjector());

  if (kDebugMode) {
    d.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  appDio = d;

  // If token already set before init, copy it into dio headers
  final existingToken = readAuthToken().trim();
  if (existingToken.isNotEmpty) {
    d.options.headers['Authorization'] = existingToken;
  }
}

/* ===================== JWT helpers ===================== */

String? _rawJwt() {
  final full = readAuthToken().trim();
  if (full.isEmpty) return null;
  if (full.toLowerCase().startsWith('bearer ')) {
    return full.substring(7).trim();
  }
  return full;
}

Map<String, dynamic>? decodeJwtPayload() {
  try {
    final raw = _rawJwt();
    if (raw == null || raw.isEmpty) return null;

    final parts = raw.split('.');
    if (parts.length != 3) return null;

    var payload = parts[1];
    payload = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(payload));
    final map = jsonDecode(decoded);

    if (map is Map<String, dynamic>) return map;
    return null;
  } catch (_) {
    return null;
  }
}

String? getOwnerNameFromJwt() {
  final payload = decodeJwtPayload();
  if (payload == null) return null;

  final roleRaw = payload['role'];
  final role = roleRaw is String ? roleRaw.toUpperCase().trim() : null;

  if (role == 'OWNER') {
    final uname = payload['username'];
    if (uname is String && uname.trim().isNotEmpty) return uname.trim();
  }
  return null;
}

class _ConnectionStateInterceptor extends Interceptor {
  bool _isNetworkFailure(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }

    if (e.type == DioExceptionType.unknown && e.error is SocketException) {
      return true;
    }

    return false;
  }

  String? _extractBackendMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in const ['error', 'message', 'detail', 'msg', 'title']) {
        final value = map[key];
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
    }

    if (data is String) {
      final text = data.trim();
      if (text.isNotEmpty) return text;
    }

    return null;
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    connectionCubit?.setOnline();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isSocket = err.error is SocketException;
    final status = err.response?.statusCode;

    if (_isNetworkFailure(err)) {
      if (!isSocket) {
        connectionCubit?.setServerDown(
          _extractBackendMessage(err.response?.data) ??
              'Server is not responding',
        );
      }
      return handler.next(err);
    }

    if (status != null && status >= 500) {
      connectionCubit?.setServerDown(
        _extractBackendMessage(err.response?.data) ??
            'Server is not responding',
      );
      return handler.next(err);
    }

    handler.next(err);
  }
}