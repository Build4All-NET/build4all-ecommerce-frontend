import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/exceptions/app_exception.dart';
import 'package:build4front/core/exceptions/auth_exception.dart';
import 'package:build4front/core/exceptions/network_exception.dart';

class AdminUserApiService {
  final Future<String?> Function() getToken;

  AdminUserApiService({required this.getToken});

  String get _base => Env.apiBaseUrl;

  Future<Map<String, dynamic>> getMyProfileJson() async {
    final token = (await getToken())?.trim() ?? '';
    if (token.isEmpty) {
      throw AuthException(
        'Session expired. Please log in again.',
        code: 'MISSING_AUTH_TOKEN',
      );
    }

    final auth = token.startsWith('Bearer ') ? token : 'Bearer $token';
    final uri = Uri.parse('$_base/api/admin/users/me');

    try {
      final res = await http
          .get(
            uri,
            headers: {
              'Authorization': auth,
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
        throw AppException('Invalid server response.');
      }

      final payload = _readPayload(res.body);

      if (res.statusCode == 401 || res.statusCode == 403) {
        throw AuthException(
          payload.message ?? 'Session expired. Please log in again.',
          code: payload.code,
        );
      }

      throw ServerException(
        payload.message ?? _fallbackForStatus(res.statusCode),
        statusCode: res.statusCode,
        code: payload.code,
      );
    } on SocketException catch (e) {
      throw NetworkException(
        'No internet connection.',
        original: e,
      );
    } on TimeoutException catch (e) {
      throw NetworkException(
        "Can't reach the server. Check your internet and try again.",
        original: e,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'Unexpected error.',
        original: e,
      );
    }
  }

  _BackendPayload _readPayload(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);

        String? code;
        String? message;

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

        final errors = map['errors'];
        if ((message == null || message.isEmpty) && errors is Map) {
          final parts = <String>[];
          errors.forEach((_, value) {
            if (value is List) {
              for (final item in value) {
                final text = item?.toString().trim() ?? '';
                if (text.isNotEmpty) parts.add(text);
              }
            } else {
              final text = value?.toString().trim() ?? '';
              if (text.isNotEmpty) parts.add(text);
            }
          });

          if (parts.isNotEmpty) {
            message = parts.join(', ');
          }
        }

        return _BackendPayload(
          code: code,
          message: (message == null || message.isEmpty) ? null : message,
        );
      }
    } catch (_) {
      // ignore and fall through
    }

    final text = body.trim();
    return _BackendPayload(
      message: text.isEmpty ? null : text,
    );
  }

  String _fallbackForStatus(int status) {
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
}

class _BackendPayload {
  final String? code;
  final String? message;

  const _BackendPayload({
    this.code,
    this.message,
  });
}