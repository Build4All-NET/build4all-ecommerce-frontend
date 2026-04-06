import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'app_exception.dart';
import 'network_exception.dart';

class ExceptionMapper {
  static String toMessage(Object error) {
    try {
      if (error is String) return _sanitize(error);

      if (error is NetworkException) {
        final orig = error.original;
        if (orig is SocketException) return 'No internet connection.';
        return "Can't reach the server. Check your internet and try again.";
      }

      if (error is AppException) {
        final orig = error.original;
        if (orig != null && orig is! AppException) {
          final fromOrig = toMessage(orig);
          if (fromOrig.trim().isNotEmpty) return fromOrig;
        }

        final fromCode = _mapBackendCode(error.code);
        if (fromCode != null) return fromCode;

        if (error.message.trim().isNotEmpty) {
          return _sanitize(error.message);
        }
      }

      if (error is DioException) return _dioToMessage(error);

      if (error is SocketException) return 'No internet connection.';
      if (error is FormatException) return 'Invalid server response.';
      if (error is ArgumentError) return 'Invalid input.';
      if (error is TypeError) return 'Something went wrong. Please try again.';

      return _sanitize(error.toString());
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  static String _dioToMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Try again.';

      case DioExceptionType.connectionError:
        return "Can't reach the server. Check your internet and try again.";

      case DioExceptionType.cancel:
        return 'Request cancelled.';

      case DioExceptionType.badCertificate:
        return 'Secure connection failed.';

      case DioExceptionType.unknown:
        final err = e.error;
        if (err is SocketException) return 'No internet connection.';
        return "Can't reach the server. Check your internet and try again.";

      case DioExceptionType.badResponse:
        break;
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;

    final backendCode = _extractBackendCode(data);
    final mappedCode = _mapBackendCode(backendCode);
    if (mappedCode != null) return mappedCode;

    final extracted = _extractBackendMessage(data);
    if (extracted != null && extracted.trim().isNotEmpty) {
      return _sanitize(extracted);
    }

    return _statusFallback(status);
  }

  static String _statusFallback(int? status) {
    if (status == null) return 'Request failed.';

    switch (status) {
      case 400:
      case 422:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You don’t have permission to do this.';
      case 404:
        return 'Not found.';
      case 409:
        return 'Conflict. This already exists or can’t be done now.';
      default:
        if (status >= 500) return 'Server error. Please try later.';
        return 'Request failed.';
    }
  }

  static String? _extractBackendCode(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      final s = data.trim();
      if ((s.startsWith('{') && s.endsWith('}')) ||
          (s.startsWith('[') && s.endsWith(']'))) {
        try {
          final decoded = json.decode(s);
          return _extractBackendCode(decoded);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final code = map['code'];
      if (code is String && code.trim().isNotEmpty) {
        return code.trim();
      }
    }

    return null;
  }

  static String? _extractBackendMessage(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      final s = data.trim();

      if ((s.startsWith('{') && s.endsWith('}')) ||
          (s.startsWith('[') && s.endsWith(']'))) {
        try {
          final decoded = json.decode(s);
          return _extractBackendMessage(decoded);
        } catch (_) {
          return s;
        }
      }

      final mapped = _mapBackendCode(s);
      if (mapped != null) return mapped;

      return s;
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      final code = map['code'];
      if (code is String && code.trim().isNotEmpty) {
        final mapped = _mapBackendCode(code);
        if (mapped != null) return mapped;
      }

      for (final k in ['error', 'message', 'detail', 'msg', 'title']) {
        final v = map[k];
        if (v is String && v.trim().isNotEmpty) {
          final mapped = _mapBackendCode(v);
          if (mapped != null) return mapped;
          return v;
        }
      }

      final errs = map['errors'];
      if (errs is Map) {
        final parts = <String>[];
        errs.forEach((_, val) {
          if (val is List) {
            for (final x in val) {
              if (x is String && x.trim().isNotEmpty) parts.add(x);
            }
          } else if (val is String && val.trim().isNotEmpty) {
            parts.add(val);
          }
        });
        if (parts.isNotEmpty) return parts.join(', ');
      }
    }

    return null;
  }

  static String? _mapBackendCode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final code = raw.trim().toUpperCase();

    switch (code) {
      case 'INVALID_CREDENTIALS':
      case 'WRONG_PASSWORD':
      case 'BUSINESS_LOGIN_FAILED':
        return 'Invalid email, phone number, or password.';

      case 'USER_NOT_FOUND':
      case 'BUSINESS_NOT_FOUND':
        return 'Account not found.';

      case 'INVALID_EMAIL_FORMAT':
        return 'Invalid email format.';

      case 'LOGIN_LOCKED':
        return 'Too many attempts. Please try again later.';

      case 'INACTIVE':
      case 'INVALID_USER_STATUS':
        return 'Your account is inactive. Reactivate to continue.';

      case 'NETWORK_ERROR':
        return "Can't reach the server. Check your internet and try again.";

      case 'SERVER_ERROR':
      case 'INTERNAL_ERROR':
        return 'Server error. Please try later.';

      case 'VALIDATION_ERROR':
        return 'Please check your input and try again.';

      case 'ACCESS_DENIED':
        return 'You don’t have permission to do this.';

      case 'TENANT_MISMATCH':
      case 'INVALID_TENANCY':
        return 'This action is not allowed for this app.';

      case 'MISSING_AUTH_TOKEN':
      case 'INVALID_TOKEN':
      case 'AUTH':
      case 'INVALID_AUTH_HEADER':
      case 'USER_TOKEN_REQUIRED':
      case 'ADMIN_TOKEN_REQUIRED':
        return 'Session expired. Please log in again.';

      case 'USERNAME_ALREADY_EXISTS':
        return 'This username is already in use.';

      case 'USER_DELETED':
      case 'BUSINESS_DELETED':
        return 'This account is no longer available.';

      case 'PROFILE_UPDATE_FAILED':
        return 'Failed to update profile. Please try again.';

      case 'PASSWORD_UPDATE_FAILED':
        return 'Failed to update password. Please try again.';

      case 'INVALID_CODE':
        return 'Invalid verification code.';

      case 'UPLOAD_FAILED':
        return 'Upload failed. Please try again.';

      case 'INVALID_FILE_TYPE':
        return 'Invalid file type.';

      case 'TAX_RULE_NOT_FOUND':
      case 'SHIPPING_METHOD_NOT_FOUND':
      case 'PROJECT_NOT_FOUND':
      case 'PROFILE_IMAGE_NOT_FOUND':
      case 'CATEGORY_NOT_FOUND':
        return 'Requested item was not found.';

      case 'SUBSCRIPTION_LIMIT_EXCEEDED':
        return 'Your subscription limit has been reached.';

      case 'FIREBASE_CONFIG_NOT_READY':
        return 'Configuration is not ready yet. Please try again shortly.';

      case 'FIREBASE_CONFIG_NOT_FOUND':
        return 'Configuration was not found.';

      default:
        return null;
    }
  }

  static String _sanitize(String raw) {
    var msg = raw.trim();

    msg = msg.replaceAll(RegExp(r'^(Exception:)\s*'), '');
    msg = msg.replaceAll(RegExp(r'^(DioException:)\s*'), '');
    msg = msg.replaceAll(RegExp(r'^(Bad state:)\s*'), '');

    final mapped = _mapBackendCode(msg);
    if (mapped != null) return mapped;

    if (msg.contains('requestOptions') || msg.contains('Response:')) {
      msg = msg.split('\n').first.trim();
    }

    const maxLen = 160;
    if (msg.length > maxLen) {
      msg = '${msg.substring(0, maxLen)}…';
    }

    return msg.isEmpty ? 'Something went wrong.' : msg;
  }
}