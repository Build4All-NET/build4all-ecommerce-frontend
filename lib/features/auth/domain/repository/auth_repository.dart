// lib/features/auth/domain/repository/auth_repository.dart

import 'package:dartz/dartz.dart';

import '../entities/user_entity.dart';

class AuthFailure {
  final String message;
  final String? code;
  final int? pendingId;

  const AuthFailure(
    this.message, {
    this.code,
    this.pendingId,
  });
}

abstract class AuthRepository {
  Future<Either<AuthFailure, void>> sendVerificationCode({
    String? email,
    String? phoneNumber,
    required String password,
    required int ownerProjectLinkId,
  });

  Future<Either<AuthFailure, int>> verifyEmailCode({
    required String email,
    required String code,
  });

  Future<Either<AuthFailure, int>> verifyPhoneCode({
    required String phoneNumber,
    required String code,
  });

  /// LOGIN
  Future<UserEntity> loginWithEmail({
    required String email,
    required String password,
    required int ownerProjectLinkId,
  });

  /// COMPLETE PROFILE
  Future<UserEntity> completeProfile({
    required int pendingId,
    required String username,
    required String firstName,
    required String lastName,
    required bool isPublicProfile,
    required int ownerProjectLinkId,
    String? profileImagePath,
  });
}
