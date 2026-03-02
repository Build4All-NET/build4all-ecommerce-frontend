// lib/features/profile_edit/domain/repositories/user_profile_repository.dart
import '../entities/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile> getById({
    required String token,
    required int userId,
  });

  Future<UserProfile> updateProfile({
    required String token,
    required int userId,
    required String firstName,
    required String lastName,
    String? username,
    String? email,
    bool? isPublicProfile,
    String? imageFilePath,
    bool imageRemoved = false,
  });

  Future<void> verifyEmailChange({
    required String token,
    required int userId,
    required String code,
  });

  Future<void> resendEmailChange({
    required String token,
    required int userId,
  });

  Future<void> deleteUser({
    required String token,
    required int userId,
    required String password,
  });
}