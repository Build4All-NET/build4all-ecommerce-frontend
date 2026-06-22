import 'package:flutter/widgets.dart';
import 'package:build4front/l10n/app_localizations.dart';

import 'package:build4front/core/exceptions/auth_exception.dart';
import 'package:build4front/core/exceptions/network_exception.dart';
import 'package:build4front/core/exceptions/app_exception.dart';

String localizeError(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;

  String code = 'GENERIC';

  if (error is AuthException) {
    code = error.code ?? 'AUTH_ERROR';
  } else if (error is NetworkException) {
    // if your NetworkException has a code, use it. otherwise keep NETWORK_ERROR
    code = (error as dynamic).code ?? 'NETWORK_ERROR';
  } else if (error is AppException) {
    code = (error as dynamic).code ?? 'GENERIC';
  }

  switch (code) {
    // --- Conflicts / taken ---
    case 'USERNAME_TAKEN':
      return l10n.authUsernameTaken;
    case 'EMAIL_ALREADY_EXISTS':
    case 'EMAIL_ALREADY_USED':
    case 'EMAIL_USED':
    case 'EMAIL_IN_USE':
      return l10n.authEmailAlreadyExists;
    case 'PHONE_ALREADY_EXISTS':
    case 'PHONE_ALREADY_USED':
    case 'PHONE_USED':
    case 'PHONE_IN_USE':
      return l10n.authPhoneAlreadyExists;

    // --- Login specific ---
    case 'USER_NOT_FOUND':
      return l10n.authUserNotFound;
    case 'WRONG_PASSWORD':
      return l10n.authWrongPassword;
    case 'INVALID_CREDENTIALS':
      return l10n.authInvalidCredentials;
    case 'INACTIVE':
      return l10n.authAccountInactive;

    // --- HTTP generic ---
    case 'VALIDATION_ERROR':
      return l10n.httpValidationError;
    case 'CONFLICT':
      return l10n.httpConflict;
    case 'UNAUTHORIZED':
      return l10n.httpUnauthorized;
    case 'FORBIDDEN':
      return l10n.httpForbidden;
    case 'NOT_FOUND':
      return l10n.httpNotFound;
    case 'SERVER_ERROR':
      return l10n.httpServerError;

    // --- Network ---
    case 'NO_INTERNET':
      return l10n.networkNoInternet;
    case 'TIMEOUT':
      return l10n.networkTimeout;
    case 'NETWORK_ERROR':
      return l10n.networkError;

    default:
      return l10n.authErrorGeneric;
  }
}
