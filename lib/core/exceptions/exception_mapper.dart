// lib/core/exceptions/exception_mapper.dart
import 'dart:convert';
import 'package:dio/dio.dart';

import 'app_exception.dart';

class ExceptionMapper {
  static String toMessage(Object error) {
    try {
      // ✅ If someone passes a String directly
      if (error is String) return _sanitize(error);

      // ✅ Your app-level exceptions
      if (error is AppException) {
        // If it wraps a DioException or any original error -> map it first
        final orig = error.original;
        if (orig != null && orig is! AppException) {
          final msgFromOrig = toMessage(orig);
          if (msgFromOrig.trim().isNotEmpty) return msgFromOrig;
        }

        // Keep your code-based mapping (existing behavior)
        switch (error.code) {
  case 'INVALID_CREDENTIALS':
    return 'Invalid email or password';

  case 'WRONG_PASSWORD':
    return 'Invalid email or password';

  case 'USER_NOT_FOUND':
    return 'User not found';

  case 'INVALID_EMAIL_FORMAT':
    return 'Invalid email format';

  case 'LOGIN_LOCKED':
    return _sanitize(error.message);

  case 'INACTIVE':
    return 'Your account is inactive. Reactivate to continue.';

  case 'NETWORK_ERROR':
    return 'No internet connection';

  case 'SERVER_ERROR':
    return 'Server error. Please try later.';
}
      }

      // ✅ Raw Dio exceptions (this is the big missing part in your project)
      if (error is DioException) return _dioToMessage(error);

      // ✅ Other common stuff
      if (error is FormatException) return 'Invalid server response.';
      if (error is ArgumentError) return 'Invalid input.';
      if (error is TypeError) return 'Something went wrong. Please try again.';

      // ✅ Fallback
      return _sanitize(error.toString());
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  static String _dioToMessage(DioException e) {
    // 1) Network & timeouts
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed.';
      case DioExceptionType.unknown:
        return 'Network error. Check your connection.';

      case DioExceptionType.badResponse:
        break; // handled below
    }

    // 2) HTTP response errors (400/401/403/500…)
    final status = e.response?.statusCode;
    final data = e.response?.data;

    // Try extract backend message (error/message/detail…)
    final extracted = _extractBackendMessage(data);
    if (extracted != null && extracted.trim().isNotEmpty) {
      return _sanitize(extracted);
    }

    // Fallback by status code
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

  static String? _extractBackendMessage(dynamic data) {
    if (data == null) return null;

    // Sometimes backend returns plain string (or JSON string)
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
      return s;
    }

    // JSON object
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      for (final k in ['error', 'message', 'detail', 'msg', 'title']) {
        final v = map[k];
        if (v is String && v.trim().isNotEmpty) return v;
      }

      // Validation errors format: errors: { field: ["msg1"] }
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

  static String _sanitize(String raw) {
    var msg = raw.trim();

    // Remove common junk prefixes
    msg = msg.replaceAll(RegExp(r'^(Exception:)\s*'), '');
    msg = msg.replaceAll(RegExp(r'^(DioException:)\s*'), '');
    msg = msg.replaceAll(RegExp(r'^(Bad state:)\s*'), '');

    // If someone passed the full Dio dump as string, cut it hard
    if (msg.contains('requestOptions') || msg.contains('Response:')) {
      // keep first line only
      msg = msg.split('\n').first.trim();
    }

    // Cut mega walls
    const maxLen = 160;
    if (msg.length > maxLen) msg = '${msg.substring(0, maxLen)}…';

    return msg.isEmpty ? 'Something went wrong.' : msg;
  }
}