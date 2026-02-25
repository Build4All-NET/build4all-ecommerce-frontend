// lib/features/auth/data/repository/auth_repository_impl.dart
import 'package:dartz/dartz.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repository/auth_repository.dart';
import '../services/auth_api_service.dart';

// bring in AppException so we can preserve it
import 'package:build4front/core/exceptions/app_exception.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService api;

  AuthRepositoryImpl({required this.api});

  // ----- Helpers for Either<> branches -----
  AuthFailure _toFailure(Object e) {
  if (e is AppException) {
    String? code;
    try {
      code = (e as dynamic).code?.toString();
    } catch (_) {
      code = null;
    }

    int? pendingId;
    if (code == 'PENDING_ALREADY_VERIFIED') {
      pendingId = api.consumeLastResumePendingId();
    }

    return AuthFailure(
      e.message,
      code: code,
      pendingId: pendingId,
    );
  }

  return const AuthFailure('Something went wrong. Please try again.');
}

  @override
  Future<Either<AuthFailure, void>> sendVerificationCode({
    String? email,
    String? phoneNumber,
    required String password,
    required int ownerProjectLinkId,
  }) async {
    try {
      await api.sendVerificationCode(
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        ownerProjectLinkId: ownerProjectLinkId,
      );
      return const Right(null);
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<AuthFailure, int>> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      final id = await api.verifyEmailCode(email: email, code: code);
      return Right(id);
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<AuthFailure, int>> verifyPhoneCode({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final id = await api.verifyPhoneCode(
        phoneNumber: phoneNumber,
        code: code,
      );
      return Right(id);
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  // ---------------------------------------------------------------
  // LOGIN → must preserve AppException so UI can map clean messages
  // ---------------------------------------------------------------
  @override
  Future<UserEntity> loginWithEmail({
    required String email,
    required String password,
    required int ownerProjectLinkId,
  }) async {
    try {
      final userModel = await api.loginWithEmail(
        email: email,
        password: password,
        ownerProjectLinkId: ownerProjectLinkId,
      );
      return userModel;
    } on AppException {
      rethrow; // ✅ keep code/message (e.g., INVALID_CREDENTIALS, USER_NOT_FOUND)
    } catch (e) {
      // unexpected error -> wrap in AppException so mapper can show a clean text
      throw AppException(
        'Server error. Please try later.',
        code: 'SERVER_ERROR',
        original: e,
      );
    }
  }

  // ---------------------------------------------------------------
  // COMPLETE PROFILE → same preservation rule
  // ---------------------------------------------------------------
  @override
  Future<UserEntity> completeProfile({
    required int pendingId,
    required String username,
    required String firstName,
    required String lastName,
    required bool isPublicProfile,
    required int ownerProjectLinkId,
    String? profileImagePath,
  }) async {
    try {
      final userModel = await api.completeUserProfile(
        pendingId: pendingId,
        username: username,
        firstName: firstName,
        lastName: lastName,
        isPublicProfile: isPublicProfile,
        ownerProjectLinkId: ownerProjectLinkId,
        profileImagePath: profileImagePath,
      );
      return userModel;
    } on AppException {
      rethrow; // ✅ keep nice message if backend responds with a clear error
    } catch (e) {
      throw AppException(
        'Server error. Please try later.',
        code: 'SERVER_ERROR',
        original: e,
      );
    }
  }
}
