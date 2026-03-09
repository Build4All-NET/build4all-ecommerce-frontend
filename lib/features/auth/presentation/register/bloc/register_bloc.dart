import 'package:build4front/core/config/env.dart';
import 'package:build4front/features/auth/domain/repository/auth_repository.dart';
import 'package:build4front/features/auth/domain/usecases/send_verification_code.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'register_event.dart';
import 'register_state.dart';

// Exceptions
import 'package:build4front/core/exceptions/auth_exception.dart';
import 'package:build4front/core/exceptions/network_exception.dart';
import 'package:build4front/core/exceptions/app_exception.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final SendVerificationCode sendVerificationCode;

  RegisterBloc({required this.sendVerificationCode})
      : super(RegisterState.initial()) {
    on<RegisterSendCodeSubmitted>(_onSendCodeSubmitted);
  }

  Future<void> _onSendCodeSubmitted(
    RegisterSendCodeSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        errorCode: null,
        codeSent: false,
        contact: null,
        method: null,
        resumeCompleteProfile: false,
        resumePendingId: null,
      ),
    );

    final ownerId = int.tryParse(Env.ownerProjectLinkId) ?? 0;

    final email =
        event.method == RegisterMethod.email ? event.email?.trim() : null;

    final phone = event.method == RegisterMethod.phone
        ? event.phoneNumber?.trim()
        : null;

    try {
      final dynamic result = await sendVerificationCode(
        email: email,
        phoneNumber: phone,
        password: event.password,
        ownerProjectLinkId: ownerId,
      );

      if (result is Either) {
        result.fold(
          (failure) {
            if (failure.code == 'PENDING_ALREADY_VERIFIED' &&
                failure.pendingId != null) {
              emit(
                state.copyWith(
                  isLoading: false,
                  errorCode: null,
                  codeSent: false,
                  contact: email ?? phone,
                  method: event.method,
                  resumeCompleteProfile: true,
                  resumePendingId: failure.pendingId,
                ),
              );
              return;
            }

            final code = _mapFailureToCode(failure);
            emit(
              state.copyWith(
                isLoading: false,
                errorCode: code,
                codeSent: false,
                contact: null,
                method: null,
                resumeCompleteProfile: false,
                resumePendingId: null,
              ),
            );
          },
          (_) {
            emit(
              state.copyWith(
                isLoading: false,
                errorCode: null,
                codeSent: true,
                contact: email ?? phone,
                method: event.method,
                resumeCompleteProfile: false,
                resumePendingId: null,
              ),
            );
          },
        );
        return;
      }

      emit(
        state.copyWith(
          isLoading: false,
          errorCode: null,
          codeSent: true,
          contact: email ?? phone,
          method: event.method,
          resumeCompleteProfile: false,
          resumePendingId: null,
        ),
      );
    } catch (e) {
      final code = _mapErrorToCode(e);
      emit(
        state.copyWith(
          isLoading: false,
          errorCode: code,
          codeSent: false,
          contact: null,
          method: null,
          resumeCompleteProfile: false,
          resumePendingId: null,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Failure mapping (Either Left)
  // ---------------------------------------------------------------------------

  String _mapFailureToCode(dynamic failure) {
    final rawCode = _tryReadDynamicCode(failure);
    final rawMsg = _tryReadDynamicMessage(failure) ?? failure.toString();

    // 1) message has highest priority if it contains something useful
    final byMessage = _mapMessageToAuthCode(rawMsg);
    if (byMessage != null) return byMessage;

    // 2) explicit backend code mapping
    final byBackendCode = _mapBackendCodeToUiCode(rawCode);
    if (byBackendCode != null) return byBackendCode;

    if (failure is AuthException) {
      final code = failure.code;
      if (code != null && !_isGenericCode(code)) {
        return _normalizeCode(code);
      }
      return 'AUTH_ERROR';
    }

    if (failure is NetworkException) {
      return _mapNetworkFailure(failure);
    }

    if (failure is AppException) {
      if (rawCode != null && !_isGenericCode(rawCode)) {
        return _normalizeCode(rawCode);
      }
      return 'GENERIC';
    }

    if (rawCode != null && !_isGenericCode(rawCode)) {
      return _normalizeCode(rawCode);
    }

    return 'GENERIC';
  }

  String _mapNetworkFailure(NetworkException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('no internet')) return 'NO_INTERNET';
    if (msg.contains('timed out') || msg.contains('timeout')) return 'TIMEOUT';
    return 'NETWORK_ERROR';
  }

  // ---------------------------------------------------------------------------
  // Exception mapping (catch)
  // ---------------------------------------------------------------------------

  String _mapErrorToCode(Object e) {
    if (e is AuthException) {
      final byMessage = _mapMessageToAuthCode(e.message ?? '');
      if (byMessage != null) return byMessage;

      final byCode = _mapBackendCodeToUiCode(e.code);
      if (byCode != null) return byCode;

      if (e.code != null && !_isGenericCode(e.code!)) {
        return _normalizeCode(e.code!);
      }

      return 'AUTH_ERROR';
    }

    if (e is NetworkException) return _mapNetworkFailure(e);

    if (e is AppException) {
      final code = _tryReadDynamicCode(e);
      final msg = _tryReadDynamicMessage(e) ?? e.toString();

      final byMessage = _mapMessageToAuthCode(msg);
      if (byMessage != null) return byMessage;

      final byCode = _mapBackendCodeToUiCode(code);
      if (byCode != null) return byCode;

      if (code != null && !_isGenericCode(code)) {
        return _normalizeCode(code);
      }

      return 'GENERIC';
    }

    if (e is DioException) {
      final parsed = _parseBackendErrorFromDio(e);

      final byMessage =
          parsed.message != null ? _mapMessageToAuthCode(parsed.message!) : null;
      if (byMessage != null) return byMessage;

      final byCode =
          parsed.code != null ? _mapBackendCodeToUiCode(parsed.code!) : null;
      if (byCode != null) return byCode;

      if (parsed.code != null && !_isGenericCode(parsed.code!)) {
        return _normalizeCode(parsed.code!);
      }

      final s = parsed.status;
      if (s == 401) return 'UNAUTHORIZED';
      if (s == 403) return 'FORBIDDEN';
      if (s == 404) return 'NOT_FOUND';
      if (s == 409) return 'CONFLICT';
      if (s != null && s >= 500) return 'SERVER_ERROR';
      if (s == 400) return 'VALIDATION_ERROR';

      return 'NETWORK_ERROR';
    }

    return _mapMessageToAuthCode(e.toString()) ?? 'GENERIC';
  }

  // ---------------------------------------------------------------------------
  // Backend parsing helpers
  // ---------------------------------------------------------------------------

  _BackendErr _parseBackendErrorFromDio(DioException e) {
    String? code;
    String? message;
    int? status;

    try {
      status = e.response?.statusCode;
      final data = e.response?.data;

      if (data is Map) {
        code = _firstNonEmpty([
          data['code']?.toString(),
          data['errorCode']?.toString(),
          data['error_code']?.toString(),
        ]);

        message = _extractMessageFromMap(data);

        final s = data['status'];
        if (s is int) status = s;
        if (s is String) status = int.tryParse(s);
      } else if (data is String && data.trim().isNotEmpty) {
        message = data.trim();
      }

      message ??= e.message;
    } catch (_) {
      message = e.message ?? e.toString();
    }

    return _BackendErr(code: code, message: message, status: status);
  }

  String? _extractMessageFromMap(Map data) {
    final direct = _firstNonEmpty([
      data['error']?.toString(),
      data['message']?.toString(),
      data['details']?.toString(),
      data['detail']?.toString(),
      data['msg']?.toString(),
    ]);

    if (direct != null) return direct;

    final errors = data['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first?.toString().trim();
          if (first != null && first.isNotEmpty) return first;
        }
        final s = value?.toString().trim();
        if (s != null && s.isNotEmpty) return s;
      }
    }

    if (errors is List && errors.isNotEmpty) {
      final first = errors.first?.toString().trim();
      if (first != null && first.isNotEmpty) return first;
    }

    return null;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      final s = v?.trim();
      if (s != null && s.isNotEmpty && s.toLowerCase() != 'null') {
        return s;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Message -> Stable code mapping
  // ---------------------------------------------------------------------------

  String? _mapMessageToAuthCode(String msg) {
    final m = msg.toLowerCase().trim();

    // email
    if (m.contains('email') &&
        (m.contains('already') ||
            m.contains('exists') ||
            m.contains('used') ||
            m.contains('in use') ||
            m.contains('registered') ||
            m.contains('taken') ||
            m.contains('duplicate'))) {
      return 'EMAIL_ALREADY_EXISTS';
    }

    // phone
    if ((m.contains('phone') || m.contains('phone number') || m.contains('mobile')) &&
        (m.contains('already') ||
            m.contains('exists') ||
            m.contains('used') ||
            m.contains('in use') ||
            m.contains('registered') ||
            m.contains('taken') ||
            m.contains('duplicate'))) {
      return 'PHONE_ALREADY_EXISTS';
    }

    // username
    if (m.contains('username') &&
        (m.contains('taken') ||
            m.contains('already') ||
            m.contains('exists') ||
            m.contains('used'))) {
      return 'USERNAME_TAKEN';
    }

    // otp / code
    if ((m.contains('invalid') || m.contains('wrong')) &&
        (m.contains('code') || m.contains('otp') || m.contains('verification'))) {
      return 'INVALID_CODE';
    }

    if (m.contains('already verified')) {
      return 'PENDING_ALREADY_VERIFIED';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Backend code -> Stable UI code mapping
  // ---------------------------------------------------------------------------

  String? _mapBackendCodeToUiCode(String? rawCode) {
    if (rawCode == null || rawCode.trim().isEmpty) return null;

    final code = _normalizeCode(rawCode);

    switch (code) {
      case 'EMAIL_ALREADY_EXISTS':
      case 'EMAIL_ALREADY_IN_USE':
      case 'EMAIL_EXISTS':
      case 'EMAIL_IN_USE':
      case 'DUPLICATE_EMAIL':
      case 'EMAIL_TAKEN':
      case 'USER_EMAIL_ALREADY_EXISTS':
        return 'EMAIL_ALREADY_EXISTS';

      case 'PHONE_ALREADY_EXISTS':
      case 'PHONE_ALREADY_IN_USE':
      case 'PHONE_EXISTS':
      case 'PHONE_IN_USE':
      case 'PHONE_NUMBER_ALREADY_EXISTS':
      case 'PHONE_NUMBER_ALREADY_IN_USE':
      case 'DUPLICATE_PHONE':
      case 'MOBILE_ALREADY_EXISTS':
      case 'MOBILE_IN_USE':
        return 'PHONE_ALREADY_EXISTS';

      case 'USERNAME_TAKEN':
      case 'USERNAME_ALREADY_EXISTS':
      case 'USERNAME_EXISTS':
      case 'DUPLICATE_USERNAME':
        return 'USERNAME_TAKEN';

      case 'INVALID_CODE':
      case 'INVALID_OTP':
      case 'WRONG_CODE':
      case 'WRONG_OTP':
      case 'INVALID_VERIFICATION_CODE':
        return 'INVALID_CODE';

      case 'PENDING_ALREADY_VERIFIED':
      case 'ALREADY_VERIFIED':
        return 'PENDING_ALREADY_VERIFIED';

      case 'USER_NOT_FOUND':
        return 'USER_NOT_FOUND';

      case 'WRONG_PASSWORD':
        return 'WRONG_PASSWORD';

      case 'INVALID_CREDENTIALS':
        return 'INVALID_CREDENTIALS';

      case 'INACTIVE':
      case 'ACCOUNT_INACTIVE':
        return 'INACTIVE';

      case 'UNAUTHORIZED':
        return 'UNAUTHORIZED';

      case 'FORBIDDEN':
        return 'FORBIDDEN';

      case 'NOT_FOUND':
        return 'NOT_FOUND';

      case 'CONFLICT':
        return 'CONFLICT';

      case 'SERVER_ERROR':
      case 'INTERNAL_SERVER_ERROR':
        return 'SERVER_ERROR';

      case 'VALIDATION_ERROR':
        return 'VALIDATION_ERROR';

      default:
        return null;
    }
  }

  bool _isGenericCode(String code) {
    final c = _normalizeCode(code);
    return {
      'GENERIC',
      'ERROR',
      'UNKNOWN',
      'UNKNOWN_ERROR',
      'AUTH_ERROR',
      'BAD_REQUEST',
      'VALIDATION_ERROR',
      'REQUEST_FAILED',
      'FAILURE',
    }.contains(c);
  }

  // ---------------------------------------------------------------------------
  // Dynamic readers
  // ---------------------------------------------------------------------------

  String? _tryReadDynamicCode(dynamic obj) {
    try {
      final any = obj as dynamic;
      final c = any.code;
      if (c == null) return null;
      final s = c.toString().trim();
      return s.isEmpty ? null : s;
    } catch (_) {
      return null;
    }
  }

  String? _tryReadDynamicMessage(dynamic obj) {
    try {
      final any = obj as dynamic;
      final m = any.message;
      if (m == null) return null;
      final s = m.toString().trim();
      return s.isEmpty ? null : s;
    } catch (_) {
      return null;
    }
  }

  String _normalizeCode(String code) {
    return code
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .toUpperCase();
  }
}

class _BackendErr {
  final String? code;
  final String? message;
  final int? status;

  _BackendErr({this.code, this.message, this.status});
}